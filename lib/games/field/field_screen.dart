import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'field_game.dart';

/// Flutter screen wrapper for the isometric field exploration game.
///
/// This screen embeds the Flame game widget and handles:
/// - Door interaction callbacks
/// - Navigation to question screens
/// - Returning from questions with results
///
/// Usage:
/// ```dart
/// final fieldScreenKey = GlobalKey<FieldScreenState>();
/// FieldScreen(key: fieldScreenKey, ...);
/// // Later: fieldScreenKey.currentState?.onQuestionComplete(doorIndex, true);
/// ```
class FieldScreen extends StatefulWidget {
  const FieldScreen({
    super.key,
    required this.stageId,
    required this.onDoorEnter,
    required this.onAllDoorsCompleted,
    this.completedDoors = const [],
    this.onBack,
  });

  /// Current stage ID
  final String stageId;

  /// Callback when player enters a door
  final void Function(int doorIndex) onDoorEnter;

  /// Callback when all 10 doors are completed
  final VoidCallback onAllDoorsCompleted;

  /// List of already completed door indices
  final List<int> completedDoors;

  /// Callback when back button is pressed
  final VoidCallback? onBack;

  @override
  State<FieldScreen> createState() => FieldScreenState();
}

/// Public state class to allow external access via GlobalKey.
class FieldScreenState extends State<FieldScreen> {
  late FieldGame _game;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  void _initGame() {
    _game = FieldGame(
      onDoorEnter: _handleDoorEnter,
      completedDoors: widget.completedDoors,
    );
  }

  @override
  void didUpdateWidget(FieldScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reinitialize game if completed doors changed (compare contents, not reference)
    if (!listEquals(widget.completedDoors, oldWidget.completedDoors)) {
      _initGame();
    }
  }

  void _handleDoorEnter(int doorIndex) {
    // Pause game while in question screen
    _game.pauseEngine();

    // Notify parent
    widget.onDoorEnter(doorIndex);
  }

  /// Called when returning from question screen.
  /// Access via GlobalKey: `fieldScreenKey.currentState?.onQuestionComplete(doorIndex, true)`
  void onQuestionComplete(int doorIndex, bool correct) {
    // Resume game
    _game.resumeEngine();

    if (correct) {
      // Mark door as completed
      _game.completeDoor(doorIndex);

      // Check if all doors completed
      if (_game.allDoorsCompleted) {
        widget.onAllDoorsCompleted();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Flame game
          GameWidget(game: _game),

          // Top HUD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),

                  // Door progress
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Doors: ${widget.completedDoors.length}/10',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
