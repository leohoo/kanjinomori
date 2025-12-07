import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../widgets/question_panel.dart';
import '../field/field_screen.dart';
import '../battle/battle_game.dart' as battle;
import '../battle/battle_screen.dart';
import 'game_coordinator.dart';

/// Integrated stage screen that coordinates field, question, and battle.
///
/// Flow:
/// 1. Field exploration - player walks around, enters doors
/// 2. Question screen - answer kanji question for each door
/// 3. Battle screen - fight boss after all doors completed
/// 4. Result screen - victory or defeat
class StageCoordinatorScreen extends ConsumerStatefulWidget {
  const StageCoordinatorScreen({
    super.key,
    required this.stage,
    required this.questions,
    required this.onStageComplete,
  });

  /// Stage data
  final Stage stage;

  /// Pre-generated questions for each door
  final List<KanjiQuestion> questions;

  /// Callback when stage is complete
  final void Function(bool victory, int coinsEarned) onStageComplete;

  @override
  ConsumerState<StageCoordinatorScreen> createState() =>
      _StageCoordinatorScreenState();
}

class _StageCoordinatorScreenState
    extends ConsumerState<StageCoordinatorScreen> {
  late GameCoordinator _coordinator;
  final GlobalKey<FieldScreenState> _fieldKey = GlobalKey<FieldScreenState>();

  KanjiQuestion? _currentQuestion;
  int _attemptNumber = 1;

  @override
  void initState() {
    super.initState();
    _coordinator = GameCoordinator(
      stageId: widget.stage.id,
      totalDoors: widget.questions.length,
    );
  }

  void _handleDoorEnter(int doorIndex) {
    if (doorIndex < 0 || doorIndex >= widget.questions.length) return;
    if (_coordinator.isDoorCompleted(doorIndex)) return;

    _coordinator.enterDoor(doorIndex);
    setState(() {
      _currentQuestion = widget.questions[doorIndex];
      _attemptNumber = 1;
    });
  }

  void _handleAllDoorsCompleted() {
    _coordinator.startBattle();
    setState(() {});
  }

  void _handleQuestionAnswer(bool correct) {
    final doorIndex = _coordinator.activeDoorIndex;
    _coordinator.completeDoor(doorIndex, correct);

    setState(() {
      _currentQuestion = null;
      _attemptNumber = 1;
    });

    if (_coordinator.phase == GamePhase.battle) {
      setState(() {});
    } else {
      _fieldKey.currentState?.onQuestionComplete(doorIndex, correct);
    }
  }

  void _handleRetry() {
    setState(() {
      _attemptNumber++;
    });
  }

  void _handleGiveUp() {
    _handleQuestionAnswer(false);
  }

  void _handleBattleEnd(battle.BattleResult result) {
    final victory = result == battle.BattleResult.victory;
    _coordinator.completeBattle(victory);
    widget.onStageComplete(victory, _coordinator.coinsEarned);
  }

  @override
  Widget build(BuildContext context) {
    switch (_coordinator.phase) {
      case GamePhase.field:
        return _buildFieldScreen();
      case GamePhase.question:
        return _buildQuestionScreen();
      case GamePhase.battle:
        return _buildBattleScreen();
      case GamePhase.victory:
      case GamePhase.defeat:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFieldScreen() {
    return FieldScreen(
      key: _fieldKey,
      stageId: widget.stage.id.toString(),
      completedDoors: _coordinator.completedDoors,
      onDoorEnter: _handleDoorEnter,
      onAllDoorsCompleted: _handleAllDoorsCompleted,
    );
  }

  Widget _buildQuestionScreen() {
    final question = _currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return QuestionPanel(
      key: ValueKey('question_${_coordinator.activeDoorIndex}_$_attemptNumber'),
      question: question,
      attemptNumber: _attemptNumber,
      doorNumber: _coordinator.activeDoorIndex + 1,
      onAnswer: _handleQuestionAnswer,
      onRetry: _handleRetry,
      onGiveUp: _handleGiveUp,
    );
  }

  Widget _buildBattleScreen() {
    return BattleScreen(
      stageId: widget.stage.id.toString(),
      enemyName: widget.stage.bossName,
      difficulty: _coordinator.difficulty,
      correctAnswerRatio: _coordinator.correctRatio,
      onBattleEnd: _handleBattleEnd,
    );
  }
}
