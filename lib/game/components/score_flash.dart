import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

/// Subtle expanding ring pulse on node arrival — replaces the
/// full-screen white flash which caused visible screen flicker.
///
/// Draws an expanding circle that fades out over 0.25s.
/// Much less jarring than a full-screen colour change.
final class ScoreFlash extends Component {
  bool _active = false;
  double _timer = 0.0;

  // Position of the pulse (set to the current node position).
  double _cx = 0.0;
  double _cy = 0.0;

  // Pre-allocated paint — colour overwritten each frame.
  final Paint _paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..color = Colors.white;

  static const double _duration = 0.28;
  static const double _maxRadius = 90.0;

  void init(Vector2 screenSize) {
    // Kept for API compatibility with the current game-world setup.
  }

  /// Triggers the pulse at [nodeWorldPosition].
  void flash({double cx = 0, double cy = 0}) {
    _cx = cx;
    _cy = cy;
    _timer = 0.0;
    _active = true;
  }

  @override
  void update(double dt) {
    if (!_active) return;
    _timer += dt;
    if (_timer >= _duration) {
      _active = false;
      _timer = 0.0;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_active) return;

    final double progress = _timer / _duration;
    // Ease-out: fast expand then slow.
    final double eased = 1.0 - math.pow(1.0 - progress, 2).toDouble();
    final double radius = _maxRadius * eased;
    final double alpha = (1.0 - progress) * 0.55;

    _paint.color = Colors.white.withValues(alpha: alpha);
    _paint.strokeWidth = 3.0 * (1.0 - progress * 0.5);

    canvas.drawCircle(Offset(_cx, _cy), radius, _paint);
  }

  @override
  int get priority => 50; // below HUD but above game objects
}
