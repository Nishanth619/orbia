import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game_config.dart';
import '../../models/skin_model.dart';
import '../../state/game_state_provider.dart';
import '../../state/skin_provider.dart';
import '../components/background.dart';
import '../components/level_complete_effect.dart';
import '../components/node.dart';
import '../components/obstacle.dart';
import '../components/particle_burst.dart';
import '../components/player.dart';
import '../components/score_flash.dart';
import '../components/shield_pickup.dart';
import '../managers/camera_controller.dart';
import '../managers/collision_manager.dart';
import '../managers/level_manager.dart';
import '../managers/object_pool.dart';

final class GameWorld extends World {
  GameWorld({
    required this.ref,
    required this.screenSize,
    required this.camera,
  });

  final WidgetRef       ref;
  final Vector2         screenSize;
  final CameraComponent camera;

  late final ObjectPool<Node>     _nodePool;
  late final ObjectPool<Obstacle> _obstaclePool;
  late final Player           _player;
  late final LevelManager     _levelManager;
  late final CameraController _cameraController;
  late final ScoreFlash       _scoreFlash;
  late final _ConnectionLine  _connectionLine;
  late final Background       _background;

  // ── Node tracking ─────────────────────────────────────────────────────
  Node?  _currentNode;
  Node?  _nextNode;
  Node?  _fadingNode;
  double _fadeTimer     = 0.0;
  static const double _fadeOutDuration = 0.20;

  // ── Obstacle tracking ─────────────────────────────────────────────────
  final List<Obstacle> _activeObstacles  = <Obstacle>[];
  final List<Obstacle> _fallingObstacles = <Obstacle>[];

  // ── Respawn — saved checkpoint ─────────────────────────────────────────
  /// World position of the node the player was on when they died.
  Vector2? _checkpointPosition;
  /// The node data for the NEXT node at time of death — to restore obstacles.
  NodeData? _checkpointNextNodeData;

  // ── Respawn animation ──────────────────────────────────────────────────
  bool   _isRespawning       = false;
  double _respawnTimer       = 0.0;
  double _invincibleTimer    = 0.0;
  bool   _isInvincible       = false;

  final math.Random _rng = math.Random();

  ShieldPickup? _activeShield;
  bool _playerHasShield = false;

  bool _isGameOver   = false;
  int  _currentScore = 0;
  int  _lastLevel    = 1;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  @override
  Future<void> onLoad() async {
    _background = Background(screenSize: screenSize, cameraRef: camera);
    add(_background);

    _nodePool     = ObjectPool<Node>(size: GameConfig.nodePoolSize, factory: Node.new);
    _obstaclePool = ObjectPool<Obstacle>(
        size: GameConfig.obstaclePoolSize, factory: Obstacle.new);
    _levelManager     = LevelManager(screenSize: screenSize);
    _cameraController = CameraController(camera: camera, screenSize: screenSize);

    _scoreFlash = ScoreFlash()..init(screenSize);
    add(_scoreFlash);

    _connectionLine = _ConnectionLine();
    add(_connectionLine);

    final SkinModel skin = ref.read(activeSkinProvider);
    _player = Player(skin: skin)
      ..onNodeArrived  = _onPlayerArrivedAtNode
      ..onDeath        = _onPlayerDied
      ..onShieldBroke  = _onShieldBroke;
    add(_player);
  }

  // ── Public API ────────────────────────────────────────────────────────

  void startGame() {
    _isGameOver        = false;
    _currentScore      = 0;
    _lastLevel         = 1;
    _playerHasShield   = false;
    _isRespawning      = false;
    _isInvincible      = false;
    _invincibleTimer   = 0.0;
    _checkpointPosition    = null;
    _checkpointNextNodeData = null;
    _activeObstacles.clear();
    _fallingObstacles.clear();
    _fadingNode = null;
    _fadeTimer  = 0.0;

    _nodePool.releaseAll();
    _obstaclePool.releaseAll();
    children.whereType<Node>().toList().forEach((n) => n.removeFromParent());
    children.whereType<Obstacle>().toList().forEach((o) => o.removeFromParent());
    children.whereType<ShieldPickup>().toList()
        .forEach((s) => s.removeFromParent());
    _activeShield = null;

    _background.transitionToLevel(1);
    _levelManager.reset(Vector2(screenSize.x / 2, screenSize.y * 0.70));

    final NodeData startData = _levelManager.generateNext();
    _currentNode = _spawnNode(startData.worldPosition, NodeState.current, _currentScore);

    _player.applySkin(ref.read(activeSkinProvider));
    _player.placeAt(_currentNode!.position.clone());
    _cameraController.resetTo(_currentNode!.position);
    _connectionLine.hide();

    _spawnNextNode();
    ref.read(gameStateProvider.notifier).beginPlaying();
  }

