import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Alignment, LinearGradient, Color;

/// Orbia-accurate background — red gradient + mountains + dust.
///
/// ROOT CAUSE FIX:
///   The old version drew its picture at world position (0,0) and was
///   only screenSize tall. As the camera moved up into negative Y world
///   coordinates, the top of the screen showed raw backgroundColor
///   instead of the gradient — visible as a seam/flicker.
///
///   FIX: Background is now a PositionComponent that tracks the camera
///   every frame. Its position is updated in update(dt) to always sit
///   exactly behind the camera viewport — so the gradient always fills
///   the entire screen regardless of how far up the camera has moved.
///   The cached Picture is reused unchanged — zero per-frame allocation.
final class Background extends PositionComponent {
  Background({
    required this.screenSize,
    required this.cameraRef,
  }) : super(priority: -100);

  final Vector2 screenSize;

  /// Reference to the camera so background can track its position.
  final CameraComponent cameraRef;

  Picture? _cachedPicture;

  static const Color _topColor = Color(0xFF2A0015);
  static const Color _midColor = Color(0xFF7A0A00);
  static const Color _bottomColor = Color(0xFFCC3300);
  static const Color _mountainDark = Color(0xFF1A0008);
  static const Color _mountainMid = Color(0xFF2D000F);
  static const Color _dustColor = Color(0x33FF6600);
  static const int _dustCount = 60;

  @override
  Future<void> onLoad() async {
    // Size matches the screen exactly.
    size = screenSize;
    // Start at top-left of screen.
    syncToCamera();
    // Build the picture once.
    _cachedPicture = _buildPicture();
  }

  /// Snaps background position so it exactly covers the camera viewport.
  void syncToCamera() {
    // camera.viewfinder.position is the world point at screen centre.
    // Background top-left = centre - screenSize/2.
    final Vector2 camPos = cameraRef.viewfinder.position;
    position.setValues(
      camPos.x - screenSize.x / 2.0,
      camPos.y - screenSize.y / 2.0,
    );
  }

  Picture _buildPicture() {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double w = screenSize.x;
    final double h = screenSize.y;
    final math.Random rng = math.Random(42);

    // Gradient
    final Paint gradientPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[_topColor, _midColor, _bottomColor],
        stops: <double>[0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradientPaint);

    // Dust particles
    final Paint dustPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _dustColor;
    for (int i = 0; i < _dustCount; i++) {
      canvas.drawCircle(
        Offset(rng.nextDouble() * w, rng.nextDouble() * h),
        0.8 + rng.nextDouble() * 2.0,
        dustPaint,
      );
    }

    // Mountains — back layer
    _drawMountainLayer(
      canvas: canvas,
      w: w,
      h: h,
      color: _mountainDark,
      baseY: h,
      peakHeight: h * 0.20,
      count: 7,
      xOffset: 0.0,
    );

    // Mountains — front layer
    _drawMountainLayer(
      canvas: canvas,
      w: w,
      h: h,
      color: _mountainMid,
      baseY: h * 1.02,
      peakHeight: h * 0.13,
      count: 9,
      xOffset: w * 0.06,
    );

    return recorder.endRecording();
  }

  void _drawMountainLayer({
    required Canvas canvas,
    required double w,
    required double h,
    required Color color,
    required double baseY,
    required double peakHeight,
    required int count,
    required double xOffset,
  }) {
    final Paint paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final double segW = w / count;
    for (int i = 0; i < count; i++) {
      final double left = i * segW + xOffset - segW * 0.1;
      final double right = left + segW * 1.2;
      final double mid = (left + right) / 2;
      final double peak = baseY - peakHeight;

      canvas.drawPath(
        Path()
          ..moveTo(left, baseY)
          ..lineTo(mid, peak)
          ..lineTo(right, baseY)
          ..close(),
        paint,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (_cachedPicture != null) canvas.drawPicture(_cachedPicture!);
  }
}
