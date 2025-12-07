import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/models.dart';
import '../../providers/kanji_provider.dart';
import '../../utils/constants.dart';
import '../../utils/stroke_grader.dart';
import '../../widgets/kanji_canvas.dart';
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
  ConsumerState<StageCoordinatorScreen> createState() => _StageCoordinatorScreenState();
}

class _StageCoordinatorScreenState extends ConsumerState<StageCoordinatorScreen> {
  late GameCoordinator _coordinator;
  final GlobalKey<FieldScreenState> _fieldKey = GlobalKey<FieldScreenState>();
  final GlobalKey<KanjiCanvasState> _canvasKey = GlobalKey<KanjiCanvasState>();

  KanjiQuestion? _currentQuestion;
  bool _hasStrokes = false;

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
    });
  }

  void _handleAllDoorsCompleted() {
    // Transition to battle
    _coordinator.startBattle();
    setState(() {});
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
      _fieldKey.currentState?.onQuestionComplete(doorIndex, correct);
    }
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
      stageId: widget.stage.id.toString(),
      completedDoors: _coordinator.completedDoors,
      onDoorEnter: _handleDoorEnter,
      onAllDoorsCompleted: _handleAllDoorsCompleted,
    );
  }

  Widget _buildQuestionOverlay() {
    final question = _currentQuestion;
    if (question == null) return const SizedBox.shrink();

    // Use different layout for reading vs writing questions
    if (question.type == QuestionType.writing) {
      return _buildWritingQuestionScreen(question);
    } else {
      return _buildReadingQuestionScreen(question);
    }
  }

  Widget _buildReadingQuestionScreen(KanjiQuestion question) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
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
                'ドア ${_coordinator.activeDoorIndex + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                question.kanji.kanji,
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '意味: ${question.kanji.meaning}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'この漢字の読みは？',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ..._buildReadingChoices(question),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildReadingChoices(KanjiQuestion question) {
    return question.choices.map((choice) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final correct = choice == question.correctAnswer;
              _handleQuestionAnswer(correct);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              choice,
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

  Widget _buildWritingQuestionScreen(KanjiQuestion question) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF81C784), Color(0xFF2E7D32)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ドア ${_coordinator.activeDoorIndex + 1} - 書き問題',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Reading/meaning prompt
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      question.kanji.readings.first,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(${question.kanji.meaning})',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Instruction
              const Text(
                'この漢字を書いてください',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              // Canvas for writing
              LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final canvasSize = (screenWidth * 0.75).clamp(250.0, 350.0);
                  return KanjiCanvas(
                    key: _canvasKey,
                    size: canvasSize,
                    strokeWidth: 8.0,
                    onChanged: () {
                      setState(() {
                        _hasStrokes = _canvasKey.currentState?.hasStrokes ?? false;
                      });
                    },
                  );
                },
              ),

              const SizedBox(height: 16),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _canvasKey.currentState?.clear(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('やり直し'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _hasStrokes ? () => _checkWritingAnswer(question) : null,
                    icon: const Icon(Icons.check),
                    label: const Text('確認'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  void _checkWritingAnswer(KanjiQuestion question) {
    final canvasState = _canvasKey.currentState;
    final drawnStrokes = canvasState?.getStrokes() ?? <List<Offset>>[];

    final kanjiRepo = ref.read(kanjiRepositoryProvider);
    final template = kanjiRepo.getStrokeTemplate(question.kanji.kanji);

    bool correct;
    if (template != null) {
      final result = gradeWithResult(
        userStrokes: drawnStrokes,
        templateStrokes: template,
      );
      correct = result.passed;
    } else {
      // Fallback: accept if user drew something
      correct = drawnStrokes.isNotEmpty;
    }

    // Reset canvas state for next question
    _hasStrokes = false;

    _handleQuestionAnswer(correct);
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
