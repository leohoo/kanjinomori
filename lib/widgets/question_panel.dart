import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kanji.dart';
import '../providers/kanji_provider.dart';
import '../utils/constants.dart';
import '../utils/stroke_grader.dart';
import 'kanji_canvas.dart';
import 'stroke_hint_banner.dart';
import 'trace_along_overlay.dart';

/// Reusable question panel for both reading and writing questions.
/// Used by both legacy QuestionScreen and new StageCoordinatorScreen.
class QuestionPanel extends ConsumerStatefulWidget {
  const QuestionPanel({
    super.key,
    required this.question,
    required this.attemptNumber,
    required this.onAnswer,
    required this.onRetry,
    required this.onGiveUp,
    this.doorNumber,
  });

  final KanjiQuestion question;
  final int attemptNumber;
  final void Function(bool correct) onAnswer;
  final VoidCallback onRetry;
  final VoidCallback onGiveUp;
  final int? doorNumber;

  @override
  ConsumerState<QuestionPanel> createState() => _QuestionPanelState();
}

class _QuestionPanelState extends ConsumerState<QuestionPanel>
    with SingleTickerProviderStateMixin {
  bool _answered = false;
  bool _isCorrect = false;
  String? _selectedAnswer;
  FailureReason? _failureReason;
  bool _showRetryOption = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  final _canvasKey = GlobalKey<KanjiCanvasState>();
  bool _hasStrokes = false;

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

  @override
  void didUpdateWidget(covariant QuestionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.attemptNumber != widget.attemptNumber) {
      _resetState();
    }
  }

  void _resetState() {
    setState(() {
      _answered = false;
      _isCorrect = false;
      _selectedAnswer = null;
      _failureReason = null;
      _showRetryOption = false;
      _hasStrokes = false;
    });
    _animController.reset();
  }

  void _handleReadingAnswer(bool correct, String answer) {
    if (_answered) return;

    setState(() {
      _answered = true;
      _isCorrect = correct;
      _selectedAnswer = answer;
    });

    _animController.forward();

    // Auto-proceed after delay
    Future.delayed(
      correct
          ? AppDurations.correctAnswerCelebration
          : AppDurations.wrongAnswerFeedback,
      () {
        if (mounted) {
          widget.onAnswer(correct);
        }
      },
    );
  }

  void _handleWritingAnswer(bool correct, FailureReason? failureReason) {
    if (_answered) return;

    // Allow retry for up to 3 attempts
    final canRetry = !correct && widget.attemptNumber < 3;

    setState(() {
      _answered = true;
      _isCorrect = correct;
      _failureReason = failureReason;
      _showRetryOption = canRetry;
    });

    _animController.forward();

    // If correct or no retry, auto-proceed
    if (correct || !canRetry) {
      Future.delayed(
        correct
            ? AppDurations.correctAnswerCelebration
            : AppDurations.wrongAnswerFeedback,
        () {
          if (mounted) {
            widget.onAnswer(correct);
          }
        },
      );
    }
  }

  void _checkWritingAnswer() {
    final canvasState = _canvasKey.currentState;
    final drawnStrokes = canvasState?.getStrokes() ?? <List<Offset>>[];

    final kanjiRepo = ref.read(kanjiRepositoryProvider);
    final template = kanjiRepo.getStrokeTemplate(widget.question.kanji.kanji);

    if (template != null) {
      final result = gradeWithResult(
        userStrokes: drawnStrokes,
        templateStrokes: template,
      );
      _handleWritingAnswer(result.passed, result.failureReason);
    } else {
      // Fallback if no template
      _handleWritingAnswer(drawnStrokes.isNotEmpty, null);
    }
  }

  void _handleTraceComplete(bool success) {
    _handleWritingAnswer(success, null);
  }

  void _onCanvasChanged() {
    setState(() {
      _hasStrokes = _canvasKey.currentState?.hasStrokes ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _buildHeaderText(),
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
              if (widget.question.type == QuestionType.reading)
                _buildReadingQuestion()
              else
                _buildWritingQuestion(),

              const Spacer(),

              // Result feedback
              if (_answered) _buildResultFeedback(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _buildHeaderText() {
    final typeText = widget.question.type == QuestionType.reading
        ? '読み問題'
        : '書き問題';
    if (widget.doorNumber != null) {
      return 'ドア ${widget.doorNumber} - $typeText';
    }
    return typeText;
  }

  Widget _buildReadingQuestion() {
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
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.question.kanji.kanji,
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
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '意味: ${widget.question.kanji.meaning}',
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
            children: widget.question.choices.map((choice) {
              return _buildChoiceButton(choice);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton(String choice) {
    final isSelected = _selectedAnswer == choice;
    final isCorrectChoice = choice == widget.question.correctAnswer;

    Color bgColor;
    Color textColor;
    Color borderColor;

    if (_answered) {
      if (isCorrectChoice) {
        bgColor = AppColors.success;
        textColor = Colors.white;
        borderColor = AppColors.success;
      } else if (isSelected && !_isCorrect) {
        bgColor = AppColors.error;
        textColor = Colors.white;
        borderColor = AppColors.error;
      } else {
        bgColor = Colors.white.withValues(alpha: 0.3);
        textColor = Colors.white70;
        borderColor = Colors.transparent;
      }
    } else {
      bgColor = Colors.white;
      textColor = AppColors.textPrimary;
      borderColor = Colors.transparent;
    }

    return GestureDetector(
      onTap: _answered
          ? null
          : () => _handleReadingAnswer(
                choice == widget.question.correctAnswer,
                choice,
              ),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          border: Border.all(color: borderColor, width: 3),
          boxShadow: _answered
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
  }

  Widget _buildWritingQuestion() {
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
                color: Colors.black.withValues(alpha: 0.1),
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

        // Canvas or feedback
        if (!_answered) ...[
          if (isTraceMode) ...[
            const Text(
              'なぞって書こう',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
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
            Text(
              widget.attemptNumber == 1
                  ? 'この漢字を書いてください'
                  : 'もう一度書いてみよう',
              style: const TextStyle(color: Colors.white, fontSize: 16),
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
                  onPressed: _hasStrokes ? _checkWritingAnswer : null,
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
          // Show correct kanji
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
                  color: _isCorrect ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResultFeedback() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
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
                  _isCorrect ? '正解！' : '残念...',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isCorrect ? AppColors.success : AppColors.error,
                  ),
                ),
                if (!_isCorrect && !_showRetryOption) ...[
                  const SizedBox(height: 4),
                  Text(
                    '正解: ${widget.question.correctAnswer}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                // Hint for writing failures
                if (_showRetryOption &&
                    _failureReason != null &&
                    widget.attemptNumber == 1) ...[
                  const SizedBox(height: 12),
                  StrokeHintBanner(failureReason: _failureReason!),
                ],
                // Retry options
                if (_showRetryOption) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.attemptNumber == 1
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
                        onPressed: widget.onGiveUp,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text('あきらめる'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: widget.onRetry,
                        icon: Icon(
                          widget.attemptNumber == 1
                              ? Icons.refresh
                              : Icons.gesture,
                        ),
                        label: Text(
                          widget.attemptNumber == 1 ? 'もう一度' : 'なぞり書き',
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
    );
  }
}
