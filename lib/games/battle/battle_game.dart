import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../components/action_button.dart';
import '../components/joystick_component.dart';
import 'components/battle_enemy.dart';
import 'components/battle_hud.dart';
import 'components/battle_player.dart';
import 'systems/combat_system.dart';

/// Battle result
enum BattleResult {
  ongoing,
  victory,
  defeat,
}

/// Side-scrolling real-time battle game.
///
/// Features:
/// - Player with jump, attack, shield
/// - Enemy AI with state machine
/// - Aerial attacks (80% damage, +5% crit)
/// - Hitbox/hurtbox collision system
///
/// Controls:
/// - Joystick: left/right movement
/// - Jump button: tap=normal, hold=high jump
/// - Attack button: ground/aerial attack
/// - Shield button: block incoming damage
class BattleGame extends FlameGame with HasCollisionDetection {
  BattleGame({
    this.enemyName = 'Boss',
    this.difficulty = 1.0,
    this.correctAnswerRatio = 0.5,
    this.onBattleEnd,
  });

  /// Enemy display name
  final String enemyName;

  /// Difficulty multiplier
  final double difficulty;

  /// Ratio of correct kanji answers (for damage bonus)
  final double correctAnswerRatio;

  /// Callback when battle ends
  final void Function(BattleResult result)? onBattleEnd;

  // Game components
  late BattlePlayer player;
  late BattleEnemy enemy;
  late BattleHud hud;
  late SpriteJoystick joystick;
  late ActionButton jumpButton;
  late ActionButton attackButton;
  late ActionButton shieldButton;

  // Random for combat calculations
  final Random _random = Random();

  // Battle state
  BattleResult result = BattleResult.ongoing;
  bool battleEnded = false;

  // Arena bounds
  late double groundY;
  late double leftBound;
  late double rightBound;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Setup arena
    groundY = size.y * 0.88; // Move ground lower to match visual
    leftBound = 50;
    rightBound = size.x - 50;

    // Create world
    final world = World();
    add(world);

    // Add background gradient sky
    final backgroundGradient = _GradientBackground(size: size);
    world.add(backgroundGradient);

    // Draw ground with grass texture effect
    final ground = RectangleComponent(
      position: Vector2(0, groundY),
      size: Vector2(size.x, size.y - groundY),
      paint: Paint()..color = AppColors.secondaryDark,
    );
    world.add(ground);

    // Add ground edge/horizon line
    final groundEdge = RectangleComponent(
      position: Vector2(0, groundY - 3),
      size: Vector2(size.x, 3),
      paint: Paint()..color = const Color(0xFF558B2F),
    );
    world.add(groundEdge);

    // Create player
    player = BattlePlayer(
      position: Vector2(size.x * 0.25, groundY),
      groundY: groundY,
    );
    player.onAttack = _onPlayerAttack;
    player.onDamage = _onPlayerDamage;
    world.add(player);

    // Create enemy
    enemy = BattleEnemy(
      position: Vector2(size.x * 0.75, groundY),
      groundY: groundY,
      playerRef: player,
      difficulty: difficulty,
    );
    enemy.onAttack = _onEnemyAttack;
    enemy.onDamage = _onEnemyDamage;
    enemy.onDeath = _onEnemyDeath;
    world.add(enemy);

    // Create camera
    final camera = CameraComponent(world: world)
      ..viewfinder.anchor = Anchor.topLeft;
    add(camera);

    // Create HUD
    hud = BattleHud(screenSize: size);
    hud.enemyName = enemyName;
    camera.viewport.add(hud);

