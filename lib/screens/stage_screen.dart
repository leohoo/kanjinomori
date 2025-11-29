import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../widgets/coin_display.dart';

class StageScreen extends ConsumerWidget {
  const StageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final gameState = ref.watch(gameProvider);
    final gameNotifier = ref.read(gameProvider.notifier);
    final stage = gameState.currentStage;
    final progress = gameState.stageProgress;

    if (stage == null || progress == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentQuestion = progress.currentQuestionIndex;
    final totalQuestions = progress.questions.length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF81C784),
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => _showExitDialog(context, gameNotifier),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            stage.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currentQuestion + 1} / $totalQuestions',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CoinDisplay(coins: player.coins + progress.coinsEarned),
                  ],
                ),
              ),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _ProgressPath(
                  currentIndex: currentQuestion,
                  total: totalQuestions,
                  answers: progress.answersCorrect,
                ),
              ),

              const Spacer(),

              // Forest scene with door
              _ForestDoor(
                questionNumber: currentQuestion + 1,
                isComplete: progress.isComplete,
              ),

              const Spacer(),

              // Action area
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Column(
                  children: [
                    // Branching path choice (decorative for now)
                    if (!progress.isComplete) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _PathButton(
                              label: '左の道',
                              icon: Icons.arrow_back,
                              onPressed: () => gameNotifier.startQuestion(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _PathButton(
                              label: '右の道',
                              icon: Icons.arrow_forward,
                              onPressed: () => gameNotifier.startQuestion(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '道を選んで進もう！',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ] else ...[
                      // All questions done - proceed to battle
                      _BattleButton(
                        bossName: stage.bossName,
                        onPressed: () => gameNotifier.startQuestion(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context, GameNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ステージを終了しますか？'),
        content: const Text('獲得したコインは保持されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.goToHome();
            },
            child: const Text('終了'),
          ),
        ],
      ),
    );
  }
}

class _ProgressPath extends StatelessWidget {
  final int currentIndex;
  final int total;
  final List<bool> answers;

  const _ProgressPath({
    required this.currentIndex,
    required this.total,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: List.generate(total, (index) {
          final isCompleted = index < answers.length;
          final isCurrent = index == currentIndex;
          final wasCorrect = index < answers.length ? answers[index] : null;

          Color color;
          IconData icon;

          if (isCompleted) {
            color = wasCorrect! ? AppColors.success : AppColors.error;
            icon = wasCorrect ? Icons.check_circle : Icons.cancel;
          } else if (isCurrent) {
            color = AppColors.accent;
            icon = Icons.radio_button_checked;
          } else {
            color = Colors.white38;
            icon = Icons.radio_button_unchecked;
          }

          return Expanded(
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                if (index < total - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted ? color : Colors.white24,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ForestDoor extends StatelessWidget {
  final int questionNumber;
  final bool isComplete;

  const _ForestDoor({
    required this.questionNumber,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.brown.shade800,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(100),
          topRight: Radius.circular(100),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border.all(
          color: Colors.brown.shade900,
          width: 8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Door panels
          Positioned(
            top: 60,
            child: Container(
              width: 160,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.brown.shade700,
                    Colors.brown.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.brown.shade800, width: 2),
                      ),
                    ),
                  ),
                  Container(
                    width: 4,
                    color: Colors.brown.shade800,
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.brown.shade800, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Door handle
          Positioned(
            top: 150,
            right: 50,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentDark.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // Question number or boss indicator
          Positioned(
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isComplete ? AppColors.error : AppColors.accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isComplete ? 'BOSS' : '問$questionNumber',
                style: TextStyle(
                  color: isComplete ? Colors.white : AppColors.accentDark,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Light rays (decorative)
          if (isComplete)
            Positioned(
              bottom: 0,
              child: Container(
                width: 100,
                height: 10,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withOpacity(0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PathButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PathButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          side: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleButton extends StatelessWidget {
  final String bossName;
  final VoidCallback onPressed;

  const _BattleButton({
    required this.bossName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.sports_mma, size: 32),
            const SizedBox(height: 8),
            Text(
              '$bossName に挑戦！',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
