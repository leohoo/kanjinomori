import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Base class for screen transitions
abstract class ScreenTransition extends PositionComponent {
  ScreenTransition({
    required this.screenSize,
    required this.duration,
    this.onComplete,
  });

  final Vector2 screenSize;
  final double duration;
  final VoidCallback? onComplete;

  double elapsed = 0;
  double get progress => (elapsed / duration).clamp(0, 1);
  bool _completed = false;

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= duration && !_completed) {
      _completed = true;
      onComplete?.call();
    }
  }
}

/// Door opening transition (field → question)
class DoorOpenTransition extends ScreenTransition {
  DoorOpenTransition({
    required super.screenSize,
    required this.doorPosition,
    super.onComplete,
  }) : super(duration: 0.6);

  final Vector2 doorPosition;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Expanding white circle from door position
    final maxRadius = screenSize.length;
    final radius = maxRadius * _easeOutCubic(progress);

    final paint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(doorPosition.x, doorPosition.y),
      radius,
      paint,
    );
  }

  double _easeOutCubic(double t) => 1 - pow(1 - t, 3).toDouble();
}

/// Door close transition (question → field)
class DoorCloseTransition extends ScreenTransition {
  DoorCloseTransition({
    required super.screenSize,
    required this.doorPosition,
    super.onComplete,
  }) : super(duration: 0.5);

  final Vector2 doorPosition;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Shrinking white circle to door position
    final maxRadius = screenSize.length;
    final radius = maxRadius * (1 - _easeInCubic(progress));

    // Draw full screen first
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
      bgPaint,
    );

    // Cut out circle (reveal game underneath)
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Rect.fromLTWH(0, 0, screenSize.x, screenSize.y), Paint());
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
      bgPaint,
    );
    canvas.drawCircle(
      Offset(doorPosition.x, doorPosition.y),
      radius,
      clearPaint,
    );
    canvas.restore();
  }

  double _easeInCubic(double t) => t * t * t;
}

/// Battle teleport transition (field → battle)
class BattleTeleportTransition extends ScreenTransition {
  BattleTeleportTransition({
    required super.screenSize,
    super.onComplete,
  }) : super(duration: 1.2);

  final Random _random = Random();
  late List<_TeleportLine> _lines;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Generate vertical teleport lines
    final lineCount = 30 + _random.nextInt(20);
    _lines = List.generate(lineCount, (i) {
      return _TeleportLine(
        x: _random.nextDouble() * screenSize.x,
        width: 2 + _random.nextDouble() * 4,
        delay: _random.nextDouble() * 0.3,
        speed: 1.5 + _random.nextDouble() * 1.0,
      );
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Phase 1: Lines appear and rush upward (0-0.6)
    // Phase 2: White flash (0.6-0.8)
    // Phase 3: Fade to reveal new scene (0.8-1.0)

    if (progress < 0.6) {
      // Teleport lines
      final lineProgress = progress / 0.6;
      for (final line in _lines) {
        if (lineProgress < line.delay / 0.3) continue;

        final adjustedProgress = (lineProgress - line.delay / 0.3) / (1 - line.delay / 0.3);
        final y = screenSize.y * (1 - adjustedProgress * line.speed);
        final height = 50 + adjustedProgress * 200;
        final opacity = (1 - adjustedProgress) * 0.8;

        final paint = Paint()
          ..color = AppColors.primaryLight.withValues(alpha: opacity);
        canvas.drawRect(
          Rect.fromLTWH(line.x, y - height, line.width, height),
          paint,
        );
      }
    } else if (progress < 0.8) {
      // White flash
      final flashProgress = (progress - 0.6) / 0.2;
      final opacity = flashProgress < 0.5 ? flashProgress * 2 : 1.0;
      final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
        paint,
      );
    } else {
      // Fade out
      final fadeProgress = (progress - 0.8) / 0.2;
      final opacity = 1 - fadeProgress;
      final paint = Paint()..color = Colors.white.withValues(alpha: opacity);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
        paint,
      );
    }
  }
}

class _TeleportLine {
  _TeleportLine({
    required this.x,
    required this.width,
    required this.delay,
    required this.speed,
  });

  final double x;
  final double width;
  final double delay;
  final double speed;
}

/// Victory transition
class VictoryTransition extends ScreenTransition {
  VictoryTransition({
    required super.screenSize,
    super.onComplete,
  }) : super(duration: 1.5);

  final Random _random = Random();
  late List<_ConfettiParticle> _confetti;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Generate confetti
    final confettiCount = 50 + _random.nextInt(30);
    _confetti = List.generate(confettiCount, (i) {
      return _ConfettiParticle(
        x: _random.nextDouble() * screenSize.x,
        y: -20 - _random.nextDouble() * 100,
        vx: (_random.nextDouble() - 0.5) * 100,
        vy: 150 + _random.nextDouble() * 200,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 10,
        color: _confettiColors[_random.nextInt(_confettiColors.length)],
        size: 6 + _random.nextDouble() * 8,
      );
    });
  }

  static const _confettiColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
  ];

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Background flash
    if (progress < 0.2) {
      final flashProgress = progress / 0.2;
      final opacity = sin(flashProgress * pi) * 0.3;
      final paint = Paint()..color = Colors.yellow.withValues(alpha: opacity);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
        paint,
      );
    }

    // Confetti
    for (final particle in _confetti) {
      final x = particle.x + particle.vx * elapsed;
      final y = particle.y + particle.vy * elapsed;
      final rotation = particle.rotation + particle.rotationSpeed * elapsed;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()..color = particle.color.withValues(alpha: 0.9);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.6),
        paint,
      );

      canvas.restore();
    }
  }
}

class _ConfettiParticle {
  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.rotationSpeed,
    required this.color,
    required this.size,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double rotation;
  final double rotationSpeed;
  final Color color;
  final double size;
}

/// Defeat transition (dark fade with shake)
class DefeatTransition extends ScreenTransition {
  DefeatTransition({
    required super.screenSize,
    super.onComplete,
  }) : super(duration: 1.0);

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Screen shake effect in early phase
    if (progress < 0.3) {
      final shakeIntensity = (1 - progress / 0.3) * 5;
      final offsetX = sin(elapsed * 50) * shakeIntensity;
      final offsetY = cos(elapsed * 50) * shakeIntensity;
      canvas.translate(offsetX, offsetY);
    }

    // Red flash then dark fade
    Color overlayColor;
    if (progress < 0.2) {
      // Red flash
      final flashProgress = progress / 0.2;
      overlayColor = Colors.red.withValues(alpha: flashProgress * 0.5);
    } else {
      // Fade to dark
      final fadeProgress = (progress - 0.2) / 0.8;
      final redOpacity = 0.5 * (1 - fadeProgress);
      final blackOpacity = fadeProgress * 0.8;
      overlayColor = Color.lerp(
        Colors.red.withValues(alpha: redOpacity),
        Colors.black.withValues(alpha: blackOpacity),
        fadeProgress,
      )!;
    }

    final paint = Paint()..color = overlayColor;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
      paint,
    );
  }
}

/// Simple fade transition
class FadeTransition extends ScreenTransition {
  FadeTransition({
    required super.screenSize,
    super.onComplete,
    this.fadeIn = true,
    this.color = Colors.black,
    super.duration = 0.3,
  });

  final bool fadeIn;
  final Color color;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final opacity = fadeIn ? (1 - progress) : progress;
    final paint = Paint()..color = color.withValues(alpha: opacity);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
      paint,
    );
  }
}
