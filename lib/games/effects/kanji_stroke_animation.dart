import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Rainbow color palette for kanji animations (10 colors for 10 kanjis)
const List<Color> kanjiColors = [
  Color(0xFFFF6B6B), // Coral Red
  Color(0xFFFF9F43), // Orange
  Color(0xFFFFD93D), // Yellow
  Color(0xFF6BCB77), // Green
  Color(0xFF4ECDC4), // Teal
  Color(0xFF45B7D1), // Sky Blue
  Color(0xFF6C5CE7), // Purple
  Color(0xFFA55EEA), // Violet
  Color(0xFFF78FB3), // Pink
  Color(0xFF7BED9F), // Mint
];

/// Animates a single kanji being written stroke by stroke
class KanjiStrokeAnimation extends PositionComponent {
  KanjiStrokeAnimation({
    required this.kanji,
    required this.strokes,
    required this.strokeColor,
    required this.kanjiSize,
    this.wasCorrect = true,
    this.onComplete,
  }) : super(size: Vector2.all(kanjiSize));

  /// The kanji character being animated
  final String kanji;

  /// Stroke data: list of strokes, each stroke is a list of normalized points
  final List<List<Offset>> strokes;

  /// Primary color for the stroke animation
  final Color strokeColor;

  /// Size of the kanji box
  final double kanjiSize;

  /// Whether this kanji was answered correctly
  final bool wasCorrect;

  /// Callback when animation is complete
  final VoidCallback? onComplete;

  // Animation state
  int _currentStroke = 0;
  double _strokeProgress = 0.0;
  double _elapsed = 0.0;
  bool _isComplete = false;
  bool _showCompletionEffect = false;
  double _completionEffectProgress = 0.0;

  // Sparkle particles
  final List<_SparkleParticle> _sparkles = [];
  final Random _random = Random();

  // Timing constants
  static const double strokeDuration = 0.35;
  static const double pauseBetweenStrokes = 0.12;
  static const double completionEffectDuration = 0.4;

