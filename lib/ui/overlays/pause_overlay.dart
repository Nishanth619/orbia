import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/game_state_provider.dart';
import '../widgets/orbia_button.dart';

class PauseOverlay extends ConsumerWidget {
  const PauseOverlay({super.key, required this.onResume});

  final VoidCallback onResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('PAUSED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                )),
            const SizedBox(height: 40),
            OrbiaButton(label: 'RESUME', onTap: onResume),
            const SizedBox(height: 20),
            OrbiaButton(
              label: 'QUIT',
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
