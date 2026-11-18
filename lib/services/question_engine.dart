import 'dart:math';

import '../core/text_utils.dart';
import '../core/word_sets.dart';
import '../models/vocab_entry.dart';

/// A piece of a sentence: plain text, or a blank where the word goes.
class SentencePart {
  const SentencePart.text(this.text) : isBlank = false;
  const SentencePart.blank() : text = '', isBlank = true;
  final String text;
  final bool isBlank;
}

/// A checked fill-in-the-blank question built from a word's example sentence.
class BlankQuestion {
  BlankQuestion._(this.entry, this.parts, this.answer, this.choices);

  final VocabEntry entry;

  /// The sentence split into text and blanks (every occurrence is a blank).
  final List<SentencePart> parts;

  /// The word exactly as it appears in the sentence (e.g. "Taste" at the
  /// start of a sentence). Checking ignores upper/lower case.
  final String answer;

  /// Four options in random order: the answer and three wrong words.
  final List<String> choices;

  String get blankedSentence => parts
      .map((p) => p.isBlank ? '_' * max(5, answer.length + 2) : p.text)
      .join();

  String get fullSentence => entry.example;

  bool isCorrect(String value) => answerMatches(value, answer);
}

/// Why a word can't be used for fill-in-the-blank.
class InvalidQuestion {
  const InvalidQuestion(this.entry, this.reason);
  final VocabEntry entry;
  final String reason;
}

/// Builds and validates all question types. Every question is checked before
/// it is shown; anything that can't be made fair is left out and reported.
class QuestionEngine {
  QuestionEngine(this.vocab, {Random? random}) : rng = random ?? Random();

  final List<VocabEntry> vocab;
  final Random rng;

  // ---------------------------------------------------------------- blanks

  /// Why [e] can't make a fill-in-the-blank question, or null if it can.
  static String? blankProblem(VocabEntry e) {
    if (findWordOccurrences(e.word, e.example).isEmpty) {
      return 'The example sentence does not contain the exact word "${e.word}".';
    }
    return null;
  }

  static bool canBlank(VocabEntry e) => blankProblem(e) == null;

  /// All entries left out of Fill in the Blanks, with reasons.
  List<InvalidQuestion> invalidBlankEntries() => [
        for (final e in vocab)
          if (blankProblem(e) case final reason?) InvalidQuestion(e, reason),
      ];

  /// Builds a validated question, or null if it can't be made fair.
  BlankQuestion? blank(VocabEntry e, {List<VocabEntry>? pool}) {
    final spans = findWordOccurrences(e.word, e.example);
    if (spans.isEmpty) return null;
    final s = e.example;
    final parts = <SentencePart>[];
    var at = 0;
    for (final r in spans) {
      if (r.start > at) parts.add(SentencePart.text(s.substring(at, r.start)));
      parts.add(const SentencePart.blank());
      at = r.end;
    }
    if (at < s.length) parts.add(SentencePart.text(s.substring(at)));
    final answer = s.substring(spans.first.start, spans.first.end);

    final wrong = _sentenceDistractors(e, pool ?? _sameGrade(e), 3);
    if (wrong.length < 3) return null;
    final shown = startsUpper(answer) && e.word != 'I'
        ? wrong.map(capitalizeFirst).toList()
        : wrong;
    final choices = [answer, ...shown]..shuffle(rng);

    // Final check: exactly one option is the answer, and no repeats.
    final norm = choices.map(normalizeAnswer).toList();
    if (norm.toSet().length != 4) return null;
    if (norm.where((c) => c == normalizeAnswer(answer)).length != 1) return null;
    return BlankQuestion._(e, parts, answer, choices);
  }

  List<VocabEntry> _sameGrade(VocabEntry e) =>
      vocab.where((v) => v.grade == e.grade).toList();

  static String _wordClass(String w) {
    final x = w.toLowerCase();
    if (x.contains("'")) return 'contraction';
    if (x.endsWith('ing') && x.length > 4) return 'ing';
    if (x.endsWith('ed') && x.length > 3) return 'ed';
    if (x.endsWith('ly') && x.length > 3) return 'ly';
    if (x.endsWith('est') && x.length > 4) return 'est';
    if (x.endsWith('er') && x.length > 3) return 'er';
    if (x.endsWith('s') && !x.endsWith('ss') && x.length > 3) return 's';
    return 'base';
  }

  static bool _sameStem(String a, String b) {
    final x = a.toLowerCase(), y = b.toLowerCase();
    if (x == y) return true;
    final (short, long) = x.length <= y.length ? (x, y) : (y, x);
    return long.startsWith(short) && long.length - short.length <= 3;
  }

