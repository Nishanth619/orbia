import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, Colors;

import '../../models/game_config.dart';
import '../../models/skin_model.dart';

enum PlayerState { idle, dashing, dying, dead }

enum ShieldState { none, active, breaking }

final class _Sparkle {
  double x = 0, y = 0;
  double age = 0, lifetime = 0;
  double radius = 0;
  double opacity = 0;
  bool alive = false;

  void spawn(double wx, double wy, math.Random rng) {
    x = wx + (rng.nextDouble() - 0.5) * GameConfig.sparkleSpread;
    y = wy + (rng.nextDouble() - 0.5) * GameConfig.sparkleSpread;
    age = 0;
    lifetime = GameConfig.sparkleLifetime * (0.5 + rng.nextDouble() * 0.5);
    radius = GameConfig.sparkleMaxRadius * (0.4 + rng.nextDouble() * 0.6);
    opacity = 1.0;
    alive = true;
  }
}

final class Player extends PositionComponent {
  Player({required SkinModel skin})
      : _skin = skin,
        super(anchor: Anchor.center);

  SkinModel _skin;

  void applySkin(SkinModel skin) {
    _skin = skin;
    collisionRadius = skin.effectiveRadius;
    _updateSize();
  }

  double collisionRadius = GameConfig.playerBaseRadius;
  double get worldX => position.x;
  double get worldY => position.y;

  PlayerState playerState = PlayerState.idle;
  ShieldState shieldState = ShieldState.none;
  bool get hasShield => shieldState == ShieldState.active;

  final Vector2 _targetPosition = Vector2.zero();
  final Vector2 _velocity = Vector2.zero();
  final Vector2 _scratchDir = Vector2.zero();
  static const double _arrivalThreshold = 7.0;

  double _pulseTimer = 0.0;
  static const double _pulseSpeed = 2.8;
  static const double _pulseAmp = 0.06;

  double _freezeTimer = 0.0;
  double _shieldTimer = 0.0;
  double _shieldBreakTimer = 0.0;

  late final List<_Sparkle> _sparkles;
  double _sparkleTimer = 0.0;
  final math.Random _rng = math.Random();

  final Paint _idlePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;

  final Paint _idleGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x55FFFFFF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

  final Paint _dashPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;

