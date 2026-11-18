import 'activity.dart';

/// Where a word is in the child's learning.
enum MasteryLevel {
  newWord('New', '🌱'),
  learning('Learning', '📘'),
  needsPractice('Needs Practice', '💪'),
  mastered('Mastered', '🏆');

  const MasteryLevel(this.label, this.emoji);
  final String label;
  final String emoji;
}

/// Days to wait before reviewing a word again, by spaced-repetition box.
/// Box 0 = practice again today, box 5+ = mastered (review monthly).
const List<int> reviewIntervalDays = [0, 1, 2, 4, 7, 14, 30];
const int masteredBox = 4;

/// Everything the app remembers about one word for one child.
class WordProgress {
  WordProgress({
    this.attempts = 0,
    this.correct = 0,
    this.incorrect = 0,
    this.firstTry = 0,
    this.hints = 0,
    this.box = 0,
    this.lastResultCorrect,
    this.lastPracticed,
    this.dueAt,
    this.knownFlashcard = false,
    Map<String, List<int>>? skill,
  }) : skill = skill ?? {};

  int attempts; // questions answered about this word
  int correct; // answered correctly (in the end)
  int incorrect; // never got it right in that question
  int firstTry; // right first time with no hints
  int hints;
  int box; // spaced-repetition box (0..6)
  bool? lastResultCorrect;
  DateTime? lastPracticed;
  DateTime? dueAt;
  bool knownFlashcard; // child tapped "I Know It!" on a flashcard

  /// Per-skill [right, total] counts, keyed by Skill.name.
  final Map<String, List<int>> skill;

  bool get isNew => attempts == 0 && !knownFlashcard;

  MasteryLevel get level {
    if (isNew) return MasteryLevel.newWord;
    if (lastResultCorrect == false) return MasteryLevel.needsPractice;
    if (box >= masteredBox) return MasteryLevel.mastered;
    return MasteryLevel.learning;
  }

  /// A word counts as "learned" once the child has got it right at least once.
  bool get learned => correct > 0 || knownFlashcard;

  bool isDue(DateTime now) => dueAt == null || !dueAt!.isAfter(now);

  /// Records one answer and moves the word between spaced-repetition boxes.
  void record(ActivityType type, ItemOutcome o, DateTime now) {
    attempts++;
    hints += o.hintsUsed;
    lastPracticed = now;
    lastResultCorrect = o.correct;
    final s = skill.putIfAbsent(type.skill.name, () => [0, 0]);
    s[1]++;
    if (o.correct) {
      correct++;
      s[0]++;
      if (o.firstTry) {
        firstTry++;
        box = (box + 1).clamp(0, reviewIntervalDays.length - 1);
      } else {
        // Right after a retry or a hint: stay in place (but at least box 1).
        box = box < 1 ? 1 : box;
      }
    } else {
      incorrect++;
      box = 0; // comes back today
    }
    dueAt = now.add(Duration(days: reviewIntervalDays[box]));
  }

  /// Flashcard self-check ("I Know It!" / "Practice Again").
  void recordFlashcard(bool known, DateTime now) {
    lastPracticed = now;
    knownFlashcard = known;
    if (known) {
      if (box < 1) box = 1;
      lastResultCorrect ??= true;
    } else {
      box = 0;
      lastResultCorrect = false;
    }
    dueAt = now.add(Duration(days: reviewIntervalDays[box]));
  }

  Map<String, dynamic> toJson() => {
        'a': attempts,
        'c': correct,
        'i': incorrect,
        'f': firstTry,
        'h': hints,
        'b': box,
        if (lastResultCorrect != null) 'l': lastResultCorrect,
        if (lastPracticed != null) 'p': lastPracticed!.millisecondsSinceEpoch,
        if (dueAt != null) 'd': dueAt!.millisecondsSinceEpoch,
        if (knownFlashcard) 'k': true,
        if (skill.isNotEmpty) 's': skill,
      };

  factory WordProgress.fromJson(Map<String, dynamic> j) => WordProgress(
        attempts: (j['a'] as num?)?.toInt() ?? 0,
        correct: (j['c'] as num?)?.toInt() ?? 0,
        incorrect: (j['i'] as num?)?.toInt() ?? 0,
        firstTry: (j['f'] as num?)?.toInt() ?? 0,
        hints: (j['h'] as num?)?.toInt() ?? 0,
        box: (j['b'] as num?)?.toInt() ?? 0,
        lastResultCorrect: j['l'] as bool?,
        lastPracticed: j['p'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((j['p'] as num).toInt()),
        dueAt: j['d'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((j['d'] as num).toInt()),
        knownFlashcard: j['k'] == true,
        skill: (j['s'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(
            k, (v as List).map((e) => (e as num).toInt()).toList())),
      );
}

/// Progress through one lesson's five steps.
class LessonProgress {
  LessonProgress({Set<int>? stepsDone, this.bestScore = 0, this.stars = 0})
      : stepsDone = stepsDone ?? {};

  final Set<int> stepsDone; // 1..5
  double bestScore; // best mastery quiz score 0..1
  int stars; // 0..3

  bool get passed => stepsDone.contains(5) && bestScore >= 0.8;

  Map<String, dynamic> toJson() =>
      {'s': stepsDone.toList(), 'b': bestScore, 't': stars};

  factory LessonProgress.fromJson(Map<String, dynamic> j) => LessonProgress(
        stepsDone:
            (j['s'] as List? ?? []).map((e) => (e as num).toInt()).toSet(),
        bestScore: (j['b'] as num?)?.toDouble() ?? 0,
        stars: (j['t'] as num?)?.toInt() ?? 0,
      );
}

/// One finished session, for the parent dashboard history.
class SessionRecord {
  const SessionRecord({
    required this.at,
    required this.title,
    required this.skill,
    required this.total,
    required this.correct,
    required this.firstTry,
  });

  final DateTime at;
  final String title;
  final String skill; // Skill.name, or 'mixed' / 'flashcards'
  final int total;
  final int correct;
  final int firstTry;

  Map<String, dynamic> toJson() => {
        'at': at.millisecondsSinceEpoch,
        't': title,
        'k': skill,
        'n': total,
        'c': correct,
        'f': firstTry,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        at: DateTime.fromMillisecondsSinceEpoch((j['at'] as num).toInt()),
        title: j['t'] as String? ?? '',
        skill: j['k'] as String? ?? 'mixed',
        total: (j['n'] as num?)?.toInt() ?? 0,
        correct: (j['c'] as num?)?.toInt() ?? 0,
        firstTry: (j['f'] as num?)?.toInt() ?? 0,
      );
}
