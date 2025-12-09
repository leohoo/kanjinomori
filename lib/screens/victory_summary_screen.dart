import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../games/effects/kanji_stroke_animation.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';

/// Victory summary screen showing animated kanji stroke-by-stroke
class VictorySummaryScreen extends ConsumerStatefulWidget {
  const VictorySummaryScreen({super.key});

  @override
  ConsumerState<VictorySummaryScreen> createState() =>
      _VictorySummaryScreenState();
}

class _VictorySummaryScreenState extends ConsumerState<VictorySummaryScreen> {
  late _VictorySummaryGame _game;
  bool _showContinueButton = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _game = _VictorySummaryGame(
      onAllComplete: _onAllAnimationsComplete,
    );
  }

  void _onAllAnimationsComplete() {
    if (mounted) {
      setState(() {
        _showContinueButton = true;
      });
    }
  }

  void _handleContinue() {
    ref.read(gameProvider.notifier).showVictoryResults();
  }

  void _handleTap() {
    _game.handleTap();
  }

  void _handleDoubleTap() {
    _game.skipToEnd();
    _onAllAnimationsComplete();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final progress = gameState.stageProgress;
    final kanjiRepo = ref.watch(kanjiRepositoryProvider);

    // Initialize game data once
    if (!_isInitialized && progress != null) {
      _isInitialized = true;
      // Use a post-frame callback to avoid calling setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _game.initializeKanjis(
          answeredKanjis: progress.answeredKanjis,
          answersCorrect: progress.answersCorrect,
          getStrokes: (kanji) => kanjiRepo.getStrokeTemplate(kanji),
        );
      });
    }

    return Scaffold(
      body: GestureDetector(
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
        child: Stack(
          children: [
            // Flame game for animations
            GameWidget(game: _game),

            // Title overlay
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 0,
              right: 0,
              child: const _TitleWidget(),
            ),

            // Continue button
            if (_showContinueButton)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: _ContinueButton(onPressed: _handleContinue),
                ),
              ),

            // Skip hint
            if (!_showContinueButton)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'タップでスキップ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TitleWidget extends StatefulWidget {
  const _TitleWidget();

  @override
  State<_TitleWidget> createState() => _TitleWidgetState();
}