  final Paint _dashGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x99FFFFFF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);

  final Paint _eyePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF0D0005);

  final Paint _sparklePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;

  final Paint _sparkleGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)
    ..color = Colors.white;

  final Paint _shieldActivePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..color = const Color(0xFF00CFFF);

  final Paint _shieldActiveGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7.0
    ..color = const Color(0x5500CFFF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

  final Paint _shieldBreakPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..color = const Color(0xFFFF3300);

  Offset _center = Offset.zero;

  void Function(Vector2)? onNodeArrived;
  void Function()? onDeath;
  void Function()? onShieldBroke;
  void Function()? onShieldExpired;

  @override
  Future<void> onLoad() async {
    collisionRadius = _skin.effectiveRadius;
    _updateSize();
    _sparkles = List<_Sparkle>.generate(
      GameConfig.sparklePoolSize,
      (_) => _Sparkle(),
      growable: false,
    );
  }

  void _updateSize() {
    size = Vector2.all(collisionRadius * 2.8);
    _center = Offset(size.x / 2, size.y / 2);
  }

  void activateShield() {
    shieldState = ShieldState.active;
    _shieldTimer = GameConfig.shieldDurationSeconds;
    _shieldBreakTimer = 0.0;
  }

  void breakShield() {
    shieldState = ShieldState.breaking;
    _shieldTimer = 0.0;
    _shieldBreakTimer = 0.0;
    onShieldBroke?.call();
  }

  void dashToward(Vector2 target) {
    if (playerState != PlayerState.idle) return;
    _targetPosition.setFrom(target);
    _scratchDir
      ..setFrom(target)
      ..sub(position);
    final double dist = _scratchDir.length;
    if (dist < _arrivalThreshold) {
      _arrive();
      return;
    }
    _velocity
      ..setFrom(_scratchDir)
      ..scale(_skin.effectiveSpeed / dist);
    playerState = PlayerState.dashing;
    _pulseTimer = 0.0;
    _sparkleTimer = 0.0;
  }

  void placeAt(Vector2 worldPosition) {
    position.setFrom(worldPosition);
    playerState = PlayerState.idle;
    shieldState = ShieldState.none;
    _shieldTimer = 0.0;
    _shieldBreakTimer = 0.0;
    _velocity.setZero();
    _pulseTimer = 0.0;
    for (final _Sparkle s in _sparkles) {
      s.alive = false;
    }
  }

  void kill() {
    if (playerState == PlayerState.dead || playerState == PlayerState.dying) {
      return;
    }
    playerState = PlayerState.dying;
    _freezeTimer = 0.0;
    _velocity.setZero();
  }

  @override
  void update(double dt) {
    if (shieldState == ShieldState.active) {
      _shieldTimer -= dt;
      if (_shieldTimer <= 0.0) {
        _shieldTimer = 0.0;
        shieldState = ShieldState.none;
        onShieldExpired?.call();
      }
    }

    if (shieldState == ShieldState.breaking) {
      _shieldBreakTimer += dt;
      if (_shieldBreakTimer >= GameConfig.shieldBreakDuration) {
        shieldState = ShieldState.none;
      }
    }

    switch (playerState) {
      case PlayerState.idle:
        _pulseTimer += dt;

      case PlayerState.dashing:
        position.x += _velocity.x * dt;
        position.y += _velocity.y * dt;

        _sparkleTimer += dt;
        if (_sparkleTimer >= GameConfig.sparkleSpawnInterval) {
          _sparkleTimer = 0.0;
          _spawnSparkle();
        }

        for (final _Sparkle s in _sparkles) {
          if (!s.alive) continue;
          s.age += dt;
          if (s.age >= s.lifetime) {
            s.alive = false;
            continue;
          }
          s.opacity = 1.0 - (s.age / s.lifetime);
        }

        final double dx = position.x - _targetPosition.x;
        final double dy = position.y - _targetPosition.y;
        if (dx * dx + dy * dy < _arrivalThreshold * _arrivalThreshold) {
          _arrive();
        }

      case PlayerState.dying:
        _freezeTimer += dt;
        if (_freezeTimer >= GameConfig.deathFreezeSeconds) {
          playerState = PlayerState.dead;
          onDeath?.call();
        }

      case PlayerState.dead:
        break;
    }
  }

  void _spawnSparkle() {
    for (final _Sparkle s in _sparkles) {
      if (!s.alive) {
        s.spawn(position.x, position.y, _rng);
        return;
      }
    }
  }

  void _arrive() {
    position.setFrom(_targetPosition);
    playerState = PlayerState.idle;
    _velocity.setZero();
    _pulseTimer = 0.0;
    for (final _Sparkle s in _sparkles) {
      s.alive = false;
    }
    onNodeArrived?.call(_targetPosition.clone());
  }

  @override
  void render(Canvas canvas) {
    switch (playerState) {
      case PlayerState.dead:
        return;

      case PlayerState.dying:
        canvas.drawCircle(_center, collisionRadius * 1.6, _dashGlowPaint);
        canvas.drawCircle(_center, collisionRadius, _dashPaint);

      case PlayerState.idle:
        _renderShield(canvas);
        final double scale =
            1.0 + _pulseAmp * math.sin(_pulseTimer * _pulseSpeed);
        final double r = collisionRadius * 0.52 * scale;
        canvas.drawCircle(_center, r * 2.2, _idleGlowPaint);
        canvas.drawCircle(_center, r, _idlePaint);
        _renderEyes(canvas, r);

      case PlayerState.dashing:
        _renderSparkles(canvas);
        _renderShield(canvas);
        canvas.drawCircle(_center, collisionRadius * 1.6, _dashGlowPaint);
        canvas.drawCircle(_center, collisionRadius, _dashPaint);
    }
  }

  void _renderSparkles(Canvas canvas) {
    for (final _Sparkle s in _sparkles) {
      if (!s.alive || s.opacity <= 0) continue;

      final double lx = s.x - position.x + _center.dx;
      final double ly = s.y - position.y + _center.dy;

      final double r = s.radius * s.opacity;
      if (r < 0.3) continue;

      _sparkleGlowPaint.color = Colors.white.withValues(alpha: s.opacity * 0.5);
      canvas.drawCircle(Offset(lx, ly), r * 2.0, _sparkleGlowPaint);

      _sparklePaint.color = Colors.white.withValues(alpha: s.opacity);
      canvas.drawCircle(Offset(lx, ly), r, _sparklePaint);
    }
  }

  void _renderShield(Canvas canvas) {
    if (shieldState == ShieldState.none) return;
    final double sr = collisionRadius * 1.6;

    if (shieldState == ShieldState.active) {
      final double pulse =
          1.0 + 0.07 * math.sin(_pulseTimer * _pulseSpeed * 1.5);
      canvas.drawCircle(_center, sr * pulse, _shieldActiveGlowPaint);
      canvas.drawCircle(_center, sr * pulse, _shieldActivePaint);
    } else {
      final double p = _shieldBreakTimer / GameConfig.shieldBreakDuration;
      _shieldBreakPaint.color =
          const Color(0xFFFF3300).withValues(alpha: 1.0 - p);
      canvas.drawCircle(_center, sr * (1.0 + p * 0.7), _shieldBreakPaint);
    }
  }

  void _renderEyes(Canvas canvas, double r) {
    final double ex = r * 0.40;
    final double ey = r * 0.12;
    final double er = r * 0.22;
    canvas.drawCircle(Offset(_center.dx - ex, _center.dy - ey), er, _eyePaint);
    canvas.drawCircle(Offset(_center.dx + ex, _center.dy - ey), er, _eyePaint);
  }
}
