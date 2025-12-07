import 'package:flame/components.dart';

/// Coordinates game flow between Field, Question, and Battle screens.
///
/// Responsibilities:
/// - Track door completion status per stage
/// - Manage field → question → field → battle flow
/// - Calculate correct answer ratios for damage bonuses
/// - Persist and restore game state
class GameCoordinator {
  GameCoordinator({
    required this.stageId,
    required this.totalDoors,
  })  : doorCompleted = List.filled(totalDoors, false),
        doorCorrect = List.filled(totalDoors, false);

  /// Current stage ID
  final int stageId;

  /// Total number of doors in the field
  final int totalDoors;

  /// Which doors have been completed
  final List<bool> doorCompleted;

  /// Whether each door's question was answered correctly
  final List<bool> doorCorrect;

  /// Last player position in the field (for resume)
  Vector2? lastFieldPosition;

  /// Currently active door index (-1 if none)
  int activeDoorIndex = -1;

  /// Current game phase
  GamePhase phase = GamePhase.field;

  /// Coins earned during this stage
  int coinsEarned = 0;

  /// Check if a specific door is completed
  bool isDoorCompleted(int index) {
    if (index < 0 || index >= totalDoors) return false;
    return doorCompleted[index];
  }

  /// Get list of completed door indices
  List<int> get completedDoors {
    final result = <int>[];
    for (var i = 0; i < totalDoors; i++) {
      if (doorCompleted[i]) result.add(i);
    }
    return result;
  }

  /// Check if all doors are completed
  bool get allDoorsCompleted {
    return doorCompleted.every((completed) => completed);
  }

  /// Number of completed doors
  int get completedCount {
    return doorCompleted.where((c) => c).length;
  }

  /// Number of correct answers
  int get correctCount {
    return doorCorrect.where((c) => c).length;
  }

  /// Ratio of correct answers (0.0 to 1.0)
  double get correctRatio {
    if (completedCount == 0) return 0.0;
    return correctCount / completedCount;
  }

  /// Calculate difficulty based on stage
  double get difficulty {
    // Stages 1-3: 1.0, 4-6: 1.2, 7-9: 1.4, 10: 1.5
    if (stageId <= 3) return 1.0;
    if (stageId <= 6) return 1.2;
    if (stageId <= 9) return 1.4;
    return 1.5;
  }

  /// Enter a door (transition to question screen)
  void enterDoor(int doorIndex) {
    if (doorIndex < 0 || doorIndex >= totalDoors) return;
    if (doorCompleted[doorIndex]) return;

    activeDoorIndex = doorIndex;
    phase = GamePhase.question;
  }

  /// Complete a door's question
  void completeDoor(int doorIndex, bool wasCorrect) {
    if (doorIndex < 0 || doorIndex >= totalDoors) return;

    doorCompleted[doorIndex] = true;
    doorCorrect[doorIndex] = wasCorrect;
    activeDoorIndex = -1;

    // Award coins for correct answer
    if (wasCorrect) {
      coinsEarned += 5;
    }

    // Check if all doors are done
    if (allDoorsCompleted) {
      // Award bonus if all correct
      if (correctCount == totalDoors) {
        coinsEarned += 10;
      }
      phase = GamePhase.battle;
    } else {
      phase = GamePhase.field;
    }
  }

  /// Start the battle phase
  void startBattle() {
    phase = GamePhase.battle;
  }

  /// Complete the battle
  void completeBattle(bool victory) {
    phase = victory ? GamePhase.victory : GamePhase.defeat;
  }

  /// Reset coordinator for a new attempt
  void reset() {
    for (var i = 0; i < totalDoors; i++) {
      doorCompleted[i] = false;
      doorCorrect[i] = false;
    }
    lastFieldPosition = null;
    activeDoorIndex = -1;
    phase = GamePhase.field;
    coinsEarned = 0;
  }

  /// Save state for persistence
  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'doorCompleted': doorCompleted,
      'doorCorrect': doorCorrect,
      'lastFieldPosition': lastFieldPosition != null
          ? {'x': lastFieldPosition!.x, 'y': lastFieldPosition!.y}
          : null,
      'activeDoorIndex': activeDoorIndex,
      'phase': phase.name,
      'coinsEarned': coinsEarned,
    };
  }

  /// Restore state from persistence
  factory GameCoordinator.fromJson(Map<String, dynamic> json) {
    final totalDoors = (json['doorCompleted'] as List).length;
    final coordinator = GameCoordinator(
      stageId: json['stageId'] as int,
      totalDoors: totalDoors,
    );

    for (var i = 0; i < totalDoors; i++) {
      coordinator.doorCompleted[i] = json['doorCompleted'][i] as bool;
      coordinator.doorCorrect[i] = json['doorCorrect'][i] as bool;
    }

    final posJson = json['lastFieldPosition'];
    if (posJson != null) {
      coordinator.lastFieldPosition = Vector2(
        (posJson['x'] as num).toDouble(),
        (posJson['y'] as num).toDouble(),
      );
    }

    coordinator.activeDoorIndex = json['activeDoorIndex'] as int;
    coordinator.phase = GamePhase.values.byName(json['phase'] as String);
    coordinator.coinsEarned = json['coinsEarned'] as int;

    return coordinator;
  }
}

/// Game phase within a stage
enum GamePhase {
  /// Player is exploring the field
  field,

  /// Player is answering a question
  question,

  /// Player is in boss battle
  battle,

  /// Player won the stage
  victory,

  /// Player lost the stage
  defeat,
}
