import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/game_config.dart';
import '../managers/object_pool.dart';

enum _ObstacleState { orbiting, falling, done }

enum ObstacleEyeColor { cyan, green }

final class Obstacle extends PositionComponent implements Poolable {
  Obstacle() : super(anchor: Anchor.center);

  @override
  bool isActive = false;

  double _centerX = 0.0;
  double _centerY = 0.0;
  double _orbitRadius = GameConfig.obstacleOrbitRadiusBase;
  double _omega = GameConfig.obstacleBaseOmega;
  double _phi = 0.0;
  double _t = 0.0;

  _ObstacleState _state = _ObstacleState.orbiting;
  double _velX = 0.0;
  double _velY = 0.0;
  double _fallX = 0.0;
  double _fallY = 0.0;
  double _screenBottom = 2000.0;

  double collisionRadius = GameConfig.obstacleRadiusMedium;
  double worldX = 0.0;
  double worldY = 0.0;

  ObstacleEyeColor eyeColor = ObstacleEyeColor.cyan;

  Offset _center = Offset.zero;

  final Paint _haloLarge = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x771A1A2E)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18.0);

  final Paint _haloSmall = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xAA252538)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7.0);

  final Paint _bodyPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF0C0C18);

  final Paint _cyanGlow = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xCC00EEFF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

  final Paint _cyanCore = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF00FFFF);

  final Paint _greenGlow = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xCC44FF44)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);

  final Paint _greenCore = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0xFF66FF44);

  void configure({
    required double centerX,
    required double centerY,
    required double omega,
    required double phi,
    required double radius,
    required double orbitRadius,
    required ObstacleEyeColor eyeColor,
    required double screenBottom,
  }) {
    _centerX = centerX;
    _centerY = centerY;
    _omega = omega;
    _phi = phi;
    _orbitRadius = orbitRadius;
    collisionRadius = radius;
    this.eyeColor = eyeColor;
    _screenBottom = screenBottom;
    _state = _ObstacleState.orbiting;

    final double d = radius * 2.0 + 32.0;
    size = Vector2.all(d);
    _center = Offset(d / 2.0, d / 2.0);
  }

  void startFalling(math.Random rng) {
    if (_state != _ObstacleState.orbiting) return;

    _state = _ObstacleState.falling;
    _fallX = worldX;
    _fallY = worldY;
    _velX = (rng.nextDouble() - 0.5) * GameConfig.fallSpreadX;
    _velY = GameConfig.fallInitialSpeedY + rng.nextDouble() * 80.0;
  }

  bool get isDoneFalling => _state == _ObstacleState.done;

  @override
  void reset() {
    _state = _ObstacleState.orbiting;
    _centerX = 0.0;
    _centerY = 0.0;
    isActive = false;
  }

  @override
  void update(double dt) {
    if (!isActive) return;

    if (_state == _ObstacleState.orbiting) {
      _t += dt;
      final double angle = _omega * _t + _phi;
      worldX = _centerX + _orbitRadius * math.cos(angle);
      worldY = _centerY + _orbitRadius * math.sin(angle);
      position.setValues(worldX, worldY);
    } else if (_state == _ObstacleState.falling) {
      _velY += GameConfig.fallGravity * dt;
      _fallX += _velX * dt;
      _fallY += _velY * dt;
      position.setValues(_fallX, _fallY);
      worldX = _fallX;
      worldY = _fallY;

      if (_fallY > _screenBottom + 200.0) {
        _state = _ObstacleState.done;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isActive) return;
    if (_state == _ObstacleState.done) return;

    final double r = collisionRadius;
    canvas.drawCircle(_center, r * 1.80, _haloLarge);
    canvas.drawCircle(_center, r * 1.28, _haloSmall);
    canvas.drawCircle(_center, r, _bodyPaint);
    _renderEyes(canvas, r);
  }

  void _renderEyes(Canvas canvas, double r) {
    final Paint glow =
        eyeColor == ObstacleEyeColor.cyan ? _cyanGlow : _greenGlow;
    final Paint core =
        eyeColor == ObstacleEyeColor.cyan ? _cyanCore : _greenCore;

    final double sep = r * 0.36;
    final double ey = r * 0.08;
    final double er = r * 0.20;

    final Offset l = Offset(_center.dx - sep, _center.dy - ey);
    final Offset r2 = Offset(_center.dx + sep, _center.dy - ey);

    canvas.drawCircle(l, er * 2.1, glow);
    canvas.drawCircle(r2, er * 2.1, glow);
    canvas.drawCircle(l, er, core);
    canvas.drawCircle(r2, er, core);
  }
}
