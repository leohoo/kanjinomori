import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';

/// Enemy AI states
enum EnemyState {
  idle,
  approach,
  attack,
  retreat,
  jumpAttack,
  hurt,
}

/// Battle enemy component with AI behavior.
///
/// AI Behaviors:
/// - Tracks player position
/// - Approaches when far, retreats when too close
/// - Attacks when in range
/// - Jumps when player jumps (reactive)
/// - Mix of ground and aerial attacks
class BattleEnemy extends PositionComponent with CollisionCallbacks {
  BattleEnemy({
    required Vector2 position,
    required this.groundY,
    required this.playerRef,
    this.difficulty = 1.0,
  }) : super(
          position: position,
          size: Vector2(GameSizes.playerWidth * 1.2, GameSizes.playerHeight * 1.2),
          anchor: Anchor.bottomCenter,
        );

  /// Y position of the ground
  final double groundY;

  /// Reference to player for AI decisions
  final PositionComponent playerRef;

  /// Difficulty multiplier (affects damage, speed, reaction time)
  final double difficulty;

  /// Current velocity
  final Vector2 velocity = Vector2.zero();

  /// Current AI state
  EnemyState state = EnemyState.idle;

  /// Whether enemy is on ground
  bool isGrounded = true;

  /// Whether enemy is facing right
  bool facingRight = false;

  /// Current HP (initialized in onLoad based on difficulty)
  int hp = 100;

  /// Maximum HP (initialized in onLoad based on difficulty)
  int maxHp = 100;

  /// Attack timer
  double attackTimer = 0;

  /// Attack cooldown
  double attackCooldown = 0;

  /// State timer (how long to stay in current state)
  double stateTimer = 0;

  /// Telegraph timer (warning before attack)
  double telegraphTimer = 0;

  /// Whether currently in telegraph phase
  bool isTelegraphing = false;

  /// Whether enemy is invincible
  bool isInvincible = false;

  /// Invincibility timer
  double invincibilityTimer = 0;

  /// Random for AI decisions
  final Random _random = Random();

  /// Callback when enemy attacks
  void Function(Rect hitbox, bool isAerial)? onAttack;

  /// Callback when enemy takes damage
  void Function(int damage)? onDamage;

  /// Callback when enemy dies
  VoidCallback? onDeath;

  // Visual components
  late RectangleComponent _visual;
  late RectangleComponent _telegraphIndicator;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Calculate HP based on difficulty
    maxHp = (100 * difficulty).round();
    hp = maxHp;

    // Enemy visual (purple placeholder)
    _visual = RectangleComponent(
      size: size,
      paint: Paint()..color = AppColors.enemyHp,
      anchor: Anchor.bottomCenter,
    );
    add(_visual);

    // Telegraph indicator (hidden by default)
    _telegraphIndicator = RectangleComponent(
      size: Vector2(size.x * 0.8, 8),
      position: Vector2(size.x * 0.1, -size.y - 10),
      paint: Paint()..color = Colors.red.withValues(alpha: 0.0),
      anchor: Anchor.bottomLeft,
    );
    add(_telegraphIndicator);

