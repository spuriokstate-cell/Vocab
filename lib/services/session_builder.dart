import 'dart:math';

import '../models/activity.dart';
import '../models/vocab_entry.dart';
import 'question_engine.dart';

/// Turns a list of words into the questions for a session. A question type
/// is only used for a word when it can be asked fairly (e.g. fill-in-the-blank
/// needs the exact word in the example sentence).
class SessionBuilder {
  SessionBuilder({Random? random}) : rng = random ?? Random();
  final Random rng;

  static bool supports(ActivityType t, VocabEntry e) => switch (t) {
        ActivityType.fillChoice ||
        ActivityType.fillDrag ||
        ActivityType.fillType =>
          QuestionEngine.canBlank(e),
        ActivityType.scramble => QuestionEngine.canScramble(e),
        ActivityType.picture => QuestionEngine.hasPicture(e),
        _ => true,
      };

  /// The same activity for every word (words that can't use it are skipped).
  List<ActivityItem> single(ActivityType t, List<VocabEntry> words) => [
        for (final w in words)
          if (supports(t, w)) ActivityItem(t, w),
      ];

  static ActivityType fillTypeForLevel(int level) => switch (level) {
        2 => ActivityType.fillDrag,
        3 => ActivityType.fillType,
        _ => ActivityType.fillChoice,
      };

  /// One question per word, picking a random type from [types] that suits
  /// the word, spreading the types out evenly.
  List<ActivityItem> mixed(List<VocabEntry> words, List<ActivityType> types) {
    final items = <ActivityItem>[];
    final used = {for (final t in types) t: 0};
    for (final w in words) {
      final ok = types.where((t) => supports(t, w)).toList()..shuffle(rng);
      if (ok.isEmpty) continue;
      ok.sort((a, b) => used[a]!.compareTo(used[b]!));
      final t = ok.first;
      used[t] = used[t]! + 1;
      items.add(ActivityItem(t, w));
    }
    items.shuffle(rng);
    return items;
  }

  /// Lesson step 4: meaning, spelling and listening games.
  List<ActivityItem> lessonGames(List<VocabEntry> words) => mixed(words, const [
        ActivityType.wordToMeaning,
        ActivityType.meaningToWord,
        ActivityType.listenChoose,
        ActivityType.scramble,
        ActivityType.spelling,
        ActivityType.picture,
      ]);

  /// Mastery quiz / mixed quiz: every kind of question.
  List<ActivityItem> masteryQuiz(List<VocabEntry> words, {int fillLevel = 1}) =>
      mixed(words, [
        ActivityType.flipWrite,
        fillTypeForLevel(fillLevel),
        ActivityType.wordToMeaning,
        ActivityType.meaningToWord,
        ActivityType.spelling,
        ActivityType.listenChoose,
        ActivityType.scramble,
      ]);
}
