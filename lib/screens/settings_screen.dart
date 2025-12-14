import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/providers.dart';
import '../utils/constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              // Header with back button
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingMedium),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => gameNotifier.goToHome(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '設定',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingLarge,
                  ),
                  children: [
                    const SizedBox(height: 16),
                    // Control settings section
                    _buildSectionHeader('操作設定'),
                    _buildMovementModeTile(ref),
                    const SizedBox(height: 8),
                    // App info section
                    _buildSectionHeader('アプリ情報'),
                    _buildVersionTile(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildMovementModeTile(WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final playerNotifier = ref.read(playerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      ),
      child: SwitchListTile(
        secondary: const Icon(
          Icons.gamepad_outlined,
          color: Colors.white70,
        ),
        title: const Text(
          'アイソメトリック移動',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          player.useIsometricMovement
              ? '斜め方向に移動します'
              : '上下左右に移動します',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        value: player.useIsometricMovement,
        onChanged: (value) => playerNotifier.setUseIsometricMovement(value),
        activeTrackColor: AppColors.accent.withValues(alpha: 0.5),
        thumbColor: WidgetStatePropertyAll(AppColors.accent),
      ),
    );
  }

  Widget _buildVersionTile() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        String version = '...';
        if (snapshot.hasData) {
          final info = snapshot.data!;
          if (info.buildNumber.isNotEmpty) {
            version = '${info.version} (${info.buildNumber})';
          } else {
            version = info.version;
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
          ),
          child: ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: Colors.white70,
            ),
            title: const Text(
              'バージョン',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              version,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }
}
