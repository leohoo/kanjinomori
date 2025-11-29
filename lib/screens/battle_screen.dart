import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/battle.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../widgets/hp_bar.dart';

class BattleScreen extends ConsumerStatefulWidget {
  const BattleScreen({super.key});

  @override
  ConsumerState<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends ConsumerState<BattleScreen>
    with TickerProviderStateMixin {
  String _message = 'バトル開始！';
  bool _isEnemyTurn = false;
  bool _canAct = true;
  Timer? _enemyTimer;
  late AnimationController _shakeController;
  late AnimationController _attackController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _attackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _enemyTimer?.cancel();
    _shakeController.dispose();
    _attackController.dispose();
    super.dispose();
  }

  void _playerAction(BattleAction action) {
    if (!_canAct || _isEnemyTurn) return;

    final gameNotifier = ref.read(gameProvider.notifier);
    final result = gameNotifier.playerBattleAction(action);

    setState(() {
      _message = result.message;
      _canAct = false;
    });

    // Attack animation
    if (action == BattleAction.attack && result.success) {
      _attackController.forward().then((_) => _attackController.reset());
    }

    final gameState = ref.read(gameProvider);
    if (gameState.currentBattle?.state == BattleState.victory ||
        gameState.currentBattle?.state == BattleState.defeat) {
      // Battle ended
      return;
    }

    // Start enemy turn
    _startEnemyTurn();
  }

  void _startEnemyTurn() {
    setState(() {
      _isEnemyTurn = true;
    });

    final gameState = ref.read(gameProvider);
    final enemyAction = gameState.currentBattle?.enemyNextAction;

    // Show telegraph
    String telegraphMessage;
    switch (enemyAction) {
      case BattleAction.attack:
        telegraphMessage = '敵が攻撃を準備している！';
        break;
      case BattleAction.shield:
        telegraphMessage = '敵が防御態勢に入った...';
        break;
      case BattleAction.jump:
        telegraphMessage = '敵がジャンプしようとしている...';
        break;
      default:
        telegraphMessage = '敵のターン...';
    }

    setState(() {
      _message = telegraphMessage;
      _canAct = true; // Player can react
    });

    // Execute enemy action after delay
    _enemyTimer = Timer(AppDurations.enemyTelegraph, () {
      if (!mounted) return;

      final gameNotifier = ref.read(gameProvider.notifier);
      final result = gameNotifier.executeEnemyAction();

      if (result.damage > 0) {
        _shakeController.repeat(reverse: true);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _shakeController.stop();
        });
      }

      setState(() {
        _message = result.message;
        _isEnemyTurn = false;
        _canAct = true;
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final battle = gameState.currentBattle;
    final stage = gameState.currentStage;

    if (battle == null || stage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a237e),
              Color(0xFF311b92),
              Color(0xFF4a148c),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Battle HUD
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Player HP
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'プレイヤー',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          HpBar(
                            current: battle.player.hp,
                            max: battle.player.maxHp,
                            color: AppColors.hp,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Turn indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _isEnemyTurn
                            ? Colors.red.withOpacity(0.3)
                            : Colors.green.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'ターン ${battle.turnCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Enemy HP
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            battle.enemy.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          HpBar(
                            current: battle.enemy.hp,
                            max: battle.enemy.maxHp,
                            color: AppColors.enemyHp,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Battle scene
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeController.value * 10 - 5,
                      0,
                    ),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Player
                    _BattleCharacter(
                      name: 'プレイヤー',
                      emoji: '🧙',
                      action: battle.player.currentAction,
                      isPlayer: true,
                    ),

                    // VS or action indicator
                    Column(
                      children: [
                        AnimatedBuilder(
                          animation: _attackController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                _attackController.value * 50,
                                0,
                              ),
                              child: const Text(
                                '⚡',
                                style: TextStyle(fontSize: 40),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'VS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Enemy
                    _BattleCharacter(
                      name: battle.enemy.name,
                      emoji: _getEnemyEmoji(stage.theme),
                      action: battle.enemy.currentAction,
                      isPlayer: false,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Message box
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons (one-hand layout)
              Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      children: [
                        // Jump button (top)
                        _ActionButton(
                          label: 'ジャンプ',
                          icon: Icons.arrow_upward,
                          color: Colors.blue,
                          onPressed: _canAct
                              ? () => _playerAction(BattleAction.jump)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Shield button (left)
                            _ActionButton(
                              label: 'シールド',
                              icon: Icons.shield,
                              color: Colors.green,
                              onPressed: _canAct
                                  ? () => _playerAction(BattleAction.shield)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            // Attack button (right)
                            _ActionButton(
                              label: 'アタック',
                              icon: Icons.flash_on,
                              color: Colors.red,
                              size: 80,
                              onPressed: _canAct
                                  ? () => _playerAction(BattleAction.attack)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEnemyEmoji(String theme) {
    switch (theme) {
      case 'forest_entrance':
        return '🟢'; // Slime
      case 'light_path':
        return '🌳'; // Tree spirit
      case 'butterfly_garden':
        return '🦋'; // Butterfly queen
      case 'bird_nest':
        return '🦉'; // Owl
      case 'magic_spring':
        return '🧜'; // Water witch
      case 'old_bridge':
        return '👹'; // Troll
      case 'secret_cave':
        return '🐉'; // Dragon
      case 'star_tower':
        return '⭐'; // Star guardian
      case 'time_temple':
        return '🧙'; // Time wizard
      case 'final_door':
        return '👿'; // Dark king
      default:
        return '👾';
    }
  }
}

class _BattleCharacter extends StatelessWidget {
  final String name;
  final String emoji;
  final BattleAction action;
  final bool isPlayer;

  const _BattleCharacter({
    required this.name,
    required this.emoji,
    required this.action,
    required this.isPlayer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Action indicator
        if (action != BattleAction.none)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getActionColor().withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getActionText(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 8),

        // Character
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: isPlayer
                ? Colors.blue.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: isPlayer ? Colors.blue : Colors.red,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 50),
            ),
          ),
        ),
      ],
    );
  }

  Color _getActionColor() {
    switch (action) {
      case BattleAction.attack:
        return Colors.red;
      case BattleAction.shield:
        return Colors.green;
      case BattleAction.jump:
        return Colors.blue;
      case BattleAction.none:
        return Colors.transparent;
    }
  }

  String _getActionText() {
    switch (action) {
      case BattleAction.attack:
        return 'アタック！';
      case BattleAction.shield:
        return 'シールド！';
      case BattleAction.jump:
        return 'ジャンプ！';
      case BattleAction.none:
        return '';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.size = 64,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onPressed != null ? 1.0 : 0.4,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: size * 0.4,
              ),
              if (size >= 70)
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