  /// Wrong words for a sentence. To make sure only ONE choice fits:
  /// * a wrong word is a different kind of word from the answer (an action
  ///   word or describing word where a naming word goes, and so on), so it
  ///   can't also make sense in the sentence;
  /// * never a sound-alike, never a form of the same word, never a word that
  ///   is already in the sentence.
  /// Among the words left, ones with a similar length and ending are
  /// preferred so the choices look alike.
  List<String> _sentenceDistractors(VocabEntry e, List<VocabEntry> pool, int n) {
    final target = e.word;
    final cls = _wordClass(target);
    final answerKinds = wordKinds(target);
    // Unknown words are usually naming or action words.
    final forbidden = answerKinds.isEmpty ? const {'N', 'V'} : answerKinds;
    bool differentKind(String w) {
      final k = wordKinds(w);
      return k.isNotEmpty && !k.any(forbidden.contains);
    }

    final candidates = pool
        .map((v) => v.word)
        .where((w) =>
            differentKind(w) &&
            !_sameStem(w, target) &&
            !soundsAlike(w, target) &&
            !easilyConfused(w, target) &&
            w.toLowerCase() != 'i' &&
            findWordOccurrences(w, e.example).isEmpty)
        .toSet()
        .toList()
      ..shuffle(rng);
    int score(String w) =>
        (_wordClass(w) == cls ? 0 : 10) + (w.length - target.length).abs();
    candidates.sort((a, b) => score(a).compareTo(score(b)));
    final top = candidates.take(14).toList()..shuffle(rng);
    final rest = candidates.skip(14).toList();
    final picked = <String>[];
    // First try for variety (wrong words from different families), then
    // fall back to any remaining candidates.
    for (final strict in const [true, false]) {
      for (final w in [...top, ...rest]) {
        if (picked.length == n) return picked;
        if (picked.contains(w) || picked.any((p) => _sameStem(p, w))) continue;
        if (strict && picked.any((p) => easilyConfused(p, w))) continue;
        picked.add(w);
      }
    }
    return picked;
  }

  // ---------------------------------------------------------------- other games

  /// Four meanings for a word (the right one + 3 others), shuffled.
  List<String> meaningChoices(VocabEntry e) {
    final others = _sameGrade(e)
        .where((v) => v.id != e.id && v.meaning != e.meaning)
        .toList()
      ..shuffle(rng);
    final picked = <String>[];
    for (final v in others) {
      if (picked.contains(v.meaning) || soundsAlike(v.word, e.word)) continue;
      picked.add(v.meaning);
      if (picked.length == 3) break;
    }
    return [e.meaning, ...picked]..shuffle(rng);
  }

  /// Four words for a meaning (the right one + 3 others), shuffled.
  List<String> wordChoicesForMeaning(VocabEntry e) {
    final others = _sameGrade(e)
        .where((v) =>
            v.id != e.id &&
            v.meaning != e.meaning &&
            !_sameStem(v.word, e.word) &&
            !soundsAlike(v.word, e.word))
        .map((v) => v.word)
        .toSet()
        .toList()
      ..shuffle(rng);
    return [e.word, ...others.take(3)]..shuffle(rng);
  }

  /// Four words that look a bit like the answer, but never sound like it, so
  /// the child really has to listen.
  List<String> listeningChoices(VocabEntry e) {
    final t = e.word.toLowerCase();
    final others = vocab
        .map((v) => v.word)
        .where((w) => w.toLowerCase() != t && !soundsAlike(w, t))
        .toSet()
        .toList()
      ..shuffle(rng);
    int score(String w) {
      final d = editDistance(w, t);
      final sameStart = w.toLowerCase()[0] == t[0] ? 0 : 2;
      return d + sameStart;
    }

    others.sort((a, b) => score(a).compareTo(score(b)));
    final near = others.take(10).toList()..shuffle(rng);
    final picked = <String>[];
    for (final w in near) {
      if (picked.any((p) => soundsAlike(p, w))) continue;
      picked.add(w);
      if (picked.length == 3) break;
    }
    return [e.word, ...picked]..shuffle(rng);
  }

  /// Letters of the word in a new order (never the original order).
  List<String> scrambled(VocabEntry e) {
    final letters = e.word.split('');
    if (letters.toSet().length < 2) return letters;
    for (var tries = 0; tries < 20; tries++) {
      letters.shuffle(rng);
      if (letters.join().toLowerCase() != e.word.toLowerCase()) break;
    }
    return letters;
  }

  static bool canScramble(VocabEntry e) =>
      e.word.length >= 3 && e.word.toLowerCase().split('').toSet().length >= 2;

  /// Words in the vocabulary that have a clear picture.
  List<VocabEntry> get pictureEntries => vocab
      .where((v) => pictureWords.containsKey(v.word.toLowerCase()))
      .toList();

  static bool hasPicture(VocabEntry e) =>
      pictureWords.containsKey(e.word.toLowerCase());

  List<String> pictureChoices(VocabEntry e) {
    final others = pictureEntries
        .where((v) => v.id != e.id)
        .map((v) => v.word)
        .toList()
      ..shuffle(rng);
    return [e.word, ...others.take(3)]..shuffle(rng);
  }

  /// Extra wrong words for the drag-and-drop word bank.
  List<String> wordBank(BlankQuestion q) => q.choices;
}
