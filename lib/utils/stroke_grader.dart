import 'dart:math';
import 'dart:ui';

List<List<Offset>> _normalize(List<List<Offset>> strokes) {
  double minX = double.infinity, minY = double.infinity;
  double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

  for (final stroke in strokes) {
    for (final p in stroke) {
      minX = min(minX, p.dx);
      minY = min(minY, p.dy);
      maxX = max(maxX, p.dx);
      maxY = max(maxY, p.dy);
    }
  }

  final width = max((maxX - minX).abs(), 1e-6);
  final height = max((maxY - minY).abs(), 1e-6);

  return strokes
      .map((stroke) => stroke
          .map((p) => Offset((p.dx - minX) / width, (p.dy - minY) / height))
          .toList())
      .toList();
}

List<Offset> _resample(List<Offset> points, int target) {
  if (points.isEmpty) return [];
  if (points.length == 1) {
    return List.filled(target, points.first);
  }

  final cumulative = <double>[0];
  for (var i = 1; i < points.length; i++) {
    final dist = (points[i] - points[i - 1]).distance;
    cumulative.add(cumulative.last + dist);
  }
  final total = cumulative.last;
  if (total == 0) {
    return List.filled(target, points.first);
  }

  final step = total / (target - 1);
  final resampled = <Offset>[];
  var j = 0;
  for (var t = 0; t < target; t++) {
    final targetDist = step * t;
    while (j < cumulative.length - 2 && cumulative[j + 1] < targetDist) {
      j++;
    }
    final ratio = (targetDist - cumulative[j]) /
        max(cumulative[j + 1] - cumulative[j], 1e-6);
    final p0 = points[j];
    final p1 = points[j + 1];
    resampled.add(Offset(
      p0.dx + (p1.dx - p0.dx) * ratio,
      p0.dy + (p1.dy - p0.dy) * ratio,
    ));
  }
  return resampled;
}

double _strokeDistance(List<Offset> a, List<Offset> b) {
  final resampledA = _resample(a, 32);
  final resampledB = _resample(b, 32);
  if (resampledA.isEmpty || resampledB.isEmpty) return double.infinity;

  var total = 0.0;
  for (var i = 0; i < 32; i++) {
    total += (resampledA[i] - resampledB[i]).distance;
  }
  return total / 32.0;
}

bool gradeWithStrokes({
  required List<List<Offset>> userStrokes,
  required List<List<Offset>> templateStrokes,
  double distanceThreshold = 0.25,
  int strokeCountTolerance = 1,
}) {
  if (userStrokes.isEmpty) return false;

  final normalizedUser = _normalize(userStrokes);
  final normalizedTemplate = _normalize(templateStrokes);

  final countDiff =
      (normalizedUser.length - normalizedTemplate.length).abs();
  if (countDiff > strokeCountTolerance) {
    return false;
  }

  final pairCount = min(normalizedUser.length, normalizedTemplate.length);
  var totalDistance = 0.0;
  for (var i = 0; i < pairCount; i++) {
    totalDistance += _strokeDistance(
      normalizedUser[i],
      normalizedTemplate[i],
    );
  }
  final averageDistance = totalDistance / pairCount;
  final penalty = 0.05 * countDiff;
  return (averageDistance + penalty) < distanceThreshold;
}
