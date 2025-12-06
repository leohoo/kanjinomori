import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kanji.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../utils/stroke_grader.dart';
import '../widgets/kanji_canvas.dart';
import '../widgets/stroke_hint_banner.dart';
import '../widgets/trace_along_overlay.dart';

class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen>
    with SingleTickerProviderStateMixin {
  bool _answered = false;
  bool _isCorrect = false;
  String? _selectedAnswer;
  FailureReason? _failureReason;
  bool _showRetryOption = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleWritingAnswer(bool correct, String answer, FailureReason? failureReason) {
    if (_answered) return;

    final progress = ref.read(gameProvider).stageProgress;
    final canRetry = progress?.canRetry ?? false;

    setState(() {
      _answered = true;
      _isCorrect = correct;
      _selectedAnswer = answer;
      _failureReason = failureReason;
      _showRetryOption = !correct && canRetry;
    });

    _animController.forward();

    // If correct or no retry available, proceed after delay
    if (correct || !canRetry) {
      Future.delayed(
        correct
            ? AppDurations.correctAnswerCelebration
            : AppDurations.wrongAnswerFeedback,
        () {
          if (mounted) {
            ref.read(gameProvider.notifier).answerQuestion(correct);
            _resetState();
          }
        },
      );
    }
    // Otherwise, wait for user to tap retry or give up
  }

  void _handleRetry() {
    final progress = ref.read(gameProvider).stageProgress;
    progress?.incrementAttempt();
    _resetState();
  }

  void _handleGiveUp() {
    ref.read(gameProvider.notifier).answerQuestion(false);
    _resetState();
  }

  void _resetState() {
    setState(() {
      _answered = false;
      _isCorrect = false;
      _selectedAnswer = null;
      _failureReason = null;
      _showRetryOption = false;
    });
    _animController.reset();
  }

  void _handleAnswer(bool correct, String answer) {
    if (_answered) return;

    setState(() {
      _answered = true;
      _isCorrect = correct;
      _selectedAnswer = answer;
    });

    _animController.forward();

    // Delay before moving to next question
    Future.delayed(
      correct
          ? AppDurations.correctAnswerCelebration
          : AppDurations.wrongAnswerFeedback,
      () {
        if (mounted) {
          ref.read(gameProvider.notifier).answerQuestion(correct);
          _resetState();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final progress = gameState.stageProgress;

    if (progress == null || progress.isComplete) {
      return const Center(child: CircularProgressIndicator());
    }

    final question = progress.currentQuestion;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _answered
                ? (_isCorrect
                    ? [Colors.green.shade300, Colors.green.shade700]
                    : [Colors.red.shade300, Colors.red.shade700])
                : [const Color(0xFF81C784), const Color(0xFF2E7D32)],
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
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        question.type == QuestionType.reading
                            ? '読み問題'
                            : '書き問題',
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

              // Question content
              if (question.type == QuestionType.reading)
                _ReadingQuestion(
                  question: question,
                  answered: _answered,
                  isCorrect: _isCorrect,
                  selectedAnswer: _selectedAnswer,
                  scaleAnimation: _scaleAnimation,
                  onAnswer: _handleAnswer,
                )
              else
                _WritingQuestion(
                  question: question,
                  answered: _answered,
                  isCorrect: _isCorrect,
                  attemptNumber: progress.currentAttempt,
                  onAnswer: _handleWritingAnswer,
                ),

              const Spacer(),

              // Result feedback
              if (_answered)
                AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    final coinReward = progress.coinRewardForCurrentAttempt;
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _isCorrect ? Icons.celebration : Icons.sentiment_dissatisfied,
                              color: _isCorrect ? AppColors.success : AppColors.error,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isCorrect ? '正解！ +$coinRewardコイン' : '残念...',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _isCorrect ? AppColors.success : AppColors.error,
                              ),
                            ),
                            if (!_isCorrect && !_showRetryOption) ...[
                              const SizedBox(height: 4),
                              Text(
                                '正解: ${question.correctAnswer}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            // Show hint for 2nd attempt
                            if (_showRetryOption && _failureReason != null && progress.currentAttempt == 1) ...[
                              const SizedBox(height: 12),
                              StrokeHintBanner(failureReason: _failureReason!),
                            ],
                            // Retry options
                            if (_showRetryOption) ...[
                              const SizedBox(height: 16),
                              Text(
                                progress.currentAttempt == 1
                                    ? 'もう一度挑戦しますか？'
                                    : 'なぞり書きで練習しますか？',
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
                                    icon: Icon(
                                      progress.currentAttempt == 1
                                          ? Icons.refresh
                                          : Icons.gesture,
                                    ),
                                    label: Text(
                                      progress.currentAttempt == 1
                                          ? 'もう一度 (${progress.coinRewardForCurrentAttempt - 2}コイン)'
                                          : 'なぞり書き (1コイン)',
                                    ),
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
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingQuestion extends StatelessWidget {
  final KanjiQuestion question;
  final bool answered;
  final bool isCorrect;
  final String? selectedAnswer;
  final Animation<double> scaleAnimation;
  final void Function(bool, String) onAnswer;

  const _ReadingQuestion({
    required this.question,
    required this.answered,
    required this.isCorrect,
    required this.selectedAnswer,
    required this.scaleAnimation,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Kanji display
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              question.kanji.kanji,
              style: const TextStyle(
                fontSize: 100,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Meaning hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '意味: ${question.kanji.meaning}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Choice buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: question.choices.map((choice) {
              final isSelected = selectedAnswer == choice;
              final isCorrectChoice = choice == question.correctAnswer;

              Color bgColor;
              Color textColor;
              Color borderColor;

              if (answered) {
                if (isCorrectChoice) {
                  bgColor = AppColors.success;
                  textColor = Colors.white;
                  borderColor = AppColors.success;
                } else if (isSelected && !isCorrect) {
                  bgColor = AppColors.error;
                  textColor = Colors.white;
                  borderColor = AppColors.error;
                } else {
                  bgColor = Colors.white.withOpacity(0.3);
                  textColor = Colors.white70;
                  borderColor = Colors.transparent;
                }
              } else {
                bgColor = Colors.white;
                textColor = AppColors.textPrimary;
                borderColor = Colors.transparent;
              }

              return GestureDetector(
                onTap: answered
                    ? null
                    : () => onAnswer(choice == question.correctAnswer, choice),
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                    border: Border.all(color: borderColor, width: 3),
                    boxShadow: answered
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Text(
                    choice,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _WritingQuestion extends ConsumerStatefulWidget {
  final KanjiQuestion question;
  final bool answered;
  final bool isCorrect;
  final int attemptNumber;
  final void Function(bool, String, FailureReason?) onAnswer;

  const _WritingQuestion({
    required this.question,
    required this.answered,
    required this.isCorrect,
    required this.attemptNumber,
    required this.onAnswer,
  });

  @override
  ConsumerState<_WritingQuestion> createState() => _WritingQuestionState();
}

class _WritingQuestionState extends ConsumerState<_WritingQuestion> {
  final _canvasKey = GlobalKey<KanjiCanvasState>();
  bool _hasStrokes = false;

  @override
  void didUpdateWidget(covariant _WritingQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attemptNumber != widget.attemptNumber) {
      _hasStrokes = false;
    }
  }

  void _onCanvasChanged() {
    setState(() {
      _hasStrokes = _canvasKey.currentState?.hasStrokes ?? false;
    });
  }

  void _checkAnswer() {
    final canvasState = _canvasKey.currentState;
    final hasDrawn = canvasState?.hasStrokes ?? false;
    final drawnStrokes = canvasState?.getStrokes() ?? <List<Offset>>[];

    final kanjiRepo = ref.read(kanjiRepositoryProvider);
    final template =
        kanjiRepo.getStrokeTemplate(widget.question.kanji.kanji);

    if (template != null) {
      final result = gradeWithResult(
        userStrokes: drawnStrokes,
        templateStrokes: template,
      );
      widget.onAnswer(result.passed, widget.question.kanji.kanji, result.failureReason);
    } else {
      // Fallback if no template
      widget.onAnswer(hasDrawn, widget.question.kanji.kanji, null);
    }
  }

  void _handleTraceComplete(bool success) {
    widget.onAnswer(success, widget.question.kanji.kanji, null);
  }

  @override
  Widget build(BuildContext context) {
    final kanjiRepo = ref.watch(kanjiRepositoryProvider);
    final template = kanjiRepo.getStrokeTemplate(widget.question.kanji.kanji);
    final isTraceMode = widget.attemptNumber == 3 && template != null;

    return Column(
      children: [
        // Reading/meaning prompt
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                widget.question.kanji.readings.first,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '(${widget.question.kanji.meaning})',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Canvas for writing
        if (!widget.answered) ...[
          if (isTraceMode) ...[
            // Trace mode (3rd attempt)
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final canvasSize = (screenWidth * 0.75).clamp(250.0, 350.0);
                return TraceAlongOverlay(
                  templateStrokes: template,
                  size: canvasSize,
                  onComplete: _handleTraceComplete,
                );
              },
            ),
          ] else ...[
            // Normal writing mode (1st or 2nd attempt)
            Text(
              widget.attemptNumber == 1
                  ? 'この漢字を書いてください'
                  : 'もう一度書いてみよう',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final canvasSize = (screenWidth * 0.75).clamp(250.0, 350.0);
                return KanjiCanvas(
                  key: _canvasKey,
                  size: canvasSize,
                  strokeWidth: 8.0,
                  onChanged: _onCanvasChanged,
                );
              },
            ),
            const SizedBox(height: 16),
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
                  onPressed: _hasStrokes ? _checkAnswer : null,
                  icon: const Icon(Icons.check),
                  label: const Text('確認'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ] else ...[
          // Show correct answer
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
            ),
            child: Center(
              child: Text(
                widget.question.kanji.kanji,
                style: TextStyle(
                  fontSize: 100,
                  fontWeight: FontWeight.bold,
                  color: widget.isCorrect ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
