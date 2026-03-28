import 'package:shared_preferences/shared_preferences.dart';

import '../models/player_save_data.dart';

const String _kSaveKey   = 'orbia_save_v2';
const String _kLegacyKey = 'orbia_save_v1';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateIfNeeded();
  }

  Future<void> _migrateIfNeeded() async {
    if (_prefs.containsKey(_kSaveKey)) return;
    final String? legacy = _prefs.getString(_kLegacyKey);
    if (legacy != null) {
      final PlayerSaveData migrated = PlayerSaveData.fromJson(legacy);
      await _prefs.setString(_kSaveKey, migrated.toJson());
      await _prefs.remove(_kLegacyKey);
    }
  }

  PlayerSaveData loadSave() {
    final String? raw = _prefs.getString(_kSaveKey);
    if (raw == null) return PlayerSaveData.initial();
    try { return PlayerSaveData.fromJson(raw); }
    catch (_) { return PlayerSaveData.initial(); }
  }

  Future<void> writeSave(PlayerSaveData data) async =>
      _prefs.setString(_kSaveKey, data.toJson());

  Future<void> updateHighScoreIfBeaten(int newScore) async {
    final PlayerSaveData s = loadSave();
    if (newScore > s.highScore) await writeSave(s.copyWith(highScore: newScore));
  }

  Future<void> addCoins(int amount) async {
    final PlayerSaveData s = loadSave();
    await writeSave(s.copyWith(
      coinBalance:          s.coinBalance + amount,
      totalCoinsEverEarned: s.totalCoinsEverEarned + amount,
    ));
  }

  Future<bool> spendCoins(int amount) async {
    final PlayerSaveData s = loadSave();
    if (s.coinBalance < amount) return false;
    await writeSave(s.copyWith(coinBalance: s.coinBalance - amount));
    return true;
  }

  Future<int> recordDeath() async {
    final PlayerSaveData s = loadSave();
    final int d = s.totalDeaths + 1;
    await writeSave(s.copyWith(totalDeaths: d, totalGamesPlayed: s.totalGamesPlayed + 1));
    return d;
  }

  Future<void> unlockSkin(String skinId) async {
    final PlayerSaveData s = loadSave();
    if (s.unlockedSkinIds.contains(skinId)) return;
    await writeSave(s.copyWith(
        unlockedSkinIds: <String>[...s.unlockedSkinIds, skinId]));
  }

  Future<void> selectSkin(String skinId) async {
    final PlayerSaveData s = loadSave();
    await writeSave(s.copyWith(selectedSkinId: skinId));
  }

  Future<void> unlockAchievement(String id) async {
    final PlayerSaveData s = loadSave();
    if (s.unlockedAchievementIds.contains(id)) return;
    await writeSave(s.copyWith(
        unlockedAchievementIds: <String>[...s.unlockedAchievementIds, id]));
  }

  bool isAchievementUnlocked(String id) =>
      loadSave().unlockedAchievementIds.contains(id);

  Future<void> recordDailyRewardClaimed(
      {required int epochMs, required int newStreakDay}) async {
    final PlayerSaveData s = loadSave();
    await writeSave(s.copyWith(
      lastDailyRewardEpochMs: epochMs,
      dailyStreakDay: newStreakDay,
    ));
  }

  Future<void> setAdsRemoved() async {
    final PlayerSaveData s = loadSave();
    await writeSave(s.copyWith(adsRemoved: true));
  }

  Future<void> nukeAllData() async {
    await _prefs.remove(_kSaveKey);
    await _prefs.remove(_kLegacyKey);
  }
}