    // Add hitbox
    add(
      RectangleHitbox(
        size: Vector2(size.x * 0.8, size.y * 0.9),
        position: Vector2(size.x * 0.1, size.y * 0.1),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _updateTimers(dt);
    _updateAI(dt);
    _updatePhysics(dt);
    _updateVisuals();
  }

  void _updateTimers(double dt) {
    stateTimer -= dt;
    attackCooldown -= dt;

    if (isTelegraphing) {
      telegraphTimer -= dt;
      if (telegraphTimer <= 0) {
        _executeAttack();
      }
    }

    if (isInvincible) {
      invincibilityTimer -= dt;
      if (invincibilityTimer <= 0) {
        isInvincible = false;
      }
    }
  }

  void _updateAI(double dt) {
    // Update facing direction based on player position
    facingRight = playerRef.position.x > position.x;

    // Calculate distance to player
    final distanceToPlayer = (playerRef.position.x - position.x).abs();
    final playerAbove = playerRef.position.y < position.y - 50;

    // State machine logic
    switch (state) {
      case EnemyState.idle:
        _handleIdleState(distanceToPlayer);
        break;
      case EnemyState.approach:
        _handleApproachState(distanceToPlayer);
        break;
      case EnemyState.attack:
        // Handled by telegraph/attack timers
        break;
      case EnemyState.retreat:
        _handleRetreatState(distanceToPlayer);
        break;
      case EnemyState.jumpAttack:
        _handleJumpAttackState(playerAbove);
        break;
      case EnemyState.hurt:
        if (stateTimer <= 0) {
          _transitionToState(EnemyState.retreat);
        }
        break;
    }
  }

  void _handleIdleState(double distanceToPlayer) {
    if (stateTimer <= 0) {
      // Decide next action
      if (distanceToPlayer > GamePhysics.enemyApproachDistance) {
        _transitionToState(EnemyState.approach);
      } else if (distanceToPlayer < GamePhysics.enemyRetreatDistance) {
        _transitionToState(EnemyState.retreat);
      } else if (attackCooldown <= 0) {
        _startAttack(false);
      }
    }
  }

  void _handleApproachState(double distanceToPlayer) {
    // Move towards player
    final direction = facingRight ? 1.0 : -1.0;
    velocity.x = direction * GamePhysics.playerSpeed * 0.7 * difficulty;

    if (distanceToPlayer < GamePhysics.enemyAttackRange) {
      velocity.x = 0;
      if (attackCooldown <= 0) {
        _startAttack(false);
      } else {
        _transitionToState(EnemyState.idle);
      }
    }
  }

  void _handleRetreatState(double distanceToPlayer) {
    // Move away from player
    final direction = facingRight ? -1.0 : 1.0;
    velocity.x = direction * GamePhysics.playerSpeed * 0.5;

    if (distanceToPlayer > GamePhysics.enemySafeDistance || stateTimer <= 0) {
      velocity.x = 0;
      _transitionToState(EnemyState.idle);
    }
  }

  void _handleJumpAttackState(bool playerAbove) {
    if (isGrounded && playerAbove) {
      // Jump towards player
      velocity.y = -GamePhysics.jumpForce * 0.8;
      isGrounded = false;
    }

    if (!isGrounded && velocity.y > 0 && attackCooldown <= 0) {
      // Aerial attack on the way down
      _startAttack(true);
    }

    if (isGrounded && stateTimer <= 0) {
      _transitionToState(EnemyState.idle);
    }
  }

  void _transitionToState(EnemyState newState) {
    state = newState;
    velocity.x = 0;

    switch (newState) {
      case EnemyState.idle:
        stateTimer = 0.5 + _random.nextDouble() * 0.5 / difficulty;
        break;
      case EnemyState.approach:
        stateTimer = 2.0;
        break;
      case EnemyState.retreat:
        stateTimer = 1.0;
        break;
      case EnemyState.jumpAttack:
        stateTimer = 1.5;
        break;
      case EnemyState.hurt:
        stateTimer = 0.3;
        break;
      case EnemyState.attack:
        break;
    }
  }

  void _startAttack(bool isAerial) {
    state = EnemyState.attack;
    isTelegraphing = true;
    telegraphTimer = AppDurations.enemyTelegraph.inMilliseconds / 1000 / difficulty;
  }

  void _executeAttack() {
    isTelegraphing = false;

    final isAerial = !isGrounded;
    attackCooldown = 1.5 / difficulty;

    // Calculate attack hitbox
    final hitboxX = facingRight
        ? position.x + size.x * 0.3
        : position.x - size.x * 0.3 - GameSizes.attackHitboxWidth * 1.2;
    final hitboxY = position.y - size.y * 0.5;
    final hitbox = Rect.fromLTWH(
      hitboxX,
      hitboxY,
      GameSizes.attackHitboxWidth * 1.2,
      GameSizes.attackHitboxHeight * 1.2,
    );

    onAttack?.call(hitbox, isAerial);

    // Return to idle after attack
    _transitionToState(EnemyState.idle);
  }

  void _updatePhysics(double dt) {
    // Apply gravity
    if (!isGrounded) {
      velocity.y += GamePhysics.gravity * dt;
      velocity.y = velocity.y.clamp(-GamePhysics.maxFallSpeed, GamePhysics.maxFallSpeed);
    }

    // Update position
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // Ground collision
    if (position.y >= groundY) {
      position.y = groundY;
      velocity.y = 0;
      isGrounded = true;
    } else {
      isGrounded = false;
    }
  }

  void _updateVisuals() {
    // Flip based on direction
    // TODO(Phase 4): Replace scale.x=-1 with flipHorizontallyAroundCenter()
    // when adding actual sprites, as negative scale may not render correctly.
    if (facingRight) {
      _visual.scale = Vector2(1, 1);
    } else {
      _visual.scale = Vector2(-1, 1);
    }

    // Invincibility flash
    if (isInvincible) {
      final flash = (invincibilityTimer * 10).floor() % 2 == 0;
      _visual.paint.color = flash ? AppColors.enemyHp : AppColors.enemyHp.withValues(alpha: 0.5);
    } else {
      _visual.paint.color = AppColors.enemyHp;
    }

    // Telegraph indicator
    _telegraphIndicator.paint.color = isTelegraphing
        ? Colors.red.withValues(alpha: 0.8)
        : Colors.red.withValues(alpha: 0.0);
  }

  /// Take damage
  void takeDamage(int damage) {
    if (isInvincible) return;

    hp -= damage;
    isInvincible = true;
    invincibilityTimer = 0.2;

    // Knockback
    velocity.x = facingRight
        ? GamePhysics.knockbackHorizontal
        : -GamePhysics.knockbackHorizontal;
    if (isGrounded) {
      velocity.y = -GamePhysics.knockbackVertical;
      isGrounded = false;
    }

    onDamage?.call(damage);

    if (hp <= 0) {
      onDeath?.call();
    } else {
      _transitionToState(EnemyState.hurt);
    }
  }

  /// React to player jumping
  void onPlayerJump() {
    // Random chance to also jump based on difficulty
    if (_random.nextDouble() < 0.3 * difficulty && isGrounded) {
      _transitionToState(EnemyState.jumpAttack);
    }
  }

  /// Check if enemy is dead
  bool get isDead => hp <= 0;

  /// Get HP percentage for health bar
  double get hpPercent => hp / maxHp;
}
