/// Text helpers shared by every activity: answer checking and finding a
/// vocabulary word inside its example sentence.
library;

/// Turns curly apostrophes (which iPhone/iPad keyboards insert automatically)
/// into straight ones, so "can’t" and "can't" are treated as the same answer.
/// The apostrophe itself is still required.
String normalizeApostrophes(String s) =>
    s.replaceAll('’', "'").replaceAll('‘', "'").replaceAll('`', "'");

/// Normalizes an answer for comparison: trims spaces, ignores upper/lower
/// case and apostrophe style. Missing letters, extra letters, wrong order and
/// missing apostrophes all still count as wrong.
String normalizeAnswer(String s) =>
    normalizeApostrophes(s).trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

/// True when [typed] is exactly [expected], ignoring case and outer spaces.
bool answerMatches(String typed, String expected) =>
    normalizeAnswer(typed).isNotEmpty &&
    normalizeAnswer(typed) == normalizeAnswer(expected);

/// Words where a following 's is a contraction (it's = it is), not a
/// possessive, so the word must not be blanked in front of it.
const _noPossessive = {
  'it', 'that', 'what', 'he', 'she', 'there', 'here', 'who', 'let', 'where',
  'how',
};

/// A position of a word inside a sentence.
class TextSpanRange {
  const TextSpanRange(this.start, this.end);
  final int start;
  final int end;
}

bool _isLetter(String ch) => RegExp(r'[A-Za-z]').hasMatch(ch);

/// Finds every whole-word occurrence of [word] in [text] (case-insensitive).
///
/// * Partial words never match ("cat" does not match "catch").
/// * A word glued to an apostrophe in front never matches.
/// * A possessive 's after the word is allowed ("doll" in "doll's"), except
///   for words like "it" where 's is a contraction.
List<TextSpanRange> findWordOccurrences(String word, String text) {
  final w = normalizeApostrophes(word.trim());
  if (w.isEmpty) return const [];
  final t = normalizeApostrophes(text);
  final lowerT = t.toLowerCase();
  final lowerW = w.toLowerCase();
  final result = <TextSpanRange>[];
  var from = 0;
  while (true) {
    final i = lowerT.indexOf(lowerW, from);
    if (i < 0) break;
    final end = i + lowerW.length;
    from = i + 1;
    final before = i > 0 ? t[i - 1] : '';
    final after = end < t.length ? t[end] : '';
    if (before.isNotEmpty && (_isLetter(before) || before == "'")) continue;
    if (after.isNotEmpty && _isLetter(after)) continue;
    if (after == "'") {
      final s = end + 1 < t.length ? t[end + 1].toLowerCase() : '';
      final s2 = end + 2 < t.length ? t[end + 2] : '';
      final possessive = s == 's' && (s2.isEmpty || !_isLetter(s2));
      if (!possessive || _noPossessive.contains(lowerW)) continue;
    }
    result.add(TextSpanRange(i, end));
  }
  return result;
}

/// Capitalizes the first letter, keeping the rest.
String capitalizeFirst(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// True if [s] starts with an uppercase letter.
bool startsUpper(String s) =>
    s.isNotEmpty && s[0].toUpperCase() == s[0] && s[0].toLowerCase() != s[0];

/// Simple letter-by-letter distance used to find similar-looking words.
int editDistance(String a, String b) {
  a = a.toLowerCase();
  b = b.toLowerCase();
  final prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    var diag = prev[0];
    prev[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final tmp = prev[j];
      prev[j] = [
        prev[j] + 1,
        prev[j - 1] + 1,
        diag + (a[i - 1] == b[j - 1] ? 0 : 1),
      ].reduce((x, y) => x < y ? x : y);
      diag = tmp;
    }
  }
  return prev[b.length];
}
