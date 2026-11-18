# Test Report

**Status: first run on a Mac with Flutter 3.50, on 2026-11-17.**

| Command | Result |
|---|---|
| `flutter analyze` | ✅ No errors or warnings. 26 "info" notes: 25 say Flutter 3.47+ prefers `package:material_ui` over `package:flutter/material.dart` (harmless, left as is), and 1 style tip (fixed). |
| `flutter test` | ✅ **All 78 tests passed** (after fixing one test whose threshold was set too high: it expected tricky words in 40% of sessions, but the correct rate is about 30%, against 12.5% without weighting). |
| `flutter run` (Android emulator, API 37) | ✅ Built, installed and started; the text-to-speech engine connected. |
| `flutter test integration_test` | Not run yet. |
| iPhone/iPad, Windows | Not run yet. |

To run the checks again:

```bash
bash tool/setup.sh
flutter analyze
flutter test
flutter test integration_test      # with an emulator or device running
```

Paste any errors back to Claude to have them fixed.

## What WAS run

| Check | Tool | Result |
|---|---|---|
| Vocabulary extraction and validation (counts, ids, order, empty fields, duplicates) | `python3 tool/validate_vocabulary.py` | ✅ 9/9 checks pass: 339 + 826 = 1,165 |
| Fill-in-the-blank question generation for every word (a Python copy of the Dart engine, several random seeds) | simulation script | ✅ All 1,148 eligible words produce 4 choices with exactly one answer; 17 flagged words are excluded |
| Setup script logic (Android manifest, iOS Info.plist, Windows title patches) | run against sample files | ✅ |
| Every Dart import resolves; brackets balanced in every file | static scan | ✅ |

## Automated tests written (Dart)

| File | Covers |
|---|---|
| `test/vocabulary_test.dart` | 339 / 826 / 1,165 entries; no missing words, meanings or examples; unique ids and words; id format; original order; known entries match the PDF; lessons contain every word in order with 10–15 words each |
| `test/answer_checking_test.dart` | Case and spaces ignored; missing, extra and swapped letters rejected; empty rejected; contractions need the apostrophe; curly apostrophes accepted; whole-word matching (no partial words, possessives OK, contractions and plurals not matched) |
| `test/question_engine_test.dart` | Every eligible word makes a valid question; the target word is removed and punctuation preserved; exactly 1 of 4 choices correct; no sound-alikes or same-family distractors; the "red" example; the 17 invalid entries are excluded and reported; meaning, listening, scramble and picture questions |
| `test/progress_test.dart` | Spaced-repetition boxes; Needs Practice and Mastered; per-skill accuracy; save/load; tricky words picked more often; Daily Practice mix; lesson unlocking at 80%; lesson locking off; offline persistence; separate child profiles; CSV export; reset; badges |
| `test/flip_write_test.dart` | Word visible before the flip, gone after; input appears; wrong answer rejected without revealing; hints 1 and 2; correct accepted (case/spaces); meaning screen; result saved (attempts and hints); first-try path and Enter key; contractions; Show Word Again; Listen & Write never shows the word; Memory Challenge flips by itself |
| `test/fill_blank_test.dart` | Multiple choice (wrong then right); reveal after two wrong; drag-and-drop with a real drag gesture, plus tap-to-place; typed answers spell-checked with a hint; flagged entries never shown |
| `test/app_test.dart` | Home screen buttons and grade progress; parent gate (wrong and right answers); lesson locking on the map; lesson step 1 completion; a full session saved, with the celebration; flashcards saved; audio buttons and mute; layout at phone, tablet and desktop sizes |
| `integration_test/app_test.dart` | On a device: home → Look, Flip & Write → write the word → saved |

## Not covered by automated tests

- **Speech quality:** real voices differ between Android, iOS and Windows, so listen on each device.
- **Real devices:** the Windows build has not been made (that needs a Windows PC), and nothing has been run on an iPhone or iPad yet.
- **Screen readers:** TalkBack (Android), VoiceOver (iOS) and Narrator (Windows) need a quick manual check.
- **Drag and drop:** with a mouse on Windows, and with touch on a real tablet.
