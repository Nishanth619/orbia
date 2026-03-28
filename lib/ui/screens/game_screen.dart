import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/orbia_game.dart';
import '../../state/game_state_provider.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/pause_overlay.dart';

/// Hosts the Flame GameWidget and all Flutter UI overlays.
/// The OrbiaGame instance is created once and survives rebuilds.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final OrbiaGame _game;

  @override
  void initState() {
    super.initState();
    // OrbiaGame.onLoad() drives all state transitions via _world.startGame()
    // → beginPlaying(). Do NOT call startGame() here — it would set phase to
    // 'countdown' and conflict with the 'playing' transition from onLoad().
    _game = OrbiaGame(ref: ref);
  }

  @override
  Widget build(BuildContext context) {
    final GamePhase phase = ref.watch(
      gameStateProvider.select((GameSessionState s) => s.phase),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF2A0015),
      body: Stack(
        children: <Widget>[

          // ── Flame canvas — fills entire screen ────────────────────
          GameWidget<OrbiaGame>(game: _game),

          // ── Pause button ──────────────────────────────────────────
          if (phase == GamePhase.playing || phase == GamePhase.dashing)
            Positioned(
              top: 48, left: 16,
              child: GestureDetector(
                onTap: _game.pauseGame,
                child: const Icon(
                  Icons.pause_circle_outline,
                  color: Color(0x88FFFFFF),
                  size: 30,
                ),
              ),
            ),

          // ── HUD ───────────────────────────────────────────────────
          if (phase == GamePhase.playing || phase == GamePhase.dashing)
            const HudOverlay(),

          // ── Pause overlay ─────────────────────────────────────────
          if (phase == GamePhase.paused)
            PauseOverlay(onResume: _game.resumeGame),

          // ── Game over overlay ─────────────────────────────────────
          if (phase == GamePhase.gameOver)
            GameOverOverlay(onRestart: _game.restartGame),

        ],
      ),
    );
  }
}
