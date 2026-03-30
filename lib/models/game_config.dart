abstract final class GameConfig {

  // ── Player ────────────────────────────────────────────────────────────
  static const double playerBaseSpeed       = 420.0;
  static const double playerBaseRadius      = 18.0;
  static const double deathFreezeSeconds    = 0.10;

  // ── Lives / respawn ───────────────────────────────────────────────────
  static const int    startingLives         = 3;
  /// Duration of the respawn flash effect (seconds).
  static const double respawnFlashDuration  = 0.6;
  /// Brief invincibility window after respawn (seconds).
  static const double respawnInvincibleTime = 1.5;

  // ── Node visual sizes ─────────────────────────────────────────────────
  static const double currentNodeRadius     = 72.0;
  static const double nextNodeRadius        = 38.0;
  static const double nodeStrokeWidth       = 2.5;
  static const double scoreInsideNodeSize   = 68.0;

  // ── Obstacles — PLAYABILITY GUARANTEED ───────────────────────────────
  static const double obstacleBaseOmega     = 1.2;

  /// HARD CAP: max 5 obstacles. At 5 with orbitRadius=100 the gap is
  /// 54wu — just enough for player (36wu diameter) + 18wu margin.
  static const int    maxObstaclesPerNode   = 5;

  /// Orbit radius GROWS with obstacle count to maintain playable gaps.
  /// count=2 → 80wu,  count=3 → 80wu,
  /// count=4 → 92wu,  count=5 → 105wu
  static const List<double> orbitRadiusByCount = <double>[
    0,    // index 0 unused
    80,   // 1 obstacle
    80,   // 2 obstacles
    80,   // 3 obstacles
    92,   // 4 obstacles
    105,  // 5 obstacles
  ];
  static const double obstacleOrbitRadiusBase = 80.0;

  /// Obstacle sizes — kept smaller to guarantee gaps.
  static const double obstacleRadiusSmall   = 20.0;
  static const double obstacleRadiusMedium  = 28.0;
  static const double obstacleRadiusLarge   = 36.0;

  /// Hard cap on angular velocity — 3.0 rad/s is fast but still readable.
  static const double maxOmega              = 3.0;
  static const double omegaPerNodeIncrement = 0.025; // slower ramp

  // ── Obstacle fall physics ─────────────────────────────────────────────
  static const double fallGravity           = 900.0;
  static const double fallInitialSpeedY     = 60.0;
  static const double fallSpreadX           = 120.0;

  // ── Shield power-up ───────────────────────────────────────────────────
  static const int    shieldSpawnEveryNNodes = 4;
  static const double shieldPickupRadius     = 26.0;
  static const double shieldDurationSeconds  = 10.0;
  static const double shieldBreakDuration    = 0.35;

  // ── Level / difficulty ────────────────────────────────────────────────
  static const int    nodesPerLevel         = 10;
  static const int    difficultyStepNodes   = 5;

  // ── Node layout ───────────────────────────────────────────────────────
  static const double nodeVerticalStep          = -240.0;
  static const double nodeMaxHorizontalOffset   = 100.0;

  // ── Camera ────────────────────────────────────────────────────────────
  static const double cameraLerpSpeed  = 3.0;
  static const double cameraLeadOffset = 140.0;

  // ── Sparkle trail ─────────────────────────────────────────────────────
  static const int    sparklePoolSize       = 40;
  static const double sparkleLifetime       = 0.35;
  static const double sparkleSpawnInterval  = 0.018;
  static const double sparkleMaxRadius      = 4.5;
  static const double sparkleSpread         = 14.0;

  // ── Visual / feedback ─────────────────────────────────────────────────
  static const double glowBlurSigma       = 12.0;
  static const int    deathParticleCount  = 28;
  static const double scoreFlashDuration  = 0.28;
  static const double deathShakeMagnitude = 7.0;
  static const double deathShakeDuration  = 0.30;

  // ── Object pool ───────────────────────────────────────────────────────
  static const int obstaclePoolSize = 24;
  static const int nodePoolSize     = 8;

  // ── Economy ───────────────────────────────────────────────────────────
  static const int coinsPerNode             = 1;
  static const int coinsPerRewardedAd       = 25;
  static const int interstitialEveryNDeaths = 3;
  static const int minAchievementCoins      = 10;

  static const List<int> dailyRewardSchedule = <int>[10,15,20,25,30,40,75];
  static const int dailyRewardCooldownHours   = 20;
  static const int dailyRewardStreakResetDays = 2;

  static const int achievementCoinsFirstHop      = 10;
  static const int achievementCoinsSpeedDemon     = 25;
  static const int achievementCoinsCoinCollector  = 15;
  static const int achievementCoinsSurvivor       = 20;
  static const int achievementCoinsStreak3        = 30;
  static const int achievementCoinsStreak7        = 75;
  static const int achievementCoinsUntouchable    = 50;
  static const int achievementCoinsShopaholic     = 10;
}
