import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart' show Colors;

import '../../models/game_config.dart';
import '../managers/object_pool.dart';

enum NodeState { current, next, completed }

/// CURRENT → large white stroke ring + semi-transparent score inside
/// NEXT    → small white stroke ring + tiny centre dot
///
/// FLICKER FIX 1: promoteToCurrentWith() animates _ringRadius
///   smoothly over 0.15s — no instant size pop.
///
/// FLICKER FIX 2: startFadeOut() lets the old node fade its opacity
///   over 0.18s instead of disappearing in 1 frame, eliminating the
///   visual gap between old ring removal and new ring growth.
final class Node extends PositionComponent implements Poolable {
  Node() : super(anchor: Anchor.center);

  @override
  bool isActive = false;

  NodeState nodeState = NodeState.next;
  int scoreValue = 0;

  // Grow animation
  double _ringRadius = GameConfig.nextNodeRadius;
  double _targetRadius = GameConfig.nextNodeRadius;
  double _sourceRadius = GameConfig.nextNodeRadius;
  double _growTimer = 0.0;
  bool _growing = false;
  static const double _growDuration = 0.15;

  // Fade-out
  double _opacity = 1.0;
  bool _fadingOut = false;

  // Paints
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = GameConfig.nodeStrokeWidth
    ..color = Colors.white;

  final Paint _dotPaint = Paint()
    ..style = PaintingStyle.fill
    ..color = Colors.white;

  Paragraph? _scoreParagraph;
  int _lastBuiltScore = -1;
  Offset _center = Offset.zero;

  void configure({
    required Vector2 worldPosition,
    required NodeState initialState,
    required int score,
  }) {
    position = worldPosition;
    nodeState = initialState;
    scoreValue = score;
    _lastBuiltScore = -1;
    _growing = false;
    _fadingOut = false;
    _growTimer = 0.0;
    _opacity = 1.0;

    _ringRadius = initialState == NodeState.current
        ? GameConfig.currentNodeRadius
        : GameConfig.nextNodeRadius;
    _targetRadius = _ringRadius;
    _sourceRadius = _ringRadius;
    _applyRadius(_ringRadius);
  }

  /// Smoothly grows from small → large when player arrives.
  void promoteToCurrentWith(int score) {
    nodeState = NodeState.current;
    scoreValue = score;
    _lastBuiltScore = -1;
    _sourceRadius = _ringRadius;
    _targetRadius = GameConfig.currentNodeRadius;
    _growTimer = 0.0;
    _growing = true;
    _opacity = 1.0;
  }

  /// Called by GameWorld — fades this node out before pool release.
  /// Opacity goes 1.0 → 0.0 over [duration] seconds.
  void startFadeOut(double duration) {
    _fadingOut = true;
    // Store duration in growTimer field (reusing to avoid new field).
    _sourceRadius = duration; // repurpose as fade duration store
    _growTimer = 0.0;
    _growing = false;
  }

  void _applyRadius(double r) {
    final double d = r * 2.0 + 24.0;
    size = Vector2.all(d);
    _center = Offset(d / 2.0, d / 2.0);
  }

  @override
  void reset() {
    nodeState = NodeState.next;
    scoreValue = 0;
    isActive = false;
    _growing = false;
    _fadingOut = false;
    _growTimer = 0.0;
    _opacity = 1.0;
    _scoreParagraph = null;
    _lastBuiltScore = -1;
    _ringRadius = GameConfig.nextNodeRadius;
    _targetRadius = GameConfig.nextNodeRadius;
    _sourceRadius = GameConfig.nextNodeRadius;
  }

  void _buildScoreParagraph() {
    final ParagraphBuilder pb = ParagraphBuilder(
      ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: GameConfig.scoreInsideNodeSize,
        fontWeight: FontWeight.bold,
      ),
    )
      ..pushStyle(TextStyle(
        color: Colors.white.withValues(alpha: 0.18 * _opacity),
        fontSize: GameConfig.scoreInsideNodeSize,
        fontWeight: FontWeight.bold,
      ))
      ..addText(scoreValue.toString());

    _scoreParagraph = pb.build()
      ..layout(ParagraphConstraints(width: _ringRadius * 2.0));
    _lastBuiltScore = scoreValue;
  }

  @override
  void update(double dt) {
    // Grow animation
    if (_growing) {
      _growTimer += dt;
      final double t = (_growTimer / _growDuration).clamp(0.0, 1.0);
      final double eased = 1.0 - math.pow(1.0 - t, 3).toDouble();
      _ringRadius = _sourceRadius + (_targetRadius - _sourceRadius) * eased;
      _applyRadius(_ringRadius);
      if (t >= 1.0) {
        _ringRadius = _targetRadius;
        _applyRadius(_ringRadius);
        _growing = false;
      }
    }

    // Fade-out animation
    if (_fadingOut) {
      _growTimer += dt;
      // _sourceRadius was repurposed to store the fade duration
      final double fadeDuration = _sourceRadius;
      final double t = (_growTimer / fadeDuration).clamp(0.0, 1.0);
      _opacity = 1.0 - t;
    }
  }

  @override
  void render(Canvas canvas) {
    if (!isActive || nodeState == NodeState.completed) return;
    if (_opacity <= 0.0) return;

    // Apply opacity by saving canvas layer.
    // Only use saveLayer when fading — it's expensive.
    if (_fadingOut && _opacity < 1.0) {
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.x, size.y),
        Paint()..color = Colors.white.withValues(alpha: _opacity),
      );
    }

    // Ring
    canvas.drawCircle(_center, _ringRadius, _ringPaint);

    if (nodeState == NodeState.current) {
      if (scoreValue != _lastBuiltScore || _fadingOut) {
        _buildScoreParagraph();
      }
      if (_scoreParagraph != null) {
        canvas.drawParagraph(
          _scoreParagraph!,
          Offset(
            _center.dx - _ringRadius,
            _center.dy - GameConfig.scoreInsideNodeSize / 2.0,
          ),
        );
      }
      canvas.drawCircle(_center, 3.5, _dotPaint);
    } else {
      canvas.drawCircle(_center, 3.0, _dotPaint);
    }

    if (_fadingOut && _opacity < 1.0) {
      canvas.restore();
    }
  }
}
