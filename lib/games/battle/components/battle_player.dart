import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import '../../effects/particle_effect.dart';

/// Player state for battle animations
enum BattlePlayerState {
  idle,
  walking,
  jumping,
  falling,
  attacking,
  aerialAttacking,
  shielding,
  hurt,
}

/// Battle player component with jump, attack, and shield mechanics.
///
/// Features:
/// - Left/right movement via joystick
/// - Jump with variable height (tap vs hold)
/// - Ground and aerial attacks
/// - Shield blocking
/// - Gravity and ground collision
class BattlePlayer extends PositionComponent with CollisionCallbacks {
  BattlePlayer({
    required Vector2 position,
    required this.groundY,
  }) : super(
          position: position,
          size: Vector2(GameSizes.playerWidth, GameSizes.playerHeight),
          anchor: Anchor.bottomCenter,
        );

  /// Y position of the ground
  final double groundY;

  /// Current velocity
  final Vector2 velocity = Vector2.zero();

  /// Movement input from joystick (-1 to 1)
  double horizontalInput = 0;

  /// Current player state
  BattlePlayerState state = BattlePlayerState.idle;

  /// Whether player is on ground
  bool isGrounded = true;

  /// Whether player is holding jump button
  bool isJumpHeld = false;

  /// Time since jump started (for variable height)
  double jumpHoldTime = 0;

  /// Whether player is currently attacking
  bool isAttacking = false;

  /// Attack timer
  double attackTimer = 0;

  /// Whether player is shielding
  bool isShielding = false;

  /// Shield timer
  double shieldTimer = 0;

  /// Shield cooldown timer
  double shieldCooldown = 0;

  /// Whether player is invincible (after taking damage)
  bool isInvincible = false;

  /// Invincibility timer
  double invincibilityTimer = 0;

  /// Whether player is facing right
  bool facingRight = true;

  /// Current HP
  int hp = GameConfig.playerBaseHp;

  /// Callback when player attacks (for hit detection)
  void Function(Rect hitbox, bool isAerial)? onAttack;

  /// Callback when player takes damage
  void Function(int damage)? onDamage;

  /// Callback when player jumps (for effects)
  VoidCallback? onJump;

  /// Callback when player lands (for effects)
  VoidCallback? onLand;

  // Visual components
  late RectangleComponent _visual;
  late RectangleComponent _shieldVisual;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Player visual (placeholder)
    _visual = RectangleComponent(
      size: size,
      paint: Paint()..color = AppColors.primary,
      anchor: Anchor.bottomCenter,
    );
    add(_visual);

