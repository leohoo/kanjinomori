import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

/// Base class for particle effects
abstract class ParticleEffect extends PositionComponent {
  ParticleEffect({
    required Vector2 position,
    required this.duration,
  }) : super(position: position);

  /// Total duration of the effect
  final double duration;

  /// Elapsed time
  double elapsed = 0;

  /// Progress from 0 to 1
  double get progress => (elapsed / duration).clamp(0, 1);

  @override
  void update(double dt) {
    super.update(dt);
    elapsed += dt;
    if (elapsed >= duration) {
      removeFromParent();
    }
  }
}

/// Wind lines effect for jumps (white diagonal lines)
class JumpWindEffect extends ParticleEffect {
  JumpWindEffect({
    required Vector2 position,
  }) : super(
          position: position,
          duration: GamePhysics.jumpWindEffectDuration,
        );

  final Random _random = Random();
  late List<_WindLine> _lines;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Generate 5-8 wind lines
    final lineCount = 5 + _random.nextInt(4);
    _lines = List.generate(lineCount, (i) {
      return _WindLine(
        startX: -20 + _random.nextDouble() * 40,
        startY: _random.nextDouble() * 60,
        length: 15 + _random.nextDouble() * 25,
        angle: -pi / 4 + (_random.nextDouble() - 0.5) * 0.3,
        delay: _random.nextDouble() * 0.1,
      );
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (1 - progress) * 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (final line in _lines) {
      if (elapsed < line.delay) continue;

      final lineProgress = ((elapsed - line.delay) / (duration - line.delay)).clamp(0, 1);
      final yOffset = lineProgress * 30; // Lines move upward

      final startX = line.startX;
      final startY = line.startY - yOffset;
      final endX = startX + cos(line.angle) * line.length;
      final endY = startY + sin(line.angle) * line.length;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }
}

class _WindLine {
  _WindLine({
    required this.startX,
    required this.startY,
    required this.length,
    required this.angle,
    required this.delay,
  });

  final double startX;
  final double startY;
  final double length;
  final double angle;
  final double delay;
}

/// Dust cloud effect for landing
class LandingDustEffect extends ParticleEffect {
  LandingDustEffect({
    required Vector2 position,
  }) : super(
          position: position,
          duration: GamePhysics.landingDustDuration,
        );

  final Random _random = Random();
  late List<_DustParticle> _particles;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Generate 8-12 dust particles
    final particleCount = 8 + _random.nextInt(5);
    _particles = List.generate(particleCount, (i) {
      final angle = pi + (_random.nextDouble() - 0.5) * pi * 0.8;
      final speed = 30 + _random.nextDouble() * 50;
      return _DustParticle(
        x: 0,
        y: 0,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed * 0.5,
        size: 3 + _random.nextDouble() * 4,
      );
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()
      ..color = Colors.brown.withValues(alpha: (1 - progress) * 0.5);

    for (final particle in _particles) {
      final x = particle.x + particle.vx * elapsed;
      final y = particle.y + particle.vy * elapsed;
      final size = particle.size * (1 - progress * 0.5);

      canvas.drawCircle(Offset(x, y), size, paint);
    }
  }
}

class _DustParticle {
  _DustParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;
}

/// Slash effect for attacks
class AttackSlashEffect extends ParticleEffect {
  AttackSlashEffect({
    required Vector2 position,
    required this.facingRight,
    this.isAerial = false,
  }) : super(
          position: position,
          duration: 0.3,
        );

  final bool facingRight;
  final bool isAerial;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final direction = facingRight ? 1.0 : -1.0;
    final slashAngle = isAerial ? -pi / 6 : 0.0;

    final rect = Rect.fromCenter(
      center: Offset(direction * 25, 0),
      width: 80 + progress * 30,
      height: 60 + progress * 20,
    );

    final startAngle = facingRight ? -pi / 3 + slashAngle : pi * 2 / 3 + slashAngle;
    final sweepAngle = (facingRight ? 1 : -1) * pi / 2 * (1 - progress * 0.3);

    // Draw outer glow (yellow)
    final glowPaint = Paint()
      ..color = Colors.yellow.withValues(alpha: (1 - progress) * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * (1 - progress * 0.5)
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // Draw main slash (bright white, thicker)
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: (1 - progress) * 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * (1 - progress * 0.5)
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }
}

/// Green glow effect for door completion
class DoorCompletionEffect extends ParticleEffect {
  DoorCompletionEffect({
    required Vector2 position,
    required this.doorSize,
  }) : super(
          position: position,
          duration: 1.5,
        );

  final Vector2 doorSize;
  final Random _random = Random();
  late List<_GlowParticle> _particles;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Generate 15-20 glow particles
    final particleCount = 15 + _random.nextInt(6);
    _particles = List.generate(particleCount, (i) {
      return _GlowParticle(
        x: (_random.nextDouble() - 0.5) * doorSize.x,
        y: -_random.nextDouble() * doorSize.y,
        vy: -30 - _random.nextDouble() * 40,
        size: 4 + _random.nextDouble() * 6,
        delay: _random.nextDouble() * 0.5,
      );
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw glow around door
    final glowOpacity = progress < 0.3 ? progress / 0.3 : (1 - (progress - 0.3) / 0.7);
    final glowPaint = Paint()
      ..color = AppColors.success.withValues(alpha: glowOpacity * 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, -doorSize.y / 2),
        width: doorSize.x + 20,
        height: doorSize.y + 20,
      ),
      glowPaint,
    );

    // Draw rising particles
    final particlePaint = Paint();
    for (final particle in _particles) {
      if (elapsed < particle.delay) continue;

      final particleProgress = ((elapsed - particle.delay) / (duration - particle.delay)).clamp(0, 1);
      final x = particle.x;
      final y = particle.y + particle.vy * (elapsed - particle.delay);
      final size = particle.size * (1 - particleProgress * 0.5);
      final opacity = (1 - particleProgress) * 0.8;

      particlePaint.color = AppColors.success.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), size, particlePaint);
    }
  }
}

