import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'games/coordinator/stage_coordinator_screen.dart';
import 'models/kanji.dart';
import 'models/player.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(KanjiAdapter());
  Hive.registerAdapter(PlayerAdapter());

  // Open boxes
  final playerBox = await Hive.openBox<Player>('player');

  runApp(
    ProviderScope(
      overrides: [
        playerBoxProvider.overrideWithValue(playerBox),
      ],
      child: const KanjiGameApp(),
    ),
  );
}

class KanjiGameApp extends StatelessWidget {
  const KanjiGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '漢字の森',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        // Use system default fonts for proper kanji support
        // fontFamily: 'NotoSansJP',
      ),
      home: const GameNavigator(),
    );
  }
}

class GameNavigator extends ConsumerWidget {
  const GameNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    // Show loading indicator during async operations
    if (gameState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('読み込み中...'),
            ],
          ),
        ),
      );
    }

    // Route to appropriate screen
    return AnimatedSwitcher(
      duration: AppDurations.transitionDuration,
      child: _getScreen(context, ref, gameState),
    );
  }

  Widget _getScreen(BuildContext context, WidgetRef ref, GameState gameState) {
    switch (gameState.currentScreen) {
      case GameScreen.home:
        return const HomeScreen();
      case GameScreen.stageSelect:
        return const StageSelectScreen();
      case GameScreen.stage:
        return const StageScreen();
      case GameScreen.field:
        return _buildFieldScreen(ref, gameState);
      case GameScreen.question:
        return const QuestionScreen();
      case GameScreen.battle:
        return const BattleScreen();
      case GameScreen.victory:
        return const VictoryScreen();
      case GameScreen.defeat:
        return const DefeatScreen();
      case GameScreen.shop:
        return const ShopScreen();
    }
  }

  Widget _buildFieldScreen(WidgetRef ref, GameState gameState) {
    final stage = gameState.currentStage;
    final progress = gameState.stageProgress;

    if (stage == null || progress == null) {
      // Fallback to home if state is invalid
      return const HomeScreen();
    }

    return StageCoordinatorScreen(
      stage: stage,
      questions: progress.questions,
      onStageComplete: (victory, questionCoins, battleCoins) {
        ref.read(gameProvider.notifier).completeFieldStage(victory, questionCoins, battleCoins);
      },
      onBack: () {
        ref.read(gameProvider.notifier).goToStageSelect();
      },
    );
  }
}
