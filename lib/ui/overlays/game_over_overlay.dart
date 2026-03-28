import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_state_provider.dart';
import '../widgets/orbia_button.dart';

class GameOverOverlay extends ConsumerWidget {
  const GameOverOverlay({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GameSessionState gameState = ref.watch(gameStateProvider);

    return Container(
      color: Colors.black87,
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
            const SizedBox(height: 16),
            Text('SCORE  ${gameState.score}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  letterSpacing: 2,
                )),
            const SizedBox(height: 8),
            Text('BEST  ${gameState.highScore}',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 18,
                  letterSpacing: 2,
                )),
            const SizedBox(height: 48),
            OrbiaButton(
              label: 'PLAY AGAIN',
              onTap: () {
                ref.read(gameStateProvider.notifier).startGame();
                onRestart();
              },
            ),
            const SizedBox(height: 20),
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
    );
  }
}