  /// Respawn player at checkpoint after losing a life.
  void respawnAtCheckpoint() {
    if (_checkpointPosition == null) return;

    _isRespawning    = false;
    _isInvincible    = true;
    _invincibleTimer = 0.0;
    _playerHasShield = false;

    // Clear falling obstacles.
    for (final Obstacle obs in _fallingObstacles) {
      obs.removeFromParent();
      _obstaclePool.release(obs);
    }
    _fallingObstacles.clear();

    // Clear active obstacles.
    for (final Obstacle obs in _activeObstacles) {
      obs.removeFromParent();
      _obstaclePool.release(obs);
    }
    _activeObstacles.clear();

    // Place player back at checkpoint node.
    _player.placeAt(_checkpointPosition!.clone());
    _player.playerState = PlayerState.idle;

    // Re-spawn the same next node with same obstacles (restored checkpoint).
    if (_nextNode != null) {
      _nextNode!.removeFromParent();
      _nodePool.release(_nextNode!);
      _nextNode = null;
    }

    if (_checkpointNextNodeData != null) {
      _restoreNextNodeFromCheckpoint(_checkpointNextNodeData!);
    } else {
      _spawnNextNode();
    }

    ref.read(gameStateProvider.notifier).respawnComplete();
  }

  void onTap() {
    if (_isGameOver || _nextNode == null) return;
    if (_isRespawning) return;
    _player.dashToward(_nextNode!.position.clone());
  }

  bool get playerHasShield => _playerHasShield;

  // ── Spawning ──────────────────────────────────────────────────────────

  void _spawnNextNode() {
    final NodeData data = _levelManager.generateNext();
    // Save checkpoint data for this next node — used on respawn.
    _checkpointNextNodeData = data;

    _nextNode = _spawnNode(data.worldPosition, NodeState.next, 0);
    if (_nextNode == null) return;

    _spawnObstaclesFromData(data);

    if (data.spawnShield && _activeShield == null) {
      _spawnShield(data.worldPosition);
    }

    if (_currentNode != null) {
      _connectionLine.show(
        from: _currentNode!.position,
        to:   _nextNode!.position,
      );
    }
  }

  /// Re-spawns the SAME next node data after a death — checkpoint restore.
  void _restoreNextNodeFromCheckpoint(NodeData data) {
    _nextNode = _spawnNode(data.worldPosition, NodeState.next, 0);
    if (_nextNode == null) return;
    _spawnObstaclesFromData(data);
    if (_currentNode != null) {
      _connectionLine.show(
        from: _currentNode!.position,
        to:   _nextNode!.position,
      );
    }
  }

  void _spawnObstaclesFromData(NodeData data) {
    for (final ObstacleConfig cfg in data.obstacles) {
      final Obstacle? obs = _obstaclePool.acquire();
      if (obs == null) break;
      obs.configure(
        centerX:      cfg.centerX,
        centerY:      cfg.centerY,
        omega:        cfg.omega,
        phi:          cfg.phi,
        radius:       cfg.radius,
        orbitRadius:  cfg.orbitRadius,
        eyeColor:     cfg.eyeColor,
        screenBottom: screenSize.y,
      );
      add(obs);
      _activeObstacles.add(obs);
    }
  }

  void _spawnShield(Vector2 nodePos) {
    if (_currentNode == null) return;
    final Vector2 mid = Vector2(
      (_currentNode!.position.x + nodePos.x) / 2.0 + 40.0,
      (_currentNode!.position.y + nodePos.y) / 2.0,
    );
    _activeShield = ShieldPickup(worldPosition: mid);
    add(_activeShield!);
  }

  Node? _spawnNode(Vector2 pos, NodeState state, int score) {
    final Node? node = _nodePool.acquire();
    if (node == null) return null;
    node.configure(worldPosition: pos, initialState: state, score: score);
    add(node);
    return node;
  }

  // ── Arrival ───────────────────────────────────────────────────────────

  void _onPlayerArrivedAtNode(Vector2 _) {
    if (_isGameOver) return;

    _isInvincible  = false;
    _invincibleTimer = 0.0;

    // Save checkpoint at current position BEFORE advancing.
    _checkpointPosition = _currentNode?.position.clone();

    // Drop obstacles.
    for (final Obstacle obs in _activeObstacles) {
      obs.startFalling(_rng);
      _fallingObstacles.add(obs);
    }
    _activeObstacles.clear();

    // Fade old node.
    if (_fadingNode != null) {
      _fadingNode!.removeFromParent();
      _nodePool.release(_fadingNode!);
      _fadingNode = null;
    }
    _fadingNode = _currentNode;
    _fadingNode?.startFadeOut(_fadeOutDuration);
    _fadeTimer  = 0.0;

    // Promote.
    _currentScore++;
    _currentNode = _nextNode;
    _currentNode?.promoteToCurrentWith(_currentScore);
    _nextNode = null;

    if (_currentNode != null) {
      _scoreFlash.flash(
          cx: _currentNode!.position.x, cy: _currentNode!.position.y);
    }

    final SkinModel skin  = ref.read(activeSkinProvider);
    final int       coins = (GameConfig.coinsPerNode * skin.coinMultiplier).round();
    ref.read(gameStateProvider.notifier).nodeReached(coins);
    _levelManager.recordNodeReached();

    // Level change check.
    final int newLevel = _levelManager.currentLevel;
    if (newLevel != _lastLevel) {
      _lastLevel = newLevel;
      _background.transitionToLevel(newLevel);
      final int themeIndex = ((newLevel - 1) % kLevelThemes.length);
      final Color themeColor = kLevelThemes[themeIndex].bottomColor;
      add(LevelCompleteEffect(
        playerPosition: _player.position.clone(),
        themeColor:     themeColor,
        screenSize:     screenSize,
        onComplete:     () {},
      ));
      ref.read(gameStateProvider.notifier).setLevelUp(newLevel);
    }

    _spawnNextNode();
  }

