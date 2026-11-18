import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_ishtika/models/activity.dart';
import 'package:vocab_ishtika/screens/fill_blanks/fill_blank_question.dart';

import 'helpers.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

Finder _wrongChoice(String prefix, String answer) => find.byWidgetPredicate((w) {
      final k = w.key;
      return k is ValueKey<String> && k.value.startsWith(prefix) && k.value != '$prefix$answer';
    });

void main() {
  testWidgets('Level 1: multiple choice, wrong then right', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final cat = entryByWord(app.vocab.all, 'cat');
    ItemOutcome? out;
    await tester.pumpWidget(wrap(app, FillBlankQuestion(entry: cat, level: 1, onDone: (o) => out = o)));
    await tester.pump();

    expect(find.text('Which word fits? 🧩'), findsOneWidget);
    expect(_key('choice-cat'), findsOneWidget);
    expect(_wrongChoice('choice-', 'cat'), findsNWidgets(3));

    await tester.tap(_wrongChoice('choice-', 'cat').first);
    await tester.pump();
    expect(find.textContaining("Nice try! Let's try again!"), findsOneWidget);

    await tester.tap(_key('choice-cat'));
    await tester.pump();
    expect(find.textContaining('Wonderful! You found the missing word!'), findsOneWidget);
    expect(find.textContaining('The cat drinks milk.'), findsWidgets);

    await tester.tap(_key('fill-next'));
    await tester.pump();
    expect(out!.correct, isTrue);
    expect(out!.attempts, 2);
  });

  testWidgets('Level 1: two wrong answers show the answer with its meaning', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final e = entryByWord(app.vocab.all, 'red');
    ItemOutcome? out;
    await tester.pumpWidget(wrap(app, FillBlankQuestion(entry: e, level: 1, onDone: (o) => out = o)));
    await tester.pump();
    await tester.tap(_wrongChoice('choice-', 'red').at(0));
    await tester.pump();
    await tester.tap(_wrongChoice('choice-', 'red').at(1));
    await tester.pump();
    expect(find.textContaining('The missing word is "red"'), findsOneWidget);
    expect(find.textContaining(e.meaning), findsOneWidget);
    await tester.tap(_key('fill-next'));
    await tester.pump();
    expect(out!.correct, isFalse);
  });

  testWidgets('Level 2: drag and drop (and tap as a keyboard-friendly option)', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final e = entryByWord(app.vocab.all, 'beautiful');
    ItemOutcome? out;
    await tester.pumpWidget(wrap(app, FillBlankQuestion(entry: e, level: 2, onDone: (o) => out = o)));
    await tester.pump();
    expect(_key('drop-blank'), findsOneWidget);

    // Tapping a wrong word is checked like dropping it.
    await tester.tap(_wrongChoice('drag-', 'beautiful').first);
    await tester.pump();
    expect(find.textContaining('Nice try'), findsOneWidget);

    // Drag the right word into the blank.
    final from = tester.getCenter(_key('drag-beautiful'));
    final to = tester.getCenter(_key('drop-blank'));
    final gesture = await tester.startGesture(from);
    await tester.pump();
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(to);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(find.textContaining('Wonderful!'), findsOneWidget);
    await tester.tap(_key('fill-next'));
    await tester.pump();
    expect(out!.correct, isTrue);
  });

  testWidgets('Level 3: typed answers are spell-checked', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final e = entryByWord(app.vocab.all, 'beautiful');
    ItemOutcome? out;
    await tester.pumpWidget(wrap(app, FillBlankQuestion(entry: e, level: 3, onDone: (o) => out = o)));
    await tester.pump();
    expect(find.text('Type the missing word ⌨️'), findsOneWidget);

    await tester.enterText(_key('write-box'), 'beutiful');
    await tester.tap(_key('fill-check'));
    await tester.pump();
    expect(find.textContaining('Nice try'), findsOneWidget);

    await tester.tap(_key('fill-hint'));
    await tester.pump();
    expect(find.textContaining('Clue: ${e.meaning}'), findsOneWidget);

    await tester.enterText(_key('write-box'), 'Beautiful');
    await tester.tap(_key('fill-check'));
    await tester.pump();
    expect(find.textContaining('Wonderful!'), findsOneWidget);
    await tester.tap(_key('fill-next'));
    await tester.pump();
    expect(out!.correct, isTrue);
    expect(out!.hintsUsed, 1);
  });

  testWidgets('A flagged entry is never shown as a question', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final e = entryByWord(app.vocab.all, 'thumb'); // "Give me a thumbs up!"
    await tester.pumpWidget(wrap(app, FillBlankQuestion(entry: e, level: 1, onDone: (_) {})));
    await tester.pump();
    expect(find.textContaining('being checked by a grown-up'), findsOneWidget);
    expect(find.textContaining('Which word fits'), findsNothing);
  });
}
