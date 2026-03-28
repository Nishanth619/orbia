import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game_config.dart';
import '../../state/economy_provider.dart';
import '../../state/game_state_provider.dart';

class HudOverlay extends ConsumerWidget {
  const HudOverlay({super.key});

  static const int _levelTarget = 3000;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int score = ref.watch(gameStateProvider.select((s) => s.score));
    final bool shieldActive =
        ref.watch(gameStateProvider.select((s) => s.shieldActive));
    final int coins = ref.watch(economyProvider.select((e) => e.coinBalance));

    final int dotsPerLevel =
        (GameConfig.nodesPerLevel / 5).round().clamp(1, 999);
    final int progressInLevel = score % GameConfig.nodesPerLevel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'LEVEL',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$score / $_levelTarget',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List<Widget>.generate(5, (int i) {
                    final bool filled = i < (progressInLevel ~/ dotsPerLevel);
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _Dot(filled: filled),
                    );
                  }),
                ),
                if (shieldActive) ...<Widget>[
                  const SizedBox(height: 8),
                  const _ShieldIcon(active: true),
                ],
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'CRYSTALS',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Transform.rotate(
                      angle: 0.785,
                      child:
                          Container(width: 10, height: 10, color: Colors.white),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$coins',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white54, width: 1.0),
        ),
      );
}

class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF00CFFF).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: active ? const Color(0xFF00CFFF) : Colors.white24,
          width: 1.5,
        ),
        boxShadow: active
            ? <BoxShadow>[
                BoxShadow(
                  color: const Color(0xFF00CFFF).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.shield,
        size: 16,
        color: active ? const Color(0xFF00CFFF) : Colors.white24,
      ),
    );
  }
}
