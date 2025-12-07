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

class _StageCoordinatorScreenState extends ConsumerState<StageCoordinatorScreen>
    with SingleTickerProviderStateMixin {
  late GameCoordinator _coordinator;
  final GlobalKey<FieldScreenState> _fieldKey = GlobalKey<FieldScreenState>();
  final GlobalKey<KanjiCanvasState> _canvasKey = GlobalKey<KanjiCanvasState>();

  KanjiQuestion? _currentQuestion;
  bool _hasStrokes = false;

  // Feedback state
  bool _showingFeedback = false;
  bool _lastAnswerCorrect = false;
  String? _selectedAnswer;
  late AnimationController _feedbackAnimController;
  late Animation<double> _feedbackScaleAnimation;

  // Writing question state
  int _attemptNumber = 1;
  bool _showRetryOption = false;
  FailureReason? _failureReason;

  @override
  void initState() {
    super.initState();
    _coordinator = GameCoordinator(
      stageId: widget.stage.id,
      totalDoors: widget.questions.length,
    );

    _feedbackAnimController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _feedbackScaleAnimation = CurvedAnimation(
      parent: _feedbackAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _feedbackAnimController.dispose();
    super.dispose();
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

  void _handleQuestionAnswer(bool correct, {String? selectedAnswer}) {
    if (_showingFeedback) return;

    setState(() {
      _showingFeedback = true;
      _lastAnswerCorrect = correct;
      _selectedAnswer = selectedAnswer;
    });

    _feedbackAnimController.forward();

    // Show feedback for a moment before transitioning
    final feedbackDuration = correct
        ? const Duration(milliseconds: 1200)
        : const Duration(milliseconds: 1500);

    Future.delayed(feedbackDuration, () {
      if (!mounted) return;

      final doorIndex = _coordinator.activeDoorIndex;
      _coordinator.completeDoor(doorIndex, correct);

      setState(() {
        _showingFeedback = false;
        _lastAnswerCorrect = false;
        _selectedAnswer = null;
        _currentQuestion = null;
      });

      _feedbackAnimController.reset();

      if (_coordinator.phase == GamePhase.battle) {
        // All doors completed, transition to battle
        setState(() {});
      } else {
        // Return to field with updated door state
        _fieldKey.currentState?.onQuestionComplete(doorIndex, correct);
      }
    });
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
      backgroundColor: _showingFeedback
          ? (_lastAnswerCorrect
              ? Colors.green.withValues(alpha: 0.7)
              : Colors.red.withValues(alpha: 0.7))
          : Colors.black54,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
            // Feedback overlay
            if (_showingFeedback) ...[
              const SizedBox(height: 24),
              _buildFeedbackBanner(question),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReadingChoices(KanjiQuestion question) {
    return question.choices.map((choice) {
      final isSelected = _selectedAnswer == choice;
      final isCorrectChoice = choice == question.correctAnswer;

      Color bgColor;
      Color textColor = Colors.white;

      if (_showingFeedback) {
        if (isCorrectChoice) {
          bgColor = AppColors.success;
        } else if (isSelected && !_lastAnswerCorrect) {
          bgColor = AppColors.error;
        } else {
          bgColor = Colors.grey;
        }
      } else {
        bgColor = AppColors.primary;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showingFeedback
                ? null
                : () {
                    final correct = choice == question.correctAnswer;
                    _handleQuestionAnswer(correct, selectedAnswer: choice);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: bgColor,
              disabledBackgroundColor: bgColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              choice,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFeedbackBanner(KanjiQuestion question) {
    return AnimatedBuilder(
      animation: _feedbackScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _feedbackScaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _lastAnswerCorrect ? Icons.celebration : Icons.close,
                  color: _lastAnswerCorrect ? AppColors.success : AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  _lastAnswerCorrect ? '正解！' : '残念...',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _lastAnswerCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
                if (!_lastAnswerCorrect) ...[
                  const SizedBox(height: 8),
                  Text(
                    '正解: ${question.correctAnswer}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWritingQuestionScreen(KanjiQuestion question) {
    // Determine background gradient based on feedback state
    List<Color> gradientColors;
    if (_showingFeedback) {
      gradientColors = _lastAnswerCorrect
          ? [Colors.green.shade300, Colors.green.shade700]
          : [Colors.red.shade300, Colors.red.shade700];
    } else {
      gradientColors = [const Color(0xFF81C784), const Color(0xFF2E7D32)];
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
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

              // Show canvas or feedback
              if (!_showingFeedback) ...[
                // Instruction
                Text(
                  _attemptNumber == 1
                      ? 'この漢字を書いてください'
                      : 'もう一度書いてみよう',
                  style: const TextStyle(
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
              ] else ...[
                // Feedback display
                _buildWritingFeedback(question),
              ],

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWritingFeedback(KanjiQuestion question) {
    return AnimatedBuilder(
      animation: _feedbackScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _feedbackScaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Correct kanji display
                Text(
                  question.kanji.kanji,
                  style: TextStyle(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: _lastAnswerCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
                const SizedBox(height: 16),
                Icon(
                  _lastAnswerCorrect ? Icons.celebration : Icons.close,
                  color: _lastAnswerCorrect ? AppColors.success : AppColors.error,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  _lastAnswerCorrect ? '正解！' : '残念...',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: _lastAnswerCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
                // Show hint for failed attempt
                if (!_lastAnswerCorrect && _failureReason != null) ...[
                  const SizedBox(height: 12),
                  _buildFailureHint(_failureReason!),
                ],
                // Retry options
                if (_showRetryOption) ...[
                  const SizedBox(height: 16),
                  Text(
                    _attemptNumber == 1
                        ? 'もう一度挑戦しますか？'
                        : 'もう一度挑戦しますか？',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: _handleGiveUp,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('あきらめる'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _handleRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('もう一度'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFailureHint(FailureReason reason) {
    String hint;
    IconData icon;

    switch (reason) {
      case FailureReason.strokeCount:
        hint = '画数が違います';
        icon = Icons.format_list_numbered;
      case FailureReason.strokeOrder:
        hint = '筆順が違います';
        icon = Icons.swap_vert;
      case FailureReason.strokeShape:
        hint = '形が違います';
        icon = Icons.gesture;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Text(
            hint,
            style: TextStyle(
              color: Colors.orange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleRetry() {
    setState(() {
      _attemptNumber++;
      _showingFeedback = false;
      _showRetryOption = false;
      _failureReason = null;
      _hasStrokes = false;
    });
    _feedbackAnimController.reset();
    _canvasKey.currentState?.clear();
  }

  void _handleGiveUp() {
    _completeQuestion(false);
  }

  void _completeQuestion(bool correct) {
    final doorIndex = _coordinator.activeDoorIndex;
    _coordinator.completeDoor(doorIndex, correct);

    setState(() {
      _showingFeedback = false;
      _lastAnswerCorrect = false;
      _selectedAnswer = null;
      _currentQuestion = null;
      _attemptNumber = 1;
      _showRetryOption = false;
      _failureReason = null;
    });

    _feedbackAnimController.reset();

    if (_coordinator.phase == GamePhase.battle) {
      setState(() {});
    } else {
      _fieldKey.currentState?.onQuestionComplete(doorIndex, correct);
    }
  }

  void _checkWritingAnswer(KanjiQuestion question) {
    if (_showingFeedback) return;

    final canvasState = _canvasKey.currentState;
    final drawnStrokes = canvasState?.getStrokes() ?? <List<Offset>>[];

    final kanjiRepo = ref.read(kanjiRepositoryProvider);
    final template = kanjiRepo.getStrokeTemplate(question.kanji.kanji);

    bool correct;
    FailureReason? failureReason;

    if (template != null) {
      final result = gradeWithResult(
        userStrokes: drawnStrokes,
        templateStrokes: template,
      );
      correct = result.passed;
      failureReason = result.failureReason;
    } else {
      // Fallback: accept if user drew something
      correct = drawnStrokes.isNotEmpty;
    }

    // Determine if retry is available (max 3 attempts)
    final canRetry = !correct && _attemptNumber < 3;

    setState(() {
      _showingFeedback = true;
      _lastAnswerCorrect = correct;
      _failureReason = failureReason;
      _showRetryOption = canRetry;
      _hasStrokes = false;
    });

    _feedbackAnimController.forward();

    // If correct or no retry, auto-proceed after delay
    if (correct || !canRetry) {
      final feedbackDuration = correct
          ? const Duration(milliseconds: 1200)
          : const Duration(milliseconds: 1500);

      Future.delayed(feedbackDuration, () {
        if (!mounted) return;
        _completeQuestion(correct);
      });
    }
    // Otherwise wait for user to tap retry or give up
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
