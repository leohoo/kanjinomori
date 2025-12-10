#!/usr/bin/env dart
import 'dart:convert';
import 'dart:io';

/// Generates curriculum-aligned kanji.json by merging MEXT reading data with KANJIDIC2.
///
/// ## Data Sources
///
/// ### Primary: MEXT 音訓の小・中・高等学校段階別割り振り表
///
/// Official PDF (authoritative source):
///   https://www.mext.go.jp/a_menu/shotou/new-cs/__icsFiles/afieldfile/2017/05/15/1385768.pdf
///
/// Machine-readable version (derived from PDF):
///   https://www.kabipan.com/language/japanese/haitou/joyo_hash20220315.js
///
/// Download with:
///   curl -sL "https://www.kabipan.com/language/japanese/haitou/joyo_hash20220315.js" -o /tmp/joyo_hash.js
///
/// ### Secondary: KANJIDIC2 (for meanings and stroke counts)
///
///   https://www.edrdg.org/kanjidic/kanjidic2.xml.gz
///
/// Download with:
///   curl -sL "https://www.edrdg.org/kanjidic/kanjidic2.xml.gz" | gunzip > /tmp/kanjidic2.xml
///
/// ## Usage
///
///   dart run tool/mext_to_kanji_json.dart \
///     --mext /tmp/joyo_hash.js \
///     --kanjidic /tmp/kanjidic2.xml \
///     --output assets/data/kanji.json
///
/// ## Output
///
/// Generates kanji.json with curriculum-aligned readings for grades 1-6.
/// Only includes readings that are taught at or before each kanji's grade level.

void main(List<String> args) async {
  final mextIndex = args.indexOf('--mext');
  final kanjidicIndex = args.indexOf('--kanjidic');
  final outputIndex = args.indexOf('--output');

  if (mextIndex == -1 ||
      mextIndex + 1 >= args.length ||
      kanjidicIndex == -1 ||
      kanjidicIndex + 1 >= args.length ||
      outputIndex == -1 ||
      outputIndex + 1 >= args.length) {
    stderr.writeln('''
Usage: dart run tool/mext_to_kanji_json.dart \\
  --mext <joyo_hash.js> \\
  --kanjidic <kanjidic2.xml> \\
  --output <kanji.json>

Download data first:
  curl -sL "https://www.kabipan.com/language/japanese/haitou/joyo_hash20220315.js" -o /tmp/joyo_hash.js
  curl -sL "https://www.edrdg.org/kanjidic/kanjidic2.xml.gz" | gunzip > /tmp/kanjidic2.xml
''');
    exit(64);
  }

  final mextFile = File(args[mextIndex + 1]);
  final kanjidicFile = File(args[kanjidicIndex + 1]);
  final outputFile = File(args[outputIndex + 1]);

  if (!mextFile.existsSync()) {
    stderr.writeln('MEXT file not found: ${mextFile.path}');
    exit(66);
  }
  if (!kanjidicFile.existsSync()) {
    stderr.writeln('KANJIDIC file not found: ${kanjidicFile.path}');
    exit(66);
  }

  stderr.writeln('Parsing MEXT data...');
  final mextData = _parseMextJs(await mextFile.readAsString());
  stderr.writeln('Found ${mextData.length} kanji in MEXT data');

  stderr.writeln('Parsing KANJIDIC2...');
  final kanjidicData = _parseKanjidic(await kanjidicFile.readAsString());
  stderr.writeln('Found ${kanjidicData.length} kanji in KANJIDIC2');

  stderr.writeln('Merging data for grades 1-6...');
  final result = _mergeData(mextData, kanjidicData);
  stderr.writeln('Generated ${result.length} kanji entries');

  // Sort by grade, then by stroke count, then by unicode codepoint
  result.sort((a, b) {
    final gradeCompare = (a['grade'] as int).compareTo(b['grade'] as int);
    if (gradeCompare != 0) return gradeCompare;
    final strokeCompare = (a['stroke_count'] as int).compareTo(b['stroke_count'] as int);
    if (strokeCompare != 0) return strokeCompare;
    return (a['kanji'] as String).codeUnitAt(0).compareTo((b['kanji'] as String).codeUnitAt(0));
  });

  await outputFile
      .writeAsString(const JsonEncoder.withIndent('  ').convert(result));
  stderr.writeln('Wrote ${outputFile.path} (${outputFile.lengthSync()} bytes)');
}

/// Parses the kabipan.com joyo_hash.js file.
/// Format: joyo={"漢":[["reading","grade"],...], ...}
Map<String, List<_MextReading>> _parseMextJs(String content) {
  // Remove 'joyo=' prefix to get JSON
  final jsonStart = content.indexOf('{');
  if (jsonStart == -1) {
    throw FormatException('Could not find JSON start in MEXT file');
  }
  final jsonStr = content.substring(jsonStart);

  final Map<String, dynamic> parsed = json.decode(jsonStr);
  final result = <String, List<_MextReading>>{};

  for (final entry in parsed.entries) {
    final kanji = entry.key;
    final readings = <_MextReading>[];

    for (final item in entry.value as List) {
      final reading = item[0] as String;
      final gradeStr = item[1] as String;
      readings.add(_MextReading(reading, gradeStr));
    }

    result[kanji] = readings;
  }

  return result;
}

