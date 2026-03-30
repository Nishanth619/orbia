import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/audio_service.dart';
import '../state/game_state_provider.dart';
import 'world/game_world.dart';

/// Root FlameGame.
///
/// - CameraComponent follows the player upward (world scrolls).
/// - TapCallbacks routes ALL taps to GameWorld.onTap().
///   The world always dashes to _nextNode — tap position is irrelevant.
/// - Input guard is inside Player.dashToward() — double-taps ignored.
final class OrbiaGame extends FlameGame with TapCallbacks {
  OrbiaGame({required this.ref});

  final WidgetRef ref;
  late final GameWorld _world;

  @override
  Color backgroundColor() => const Color(0xFF2A0015);

  @override
  Future<void> onLoad() async {
    // canvasSize is guaranteed to be non-zero once the GameWidget is
    // laid out; use it instead of size which may still be Vector2.zero()
    // at onLoad() time on some devices.
    final double w = canvasSize.x > 0 ? canvasSize.x : 390;
    final double h = canvasSize.y > 0 ? canvasSize.y : 844;
    final Vector2 screenSize = Vector2(w, h);

    // Fixed-resolution camera — maintains aspect ratio on all devices.
    camera = CameraComponent.withFixedResolution(
      width: w,
      height: h,
    );
    camera.viewfinder.anchor = Anchor.center;

    _world = GameWorld(
      ref: ref,
      screenSize: screenSize,
      camera: camera,
    );

    await add(_world);
    await add(camera);
    camera.world = _world;

    await AudioService.instance.playBackgroundMusic();

    _world.startGame();
  }

  @override
  void onRemove() {
    AudioService.instance.stopBackgroundMusic();
    super.onRemove();
  }

  // ── Input ─────────────────────────────────────────────────────────────

  @override
  void onTapDown(TapDownEvent event) {
    final GamePhase phase = ref.read(gameStateProvider).phase;
    if (phase != GamePhase.playing && phase != GamePhase.dashing) return;
    AudioService.instance.playTap();
    _world.onTap();
  }

  // ── Controls ──────────────────────────────────────────────────────────

  void pauseGame() {
    pauseEngine();
    ref.read(gameStateProvider.notifier).pause();
    AudioService.instance.pauseBackgroundMusic();
  }

  void resumeGame() {
    resumeEngine();
    ref.read(gameStateProvider.notifier).resume();
    AudioService.instance.resumeBackgroundMusic();
  }

  void restartGame() {
    _world.startGame();
  }

  void handleTap() {
    final GamePhase phase = ref.read(gameStateProvider).phase;
    if (phase != GamePhase.playing && phase != GamePhase.dashing) {
      return;
    }
    AudioService.instance.playTap();
    _world.onTap();
  }
}