    // Create controls
    _setupControls(camera.viewport);
  }

  void _setupControls(Component viewport) {
    // Joystick (bottom-left)
    joystick = SpriteJoystick(
      position: Vector2(
        GameSizes.joystickSize / 2 + 20,
        size.y - GameSizes.joystickSize / 2 - 20,
      ),
    );
    viewport.add(joystick);

    // Jump button (bottom-right, medium)
    jumpButton = ActionButton(
      type: ActionButtonType.jump,
      position: Vector2(
        size.x - GameSizes.actionButtonMedium - 20,
        size.y - GameSizes.actionButtonMedium - 20,
      ),
      onPressed: _onJumpPressed,
      onReleased: _onJumpReleased,
    );
    viewport.add(jumpButton);

    // Attack button (middle-right, large)
    attackButton = ActionButton(
      type: ActionButtonType.attack,
      position: Vector2(
        size.x - GameSizes.actionButtonLarge - 20,
        size.y - GameSizes.actionButtonMedium - GameSizes.actionButtonLarge - 40,
      ),
      onPressed: _onAttackPressed,
    );
    viewport.add(attackButton);

    // Shield button (top-right, medium)
    shieldButton = ActionButton(
      type: ActionButtonType.shield,
      position: Vector2(
        size.x - GameSizes.actionButtonMedium - 20,
        size.y - GameSizes.actionButtonMedium - GameSizes.actionButtonLarge -
            GameSizes.actionButtonMedium - 60,
      ),
      onPressed: _onShieldPressed,
      onReleased: _onShieldReleased,
    );
    viewport.add(shieldButton);
  }

  @override
  void update(double dt) {
    if (battleEnded) return;

    super.update(dt);

    // Update player from joystick
    player.setHorizontalInput(joystick.directionWithDeadZone.x);

    // Clamp positions to arena
    _clampToArena(player);
    _clampToArena(enemy);

    // Update HUD
    hud.setPlayerHp(player.hp / GameConfig.playerBaseHp);
    hud.setEnemyHp(enemy.hpPercent);

    // Check battle end conditions
    _checkBattleEnd();
  }

  void _clampToArena(PositionComponent component) {
    if (component.position.x < leftBound) {
      component.position.x = leftBound;
    }
    if (component.position.x > rightBound) {
      component.position.x = rightBound;
    }
  }

  void _onJumpPressed() {
    player.startJump();
    enemy.onPlayerJump(); // Enemy can react
  }

  void _onJumpReleased() {
    player.endJump();
  }

  void _onAttackPressed() {
    player.attack();
  }

  void _onShieldPressed() {
    player.startShield();
  }

  void _onShieldReleased() {
    player.stopShield();
  }

  void _onPlayerAttack(Rect hitbox, bool isAerial) {
    // Check if enemy is hit
    final enemyBounds = Rect.fromCenter(
      center: Offset(enemy.position.x, enemy.position.y - enemy.size.y / 2),
      width: enemy.size.x * 0.8,
      height: enemy.size.y * 0.9,
    );

    if (hitbox.overlaps(enemyBounds)) {
      final damageResult = CombatSystem.calculateDamage(
        baseDamage: GameConfig.playerBaseDamage.toDouble(),
        isAerial: isAerial,
        kanjiCorrectRatio: correctAnswerRatio,
        randomValue: _random.nextDouble(),
      );

      enemy.takeDamage(damageResult.damage);
    }
  }

  void _onEnemyAttack(Rect hitbox, bool isAerial) {
    // Check if player is hit
    final playerBounds = Rect.fromCenter(
      center: Offset(player.position.x, player.position.y - player.size.y / 2),
      width: player.size.x * 0.8,
      height: player.size.y * 0.9,
    );

    if (hitbox.overlaps(playerBounds)) {
      final baseDamage = (15 * difficulty).round();
      player.takeDamage(baseDamage);
    }
  }

  void _onPlayerDamage(int damage) {
    // Could add damage number popup here
  }

  void _onEnemyDamage(int damage) {
    // Could add damage number popup here
  }

  void _onEnemyDeath() {
    result = BattleResult.victory;
    _endBattle();
  }

  void _checkBattleEnd() {
    if (player.isDead) {
      result = BattleResult.defeat;
      _endBattle();
    }
  }

  void _endBattle() {
    if (battleEnded) return;

    battleEnded = true;
    pauseEngine();
    onBattleEnd?.call(result);
  }

  @override
  Color backgroundColor() => const Color(0xFF87CEEB); // Sky blue
}

/// Gradient background for battle scene
class _GradientBackground extends PositionComponent {
  _GradientBackground({required Vector2 size})
      : super(
          size: size,
          position: Vector2.zero(),
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw gradient sky (light blue to darker blue)
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF87CEEB), // Light sky blue
        const Color(0xFFB0E0E6), // Powder blue
        const Color(0xFFE6F5E6), // Very light green (horizon)
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()..shader = gradient.createShader(rect);

    canvas.drawRect(rect, paint);

    // Draw simple clouds
    _drawCloud(canvas, size.x * 0.2, size.y * 0.15, 60);
    _drawCloud(canvas, size.x * 0.6, size.y * 0.25, 80);
    _drawCloud(canvas, size.x * 0.85, size.y * 0.12, 50);
  }

  void _drawCloud(Canvas canvas, double x, double y, double size) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    // Draw 3 overlapping circles for cloud shape
    canvas.drawCircle(Offset(x, y), size * 0.4, cloudPaint);
    canvas.drawCircle(Offset(x + size * 0.3, y), size * 0.5, cloudPaint);
    canvas.drawCircle(Offset(x + size * 0.6, y + size * 0.1), size * 0.35, cloudPaint);
  }
}