    // Shield visual (hidden by default)
    _shieldVisual = RectangleComponent(
      size: Vector2(size.x * 1.5, size.y * 1.2),
      position: Vector2(-size.x * 0.25, -size.y * 0.1),
      paint: Paint()
        ..color = Colors.blue.withValues(alpha: 0.0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
      anchor: Anchor.bottomLeft,
    );
    add(_shieldVisual);

    // Add hitbox
    add(
      RectangleHitbox(
        size: Vector2(GameSizes.playerHitboxWidth, GameSizes.playerHitboxHeight),
        position: Vector2(
          (size.x - GameSizes.playerHitboxWidth) / 2,
          size.y - GameSizes.playerHitboxHeight,
        ),
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);

    _updateTimers(dt);
    _updateMovement(dt);
    _updatePhysics(dt);
    _updateState();
    _updateVisuals();
  }

  void _updateTimers(double dt) {
    // Attack timer
    if (isAttacking) {
      attackTimer -= dt;
      if (attackTimer <= 0) {
        isAttacking = false;
      }
    }

    // Shield timer
    if (isShielding) {
      shieldTimer -= dt;
      if (shieldTimer <= 0) {
        stopShield();
      }
    }

    // Shield cooldown
    if (shieldCooldown > 0) {
      shieldCooldown -= dt;
    }

    // Invincibility
    if (isInvincible) {
      invincibilityTimer -= dt;
      if (invincibilityTimer <= 0) {
        isInvincible = false;
      }
    }

    // Jump hold time
    if (isJumpHeld && !isGrounded) {
      jumpHoldTime += dt;
    }
  }

  void _updateMovement(double dt) {
    if (isAttacking || isShielding) return;

    // Horizontal movement
    if (horizontalInput.abs() > 0.1) {
      velocity.x = horizontalInput * GamePhysics.playerSpeed;
      facingRight = horizontalInput > 0;
    } else {
      // Apply friction
      if (velocity.x.abs() < GamePhysics.playerFriction * dt) {
        velocity.x = 0;
      } else {
        velocity.x -= GamePhysics.playerFriction * dt * velocity.x.sign;
      }
    }
  }

  void _updatePhysics(double dt) {
    // Apply gravity if not grounded
    if (!isGrounded) {
      velocity.y += GamePhysics.gravity * dt;
      velocity.y = velocity.y.clamp(-GamePhysics.maxFallSpeed, GamePhysics.maxFallSpeed);
    }

    // Variable jump height - reduce upward velocity when button released
    if (!isJumpHeld && velocity.y < 0) {
      velocity.y *= 0.9;
    }

    // Update position
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;

    // Ground collision
    if (position.y >= groundY) {
      position.y = groundY;
      velocity.y = 0;
      if (!isGrounded) {
        _onLand();
      }
      isGrounded = true;
    } else {
      isGrounded = false;
    }
  }

  void _onLand() {
    // Reset jump state
    isJumpHeld = false;
    jumpHoldTime = 0;

    // Spawn landing dust effect
    parent?.add(LandingDustEffect(position: position.clone()));
    onLand?.call();
  }

  void _updateState() {
    if (isAttacking) {
      state = isGrounded ? BattlePlayerState.attacking : BattlePlayerState.aerialAttacking;
    } else if (isShielding) {
      state = BattlePlayerState.shielding;
    } else if (!isGrounded) {
      state = velocity.y < 0 ? BattlePlayerState.jumping : BattlePlayerState.falling;
    } else if (velocity.x.abs() > 1) {
      state = BattlePlayerState.walking;
    } else {
      state = BattlePlayerState.idle;
    }
  }

  void _updateVisuals() {
    // Flip sprite based on direction
    if (facingRight) {
      _visual.scale = Vector2(1, 1);
    } else {
      _visual.scale = Vector2(-1, 1);
    }

    // Invincibility flash
    if (isInvincible) {
      final flash = (invincibilityTimer * 10).floor() % 2 == 0;
      _visual.paint.color = flash ? AppColors.primary : AppColors.primaryLight;
    } else {
      _visual.paint.color = AppColors.primary;
    }

    // Shield visual
    _shieldVisual.paint.color = isShielding
        ? Colors.blue.withValues(alpha: 0.5)
        : Colors.blue.withValues(alpha: 0.0);
  }

  /// Start jump (call when button pressed)
  void startJump() {
    if (!isGrounded || isAttacking || isShielding) return;

    isGrounded = false;
    isJumpHeld = true;
    jumpHoldTime = 0;
    velocity.y = -GamePhysics.jumpForce;

    // Spawn jump wind effect
    parent?.add(JumpWindEffect(position: position.clone()));
    onJump?.call();
  }

  /// End jump hold (call when button released)
  void endJump() {
    isJumpHeld = false;
  }

  /// Perform attack
  void attack() {
    if (isAttacking || isShielding) return;

    isAttacking = true;
    final isAerial = !isGrounded;
    attackTimer = isAerial
        ? GamePhysics.aerialAttackDuration
        : GamePhysics.attackDuration;

    // Calculate attack hitbox
    final hitboxX = facingRight
        ? position.x + size.x / 2
        : position.x - size.x / 2 - GameSizes.attackHitboxWidth;
    final hitboxY = position.y - size.y * 0.6;
    final hitbox = Rect.fromLTWH(
      hitboxX,
      hitboxY,
      GameSizes.attackHitboxWidth,
      GameSizes.attackHitboxHeight,
    );

    // Spawn attack slash effect
    final slashPosition = Vector2(
      facingRight ? position.x + size.x / 2 : position.x - size.x / 2,
      position.y - size.y * 0.5,
    );
    parent?.add(AttackSlashEffect(
      position: slashPosition,
      facingRight: facingRight,
      isAerial: isAerial,
    ));

    onAttack?.call(hitbox, isAerial);
  }

  /// Start shielding
  void startShield() {
    if (isShielding || isAttacking || shieldCooldown > 0) return;

    isShielding = true;
    shieldTimer = GamePhysics.shieldDuration;
  }

  /// Stop shielding
  void stopShield() {
    if (!isShielding) return;

    isShielding = false;
    shieldCooldown = GamePhysics.shieldCooldown;
  }

  /// Take damage
  void takeDamage(int damage) {
    if (isInvincible) return;

    if (isShielding) {
      // Blocked - reduce shield time
      shieldTimer -= 0.2;
      return;
    }

    hp -= damage;
    isInvincible = true;
    invincibilityTimer = GamePhysics.invincibilityDuration;

    // Spawn damage flash effect
    parent?.add(DamageFlashEffect(position: position.clone(), flashSize: size.clone()));

    // Knockback
    velocity.x = facingRight
        ? -GamePhysics.playerKnockbackHorizontal
        : GamePhysics.playerKnockbackHorizontal;
    if (isGrounded) {
      velocity.y = -GamePhysics.playerKnockbackVertical;
      isGrounded = false;
    }

    onDamage?.call(damage);
  }

  /// Set horizontal input from joystick
  void setHorizontalInput(double input) {
    horizontalInput = input.clamp(-1, 1);
  }

  /// Check if player is dead
  bool get isDead => hp <= 0;

  /// Get attack hitbox for current frame
  Rect? get currentAttackHitbox {
    if (!isAttacking) return null;

    final hitboxX = facingRight
        ? position.x + size.x / 2
        : position.x - size.x / 2 - GameSizes.attackHitboxWidth;
    final hitboxY = position.y - size.y * 0.6;

    return Rect.fromLTWH(
      hitboxX,
      hitboxY,
      GameSizes.attackHitboxWidth,
      GameSizes.attackHitboxHeight,
    );
  }
}