  // ── Death / respawn ───────────────────────────────────────────────────

  void _onPlayerDied() {
    if (_isGameOver) return;

    // Ask provider: do we have lives left?
    final bool canRespawn =
        ref.read(gameStateProvider.notifier).hitAndRespawn();

    if (canRespawn) {
      // Respawn path.
      _isRespawning = true;
      _respawnTimer = 0.0;
      _cameraController.triggerShake();

      // Small burst at death point.
      add(ParticleBurst(
        worldPosition:  _player.position.clone(),
        primaryColor:   Colors.white,
        secondaryColor: const Color(0xFFFF4400),
      ));
    } else {
      // No lives left — full game over.
      _isGameOver = true;
      _cameraController.triggerShake();
      _connectionLine.hide();
      add(ParticleBurst(
        worldPosition:  _player.position.clone(),
        primaryColor:   Colors.white,
        secondaryColor: const Color(0xFFFF4400),
      ));
      ref.read(gameStateProvider.notifier).triggerGameOver();
    }
  }

  void _onShieldBroke() {
    _playerHasShield = false;
    ref.read(gameStateProvider.notifier).setShieldActive(false);
  }

  // ── Update ────────────────────────────────────────────────────────────

  @override
  void update(double dt) {
    super.update(dt);
    _cameraController.update(dt, _player.position);

    // Fading node.
    if (_fadingNode != null) {
      _fadeTimer += dt;
      if (_fadeTimer >= _fadeOutDuration) {
        _fadingNode!.removeFromParent();
        _nodePool.release(_fadingNode!);
        _fadingNode = null;
        _fadeTimer  = 0.0;
      }
    }

    // Clean fallen obstacles.
    _fallingObstacles.removeWhere((Obstacle obs) {
      if (obs.isDoneFalling) {
        obs.removeFromParent();
        _obstaclePool.release(obs);
        return true;
      }
      return false;
    });

    // Respawn countdown — wait for death animation then restore.
    if (_isRespawning) {
      _respawnTimer += dt;
      if (_respawnTimer >= 0.8) {
        _isRespawning = false;
        respawnAtCheckpoint();
      }
      return; // skip collision during respawn
    }

    // Invincibility countdown after respawn.
    if (_isInvincible) {
      _invincibleTimer += dt;
      if (_invincibleTimer >= GameConfig.respawnInvincibleTime) {
        _isInvincible    = false;
        _invincibleTimer = 0.0;
      }
    }

    if (_isGameOver) return;

    _checkShieldCollection();
    if (!_isInvincible) _runCollision();
  }

  void _checkShieldCollection() {
    if (_activeShield == null || _activeShield!.collected || _playerHasShield) return;
    final double dx = _player.worldX - _activeShield!.position.x;
    final double dy = _player.worldY - _activeShield!.position.y;
    final double t  = _player.collisionRadius + GameConfig.shieldPickupRadius;
    if (dx * dx + dy * dy < t * t) {
      _activeShield!.collected = true;
      _activeShield!.removeFromParent();
      _activeShield    = null;
      _playerHasShield = true;
      _player.activateShield();
      ref.read(gameStateProvider.notifier).setShieldActive(true);
    }
  }

  void _runCollision() {
    for (int i = 0; i < _activeObstacles.length; i++) {
      final Obstacle obs = _activeObstacles[i];
      if (!obs.isActive) continue;
      if (CollisionManager.checkPlayerObstacle(_player, obs)) {
        if (_player.hasShield) {
          _player.breakShield();
        } else {
          _player.kill();
        }
        return;
      }
    }
  }
}

// ── Connection line ───────────────────────────────────────────────────────────

final class _ConnectionLine extends Component {
  double _x1 = 0, _y1 = 0, _x2 = 0, _y2 = 0;
  bool   _visible = false;

  final Paint _paint = Paint()
    ..style       = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color       = const Color(0xBFFFFFFF);

  void show({required Vector2 from, required Vector2 to}) {
    _x1 = from.x; _y1 = from.y;
    _x2 = to.x;   _y2 = to.y;
    _visible = true;
  }

  void hide() => _visible = false;

  @override
  void render(Canvas canvas) {
    if (!_visible) return;
    canvas.drawLine(Offset(_x1, _y1), Offset(_x2, _y2), _paint);
  }
}
