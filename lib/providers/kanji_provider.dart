import 'dart:convert';
import 'dart:math';
import 'dart:ui';
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
      final jsonString = await rootBundle.loadString('assets/data/kanjivg_strokes.json');
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
        final correctReading = kanji.readings.first;
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
      final reading = k.readings.first;
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
    return [
      // Grade 1
      Kanji(kanji: '一', readings: ['いち', 'ひと'], meaning: 'one', grade: 1, strokeCount: 1),
      Kanji(kanji: '二', readings: ['に', 'ふた'], meaning: 'two', grade: 1, strokeCount: 2),
      Kanji(kanji: '三', readings: ['さん', 'み'], meaning: 'three', grade: 1, strokeCount: 3),
      Kanji(kanji: '四', readings: ['し', 'よん'], meaning: 'four', grade: 1, strokeCount: 5),
      Kanji(kanji: '五', readings: ['ご', 'いつ'], meaning: 'five', grade: 1, strokeCount: 4),
      Kanji(kanji: '六', readings: ['ろく', 'む'], meaning: 'six', grade: 1, strokeCount: 4),
      Kanji(kanji: '七', readings: ['しち', 'なな'], meaning: 'seven', grade: 1, strokeCount: 2),
      Kanji(kanji: '八', readings: ['はち', 'や'], meaning: 'eight', grade: 1, strokeCount: 2),
      Kanji(kanji: '九', readings: ['きゅう', 'く'], meaning: 'nine', grade: 1, strokeCount: 2),
      Kanji(kanji: '十', readings: ['じゅう', 'とお'], meaning: 'ten', grade: 1, strokeCount: 2),
      Kanji(kanji: '百', readings: ['ひゃく'], meaning: 'hundred', grade: 1, strokeCount: 6),
      Kanji(kanji: '千', readings: ['せん', 'ち'], meaning: 'thousand', grade: 1, strokeCount: 3),
      Kanji(kanji: '上', readings: ['うえ', 'じょう'], meaning: 'up', grade: 1, strokeCount: 3),
      Kanji(kanji: '下', readings: ['した', 'か'], meaning: 'down', grade: 1, strokeCount: 3),
      Kanji(kanji: '左', readings: ['ひだり', 'さ'], meaning: 'left', grade: 1, strokeCount: 5),
      Kanji(kanji: '右', readings: ['みぎ', 'う'], meaning: 'right', grade: 1, strokeCount: 5),
      Kanji(kanji: '中', readings: ['なか', 'ちゅう'], meaning: 'middle', grade: 1, strokeCount: 4),
      Kanji(kanji: '大', readings: ['おお', 'だい'], meaning: 'big', grade: 1, strokeCount: 3),
      Kanji(kanji: '小', readings: ['ちい', 'しょう'], meaning: 'small', grade: 1, strokeCount: 3),
      Kanji(kanji: '月', readings: ['つき', 'げつ'], meaning: 'moon/month', grade: 1, strokeCount: 4),
      Kanji(kanji: '日', readings: ['ひ', 'にち'], meaning: 'sun/day', grade: 1, strokeCount: 4),
      Kanji(kanji: '年', readings: ['とし', 'ねん'], meaning: 'year', grade: 1, strokeCount: 6),
      Kanji(kanji: '早', readings: ['はや', 'そう'], meaning: 'early', grade: 1, strokeCount: 6),
      Kanji(kanji: '木', readings: ['き', 'もく'], meaning: 'tree', grade: 1, strokeCount: 4),
      Kanji(kanji: '林', readings: ['はやし', 'りん'], meaning: 'forest', grade: 1, strokeCount: 8),
      Kanji(kanji: '山', readings: ['やま', 'さん'], meaning: 'mountain', grade: 1, strokeCount: 3),
      Kanji(kanji: '川', readings: ['かわ', 'せん'], meaning: 'river', grade: 1, strokeCount: 3),
      Kanji(kanji: '土', readings: ['つち', 'ど'], meaning: 'earth', grade: 1, strokeCount: 3),
      Kanji(kanji: '空', readings: ['そら', 'くう'], meaning: 'sky', grade: 1, strokeCount: 8),
      Kanji(kanji: '田', readings: ['た', 'でん'], meaning: 'rice field', grade: 1, strokeCount: 5),
      Kanji(kanji: '天', readings: ['あま', 'てん'], meaning: 'heaven', grade: 1, strokeCount: 4),
      Kanji(kanji: '生', readings: ['い', 'せい'], meaning: 'life', grade: 1, strokeCount: 5),
      Kanji(kanji: '花', readings: ['はな', 'か'], meaning: 'flower', grade: 1, strokeCount: 7),
      Kanji(kanji: '草', readings: ['くさ', 'そう'], meaning: 'grass', grade: 1, strokeCount: 9),
      Kanji(kanji: '虫', readings: ['むし', 'ちゅう'], meaning: 'insect', grade: 1, strokeCount: 6),
      Kanji(kanji: '犬', readings: ['いぬ', 'けん'], meaning: 'dog', grade: 1, strokeCount: 4),
      Kanji(kanji: '人', readings: ['ひと', 'じん'], meaning: 'person', grade: 1, strokeCount: 2),
      Kanji(kanji: '名', readings: ['な', 'めい'], meaning: 'name', grade: 1, strokeCount: 6),
      Kanji(kanji: '女', readings: ['おんな', 'じょ'], meaning: 'woman', grade: 1, strokeCount: 3),
      Kanji(kanji: '男', readings: ['おとこ', 'だん'], meaning: 'man', grade: 1, strokeCount: 7),
      Kanji(kanji: '子', readings: ['こ', 'し'], meaning: 'child', grade: 1, strokeCount: 3),
      Kanji(kanji: '目', readings: ['め', 'もく'], meaning: 'eye', grade: 1, strokeCount: 5),
      Kanji(kanji: '耳', readings: ['みみ', 'じ'], meaning: 'ear', grade: 1, strokeCount: 6),
      Kanji(kanji: '口', readings: ['くち', 'こう'], meaning: 'mouth', grade: 1, strokeCount: 3),
      Kanji(kanji: '手', readings: ['て', 'しゅ'], meaning: 'hand', grade: 1, strokeCount: 4),
      Kanji(kanji: '足', readings: ['あし', 'そく'], meaning: 'foot', grade: 1, strokeCount: 7),
      Kanji(kanji: '見', readings: ['み', 'けん'], meaning: 'see', grade: 1, strokeCount: 7),
      Kanji(kanji: '音', readings: ['おと', 'おん'], meaning: 'sound', grade: 1, strokeCount: 9),
      Kanji(kanji: '力', readings: ['ちから', 'りょく'], meaning: 'power', grade: 1, strokeCount: 2),
      Kanji(kanji: '気', readings: ['き', 'け'], meaning: 'spirit', grade: 1, strokeCount: 6),
      // Grade 2
      Kanji(kanji: '春', readings: ['はる', 'しゅん'], meaning: 'spring', grade: 2, strokeCount: 9),
      Kanji(kanji: '夏', readings: ['なつ', 'か'], meaning: 'summer', grade: 2, strokeCount: 10),
      Kanji(kanji: '秋', readings: ['あき', 'しゅう'], meaning: 'autumn', grade: 2, strokeCount: 9),
      Kanji(kanji: '冬', readings: ['ふゆ', 'とう'], meaning: 'winter', grade: 2, strokeCount: 5),
      Kanji(kanji: '朝', readings: ['あさ', 'ちょう'], meaning: 'morning', grade: 2, strokeCount: 12),
      Kanji(kanji: '昼', readings: ['ひる', 'ちゅう'], meaning: 'noon', grade: 2, strokeCount: 9),
      Kanji(kanji: '夜', readings: ['よる', 'や'], meaning: 'night', grade: 2, strokeCount: 8),
      Kanji(kanji: '今', readings: ['いま', 'こん'], meaning: 'now', grade: 2, strokeCount: 4),
      Kanji(kanji: '時', readings: ['とき', 'じ'], meaning: 'time', grade: 2, strokeCount: 10),
      Kanji(kanji: '間', readings: ['あいだ', 'かん'], meaning: 'interval', grade: 2, strokeCount: 12),
      Kanji(kanji: '週', readings: ['しゅう'], meaning: 'week', grade: 2, strokeCount: 11),
      Kanji(kanji: '曜', readings: ['よう'], meaning: 'weekday', grade: 2, strokeCount: 18),
      Kanji(kanji: '毎', readings: ['まい'], meaning: 'every', grade: 2, strokeCount: 6),
      Kanji(kanji: '何', readings: ['なに', 'なん'], meaning: 'what', grade: 2, strokeCount: 7),
      Kanji(kanji: '北', readings: ['きた', 'ほく'], meaning: 'north', grade: 2, strokeCount: 5),
      Kanji(kanji: '南', readings: ['みなみ', 'なん'], meaning: 'south', grade: 2, strokeCount: 9),
      Kanji(kanji: '東', readings: ['ひがし', 'とう'], meaning: 'east', grade: 2, strokeCount: 8),
      Kanji(kanji: '西', readings: ['にし', 'せい'], meaning: 'west', grade: 2, strokeCount: 6),
      Kanji(kanji: '外', readings: ['そと', 'がい'], meaning: 'outside', grade: 2, strokeCount: 5),
      Kanji(kanji: '内', readings: ['うち', 'ない'], meaning: 'inside', grade: 2, strokeCount: 4),
      Kanji(kanji: '前', readings: ['まえ', 'ぜん'], meaning: 'before', grade: 2, strokeCount: 9),
      Kanji(kanji: '後', readings: ['あと', 'ご'], meaning: 'after', grade: 2, strokeCount: 9),
      Kanji(kanji: '午', readings: ['ご'], meaning: 'noon', grade: 2, strokeCount: 4),
      Kanji(kanji: '元', readings: ['もと', 'げん'], meaning: 'origin', grade: 2, strokeCount: 4),
      Kanji(kanji: '気', readings: ['き'], meaning: 'spirit', grade: 2, strokeCount: 6),
      Kanji(kanji: '同', readings: ['おな', 'どう'], meaning: 'same', grade: 2, strokeCount: 6),
      Kanji(kanji: '多', readings: ['おお', 'た'], meaning: 'many', grade: 2, strokeCount: 6),
      Kanji(kanji: '少', readings: ['すく', 'しょう'], meaning: 'few', grade: 2, strokeCount: 4),
      Kanji(kanji: '広', readings: ['ひろ', 'こう'], meaning: 'wide', grade: 2, strokeCount: 5),
      Kanji(kanji: '長', readings: ['なが', 'ちょう'], meaning: 'long', grade: 2, strokeCount: 8),
      // Grade 3
      Kanji(kanji: '世', readings: ['よ', 'せ'], meaning: 'world', grade: 3, strokeCount: 5),
      Kanji(kanji: '界', readings: ['かい'], meaning: 'world', grade: 3, strokeCount: 9),
      Kanji(kanji: '物', readings: ['もの', 'ぶつ'], meaning: 'thing', grade: 3, strokeCount: 8),
      Kanji(kanji: '事', readings: ['こと', 'じ'], meaning: 'matter', grade: 3, strokeCount: 8),
      Kanji(kanji: '者', readings: ['もの', 'しゃ'], meaning: 'person', grade: 3, strokeCount: 8),
      Kanji(kanji: '主', readings: ['ぬし', 'しゅ'], meaning: 'master', grade: 3, strokeCount: 5),
      Kanji(kanji: '全', readings: ['まった', 'ぜん'], meaning: 'whole', grade: 3, strokeCount: 6),
      Kanji(kanji: '部', readings: ['ぶ'], meaning: 'part', grade: 3, strokeCount: 11),
      Kanji(kanji: '度', readings: ['たび', 'ど'], meaning: 'degree', grade: 3, strokeCount: 9),
      Kanji(kanji: '問', readings: ['と', 'もん'], meaning: 'question', grade: 3, strokeCount: 11),
      Kanji(kanji: '題', readings: ['だい'], meaning: 'topic', grade: 3, strokeCount: 18),
      Kanji(kanji: '答', readings: ['こた', 'とう'], meaning: 'answer', grade: 3, strokeCount: 12),
      Kanji(kanji: '動', readings: ['うご', 'どう'], meaning: 'move', grade: 3, strokeCount: 11),
      Kanji(kanji: '使', readings: ['つか', 'し'], meaning: 'use', grade: 3, strokeCount: 8),
      Kanji(kanji: '始', readings: ['はじ', 'し'], meaning: 'begin', grade: 3, strokeCount: 8),
      Kanji(kanji: '終', readings: ['お', 'しゅう'], meaning: 'end', grade: 3, strokeCount: 11),
      Kanji(kanji: '持', readings: ['も', 'じ'], meaning: 'hold', grade: 3, strokeCount: 9),
      Kanji(kanji: '送', readings: ['おく', 'そう'], meaning: 'send', grade: 3, strokeCount: 9),
      Kanji(kanji: '受', readings: ['う', 'じゅ'], meaning: 'receive', grade: 3, strokeCount: 8),
      Kanji(kanji: '取', readings: ['と', 'しゅ'], meaning: 'take', grade: 3, strokeCount: 8),
      // Grade 4
      Kanji(kanji: '不', readings: ['ふ', 'ぶ'], meaning: 'not', grade: 4, strokeCount: 4),
      Kanji(kanji: '成', readings: ['な', 'せい'], meaning: 'become', grade: 4, strokeCount: 6),
      Kanji(kanji: '功', readings: ['こう'], meaning: 'success', grade: 4, strokeCount: 5),
      Kanji(kanji: '失', readings: ['うしな', 'しつ'], meaning: 'lose', grade: 4, strokeCount: 5),
      Kanji(kanji: '必', readings: ['かなら', 'ひつ'], meaning: 'must', grade: 4, strokeCount: 5),
      Kanji(kanji: '要', readings: ['い', 'よう'], meaning: 'need', grade: 4, strokeCount: 9),
      Kanji(kanji: '求', readings: ['もと', 'きゅう'], meaning: 'request', grade: 4, strokeCount: 7),
      Kanji(kanji: '試', readings: ['ため', 'し'], meaning: 'try', grade: 4, strokeCount: 13),
      Kanji(kanji: '験', readings: ['けん'], meaning: 'test', grade: 4, strokeCount: 18),
      Kanji(kanji: '結', readings: ['むす', 'けつ'], meaning: 'tie', grade: 4, strokeCount: 12),
      Kanji(kanji: '果', readings: ['は', 'か'], meaning: 'fruit', grade: 4, strokeCount: 8),
      Kanji(kanji: '勝', readings: ['か', 'しょう'], meaning: 'win', grade: 4, strokeCount: 12),
      Kanji(kanji: '負', readings: ['ま', 'ふ'], meaning: 'lose', grade: 4, strokeCount: 9),
      Kanji(kanji: '戦', readings: ['たたか', 'せん'], meaning: 'war', grade: 4, strokeCount: 13),
      Kanji(kanji: '争', readings: ['あらそ', 'そう'], meaning: 'fight', grade: 4, strokeCount: 6),
      Kanji(kanji: '軍', readings: ['ぐん'], meaning: 'army', grade: 4, strokeCount: 9),
      Kanji(kanji: '兵', readings: ['へい'], meaning: 'soldier', grade: 4, strokeCount: 7),
      Kanji(kanji: '氏', readings: ['うじ', 'し'], meaning: 'clan', grade: 4, strokeCount: 4),
      Kanji(kanji: '民', readings: ['たみ', 'みん'], meaning: 'people', grade: 4, strokeCount: 5),
      Kanji(kanji: '法', readings: ['ほう'], meaning: 'law', grade: 4, strokeCount: 8),
      // Grade 5
      Kanji(kanji: '政', readings: ['まつりごと', 'せい'], meaning: 'politics', grade: 5, strokeCount: 9),
      Kanji(kanji: '経', readings: ['へ', 'けい'], meaning: 'pass through', grade: 5, strokeCount: 11),
      Kanji(kanji: '済', readings: ['す', 'さい'], meaning: 'settle', grade: 5, strokeCount: 11),
      Kanji(kanji: '財', readings: ['ざい'], meaning: 'wealth', grade: 5, strokeCount: 10),
      Kanji(kanji: '産', readings: ['う', 'さん'], meaning: 'produce', grade: 5, strokeCount: 11),
      Kanji(kanji: '業', readings: ['わざ', 'ぎょう'], meaning: 'business', grade: 5, strokeCount: 13),
      Kanji(kanji: '職', readings: ['しょく'], meaning: 'job', grade: 5, strokeCount: 18),
      Kanji(kanji: '術', readings: ['じゅつ'], meaning: 'art', grade: 5, strokeCount: 11),
      Kanji(kanji: '技', readings: ['わざ', 'ぎ'], meaning: 'skill', grade: 5, strokeCount: 7),
      Kanji(kanji: '能', readings: ['のう'], meaning: 'ability', grade: 5, strokeCount: 10),
      // Grade 6
      Kanji(kanji: '私', readings: ['わたし', 'し'], meaning: 'I/private', grade: 6, strokeCount: 7),
      Kanji(kanji: '我', readings: ['われ', 'が'], meaning: 'I/we', grade: 6, strokeCount: 7),
      Kanji(kanji: '彼', readings: ['かれ', 'ひ'], meaning: 'he', grade: 6, strokeCount: 8),
      Kanji(kanji: '誰', readings: ['だれ'], meaning: 'who', grade: 6, strokeCount: 15),
      Kanji(kanji: '皆', readings: ['みな', 'かい'], meaning: 'everyone', grade: 6, strokeCount: 9),
      Kanji(kanji: '各', readings: ['おのおの', 'かく'], meaning: 'each', grade: 6, strokeCount: 6),
      Kanji(kanji: '自', readings: ['みずか', 'じ'], meaning: 'self', grade: 6, strokeCount: 6),
      Kanji(kanji: '己', readings: ['おのれ', 'こ'], meaning: 'oneself', grade: 6, strokeCount: 3),
      Kanji(kanji: '心', readings: ['こころ', 'しん'], meaning: 'heart', grade: 6, strokeCount: 4),
      Kanji(kanji: '意', readings: ['い'], meaning: 'mind', grade: 6, strokeCount: 13),
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
