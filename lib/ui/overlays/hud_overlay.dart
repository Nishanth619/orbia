import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game_config.dart';
import '../../state/economy_provider.dart';
import '../../state/game_state_provider.dart';

class HudOverlay extends ConsumerStatefulWidget {
  const HudOverlay({super.key});

  @override
  ConsumerState<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends ConsumerState<HudOverlay>
    with SingleTickerProviderStateMixin {
  static const int _levelTarget = 3000;

  late final AnimationController _toastCtrl;
  late final Animation<double>   _toastAnim;
  String _toastText    = '';
  bool   _showingToast = false;

  @override
  void initState() {
    super.initState();
    _toastCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _toastAnim = CurvedAnimation(parent: _toastCtrl, curve: Curves.easeOut);
    _toastCtrl.addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        if (mounted) setState(() => _showingToast = false);
      }
    });
  }

  @override
  void dispose() {
    _toastCtrl.dispose();
    super.dispose();
  }

  void _triggerLevelUpToast(int level) {
    setState(() { _toastText = 'LEVEL $level'; _showingToast = true; });
    _toastCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final GameSessionState gameState = ref.watch(gameStateProvider);
    final int coins = ref.watch(
        economyProvider.select((e) => e.coinBalance));

    ref.listen<GameSessionState>(gameStateProvider, (prev, next) {
      if (next.justLeveledUp && next.level > (prev?.level ?? 1)) {
        _triggerLevelUpToast(next.level);
      }
    });

    return SafeArea(
      child: Stack(
        children: <Widget>[

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[

                // ── Left: LEVEL + dots + lives ──────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text('LEVEL',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        )),
                    Text('${gameState.score} / $_levelTarget',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 4),
                    // Progress dots
                    Row(children: List<Widget>.generate(5, (int i) {
                      final int prog = gameState.score % GameConfig.nodesPerLevel;
                      final bool filled = i < (prog * 5 ~/ GameConfig.nodesPerLevel);
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _Dot(filled: filled),
                      );
                    })),
                    const SizedBox(height: 8),
                    // Lives (heart icons)
                    _LivesRow(lives: gameState.lives),
                    // Shield indicator
                    if (gameState.shieldActive) ...<Widget>[
                      const SizedBox(height: 6),
                      const _ShieldIcon(),
                    ],
                  ],
                ),

                // ── Right: Level badge + CRYSTALS ───────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30, width: 1),
                      ),
                      child: Text('LVL ${gameState.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          )),
                    ),
                    const SizedBox(height: 4),
                    const Text('CRYSTALS',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        )),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Transform.rotate(
                          angle: 0.785,
                          child: Container(
                              width: 10, height: 10, color: Colors.white),
                        ),
                        const SizedBox(width: 6),
                        Text('$coins',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            )),
                      ],
                    ),
                  ],
                ),

              ],
            ),
          ),

          // ── LEVEL UP toast ───────────────────────────────────────
          if (_showingToast)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _toastAnim,
                    builder: (_, __) {
                      final double t = _toastAnim.value;
                      double opacity;
                      if (t < 0.25) {
                        opacity = t / 0.25;
                      } else if (t < 0.70) {
                        opacity = 1.0;
                      } else {
                        opacity = 1.0 - (t - 0.70) / 0.30;
                      }

                      return Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Text('LEVEL UP!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  letterSpacing: 5,
                                  fontWeight: FontWeight.w400,
                                )),
                            Text(_toastText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 52,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4,
                                  shadows: <Shadow>[
                                    Shadow(color: Colors.white, blurRadius: 24),
                                  ],
                                )),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

        ],
      ),
    );
  }
}

// ── Lives row ─────────────────────────────────────────────────────────────────

class _LivesRow extends StatelessWidget {
  const _LivesRow({required this.lives});
  final int lives;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(GameConfig.startingLives, (int i) {
        final bool filled = i < lives;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            filled ? Icons.favorite : Icons.favorite_border,
            color: filled
                ? const Color(0xFFFF4466)
                : Colors.white24,
            size: 14,
            shadows: filled
                ? const <Shadow>[
                    Shadow(color: Color(0xFFFF4466), blurRadius: 6),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  const _Dot({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) => Container(
        width: 7, height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white54, width: 1.0),
        ),
      );
}

class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon();

  @override
  Widget build(BuildContext context) => Container(
        width: 26, height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFF00CFFF).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF00CFFF), width: 1.5),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF00CFFF).withValues(alpha: 0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(Icons.shield, size: 14, color: Color(0xFF00CFFF)),
      );
}
