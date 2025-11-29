import 'kanji.dart';

class Stage {
  final int id;
  final String name;
  final String theme;
  final int grade; // Which grade kanji to use
  final int questionCount;
  final String bossName;
  final int bossHp;
  final int bossDamage;

  Stage({
    required this.id,
    required this.name,
    required this.theme,
    required this.grade,
    this.questionCount = 10,
    required this.bossName,
    this.bossHp = 100,
    this.bossDamage = 10,
  });

  static List<Stage> get allStages => [
        Stage(
          id: 1,
          name: '森の入り口',
          theme: 'forest_entrance',
          grade: 1,
          bossName: '森のスライム',
          bossHp: 80,
          bossDamage: 8,
        ),
        Stage(
          id: 2,
          name: '光の小道',
          theme: 'light_path',
          grade: 1,
          bossName: '木の精霊',
          bossHp: 100,
          bossDamage: 10,
        ),
        Stage(
          id: 3,
          name: '蝶の庭',
          theme: 'butterfly_garden',
          grade: 2,
          bossName: '蝶の女王',
          bossHp: 120,
          bossDamage: 12,
        ),
        Stage(
          id: 4,
          name: '鳥のすみか',
          theme: 'bird_nest',
          grade: 2,
          bossName: '巨大フクロウ',
          bossHp: 140,
          bossDamage: 14,
        ),
        Stage(
          id: 5,
          name: '魔法の泉',
          theme: 'magic_spring',
          grade: 3,
          bossName: '水の魔女',
          bossHp: 160,
          bossDamage: 16,
        ),
        Stage(
          id: 6,
          name: '古い橋',
          theme: 'old_bridge',
          grade: 3,
          bossName: '橋のトロル',
          bossHp: 180,
          bossDamage: 18,
        ),
        Stage(
          id: 7,
          name: '秘密の洞窟',
          theme: 'secret_cave',
          grade: 4,
          bossName: '洞窟のドラゴン',
          bossHp: 200,
          bossDamage: 20,
        ),
        Stage(
          id: 8,
          name: '星の塔',
          theme: 'star_tower',
          grade: 4,
          bossName: '星の番人',
          bossHp: 220,
          bossDamage: 22,
        ),
        Stage(
          id: 9,
          name: '時の神殿',
          theme: 'time_temple',
          grade: 5,
          bossName: '時の魔導士',
          bossHp: 240,
          bossDamage: 24,
        ),
        Stage(
          id: 10,
          name: '最後の扉',
          theme: 'final_door',
          grade: 6,
          bossName: '闇の王',
          bossHp: 300,
          bossDamage: 30,
        ),
      ];

  static Stage? getStage(int id) {
    try {
      return allStages.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}

class StageProgress {
  final int stageId;
  final List<KanjiQuestion> questions;
  int currentQuestionIndex;
  int correctAnswers;
  int coinsEarned;
  List<bool> answersCorrect;

  StageProgress({
    required this.stageId,
    required this.questions,
    this.currentQuestionIndex = 0,
    this.correctAnswers = 0,
    this.coinsEarned = 0,
    List<bool>? answersCorrect,
  }) : answersCorrect = answersCorrect ?? [];

  KanjiQuestion get currentQuestion => questions[currentQuestionIndex];

  bool get isComplete => currentQuestionIndex >= questions.length;

  bool get isPerfect => correctAnswers == questions.length;

  int get totalPossibleCoins => questions.length * 5 + 10; // 5 per question + 10 bonus

  void answerQuestion(bool correct) {
    answersCorrect.add(correct);
    if (correct) {
      correctAnswers++;
      coinsEarned += 5;
    }
    currentQuestionIndex++;

    // Add bonus for perfect score
    if (isComplete && isPerfect) {
      coinsEarned += 10;
    }
  }

  void reset() {
    currentQuestionIndex = 0;
    correctAnswers = 0;
    coinsEarned = 0;
    answersCorrect.clear();
  }
}
