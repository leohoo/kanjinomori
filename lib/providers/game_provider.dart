import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'kanji_provider.dart';
import 'player_provider.dart';

enum GameScreen {
  home,
  stageSelect,
  stage,      // Legacy turn-based stage
  field,      // New 2.5D field exploration
  question,
  battle,
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

  Future<void> startStage(int stageId) async {
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
      currentScreen: GameScreen.stage,
      currentStage: stage,
      stageProgress: progress,
      isLoading: false,
    );
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
  void completeFieldStage(bool victory, int coinsEarned) {
    final stage = state.currentStage;
    if (stage == null) return;

    if (victory) {
      final playerNotifier = _ref.read(playerProvider.notifier);
      playerNotifier.addCoins(coinsEarned);
      playerNotifier.updateHighScore(stage.id, coinsEarned);

      // Unlock next stage
      if (stage.id < Stage.allStages.length) {
        playerNotifier.unlockStage(stage.id + 1);
      }

      state = state.copyWith(currentScreen: GameScreen.victory);
    } else {
      // Give partial coins on defeat
      if (coinsEarned > 0) {
        final playerNotifier = _ref.read(playerProvider.notifier);
        playerNotifier.addCoins(coinsEarned ~/ 2);
      }
      state = state.copyWith(currentScreen: GameScreen.defeat);
    }
  }

  void startQuestion() {
    state = state.copyWith(currentScreen: GameScreen.question);
  }

  void answerQuestion(bool correct) {
    final progress = state.stageProgress;
    if (progress == null) return;

    progress.answerQuestion(correct);

    if (progress.isComplete) {
      // All questions done, start boss battle
      _startBattle();
    } else {
      // Continue to next question or show stage screen for path choice
      state = state.copyWith(
        stageProgress: progress,
        currentScreen: GameScreen.stage,
      );
    }
  }

  void _startBattle() {
    final stage = state.currentStage;
    final progress = state.stageProgress;
    if (stage == null || progress == null) return;

    final playerNotifier = _ref.read(playerProvider.notifier);
    final weaponDamage = playerNotifier.getWeaponDamage();

    final battle = Battle(
      playerName: 'プレイヤー',
      playerHp: 100,
      playerDamage: 10 + weaponDamage,
      enemyName: stage.bossName,
      enemyHp: stage.bossHp,
      enemyDamage: stage.bossDamage,
      hasKanjiBonus: progress.correctAnswers > 5, // Bonus if >50% correct
    );

    battle.startBattle();

    state = state.copyWith(
      currentBattle: battle,
      currentScreen: GameScreen.battle,
    );
  }

  ActionResult playerBattleAction(BattleAction action) {
    final battle = state.currentBattle;
    if (battle == null) {
      return ActionResult(success: false, message: 'バトルがありません', damage: 0);
    }

    final result = battle.playerAction(action);

    if (battle.state == BattleState.victory) {
      _onBattleVictory();
    } else if (battle.state == BattleState.defeat) {
      _onBattleDefeat();
    } else {
      // Prepare enemy action
      battle.prepareEnemyAction();
    }

    state = state.copyWith(currentBattle: battle);
    return result;
  }

  ActionResult executeEnemyAction() {
    final battle = state.currentBattle;
    if (battle == null) {
      return ActionResult(success: false, message: 'バトルがありません', damage: 0);
    }

    final result = battle.enemyAction();

    if (battle.state == BattleState.victory) {
      _onBattleVictory();
    } else if (battle.state == BattleState.defeat) {
      _onBattleDefeat();
    } else {
      battle.nextTurn();
    }

    state = state.copyWith(currentBattle: battle);
    return result;
  }

  void _onBattleVictory() {
    final battle = state.currentBattle;
    final progress = state.stageProgress;
    final stage = state.currentStage;

    if (battle == null || progress == null || stage == null) return;

    final battleResult = battle.getResult();
    final totalCoins = progress.coinsEarned + battleResult.coinsEarned;

    // Award coins and unlock next stage
    final playerNotifier = _ref.read(playerProvider.notifier);
    playerNotifier.addCoins(totalCoins);
    playerNotifier.updateHighScore(stage.id, totalCoins);

    // Unlock next stage
    if (stage.id < Stage.allStages.length) {
      playerNotifier.unlockStage(stage.id + 1);
    }

    state = state.copyWith(currentScreen: GameScreen.victory);
  }

  void _onBattleDefeat() {
    // Give partial coins from questions
    final progress = state.stageProgress;
    if (progress != null && progress.coinsEarned > 0) {
      final playerNotifier = _ref.read(playerProvider.notifier);
      playerNotifier.addCoins(progress.coinsEarned ~/ 2); // Half coins on defeat
    }

    state = state.copyWith(currentScreen: GameScreen.defeat);
  }

  int getTotalCoinsEarned() {
    final progress = state.stageProgress;
    final battle = state.currentBattle;
    int total = 0;

    if (progress != null) {
      total += progress.coinsEarned;
    }
    if (battle != null && battle.state == BattleState.victory) {
      total += battle.getResult().coinsEarned;
    }

    return total;
  }
}

final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref);
});
