#!/usr/bin/env python3
"""
Filter KanjiVG stroke data to only include 教育漢字 (kyouiku kanji).

This reduces the stroke data from ~60MB (6702 entries) to ~9MB (1006 entries),
significantly improving web app load time.
"""

import json
import sys
from pathlib import Path

def main():
    # Paths
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    kanji_json = project_root / "assets" / "data" / "kanji.json"
    strokes_json = project_root / "assets" / "data" / "kyouiku_strokes.json"

    # Load kyouiku kanji list
    print("Loading kanji.json...")
    with open(kanji_json, "r", encoding="utf-8") as f:
        kanji_list = json.load(f)

    kyouiku_kanji = {k["kanji"] for k in kanji_list}
    print(f"Found {len(kyouiku_kanji)} 教育漢字")

    # Load stroke data
    print("Loading kyouiku_strokes.json...")
    with open(strokes_json, "r", encoding="utf-8") as f:
        strokes_data = json.load(f)

    print(f"Original stroke data: {len(strokes_data)} entries")

    # Filter to only kyouiku kanji
    filtered_strokes = {k: v for k, v in strokes_data.items() if k in kyouiku_kanji}
    print(f"Filtered stroke data: {len(filtered_strokes)} entries")

    # Check for missing kanji
    missing = kyouiku_kanji - set(filtered_strokes.keys())
    if missing:
        print(f"Warning: {len(missing)} kanji missing stroke data: {missing}")

    # Write filtered data
    print("Writing filtered kyouiku_strokes.json...")
    with open(strokes_json, "w", encoding="utf-8") as f:
        json.dump(filtered_strokes, f, ensure_ascii=False, separators=(",", ":"))

    # Report size
    size_mb = strokes_json.stat().st_size / (1024 * 1024)
    print(f"New file size: {size_mb:.1f}MB")
    print("Done!")

if __name__ == "__main__":
    main()
