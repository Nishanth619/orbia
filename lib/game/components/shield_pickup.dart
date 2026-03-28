import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

import '../../models/game_config.dart';

final class ShieldPickup extends PositionComponent {
  ShieldPickup({required Vector2 worldPosition})
      : super(anchor: Anchor.center) {
    position.setFrom(worldPosition);
    size = Vector2.all(GameConfig.shieldPickupRadius * 2.0 + 20.0);
  }

  bool collected = false;

  double _pulseTimer = 0.0;
  static const double _pulseSpeed = 3.0;

  final double collisionRadius = GameConfig.shieldPickupRadius;

  final Paint _outerGlowPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x4400CFFF)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);

  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = const Color(0xFF00CFFF);

  final Paint _corePaint = Paint()
    ..style = PaintingStyle.fill
    ..color = const Color(0x8800CFFF);

  final Paint _iconPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5
    ..color = Colors.white
    ..strokeCap = StrokeCap.round;

  @override
  void update(double dt) {
    if (collected) return;
    _pulseTimer += dt;
  }

  @override
  void render(Canvas canvas) {
    if (collected) return;

    final Offset centre = Offset(size.x / 2.0, size.y / 2.0);
    final double pulse = 1.0 + 0.12 * math.sin(_pulseTimer * _pulseSpeed);
    final double r = collisionRadius * pulse;

    canvas.drawCircle(centre, r * 1.6, _outerGlowPaint);
    canvas.drawCircle(centre, r, _ringPaint);
    canvas.drawCircle(centre, r * 0.85, _corePaint);
    _drawShieldIcon(canvas, centre, r * 0.52);
  }

  void _drawShieldIcon(Canvas canvas, Offset centre, double size) {
    final Path path = Path();
    path.moveTo(centre.dx - size, centre.dy - size * 0.3);
    path.arcTo(
      Rect.fromCenter(center: centre, width: size * 2, height: size * 2),
      math.pi,
      -math.pi,
      false,
    );
    path.lineTo(centre.dx + size, centre.dy - size * 0.3);
    path.lineTo(centre.dx, centre.dy + size * 1.1);
    path.lineTo(centre.dx - size, centre.dy - size * 0.3);

    canvas.drawPath(path, _iconPaint);
  }
}
