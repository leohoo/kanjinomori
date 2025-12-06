import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_game/utils/stroke_grader.dart';

List<Offset> _horizontalLine(double y) =>
    [Offset(0, y), Offset(0.5, y), Offset(1, y)];

List<Offset> _verticalLine(double x) =>
    [Offset(x, 0), Offset(x, 0.5), Offset(x, 1)];

List<Offset> _slopedLine(double y, double delta) =>
    [Offset(0, y), Offset(1, y + delta)];

void main() {
  group('gradeWithStrokes', () {
    test('accepts similar single-stroke shape', () {
      final template = [_slopedLine(0.5, 0.01)];
      final user = [
        [const Offset(0.05, 0.51), const Offset(0.95, 0.52)]
      ];

      final result = gradeWithStrokes(
        userStrokes: user,
        templateStrokes: template,
      );

      expect(result, isTrue);
    });

    test('rejects when shape deviates noticeably', () {
      final template = [_slopedLine(0.5, 0.01)];
      final user = [
        [const Offset(0.5, 0.1), const Offset(0.5, 0.9)]
      ];

      final result = gradeWithStrokes(
        userStrokes: user,
        templateStrokes: template,
      );

      expect(result, isFalse);
    });

    test('rejects when stroke count differs too much', () {
      final template = [_slopedLine(0.5, 0.01), _slopedLine(0.7, -0.01)];
      final user = [
        [const Offset(0.0, 0.5), const Offset(1.0, 0.5)],
      ];

      final result = gradeWithStrokes(
        userStrokes: user,
        templateStrokes: template,
        strokeCountTolerance: 0,
      );

      expect(result, isFalse);
    });

    test('rejects empty user strokes', () {
      final template = [_horizontalLine(0.5)];
      final result = gradeWithStrokes(
        userStrokes: [],
        templateStrokes: template,
      );
      expect(result, isFalse);
    });

    test('accepts stroke count within tolerance', () {
      final template = [_horizontalLine(0.3), _horizontalLine(0.7)];
      final user = [_horizontalLine(0.3)]; // 1 stroke instead of 2

      final result = gradeWithStrokes(
        userStrokes: user,
        templateStrokes: template,
        strokeCountTolerance: 1,
      );

      // With tolerance=1, missing 1 stroke is allowed, and the shape matches
      expect(result, isTrue);
    });

    test('accepts multi-stroke kanji with correct strokes', () {
      // Simulate a simple 十 (cross) shape
      final template = [_horizontalLine(0.5), _verticalLine(0.5)];
      final user = [
        [const Offset(0.05, 0.5), const Offset(0.5, 0.5), const Offset(0.95, 0.5)],
        [const Offset(0.5, 0.05), const Offset(0.5, 0.5), const Offset(0.5, 0.95)],
      ];

      final result = gradeWithStrokes(
        userStrokes: user,
        templateStrokes: template,
      );

      expect(result, isTrue);
    });
  });

  group('gradeWithResult', () {
    test('returns passed=true for correct strokes', () {
      final template = [_slopedLine(0.5, 0.01)];
      final user = [
        [const Offset(0.05, 0.51), const Offset(0.95, 0.52)]
      ];

      final result = gradeWithResult(
        userStrokes: user,
        templateStrokes: template,
      );

      expect(result.passed, isTrue);
      expect(result.failureReason, isNull);
    });

    test('returns strokeCount failure for wrong stroke count', () {
      final template = [
        _slopedLine(0.5, 0.01),
        _slopedLine(0.7, -0.01),
        _slopedLine(0.9, 0.01)
      ];
      final user = [
        [const Offset(0.0, 0.5), const Offset(1.0, 0.5)],
      ];

      final result = gradeWithResult(
        userStrokes: user,
        templateStrokes: template,
        strokeCountTolerance: 1,
      );

      expect(result.passed, isFalse);
      expect(result.failureReason, FailureReason.strokeCount);
    });

    test('returns strokeCount failure for empty user strokes', () {
      final template = [_horizontalLine(0.5)];

      final result = gradeWithResult(
        userStrokes: [],
        templateStrokes: template,
      );

      expect(result.passed, isFalse);
      expect(result.failureReason, FailureReason.strokeCount);
      expect(result.distance, double.infinity);
    });

    test('returns strokeShape failure for wrong shape', () {
      final template = [_slopedLine(0.5, 0.01)];
      final user = [
        [const Offset(0.5, 0.1), const Offset(0.5, 0.9)]
      ];

      final result = gradeWithResult(
        userStrokes: user,
        templateStrokes: template,
      );

      expect(result.passed, isFalse);
      expect(result.failureReason, FailureReason.strokeShape);
    });

    test('returns strokeOrder failure when reordering improves score', () {
      // Two horizontal lines - user draws them in reverse order
      final template = [_horizontalLine(0.2), _horizontalLine(0.8)];
      final user = [_horizontalLine(0.8), _horizontalLine(0.2)]; // swapped order

      final result = gradeWithResult(
        userStrokes: user,
        templateStrokes: template,
      );

      expect(result.passed, isFalse);
      expect(result.failureReason, FailureReason.strokeOrder);
    });

    test('provides hint messages for each failure reason', () {
      expect(
        const GradeResult(
                passed: false,
                failureReason: FailureReason.strokeCount,
                distance: 0)
            .hintMessage,
        '画数を確認しよう',
      );
      expect(
        const GradeResult(
                passed: false,
                failureReason: FailureReason.strokeOrder,
                distance: 0)
            .hintMessage,
        '書き順を確認しよう',
      );
      expect(
        const GradeResult(
                passed: false,
                failureReason: FailureReason.strokeShape,
                distance: 0)
            .hintMessage,
        '形を確認しよう',
      );
    });

    test('returns null hintMessage when passed', () {
      final result = const GradeResult(passed: true, distance: 0.1);
      expect(result.hintMessage, isNull);
      expect(result.failureReason, isNull);
    });

    test('distance is finite for valid comparisons', () {
      final template = [_horizontalLine(0.5)];
      // Use a noticeably different line to get a non-zero distance
      final user = [
        [const Offset(0, 0.7), const Offset(0.5, 0.7), const Offset(1, 0.7)]
      ];

      final result = gradeWithResult(
        userStrokes: user,
        templateStrokes: template,
      );

      expect(result.distance.isFinite, isTrue);
      expect(result.distance, greaterThanOrEqualTo(0));
    });

  });

  group('GradeResult', () {
    test('equality and properties', () {
      const result1 = GradeResult(
        passed: false,
        failureReason: FailureReason.strokeCount,
        distance: 0.5,
      );

      expect(result1.passed, isFalse);
      expect(result1.failureReason, FailureReason.strokeCount);
      expect(result1.distance, 0.5);
    });

    test('passed result has no failure reason', () {
      const result = GradeResult(passed: true, distance: 0.1);

      expect(result.passed, isTrue);
      expect(result.failureReason, isNull);
      expect(result.hintMessage, isNull);
    });
  });

  group('FailureReason', () {
    test('enum values exist', () {
      expect(FailureReason.values, contains(FailureReason.strokeCount));
      expect(FailureReason.values, contains(FailureReason.strokeOrder));
      expect(FailureReason.values, contains(FailureReason.strokeShape));
      expect(FailureReason.values.length, 3);
    });
  });
}