class _TitleWidgetState extends State<_TitleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                  Color(0xFFFFD700),
                ],
              ).createShader(bounds);
            },
            child: const Text(
              '覚えた漢字',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kanji You Learned',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'つづける',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}

/// Flame game for managing kanji animations
class _VictorySummaryGame extends FlameGame {
  _VictorySummaryGame({required this.onAllComplete});

  final VoidCallback onAllComplete;

  final List<KanjiStrokeAnimation> _kanjiAnimations = [];
  final List<_BackgroundParticle> _bgParticles = [];
  final Random _random = Random();

  int _currentKanjiIndex = 0;
  bool _allComplete = false;
  double _staggerDelay = 0;
  bool _initialized = false;
  bool _layoutComplete = false;

  // Pending data for deferred initialization
  List<String>? _pendingKanjis;
  List<bool>? _pendingCorrect;
  List<List<Offset>>? Function(String)? _pendingGetStrokes;

  // Layout
  static const int columns = 5;
  static const double kanjiSize = 64.0;
  static const double spacing = 12.0;
  static const double topPadding = 160.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Set camera to top-left anchor so positions work as expected
    camera.viewfinder.anchor = Anchor.topLeft;
  }

  void initializeKanjis({
    required List<String> answeredKanjis,
    required List<bool> answersCorrect,
    required List<List<Offset>>? Function(String) getStrokes,
  }) {
    if (_initialized) return;
    _initialized = true;

    // Store data for deferred layout
    _pendingKanjis = answeredKanjis;
    _pendingCorrect = answersCorrect;
    _pendingGetStrokes = getStrokes;

    // Try to layout now if size is available
    _tryLayout();
  }

  void _tryLayout() {
    if (_layoutComplete) return;
    if (_pendingKanjis == null) return;
    if (size.x == 0 || size.y == 0) return;

    _layoutComplete = true;

    final screenWidth = size.x;
    final gridWidth = columns * kanjiSize + (columns - 1) * spacing;
    final startX = (screenWidth - gridWidth) / 2;

    for (int i = 0; i < _pendingKanjis!.length && i < 10; i++) {
      final kanji = _pendingKanjis![i];
      final wasCorrect =
          i < _pendingCorrect!.length ? _pendingCorrect![i] : true;
      final strokes = _pendingGetStrokes!(kanji);

      if (strokes == null || strokes.isEmpty) continue;

      final row = i ~/ columns;
      final col = i % columns;
      final x = startX + col * (kanjiSize + spacing);
      final y = topPadding + row * (kanjiSize + spacing + 10);

      final animation = KanjiStrokeAnimation(
        kanji: kanji,
        strokes: strokes,
        strokeColor: kanjiColors[i % kanjiColors.length],
        kanjiSize: kanjiSize,
        wasCorrect: wasCorrect,
        onComplete: () => _onKanjiComplete(i),
      );
      animation.position = Vector2(x, y);

      _kanjiAnimations.add(animation);
    }

    // Spawn background particles
    _spawnBackgroundParticles();

    // Clear pending data
    _pendingKanjis = null;
    _pendingCorrect = null;
    _pendingGetStrokes = null;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Try layout when we get a valid size
    _tryLayout();
  }

  void _spawnBackgroundParticles() {
    for (int i = 0; i < 30; i++) {
      _bgParticles.add(_BackgroundParticle(
        x: _random.nextDouble() * size.x,
        y: _random.nextDouble() * size.y,
        vx: (_random.nextDouble() - 0.5) * 10,
        vy: -10 - _random.nextDouble() * 20,
        size: 2 + _random.nextDouble() * 4,
        color: kanjiColors[_random.nextInt(kanjiColors.length)]
            .withValues(alpha: 0.3),
      ));
    }
  }

  void _onKanjiComplete(int index) {
    // Start next kanji animation if available
    if (_currentKanjiIndex < _kanjiAnimations.length - 1) {
      _currentKanjiIndex++;
      _staggerDelay = 0.2; // Small delay before next
    } else if (!_allComplete) {
      _allComplete = true;
      // Wait a bit then show continue button
      Future.delayed(const Duration(milliseconds: 500), onAllComplete);
    }
  }

  void handleTap() {
    // Skip current kanji animation
    if (_currentKanjiIndex < _kanjiAnimations.length) {
      _kanjiAnimations[_currentKanjiIndex].skipToEnd();
    }
  }

  void skipToEnd() {
    // Skip all animations
    for (final anim in _kanjiAnimations) {
      anim.skipToEnd();
    }
    _allComplete = true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Handle stagger delay
    if (_staggerDelay > 0) {
      _staggerDelay -= dt;
      if (_staggerDelay <= 0 && _currentKanjiIndex < _kanjiAnimations.length) {
        // Add next kanji to the world
        if (!_kanjiAnimations[_currentKanjiIndex].isMounted) {
          world.add(_kanjiAnimations[_currentKanjiIndex]);
        }
      }
    }

    // Start first kanji if not started
    if (_layoutComplete &&
        _kanjiAnimations.isNotEmpty &&
        !_kanjiAnimations[0].isMounted &&
        _staggerDelay <= 0) {
      world.add(_kanjiAnimations[0]);
    }

    // Update background particles
    for (final particle in _bgParticles) {
      particle.update(dt, size);
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw gradient background
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1A1A2E),
        const Color(0xFF16213E),
        const Color(0xFF0F3460),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Draw background particles
    for (final particle in _bgParticles) {
      final paint = Paint()..color = particle.color;
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }

    super.render(canvas);
  }

  @override
  Color backgroundColor() => Colors.transparent;
}

class _BackgroundParticle {
  _BackgroundParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });

  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;

  void update(double dt, Vector2 screenSize) {
    x += vx * dt;
    y += vy * dt;

    // Wrap around screen
    if (y < -size) {
      y = screenSize.y + size;
      x = Random().nextDouble() * screenSize.x;
    }
    if (x < -size) x = screenSize.x + size;
    if (x > screenSize.x + size) x = -size;
  }
}
