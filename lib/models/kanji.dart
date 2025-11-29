import 'package:hive/hive.dart';

part 'kanji.g.dart';

enum QuestionType { reading, writing }

@HiveType(typeId: 0)
class Kanji extends HiveObject {
  @HiveField(0)
  final String kanji;

  @HiveField(1)
  final List<String> readings; // ひらがな readings

  @HiveField(2)
  final String meaning;

  @HiveField(3)
  final int grade; // 1-6 for elementary school

  @HiveField(4)
  final int strokeCount;

  Kanji({
    required this.kanji,
    required this.readings,
    required this.meaning,
    required this.grade,
    this.strokeCount = 0,
  });

  factory Kanji.fromJson(Map<String, dynamic> json) {
    return Kanji(
      kanji: json['kanji'] as String,
      readings: List<String>.from(json['readings'] as List),
      meaning: json['meaning'] as String,
      grade: json['grade'] as int,
      strokeCount: json['stroke_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'kanji': kanji,
        'readings': readings,
        'meaning': meaning,
        'grade': grade,
        'stroke_count': strokeCount,
      };
}

class KanjiQuestion {
  final Kanji kanji;
  final QuestionType type;
  final List<String> choices; // For reading questions
  final String correctAnswer;
  final int coinReward;

  KanjiQuestion({
    required this.kanji,
    required this.type,
    required this.choices,
    required this.correctAnswer,
    this.coinReward = 5,
  });

  bool checkAnswer(String answer) {
    if (type == QuestionType.reading) {
      return answer == correctAnswer;
    } else {
      // For writing, compare the kanji character
      return answer == kanji.kanji;
    }
  }
}
