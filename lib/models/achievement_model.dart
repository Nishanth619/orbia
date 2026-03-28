import 'package:equatable/equatable.dart';

import 'game_config.dart';

enum AchievementCategory { gameplay, economy, social, collection }

final class AchievementModel extends Equatable {
  const AchievementModel({
    required this.id,
    required this.displayName,
    required this.description,
    required this.category,
    required this.coinReward,
    required this.targetValue,
    this.unlockedSkinId,
    this.isSecret = false,
  });

  final String              id;
  final String              displayName;
  final String              description;
  final AchievementCategory category;
  final int                 coinReward;
  final int                 targetValue;
  final String?             unlockedSkinId;
  final bool                isSecret;

  @override
  List<Object?> get props => <Object?>[id];
}

abstract final class AchievementCatalogue {
  static const List<AchievementModel> all = <AchievementModel>[
    AchievementModel(
      id: 'first_hop', displayName: 'First Hop',
      description: 'Reach your first node.',
      category: AchievementCategory.gameplay,
      coinReward: GameConfig.achievementCoinsFirstHop, targetValue: 1,
    ),
    AchievementModel(
      id: 'speed_demon', displayName: 'Speed Demon',
      description: 'Reach 25 nodes in one run.',
      category: AchievementCategory.gameplay,
      coinReward: GameConfig.achievementCoinsSpeedDemon, targetValue: 25,
    ),
    AchievementModel(
      id: 'untouchable', displayName: 'Untouchable',
      description: 'Reach 50 nodes without dying.',
      category: AchievementCategory.gameplay,
      coinReward: GameConfig.achievementCoinsUntouchable, targetValue: 50,
    ),
    AchievementModel(
      id: 'coin_collector', displayName: 'Coin Collector',
      description: 'Earn 100 coins lifetime.',
      category: AchievementCategory.economy,
      coinReward: GameConfig.achievementCoinsCoinCollector, targetValue: 100,
    ),
    AchievementModel(
      id: 'shopaholic', displayName: 'Shopaholic',
      description: 'Purchase your first skin.',
      category: AchievementCategory.collection,
      coinReward: GameConfig.achievementCoinsShopaholic, targetValue: 1,
    ),
    AchievementModel(
      id: 'survivor', displayName: 'Survivor',
      description: 'Play 10 games.',
      category: AchievementCategory.social,
      coinReward: GameConfig.achievementCoinsSurvivor, targetValue: 10,
    ),
    AchievementModel(
      id: 'streak_3', displayName: '3-Day Streak',
      description: 'Log in 3 days in a row.',
      category: AchievementCategory.social,
      coinReward: GameConfig.achievementCoinsStreak3, targetValue: 3,
    ),
    AchievementModel(
      id: 'streak_7', displayName: '7-Day Streak',
      description: 'Log in 7 days in a row.',
      category: AchievementCategory.social,
      coinReward: GameConfig.achievementCoinsStreak7, targetValue: 7,
      unlockedSkinId: 'void_walker',
    ),
  ];

  static AchievementModel? findById(String id) {
    try {
      return all.firstWhere((AchievementModel a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
