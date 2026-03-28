import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_state_provider.dart';
import '../widgets/orbia_button.dart';

/// Standalone game-over screen (used when navigating outside game).
/// The in-game version uses GameOverOverlay.
class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameSessionState state = ref.watch(gameStateProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF2A0015), Color(0xFF7A0A00), Color(0xFFCC3300),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('GAME OVER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                    )),
                const SizedBox(height: 20),
                Text('SCORE  ${state.score}',
                    style: const TextStyle(
                      color: Colors.white70, fontSize: 22)),
                const SizedBox(height: 8),
                Text('BEST  ${state.highScore}',
                    style: const TextStyle(
                      color: Colors.white38, fontSize: 16)),
                const SizedBox(height: 48),
                OrbiaButton(
                  label: 'MENU',
                  onTap: () {
                    ref.read(gameStateProvider.notifier).returnToMenu();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
