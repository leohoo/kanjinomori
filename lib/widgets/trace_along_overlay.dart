import 'package:flutter/material.dart';
import '../utils/constants.dart';

class TraceAlongOverlay extends StatefulWidget {
  final List<List<Offset>> templateStrokes;
  final double size;
  final void Function(bool success) onComplete;

  const TraceAlongOverlay({
    super.key,
    required this.templateStrokes,
    required this.size,
    required this.onComplete,
  });

  @override
  State<TraceAlongOverlay> createState() => _TraceAlongOverlayState();
}

class _TraceAlongOverlayState extends State<TraceAlongOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStrokeIndex = 0;
  List<Offset> _currentUserStroke = [];
  final List<List<Offset>> _completedStrokes = [];
  late AnimationController _guideAnimController;
  late Animation<double> _guideAnimation;

  @override
  void initState() {
    super.initState();
    _guideAnimController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _guideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _guideAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _guideAnimController.dispose();
    super.dispose();
  }

  List<Offset> get _currentTemplateStroke {
    if (_currentStrokeIndex >= widget.templateStrokes.length) {
      return [];
    }
    return _normalizeStroke(widget.templateStrokes[_currentStrokeIndex]);
  }

  List<Offset> _normalizeStroke(List<Offset> stroke) {
    // Normalize stroke to canvas coordinates
    // Template strokes are in 0-1 range, convert to canvas size with 10% margin
    final margin = widget.size * 0.1;
    final usableSize = widget.size * 0.8;
    return stroke.map((p) {
      return Offset(
        p.dx * usableSize + margin,
        p.dy * usableSize + margin,
      );
    }).toList();
  }

  Offset? get _guidePoint {
    if (_currentTemplateStroke.isEmpty) return null;
    final progress = _guideAnimation.value;
    final index = (progress * (_currentTemplateStroke.length - 1)).round();
    return _currentTemplateStroke[index.clamp(0, _currentTemplateStroke.length - 1)];
  }

  Offset? get _startPoint {
    if (_currentTemplateStroke.isEmpty) return null;
    return _currentTemplateStroke.first;
  }

  void _onPanStart(DragStartDetails details) {
    final startPoint = _startPoint;
    if (startPoint == null) return;

    // Check if starting near the stroke's start point (relaxed threshold for trace mode)
    final distance = (details.localPosition - startPoint).distance;
    if (distance < 50) {
      // Relaxed threshold
      setState(() {
        _currentUserStroke = [details.localPosition];
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentUserStroke.isEmpty) return;
    setState(() {
      _currentUserStroke = List.from(_currentUserStroke)
        ..add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentUserStroke.isEmpty) return;

    // Check if the user's stroke is close enough to the template
    final isGoodTrace = _evaluateTrace();

    if (isGoodTrace) {
      setState(() {
        _completedStrokes.add(List.from(_currentUserStroke));
        _currentUserStroke = [];
        _currentStrokeIndex++;
      });

      // Check if all strokes completed
      if (_currentStrokeIndex >= widget.templateStrokes.length) {
        widget.onComplete(true);
      }
    } else {
      // Allow retry on this stroke
      setState(() {
        _currentUserStroke = [];
      });
    }
  }

  bool _evaluateTrace() {
    if (_currentUserStroke.length < 3) return false;

    final template = _currentTemplateStroke;
    if (template.isEmpty) return false;

    // Sample both strokes and compare average distance
    // Relaxed threshold for trace mode (0.15 of canvas size)
    final threshold = widget.size * 0.15;

    // Simple evaluation: check if user stroke covers the general area
    final userBounds = _getBounds(_currentUserStroke);
    final templateBounds = _getBounds(template);

    // Check if bounding boxes roughly overlap
    final overlap = userBounds.overlaps(templateBounds.inflate(threshold));
    if (!overlap) return false;

    // Check start and end points
    final startDist = (_currentUserStroke.first - template.first).distance;
    final endDist = (_currentUserStroke.last - template.last).distance;

    return startDist < threshold && endDist < threshold;
  }

  Rect _getBounds(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final p in points) {
      minX = minX < p.dx ? minX : p.dx;
      maxX = maxX > p.dx ? maxX : p.dx;
      minY = minY < p.dy ? minY : p.dy;
      maxY = maxY > p.dy ? maxY : p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'なぞって書こう (${_currentStrokeIndex + 1}/${widget.templateStrokes.length}画)',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Canvas with trace overlay
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: AnimatedBuilder(
                animation: _guideAnimation,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _TraceAlongPainter(
                      templateStrokes: widget.templateStrokes
                          .map(_normalizeStroke)
                          .toList(),
                      currentStrokeIndex: _currentStrokeIndex,
                      completedStrokes: _completedStrokes,
                      currentUserStroke: _currentUserStroke,
                      guidePoint: _guidePoint,
                      startPoint: _startPoint,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TraceAlongPainter extends CustomPainter {
  final List<List<Offset>> templateStrokes;
  final int currentStrokeIndex;
  final List<List<Offset>> completedStrokes;
  final List<Offset> currentUserStroke;
  final Offset? guidePoint;
  final Offset? startPoint;

  _TraceAlongPainter({
    required this.templateStrokes,
    required this.currentStrokeIndex,
    required this.completedStrokes,
    required this.currentUserStroke,
    required this.guidePoint,
    required this.startPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid
    _drawGrid(canvas, size);

    // Draw completed strokes (solid green)
    final completedPaint = Paint()
      ..color = AppColors.success
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in completedStrokes) {
      _drawStroke(canvas, stroke, completedPaint);
    }

    // Draw upcoming template strokes (very light)
    final upcomingPaint = Paint()
      ..color = Colors.grey.withOpacity(0.15)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (int i = currentStrokeIndex + 1; i < templateStrokes.length; i++) {
      _drawStroke(canvas, templateStrokes[i], upcomingPaint);
    }

    // Draw current template stroke (light, but visible)
    if (currentStrokeIndex < templateStrokes.length) {
      final templatePaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      _drawStroke(canvas, templateStrokes[currentStrokeIndex], templatePaint);
    }

    // Draw current user stroke (dark)
    if (currentUserStroke.isNotEmpty) {
      final userPaint = Paint()
        ..color = AppColors.textPrimary
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      _drawStroke(canvas, currentUserStroke, userPaint);
    }

    // Draw start point indicator
    if (startPoint != null && currentUserStroke.isEmpty) {
      // Outer glow
      final glowPaint = Paint()
        ..color = Colors.amber.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPoint!, 20, glowPaint);

      // Inner circle
      final startPaint = Paint()
        ..color = Colors.amber
        ..style = PaintingStyle.fill;
      canvas.drawCircle(startPoint!, 12, startPaint);

      // Border
      final borderPaint = Paint()
        ..color = Colors.amber.shade800
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(startPoint!, 12, borderPaint);
    }

    // Draw guide point (animated dot along the stroke)
    if (guidePoint != null && currentUserStroke.isEmpty) {
      final guidePaint = Paint()
        ..color = Colors.blue.withOpacity(0.6)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(guidePoint!, 8, guidePaint);
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(
          points[0], paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
      paint.style = PaintingStyle.stroke;
      return;
    }

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (points.length == 2) {
      path.lineTo(points[1].dx, points[1].dy);
    } else {
      for (int i = 1; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final midX = (p0.dx + p1.dx) / 2;
        final midY = (p0.dy + p1.dy) / 2;
        path.quadraticBezierTo(p0.dx, p0.dy, midX, midY);
      }
      final last = points.last;
      path.lineTo(last.dx, last.dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      gridPaint,
    );

    final diagonalPaint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 1;

    canvas.drawLine(Offset.zero, Offset(size.width, size.height), diagonalPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), diagonalPaint);
  }

  @override
  bool shouldRepaint(covariant _TraceAlongPainter oldDelegate) => true;
}
