import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_config.dart';
import '../services/storage_service.dart';
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
    required this.justLeveledUp,
  });

  factory GameSessionState.initial(int storedHighScore) => GameSessionState(
        phase: GamePhase.menu, score: 0,
        highScore: storedHighScore, coinsEarnedThisRun: 0,
        shieldActive: false, level: 1, justLeveledUp: false,
      );

  final GamePhase phase;
  final int score;
  final int highScore;
  final int coinsEarnedThisRun;
  final bool shieldActive;
  final int level;
  final bool justLeveledUp;

  GameSessionState copyWith({
    GamePhase? phase, int? score, int? highScore,
    int? coinsEarnedThisRun, bool? shieldActive,
    int? level, bool? justLeveledUp,
  }) => GameSessionState(
        phase: phase ?? this.phase,
        score: score ?? this.score,
        highScore: highScore ?? this.highScore,
        coinsEarnedThisRun: coinsEarnedThisRun ?? this.coinsEarnedThisRun,
        shieldActive: shieldActive ?? this.shieldActive,
        level: level ?? this.level,
        justLeveledUp: justLeveledUp ?? this.justLeveledUp,
      );
}

class GameStateNotifier extends StateNotifier<GameSessionState> {
  GameStateNotifier(this._ref)
      : super(GameSessionState.initial(
            StorageService.instance.loadSave().highScore));

  final Ref _ref;

  void startGame() => state = state.copyWith(
      phase: GamePhase.countdown, score: 0,
      coinsEarnedThisRun: 0, shieldActive: false,
      level: 1, justLeveledUp: false);

  void beginPlaying() => state = state.copyWith(phase: GamePhase.playing);

  void pause() {
    if (state.phase == GamePhase.playing)
      state = state.copyWith(phase: GamePhase.paused);
  }

  void resume() {
    if (state.phase == GamePhase.paused)
      state = state.copyWith(phase: GamePhase.playing);
  }

  void returnToMenu() =>
      state = GameSessionState.initial(state.highScore);

  void nodeReached(int coinsEarned) {
    final int newScore = state.score + 1;
    final int newHigh = newScore > state.highScore ? newScore : state.highScore;
    final int newLevel = (newScore ~/ GameConfig.nodesPerLevel) + 1;
    state = state.copyWith(
      score: newScore,
      highScore: newHigh,
      coinsEarnedThisRun: state.coinsEarnedThisRun + coinsEarned,
      level: newLevel,
      justLeveledUp: false,
    );
  }

  void setLevelUp(int newLevel) {
    state = state.copyWith(level: newLevel, justLeveledUp: true);
    // Auto-clear after a short delay so HUD can read it once.
    Future<void>.delayed(const Duration(milliseconds: 100), () {
      if (mounted) state = state.copyWith(justLeveledUp: false);
    });
  }

  void setShieldActive(bool active) =>
      state = state.copyWith(shieldActive: active);

  Future<void> triggerGameOver() async {
    state = state.copyWith(phase: GamePhase.dying);
    await StorageService.instance.updateHighScoreIfBeaten(state.score);
    await StorageService.instance.addCoins(state.coinsEarnedThisRun);
    await StorageService.instance.recordDeath();
    _ref.read(economyProvider.notifier).refresh();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    state = state.copyWith(phase: GamePhase.gameOver);
  }
}

final StateNotifierProvider<GameStateNotifier, GameSessionState>
    gameStateProvider =
    StateNotifierProvider<GameStateNotifier, GameSessionState>(
  (ref) => GameStateNotifier(ref),
);
