# Task 001: Initial Implementation

## Description
Build a kanji learning game app for iOS/Android using Flutter based on the specification in `kanji-game.md`.

## Requirements
- Framework: Flutter (iOS/Android)
- 10 stages with branching paths
- Kanji questions: reading (multiple choice) + writing (canvas drawing)
- Action-timing battle system (Attack/Shield/Jump)
- Coin system with shop (weapons, costumes, decorations)
- Grade 1-6 kanji (~130 characters)
- Persistent storage with Hive

## Completed
- [x] Flutter project setup with dependencies
- [x] Data models (Kanji, Player, Stage, Battle, ShopItem)
- [x] State management with Riverpod
- [x] Home screen with navigation
- [x] Stage select screen (10 stages grid)
- [x] Stage screen (forest door theme, branching paths)
- [x] Question screen (reading choices + writing canvas)
- [x] Battle screen (action timing controls, HP bars)
- [x] Shop screen (weapons, costumes, decorations)
- [x] Victory/Defeat result screens
- [x] Kanji data JSON (Grade 1-6)
- [x] Hive persistence for player progress

## Tech Stack
- Flutter 3.32.4
- flutter_riverpod ^2.4.9
- hive_flutter ^1.1.0
- audioplayers ^5.2.1
- google_fonts ^6.1.0