class _GlowParticle {
  _GlowParticle({
    required this.x,
    required this.y,
    required this.vy,
    required this.size,
    required this.delay,
  });

  final double x;
  final double y;
  final double vy;
  final double size;
  final double delay;
}

/// Coin collection animation
class CoinCollectEffect extends ParticleEffect {
  CoinCollectEffect({
    required Vector2 position,
    required this.targetPosition,
    this.coinCount = 1,
  }) : super(
          position: position,
          duration: 0.8,
        );

  final Vector2 targetPosition;
  final int coinCount;
  final Random _random = Random();
  late List<_CoinParticle> _coins;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _coins = List.generate(coinCount.clamp(1, 5), (i) {
      return _CoinParticle(
        delay: i * 0.1,
        offsetX: (_random.nextDouble() - 0.5) * 20,
        offsetY: (_random.nextDouble() - 0.5) * 20,
      );
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    for (final coin in _coins) {
      if (elapsed < coin.delay) continue;

      final coinProgress = ((elapsed - coin.delay) / (duration - coin.delay)).clamp(0, 1);

      // Ease out curve for smooth arrival
      final easedProgress = 1 - pow(1 - coinProgress, 3);

      // Calculate position with arc
      final startX = coin.offsetX;
      final startY = coin.offsetY;
      final endX = targetPosition.x - position.x;
      final endY = targetPosition.y - position.y;

      final x = startX + (endX - startX) * easedProgress;
      final arcHeight = -50 * sin(easedProgress * pi);
      final y = startY + (endY - startY) * easedProgress + arcHeight;

      // Shrink as it approaches target
      final size = 8 * (1 - easedProgress * 0.5);
      final opacity = coinProgress < 0.9 ? 1.0 : (1 - (coinProgress - 0.9) / 0.1);

      final paint = Paint()..color = AppColors.accent.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), size, paint);

      // Shine effect
      final shinePaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.6);
      canvas.drawCircle(Offset(x - 2, y - 2), size * 0.3, shinePaint);
    }
  }
}

class _CoinParticle {
  _CoinParticle({
    required this.delay,
    required this.offsetX,
    required this.offsetY,
  });

  final double delay;
  final double offsetX;
  final double offsetY;
}

/// Damage flash effect (red tint)
class DamageFlashEffect extends ParticleEffect {
  DamageFlashEffect({
    required Vector2 position,
    required Vector2 flashSize,
  }) : _flashSize = flashSize,
       super(
          position: position,
          duration: 0.15,
        );

  final Vector2 _flashSize;

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final opacity = (1 - progress) * 0.4;
    final paint = Paint()..color = Colors.red.withValues(alpha: opacity);

    canvas.drawRect(
      Rect.fromLTWH(-_flashSize.x / 2, -_flashSize.y, _flashSize.x, _flashSize.y),
      paint,
    );
  }
}

/// Critical hit effect (star burst)
class CriticalHitEffect extends ParticleEffect {
  CriticalHitEffect({
    required Vector2 position,
  }) : super(
          position: position,
          duration: 0.4,
        );

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final scale = 1 + progress * 0.5;
    final opacity = (1 - progress) * 0.9;

    // Draw star burst
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - progress * 0.5);

    const rayCount = 8;
    const innerRadius = 10.0;
    final outerRadius = 30.0 * scale;

    for (var i = 0; i < rayCount; i++) {
      final angle = (i / rayCount) * 2 * pi + progress * pi / 4;
      final innerX = cos(angle) * innerRadius;
      final innerY = sin(angle) * innerRadius;
      final outerX = cos(angle) * outerRadius;
      final outerY = sin(angle) * outerRadius;

      canvas.drawLine(
        Offset(innerX, innerY),
        Offset(outerX, outerY),
        paint,
      );
    }

    // Center flash
    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(Offset.zero, 8 * (1 - progress * 0.5), centerPaint);
  }
}
