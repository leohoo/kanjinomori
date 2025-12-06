import 'dart:math';
import 'dart:ui';

enum FailureReason {
  strokeCount,
  strokeOrder,
  strokeShape,
}

class GradeResult {
  final bool passed;
  final FailureReason? failureReason;
  final double distance;

  const GradeResult({
    required this.passed,
    this.failureReason,
    required this.distance,
  });

  String? get hintMessage {
    switch (failureReason) {
      case FailureReason.strokeCount:
        return '画数を確認しよう';
      case FailureReason.strokeOrder:
        return '書き順を確認しよう';
      case FailureReason.strokeShape:
        return '形を確認しよう';
      case null:
        return null;
    }
  }
}

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

double _calculateOrderedDistance(
  List<List<Offset>> user,
  List<List<Offset>> template,
) {
  final pairCount = min(user.length, template.length);
  if (pairCount == 0) return double.infinity;

  var totalDistance = 0.0;
  for (var i = 0; i < pairCount; i++) {
    totalDistance += _strokeDistance(user[i], template[i]);
  }
  return totalDistance / pairCount;
}

double _calculateBestReorderedDistance(
  List<List<Offset>> user,
  List<List<Offset>> template,
) {
  if (user.isEmpty || template.isEmpty) return double.infinity;

  final pairCount = min(user.length, template.length);
  final usedTemplate = List.filled(template.length, false);
  var totalDistance = 0.0;

  for (var i = 0; i < pairCount; i++) {
    var bestDist = double.infinity;
    var bestIdx = -1;
    for (var j = 0; j < template.length; j++) {
      if (usedTemplate[j]) continue;
      final dist = _strokeDistance(user[i], template[j]);
      if (dist < bestDist) {
        bestDist = dist;
        bestIdx = j;
      }
    }
    if (bestIdx >= 0) {
      usedTemplate[bestIdx] = true;
      totalDistance += bestDist;
    }
  }
  return totalDistance / pairCount;
}

GradeResult gradeWithResult({
  required List<List<Offset>> userStrokes,
  required List<List<Offset>> templateStrokes,
  double distanceThreshold = 0.25,
  int strokeCountTolerance = 1,
}) {
  if (userStrokes.isEmpty) {
    return const GradeResult(
      passed: false,
      failureReason: FailureReason.strokeCount,
      distance: double.infinity,
    );
  }

  final normalizedUser = _normalize(userStrokes);
  final normalizedTemplate = _normalize(templateStrokes);

  final countDiff =
      (normalizedUser.length - normalizedTemplate.length).abs();

  // 1. Check stroke count first
  if (countDiff > strokeCountTolerance) {
    return GradeResult(
      passed: false,
      failureReason: FailureReason.strokeCount,
      distance: double.infinity,
    );
  }

  final orderedDistance = _calculateOrderedDistance(
    normalizedUser,
    normalizedTemplate,
  );
  final penalty = 0.05 * countDiff;
  final finalDistance = orderedDistance + penalty;

  // Check if passed
  if (finalDistance < distanceThreshold) {
    return GradeResult(
      passed: true,
      distance: finalDistance,
    );
  }

  // 2. Check stroke order (only if stroke count is acceptable)
  if (countDiff == 0) {
    final reorderedDistance = _calculateBestReorderedDistance(
      normalizedUser,
      normalizedTemplate,
    );

    // If reordering significantly improves the score, it's a stroke order issue
    if (reorderedDistance < orderedDistance * 0.7 &&
        reorderedDistance < distanceThreshold) {
      return GradeResult(
        passed: false,
        failureReason: FailureReason.strokeOrder,
        distance: orderedDistance,
      );
    }
  }

  // 3. Otherwise it's a shape issue
  return GradeResult(
    passed: false,
    failureReason: FailureReason.strokeShape,
    distance: finalDistance,
  );
}

bool gradeWithStrokes({
  required List<List<Offset>> userStrokes,
  required List<List<Offset>> templateStrokes,
  double distanceThreshold = 0.25,
  int strokeCountTolerance = 1,
}) {
  return gradeWithResult(
    userStrokes: userStrokes,
    templateStrokes: templateStrokes,
    distanceThreshold: distanceThreshold,
    strokeCountTolerance: strokeCountTolerance,
  ).passed;
}
