# Stroke Data Optimization

## Problem

The original KanjiVG stroke data contained 6,702 kanji entries, resulting in a **60MB** file. This caused:

- Slow initial web app load times
- Excessive bandwidth usage
- Poor user experience on mobile/slow connections

## Solution

Filter the stroke data to only include the **1,006 教育漢字** (kyouiku kanji) that the app actually uses.

### Results

| Metric | Before | After | Reduction |
|--------|--------|-------|-----------|
| Entries | 6,702 | 1,006 | 85% |
| File size | 60MB | 4MB | 93% |

## How to Regenerate

If you need to regenerate the filtered stroke data:

```bash
# Ensure you have the full KanjiVG stroke data first
# Then run the filter script:
python3 tool/filter_strokes.py
```

## Files

- `tool/filter_strokes.py` - Script to filter stroke data
- `tool/kanjivg_to_json.dart` - Original converter from KanjiVG XML
- `assets/data/kyouiku_strokes.json` - Filtered stroke data (LFS)

## Future Considerations

If the app expands beyond 教育漢字:

1. **Lazy loading by grade** - Split into `strokes/grade1.json`, etc.
2. **On-demand loading** - Fetch individual kanji stroke data as needed
3. **Binary format** - Convert to more compact binary representation
