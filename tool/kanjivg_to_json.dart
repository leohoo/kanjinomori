#!/usr/bin/env dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';

/// Converts KanjiVG SVG stroke data into a JSON file with normalized polylines.
///
/// Usage:
///   dart run tool/kanjivg_to_json.dart --input <kanjivg-root> --output <out.json>
/// The input directory should contain the `kanji` folder from KanjiVG.
///
/// Output JSON shape:
/// {
///   "一": [
///     [ [0.1, 0.2], [0.9, 0.2] ], // stroke 1 (normalized to 0..1)
///     ...
///   ],
///   ...
/// }
void main(List<String> args) async {
  final inputArgIndex = args.indexOf('--input');
  final outputArgIndex = args.indexOf('--output');
  if (inputArgIndex == -1 ||
      inputArgIndex + 1 >= args.length ||
      outputArgIndex == -1 ||
      outputArgIndex + 1 >= args.length) {
    stderr.writeln(
        'Usage: dart run tool/kanjivg_to_json.dart --input <kanjivg-root> --output <out.json>');
    exit(64);
  }

  final inputDir = Directory(args[inputArgIndex + 1]);
  final outputFile = File(args[outputArgIndex + 1]);

  if (!inputDir.existsSync()) {
    stderr.writeln('Input directory does not exist: ${inputDir.path}');
    exit(66);
  }

  final kanjiDir = Directory(p.join(inputDir.path, 'kanji'));
  if (!kanjiDir.existsSync()) {
    stderr.writeln('Could not find kanji directory at ${kanjiDir.path}');
    exit(66);
  }

  final result = <String, List<List<List<double>>>>{};
  final svgFiles = kanjiDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.svg'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  stderr.writeln('Processing ${svgFiles.length} kanji SVGs...');

  for (final file in svgFiles) {
    final basename = p.basenameWithoutExtension(file.path);
    int codePoint;
    try {
      codePoint = int.parse(basename, radix: 16);
    } catch (_) {
      continue;
    }
    final kanjiChar = String.fromCharCode(codePoint);

    final xml = XmlDocument.parse(await file.readAsString());
    final paths = xml.findAllElements('path');
    final strokes = <List<List<double>>>[];

    for (final path in paths) {
      final data = path.getAttribute('d');
      if (data == null) continue;
      try {
        final points = _PathSampler().sample(data);
        if (points.length >= 2) {
          strokes.add(points.map((p) => [p.dx, p.dy]).toList());
        }
      } catch (_) {
        // Skip malformed paths.
      }
    }

    if (strokes.isEmpty) continue;

  final normalized = _normalizeStrokes(strokes);
  result[kanjiChar] =
      normalized.map((s) => _resampleStroke(s, targetPoints: 12)).toList();
}

await outputFile
    .writeAsString(const JsonEncoder.withIndent('  ').convert(result));
stderr.writeln(
      'Wrote ${result.length} kanji strokes to ${outputFile.path} (${outputFile.lengthSync()} bytes).');
}

List<List<List<double>>> _normalizeStrokes(
    List<List<List<double>>> strokes) {
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;

  for (final stroke in strokes) {
    for (final point in stroke) {
      minX = min(minX, point[0]);
      minY = min(minY, point[1]);
      maxX = max(maxX, point[0]);
      maxY = max(maxY, point[1]);
    }
  }

  final width = (maxX - minX).abs().clamp(1e-6, double.infinity);
  final height = (maxY - minY).abs().clamp(1e-6, double.infinity);

  return strokes
      .map((stroke) => stroke
          .map((p) => [(p[0] - minX) / width, (p[1] - minY) / height])
          .toList())
      .toList();
}

