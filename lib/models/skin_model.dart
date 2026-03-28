import 'package:equatable/equatable.dart';

import 'game_config.dart';

enum SkinRarity { common, rare, epic, legendary }

final class SkinModel extends Equatable {
  const SkinModel({
    required this.id,
    required this.displayName,
    required this.description,
    required this.colorHex,
    required this.glowColorHex,
    required this.cost,
    required this.rarity,
    this.speedMultiplier        = 1.0,
    this.hitboxRadiusMultiplier = 1.0,
    this.coinMultiplier         = 1.0,
    this.isUnlockedByDefault    = false,
    this.unlockedByAchievementId,
  });

  final String   id;
  final String   displayName;
  final String   description;
  final int      colorHex;
  final int      glowColorHex;
  final int      cost;
  final SkinRarity rarity;
  final double   speedMultiplier;
  final double   hitboxRadiusMultiplier;
  final double   coinMultiplier;
  final bool     isUnlockedByDefault;
  final String?  unlockedByAchievementId;

  double get effectiveSpeed  =>
      GameConfig.playerBaseSpeed  * speedMultiplier;
  double get effectiveRadius =>
      GameConfig.playerBaseRadius * hitboxRadiusMultiplier;

  @override
  List<Object?> get props => <Object?>[
        id, speedMultiplier, hitboxRadiusMultiplier, coinMultiplier,
      ];
}

abstract final class SkinCatalogue {
  static const List<SkinModel> all = <SkinModel>[
    SkinModel(
      id: 'default', displayName: 'Orbia',
      description: 'The original.',
      colorHex: 0xFFFFFFFF, glowColorHex: 0xFFFFFFFF,
      cost: 0, rarity: SkinRarity.common, isUnlockedByDefault: true,
    ),
    SkinModel(
      id: 'ember', displayName: 'Ember',
      description: 'Warm orange energy.',
      colorHex: 0xFFFF6B35, glowColorHex: 0xFFFF4500,
      cost: 80, rarity: SkinRarity.common,
    ),
    SkinModel(
      id: 'magenta_pulse', displayName: 'Magenta Pulse',
      description: 'Slightly faster.',
      colorHex: 0xFFFF00FF, glowColorHex: 0xFFFF00FF,
      cost: 150, rarity: SkinRarity.rare, speedMultiplier: 1.12,
    ),
    SkinModel(
      id: 'ghost', displayName: 'Ghost',
      description: 'Smallest hitbox.',
      colorHex: 0xFFE0E0E0, glowColorHex: 0xFFFFFFFF,
      cost: 300, rarity: SkinRarity.epic,
      hitboxRadiusMultiplier: 0.78,
    ),
    SkinModel(
      id: 'golden_orbit', displayName: 'Golden Orbit',
      description: 'Double coins.',
      colorHex: 0xFFFFD700, glowColorHex: 0xFFFFA500,
      cost: 500, rarity: SkinRarity.legendary, coinMultiplier: 2.0,
    ),
    SkinModel(
      id: 'void_walker', displayName: 'Void Walker',
      description: 'Unlocked by 7-day streak.',
      colorHex: 0xFF2C0052, glowColorHex: 0xFF8800FF,
      cost: 0, rarity: SkinRarity.legendary,
      speedMultiplier: 1.15, hitboxRadiusMultiplier: 0.80,
      coinMultiplier: 1.5, unlockedByAchievementId: 'streak_7',
    ),
  ];

  static SkinModel? findById(String id) {
    try {
      return all.firstWhere((SkinModel s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
