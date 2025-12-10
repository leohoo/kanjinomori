import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stage.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../widgets/coin_display.dart';

class StageSelectScreen extends ConsumerWidget {
  const StageSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final gameNotifier = ref.read(gameProvider.notifier);
    final stages = Stage.allStages;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF2E7D32),
              Color(0xFF1B5E20),
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => gameNotifier.goToHome(),
                    ),
                    const Expanded(
                      child: Text(
                        'ステージ選択',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    CoinDisplay(coins: player.coins),
                  ],
                ),
              ),

              // Stage grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(AppSizes.paddingMedium),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: stages.length,
                  itemBuilder: (context, index) {
                    final stage = stages[index];
                    final isUnlocked = player.isStageUnlocked(stage.id);
                    final highScore = player.stageHighScores[stage.id] ?? 0;

                    return _StageCard(
                      stage: stage,
                      isUnlocked: isUnlocked,
                      highScore: highScore,
                      onTap: isUnlocked
                          ? () => gameNotifier.startFieldStage(stage.id)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final Stage stage;
  final bool isUnlocked;
  final int highScore;
  final VoidCallback? onTap;

  const _StageCard({
    required this.stage,
    required this.isUnlocked,
    required this.highScore,
    this.onTap,
  });

  IconData _getStageIcon() {
    switch (stage.theme) {
      case 'forest_entrance':
        return Icons.forest;
      case 'light_path':
        return Icons.wb_sunny;
      case 'butterfly_garden':
        return Icons.nature;
      case 'bird_nest':
        return Icons.flutter_dash;
      case 'magic_spring':
        return Icons.water_drop;
      case 'old_bridge':
        return Icons.architecture;
      case 'secret_cave':
        return Icons.landscape;
      case 'star_tower':
        return Icons.star;
      case 'time_temple':
        return Icons.access_time;
      case 'final_door':
        return Icons.door_front_door;
      default:
        return Icons.explore;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isUnlocked
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
          border: Border.all(
            color: isUnlocked
                ? AppColors.accent.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Stage number
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isUnlocked ? AppColors.accent : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${stage.id}',
                        style: TextStyle(
                          color: isUnlocked
                              ? AppColors.accentDark
                              : Colors.white60,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Stage icon
                  Icon(
                    isUnlocked ? _getStageIcon() : Icons.lock,
                    size: 40,
                    color: isUnlocked ? Colors.white : Colors.white38,
                  ),
                  const SizedBox(height: 8),

                  // Stage name
                  Text(
                    stage.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.white38,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // High score
                  if (isUnlocked && highScore > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.stars,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$highScore',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Grade indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${stage.grade}年',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
