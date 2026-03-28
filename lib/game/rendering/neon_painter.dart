import 'dart:ui';

import 'package:flutter/material.dart'
    show Color, CustomPainter, Canvas, Size, Colors;

import 'bloom_cache.dart';

/// CustomPainter for an animated neon orb — used in Flutter UI screens.
class NeonOrbPainter extends CustomPainter {
  NeonOrbPainter({
    required Color color,
    required this.radius,
    required this.pulseProgress,
    List<BloomLayer>? bloomLayers,
  }) : _bloom = BloomPaintSet(
          color: color,
          layers: bloomLayers ?? BloomPresets.standard,
        );

  final double radius;
  final double pulseProgress;
  final BloomPaintSet _bloom;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double scale = 0.92 + 0.16 * pulseProgress;
    _bloom.renderBloom(canvas, center, radius * scale);
  }

  @override
  bool shouldRepaint(NeonOrbPainter old) =>
      old.pulseProgress != pulseProgress || old.radius != radius;
}

/// CustomPainter for the HUD score progress ring.
class NeonProgressRingPainter extends CustomPainter {
  NeonProgressRingPainter({required this.progress, required Color color})
      : _trackPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Colors.white10,
        _fillPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..strokeCap = StrokeCap.round
          ..color = color,
        _glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round
          ..color = color.withAlpha((0.3 * 255).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

  final double progress;
  final Paint _trackPaint;
  final Paint _fillPaint;
  final Paint _glowPaint;

  static const double _startAngle = -1.5708;
  static const double _fullSweep = 6.2832;

  @override
  void paint(Canvas canvas, Size size) {
    final double r =
        (size.width < size.height ? size.width : size.height) / 2 - 4;
    final Rect rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2), radius: r);
    canvas.drawArc(rect, _startAngle, _fullSweep, false, _trackPaint);
    if (progress > 0.0) {
      final double sweep = _fullSweep * progress;
      canvas.drawArc(rect, _startAngle, sweep, false, _glowPaint);
      canvas.drawArc(rect, _startAngle, sweep, false, _fillPaint);
    }
  }

  @override
  bool shouldRepaint(NeonProgressRingPainter old) => old.progress != progress;
}
