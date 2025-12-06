import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_game/utils/stroke_grader.dart';

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
  });
}
