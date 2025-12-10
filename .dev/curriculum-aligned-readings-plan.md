# Plan: Integrate KANJIDIC2 Data for Improved Kanji Data

## Problem

Current app issues:
1. **Always uses first reading** - `kanji.readings.first` is arbitrary
2. **No Jouyou-approved filtering** - may include non-standard readings
3. **Writing questions don't show all readings** - students need to see what they're learning

## Solution

Use KANJIDIC2 (CC BY-SA 4.0) to provide accurate reading data. Keep scope minimal.

## Scope

- **Automate kanji.json generation**: Create reproducible script (currently manually compiled)
- **Writing questions**: Show ALL readings (音読み + 訓読み) as hint
- **Reading questions**: Pick ONE correct answer randomly from all readings
- **No model changes**: Keep existing `List<String> readings` field
- **No UI changes**: Just improve data quality and question logic

## Implementation Steps

### Step 1: Create Data Conversion Tool
Create `tool/kanjidic2_to_json.dart`:
- Document how to download KANJIDIC2 XML (similar to kanjivg_to_json.dart)
- Parse KANJIDIC2 XML
- Filter to grade 1-6 (教育漢字) only
- Extract:
  - `ja_on` readings → convert katakana to hiragana
  - `ja_kun` readings → strip okurigana (remove "." and after)
  - Combine into single `readings` list (on first, then kun)
  - English meanings
  - Grade, stroke count
- Output as `kanji.json` (same format as current)
- This replaces the current manual process documented in `.dev/data/kanji-data-sources.md`

### Step 2: Update Question Generation
Modify `lib/providers/kanji_provider.dart`:
- **Reading questions**: Pick random reading instead of `.first`
- **Writing questions**: Already shows meaning, could show readings too (optional)

### Step 3: Update Fallback Data
Update `_getSampleKanji()` in `kanji_provider.dart` to match new data.

## File Changes

| File | Change |
|------|--------|
| `tool/kanjidic2_to_json.dart` | New - data conversion script |
| `assets/data/kanji.json` | Regenerate with KANJIDIC2 data |
| `lib/providers/kanji_provider.dart` | Random reading selection |

## Data Sources

### Primary: MEXT Official Curriculum (文部科学省)
- **URL**: https://www.mext.go.jp/a_menu/shotou/new-cs/1385768.htm
- **Document**: 音訓の小・中・高等学校段階別割り振り表 (PDF)
- **Content**: Official readings required at each school level (小学校・中学校・高等学校)
- **Updated**: March 2017, aligned with 2020 curriculum
- **This is the authoritative source for curriculum-aligned readings**

### Secondary: KANJIDIC2
- **URL**: https://www.edrdg.org/kanjidic/kanjidic2.xml.gz
- **License**: Creative Commons Attribution-ShareAlike 4.0
- **Use**: Supplement for stroke count, meanings, additional metadata
- **Attribution**: Add to app credits/about screen
