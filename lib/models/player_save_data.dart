import 'dart:convert';

import 'package:equatable/equatable.dart';

final class PlayerSaveData extends Equatable {
  const PlayerSaveData({
    required this.highScore,
    required this.coinBalance,
    required this.unlockedSkinIds,
    required this.selectedSkinId,
    required this.totalDeaths,
    required this.totalGamesPlayed,
    required this.adsRemoved,
    required this.unlockedAchievementIds,
    required this.lastDailyRewardEpochMs,
    required this.dailyStreakDay,
    required this.totalCoinsEverEarned,
  });

  factory PlayerSaveData.initial() => const PlayerSaveData(
        highScore: 0,
        coinBalance: 0,
        unlockedSkinIds: <String>['default'],
        selectedSkinId: 'default',
        totalDeaths: 0,
        totalGamesPlayed: 0,
        adsRemoved: false,
        unlockedAchievementIds: <String>[],
        lastDailyRewardEpochMs: 0,
        dailyStreakDay: 0,
        totalCoinsEverEarned: 0,
      );

  factory PlayerSaveData.fromJson(String jsonString) {
    final Map<String, dynamic> m =
        jsonDecode(jsonString) as Map<String, dynamic>;
    return PlayerSaveData(
      highScore:    (m['highScore']    as num? ?? 0).toInt(),
      coinBalance:  (m['coinBalance']  as num? ?? 0).toInt(),
      unlockedSkinIds: List<String>.from(
          m['unlockedSkinIds'] as List<dynamic>? ?? <dynamic>['default']),
      selectedSkinId: m['selectedSkinId'] as String? ?? 'default',
      totalDeaths:      (m['totalDeaths']      as num? ?? 0).toInt(),
      totalGamesPlayed: (m['totalGamesPlayed'] as num? ?? 0).toInt(),
      adsRemoved:       m['adsRemoved']        as bool? ?? false,
      unlockedAchievementIds: List<String>.from(
          m['unlockedAchievementIds'] as List<dynamic>? ?? <dynamic>[]),
      lastDailyRewardEpochMs:
          (m['lastDailyRewardEpochMs'] as num? ?? 0).toInt(),
      dailyStreakDay:
          (m['dailyStreakDay'] as num? ?? 0).toInt(),
      totalCoinsEverEarned:
          (m['totalCoinsEverEarned'] as num? ?? 0).toInt(),
    );
  }

  final int    highScore;
  final int    coinBalance;
  final List<String> unlockedSkinIds;
  final String selectedSkinId;
  final int    totalDeaths;
  final int    totalGamesPlayed;
  final bool   adsRemoved;
  final List<String> unlockedAchievementIds;
  final int    lastDailyRewardEpochMs;
  final int    dailyStreakDay;
  final int    totalCoinsEverEarned;

  String toJson() => jsonEncode(<String, dynamic>{
        'highScore':              highScore,
        'coinBalance':            coinBalance,
        'unlockedSkinIds':        unlockedSkinIds,
        'selectedSkinId':         selectedSkinId,
        'totalDeaths':            totalDeaths,
        'totalGamesPlayed':       totalGamesPlayed,
        'adsRemoved':             adsRemoved,
        'unlockedAchievementIds': unlockedAchievementIds,
        'lastDailyRewardEpochMs': lastDailyRewardEpochMs,
        'dailyStreakDay':          dailyStreakDay,
        'totalCoinsEverEarned':   totalCoinsEverEarned,
      });

  PlayerSaveData copyWith({
    int?    highScore,
    int?    coinBalance,
    List<String>? unlockedSkinIds,
    String? selectedSkinId,
    int?    totalDeaths,
    int?    totalGamesPlayed,
    bool?   adsRemoved,
    List<String>? unlockedAchievementIds,
    int?    lastDailyRewardEpochMs,
    int?    dailyStreakDay,
    int?    totalCoinsEverEarned,
  }) => PlayerSaveData(
        highScore:              highScore              ?? this.highScore,
        coinBalance:            coinBalance            ?? this.coinBalance,
        unlockedSkinIds:        unlockedSkinIds        ?? this.unlockedSkinIds,
        selectedSkinId:         selectedSkinId         ?? this.selectedSkinId,
        totalDeaths:            totalDeaths            ?? this.totalDeaths,
        totalGamesPlayed:       totalGamesPlayed       ?? this.totalGamesPlayed,
        adsRemoved:             adsRemoved             ?? this.adsRemoved,
        unlockedAchievementIds: unlockedAchievementIds ?? this.unlockedAchievementIds,
        lastDailyRewardEpochMs: lastDailyRewardEpochMs ?? this.lastDailyRewardEpochMs,
        dailyStreakDay:          dailyStreakDay          ?? this.dailyStreakDay,
        totalCoinsEverEarned:   totalCoinsEverEarned   ?? this.totalCoinsEverEarned,
      );

  @override
  List<Object?> get props => <Object?>[
        highScore, coinBalance, unlockedSkinIds, selectedSkinId,
        totalDeaths, totalGamesPlayed, adsRemoved,
        unlockedAchievementIds, lastDailyRewardEpochMs,
        dailyStreakDay, totalCoinsEverEarned,
      ];
}
