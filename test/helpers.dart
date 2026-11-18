import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vocab_ishtika/data/profile_store.dart';
import 'package:vocab_ishtika/data/vocabulary_repository.dart';
import 'package:vocab_ishtika/models/vocab_entry.dart';
import 'package:vocab_ishtika/services/speech_service.dart';
import 'package:vocab_ishtika/state/app_state.dart';
import 'package:vocab_ishtika/theme/app_theme.dart';

/// All 1,165 words, read straight from the asset files.
List<VocabEntry> loadAllEntries() => [
      for (final g in const [1, 2])
        ...VocabularyRepository.parse(
            File('assets/vocabulary/grade$g.json').readAsStringSync()),
    ];

VocabEntry entryByWord(List<VocabEntry> all, String word) =>
    all.firstWhere((e) => e.word == word);

/// A fresh app state with empty storage, silent speech and no animations.
Future<AppState> makeState({Map<String, Object> prefs = const {}, int seed = 42}) async {
  SharedPreferences.setMockInitialValues(Map.of(prefs));
  final state = AppState(
    vocab: VocabularyRepository(loadAllEntries()),
    store: await ProfileStore.open(),
    speech: SilentSpeechService(),
    random: Random(seed),
  );
  await state.init();
  state.settings.reducedMotion = true;
  state.settings.autoRead = false;
  return state;
}

/// Puts [child] inside the app scope, theme and a scrollable page.
Widget wrap(AppState state, Widget child) => AppScope(
      state: state,
      child: MaterialApp(
        theme: buildTheme(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(900, 1600), disableAnimations: true),
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );

/// A tall test screen so every button is visible without scrolling.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// A full app around [home] (with navigation), animations turned off.
Widget appWith(AppState state, Widget home) => AppScope(
      state: state,
      child: MaterialApp(
        theme: buildTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: home,
      ),
    );