/// Parses KANJIDIC2 XML to extract meanings and stroke counts.
Map<String, _KanjidicEntry> _parseKanjidic(String content) {
  final result = <String, _KanjidicEntry>{};

  // Simple regex-based parsing (faster than full XML parsing for this use case)
  final characterRegex = RegExp(r'<character>(.*?)</character>', dotAll: true);
  final literalRegex = RegExp(r'<literal>(.)</literal>');
  final gradeRegex = RegExp(r'<grade>(\d+)</grade>');
  final strokeRegex = RegExp(r'<stroke_count>(\d+)</stroke_count>');
  final meaningRegex = RegExp(r'<meaning>([^<]+)</meaning>');

  for (final match in characterRegex.allMatches(content)) {
    final charContent = match.group(1)!;

    final literalMatch = literalRegex.firstMatch(charContent);
    if (literalMatch == null) continue;
    final kanji = literalMatch.group(1)!;

    final gradeMatch = gradeRegex.firstMatch(charContent);
    // Only include grades 1-6 (elementary school)
    if (gradeMatch == null) continue;
    final grade = int.tryParse(gradeMatch.group(1)!);
    if (grade == null || grade < 1 || grade > 6) continue;

    final strokeMatch = strokeRegex.firstMatch(charContent);
    final strokeCount = strokeMatch != null
        ? int.tryParse(strokeMatch.group(1)!) ?? 0
        : 0;

    // Get English meanings (exclude non-English by checking for m_lang attribute)
    final meanings = <String>[];
    for (final m in meaningRegex.allMatches(charContent)) {
      // Only include if not preceded by m_lang (which indicates non-English)
      final start = m.start;
      final preceding = charContent.substring(
          start > 20 ? start - 20 : 0, start);
      if (!preceding.contains('m_lang=')) {
        meanings.add(m.group(1)!);
      }
    }

    result[kanji] = _KanjidicEntry(
      grade: grade,
      strokeCount: strokeCount,
      meanings: meanings,
    );
  }

  return result;
}

/// Merges MEXT readings with KANJIDIC2 metadata.
List<Map<String, dynamic>> _mergeData(
  Map<String, List<_MextReading>> mextData,
  Map<String, _KanjidicEntry> kanjidicData,
) {
  final result = <Map<String, dynamic>>[];

  for (final entry in kanjidicData.entries) {
    final kanji = entry.key;
    final kanjidic = entry.value;

    final mextReadings = mextData[kanji];
    if (mextReadings == null) {
      stderr.writeln('Warning: No MEXT data for $kanji (grade ${kanjidic.grade})');
      continue;
    }

    // Filter readings to only include those taught at or before this grade
    final gradeAppropriateReadings = mextReadings
        .where((r) => r.isElementaryGrade && r.numericGrade <= kanjidic.grade)
        .map((r) => _normalizeReading(r.reading))
        .toSet() // Remove duplicates
        .toList();

    if (gradeAppropriateReadings.isEmpty) {
      stderr.writeln('Warning: No grade-appropriate readings for $kanji (grade ${kanjidic.grade})');
      // Fall back to all elementary readings
      final allElementaryReadings = mextReadings
          .where((r) => r.isElementaryGrade)
          .map((r) => _normalizeReading(r.reading))
          .toSet()
          .toList();
      if (allElementaryReadings.isEmpty) continue;
      gradeAppropriateReadings.addAll(allElementaryReadings);
    }

    result.add({
      'kanji': kanji,
      'readings': gradeAppropriateReadings,
      'meaning': kanjidic.meanings.isNotEmpty ? kanjidic.meanings.first : '',
      'grade': kanjidic.grade,
      'stroke_count': kanjidic.strokeCount,
    });
  }

  return result;
}

/// Normalizes a reading:
/// - Converts katakana to hiragana
/// - Removes okurigana markers (e.g., "ひと-つ" → "ひとつ")
/// - Handles special notation like "あめ（さめ）"
String _normalizeReading(String reading) {
  // Remove okurigana marker
  var normalized = reading.replaceAll('-', '');

  // Remove parenthetical alternatives like "あめ（さめ）" → "あめ"
  normalized = normalized.replaceAll(RegExp(r'（[^）]*）'), '');
  normalized = normalized.replaceAll(RegExp(r'\([^)]*\)'), '');

  // Convert katakana to hiragana
  normalized = _katakanaToHiragana(normalized);

  return normalized.trim();
}

/// Converts katakana to hiragana.
String _katakanaToHiragana(String text) {
  final buffer = StringBuffer();
  for (final codeUnit in text.codeUnits) {
    // Katakana range: U+30A1 to U+30F6
    // Hiragana range: U+3041 to U+3096
    // Offset: 0x60
    if (codeUnit >= 0x30A1 && codeUnit <= 0x30F6) {
      buffer.writeCharCode(codeUnit - 0x60);
    } else {
      buffer.writeCharCode(codeUnit);
    }
  }
  return buffer.toString();
}

class _MextReading {
  final String reading;
  final String gradeStr;

  _MextReading(this.reading, this.gradeStr);

  bool get isElementaryGrade {
    final grade = int.tryParse(gradeStr);
    return grade != null && grade >= 1 && grade <= 6;
  }

  int get numericGrade {
    return int.tryParse(gradeStr) ?? 99;
  }
}

class _KanjidicEntry {
  final int grade;
  final int strokeCount;
  final List<String> meanings;

  _KanjidicEntry({
    required this.grade,
    required this.strokeCount,
    required this.meanings,
  });
}
