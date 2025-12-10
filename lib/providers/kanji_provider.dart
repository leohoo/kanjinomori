import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kanji.dart';

class KanjiRepository {
  List<Kanji> _allKanji = [];
  Map<String, List<List<Offset>>> _strokeTemplates = {};
  final Random _random = Random();

  Future<void> loadKanji() async {
    if (_allKanji.isNotEmpty) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/kanji.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _allKanji = jsonList.map((json) => Kanji.fromJson(json)).toList();
    } catch (e) {
      // If file doesn't exist yet, use sample data
      _allKanji = _getSampleKanji();
    }
  }

  Future<void> loadStrokes() async {
    if (_strokeTemplates.isNotEmpty) return;

    try {
      final jsonString = await rootBundle.loadString('assets/data/kyouiku_strokes.json');
      final Map<String, dynamic> decoded = json.decode(jsonString);
      _strokeTemplates = decoded.map((kanji, strokes) {
        final parsedStrokes = (strokes as List)
            .map((stroke) => (stroke as List)
                .map((point) => Offset(
                      (point[0] as num).toDouble(),
                      (point[1] as num).toDouble(),
                    ))
                .toList())
            .toList();
        return MapEntry(kanji, parsedStrokes);
      });
    } catch (_) {
      _strokeTemplates = {};
    }
  }

  List<List<Offset>>? getStrokeTemplate(String kanji) {
    return _strokeTemplates[kanji];
  }

  List<Kanji> getKanjiByGrade(int grade) {
    return _allKanji.where((k) => k.grade == grade).toList();
  }

  List<Kanji> getKanjiByGrades(List<int> grades) {
    return _allKanji.where((k) => grades.contains(k.grade)).toList();
  }

  List<KanjiQuestion> generateQuestions(int grade, int count) {
    final kanjiList = getKanjiByGrade(grade);
    if (kanjiList.isEmpty) {
      // Fallback to all available kanji
      return _generateFromList(_allKanji, count);
    }
    return _generateFromList(kanjiList, count);
  }

  List<KanjiQuestion> _generateFromList(List<Kanji> kanjiList, int count) {
    final questions = <KanjiQuestion>[];
    final shuffled = List<Kanji>.from(kanjiList)..shuffle(_random);
    final selected = shuffled.take(count).toList();

    for (final kanji in selected) {
      // Alternate between reading and writing questions
      final isReading = _random.nextBool();

      if (isReading) {
        // Reading question: show kanji, choose correct reading
        // Pick a random reading from all available readings
        final correctReading = kanji.readings[_random.nextInt(kanji.readings.length)];
        final wrongChoices = _getWrongReadings(kanji, kanjiList, 3);
        final choices = [correctReading, ...wrongChoices]..shuffle(_random);

        questions.add(KanjiQuestion(
          kanji: kanji,
          type: QuestionType.reading,
          choices: choices,
          correctAnswer: correctReading,
        ));
      } else {
        // Writing question: show reading/meaning, draw kanji
        questions.add(KanjiQuestion(
          kanji: kanji,
          type: QuestionType.writing,
          choices: [], // Not used for writing
          correctAnswer: kanji.kanji,
        ));
      }
    }

    return questions;
  }

  List<String> _getWrongReadings(Kanji correct, List<Kanji> pool, int count) {
    final wrongReadings = <String>[];
    final otherKanji = pool.where((k) => k.kanji != correct.kanji).toList()
      ..shuffle(_random);

    for (final k in otherKanji) {
      if (wrongReadings.length >= count) break;
      // Pick a random reading from this kanji
      final reading = k.readings[_random.nextInt(k.readings.length)];
      if (!correct.readings.contains(reading) &&
          !wrongReadings.contains(reading)) {
        wrongReadings.add(reading);
      }
    }

    // If not enough wrong readings, generate some
    while (wrongReadings.length < count) {
      wrongReadings.add(_generateFakeReading());
    }

    return wrongReadings;
  }

  String _generateFakeReading() {
    const hiragana = [
      'あ', 'い', 'う', 'え', 'お',
      'か', 'き', 'く', 'け', 'こ',
      'さ', 'し', 'す', 'せ', 'そ',
      'た', 'ち', 'つ', 'て', 'と',
      'な', 'に', 'ぬ', 'ね', 'の',
      'は', 'ひ', 'ふ', 'へ', 'ほ',
      'ま', 'み', 'む', 'め', 'も',
      'や', 'ゆ', 'よ',
      'ら', 'り', 'る', 'れ', 'ろ',
      'わ', 'を', 'ん',
    ];
    final length = _random.nextInt(2) + 2; // 2-3 characters
    return List.generate(length, (_) => hiragana[_random.nextInt(hiragana.length)])
        .join();
  }

  List<Kanji> _getSampleKanji() {
    // Fallback sample data with curriculum-aligned readings from MEXT
    return [
      // Grade 1
      Kanji(kanji: '一', readings: ['いち', 'いつ', 'ひと', 'ひとつ'], meaning: 'one', grade: 1, strokeCount: 1),
      Kanji(kanji: '二', readings: ['に', 'ふた', 'ふたつ'], meaning: 'two', grade: 1, strokeCount: 2),
      Kanji(kanji: '三', readings: ['さん', 'み', 'みつ', 'みっつ'], meaning: 'three', grade: 1, strokeCount: 3),
      Kanji(kanji: '四', readings: ['し', 'よ', 'よつ', 'よっつ', 'よん'], meaning: 'four', grade: 1, strokeCount: 5),
      Kanji(kanji: '五', readings: ['ご', 'いつ', 'いつつ'], meaning: 'five', grade: 1, strokeCount: 4),
      Kanji(kanji: '六', readings: ['ろく', 'む', 'むつ', 'むい', 'むっつ'], meaning: 'six', grade: 1, strokeCount: 4),
      Kanji(kanji: '七', readings: ['しち', 'なな', 'ななつ', 'なの'], meaning: 'seven', grade: 1, strokeCount: 2),
      Kanji(kanji: '八', readings: ['はち', 'や', 'やつ', 'やっつ', 'よう'], meaning: 'eight', grade: 1, strokeCount: 2),
      Kanji(kanji: '九', readings: ['きゅう', 'く', 'ここの', 'ここのつ'], meaning: 'nine', grade: 1, strokeCount: 2),
      Kanji(kanji: '十', readings: ['じっ', 'じゅう', 'と', 'とお'], meaning: 'ten', grade: 1, strokeCount: 2),
      Kanji(kanji: '百', readings: ['ひゃく'], meaning: 'hundred', grade: 1, strokeCount: 6),
      Kanji(kanji: '千', readings: ['せん', 'ち'], meaning: 'thousand', grade: 1, strokeCount: 3),
      Kanji(kanji: '上', readings: ['じょう', 'あがる', 'あげる', 'うえ', 'うわ', 'かみ', 'のぼる'], meaning: 'above', grade: 1, strokeCount: 3),
      Kanji(kanji: '下', readings: ['か', 'げ', 'おりる', 'おろす', 'くださる', 'くだす', 'くだる', 'さがる', 'さげる', 'した', 'しも'], meaning: 'below', grade: 1, strokeCount: 3),
      Kanji(kanji: '左', readings: ['さ', 'ひだり'], meaning: 'left', grade: 1, strokeCount: 5),
      Kanji(kanji: '右', readings: ['う', 'ゆう', 'みぎ'], meaning: 'right', grade: 1, strokeCount: 5),
      Kanji(kanji: '中', readings: ['じゅう', 'ちゅう', 'なか'], meaning: 'in', grade: 1, strokeCount: 4),
      Kanji(kanji: '大', readings: ['たい', 'だい', 'おお', 'おおいに', 'おおきい'], meaning: 'large', grade: 1, strokeCount: 3),
      Kanji(kanji: '小', readings: ['しょう', 'お', 'こ', 'ちいさい'], meaning: 'little', grade: 1, strokeCount: 3),
      Kanji(kanji: '月', readings: ['がつ', 'げつ', 'つき'], meaning: 'month', grade: 1, strokeCount: 4),
      Kanji(kanji: '日', readings: ['じつ', 'にち', 'か', 'ひ'], meaning: 'day', grade: 1, strokeCount: 4),
      Kanji(kanji: '年', readings: ['ねん', 'とし'], meaning: 'year', grade: 1, strokeCount: 6),
      Kanji(kanji: '早', readings: ['そう', 'はやい', 'はやまる', 'はやめる'], meaning: 'early', grade: 1, strokeCount: 6),
      Kanji(kanji: '木', readings: ['ぼく', 'もく', 'き', 'こ'], meaning: 'tree', grade: 1, strokeCount: 4),
      Kanji(kanji: '林', readings: ['りん', 'はやし'], meaning: 'grove', grade: 1, strokeCount: 8),
      Kanji(kanji: '山', readings: ['さん', 'やま'], meaning: 'mountain', grade: 1, strokeCount: 3),
      Kanji(kanji: '川', readings: ['かわ'], meaning: 'stream', grade: 1, strokeCount: 3),
      Kanji(kanji: '土', readings: ['と', 'ど', 'つち'], meaning: 'soil', grade: 1, strokeCount: 3),
      Kanji(kanji: '空', readings: ['くう', 'あく', 'あける', 'から', 'そら'], meaning: 'empty', grade: 1, strokeCount: 8),
      Kanji(kanji: '田', readings: ['でん', 'た'], meaning: 'rice field', grade: 1, strokeCount: 5),
      Kanji(kanji: '天', readings: ['てん', 'あま'], meaning: 'heavens', grade: 1, strokeCount: 4),
      Kanji(kanji: '生', readings: ['しょう', 'せい', 'いかす', 'いきる', 'いける', 'うまれる', 'うむ', 'なま', 'はえる', 'はやす'], meaning: 'life', grade: 1, strokeCount: 5),
      Kanji(kanji: '花', readings: ['か', 'はな'], meaning: 'flower', grade: 1, strokeCount: 7),
      Kanji(kanji: '草', readings: ['そう', 'くさ'], meaning: 'grass', grade: 1, strokeCount: 9),
      Kanji(kanji: '虫', readings: ['ちゅう', 'むし'], meaning: 'insect', grade: 1, strokeCount: 6),
      Kanji(kanji: '犬', readings: ['けん', 'いぬ'], meaning: 'dog', grade: 1, strokeCount: 4),
      Kanji(kanji: '人', readings: ['じん', 'にん', 'ひと'], meaning: 'person', grade: 1, strokeCount: 2),
      Kanji(kanji: '名', readings: ['みょう', 'めい', 'な'], meaning: 'name', grade: 1, strokeCount: 6),
      Kanji(kanji: '女', readings: ['じょ', 'おんな'], meaning: 'woman', grade: 1, strokeCount: 3),
      Kanji(kanji: '男', readings: ['だん', 'なん', 'おとこ'], meaning: 'male', grade: 1, strokeCount: 7),
      Kanji(kanji: '子', readings: ['し', 'す', 'こ'], meaning: 'child', grade: 1, strokeCount: 3),
      Kanji(kanji: '目', readings: ['もく', 'め'], meaning: 'eye', grade: 1, strokeCount: 5),
      Kanji(kanji: '耳', readings: ['みみ'], meaning: 'ear', grade: 1, strokeCount: 6),
      Kanji(kanji: '口', readings: ['く', 'こう', 'くち'], meaning: 'mouth', grade: 1, strokeCount: 3),
      Kanji(kanji: '手', readings: ['しゅ', 'て'], meaning: 'hand', grade: 1, strokeCount: 4),
      Kanji(kanji: '足', readings: ['そく', 'あし', 'たす', 'たりる', 'たる'], meaning: 'leg', grade: 1, strokeCount: 7),
      Kanji(kanji: '見', readings: ['けん', 'みえる', 'みせる', 'みる'], meaning: 'see', grade: 1, strokeCount: 7),
      Kanji(kanji: '音', readings: ['おん', 'おと', 'ね'], meaning: 'sound', grade: 1, strokeCount: 9),
      Kanji(kanji: '力', readings: ['りき', 'りょく', 'ちから'], meaning: 'power', grade: 1, strokeCount: 2),
      Kanji(kanji: '気', readings: ['き', 'け'], meaning: 'spirit', grade: 1, strokeCount: 6),
      // Grade 2
      Kanji(kanji: '春', readings: ['しゅん', 'はる'], meaning: 'springtime', grade: 2, strokeCount: 9),
      Kanji(kanji: '夏', readings: ['か', 'なつ'], meaning: 'summer', grade: 2, strokeCount: 10),
      Kanji(kanji: '秋', readings: ['しゅう', 'あき'], meaning: 'autumn', grade: 2, strokeCount: 9),
      Kanji(kanji: '冬', readings: ['とう', 'ふゆ'], meaning: 'winter', grade: 2, strokeCount: 5),
      Kanji(kanji: '朝', readings: ['ちょう', 'あさ'], meaning: 'morning', grade: 2, strokeCount: 12),
      Kanji(kanji: '昼', readings: ['ちゅう', 'ひる'], meaning: 'daytime', grade: 2, strokeCount: 9),
      Kanji(kanji: '夜', readings: ['や', 'よ', 'よる'], meaning: 'night', grade: 2, strokeCount: 8),
      Kanji(kanji: '今', readings: ['こん', 'いま'], meaning: 'now', grade: 2, strokeCount: 4),
      Kanji(kanji: '時', readings: ['じ', 'とき'], meaning: 'time', grade: 2, strokeCount: 10),
      Kanji(kanji: '間', readings: ['かん', 'けん', 'あいだ', 'ま'], meaning: 'interval', grade: 2, strokeCount: 12),
      Kanji(kanji: '週', readings: ['しゅう'], meaning: 'week', grade: 2, strokeCount: 11),
      Kanji(kanji: '曜', readings: ['よう'], meaning: 'weekday', grade: 2, strokeCount: 18),
      Kanji(kanji: '毎', readings: ['まい'], meaning: 'every', grade: 2, strokeCount: 6),
      Kanji(kanji: '何', readings: ['なに', 'なん'], meaning: 'what', grade: 2, strokeCount: 7),
      Kanji(kanji: '北', readings: ['ほく', 'きた'], meaning: 'north', grade: 2, strokeCount: 5),
      Kanji(kanji: '南', readings: ['なん', 'みなみ'], meaning: 'south', grade: 2, strokeCount: 9),
      Kanji(kanji: '東', readings: ['とう', 'ひがし'], meaning: 'east', grade: 2, strokeCount: 8),
      Kanji(kanji: '西', readings: ['さい', 'せい', 'にし'], meaning: 'west', grade: 2, strokeCount: 6),
      Kanji(kanji: '外', readings: ['がい', 'そと', 'はずす', 'はずれる', 'ほか'], meaning: 'outside', grade: 2, strokeCount: 5),
      Kanji(kanji: '内', readings: ['ない', 'うち'], meaning: 'inside', grade: 2, strokeCount: 4),
      Kanji(kanji: '前', readings: ['ぜん', 'まえ'], meaning: 'in front', grade: 2, strokeCount: 9),
      Kanji(kanji: '後', readings: ['こう', 'ご', 'あと', 'うしろ', 'のち'], meaning: 'behind', grade: 2, strokeCount: 9),
      Kanji(kanji: '午', readings: ['ご'], meaning: 'noon', grade: 2, strokeCount: 4),
      Kanji(kanji: '元', readings: ['がん', 'げん', 'もと'], meaning: 'beginning', grade: 2, strokeCount: 4),
      Kanji(kanji: '同', readings: ['どう', 'おなじ'], meaning: 'same', grade: 2, strokeCount: 6),
      Kanji(kanji: '多', readings: ['た', 'おおい'], meaning: 'many', grade: 2, strokeCount: 6),
      Kanji(kanji: '少', readings: ['しょう', 'すくない', 'すこし'], meaning: 'few', grade: 2, strokeCount: 4),
      Kanji(kanji: '広', readings: ['こう', 'ひろい', 'ひろがる', 'ひろげる', 'ひろまる', 'ひろめる'], meaning: 'wide', grade: 2, strokeCount: 5),
      Kanji(kanji: '長', readings: ['ちょう', 'ながい'], meaning: 'long', grade: 2, strokeCount: 8),
      Kanji(kanji: '答', readings: ['とう', 'こたえ', 'こたえる'], meaning: 'solution', grade: 2, strokeCount: 12),
      // Grade 3
      Kanji(kanji: '世', readings: ['せ', 'せい', 'よ'], meaning: 'generation', grade: 3, strokeCount: 5),
      Kanji(kanji: '界', readings: ['かい'], meaning: 'world', grade: 3, strokeCount: 9),
      Kanji(kanji: '物', readings: ['ぶつ', 'もつ', 'もの'], meaning: 'thing', grade: 3, strokeCount: 8),
      Kanji(kanji: '事', readings: ['じ', 'こと'], meaning: 'matter', grade: 3, strokeCount: 8),
      Kanji(kanji: '者', readings: ['しゃ', 'もの'], meaning: 'someone', grade: 3, strokeCount: 8),
      Kanji(kanji: '主', readings: ['しゅ', 'おも', 'ぬし'], meaning: 'lord', grade: 3, strokeCount: 5),
      Kanji(kanji: '全', readings: ['ぜん', 'すべて', 'まったく'], meaning: 'whole', grade: 3, strokeCount: 6),
      Kanji(kanji: '部', readings: ['ぶ'], meaning: 'section', grade: 3, strokeCount: 11),
      Kanji(kanji: '度', readings: ['ど'], meaning: 'degrees', grade: 3, strokeCount: 9),
      Kanji(kanji: '問', readings: ['もん', 'とい', 'とう', 'とん'], meaning: 'question', grade: 3, strokeCount: 11),
      Kanji(kanji: '題', readings: ['だい'], meaning: 'topic', grade: 3, strokeCount: 18),
      Kanji(kanji: '動', readings: ['どう', 'うごかす', 'うごく'], meaning: 'move', grade: 3, strokeCount: 11),
      Kanji(kanji: '使', readings: ['し', 'つかう'], meaning: 'use', grade: 3, strokeCount: 8),
      Kanji(kanji: '始', readings: ['し', 'はじまる', 'はじめる'], meaning: 'commence', grade: 3, strokeCount: 8),
      Kanji(kanji: '終', readings: ['しゅう', 'おえる', 'おわる'], meaning: 'end', grade: 3, strokeCount: 11),
      Kanji(kanji: '持', readings: ['じ', 'もつ'], meaning: 'hold', grade: 3, strokeCount: 9),
      Kanji(kanji: '送', readings: ['そう', 'おくる'], meaning: 'escort', grade: 3, strokeCount: 9),
      Kanji(kanji: '受', readings: ['じゅ', 'うかる', 'うける'], meaning: 'accept', grade: 3, strokeCount: 8),
      Kanji(kanji: '取', readings: ['しゅ', 'とる'], meaning: 'take', grade: 3, strokeCount: 8),
      Kanji(kanji: '勝', readings: ['しょう', 'かつ'], meaning: 'victory', grade: 3, strokeCount: 12),
      Kanji(kanji: '負', readings: ['ふ', 'おう', 'まかす', 'まける'], meaning: 'defeat', grade: 3, strokeCount: 9),
      Kanji(kanji: '業', readings: ['ぎょう'], meaning: 'business', grade: 3, strokeCount: 13),
      Kanji(kanji: '意', readings: ['い'], meaning: 'idea', grade: 3, strokeCount: 13),
      // Grade 4
      Kanji(kanji: '不', readings: ['ふ', 'ぶ'], meaning: 'negative', grade: 4, strokeCount: 4),
      Kanji(kanji: '成', readings: ['せい', 'なす', 'なる'], meaning: 'turn into', grade: 4, strokeCount: 6),
      Kanji(kanji: '功', readings: ['こう'], meaning: 'achievement', grade: 4, strokeCount: 5),
      Kanji(kanji: '失', readings: ['しつ', 'うしなう'], meaning: 'lose', grade: 4, strokeCount: 5),
      Kanji(kanji: '必', readings: ['ひつ', 'かならず'], meaning: 'invariably', grade: 4, strokeCount: 5),
      Kanji(kanji: '要', readings: ['よう', 'かなめ'], meaning: 'need', grade: 4, strokeCount: 9),
      Kanji(kanji: '求', readings: ['きゅう', 'もとめる'], meaning: 'request', grade: 4, strokeCount: 7),
      Kanji(kanji: '試', readings: ['し', 'こころみる'], meaning: 'test', grade: 4, strokeCount: 13),
      Kanji(kanji: '験', readings: ['けん'], meaning: 'verification', grade: 4, strokeCount: 18),
      Kanji(kanji: '結', readings: ['けつ', 'むすぶ'], meaning: 'tie', grade: 4, strokeCount: 12),
      Kanji(kanji: '果', readings: ['か', 'はたす', 'はて', 'はてる'], meaning: 'fruit', grade: 4, strokeCount: 8),
      Kanji(kanji: '戦', readings: ['せん', 'たたかう'], meaning: 'war', grade: 4, strokeCount: 13),
      Kanji(kanji: '争', readings: ['そう', 'あらそう'], meaning: 'contend', grade: 4, strokeCount: 6),
      Kanji(kanji: '軍', readings: ['ぐん'], meaning: 'army', grade: 4, strokeCount: 9),
      Kanji(kanji: '兵', readings: ['へい', 'ひょう'], meaning: 'soldier', grade: 4, strokeCount: 7),
      Kanji(kanji: '氏', readings: ['し'], meaning: 'family name', grade: 4, strokeCount: 4),
      Kanji(kanji: '民', readings: ['みん'], meaning: 'people', grade: 4, strokeCount: 5),
      Kanji(kanji: '法', readings: ['ほう'], meaning: 'method', grade: 4, strokeCount: 8),
      Kanji(kanji: '産', readings: ['さん', 'うまれる', 'うむ'], meaning: 'products', grade: 4, strokeCount: 11),
      Kanji(kanji: '各', readings: ['かく'], meaning: 'each', grade: 4, strokeCount: 6),
      // Grade 5
      Kanji(kanji: '政', readings: ['せい'], meaning: 'politics', grade: 5, strokeCount: 9),
      Kanji(kanji: '経', readings: ['けい', 'へる'], meaning: 'sutra', grade: 5, strokeCount: 11),
      Kanji(kanji: '財', readings: ['ざい'], meaning: 'property', grade: 5, strokeCount: 10),
      Kanji(kanji: '職', readings: ['しょく'], meaning: 'post', grade: 5, strokeCount: 18),
      Kanji(kanji: '術', readings: ['じゅつ'], meaning: 'art', grade: 5, strokeCount: 11),
      Kanji(kanji: '技', readings: ['ぎ'], meaning: 'skill', grade: 5, strokeCount: 7),
      Kanji(kanji: '能', readings: ['のう'], meaning: 'ability', grade: 5, strokeCount: 10),
      Kanji(kanji: '条', readings: ['じょう'], meaning: 'article', grade: 5, strokeCount: 7),
      Kanji(kanji: '件', readings: ['けん'], meaning: 'affair', grade: 5, strokeCount: 6),
      Kanji(kanji: '価', readings: ['か'], meaning: 'value', grade: 5, strokeCount: 8),
      // Grade 6
      Kanji(kanji: '私', readings: ['し', 'わたくし', 'わたし'], meaning: 'private', grade: 6, strokeCount: 7),
      Kanji(kanji: '我', readings: ['われ'], meaning: 'ego', grade: 6, strokeCount: 7),
      Kanji(kanji: '己', readings: ['こ'], meaning: 'self', grade: 6, strokeCount: 3),
      Kanji(kanji: '済', readings: ['さい', 'すます', 'すむ'], meaning: 'settle', grade: 6, strokeCount: 11),
      Kanji(kanji: '認', readings: ['にん', 'みとめる'], meaning: 'acknowledge', grade: 6, strokeCount: 14),
      Kanji(kanji: '論', readings: ['ろん'], meaning: 'argument', grade: 6, strokeCount: 15),
      Kanji(kanji: '権', readings: ['けん'], meaning: 'authority', grade: 6, strokeCount: 15),
      Kanji(kanji: '憲', readings: ['けん'], meaning: 'constitution', grade: 6, strokeCount: 16),
      Kanji(kanji: '値', readings: ['ち', 'ね', 'あたい'], meaning: 'price', grade: 6, strokeCount: 10),
      Kanji(kanji: '域', readings: ['いき'], meaning: 'range', grade: 6, strokeCount: 11),
    ];
  }
}

final kanjiRepositoryProvider = Provider<KanjiRepository>((ref) {
  return KanjiRepository();
});

final kanjiLoadedProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(kanjiRepositoryProvider);
  await repo.loadKanji();
  await repo.loadStrokes();
});
