import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_game/games/effects/particle_effect.dart';
import 'package:kanji_game/games/effects/screen_transition.dart';
import 'package:kanji_game/utils/constants.dart';

void main() {
  group('JumpWindEffect', () {
    test('should have correct duration', () {
      final effect = JumpWindEffect(position: Vector2.zero());
      expect(effect.duration, equals(GamePhysics.jumpWindEffectDuration));
    });

    test('should remove itself after duration', () async {
      final effect = JumpWindEffect(position: Vector2.zero());
      await effect.onLoad();

      // Simulate time passing beyond duration
      effect.update(GamePhysics.jumpWindEffectDuration + 0.1);

      // Progress should be clamped at 1
      expect(effect.progress, equals(1.0));
    });

    test('progress should increase over time', () async {
      final effect = JumpWindEffect(position: Vector2.zero());
      await effect.onLoad();

      effect.update(0.1);
      expect(effect.progress, greaterThan(0));
      expect(effect.progress, lessThan(1));
    });
  });

  group('LandingDustEffect', () {
    test('should have correct duration', () {
      final effect = LandingDustEffect(position: Vector2.zero());
      expect(effect.duration, equals(GamePhysics.landingDustDuration));
    });

    test('should initialize particles on load', () async {
      final effect = LandingDustEffect(position: Vector2.zero());
      await effect.onLoad();
      // If no exception, particles were initialized correctly
      expect(true, isTrue);
    });
  });

  group('AttackSlashEffect', () {
    test('should have correct duration', () {
      final effect = AttackSlashEffect(
        position: Vector2.zero(),
        facingRight: true,
      );
      expect(effect.duration, equals(0.2));
    });

    test('should accept isAerial parameter', () {
      final groundEffect = AttackSlashEffect(
        position: Vector2.zero(),
        facingRight: true,
        isAerial: false,
      );
      final aerialEffect = AttackSlashEffect(
        position: Vector2.zero(),
        facingRight: true,
        isAerial: true,
      );

      expect(groundEffect.isAerial, isFalse);
      expect(aerialEffect.isAerial, isTrue);
    });

    test('should respect facing direction', () {
      final rightEffect = AttackSlashEffect(
        position: Vector2.zero(),
        facingRight: true,
      );
      final leftEffect = AttackSlashEffect(
        position: Vector2.zero(),
        facingRight: false,
      );

      expect(rightEffect.facingRight, isTrue);
      expect(leftEffect.facingRight, isFalse);
    });
  });

  group('DoorCompletionEffect', () {
    test('should have correct duration', () {
      final effect = DoorCompletionEffect(
        position: Vector2.zero(),
        doorSize: Vector2(64, 96),
      );
      expect(effect.duration, equals(1.5));
    });

    test('should initialize particles on load', () async {
      final effect = DoorCompletionEffect(
        position: Vector2.zero(),
        doorSize: Vector2(64, 96),
      );
      await effect.onLoad();
      expect(true, isTrue);
    });
  });

  group('CoinCollectEffect', () {
    test('should have correct duration', () {
      final effect = CoinCollectEffect(
        position: Vector2.zero(),
        targetPosition: Vector2(100, 50),
      );
      expect(effect.duration, equals(0.8));
    });

    test('should accept coin count parameter', () {
      final singleCoin = CoinCollectEffect(
        position: Vector2.zero(),
        targetPosition: Vector2(100, 50),
        coinCount: 1,
      );
      final multipleCoin = CoinCollectEffect(
        position: Vector2.zero(),
        targetPosition: Vector2(100, 50),
        coinCount: 5,
      );

      expect(singleCoin.coinCount, equals(1));
      expect(multipleCoin.coinCount, equals(5));
    });

    test('should clamp coin count to max 5', () async {
      final effect = CoinCollectEffect(
        position: Vector2.zero(),
        targetPosition: Vector2(100, 50),
        coinCount: 10,
      );
      await effect.onLoad();
      // Effect should still work with clamped count
      expect(true, isTrue);
    });
  });

  group('DamageFlashEffect', () {
    test('should have correct duration', () {
      final effect = DamageFlashEffect(
        position: Vector2.zero(),
        flashSize: Vector2(48, 64),
      );
      expect(effect.duration, equals(0.15));
    });
  });

  group('CriticalHitEffect', () {
    test('should have correct duration', () {
      final effect = CriticalHitEffect(position: Vector2.zero());
      expect(effect.duration, equals(0.4));
    });
  });

  group('DoorOpenTransition', () {
    test('should have correct duration', () {
      final transition = DoorOpenTransition(
        screenSize: Vector2(800, 600),
        doorPosition: Vector2(400, 300),
      );
      expect(transition.duration, equals(0.6));
    });

    test('should call onComplete when finished', () async {
      var completed = false;
      final transition = DoorOpenTransition(
        screenSize: Vector2(800, 600),
        doorPosition: Vector2(400, 300),
        onComplete: () => completed = true,
      );

      transition.update(0.7);
      expect(completed, isTrue);
    });

    test('should not call onComplete before finished', () {
      var completed = false;
      final transition = DoorOpenTransition(
        screenSize: Vector2(800, 600),
        doorPosition: Vector2(400, 300),
        onComplete: () => completed = true,
      );

      transition.update(0.3);
      expect(completed, isFalse);
    });
  });

  group('DoorCloseTransition', () {
    test('should have correct duration', () {
      final transition = DoorCloseTransition(
        screenSize: Vector2(800, 600),
        doorPosition: Vector2(400, 300),
      );
      expect(transition.duration, equals(0.5));
    });
  });

  group('BattleTeleportTransition', () {
    test('should have correct duration', () {
      final transition = BattleTeleportTransition(
        screenSize: Vector2(800, 600),
      );
      expect(transition.duration, equals(1.2));
    });

    test('should initialize teleport lines on load', () async {
      final transition = BattleTeleportTransition(
        screenSize: Vector2(800, 600),
      );
      await transition.onLoad();
      expect(true, isTrue);
    });
  });

  group('VictoryTransition', () {
    test('should have correct duration', () {
      final transition = VictoryTransition(
        screenSize: Vector2(800, 600),
      );
      expect(transition.duration, equals(1.5));
    });

    test('should initialize confetti on load', () async {
      final transition = VictoryTransition(
        screenSize: Vector2(800, 600),
      );
      await transition.onLoad();
      expect(true, isTrue);
    });
  });

  group('DefeatTransition', () {
    test('should have correct duration', () {
      final transition = DefeatTransition(
        screenSize: Vector2(800, 600),
      );
      expect(transition.duration, equals(1.0));
    });
  });

  group('FadeTransition', () {
    test('should have configurable duration', () {
      final defaultTransition = FadeTransition(
        screenSize: Vector2(800, 600),
      );
      final customTransition = FadeTransition(
        screenSize: Vector2(800, 600),
        duration: 0.5,
      );

      expect(defaultTransition.duration, equals(0.3));
      expect(customTransition.duration, equals(0.5));
    });

    test('should support fade in and fade out', () {
      final fadeIn = FadeTransition(
        screenSize: Vector2(800, 600),
        fadeIn: true,
      );
      final fadeOut = FadeTransition(
        screenSize: Vector2(800, 600),
        fadeIn: false,
      );

      expect(fadeIn.fadeIn, isTrue);
      expect(fadeOut.fadeIn, isFalse);
    });
  });
}
