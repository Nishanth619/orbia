import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Color, Colors;

/// Handles the full in-world visual effect when a level is completed.
///
/// Sequence (total ~2.0s, runs inside Flame world):
///   0.00–0.25s  Screen-edge glow flash (themed color)
///   0.15–0.70s  Expanding ring from player position
///   0.20–0.80s  32-particle burst in all directions
///   2.00s       Calls [onComplete] — game world resumes
///
/// The Flutter UI layer (LevelCompleteOverlay widget) handles the text
/// animation separately so it can use Flutter animations.
final class LevelCompleteEffect extends Component {
  LevelCompleteEffect({
    required this.playerPosition,
    required this.themeColor,
    required this.screenSize,
    required this.onComplete,
  });

  final Vector2  playerPosition;
  final Color    themeColor;
  final Vector2  screenSize;
  final void Function() onComplete;

  double _t       = 0.0;
  bool   _done    = false;
  bool   _fired   = false;

  static const double _totalDuration = 2.0;

  // ── Expanding ring ────────────────────────────────────────────────────
  static const double _ringMaxRadius = 280.0;
  static const double _ringDuration  = 0.65;

  // ── Edge glow ─────────────────────────────────────────────────────────
  static const double _glowDuration  = 0.40;

  // ── Particles ─────────────────────────────────────────────────────────
  static const int    _particleCount = 36;
  static const double _particleStart = 0.15;

  late final List<_LevelParticle> _particles;

  // ── Pre-allocated paints ──────────────────────────────────────────────
  final Paint _ringPaint = Paint()
    ..style       = PaintingStyle.stroke
    ..strokeWidth = 3.0;

  final Paint _ringGlowPaint = Paint()
    ..style       = PaintingStyle.stroke
    ..strokeWidth = 8.0;

  final Paint _edgePaint = Paint()..style = PaintingStyle.fill;
  final Paint _particlePaint = Paint()..style = PaintingStyle.fill;

  @override
  Future<void> onLoad() async {
    final math.Random rng = math.Random();

    _particles = List<_LevelParticle>.generate(_particleCount, (int i) {
      final double angle  = (i / _particleCount) * math.pi * 2.0
          + (rng.nextDouble() - 0.5) * 0.3;
      final double speed  = 180.0 + rng.nextDouble() * 160.0;
      final double size   = 3.0 + rng.nextDouble() * 5.0;
      final double life   = 0.5 + rng.nextDouble() * 0.4;
      return _LevelParticle(
        x:     playerPosition.x,
        y:     playerPosition.y,
        vx:    math.cos(angle) * speed,
        vy:    math.sin(angle) * speed,
        size:  size,
        life:  life,
      );
    }, growable: false);
  }

  @override
  void update(double dt) {
    if (_done) return;
    _t += dt;

    // Activate particles after short delay.
    if (_t >= _particleStart) {
      for (final _LevelParticle p in _particles) {
        if (!p.active) { p.active = true; }
        if (!p.active) continue;
        final double age = _t - _particleStart;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.vy += 200.0 * dt; // gravity
        p.age = age;
      }
    }

    // Fire completion callback.
    if (_t >= _totalDuration && !_fired) {
      _fired = true;
      _done  = true;
      onComplete();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (_done) return;

    // ── Screen edge glow ──────────────────────────────────────────────
    if (_t < _glowDuration) {
      final double progress = _t / _glowDuration;
      final double alpha    = math.sin(progress * math.pi) * 0.45;
      _edgePaint.color      = themeColor.withValues(alpha: alpha);
      _edgePaint.maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 40.0);

      // Four edge rectangles
      final double w = screenSize.x;
      final double h = screenSize.y;
      const double thickness = 60.0;

      // Camera offset: draw relative to player so it appears at screen edges.
      // Since this is in world space, use player position as reference.
      // Top edge
      canvas.drawRect(
        Rect.fromLTWH(playerPosition.x - w / 2, playerPosition.y - h / 2,
            w, thickness),
        _edgePaint,
      );
      // Bottom edge
      canvas.drawRect(
        Rect.fromLTWH(playerPosition.x - w / 2,
            playerPosition.y + h / 2 - thickness, w, thickness),
        _edgePaint,
      );
      // Left edge
      canvas.drawRect(
        Rect.fromLTWH(playerPosition.x - w / 2, playerPosition.y - h / 2,
            thickness, h),
        _edgePaint,
      );
      // Right edge
      canvas.drawRect(
        Rect.fromLTWH(playerPosition.x + w / 2 - thickness,
            playerPosition.y - h / 2, thickness, h),
        _edgePaint,
      );
    }

    // ── Expanding ring ────────────────────────────────────────────────
    if (_t < _ringDuration) {
      final double progress = _t / _ringDuration;
      // Ease-out: ring expands fast then decelerates.
      final double eased  = 1.0 - math.pow(1.0 - progress, 2.5).toDouble();
      final double radius = _ringMaxRadius * eased;
      final double alpha  = 1.0 - progress;

      _ringGlowPaint.color = themeColor.withValues(alpha: alpha * 0.35);
      _ringGlowPaint.maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 12.0);
      _ringPaint.color     = themeColor.withValues(alpha: alpha);

      final Offset centre = Offset(playerPosition.x, playerPosition.y);
      canvas.drawCircle(centre, radius, _ringGlowPaint);
      canvas.drawCircle(centre, radius, _ringPaint);

      // Inner ring (half radius, slight delay)
      if (progress > 0.1) {
        final double ir  = _ringMaxRadius * 0.5 * eased;
        final double ia  = (1.0 - progress) * 0.6;
        _ringPaint.color = Colors.white.withValues(alpha: ia);
        canvas.drawCircle(centre, ir, _ringPaint);
      }
    }

    // ── Burst particles ───────────────────────────────────────────────
    if (_t >= _particleStart) {
      for (final _LevelParticle p in _particles) {
        if (!p.active) continue;
        if (p.age >= p.life) continue;

        final double progress = p.age / p.life;
        final double alpha    = (1.0 - progress) * 0.9;
        final double r        = p.size * (1.0 - progress * 0.5);

        if (r < 0.3 || alpha <= 0) continue;

        // Alternating particle colours: theme color and white.
        final Color c = _particles.indexOf(p).isEven
            ? themeColor.withValues(alpha: alpha)
            : Colors.white.withValues(alpha: alpha);

        _particlePaint.color      = c;
        _particlePaint.maskFilter = null;
        canvas.drawCircle(Offset(p.x, p.y), r, _particlePaint);

        // Glow dot
        _particlePaint.color      = c.withValues(alpha: alpha * 0.4);
        _particlePaint.maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawCircle(Offset(p.x, p.y), r * 2.0, _particlePaint);
      }
    }
  }
}

final class _LevelParticle {
  _LevelParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
  });

  double x, y;
  double vx, vy;
  double size;
  double life;
  double age    = 0.0;
  bool   active = false;
}
