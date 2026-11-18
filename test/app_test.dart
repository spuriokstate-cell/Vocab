import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_ishtika/main.dart';
import 'package:vocab_ishtika/models/activity.dart';
import 'package:vocab_ishtika/screens/flashcards/flashcards_screen.dart';
import 'package:vocab_ishtika/screens/lessons/lesson_screen.dart';
import 'package:vocab_ishtika/screens/session/session_runner.dart';
import 'package:vocab_ishtika/services/speech_service.dart';
import 'package:vocab_ishtika/widgets/common.dart';

import 'helpers.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // Let delayed saves and snack bars finish so no timers are left running.
  await tester.pump(const Duration(seconds: 5));
}

void main() {
  testWidgets('Home screen shows every learning button and grade progress', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    await tester.pumpWidget(VocabIshtikaApp(state: app));
    await tester.pumpAndSettle();
    for (final id in const [
      'grade1', 'grade2', 'flipwrite', 'fillblanks', 'flashcards', 'spelling',
      'listening', 'daily', 'achievements', 'parents', 'wordgames',
    ]) {
      expect(_key('home-$id'), findsOneWidget, reason: id);
    }
    expect(find.text('Vocab Ishtika'), findsOneWidget);
    expect(find.textContaining('0/339 learned'), findsOneWidget);
    expect(find.textContaining('0/826 learned'), findsOneWidget);
  });

  testWidgets('Parent dashboard is behind a parent gate', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    await tester.pumpWidget(VocabIshtikaApp(state: app));
    await tester.pumpAndSettle();
    await tester.tap(_key('home-parents'));
    await tester.pumpAndSettle();

    // Wrong answer keeps the gate closed.
    await tester.enterText(_key('gate-answer'), '1');
    await tester.tap(_key('gate-enter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Parent Dashboard'), findsNothing);

    // Right answer opens the dashboard.
    final q = tester.widget<Text>(_key('gate-question')).data!;
    final nums = RegExp(r'\d+').allMatches(q).map((m) => int.parse(m.group(0)!)).toList();
    await tester.enterText(_key('gate-answer'), '${nums[0] * nums[1]}');
    await tester.tap(_key('gate-enter'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Parent Dashboard'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Grade completion'), findsOneWidget);
  });

  testWidgets('Grade map: lesson 2 is locked until lesson 1 is passed', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    await tester.pumpWidget(VocabIshtikaApp(state: app));
    await tester.pumpAndSettle();
    await tester.tap(_key('home-grade1'));
    await tester.pumpAndSettle();
    expect(find.text('Grade 1 Adventure'), findsOneWidget);
    await tester.tap(_key('map-lesson-2'));
    await tester.pump();
    expect(find.textContaining('Pass Lesson 1'), findsOneWidget);
    await _settle(tester);

    await tester.tap(_key('map-lesson-1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Lesson 1'), findsWidgets);
    expect(_key('lesson-step-1'), findsOneWidget);
    expect(_key('lesson-step-5'), findsOneWidget);
  });

  testWidgets('Lesson step 1 (Learn) goes through every word and is marked done', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final lesson = app.vocab.lessons(1).first;
    await tester.pumpWidget(appWith(app, LessonScreen(lesson: lesson)));
    await tester.pumpAndSettle();
    await tester.tap(_key('lesson-step-1'));
    await tester.pumpAndSettle();
    for (var i = 0; i < lesson.words.length; i++) {
      expect(find.text(lesson.words[i].word), findsWidgets);
      await tester.tap(_key('learn-next'));
      await tester.pumpAndSettle();
    }
    expect(app.lessonProgress(lesson).stepsDone, contains(1));
    await _settle(tester);
  });

  testWidgets('A session saves answers and celebrates at the end', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final words = app.vocab.lessons(1).first.words.take(2).toList();
    SessionSummary? result;
    await tester.pumpWidget(appWith(
      app,
      Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            result = await SessionRunner.open(context,
                title: 'Test',
                items: [for (final w in words) ActivityItem(ActivityType.wordToMeaning, w)]);
          },
          child: const Text('start'),
        ),
      ),
    ));
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
    for (final w in words) {
      await tester.tap(_key('opt-${w.meaning}'));
      await tester.pump();
      await tester.tap(_key('choice-next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('You got 2 of 2 right'), findsOneWidget);
    await tester.tap(_key('session-done'));
    await tester.pumpAndSettle();
    expect(result!.correct, 2);
    expect(result!.score, 1.0);
    expect(app.progressOf(words.first)!.firstTry, 1);
    expect(app.profile.history.first.title, 'Test');
    await _settle(tester);
  });

  testWidgets('Flashcards: flip, then "I Know It!" saves the answer', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final words = app.vocab.all.take(2).toList();
    await tester.pumpWidget(appWith(app, FlashcardsScreen(words: words)));
    await tester.pumpAndSettle();
    expect(find.text(words[0].word), findsOneWidget);
    await tester.tap(_key('flash-flip'));
    await tester.pumpAndSettle();
    expect(find.text(words[0].meaning), findsOneWidget);
    await tester.tap(_key('flash-known'));
    await tester.pumpAndSettle();
    await tester.tap(_key('flash-flip'));
    await tester.pumpAndSettle();
    await tester.tap(_key('flash-practice'));
    await tester.pumpAndSettle();
    expect(find.text('All done!'), findsOneWidget);
    expect(app.progressOf(words[0])!.knownFlashcard, isTrue);
    expect(app.progressOf(words[1])!.lastResultCorrect, isFalse);
    await _settle(tester);
  });

  testWidgets('Speaker buttons read aloud, and the mute setting silences them', (tester) async {
    final app = await makeState();
    final speech = app.speech as SilentSpeechService;
    await tester.pumpWidget(wrap(app, const SpeakButton(text: 'hello there')));
    await tester.tap(find.byType(SpeakButton));
    await tester.pump();
    expect(speech.spoken.last, 'hello there');
    app.updateSettings((s) => s.sound = false);
    speech.spoken.clear();
    await tester.tap(find.byType(SpeakButton));
    await tester.pump();
    expect(speech.spoken, isEmpty);
    await _settle(tester);
  });

  for (final size in const [Size(390, 844), Size(820, 1180), Size(1440, 900)]) {
    testWidgets('Home screen fits a ${size.width.toInt()}x${size.height.toInt()} screen', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final app = await makeState();
      await tester.pumpWidget(VocabIshtikaApp(state: app));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_key('home-grade1'), findsOneWidget);
    });
  }
}
