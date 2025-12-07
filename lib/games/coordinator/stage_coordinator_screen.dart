import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/constants.dart';
import '../field/field_game.dart';
import '../field/field_screen.dart';
import '../battle/battle_game.dart';
import '../battle/battle_screen.dart';
import 'game_coordinator.dart';

/// Integrated stage screen that coordinates field, question, and battle.
///
/// Flow:
/// 1. Field exploration - player walks around, enters doors
/// 2. Question screen - answer kanji question for each door
/// 3. Battle screen - fight boss after all doors completed
/// 4. Result screen - victory or defeat
class StageCoordinatorScreen extends StatefulWidget {
  const StageCoordinatorScreen({
    super.key,
    required this.stage,
    required this.questions,
    required this.onStageComplete,
  });

  /// Stage data
  final Stage stage;

  /// Pre-generated questions for each door
  final List<Question> questions;

  /// Callback when stage is complete
  final void Function(bool victory, int coinsEarned) onStageComplete;

  @override
  State<StageCoordinatorScreen> createState() => _StageCoordinatorScreenState();
}

class _StageCoordinatorScreenState extends State<StageCoordinatorScreen> {
  late GameCoordinator _coordinator;
  late FieldGame _fieldGame;
  final GlobalKey<FieldScreenState> _fieldKey = GlobalKey<FieldScreenState>();

  Question? _currentQuestion;

  @override
  void initState() {
    super.initState();
    _coordinator = GameCoordinator(
      stageId: widget.stage.id,
      totalDoors: widget.questions.length,
    );
    _initFieldGame();
  }

  void _initFieldGame() {
    _fieldGame = FieldGame(
      completedDoors: _coordinator.completedDoors,
      onDoorEnter: _handleDoorEnter,
    );
  }

  void _handleDoorEnter(int doorIndex) {
    if (doorIndex < 0 || doorIndex >= widget.questions.length) return;
    if (_coordinator.isDoorCompleted(doorIndex)) return;

    _coordinator.enterDoor(doorIndex);
    setState(() {
      _currentQuestion = widget.questions[doorIndex];
    });
  }

  void _handleQuestionAnswer(bool correct) {
    final doorIndex = _coordinator.activeDoorIndex;
    _coordinator.completeDoor(doorIndex, correct);

    setState(() {
      _currentQuestion = null;
    });

    if (_coordinator.phase == GamePhase.battle) {
      // All doors completed, transition to battle
      setState(() {});
    } else {
      // Return to field with updated door state
      _fieldKey.currentState?.onQuestionComplete(correct);
    }
  }

  void _handleBattleEnd(BattleResult result) {
    final victory = result == BattleResult.victory;
    _coordinator.completeBattle(victory);
    widget.onStageComplete(victory, _coordinator.coinsEarned);
  }

  @override
  Widget build(BuildContext context) {
    switch (_coordinator.phase) {
      case GamePhase.field:
        return _buildFieldScreen();
      case GamePhase.question:
        return _buildQuestionOverlay();
      case GamePhase.battle:
        return _buildBattleScreen();
      case GamePhase.victory:
      case GamePhase.defeat:
        // These are handled by the parent via onStageComplete callback
        return const SizedBox.shrink();
    }
  }

  Widget _buildFieldScreen() {
    return FieldScreen(
      key: _fieldKey,
      game: _fieldGame,
      completedDoors: _coordinator.completedDoors,
    );
  }

  Widget _buildQuestionOverlay() {
    // Show field with question overlay
    return Stack(
      children: [
        // Field in background (paused)
        IgnorePointer(
          child: GameWidget(game: _fieldGame),
        ),
        // Question overlay
        _buildQuestionCard(),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final question = _currentQuestion;
    if (question == null) return const SizedBox.shrink();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Door ${_coordinator.activeDoorIndex + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                question.kanji.character,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                question.prompt,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ..._buildAnswerButtons(question),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnswerButtons(Question question) {
    return question.options.map((option) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final correct = option == question.correctAnswer;
              _handleQuestionAnswer(correct);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }).toList();
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
