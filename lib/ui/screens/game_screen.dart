import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/orbia_game.dart';
import '../../state/game_state_provider.dart';
import '../overlays/game_over_overlay.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/level_complete_overlay.dart';
import '../overlays/pause_overlay.dart';

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
    _game = OrbiaGame(ref: ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameStateProvider.notifier).startGame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final GameSessionState state = ref.watch(gameStateProvider);
    final GamePhase phase = state.phase;
    final bool showLevelComplete = state.showLevelComplete;

    return Scaffold(
      backgroundColor: const Color(0xFF2A0015),
      body: Stack(
        children: <Widget>[

          // ── Flame canvas ────────────────────────────────────────────
          // Always present — game loop runs even during level complete
          // (the Flame effect still needs to render).
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            // Only accept taps during active play (not during level anim).
            onTapDown: (!showLevelComplete &&
                    (phase == GamePhase.playing ||
                        phase == GamePhase.dashing))
                ? (_) => _game.handleTap()
                : null,
            child: GameWidget<OrbiaGame>(game: _game),
          ),

          // ── LEVEL COMPLETE overlay ───────────────────────────────────
          // Full-screen animated overlay — shown on level up.
          if (showLevelComplete)
            const LevelCompleteOverlay(),

          // ── Pause button (not during level complete) ─────────────────
          if (!showLevelComplete &&
              (phase == GamePhase.playing || phase == GamePhase.dashing))
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

          // ── HUD ──────────────────────────────────────────────────────
          if (!showLevelComplete &&
              (phase == GamePhase.playing || phase == GamePhase.dashing))
            const HudOverlay(),

          // ── Pause overlay ─────────────────────────────────────────────
          if (!showLevelComplete && phase == GamePhase.paused)
            PauseOverlay(onResume: _game.resumeGame),

          // ── Game over overlay ─────────────────────────────────────────
          if (phase == GamePhase.gameOver)
            GameOverOverlay(onRestart: _game.restartGame),

        ],
      ),
    );
  }
}
