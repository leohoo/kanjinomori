import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_game/games/battle/components/battle_player.dart';
import 'package:kanji_game/games/battle/components/battle_enemy.dart';
import 'package:kanji_game/utils/constants.dart';

void main() {
  group('BattlePlayer', () {
    test('should initialize with correct position and HP', () {
      final player = BattlePlayer(
        position: Vector2(100, 300),
        groundY: 300,
      );

      expect(player.position, Vector2(100, 300));
      expect(player.hp, GameConfig.playerBaseHp);
      expect(player.state, BattlePlayerState.idle);
      expect(player.isGrounded, true);
    });

    test('should start jump when grounded', () {
      final player = BattlePlayer(
        position: Vector2(100, 300),
        groundY: 300,
      );

      player.startJump();

      expect(player.isGrounded, false);
      expect(player.velocity.y, lessThan(0)); // Moving up
    });

    test('should not jump when already in air', () {
      final player = BattlePlayer(
        position: Vector2(100, 200),
        groundY: 300,
      );
      player.isGrounded = false;
      player.velocity.y = 50;

      final velocityBefore = player.velocity.y;
      player.startJump();

      expect(player.velocity.y, velocityBefore); // Unchanged
    });

    test('should apply gravity when not grounded', () async {
      final player = BattlePlayer(
        position: Vector2(100, 200),
        groundY: 300,
      );
      await player.onLoad();
      player.isGrounded = false;
      player.velocity.y = 0;

      player.update(0.1); // 100ms

      expect(player.velocity.y, greaterThan(0)); // Falling
    });

    test('should land when reaching ground', () async {
      final player = BattlePlayer(
        position: Vector2(100, 290),
        groundY: 300,
      );
      await player.onLoad();
      player.isGrounded = false;
      player.velocity.y = 50;

      player.update(0.5); // Update until landing

      expect(player.position.y, 300);
      expect(player.isGrounded, true);
    });

    test('should perform attack', () async {
      final player = BattlePlayer(
        position: Vector2(100, 300),
        groundY: 300,
      );
      await player.onLoad();

      bool attackCalled = false;
      player.onAttack = (hitbox, isAerial) {
        attackCalled = true;
        expect(isAerial, false); // Ground attack
      };

      player.attack();

      expect(player.isAttacking, true);
      expect(attackCalled, true);
    });

    test('should perform aerial attack when in air', () async {
      final player = BattlePlayer(
        position: Vector2(100, 200),
        groundY: 300,
      );
      await player.onLoad();
      player.isGrounded = false;

      bool attackCalled = false;
      player.onAttack = (hitbox, isAerial) {
        attackCalled = true;
        expect(isAerial, true); // Aerial attack
      };

      player.attack();

      expect(attackCalled, true);
    });

    test('should take damage and become invincible', () async {
      final player = BattlePlayer(
        position: Vector2(100, 300),
        groundY: 300,
      );
      await player.onLoad();

      final initialHp = player.hp;
      player.takeDamage(10);

      expect(player.hp, initialHp - 10);
      expect(player.isInvincible, true);
    });

    test('should block damage when shielding', () async {
      final player = BattlePlayer(
        position: Vector2(100, 300),
        groundY: 300,
      );
      await player.onLoad();

      player.startShield();
      final initialHp = player.hp;
      player.takeDamage(10);

      expect(player.hp, initialHp); // No damage taken
      expect(player.isShielding, true);
    });

    test('should not take damage when invincible', () async {
      final player = BattlePlayer(
        position: Vector2(100, 300),
        groundY: 300,
      );
      await player.onLoad();

      player.takeDamage(10);
      final hpAfterFirstHit = player.hp;
      player.takeDamage(10); // Should be ignored

      expect(player.hp, hpAfterFirstHit);
    });

    test('should be dead when HP reaches 0', () async {
      final player = BattlePlayer(
        position: Vector2(100, 300),
        groundY: 300,
      );
      await player.onLoad();

      player.takeDamage(player.hp);

      expect(player.isDead, true);
    });

    test('should update facing direction based on movement', () async {
      final player = BattlePlayer(
        position: Vector2(100, 300),
        groundY: 300,
      );
      await player.onLoad();

      player.setHorizontalInput(1);
      player.update(0.1);
      expect(player.facingRight, true);

      player.setHorizontalInput(-1);
      player.update(0.1);
      expect(player.facingRight, false);
    });
  });

  group('BattleEnemy', () {
    late PositionComponent mockPlayer;

    setUp(() {
      mockPlayer = PositionComponent(position: Vector2(100, 300));
    });

    test('should initialize with HP based on difficulty', () async {
      final enemy = BattleEnemy(
        position: Vector2(400, 300),
        groundY: 300,
        playerRef: mockPlayer,
        difficulty: 1.5,
      );
      await enemy.onLoad();

      expect(enemy.maxHp, 150); // 100 * 1.5
    });

    test('should face player', () async {
      final enemy = BattleEnemy(
        position: Vector2(400, 300),
        groundY: 300,
        playerRef: mockPlayer,
        difficulty: 1.0,
      );
      await enemy.onLoad();

      // Player is at x=100, enemy at x=400
      enemy.update(0.1);

      expect(enemy.facingRight, false); // Should face left towards player
    });

    test('should take damage and trigger callback', () async {
      final enemy = BattleEnemy(
        position: Vector2(400, 300),
        groundY: 300,
        playerRef: mockPlayer,
        difficulty: 1.0,
      );
      await enemy.onLoad();

      int? damageTaken;
      enemy.onDamage = (damage) => damageTaken = damage;

      enemy.takeDamage(25);

      expect(damageTaken, 25);
      expect(enemy.hp, 75);
    });

    test('should trigger death callback when HP reaches 0', () async {
      final enemy = BattleEnemy(
        position: Vector2(400, 300),
        groundY: 300,
        playerRef: mockPlayer,
        difficulty: 1.0,
      );
      await enemy.onLoad();

      bool deathCalled = false;
      enemy.onDeath = () => deathCalled = true;

      enemy.takeDamage(100);

      expect(deathCalled, true);
      expect(enemy.isDead, true);
    });

    test('should become invincible after taking damage', () async {
      final enemy = BattleEnemy(
        position: Vector2(400, 300),
        groundY: 300,
        playerRef: mockPlayer,
        difficulty: 1.0,
      );
      await enemy.onLoad();

      enemy.takeDamage(10);
      expect(enemy.isInvincible, true);

      final hpAfterFirstHit = enemy.hp;
      enemy.takeDamage(10); // Should be ignored

      expect(enemy.hp, hpAfterFirstHit);
    });

    test('should calculate HP percentage correctly', () async {
      final enemy = BattleEnemy(
        position: Vector2(400, 300),
        groundY: 300,
        playerRef: mockPlayer,
        difficulty: 1.0,
      );
      await enemy.onLoad();

      expect(enemy.hpPercent, 1.0);

      enemy.isInvincible = false; // Allow damage
      enemy.takeDamage(50);

      expect(enemy.hpPercent, 0.5);
    });
  });
}
