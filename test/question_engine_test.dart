import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_ishtika/core/text_utils.dart';
import 'package:vocab_ishtika/core/word_sets.dart';
import 'package:vocab_ishtika/models/activity.dart';
import 'package:vocab_ishtika/services/question_engine.dart';
import 'package:vocab_ishtika/services/session_builder.dart';

import 'helpers.dart';

void main() {
  final all = loadAllEntries();

  group('Fill in the Blanks engine', () {
    test('every word with its exact word in the sentence makes a valid question', () {
      for (final seed in const [1, 2, 3]) {
        final engine = QuestionEngine(all, random: Random(seed));
        for (final e in all.where(QuestionEngine.canBlank)) {
          final q = engine.blank(e);
          expect(q, isNotNull, reason: '${e.id} ${e.word} (seed $seed)');
        }
      }
    });

    test('the target word is removed and punctuation is preserved', () {
      final engine = QuestionEngine(all, random: Random(7));
      for (final e in all.where(QuestionEngine.canBlank)) {
        final q = engine.blank(e)!;
        final textOnly = q.parts.where((p) => !p.isBlank).map((p) => p.text).join(' ');
        expect(findWordOccurrences(e.word, textOnly), isEmpty, reason: e.id);
        // Putting the answer back gives exactly the original sentence.
        final rebuilt = q.parts.map((p) => p.isBlank ? q.answer : p.text).join();
        expect(rebuilt.toLowerCase(), e.example.toLowerCase(), reason: e.id);
        expect(q.parts.where((p) => p.isBlank), isNotEmpty);
      }
    });

    test('exactly one of the four choices is correct', () {
      final engine = QuestionEngine(all, random: Random(11));
      for (final e in all.where(QuestionEngine.canBlank)) {
        final q = engine.blank(e)!;
        expect(q.choices.length, 4, reason: e.id);
        expect(q.choices.map(normalizeAnswer).toSet().length, 4, reason: e.id);
        expect(q.choices.where(q.isCorrect).length, 1, reason: e.id);
      }
    });

    test('wrong choices are never sound-alikes or from the same word family', () {
      final engine = QuestionEngine(all, random: Random(5));
      for (final e in all.where(QuestionEngine.canBlank)) {
        final q = engine.blank(e)!;
        for (final c in q.choices.where((c) => !q.isCorrect(c))) {
          expect(soundsAlike(c, e.word), isFalse, reason: '${e.word} / $c');
          expect(easilyConfused(c, e.word), isFalse, reason: '${e.word} / $c');
          expect(findWordOccurrences(c, e.example), isEmpty, reason: '${e.word} / $c');
        }
      }
    });

    test('"My shoes are red." never offers another describing word', () {
      final red = entryByWord(all, 'red');
      for (var seed = 0; seed < 30; seed++) {
        final q = QuestionEngine(all, random: Random(seed)).blank(red)!;
        for (final c in q.choices.where((c) => c != 'red')) {
          expect(wordKinds(c).contains('A'), isFalse, reason: c);
        }
      }
    });

    test('the cat example from the brief works', () {
      final q = QuestionEngine(all, random: Random(1)).blank(entryByWord(all, 'cat'))!;
      expect(q.blankedSentence.startsWith('The _'), isTrue);
      expect(q.blankedSentence.endsWith(' drinks milk.'), isTrue);
      expect(q.isCorrect('cat'), isTrue);
      expect(q.isCorrect('Cat'), isTrue);
      expect(q.isCorrect('dog'), isFalse);
    });

    test('incorrect typed answers are rejected', () {
      final q = QuestionEngine(all, random: Random(1)).blank(entryByWord(all, 'beautiful'))!;
      expect(q.isCorrect('beutiful'), isFalse);
      expect(q.isCorrect('beautiful'), isTrue);
    });

    test('the 17 sentences without the exact word are excluded and reported', () {
      final invalid = QuestionEngine(all).invalidBlankEntries();
      expect(invalid.length, 17);
      expect(invalid.map((i) => i.entry.word), containsAll(['thumb', 'eye', 'bean']));
      for (final i in invalid) {
        expect(QuestionEngine(all).blank(i.entry), isNull);
        expect(SessionBuilder.supports(ActivityType.fillChoice, i.entry), isFalse);
      }
    });

    test('sessions never include invalid fill-in-the-blank questions', () {
      final items = SessionBuilder(random: Random(3)).single(ActivityType.fillType, all);
      expect(items.length, 1165 - 17);
      expect(items.every((i) => QuestionEngine.canBlank(i.entry)), isTrue);
    });
  });

  group('Other games', () {
    final engine = QuestionEngine(all, random: Random(9));

    test('meaning choices include the right meaning once', () {
      for (final e in all.take(200)) {
        final c = engine.meaningChoices(e);
        expect(c.length, 4);
        expect(c.where((m) => m == e.meaning).length, 1);
      }
    });

    test('listening choices never include a sound-alike', () {
      for (final w in const ['write', 'right', 'two', 'sun', 'eight', 'their']) {
        final e = all.where((x) => x.word == w);
        if (e.isEmpty) continue;
        final c = engine.listeningChoices(e.first);
        expect(c.where((x) => x == w).length, 1);
        expect(c.where((x) => x != w && soundsAlike(x, w)), isEmpty, reason: w);
      }
    });

    test('scrambled letters are a real shuffle of the word', () {
      for (final e in all.where(QuestionEngine.canScramble).take(300)) {
        final s = engine.scrambled(e);
        expect((s.toList()..sort()).join(), (e.word.split('')..sort()).join());
        expect(s.join().toLowerCase() == e.word.toLowerCase(), isFalse, reason: e.word);
      }
    });

    test('picture words only use words with a picture', () {
      final pics = engine.pictureEntries;
      expect(pics.length, greaterThan(40));
      for (final e in pics) {
        final c = engine.pictureChoices(e);
        expect(c.contains(e.word), isTrue);
        expect(c.every((w) => pictureWords.containsKey(w.toLowerCase())), isTrue);
      }
    });
  });
}
