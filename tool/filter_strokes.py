#!/usr/bin/env python3
"""
Filter KanjiVG stroke data to only include 教育漢字 (kyouiku kanji).

This reduces the stroke data from ~60MB (6702 entries) to ~8MB (1026 entries),
significantly improving web app load time.

Usage:
    python3 tool/filter_strokes.py --input <all_strokes.json>

The input file should be the full KanjiVG output from kanjivg_to_json.dart.
The script reads kanji.json to determine which kanji to include.
"""

import argparse
import json
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(
        description="Filter KanjiVG stroke data to only include 教育漢字"
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to full KanjiVG stroke data JSON (from kanjivg_to_json.dart)",
    )
    args = parser.parse_args()

    # Paths
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    kanji_json = project_root / "assets" / "data" / "kanji.json"
    output_json = project_root / "assets" / "data" / "kyouiku_strokes.json"
    input_json = Path(args.input)

    if not input_json.exists():
        print(f"Error: Input file not found: {input_json}")
        sys.exit(1)

    # Load kyouiku kanji list
    print("Loading kanji.json...")
    with open(kanji_json, "r", encoding="utf-8") as f:
        kanji_list = json.load(f)

    kyouiku_kanji = {k["kanji"] for k in kanji_list}
    print(f"Found {len(kyouiku_kanji)} 教育漢字")

    # Load full stroke data
    print(f"Loading {input_json}...")
    with open(input_json, "r", encoding="utf-8") as f:
        all_strokes = json.load(f)

    print(f"Full stroke data: {len(all_strokes)} entries")

    # Filter to only kyouiku kanji
    filtered_strokes = {k: v for k, v in all_strokes.items() if k in kyouiku_kanji}
    print(f"Filtered stroke data: {len(filtered_strokes)} entries")

    # Check for missing kanji
    missing = kyouiku_kanji - set(filtered_strokes.keys())
    if missing:
        print(f"Error: {len(missing)} kanji missing stroke data:")
        print("  " + "".join(sorted(missing)))
        sys.exit(1)

    # Write filtered data
    print(f"Writing {output_json}...")
    with open(output_json, "w", encoding="utf-8") as f:
        json.dump(filtered_strokes, f, ensure_ascii=False, separators=(",", ":"))

    # Report size
    size_mb = output_json.stat().st_size / (1024 * 1024)
    print(f"New file size: {size_mb:.1f}MB")
    print("Done!")


if __name__ == "__main__":
    main()
