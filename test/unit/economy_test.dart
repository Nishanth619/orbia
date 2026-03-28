import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orbia_game/services/storage_service.dart';
import 'package:orbia_game/services/daily_reward_service.dart';
import 'package:orbia_game/models/game_config.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.instance.init();
    await StorageService.instance.nukeAllData();
  });

  group('Coin balance', () {
    test('starts at zero', () =>
        expect(StorageService.instance.loadSave().coinBalance, 0));

    test('addCoins increases balance', () async {
      await StorageService.instance.addCoins(50);
      expect(StorageService.instance.loadSave().coinBalance, 50);
    });

    test('addCoins tracks lifetime total', () async {
      await StorageService.instance.addCoins(30);
      await StorageService.instance.addCoins(20);
      expect(StorageService.instance.loadSave().totalCoinsEverEarned, 50);
    });

    test('spendCoins deducts balance', () async {
      await StorageService.instance.addCoins(100);
      final bool ok = await StorageService.instance.spendCoins(40);
      expect(ok, isTrue);
      expect(StorageService.instance.loadSave().coinBalance, 60);
    });

    test('spendCoins returns false when insufficient', () async {
      await StorageService.instance.addCoins(10);
      final bool ok = await StorageService.instance.spendCoins(50);
      expect(ok, isFalse);
      expect(StorageService.instance.loadSave().coinBalance, 10);
    });
  });

  group('High score', () {
    test('updates when beaten', () async {
      await StorageService.instance.updateHighScoreIfBeaten(42);
      expect(StorageService.instance.loadSave().highScore, 42);
    });

    test('does not update when lower', () async {
      await StorageService.instance.updateHighScoreIfBeaten(42);
      await StorageService.instance.updateHighScoreIfBeaten(10);
      expect(StorageService.instance.loadSave().highScore, 42);
    });
  });

  group('Skins', () {
    test('default unlocked on first save', () =>
        expect(StorageService.instance.loadSave().unlockedSkinIds,
            contains('default')));

    test('unlockSkin adds to list', () async {
      await StorageService.instance.unlockSkin('ghost');
      expect(StorageService.instance.loadSave().unlockedSkinIds,
          contains('ghost'));
    });

    test('unlockSkin is idempotent', () async {
      await StorageService.instance.unlockSkin('ghost');
      await StorageService.instance.unlockSkin('ghost');
      final List<String> ids =
          StorageService.instance.loadSave().unlockedSkinIds;
      expect(ids.where((String s) => s == 'ghost').length, 1);
    });
  });

  group('Daily reward', () {
    test('can claim on first launch', () {
      final result = DailyRewardService.instance.checkStatus();
      expect(result.canClaim, isTrue);
      expect(result.streakDay, 1);
      expect(result.coinsReward, GameConfig.dailyRewardSchedule[0]);
    });

    test('claim awards coins', () async {
      await DailyRewardService.instance.claimReward();
      expect(StorageService.instance.loadSave().coinBalance,
          GameConfig.dailyRewardSchedule[0]);
    });

    test('cannot claim twice in same window', () async {
      await DailyRewardService.instance.claimReward();
      final result = DailyRewardService.instance.checkStatus();
      expect(result.canClaim, isFalse);
      expect(result.hoursUntilNext, greaterThan(0));
    });

    test('schedule has 7 entries', () =>
        expect(GameConfig.dailyRewardSchedule.length, 7));
  });

  group('Achievements', () {
    test('unlockAchievement persists', () async {
      await StorageService.instance.unlockAchievement('first_hop');
      expect(StorageService.instance.loadSave().unlockedAchievementIds,
          contains('first_hop'));
    });

    test('isAchievementUnlocked correct', () async {
      await StorageService.instance.unlockAchievement('speed_demon');
      expect(StorageService.instance.isAchievementUnlocked('speed_demon'),
          isTrue);
      expect(StorageService.instance.isAchievementUnlocked('untouchable'),
          isFalse);
    });
  });
}