List<List<double>> _resampleStroke(List<List<double>> stroke,
    {int targetPoints = 32}) {
  if (stroke.isEmpty) return stroke;
  if (stroke.length <= targetPoints) return stroke;

  final points = stroke.map((p) => _Point(p[0], p[1])).toList();
  final cumulative = <double>[0];
  for (var i = 1; i < points.length; i++) {
    cumulative.add(cumulative.last +
        sqrt(pow(points[i].dx - points[i - 1].dx, 2) +
            pow(points[i].dy - points[i - 1].dy, 2)));
  }
  final total = cumulative.last;
  if (total == 0) return stroke;

  final step = total / (targetPoints - 1);
  final resampled = <List<double>>[];
  var j = 0;
  for (var t = 0; t < targetPoints; t++) {
    final targetDist = step * t;
    while (j < cumulative.length - 2 && cumulative[j + 1] < targetDist) {
      j++;
    }
    final ratio = (targetDist - cumulative[j]) /
        max(cumulative[j + 1] - cumulative[j], 1e-6);
    final p0 = points[j];
    final p1 = points[j + 1];
    resampled.add([
      p0.dx + (p1.dx - p0.dx) * ratio,
      p0.dy + (p1.dy - p0.dy) * ratio,
    ]);
  }
  return resampled;
}

class _Point {
  final double dx;
  final double dy;
  const _Point(this.dx, this.dy);
}

class _PathSampler extends PathProxy {
  final List<_Point> _currentStroke = [];
  final List<_Point> _strokeStartPoints = [];
  final List<List<_Point>> _strokes = [];
  _Point _current = const _Point(0, 0);
  _Point? _start;

  List<_Point> sample(String data) {
    _currentStroke.clear();
    _strokeStartPoints.clear();
    _strokes.clear();
    _current = const _Point(0, 0);
    _start = null;
    writeSvgPathDataToPath(data, this);
    _commitStroke();
    if (_strokes.isEmpty) return [];
    if (_strokes.length == 1) return _strokes.first;
    return _strokes.expand((s) => s).toList(growable: false);
  }

  @override
  void close() {
    if (_start != null) {
      lineTo(_start!.dx, _start!.dy);
    }
    _commitStroke();
  }

  @override
  void moveTo(double x, double y) {
    _commitStroke();
    _start = _Point(x, y);
    _currentStroke.add(_start!);
    _current = _start!;
  }

  @override
  void lineTo(double x, double y) {
    final pt = _Point(x, y);
    _currentStroke.add(pt);
    _current = pt;
  }

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3,
      double y3) {
    final p0 = _current;
    final p1 = _Point(x1, y1);
    final p2 = _Point(x2, y2);
    final p3 = _Point(x3, y3);
    const steps = 6;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final pt = _cubicPoint(p0, p1, p2, p3, t);
      _currentStroke.add(pt);
    }
    _current = _Point(x3, y3);
  }

  @override
  void quadraticBezierTo(double x1, double y1, double x2, double y2) {
    final p0 = _current;
    final p1 = _Point(x1, y1);
    final p2 = _Point(x2, y2);
    const steps = 6;
    for (var i = 1; i <= steps; i++) {
      final t = i / steps;
      final pt = _quadraticPoint(p0, p1, p2, t);
      _currentStroke.add(pt);
    }
    _current = _Point(x2, y2);
  }

  @override
  void arcTo(
      double rx,
      double ry,
      double rotation,
      bool largeArc,
      bool clockwise,
      double x,
      double y) {
    // Approximate arc with a simple line; arc shapes are rare in KanjiVG.
    lineTo(x, y);
  }

  void _commitStroke() {
    if (_currentStroke.length >= 2) {
      _strokes.add(List<_Point>.from(_currentStroke));
    }
    _currentStroke.clear();
    _start = null;
  }

  _Point _cubicPoint(
      _Point p0, _Point p1, _Point p2, _Point p3, double t) {
    final mt = 1 - t;
    final x = mt * mt * mt * p0.dx +
        3 * mt * mt * t * p1.dx +
        3 * mt * t * t * p2.dx +
        t * t * t * p3.dx;
    final y = mt * mt * mt * p0.dy +
        3 * mt * mt * t * p1.dy +
        3 * mt * t * t * p2.dy +
        t * t * t * p3.dy;
    return _Point(x, y);
  }

  _Point _quadraticPoint(_Point p0, _Point p1, _Point p2, double t) {
    final mt = 1 - t;
    final x = mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx;
    final y = mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy;
    return _Point(x, y);
  }
}
