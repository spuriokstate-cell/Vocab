import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_ishtika/core/text_utils.dart';

void main() {
  group('answerMatches', () {
    test('accepts the exact word', () {
      expect(answerMatches('beautiful', 'beautiful'), isTrue);
    });

    test('ignores upper/lower case and outer spaces', () {
      expect(answerMatches('  Beautiful ', 'beautiful'), isTrue);
      expect(answerMatches('CAT', 'cat'), isTrue);
      expect(answerMatches('i', 'I'), isTrue);
    });

    test('rejects missing letters', () {
      expect(answerMatches('beautful', 'beautiful'), isFalse);
    });

    test('rejects extra letters', () {
      expect(answerMatches('beautifull', 'beautiful'), isFalse);
    });

    test('rejects wrong letter order', () {
      expect(answerMatches('beuatiful', 'beautiful'), isFalse);
      expect(answerMatches('tac', 'cat'), isFalse);
    });

    test('rejects an empty answer', () {
      expect(answerMatches('   ', 'cat'), isFalse);
    });

    test('contractions need their apostrophe', () {
      expect(answerMatches('cant', "can't"), isFalse);
      expect(answerMatches("can't", "can't"), isTrue);
    });

    test('curly apostrophes from iPhone/iPad keyboards are accepted', () {
      expect(answerMatches('can’t', "can't"), isTrue);
      expect(answerMatches('O’CLOCK', "o'clock"), isTrue);
    });
  });

  group('findWordOccurrences', () {
    test('finds a whole word', () {
      final r = findWordOccurrences('cat', 'The cat drinks milk.');
      expect(r.length, 1);
      expect('The cat drinks milk.'.substring(r[0].start, r[0].end), 'cat');
    });

    test('never matches part of a longer word', () {
      expect(findWordOccurrences('cat', 'I can catch it.'), isEmpty);
      expect(findWordOccurrences('snow', 'A snowman.'), isEmpty);
      expect(findWordOccurrences('an', 'I ate an apple.').length, 1);
    });

    test('is case-insensitive (sentence start)', () {
      final r = findWordOccurrences('taste', 'Taste the soup.');
      expect(r.single.start, 0);
    });

    test('finds every occurrence', () {
      expect(findWordOccurrences('as', 'She is as tall as her brother.').length, 2);
    });

    test('allows a possessive but not a contraction', () {
      expect(findWordOccurrences('doll', "She brushed her doll's hair.").length, 1);
      expect(findWordOccurrences('it', "It's fun.").length, 0);
    });

    test('matches contractions as whole words', () {
      expect(findWordOccurrences("can't", "I can't reach the shelf.").length, 1);
    });

    test('does not match a plural form', () {
      expect(findWordOccurrences('thumb', 'Give me a thumbs up!'), isEmpty);
    });
  });
}
