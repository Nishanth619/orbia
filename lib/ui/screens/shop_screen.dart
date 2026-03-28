import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/skin_model.dart';
import '../../state/economy_provider.dart';
import '../../state/skin_provider.dart';
import '../widgets/coin_display.dart';
import '../widgets/skin_card.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SkinState    skins   = ref.watch(skinProvider);
    final EconomyState economy = ref.watch(economyProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end:   Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF2A0015), Color(0xFF7A0A00), Color(0xFFCC3300),
            ],
            stops: <double>[0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text('SHOP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          )),
                    ),
                    CoinDisplay(balance: economy.coinBalance),
                  ],
                ),
              ),

              // ── Skin grid ──────────────────────────────────────────
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:  2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing:  14,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: skins.allSkins.length,
                  itemBuilder: (BuildContext ctx, int i) {
                    final SkinModel skin = skins.allSkins[i];
                    return SkinCard(
                      skin:       skin,
                      isUnlocked: skins.isUnlocked(skin.id),
                      isSelected: skins.selectedId == skin.id,
                      onTap:      () => _onTap(ctx, ref, skin, skins),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    SkinModel skin,
    SkinState skins,
  ) async {
    if (skins.isUnlocked(skin.id)) {
      await ref.read(skinProvider.notifier).selectSkin(skin.id);
      return;
    }
    final bool ok =
        await ref.read(skinProvider.notifier).purchaseSkin(skin.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough crystals!'),
          backgroundColor: Color(0xFF3D0020),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
