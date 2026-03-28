import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_config.dart';
import '../services/storage_service.dart';
import 'achievement_provider.dart';
import 'economy_provider.dart';

enum GamePhase { menu, countdown, playing, dashing, dying, gameOver, paused }

final class GameSessionState {
  const GameSessionState({
    required this.phase,
    required this.score,
    required this.highScore,
    required this.coinsEarnedThisRun,
    required this.shieldActive,
    required this.level,
  });

  factory GameSessionState.initial(int storedHighScore) => GameSessionState(
        phase: GamePhase.menu,
        score: 0,
        highScore: storedHighScore,
        coinsEarnedThisRun: 0,
        shieldActive: false,
        level: 1,
      );

  final GamePhase phase;
  final int score;
  final int highScore;
  final int coinsEarnedThisRun;
  final bool shieldActive;
  final int level;

  GameSessionState copyWith({
    GamePhase? phase,
    int? score,
    int? highScore,
    int? coinsEarnedThisRun,
    bool? shieldActive,
    int? level,
  }) =>
      GameSessionState(
        phase: phase ?? this.phase,
        score: score ?? this.score,
        highScore: highScore ?? this.highScore,
        coinsEarnedThisRun: coinsEarnedThisRun ?? this.coinsEarnedThisRun,
        shieldActive: shieldActive ?? this.shieldActive,
        level: level ?? this.level,
      );
}

class GameStateNotifier extends StateNotifier<GameSessionState> {
  GameStateNotifier(this._ref)
      : super(GameSessionState.initial(
          StorageService.instance.loadSave().highScore,
        ));

  final Ref _ref;

  void startGame() => state = state.copyWith(
        phase: GamePhase.countdown,
        score: 0,
        coinsEarnedThisRun: 0,
        shieldActive: false,
        level: 1,
      );

  void beginPlaying() => state = state.copyWith(phase: GamePhase.playing);

  void pause() {
    if (state.phase == GamePhase.playing) {
      state = state.copyWith(phase: GamePhase.paused);
    }
  }

  void resume() {
    if (state.phase == GamePhase.paused) {
      state = state.copyWith(phase: GamePhase.playing);
    }
  }

  void returnToMenu() => state = GameSessionState.initial(state.highScore);

  void nodeReached(int coinsEarned) {
    final int newScore = state.score + 1;
    final int newHighScore =
        newScore > state.highScore ? newScore : state.highScore;
    final int newLevel = (newScore ~/ GameConfig.nodesPerLevel) + 1;

    state = state.copyWith(
      score: newScore,
      highScore: newHighScore,
      coinsEarnedThisRun: state.coinsEarnedThisRun + coinsEarned,
      level: newLevel,
    );
  }

  void setShieldActive(bool active) {
    state = state.copyWith(shieldActive: active);
  }

  Future<void> triggerGameOver() async {
    state = state.copyWith(phase: GamePhase.dying);

    await StorageService.instance.updateHighScoreIfBeaten(state.score);
    await StorageService.instance.addCoins(state.coinsEarnedThisRun);
    await StorageService.instance.recordDeath();

    final int runScore = state.score;
    final save = StorageService.instance.loadSave();

    _ref.read(economyProvider.notifier).refresh();

    final achievementNotifier = _ref.read(achievementProvider.notifier);
    await achievementNotifier.checkAfterRun(
      runScore: runScore,
      totalGamesPlayed: save.totalGamesPlayed,
    );
    await achievementNotifier.checkCoins(save.totalCoinsEverEarned);

    await Future<void>.delayed(const Duration(milliseconds: 900));
    state = state.copyWith(phase: GamePhase.gameOver);
  }
}

final StateNotifierProvider<GameStateNotifier, GameSessionState>
    gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameSessionState>(
  (ref) => GameStateNotifier(ref),
);
