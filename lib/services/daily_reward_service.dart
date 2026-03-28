import '../models/game_config.dart';
import '../models/player_save_data.dart';
import 'storage_service.dart';

final class DailyRewardResult {
  const DailyRewardResult({
    required this.canClaim,
    required this.streakDay,
    required this.coinsReward,
    required this.hoursUntilNext,
    required this.isStreakReset,
  });

  final bool   canClaim;
  final int    streakDay;
  final int    coinsReward;
  final double hoursUntilNext;
  final bool   isStreakReset;
}

class DailyRewardService {
  DailyRewardService._();
  static final DailyRewardService instance = DailyRewardService._();

  DailyRewardResult checkStatus() =>
      _compute(StorageService.instance.loadSave(), DateTime.now());

  Future<DailyRewardResult> claimReward() async {
    final PlayerSaveData    save   = StorageService.instance.loadSave();
    final DateTime          now    = DateTime.now();
    final DailyRewardResult result = _compute(save, now);
    if (!result.canClaim) return result;
    await StorageService.instance.recordDailyRewardClaimed(
      epochMs: now.millisecondsSinceEpoch, newStreakDay: result.streakDay);
    await StorageService.instance.addCoins(result.coinsReward);
    return result;
  }

  DailyRewardResult _compute(PlayerSaveData save, DateTime now) {
    final int lastMs = save.lastDailyRewardEpochMs;
    if (lastMs == 0) {
      return DailyRewardResult(canClaim: true, streakDay: 1,
          coinsReward: GameConfig.dailyRewardSchedule[0],
          hoursUntilNext: 0, isStreakReset: false);
    }
    final double hoursSince =
        now.difference(DateTime.fromMillisecondsSinceEpoch(lastMs))
            .inMinutes / 60.0;
    if (hoursSince < GameConfig.dailyRewardCooldownHours) {
      return DailyRewardResult(canClaim: false,
          streakDay: save.dailyStreakDay,
          coinsReward: _coinsForDay(save.dailyStreakDay),
          hoursUntilNext: GameConfig.dailyRewardCooldownHours - hoursSince,
          isStreakReset: false);
    }
    final bool streakBroken =
        hoursSince >= GameConfig.dailyRewardStreakResetDays * 24;
    final int nextDay = streakBroken ? 1 : (save.dailyStreakDay % 7) + 1;
    return DailyRewardResult(canClaim: true, streakDay: nextDay,
        coinsReward: _coinsForDay(nextDay), hoursUntilNext: 0,
        isStreakReset: streakBroken && save.dailyStreakDay > 0);
  }

  int _coinsForDay(int day) {
    if (day <= 0) return GameConfig.dailyRewardSchedule[0];
    return GameConfig.dailyRewardSchedule[(day - 1) %
        GameConfig.dailyRewardSchedule.length];
  }
}
