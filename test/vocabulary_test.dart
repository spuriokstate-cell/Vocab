import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_ishtika/data/vocabulary_repository.dart';

import 'helpers.dart';

void main() {
  final all = loadAllEntries();
  final repo = VocabularyRepository(all);

  group('Vocabulary data (from the PDF)', () {
    test('Grade 1 has exactly 339 entries', () {
      expect(all.where((e) => e.grade == 1).length, 339);
    });

    test('Grade 2 has exactly 826 entries', () {
      expect(all.where((e) => e.grade == 2).length, 826);
    });

    test('There are exactly 1,165 entries in total', () {
      expect(all.length, 1165);
    });

    test('No missing words, meanings or examples', () {
      for (final e in all) {
        expect(e.word.trim(), isNotEmpty, reason: e.id);
        expect(e.meaning.trim(), isNotEmpty, reason: e.id);
        expect(e.example.trim(), isNotEmpty, reason: e.id);
      }
    });

    test('No duplicate ids', () {
      final ids = all.map((e) => e.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('No duplicate words', () {
      final words = all.map((e) => e.word.toLowerCase()).toList();
      expect(words.toSet().length, words.length);
    });

    test('Ids match grade and order (g1_0008 = Grade 1, word 8)', () {
      for (final e in all) {
        expect(e.id, 'g${e.grade}_${e.order.toString().padLeft(4, '0')}');
      }
    });

    test('Original order is preserved with no gaps', () {
      for (final g in const [1, 2]) {
        final orders = all.where((e) => e.grade == g).map((e) => e.order).toList();
        expect(orders, List.generate(orders.length, (i) => i + 1));
      }
    });

    test('Known entries match the PDF exactly', () {
      final cat = entryByWord(all, 'cat');
      expect(cat.id, 'g1_0008');
      expect(cat.meaning, 'A small furry pet that says "meow."');
      expect(cat.example, 'The cat drinks milk.');
      final beautiful = entryByWord(all, 'beautiful');
      expect(beautiful.grade, 2);
      expect(beautiful.example, 'The sunset is beautiful.');
      expect(entryByWord(all, "can't").meaning, 'Short for "cannot."');
    });

    test('Repository validation finds no problems', () {
      expect(repo.validate(), isEmpty);
    });
  });

  group('Lessons', () {
    test('Every word is in exactly one lesson, in the original order', () {
      for (final g in const [1, 2]) {
        final fromLessons = repo.lessons(g).expand((l) => l.words).toList();
        expect(fromLessons.map((e) => e.id).toList(),
            all.where((e) => e.grade == g).map((e) => e.id).toList());
      }
    });

    test('Lessons have 10 to 15 words', () {
      for (final g in const [1, 2]) {
        for (final l in repo.lessons(g)) {
          expect(l.words.length, inInclusiveRange(10, 15), reason: l.id);
        }
      }
    });
  });
}
