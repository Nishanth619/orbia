import 'dart:math' as math;

import 'package:flame/components.dart';

import '../../models/game_config.dart';

/// Smooth camera that follows the player upward.
///
/// FLICKER FIX:
///   Old version updated _highestCameraY every frame which caused
///   the camera target to snap on arrival. Now _highestCameraY is
///   only updated when the player actually moves to a new higher point,
///   and lerpSpeed is reduced from 5.0 → 3.0 for smoother movement.
final class CameraController {
  CameraController({required this.camera, required this.screenSize});

  final CameraComponent camera;
  final Vector2 screenSize;

  double _shakeMagnitude = 0.0;
  double _shakeTimer = 0.0;
  bool _shaking = false;

  // Tracks the highest (most upward = lowest Y value) the camera
  // has reached. Only updated when player moves further up —
  // prevents camera snapping back down.
  double _highestCameraY = double.infinity;

  // Reduced from 5.0 → 3.0 — smoother follow, less snap on arrival.
  static const double _lerpSpeed = 3.0;

  static final math.Random _shakeRng = math.Random();

  void update(double dt, Vector2 playerPosition) {
    _updateFollow(dt, playerPosition);
    if (_shaking) _updateShake(dt);
  }

  void triggerShake() {
    _shakeMagnitude = GameConfig.deathShakeMagnitude;
    _shakeTimer = 0.0;
    _shaking = true;
  }

  void resetTo(Vector2 startPosition) {
    _highestCameraY = startPosition.y - GameConfig.cameraLeadOffset;
    _shaking = false;
    _shakeMagnitude = 0.0;
    camera.viewfinder.position = Vector2(screenSize.x / 2, _highestCameraY);
  }

  void _updateFollow(double dt, Vector2 playerPos) {
    // Target Y: player position shifted up by lead offset.
    final double desiredY = playerPos.y - GameConfig.cameraLeadOffset;

    // Only move camera UP (lower Y value), never back down.
    // KEY FIX: only update _highestCameraY when we actually
    // need to go further up — don't set it every frame.
    if (desiredY < _highestCameraY) {
      _highestCameraY = desiredY;
    }

    // Exponential lerp — framerate-independent, never overshoots.
    final double t = 1.0 - math.exp(-_lerpSpeed * dt);
    final Vector2 cur = camera.viewfinder.position;

    camera.viewfinder.position = Vector2(
      cur.x + (screenSize.x / 2.0 - cur.x) * t,
      cur.y + (_highestCameraY - cur.y) * t,
    );
  }

  void _updateShake(double dt) {
    _shakeTimer += dt;
    if (_shakeTimer >= GameConfig.deathShakeDuration) {
      _shaking = false;
      return;
    }
    final double decay = 1.0 - (_shakeTimer / GameConfig.deathShakeDuration);
    camera.viewfinder.position = Vector2(
      camera.viewfinder.position.x +
          (_shakeRng.nextDouble() - 0.5) * 2 * _shakeMagnitude * decay,
      camera.viewfinder.position.y +
          (_shakeRng.nextDouble() - 0.5) * 2 * _shakeMagnitude * decay,
    );
  }
}
