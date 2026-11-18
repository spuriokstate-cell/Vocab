import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_ishtika/models/activity.dart';
import 'package:vocab_ishtika/screens/flip_write/flip_write_question.dart';
import 'package:vocab_ishtika/services/speech_service.dart';

import 'helpers.dart';

Finder _key(String k) => find.byKey(ValueKey(k));

void main() {
  testWidgets('Look → Flip → Write → Check → Meaning (full flow)', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final cat = entryByWord(app.vocab.all, 'cat');
    ItemOutcome? outcome;
    await tester.pumpWidget(wrap(
        app, FlipWriteQuestion(entry: cat, mode: FlipWriteMode.look, onDone: (o) => outcome = o)));
    await tester.pump();

    // Stage 1: the word is visible before flipping.
    expect(_key('study-word'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);
    expect(find.text('Look carefully and remember this word!'), findsOneWidget);
    expect(_key('write-box'), findsNothing, reason: 'no writing while the word is shown');

    // Stage 2: flip. The word disappears completely and the box appears.
    await tester.tap(_key('flip-button'));
    await tester.pump(const Duration(seconds: 1));
    expect(_key('study-word'), findsNothing);
    expect(find.text('cat'), findsNothing);
    expect(find.text('Can you remember the word?\nWrite it below!'), findsOneWidget);
    expect(_key('write-box'), findsOneWidget);

    // Stage 3/4: a wrong spelling is rejected, the answer is not revealed.
    await tester.enterText(_key('write-box'), 'kat');
    await tester.tap(_key('check-button'));
    await tester.pump();
    expect(find.textContaining("Good try! Let's try again!"), findsOneWidget);
    expect(find.text('cat'), findsNothing);

    // Hint 1: first letter. Hint 2: number of letters.
    await tester.tap(_key('hint-button'));
    await tester.pump();
    expect(find.textContaining('It starts with "c"'), findsOneWidget);
    await tester.tap(_key('hint-button'));
    await tester.pump();
    expect(find.textContaining('It has 3 letters'), findsOneWidget);

    // Correct (different case and spaces are fine).
    await tester.enterText(_key('write-box'), '  CAT ');
    await tester.tap(_key('check-button'));
    await tester.pump();
    expect(find.textContaining('Excellent! You remembered the word!'), findsOneWidget);
    expect(_key('correct-word'), findsOneWidget);

    // Stage 5: meaning and example sentence from the PDF.
    await tester.tap(_key('next-button'));
    await tester.pump();
    expect(find.text(cat.meaning), findsOneWidget);
    expect(find.text(cat.example), findsOneWidget);

    // Result is reported for saving.
    await tester.tap(_key('continue-button'));
    await tester.pump();
    expect(outcome, isNotNull);
    expect(outcome!.correct, isTrue);
    expect(outcome!.attempts, 2);
    expect(outcome!.hintsUsed, 2);
    expect(outcome!.firstTry, isFalse);
  });

  testWidgets('right on the first try counts as first try', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final e = entryByWord(app.vocab.all, 'beautiful');
    ItemOutcome? outcome;
    await tester.pumpWidget(
        wrap(app, FlipWriteQuestion(entry: e, mode: FlipWriteMode.look, onDone: (o) => outcome = o)));
    await tester.pump();
    await tester.tap(find.text('beautiful')); // tapping the card flips it too
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('beautiful'), findsNothing);
    await tester.enterText(_key('write-box'), 'beautiful');
    await tester.testTextInput.receiveAction(TextInputAction.done); // Enter key / keyboard Done
    await tester.pump();
    expect(find.textContaining('Excellent!'), findsOneWidget);
    await tester.tap(_key('next-button'));
    await tester.pump();
    await tester.tap(_key('continue-button'));
    await tester.pump();
    expect(outcome!.firstTry, isTrue);
  });

  testWidgets('contractions must include the apostrophe', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final e = entryByWord(app.vocab.all, "can't");
    await tester.pumpWidget(
        wrap(app, FlipWriteQuestion(entry: e, mode: FlipWriteMode.look, onDone: (_) {})));
    await tester.pump();
    await tester.tap(_key('flip-button'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(_key('write-box'), 'cant');
    await tester.tap(_key('check-button'));
    await tester.pump();
    expect(find.textContaining('Good try'), findsOneWidget);
    await tester.enterText(_key('write-box'), 'can’t'); // curly apostrophe from iPad
    await tester.tap(_key('check-button'));
    await tester.pump();
    expect(find.textContaining('Excellent!'), findsOneWidget);
  });

  testWidgets('Show Word Again flips back to the word and counts as a hint', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final e = entryByWord(app.vocab.all, 'dog');
    ItemOutcome? outcome;
    await tester.pumpWidget(
        wrap(app, FlipWriteQuestion(entry: e, mode: FlipWriteMode.look, onDone: (o) => outcome = o)));
    await tester.pump();
    await tester.tap(_key('flip-button'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(_key('show-again-button'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('dog'), findsOneWidget);
    expect(_key('write-box'), findsNothing);
    await tester.tap(_key('flip-button'));
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(_key('write-box'), 'dog');
    await tester.tap(_key('check-button'));
    await tester.pump();
    await tester.tap(_key('next-button'));
    await tester.pump();
    await tester.tap(_key('continue-button'));
    await tester.pump();
    expect(outcome!.hintsUsed, 1);
    expect(outcome!.firstTry, isFalse);
  });

  testWidgets('Listen & Write never shows the word, only says it', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    final e = entryByWord(app.vocab.all, 'write');
    await tester.pumpWidget(
        wrap(app, FlipWriteQuestion(entry: e, mode: FlipWriteMode.listen, onDone: (_) {})));
    await tester.pump();
    expect(find.text('write'), findsNothing);
    final spoken = (app.speech as SilentSpeechService).spoken.join(' ');
    expect(spoken, contains('write'));
    expect(spoken, contains(e.example), reason: 'sound-alike words are read in a sentence');
    await tester.tap(_key('flip-button'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Write the word you heard!'), findsOneWidget);
  });

  testWidgets('Memory Challenge flips the card by itself', (tester) async {
    useTallScreen(tester);
    final app = await makeState();
    app.settings.memorySeconds = 3;
    final e = entryByWord(app.vocab.all, 'sun');
    await tester.pumpWidget(
        wrap(app, FlipWriteQuestion(entry: e, mode: FlipWriteMode.memory, onDone: (_) {})));
    await tester.pump();
    expect(find.text('sun'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('sun'), findsNothing);
    expect(_key('write-box'), findsOneWidget);
  });
}
