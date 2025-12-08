import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'kanji_provider.dart';
import 'player_provider.dart';

enum GameScreen {
  home,
  stageSelect,
  field,      // New 2.5D field exploration
  victory,
  defeat,
  shop,
}

class GameState {
  final GameScreen currentScreen;
  final Stage? currentStage;
  final StageProgress? stageProgress;
  final Battle? currentBattle;
  final bool isLoading;

  const GameState({
    this.currentScreen = GameScreen.home,
    this.currentStage,
    this.stageProgress,
    this.currentBattle,
    this.isLoading = false,
  });

  GameState copyWith({
    GameScreen? currentScreen,
    Stage? currentStage,
    StageProgress? stageProgress,
    Battle? currentBattle,
    bool? isLoading,
  }) {
    return GameState(
      currentScreen: currentScreen ?? this.currentScreen,
      currentStage: currentStage ?? this.currentStage,
      stageProgress: stageProgress ?? this.stageProgress,
      currentBattle: currentBattle ?? this.currentBattle,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class GameNotifier extends StateNotifier<GameState> {
  final Ref _ref;

  GameNotifier(this._ref) : super(const GameState());

  void goToHome() {
    state = const GameState(currentScreen: GameScreen.home);
  }

  void goToStageSelect() {
    state = state.copyWith(currentScreen: GameScreen.stageSelect);
  }

  void goToShop() {
    state = state.copyWith(currentScreen: GameScreen.shop);
  }

  /// Start a stage with the new 2.5D field exploration mode.
  Future<void> startFieldStage(int stageId) async {
    final stage = Stage.getStage(stageId);
    if (stage == null) return;

    state = state.copyWith(isLoading: true);

    // Generate questions for this stage
    final kanjiRepo = _ref.read(kanjiRepositoryProvider);
    await kanjiRepo.loadKanji();
    await kanjiRepo.loadStrokes();
    final questions = kanjiRepo.generateQuestions(stage.grade, stage.questionCount);

    final progress = StageProgress(
      stageId: stageId,
      questions: questions,
    );

    state = GameState(
      currentScreen: GameScreen.field,
      currentStage: stage,
      stageProgress: progress,
      isLoading: false,
    );
  }

  /// Handle field stage completion
  void completeFieldStage(bool victory, int questionCoins, int battleCoins) {
    final stage = state.currentStage;
    if (stage == null) return;

    final totalCoins = questionCoins + battleCoins;

    // Sync coins to stageProgress so VictoryScreen/DefeatScreen can display them
    final progress = state.stageProgress;
    if (progress != null) {
      progress.coinsEarned = questionCoins; // Store question coins here
    }

    // Create a fake battle result to store battle coins for display
    final fakeBattle = Battle(
      playerName: 'Player',
      playerHp: 100,
      playerDamage: 10,
      enemyName: stage.bossName,
      enemyHp: 100,
      enemyDamage: 15,
    );
    // Hack: Store battle coins in the battle's turn count for display
    fakeBattle.turnCount = battleCoins;
    if (victory) {
      fakeBattle.state = BattleState.victory;
    }

    if (victory) {
      final playerNotifier = _ref.read(playerProvider.notifier);
      playerNotifier.addCoins(totalCoins);
      playerNotifier.updateHighScore(stage.id, totalCoins);

      // Unlock next stage
      if (stage.id < Stage.allStages.length) {
        playerNotifier.unlockStage(stage.id + 1);
      }

      state = state.copyWith(
        currentScreen: GameScreen.victory,
        currentBattle: fakeBattle,
      );
    } else {
      // Give partial coins on defeat
      if (totalCoins > 0) {
        final playerNotifier = _ref.read(playerProvider.notifier);
        playerNotifier.addCoins(totalCoins ~/ 2);
      }
      state = state.copyWith(currentScreen: GameScreen.defeat);
    }
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref);
});
