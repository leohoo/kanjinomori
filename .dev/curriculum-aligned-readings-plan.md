# Plan: Curriculum-Aligned Kanji Readings

## Problem

Current app issues:
1. **Always uses first reading** - `kanji.readings.first` is arbitrary
2. **No curriculum filtering** - may include readings not taught at the student's grade level
3. **Writing questions don't show all readings** - students need to see what they're learning

## Solution

Use MEXT curriculum data to ensure readings match what students are actually taught at each grade level.

## Scope

- **Automate kanji.json generation**: Create reproducible script
- **Writing questions**: Show ALL grade-appropriate readings (音読み + 訓読み) as hint
- **Reading questions**: Pick ONE correct answer randomly from grade-appropriate readings
- **No model changes**: Keep existing `List<String> readings` field
- **No UI changes**: Just improve data quality and question logic

## Implementation Steps

### Step 1: Create Data Conversion Tool
Create `tool/mext_to_kanji_json.dart`:
- Download and parse kabipan.com JS data (derived from MEXT PDF)
- Filter to grade 1-6 (教育漢字) readings only
- Extract:
  - Readings with grade levels
  - Convert katakana to hiragana
  - Strip okurigana markers (e.g., "ひと-つ" → "ひとつ")
- Merge with existing kanji.json for meanings and stroke counts
- Output updated `kanji.json`

### Step 2: Update Question Generation
Modify `lib/providers/kanji_provider.dart`:
- **Reading questions**: Pick random reading instead of `.first`
- **Writing questions**: Already shows meaning, could show readings too (optional)

### Step 3: Update Fallback Data
Update `_getSampleKanji()` in `kanji_provider.dart` to match new data.

## File Changes

| File | Change |
|------|--------|
| `tool/mext_to_kanji_json.dart` | New - data conversion script |
| `assets/data/kanji.json` | Regenerate with curriculum-aligned readings |
| `lib/providers/kanji_provider.dart` | Random reading selection |

## Data Sources

### Primary: MEXT Official Curriculum (文部科学省)

The authoritative source for curriculum-aligned readings.

**Official PDF:**
- **URL**: https://www.mext.go.jp/a_menu/shotou/new-cs/1385768.htm
- **Direct PDF**: https://www.mext.go.jp/a_menu/shotou/new-cs/__icsFiles/afieldfile/2017/05/15/1385768.pdf
- **Document**: 音訓の小・中・高等学校段階別割り振り表 (平成29年3月)
- **Content**: Official readings required at each school level (小学校・中学校・高等学校)
- **Updated**: March 2017, aligned with 2020 curriculum

**Machine-readable version (derived from PDF):**
- **URL**: https://www.kabipan.com/language/japanese/haitou/joyo_hash20220315.js
- **Source site**: https://www.kabipan.com/language/japanese/onkun.html
- **Format**: JavaScript hash object
- **Structure**: `{ "漢字": [["reading", "grade"], ...], ... }`
  - Grade values: "1"-"6" (elementary), "中" (middle school), "高" (high school)
  - On'yomi in katakana, kun'yomi in hiragana with okurigana markers (e.g., "ひと-つ")
- **Updated**: March 2022
- **Note**: This is a third-party extraction of the official MEXT data

### Secondary: KANJIDIC2

Required for fields not available in MEXT data:
- **URL**: https://www.edrdg.org/kanjidic/kanjidic2.xml.gz
- **License**: Creative Commons Attribution-ShareAlike 4.0
- **Provides**: English meanings, stroke counts
- **Attribution**: Already credited in app (see `.dev/data/kanji-data-sources.md`)
