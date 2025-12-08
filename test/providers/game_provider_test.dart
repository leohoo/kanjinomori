import 'package:flutter_test/flutter_test.dart';
import 'package:kanji_game/models/models.dart';

void main() {
  group('StageProgress coinsEarned', () {
    test('should track coins earned from answers', () {
      final questions = List.generate(10, (i) => KanjiQuestion(
        kanji: Kanji(
          kanji: '一',
          readings: ['いち'],
          meaning: 'one',
          strokeCount: 1,
          grade: 1,
        ),
        type: QuestionType.reading,
        choices: ['いち', 'に', 'さん', 'し'],
        correctAnswer: 'いち',
      ));

      final progress = StageProgress(stageId: 1, questions: questions);
      expect(progress.coinsEarned, equals(0));

      // Answer first question correctly
      progress.answerQuestion(true);
      expect(progress.coinsEarned, equals(5));

      // Answer second question wrong
      progress.answerQuestion(false);
      expect(progress.coinsEarned, equals(5)); // No change
    });

    test('should allow setting coinsEarned directly', () {
      final questions = List.generate(10, (i) => KanjiQuestion(
        kanji: Kanji(
          kanji: '一',
          readings: ['いち'],
          meaning: 'one',
          strokeCount: 1,
          grade: 1,
        ),
        type: QuestionType.reading,
        choices: ['いち', 'に', 'さん', 'し'],
        correctAnswer: 'いち',
      ));

      final progress = StageProgress(stageId: 1, questions: questions);
      expect(progress.coinsEarned, equals(0));

      // This is what completeFieldStage should do - sync coins from GameCoordinator
      progress.coinsEarned = 45;
      expect(progress.coinsEarned, equals(45));
    });

    test('coinsEarned should persist after being set externally', () {
      final questions = List.generate(10, (i) => KanjiQuestion(
        kanji: Kanji(
          kanji: '一',
          readings: ['いち'],
          meaning: 'one',
          strokeCount: 1,
          grade: 1,
        ),
        type: QuestionType.reading,
        choices: ['いち', 'に', 'さん', 'し'],
        correctAnswer: 'いち',
      ));

      final progress = StageProgress(stageId: 1, questions: questions);

      // Simulate GameCoordinator setting coins
      const coordinatorCoins = 60; // Max: 10 questions * 5 + 10 bonus
      progress.coinsEarned = coordinatorCoins;

      // Verify it can be read back (this is what VictoryScreen does)
      expect(progress.coinsEarned, equals(coordinatorCoins));
    });
  });
}
