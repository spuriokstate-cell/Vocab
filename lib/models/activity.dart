import 'vocab_entry.dart';

/// Every kind of question the app can ask.
enum ActivityType {
  flipWrite('Look, Flip & Write', '🃏'),
  listenWrite('Listen & Write', '🎧'),
  memoryWrite('Memory Challenge', '🧠'),
  fillChoice('Fill in the Blank', '🧩'),
  fillDrag('Drag the Word', '✋'),
  fillType('Type the Missing Word', '⌨️'),
  wordToMeaning('Word to Meaning', '📖'),
  meaningToWord('Meaning to Word', '🔎'),
  spelling('Spelling Challenge', '🐝'),
  listenChoose('Listen & Choose', '👂'),
  scramble('Word Scramble', '🔀'),
  picture('Picture to Word', '🖼️');

  const ActivityType(this.label, this.emoji);
  final String label;
  final String emoji;

  /// Which skill this activity trains, for stats and badges.
  Skill get skill => switch (this) {
        ActivityType.flipWrite ||
        ActivityType.memoryWrite ||
        ActivityType.spelling ||
        ActivityType.scramble =>
          Skill.spelling,
        ActivityType.listenWrite || ActivityType.listenChoose => Skill.listening,
        ActivityType.fillChoice ||
        ActivityType.fillDrag ||
        ActivityType.fillType =>
          Skill.sentences,
        ActivityType.wordToMeaning ||
        ActivityType.meaningToWord ||
        ActivityType.picture =>
          Skill.meaning,
      };
}

enum Skill {
  spelling('Spelling'),
  sentences('Sentences'),
  listening('Listening'),
  meaning('Meanings');

  const Skill(this.label);
  final String label;
}

/// One question in a session: a word asked in a particular way.
class ActivityItem {
  const ActivityItem(this.type, this.entry);
  final ActivityType type;
  final VocabEntry entry;
}

/// How the child did on one question.
class ItemOutcome {
  const ItemOutcome({
    required this.correct,
    required this.attempts,
    required this.hintsUsed,
    required this.duration,
  });

  /// Got it right in the end (possibly after retries).
  final bool correct;

  /// Number of answers given (1 = right first time).
  final int attempts;
  final int hintsUsed;
  final Duration duration;

  bool get firstTry => correct && attempts == 1 && hintsUsed == 0;
}

/// The result of a whole session, used by lessons and the parent dashboard.
class SessionSummary {
  const SessionSummary({
    required this.title,
    required this.total,
    required this.correct,
    required this.firstTry,
    required this.missedIds,
  });

  final String title;
  final int total;
  final int correct;
  final int firstTry;
  final List<String> missedIds;

  /// Score used for lesson mastery: questions right on the first try count
  /// fully, questions right after a retry count half.
  double get score =>
      total == 0 ? 0 : (firstTry + (correct - firstTry) * 0.5) / total;
}
