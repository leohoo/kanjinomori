# Kanji Data Sources

This document describes how the kanji data (`assets/data/kanji.json`) was compiled.

## Overview

The game includes all **1,006 教育漢字** (Kyouiku Kanji) - the kanji taught in Japanese elementary schools (grades 1-6).

| Grade | Count |
|-------|-------|
| 1 | 80 |
| 2 | 160 |
| 3 | 200 |
| 4 | 200 |
| 5 | 185 |
| 6 | 181 |
| **Total** | **1,006** |

## Data Sources

### 1. MEXT (文部科学省) - Kanji List

**Source:** [学習指導要領「生きる力」- 別表 学年別漢字配当表](https://www.mext.go.jp/a_menu/shotou/new-cs/youryou/syo/koku/001.htm)

The official list of kanji assigned to each grade level, as defined by the Japanese Ministry of Education, Culture, Sports, Science and Technology (MEXT).

**Data extracted:**
- Kanji characters (漢字)
- Grade level (学年: 1-6)

### 2. KANJIDIC2 - Readings & Meanings

**Source:** [EDRDG KANJIDIC Project](http://www.edrdg.org/wiki/index.php/KANJIDIC_Project)

**File:** `kanjidic2.xml` (XML format, UTF-8)

KANJIDIC2 is a comprehensive kanji dictionary maintained by the Electronic Dictionary Research and Development Group (EDRDG). It contains 13,108 kanji with detailed information.

**Data extracted:**
- Readings (読み方)
  - 音読み (on'yomi) - converted from katakana to hiragana
  - 訓読み (kun'yomi) - already in hiragana
- Meanings (意味) - English translations
- Stroke count (画数)

## Data Schema

Each entry in `kanji.json`:

```json
{
  "kanji": "一",
  "readings": ["いち", "いつ", "ひと", "ひとつ"],
  "meaning": "one",
  "grade": 1,
  "stroke_count": 1
}
```

| Field | Type | Description |
|-------|------|-------------|
| `kanji` | string | The kanji character |
| `readings` | string[] | Up to 4 common readings in hiragana |
| `meaning` | string | Primary English meaning |
| `grade` | int | School grade (1-6) |
| `stroke_count` | int | Number of strokes |

## Data Retrieval Process

1. **Download KANJIDIC2:**
   ```bash
   curl -sL "http://www.edrdg.org/kanjidic/kanjidic2.xml.gz" -o kanjidic2.xml.gz
   gunzip kanjidic2.xml.gz
   ```

2. **Extract MEXT kanji list** from the official webpage

3. **Parse and merge:**
   - Filter KANJIDIC2 to only include the 1,006 MEXT kanji
   - Extract readings (ja_on, ja_kun) and convert to hiragana
   - Extract primary English meaning
   - Use MEXT grade assignments (not KANJIDIC2 grades)

4. **Output:** `assets/data/kanji.json`

## License

### KANJIDIC2
The KANJIDIC2 file is released under a [Creative Commons Attribution-ShareAlike License (V4.0)](https://creativecommons.org/licenses/by-sa/4.0/).

> Copyright: James William BREEN and The Electronic Dictionary Research and Development Group

### MEXT Data
Public government data from the Ministry of Education, Culture, Sports, Science and Technology of Japan.

## References

- EDRDG: http://www.edrdg.org/
- KANJIDIC Project: http://www.edrdg.org/wiki/index.php/KANJIDIC_Project
- MEXT 学習指導要領: https://www.mext.go.jp/a_menu/shotou/new-cs/youryou/syo/koku/001.htm