  // Paint objects
  late Paint _strokePaint;
  late Paint _glowPaint;
  late Paint _completedStrokePaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = kanjiSize * 0.06
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    _glowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.4)
      ..strokeWidth = kanjiSize * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    _completedStrokePaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.85)
      ..strokeWidth = kanjiSize * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isComplete) {
      // Update completion effect
      if (_showCompletionEffect) {
        _completionEffectProgress += dt / completionEffectDuration;
        if (_completionEffectProgress >= 1.0) {
          _completionEffectProgress = 1.0;
          _showCompletionEffect = false;
          onComplete?.call();
        }
      }
      // Update sparkles
      _updateSparkles(dt);
      return;
    }

    _elapsed += dt;

    // Calculate which stroke we're on and progress within it
    double timeInAnimation = _elapsed;
    int strokeIndex = 0;
    while (strokeIndex < strokes.length) {
      final strokeTime = strokeDuration + (strokeIndex < strokes.length - 1 ? pauseBetweenStrokes : 0);
      if (timeInAnimation < strokeTime) {
        _currentStroke = strokeIndex;
        _strokeProgress = (timeInAnimation / strokeDuration).clamp(0.0, 1.0);
        break;
      }
      timeInAnimation -= strokeTime;
      strokeIndex++;
    }

    // Check if animation is complete
    if (strokeIndex >= strokes.length) {
      _isComplete = true;
      _showCompletionEffect = true;
      _spawnCompletionSparkles();
    }

    // Spawn sparkles at pen tip
    if (!_isComplete && _currentStroke < strokes.length && _strokeProgress > 0) {
      _maybeSpawnSparkle();
    }

    _updateSparkles(dt);
  }

  void _maybeSpawnSparkle() {
    if (_random.nextDouble() > 0.3) return;

    final stroke = strokes[_currentStroke];
    if (stroke.isEmpty) return;

    final pointIndex = (stroke.length * _strokeProgress).floor().clamp(0, stroke.length - 1);
    final point = stroke[pointIndex];

    _sparkles.add(_SparkleParticle(
      x: point.dx * kanjiSize,
      y: point.dy * kanjiSize,
      vx: (_random.nextDouble() - 0.5) * 30,
      vy: (_random.nextDouble() - 0.5) * 30 - 20,
      size: 2 + _random.nextDouble() * 3,
      lifetime: 0.3 + _random.nextDouble() * 0.3,
      color: _random.nextBool() ? strokeColor : Colors.white,
    ));
  }

  void _spawnCompletionSparkles() {
    // Spawn burst of sparkles from center
    for (int i = 0; i < 15; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 40 + _random.nextDouble() * 60;
      _sparkles.add(_SparkleParticle(
        x: kanjiSize / 2,
        y: kanjiSize / 2,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        size: 3 + _random.nextDouble() * 4,
        lifetime: 0.4 + _random.nextDouble() * 0.3,
        color: kanjiColors[_random.nextInt(kanjiColors.length)],
      ));
    }
  }

  void _updateSparkles(double dt) {
    for (int i = _sparkles.length - 1; i >= 0; i--) {
      _sparkles[i].update(dt);
      if (_sparkles[i].isDead) {
        _sparkles.removeAt(i);
      }
    }
  }

  /// Skip to completion instantly
  void skipToEnd() {
    if (_isComplete) return;
    _isComplete = true;
    _currentStroke = strokes.length;
    _strokeProgress = 1.0;
    _showCompletionEffect = true;
    _spawnCompletionSparkles();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw background box
    _drawBackground(canvas);

    // Draw completed strokes
    for (int i = 0; i < _currentStroke && i < strokes.length; i++) {
      _drawStroke(canvas, strokes[i], 1.0, isCompleted: true);
    }

    // Draw current stroke in progress
    if (_currentStroke < strokes.length && !_isComplete) {
      _drawStroke(canvas, strokes[_currentStroke], _strokeProgress, isCompleted: false);
    }

    // If complete, draw all strokes as completed
    if (_isComplete) {
      for (int i = 0; i < strokes.length; i++) {
        _drawStroke(canvas, strokes[i], 1.0, isCompleted: true);
      }
    }

    // Draw sparkles
    _drawSparkles(canvas);

    // Draw completion effect
    if (_showCompletionEffect) {
      _drawCompletionEffect(canvas);
    }

    // Draw correct/incorrect badge
    if (_isComplete && _completionEffectProgress > 0.5) {
      _drawBadge(canvas);
    }
  }

  void _drawBackground(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, kanjiSize, kanjiSize);

    // Background fill
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.95);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, bgPaint);

    // Border
    final borderColor = _isComplete
        ? (wasCorrect ? const Color(0xFF27AE60) : const Color(0xFFE74C3C))
        : strokeColor.withValues(alpha: 0.3);
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isComplete ? 3 : 2;
    canvas.drawRRect(rrect, borderPaint);

    // Glow effect when complete
    if (_isComplete && _completionEffectProgress > 0) {
      final glowColor = wasCorrect
          ? const Color(0xFF27AE60).withValues(alpha: 0.3 * (1 - _completionEffectProgress))
          : const Color(0xFFE74C3C).withValues(alpha: 0.2 * (1 - _completionEffectProgress));
      final glowPaint = Paint()
        ..color = glowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
      canvas.drawRRect(rrect.inflate(5), glowPaint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> stroke, double progress, {required bool isCompleted}) {
    if (stroke.isEmpty) return;

    final pointCount = stroke.length;
    final visiblePoints = (pointCount * progress).floor().clamp(0, pointCount);

    if (visiblePoints < 2) return;

    final path = Path();
    // Apply padding to keep strokes inside the box
    const padding = 0.1;
    final scale = 1.0 - (padding * 2);
    final offset = padding;

    path.moveTo(
      (stroke[0].dx * scale + offset) * kanjiSize,
      (stroke[0].dy * scale + offset) * kanjiSize,
    );

    for (int i = 1; i < visiblePoints; i++) {
      path.lineTo(
        (stroke[i].dx * scale + offset) * kanjiSize,
        (stroke[i].dy * scale + offset) * kanjiSize,
      );
    }

    if (isCompleted) {
      canvas.drawPath(path, _completedStrokePaint);
    } else {
      // Draw glow first
      canvas.drawPath(path, _glowPaint);
      // Draw main stroke
      canvas.drawPath(path, _strokePaint);

      // Draw pen tip glow
      if (visiblePoints > 0 && visiblePoints <= stroke.length) {
        final tipIndex = (visiblePoints - 1).clamp(0, stroke.length - 1);
        final tip = stroke[tipIndex];
        final tipX = (tip.dx * scale + offset) * kanjiSize;
        final tipY = (tip.dy * scale + offset) * kanjiSize;

        final tipGlowPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.9)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(tipX, tipY), 4, tipGlowPaint);

        final tipPaint = Paint()..color = strokeColor;
        canvas.drawCircle(Offset(tipX, tipY), 3, tipPaint);
      }
    }
  }

  void _drawSparkles(Canvas canvas) {
    for (final sparkle in _sparkles) {
      final opacity = (1 - sparkle.progress) * 0.9;
      final paint = Paint()..color = sparkle.color.withValues(alpha: opacity);
      final size = sparkle.size * (1 - sparkle.progress * 0.5);
      canvas.drawCircle(Offset(sparkle.x, sparkle.y), size, paint);
    }
  }

  void _drawCompletionEffect(Canvas canvas) {
    // Scale bounce effect
    final bounce = sin(_completionEffectProgress * pi) * 0.1;
    final scale = 1.0 + bounce;

    canvas.save();
    canvas.translate(kanjiSize / 2, kanjiSize / 2);
    canvas.scale(scale);
    canvas.translate(-kanjiSize / 2, -kanjiSize / 2);

    // Flash overlay
    if (_completionEffectProgress < 0.3) {
      final flashOpacity = (1 - _completionEffectProgress / 0.3) * 0.3;
      final flashPaint = Paint()
        ..color = (wasCorrect ? Colors.green : Colors.red).withValues(alpha: flashOpacity);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, kanjiSize, kanjiSize),
          const Radius.circular(12),
        ),
        flashPaint,
      );
    }

    canvas.restore();
  }

  void _drawBadge(Canvas canvas) {
    final badgeSize = kanjiSize * 0.28;
    // Position badge outside the box (bottom-right corner)
    final badgeX = kanjiSize + badgeSize * 0.1;
    final badgeY = kanjiSize + badgeSize * 0.1;

    // Badge background with white border for visibility
    final badgeColor = wasCorrect ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);
    final borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(badgeX, badgeY), badgeSize / 2 + 2, borderPaint);
    final badgePaint = Paint()..color = badgeColor;
    canvas.drawCircle(Offset(badgeX, badgeY), badgeSize / 2, badgePaint);

    // Badge icon (checkmark or X)
    final iconPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (wasCorrect) {
      // Checkmark
      final path = Path()
        ..moveTo(badgeX - badgeSize * 0.2, badgeY)
        ..lineTo(badgeX - badgeSize * 0.05, badgeY + badgeSize * 0.15)
        ..lineTo(badgeX + badgeSize * 0.2, badgeY - badgeSize * 0.15);
      canvas.drawPath(path, iconPaint);
    } else {
      // X mark
      final halfSize = badgeSize * 0.15;
      canvas.drawLine(
        Offset(badgeX - halfSize, badgeY - halfSize),
        Offset(badgeX + halfSize, badgeY + halfSize),
        iconPaint,
      );
      canvas.drawLine(
        Offset(badgeX + halfSize, badgeY - halfSize),
        Offset(badgeX - halfSize, badgeY + halfSize),
        iconPaint,
      );
    }
  }
}

class _SparkleParticle {
  _SparkleParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.lifetime,
    required this.color,
  });

  double x;
  double y;
  final double vx;
  final double vy;
  final double size;
  final double lifetime;
  final Color color;

  double _elapsed = 0;

  double get progress => (_elapsed / lifetime).clamp(0.0, 1.0);
  bool get isDead => _elapsed >= lifetime;

  void update(double dt) {
    _elapsed += dt;
    x += vx * dt;
    y += vy * dt;
  }
}
