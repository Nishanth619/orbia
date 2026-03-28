import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../models/game_config.dart';
import '../components/obstacle.dart';

final class ObstacleConfig {
  const ObstacleConfig({
    required this.centerX,
    required this.centerY,
    required this.omega,
    required this.phi,
    required this.radius,
    required this.orbitRadius,
    required this.eyeColor,
  });

  final double centerX;
  final double centerY;
  final double omega;
  final double phi;
  final double radius;
  final double orbitRadius;
  final ObstacleEyeColor eyeColor;
}

final class NodeData {
  const NodeData({
    required this.worldPosition,
    required this.obstacles,
    this.spawnShield = false,
  });

  final Vector2 worldPosition;
  final List<ObstacleConfig> obstacles;
  final bool spawnShield;
}

final class LevelManager {
  LevelManager({required this.screenSize}) {
    _rng = math.Random();
  }

  final Vector2 screenSize;
  late final math.Random _rng;

  int _nodesGenerated = 0;
  int _nodesReached = 0;
  double _lastX = 0.0;
  double _lastY = 0.0;
  int _zigDir = 1;

  void reset(Vector2 startPosition) {
    _nodesGenerated = 0;
    _nodesReached = 0;
    _lastX = startPosition.x;
    _lastY = startPosition.y;
    _zigDir = 1;
  }

  void recordNodeReached() => _nodesReached++;

  int get nodesReached => _nodesReached;
  int get currentLevel => (_nodesReached ~/ GameConfig.nodesPerLevel) + 1;

  NodeData generateNext() {
    final Vector2 pos = _nextNodePosition();
    final List<ObstacleConfig> obstacles = _buildObstacles(pos);

    final bool spawnShield = _nodesGenerated > 0 &&
        _nodesGenerated % GameConfig.shieldSpawnEveryNNodes == 0;

    _lastX = pos.x;
    _lastY = pos.y;
    _nodesGenerated++;

    return NodeData(
      worldPosition: pos,
      obstacles: obstacles,
      spawnShield: spawnShield,
    );
  }

  Vector2 _nextNodePosition() {
    if (_nodesGenerated == 0) {
      return Vector2(screenSize.x / 2, screenSize.y * 0.70);
    }

    final double newY = _lastY + GameConfig.nodeVerticalStep;
    final double baseStep = GameConfig.nodeMaxHorizontalOffset * _zigDir;
    final double jitter =
        (_rng.nextDouble() - 0.5) * GameConfig.nodeMaxHorizontalOffset * 0.3;
    double newX = _lastX + baseStep + jitter;

    const double margin = 70.0;
    newX = newX.clamp(margin, screenSize.x - margin);

    if (_rng.nextDouble() > 0.20) _zigDir = -_zigDir;
    return Vector2(newX, newY);
  }

  List<ObstacleConfig> _buildObstacles(Vector2 nodePos) {
    if (_nodesGenerated == 0) return <ObstacleConfig>[];

    final int count = _obstacleCount();
    final double omega = _scaledOmega();
    final double direction = _nodesGenerated.isEven ? 1.0 : -1.0;

    final double cx = nodePos.x;
    final double cy = nodePos.y;

    final double phaseStep = (math.pi * 2.0) / count;
    final double phaseOffset = _rng.nextDouble() * math.pi * 2.0;

    return List<ObstacleConfig>.generate(count, (int i) {
      final double radius = _randomRadius();
      final double orbitR = GameConfig.obstacleOrbitRadiusBase +
          (radius - GameConfig.obstacleRadiusMedium) * 0.8;

      final ObstacleEyeColor eyes =
          i.isEven ? ObstacleEyeColor.cyan : ObstacleEyeColor.green;

      return ObstacleConfig(
        centerX: cx,
        centerY: cy,
        omega: omega * direction,
        phi: phaseOffset + phaseStep * i,
        radius: radius,
        orbitRadius: orbitR,
        eyeColor: eyes,
      );
    }, growable: false);
  }

  double _randomRadius() {
    final double r = _rng.nextDouble();
    if (r < 0.25) return GameConfig.obstacleRadiusSmall;
    if (r < 0.75) return GameConfig.obstacleRadiusMedium;
    return GameConfig.obstacleRadiusLarge;
  }

  int _obstacleCount() {
    if (_nodesReached == 0) return 2;
    if (_nodesReached < 5) return 3;
    if (_nodesReached < 10) return 4;
    if (_nodesReached < 15) return 5;
    if (_nodesReached < 20) return 6;
    return 7;
  }

  double _scaledOmega() {
    final double ramp = GameConfig.obstacleBaseOmega +
        _nodesReached * GameConfig.omegaPerNodeIncrement;
    return math.min(ramp, GameConfig.maxOmega);
  }
}
