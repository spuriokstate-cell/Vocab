# Vocab Ishtika 🦉

An offline vocabulary learning app for children in Grades 1 and 2 (ages 6–9), built with Flutter, so one codebase runs on **Android**, **iPhone and iPad**, and **Windows**.

It includes all **1,165 words** from *My Word Book* (339 Grade 1 + 826 Grade 2), each with its kid-friendly meaning and example sentence, in the original learning order.

## What's inside

| Activity | What the child does |
|---|---|
| **🃏 Look → Flip → Write → Check** | See the word, flip the card (the word disappears), write it from memory, check it, then learn the meaning. Three modes: **Look & Write**, **Listen & Write** and **Memory Challenge**. Progressive hints: first letter, then number of letters, then peek at the word. |
| **🧩 Fill in the Blanks** | The word's example sentence with the word hidden. **Easy:** tap one of 4 words. **Medium:** drag the word into the blank (tapping also works, for keyboard and screen-reader users). **Hard:** type it. |
| **📇 Flashcards** | Word on the front; meaning and sentence on the back. Then "I Know It!" or "Practice Again". |
| **🐝 Spelling Games** | Spelling Challenge (hear it, spell it) and Word Scramble. |
| **👂 Listening Games** | Listen & Choose, and Listen & Write. |
| **🎮 Word Games** | Word → Meaning, Meaning → Word, Picture → Word, and a Mixed Quiz. |
| **🗺️ Lessons** | Each grade is split into lessons of 10–15 words in the original order, shown on an adventure map. Each lesson has 5 steps: Learn → Look, Flip & Write → Fill in the Blanks → Games → Mastery Quiz. Scoring **80%** on the quiz opens the next lesson. |
| **📅 Daily Practice** | A short mixed session picked by smart review. Tricky words come back sooner, and mastered words come back now and then. |
| **🏅 Achievements** | Stars, confetti and 15 badges (First 10 Words, Spelling Star, Memory Champion, Sentence Superstar, Grade 1 Champion…). |
| **🔒 Parent Dashboard** | Behind a grown-up question. Shows progress charts, accuracy by skill, difficult words, history, settings, multiple child profiles, CSV export and reset. |

