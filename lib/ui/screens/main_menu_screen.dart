import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/economy_provider.dart';
import '../../state/game_state_provider.dart';
import '../widgets/coin_display.dart';
import '../widgets/orbia_button.dart';
import 'game_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int highScore = ref.watch(
        gameStateProvider.select((GameSessionState s) => s.highScore));
    final int coins     = ref.watch(
        economyProvider.select((EconomyState e) => e.coinBalance));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: <Color>[Color(0xFF2A0015), Color(0xFF7A0A00), Color(0xFFCC3300)],
            stops: <double>[0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              // Crystal counter top-right
              Positioned(
                top: 12, right: 16,
                child: CoinDisplay(balance: coins),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('ORBIA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                        )),
                    const SizedBox(height: 8),
                    Text('BEST: $highScore',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 16,
                          letterSpacing: 3,
                        )),
                    const SizedBox(height: 60),
                    OrbiaButton(
                      label: 'PLAY',
                      onTap: () => Navigator.of(context).push<void>(
                        PageRouteBuilder<void>(
                          pageBuilder: (_, __, ___) => const GameScreen(),
                          transitionsBuilder: (_, Animation<double> a, __, Widget c) =>
                              FadeTransition(opacity: a, child: c),
                          transitionDuration:
                              const Duration(milliseconds: 350),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OrbiaButton(
                      label: 'SHOP',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                            builder: (_) => const ShopScreen()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OrbiaButton(
                      label: 'SETTINGS',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
