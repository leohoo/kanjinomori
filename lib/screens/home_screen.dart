import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../widgets/coin_display.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final gameNotifier = ref.read(gameProvider.notifier);

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
              // Coin display
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CoinDisplay(coins: player.coins),
                  ],
                ),
              ),

              const Spacer(),

              // Title
              const Text(
                '漢字の森',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black26,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kanji Forest Adventure',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),

              const Spacer(),

              // Forest illustration placeholder
              Container(
                height: 150,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.forest,
                        size: 60,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '🌲 🚪 🌲',
                        style: TextStyle(fontSize: 32),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    // Start button
                    _MenuButton(
                      label: '冒険を始める',
                      icon: Icons.play_arrow,
                      color: AppColors.accent,
                      textColor: AppColors.textPrimary,
                      onPressed: () => gameNotifier.goToStageSelect(),
                    ),
                    const SizedBox(height: 16),

                    // Shop button
                    _MenuButton(
                      label: 'ショップ',
                      icon: Icons.storefront,
                      color: Colors.white.withValues(alpha: 0.2),
                      textColor: Colors.white,
                      onPressed: () => gameNotifier.goToShop(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Stats row
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'ステージ',
                      value: '${player.unlockedStages.length}/10',
                      icon: Icons.map,
                    ),
                    _StatItem(
                      label: '武器',
                      value: '${player.ownedWeapons.length}',
                      icon: Icons.auto_fix_high,
                    ),
                    _StatItem(
                      label: '衣装',
                      value: '${player.ownedCostumes.length}',
                      icon: Icons.checkroom,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
