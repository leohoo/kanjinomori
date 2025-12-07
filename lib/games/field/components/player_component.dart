import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../utils/constants.dart';
import 'door_component.dart';

/// Player state for animation selection
enum PlayerState {
  idle,
  walking,
}

/// Direction the player is facing (for sprite flipping)
enum PlayerDirection {
  left,
  right,
  up,
  down,
  upLeft,
  upRight,
  downLeft,
  downRight,
}

/// Player component for isometric field exploration.
///
/// Features:
/// - 8-directional movement via joystick
/// - Smooth acceleration/deceleration
/// - Collision detection with doors and boundaries
/// - Dust effect when moving at max speed
class PlayerComponent extends PositionComponent with CollisionCallbacks, HasGameReference {
  PlayerComponent({
    required Vector2 position,
  }) : super(
          position: position,
          size: Vector2(GameSizes.playerWidth, GameSizes.playerHeight),
          anchor: Anchor.bottomCenter,
        );

  /// Current velocity
  final Vector2 velocity = Vector2.zero();

  /// Movement input from joystick (-1 to 1 for each axis)
  Vector2 movementInput = Vector2.zero();

  /// Current player state
  PlayerState state = PlayerState.idle;

  /// Direction player is facing
  PlayerDirection direction = PlayerDirection.down;

  /// Whether player is at max speed (for dust effect)
  bool isAtMaxSpeed = false;

  /// Callback when player collides with a door
  void Function(PositionComponent door)? onDoorCollision;

  // Sprite animation components
  SpriteAnimationComponent? _runAnimation;
  SpriteComponent? _idleSprite;
  bool _facingRight = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Try to load sprites, fall back to placeholder if not available
    try {
      // Load runner spritesheet
      // The spritesheet has: RUN (6 frames), JUMP (2+2 frames), RUN_AND_SHOOT (6 frames)
      // Frame size is approximately 100x100
      final spriteSheet = await game.images.load('sprites/player/runner_spritesheet.png');

      // Create run animation from first row (6 frames, ~100x100 each)
      // Adjust these values based on actual sprite dimensions
      const frameWidth = 100.0;
      const frameHeight = 100.0;

      final runFrames = List.generate(6, (i) {
        return Sprite(
          spriteSheet,
          srcPosition: Vector2(i * frameWidth, 0),
          srcSize: Vector2(frameWidth, frameHeight),
        );
      });

      final runSpriteAnimation = SpriteAnimation.spriteList(
        runFrames,
        stepTime: 0.1,
      );

      _runAnimation = SpriteAnimationComponent(
        animation: runSpriteAnimation,
        size: size,
        anchor: Anchor.bottomCenter,
      );

      // Use first frame as idle
      _idleSprite = SpriteComponent(
        sprite: runFrames[0],
        size: size,
        anchor: Anchor.bottomCenter,
      );

      // Start with idle (will be managed by _updateAnimation on state changes)
      add(_idleSprite!);
    } catch (e) {
      // Fall back to placeholder rectangle (for tests or missing assets)
      add(RectangleComponent(
        size: size,
        paint: Paint()..color = AppColors.primary,
        anchor: Anchor.bottomCenter,
      ));
    }

    // Add hitbox for collision detection
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

    _updateVelocity(dt);
    _updatePosition(dt);
    _updateState();
    _updateDirection();
  }

  void _updateVelocity(double dt) {
    if (movementInput.length > 0) {
      // Accelerate towards input direction
      final targetVelocity = movementInput.normalized() * GamePhysics.playerSpeed;
      final acceleration = GamePhysics.playerAcceleration * dt;

      velocity.x = _moveTowards(velocity.x, targetVelocity.x, acceleration);
      velocity.y = _moveTowards(velocity.y, targetVelocity.y, acceleration);
    } else {
      // Apply friction when no input
      final friction = GamePhysics.playerFriction * dt;

      if (velocity.x.abs() < friction) {
        velocity.x = 0;
      } else {
        velocity.x -= friction * velocity.x.sign;
      }

      if (velocity.y.abs() < friction) {
        velocity.y = 0;
      } else {
        velocity.y -= friction * velocity.y.sign;
      }
    }

    // Check if at max speed
    isAtMaxSpeed = velocity.length > GamePhysics.playerSpeed * 0.9;
  }

  double _moveTowards(double current, double target, double maxDelta) {
    if ((target - current).abs() <= maxDelta) {
      return target;
    }
    return current + maxDelta * (target - current).sign;
  }

  void _updatePosition(double dt) {
    position += velocity * dt;
  }

  void _updateState() {
    final previousState = state;

    if (velocity.length > 1) {
      state = PlayerState.walking;
    } else {
      state = PlayerState.idle;
    }

    // Switch animations when state changes
    if (previousState != state) {
      _updateAnimation();
    }

    // Update facing direction
    if (velocity.x.abs() > 0.1) {
      final shouldFaceRight = velocity.x > 0;
      if (_facingRight != shouldFaceRight) {
        _facingRight = shouldFaceRight;
        _updateSpriteFlip();
      }
    }
  }

  void _updateAnimation() {
    // Always remove both sprites first to avoid overlap
    if (_idleSprite?.isMounted == true) {
      _idleSprite?.removeFromParent();
    }
    if (_runAnimation?.isMounted == true) {
      _runAnimation?.removeFromParent();
    }

    // Add the appropriate sprite based on state
    if (state == PlayerState.walking && _runAnimation != null) {
      add(_runAnimation!);
    } else if (_idleSprite != null) {
      add(_idleSprite!);
    }

    _updateSpriteFlip();
  }

  void _updateSpriteFlip() {
    final scaleX = _facingRight ? 1.0 : -1.0;
    // Only update the sprite that's currently mounted
    if (_idleSprite?.isMounted == true) {
      _idleSprite?.scale = Vector2(scaleX, 1);
    }
    if (_runAnimation?.isMounted == true) {
      _runAnimation?.scale = Vector2(scaleX, 1);
    }
  }

  void _updateDirection() {
    if (movementInput.length < 0.1) return;

    // Determine 8-way direction from input
    final angle = movementInput.angleTo(Vector2(1, 0));
    final degrees = angle * 180 / 3.14159;

    if (degrees >= -22.5 && degrees < 22.5) {
      direction = PlayerDirection.right;
    } else if (degrees >= 22.5 && degrees < 67.5) {
      direction = PlayerDirection.downRight;
    } else if (degrees >= 67.5 && degrees < 112.5) {
      direction = PlayerDirection.down;
    } else if (degrees >= 112.5 && degrees < 157.5) {
      direction = PlayerDirection.downLeft;
    } else if (degrees >= 157.5 || degrees < -157.5) {
      direction = PlayerDirection.left;
    } else if (degrees >= -157.5 && degrees < -112.5) {
      direction = PlayerDirection.upLeft;
    } else if (degrees >= -112.5 && degrees < -67.5) {
      direction = PlayerDirection.up;
    } else {
      direction = PlayerDirection.upRight;
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Notify about door collision
    if (other is DoorComponent) {
      onDoorCollision?.call(other);
    }
  }

  /// Set movement input from joystick (values should be -1 to 1)
  void setMovementInput(Vector2 input) {
    movementInput = input.clone();
  }
}
