# Proposal: Add Kanken Level Data Source

## Overview

Add support for 漢検 (Kanji Kentei / Japanese Kanji Aptitude Test) level categorization as an additional data source alongside the existing MEXT grade-based system.

## Data Source

**URL:** https://kanjitisiki.com/kanken/

This website provides kanji lists organized by 漢検 levels (10級 through 1級).

## Motivation

- **Alternative progression system:** 漢検 levels provide another way to categorize and progress through kanji learning
- **Test preparation:** Many learners study for 漢検 certification, so having level-based filtering would be useful
- **Cross-reference:** Can validate and supplement existing MEXT grade data

## Kanken Levels Overview

Note: Kanken uses **cumulative** kanji counts (total kanji up to and including that level).

| Level | School Level | Cumulative Total | New at Level |
|-------|--------------|------------------|--------------|
| 10級  | Grade 1      | 80               | 80           |
| 9級   | Grade 2      | 240              | 160          |
| 8級   | Grade 3      | 440              | 200          |
| 7級   | Grade 4      | 640              | 200          |
| 6級   | Grade 5      | 825              | 185          |
| 5級   | Grade 6      | 1,006            | 181          |
| 4級   | Junior High  | 1,322            | 316          |
| 3級   | Junior High  | 1,607            | 285          |
| 準2級 | High School  | 1,940            | 333          |
| 2級   | High School+ | 2,136            | 196          |
| 準1級 | Advanced     | ~3,000           | ~864         |
| 1級   | Advanced     | ~6,000           | ~3,000       |

## Potential Features

1. **Kanken level field** - Add `kanken_level` to kanji data model
2. **Level-based filtering** - Allow users to practice by 漢検 level
3. **Dual progression** - Track progress by both school grade and 漢検 level
4. **Extended kanji support** - Could expand beyond 教育漢字 to include 常用漢字 and beyond

## Implementation Considerations

- Need to verify data accuracy against official 漢検 specifications
- Consider scraping vs manual data entry
- Respect website terms of service
- May need to cross-reference with existing MEXT data

## Status

**Draft** - Idea documentation only. Implementation pending.

## References

- https://kanjitisiki.com/kanken/
- Official 漢検: https://www.kanken.or.jp/
