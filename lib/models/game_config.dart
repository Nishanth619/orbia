abstract final class GameConfig {
  static const double playerBaseSpeed = 420.0;
  static const double playerBaseRadius = 18.0;
  static const double deathFreezeSeconds = 0.10;

  static const double currentNodeRadius = 72.0;
  static const double nextNodeRadius = 38.0;
  static const double nodeStrokeWidth = 2.5;
  static const double scoreInsideNodeSize = 68.0;

  static const double obstacleBaseOmega = 1.2;
  static const double obstacleRadiusSmall = 22.0;
  static const double obstacleRadiusMedium = 32.0;
  static const double obstacleRadiusLarge = 44.0;
  static const double obstacleOrbitRadiusBase = 80.0;
  static const double maxOmega = 5.5;
  static const double omegaPerNodeIncrement = 0.04;
  static const int maxObstaclesPerNode = 7;

  static const double fallGravity = 900.0;
  static const double fallInitialSpeedY = 60.0;
  static const double fallSpreadX = 120.0;

  static const int shieldSpawnEveryNNodes = 4;
  static const double shieldPickupRadius = 26.0;
  static const double shieldDurationSeconds = 10.0;
  static const double shieldBreakDuration = 0.35;

  static const int nodesPerLevel = 10;
  static const int difficultyStepNodes = 5;

  static const double nodeVerticalStep = -240.0;
  static const double nodeMaxHorizontalOffset = 100.0;

  static const double cameraLerpSpeed = 3.0;
  static const double cameraLeadOffset = 140.0;

  static const int sparklePoolSize = 40;
  static const double sparkleLifetime = 0.35;
  static const double sparkleSpawnInterval = 0.018;
  static const double sparkleMaxRadius = 4.5;
  static const double sparkleSpread = 14.0;

  static const double glowBlurSigma = 12.0;
  static const int deathParticleCount = 28;
  static const double scoreFlashDuration = 0.28;
  static const double deathShakeMagnitude = 7.0;
  static const double deathShakeDuration = 0.30;

  static const int obstaclePoolSize = 30;
  static const int nodePoolSize = 8;

  static const int coinsPerNode = 1;
  static const int coinsPerRewardedAd = 25;
  static const int interstitialEveryNDeaths = 3;
  static const int minAchievementCoins = 10;

  static const List<int> dailyRewardSchedule = <int>[10, 15, 20, 25, 30, 40, 75];
  static const int dailyRewardCooldownHours = 20;
  static const int dailyRewardStreakResetDays = 2;

  static const int achievementCoinsFirstHop = 10;
  static const int achievementCoinsSpeedDemon = 25;
  static const int achievementCoinsCoinCollector = 15;
  static const int achievementCoinsSurvivor = 20;
  static const int achievementCoinsStreak3 = 30;
  static const int achievementCoinsStreak7 = 75;
  static const int achievementCoinsUntouchable = 50;
  static const int achievementCoinsShopaholic = 10;
}
