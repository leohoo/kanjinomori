import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_game/games/coordinator/game_coordinator.dart';

void main() {
  group('GameCoordinator', () {
    late GameCoordinator coordinator;

    setUp(() {
      coordinator = GameCoordinator(stageId: 1, totalDoors: 10);
    });

    test('should initialize with correct defaults', () {
      expect(coordinator.stageId, equals(1));
      expect(coordinator.totalDoors, equals(10));
      expect(coordinator.phase, equals(GamePhase.field));
      expect(coordinator.completedCount, equals(0));
      expect(coordinator.correctCount, equals(0));
      expect(coordinator.coinsEarned, equals(0));
      expect(coordinator.activeDoorIndex, equals(-1));
    });

    test('should track door completion', () {
      expect(coordinator.isDoorCompleted(0), isFalse);

      coordinator.enterDoor(0);
      coordinator.completeDoor(0, true);

      expect(coordinator.isDoorCompleted(0), isTrue);
      expect(coordinator.completedCount, equals(1));
    });

    test('should track correct answers', () {
      coordinator.enterDoor(0);
      coordinator.completeDoor(0, true);

      coordinator.enterDoor(1);
      coordinator.completeDoor(1, false);

      coordinator.enterDoor(2);
      coordinator.completeDoor(2, true);

      expect(coordinator.correctCount, equals(2));
      expect(coordinator.completedCount, equals(3));
    });

    test('should calculate correct ratio', () {
      // Complete 2 correct, 2 wrong
      coordinator.enterDoor(0);
      coordinator.completeDoor(0, true);

      coordinator.enterDoor(1);
      coordinator.completeDoor(1, false);

      coordinator.enterDoor(2);
      coordinator.completeDoor(2, true);

      coordinator.enterDoor(3);
      coordinator.completeDoor(3, false);

      expect(coordinator.correctRatio, equals(0.5));
    });

    test('should award coins for correct answers', () {
      coordinator.enterDoor(0);
      coordinator.completeDoor(0, true);
      expect(coordinator.coinsEarned, equals(5));

      coordinator.enterDoor(1);
      coordinator.completeDoor(1, false);
      expect(coordinator.coinsEarned, equals(5)); // No additional coins

      coordinator.enterDoor(2);
      coordinator.completeDoor(2, true);
      expect(coordinator.coinsEarned, equals(10));
    });

    test('should transition to question phase on door enter', () {
      expect(coordinator.phase, equals(GamePhase.field));

      coordinator.enterDoor(0);

      expect(coordinator.phase, equals(GamePhase.question));
      expect(coordinator.activeDoorIndex, equals(0));
    });

    test('should transition to field phase after question', () {
      coordinator.enterDoor(0);
      expect(coordinator.phase, equals(GamePhase.question));

      coordinator.completeDoor(0, true);

      expect(coordinator.phase, equals(GamePhase.field));
      expect(coordinator.activeDoorIndex, equals(-1));
    });

    test('should transition to battle when all doors completed', () {
      // Complete all 10 doors
      for (var i = 0; i < 10; i++) {
        coordinator.enterDoor(i);
        coordinator.completeDoor(i, i % 2 == 0); // Alternate correct/wrong
      }

      expect(coordinator.allDoorsCompleted, isTrue);
      expect(coordinator.phase, equals(GamePhase.battle));
    });

    test('should award bonus for all correct', () {
      // Complete all doors correctly
      for (var i = 0; i < 10; i++) {
        coordinator.enterDoor(i);
        coordinator.completeDoor(i, true);
      }

      // 5 coins * 10 doors + 10 bonus = 60
      expect(coordinator.coinsEarned, equals(60));
    });

    test('should not allow entering completed door', () {
      coordinator.enterDoor(0);
      coordinator.completeDoor(0, true);

      // Try to enter same door again
      coordinator.enterDoor(0);

      expect(coordinator.phase, equals(GamePhase.field));
      expect(coordinator.activeDoorIndex, equals(-1));
    });

    test('should complete battle with victory', () {
      // Complete all doors first
      for (var i = 0; i < 10; i++) {
        coordinator.enterDoor(i);
        coordinator.completeDoor(i, true);
      }

      expect(coordinator.phase, equals(GamePhase.battle));

      coordinator.completeBattle(true);

      expect(coordinator.phase, equals(GamePhase.victory));
    });

    test('should complete battle with defeat', () {
      for (var i = 0; i < 10; i++) {
        coordinator.enterDoor(i);
        coordinator.completeDoor(i, true);
      }

      coordinator.completeBattle(false);

      expect(coordinator.phase, equals(GamePhase.defeat));
    });

    test('should calculate difficulty based on stage', () {
      expect(GameCoordinator(stageId: 1, totalDoors: 10).difficulty, equals(1.0));
      expect(GameCoordinator(stageId: 3, totalDoors: 10).difficulty, equals(1.0));
      expect(GameCoordinator(stageId: 4, totalDoors: 10).difficulty, equals(1.2));
      expect(GameCoordinator(stageId: 6, totalDoors: 10).difficulty, equals(1.2));
      expect(GameCoordinator(stageId: 7, totalDoors: 10).difficulty, equals(1.4));
      expect(GameCoordinator(stageId: 9, totalDoors: 10).difficulty, equals(1.4));
      expect(GameCoordinator(stageId: 10, totalDoors: 10).difficulty, equals(1.5));
    });

    test('should reset to initial state', () {
      coordinator.enterDoor(0);
      coordinator.completeDoor(0, true);
      coordinator.lastFieldPosition = Vector2(100, 200);

      coordinator.reset();

      expect(coordinator.completedCount, equals(0));
      expect(coordinator.coinsEarned, equals(0));
      expect(coordinator.phase, equals(GamePhase.field));
      expect(coordinator.lastFieldPosition, isNull);
      expect(coordinator.activeDoorIndex, equals(-1));
    });

    group('serialization', () {
      test('should serialize to JSON', () {
        coordinator.enterDoor(0);
        coordinator.completeDoor(0, true);
        coordinator.lastFieldPosition = Vector2(100, 200);

        final json = coordinator.toJson();

        expect(json['stageId'], equals(1));
        expect(json['doorCompleted'][0], isTrue);
        expect(json['doorCorrect'][0], isTrue);
        expect(json['lastFieldPosition']['x'], equals(100));
        expect(json['lastFieldPosition']['y'], equals(200));
        expect(json['coinsEarned'], equals(5));
        expect(json['phase'], equals('field'));
      });

      test('should deserialize from JSON', () {
        coordinator.enterDoor(0);
        coordinator.completeDoor(0, true);
        coordinator.enterDoor(1);
        coordinator.completeDoor(1, false);
        coordinator.lastFieldPosition = Vector2(150, 250);

        final json = coordinator.toJson();
        final restored = GameCoordinator.fromJson(json);

        expect(restored.stageId, equals(1));
        expect(restored.isDoorCompleted(0), isTrue);
        expect(restored.isDoorCompleted(1), isTrue);
        expect(restored.isDoorCompleted(2), isFalse);
        expect(restored.correctCount, equals(1));
        expect(restored.lastFieldPosition?.x, equals(150));
        expect(restored.lastFieldPosition?.y, equals(250));
        expect(restored.coinsEarned, equals(5));
      });
    });

    group('edge cases', () {
      test('should handle invalid door indices', () {
        coordinator.enterDoor(-1);
        expect(coordinator.activeDoorIndex, equals(-1));

        coordinator.enterDoor(100);
        expect(coordinator.activeDoorIndex, equals(-1));
      });

      test('should return 0 ratio when no doors completed', () {
        expect(coordinator.correctRatio, equals(0.0));
      });

      test('should return completed doors list', () {
        coordinator.enterDoor(2);
        coordinator.completeDoor(2, true);
        coordinator.enterDoor(5);
        coordinator.completeDoor(5, false);

        final completed = coordinator.completedDoors;

        expect(completed, contains(2));
        expect(completed, contains(5));
        expect(completed.length, equals(2));
      });
    });
  });
}
