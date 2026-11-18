import 'dart:math';

import '../models/profile.dart';
import '../models/progress.dart';
import '../models/vocab_entry.dart';

/// Chooses which words to practice. Words the child got wrong come back more
/// often and sooner; mastered words come back now and then for review.
class WordScheduler {
  WordScheduler({Random? random}) : rng = random ?? Random();
  final Random rng;

  double weight(WordProgress? p, DateTime now) {
    if (p == null || p.isNew) return 3;
    final recent = p.lastPracticed != null &&
        now.difference(p.lastPracticed!) < const Duration(minutes: 30);
    double w = switch (p.level) {
      MasteryLevel.needsPractice => 8.0,
      MasteryLevel.newWord => 3.0,
      MasteryLevel.learning => p.isDue(now) ? 5.0 : 1.5,
      MasteryLevel.mastered => p.isDue(now) ? 2.0 : 0.3,
    };
    if (recent && p.level != MasteryLevel.needsPractice) w *= 0.3;
    return w;
  }

  /// Picks up to [count] different words, favouring the ones that need work.
  List<VocabEntry> pick(
    List<VocabEntry> candidates,
    ChildProfile profile,
    int count, {
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final pool = [...candidates];
    final weights = [for (final e in pool) weight(profile.words[e.id], t)];
    final out = <VocabEntry>[];
    while (out.length < count && pool.isNotEmpty) {
      final total = weights.fold<double>(0, (a, b) => a + b);
      var r = rng.nextDouble() * total;
      var i = 0;
      while (i < pool.length - 1 && r > weights[i]) {
        r -= weights[i];
        i++;
      }
      out.add(pool.removeAt(i));
      weights.removeAt(i);
    }
    return out;
  }

  /// Words for today's practice: words needing practice and words due for
  /// review first, then new words in their original order.
  List<VocabEntry> daily(
    List<VocabEntry> gradeWords,
    ChildProfile profile,
    int count, {
    DateTime? now,
  }) {
    final t = now ?? DateTime.now();
    final needs = <VocabEntry>[];
    final due = <VocabEntry>[];
    final fresh = <VocabEntry>[];
    for (final e in gradeWords) {
      final p = profile.words[e.id];
      if (p == null || p.isNew) {
        fresh.add(e);
      } else if (p.level == MasteryLevel.needsPractice) {
        needs.add(e);
      } else if (p.isDue(t)) {
        due.add(e);
      }
    }
    needs.shuffle(rng);
    due.shuffle(rng);
    final out = <VocabEntry>[...needs, ...due].take(count).toList();
    // Keep about a third of the session for new words when there are some.
    final newSlots = max(count - out.length, min(fresh.length, count ~/ 3));
    if (out.length + newSlots > count) {
      out.removeRange(count - newSlots, out.length);
    }
    out.addAll(fresh.take(newSlots));
    return out..shuffle(rng);
  }
}