- **Everything works offline.** Words, progress, audio (the device's own voice) and rewards all work without internet, and there's no account or sign-up.
- **Mascot:** Ishi the owl, an original character drawn in code.

## Download the app

Ready-to-install files are on the **[Releases page](https://github.com/spuriokstate-cell/Vocab/releases/latest)**:

| Device | File | How to install |
|---|---|---|
| Android | `VocabIshtika-Android.apk` | Open it on the phone or tablet and allow "Install unknown apps". |
| Windows | `VocabIshtika-Windows.zip` | Unzip, then run `vocab_ishtika.exe` (SmartScreen: **More info → Run anyway**). |
| Mac | `VocabIshtika-macOS.zip` | Unzip, then **right-click → Open** the first time. |
| iPhone/iPad | see below | Apple requires apps to be signed, so install from a Mac with Xcode. |

GitHub builds these files automatically (`.github/workflows/build.yml`) whenever the app code or vocabulary changes, which takes about 15–25 minutes. You can also start a build yourself: repository **Actions** tab → **Build apps** → **Run workflow**.

### Install on an iPhone or iPad

1. Connect the iPhone or iPad to your Mac with a cable and tap **Trust** on the device.
2. On the device, turn on **Settings → Privacy & Security → Developer Mode** (it restarts).
3. On the Mac, in the project folder, run `open ios/Runner.xcworkspace`. In Xcode, click **Runner** → **Signing & Capabilities** → **Team**, and choose your Apple ID (add it under **Xcode → Settings → Accounts**).
4. Back in the Terminal, run `flutter run --release` and pick the iPhone or iPad.
5. The first time, on the device go to **Settings → General → VPN & Device Management** and **trust** your Apple ID.

With a free Apple ID the app works for 7 days, after which you run step 4 again. A paid Apple Developer account ($99/year) removes that limit and lets you use TestFlight or the App Store.

## Install Flutter (one time)

**Mac** (for Android, iPhone and iPad):
```bash
brew install --cask flutter
brew install cocoapods          # needed for iPhone/iPad
flutter doctor                  # fix anything marked ✗
```
You also need Android Studio (with the Flutter plugin) and Xcode from the App Store.

**Windows PC** (for the Windows app, and Android): install Flutter from https://docs.flutter.dev/get-started/install/windows, plus **Visual Studio 2022** with the *"Desktop development with C++"* workload. Then run `flutter doctor`.

> Windows apps can only be built on a Windows PC, and iPhone/iPad apps only on a Mac. Android can be built on either.

## Get the app running

```bash
git clone https://github.com/spuriokstate-cell/Vocab.git vocab_ishtika
cd vocab_ishtika
bash tool/setup.sh                 # Mac  (Windows: powershell -ExecutionPolicy Bypass -File tool\setup.ps1)
flutter analyze                    # check the code
flutter test                       # run the automated tests
flutter run                        # start on an emulator, phone or tablet
flutter run -d windows             # (on a Windows PC)
```

The setup script creates the `android/`, `ios/` and `windows/` folders, sets the app name to **Vocab Ishtika**, allows the text-to-speech voice on Android 11+, and lets parents find exported CSV files in the iPhone/iPad Files app.

## Adding or editing vocabulary later

The words live in two files:

- `assets/vocabulary/grade1.json`
- `assets/vocabulary/grade2.json`

Each entry looks like this:

```json
{
  "id": "g1_0008",
  "grade": 1,
  "order": 8,
  "word": "cat",
  "meaning": "A small furry pet that says \"meow.\"",
  "example": "The cat drinks milk."
}
```

1. Edit the meaning or example, or add a new entry at the end of a grade with the next `order` number and a matching `id` (`g2_0827`, …).
2. For **Fill in the Blanks**, the example sentence must contain the **exact** word (not a plural like "thumbs" for "thumb").
3. Run the checker. It writes `docs/VOCABULARY_VALIDATION_REPORT.md` and `docs/VOCABULARY_REVIEW_FLAGS.md`:
   ```bash
   python3 tool/validate_vocabulary.py
   ```
4. If you changed the number of words, update the expected counts in `tool/validate_vocabulary.py`, `lib/data/vocabulary_repository.dart` and `test/vocabulary_test.dart`.
5. Run `flutter test`, then rebuild the app.

Children's progress is stored by word `id`, so editing a meaning never loses progress.

To re-extract everything from the PDF:
`pdftotext -raw latest_Vocab_Meanings_Grade1_Grade2.pdf raw.txt && python3 tool/extract_pdf.py raw.txt extracted.json`

## Reports

- `docs/VOCABULARY_VALIDATION_REPORT.md`: counts, ids, order and duplicates. All checks pass.
- `docs/VOCABULARY_REVIEW_FLAGS.md`: **17 example sentences that need your decision**, with suggested replacements.
- `docs/TEST_REPORT.md`: what is tested, and what has and hasn't been run.
- `docs/RELEASE.md`: building for Google Play, the App Store and Windows.
- `docs/PRIVACY_AND_STORES.md`: children's privacy design and the store checklist.

## Project layout

```text
lib/
  core/        answer checking, word matching, word families (homophones, pictures)
  models/      vocabulary entries, lessons, progress, profiles, settings
  data/        vocabulary loading and lesson splitting, local storage
  services/    question engine, spaced repetition, achievements, speech, session builder
  state/       AppState (the whole app's state) and AppScope
  theme/       colors and styles
  widgets/     mascot, flip card, writing box, letter tiles, confetti, buttons
  screens/     home, grades (map), lessons, flip_write, fill_blanks, flashcards,
               games, session runner, practice, achievements, parents
assets/vocabulary/   grade1.json, grade2.json (from the PDF)
test/                unit and widget tests
integration_test/    on-device test
tool/                setup scripts, PDF extractor, vocabulary validator
```

**Dependencies:** `flutter_tts` (offline speech), `shared_preferences` (local storage) and `path_provider` (CSV export). Charts, confetti and the mascot are drawn with plain Flutter, with no extra packages.
