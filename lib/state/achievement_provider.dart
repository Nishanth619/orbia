import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement_model.dart';
import '../models/player_save_data.dart';
import '../services/storage_service.dart';
import 'economy_provider.dart';
import 'skin_provider.dart';

final class AchievementProgress {
  const AchievementProgress({
    required this.model,
    required this.isUnlocked,
    required this.currentValue,
  });

  final AchievementModel model;
  final bool             isUnlocked;
  final int              currentValue;

  double get progressFraction =>
      (currentValue / model.targetValue).clamp(0.0, 1.0);
}

final class AchievementState {
  const AchievementState({required this.achievements});

  factory AchievementState.fromSave(PlayerSaveData save) => AchievementState(
        achievements: AchievementCatalogue.all
            .map((AchievementModel m) => AchievementProgress(
                  model:        m,
                  isUnlocked:   save.unlockedAchievementIds.contains(m.id),
                  currentValue: _valueFor(m.id, save),
                ))
            .toList(growable: false),
      );

  final List<AchievementProgress> achievements;

  bool isUnlocked(String id) =>
      achievements.any((AchievementProgress a) => a.model.id == id && a.isUnlocked);

  static int _valueFor(String id, PlayerSaveData s) => switch (id) {
        'first_hop'      => s.highScore >= 1 ? 1 : 0,
        'speed_demon'    => s.highScore.clamp(0, 25),
        'untouchable'    => s.highScore.clamp(0, 50),
        'coin_collector' => s.totalCoinsEverEarned.clamp(0, 100),
        'shopaholic'     => s.unlockedSkinIds.length > 1 ? 1 : 0,
        'survivor'       => s.totalGamesPlayed.clamp(0, 10),
        'streak_3'       => s.dailyStreakDay.clamp(0, 3),
        'streak_7'       => s.dailyStreakDay.clamp(0, 7),
        _                => 0,
      };
}

class AchievementNotifier extends StateNotifier<AchievementState> {
  AchievementNotifier(this._ref)
      : super(AchievementState.fromSave(StorageService.instance.loadSave()));

  final Ref _ref;

  Future<void> checkAfterRun(
      {required int runScore, required int totalGamesPlayed}) async {
    await _check('first_hop',   runScore >= 1);
    await _check('speed_demon', runScore >= 25);
    await _check('untouchable', runScore >= 50);
    await _check('survivor',    totalGamesPlayed >= 10);
  }

  Future<void> checkCoins(int totalCoinsEverEarned) async {
    await _check('coin_collector', totalCoinsEverEarned >= 100);
  }

  Future<void> checkShopPurchase(int ownedCount) async {
    await _check('shopaholic', ownedCount > 1);
  }

  Future<void> checkStreak(int streakDay) async {
    await _check('streak_3', streakDay >= 3);
    await _check('streak_7', streakDay >= 7);
  }

  Future<void> _check(String id, bool condition) async {
    if (!condition || state.isUnlocked(id)) return;
    final AchievementModel? model = AchievementCatalogue.findById(id);
    if (model == null) return;
    await StorageService.instance.unlockAchievement(id);
    await _ref.read(economyProvider.notifier).addCoins(model.coinReward);
    if (model.unlockedSkinId != null) {
      await StorageService.instance.unlockSkin(model.unlockedSkinId!);
      await _ref.read(skinProvider.notifier).forceUnlock(model.unlockedSkinId!);
    }
    state = AchievementState.fromSave(StorageService.instance.loadSave());
  }
}

final StateNotifierProvider<AchievementNotifier, AchievementState>
    achievementProvider =
    StateNotifierProvider<AchievementNotifier, AchievementState>(
        (ref) => AchievementNotifier(ref));
