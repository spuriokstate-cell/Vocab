import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vocab_ishtika/models/activity.dart';
import 'package:vocab_ishtika/models/profile.dart';
import 'package:vocab_ishtika/models/progress.dart';
import 'package:vocab_ishtika/services/scheduler.dart';

import 'helpers.dart';

const _right = ItemOutcome(correct: true, attempts: 1, hintsUsed: 0, duration: Duration(seconds: 3));
const _retry = ItemOutcome(correct: true, attempts: 2, hintsUsed: 1, duration: Duration(seconds: 9));
const _wrong = ItemOutcome(correct: false, attempts: 3, hintsUsed: 2, duration: Duration(seconds: 20));

void main() {
  final now = DateTime(2026, 11, 17, 18);

  group('Spaced repetition', () {
    test('a new word is New', () {
      expect(WordProgress().level, MasteryLevel.newWord);
    });

    test('right first try moves the word up and schedules a review', () {
      final p = WordProgress()..record(ActivityType.flipWrite, _right, now);
      expect(p.box, 1);
      expect(p.firstTry, 1);
      expect(p.level, MasteryLevel.learning);
      expect(p.dueAt, now.add(const Duration(days: 1)));
    });

    test('a wrong answer means Needs Practice and comes back today', () {
      final p = WordProgress(box: 3)..record(ActivityType.fillChoice, _wrong, now);
      expect(p.box, 0);
      expect(p.incorrect, 1);
      expect(p.level, MasteryLevel.needsPractice);
      expect(p.isDue(now), isTrue);
    });

    test('right after a retry keeps the word in place', () {
      final p = WordProgress(box: 2)..record(ActivityType.spelling, _retry, now);
      expect(p.box, 2);
      expect(p.hints, 1);
      expect(p.firstTry, 0);
    });

    test('four first-try answers make a word Mastered', () {
      final p = WordProgress();
      for (var i = 0; i < 4; i++) {
        p.record(ActivityType.flipWrite, _right, now.add(Duration(days: i * 10)));
      }
      expect(p.level, MasteryLevel.mastered);
    });

    test('skill accuracy is tracked per activity', () {
      final p = WordProgress()
        ..record(ActivityType.flipWrite, _right, now)
        ..record(ActivityType.fillType, _wrong, now);
      expect(p.skill['spelling'], [1, 1]);
      expect(p.skill['sentences'], [0, 1]);
    });

    test('progress survives saving and loading', () {
      final p = WordProgress()..record(ActivityType.flipWrite, _right, now);
      final back = WordProgress.fromJson(p.toJson());
      expect(back.box, p.box);
      expect(back.firstTry, 1);
      expect(back.lastPracticed, now);
      expect(back.skill['spelling'], [1, 1]);
    });
  });

  group('Word picking', () {
    final all = loadAllEntries().where((e) => e.grade == 1).toList();

    test('words that need practice are picked much more often', () {
      final profile = ChildProfile(id: 't', name: 'T');
      final hard = all[5];
      profile.progressFor(hard.id).record(ActivityType.flipWrite, _wrong, now);
      final s = WordScheduler(random: Random(1));
      var hits = 0;
      for (var i = 0; i < 300; i++) {
        if (s.pick(all.take(40).toList(), profile, 5, now: now).contains(hard)) hits++;
      }
      // Without weighting it would be picked ~5/40 = 12.5% of the time.
      expect(hits / 300, greaterThan(0.4));
    });

    test('pick returns different words and no more than asked', () {
      final profile = ChildProfile(id: 't', name: 'T');
      final picked = WordScheduler(random: Random(2)).pick(all, profile, 10, now: now);
      expect(picked.length, 10);
      expect(picked.toSet().length, 10);
    });

    test('daily practice puts tricky words first and adds new words', () {
      final profile = ChildProfile(id: 't', name: 'T');
      for (final e in all.take(3)) {
        profile.progressFor(e.id).record(ActivityType.flipWrite, _wrong, now);
      }
      final daily = WordScheduler(random: Random(3)).daily(all, profile, 10, now: now);
      expect(daily.length, 10);
      for (final e in all.take(3)) {
        expect(daily, contains(e));
      }
      expect(daily.where((e) => profile.words[e.id] == null), isNotEmpty);
    });
  });

  group('Lessons and profiles', () {
    test('passing the mastery quiz unlocks the next lesson', () async {
      final app = await makeState();
      final l1 = app.vocab.lessons(1)[0], l2 = app.vocab.lessons(1)[1];
      expect(app.isLessonUnlocked(l2), isFalse);
      app.completeLessonStep(l1, 5, score: 0.7);
      expect(app.isLessonUnlocked(l2), isFalse);
      app.completeLessonStep(l1, 5, score: 0.85);
      expect(app.lessonPassed(l1), isTrue);
      expect(app.isLessonUnlocked(l2), isTrue);
    });

    test('parents can turn lesson locking off', () async {
      final app = await makeState();
      app.updateSettings((s) => s.lessonLocking = false);
      expect(app.isLessonUnlocked(app.vocab.lessons(2)[10]), isTrue);
    });

    test('progress is saved and loaded again (offline storage)', () async {
      final app = await makeState();
      final e = app.vocab.all.first;
      app.recordAnswer(ActivityItem(ActivityType.flipWrite, e), _right);
      await app.saveNow();
      // Re-open with the same saved data.
      final saved = app.store.loadAll();
      expect(saved.single.words[e.id]!.firstTry, 1);
    });

    test('several children have separate progress', () async {
      final app = await makeState();
      final e = app.vocab.all.first;
      app.recordAnswer(ActivityItem(ActivityType.flipWrite, e), _right);
      final second = await app.addProfile('Sam', '🐼');
      await app.switchProfile(second);
      expect(app.profile.name, 'Sam');
      expect(app.progressOf(e), isNull);
      expect(app.profiles.length, 2);
    });

    test('CSV export lists every word', () async {
      final app = await makeState();
      final csv = app.exportCsv();
      expect(csv.split('\n').where((l) => l.startsWith('g1_') || l.startsWith('g2_')).length, 1165);
    });

    test('reset clears progress but keeps the child', () async {
      final app = await makeState();
      app.recordAnswer(ActivityItem(ActivityType.flipWrite, app.vocab.all.first), _right);
      await app.resetProgress();
      expect(app.profile.words, isEmpty);
      expect(app.profile.stars, 0);
      expect(app.profiles, isNotEmpty);
    });

    test('badges are earned for learning words', () async {
      final app = await makeState();
      for (final e in app.vocab.all.take(10)) {
        app.recordAnswer(ActivityItem(ActivityType.flipWrite, e), _right);
      }
      final earned = app.finishSession(
          const SessionSummary(title: 't', total: 10, correct: 10, firstTry: 10, missedIds: []),
          'spelling');
      expect(earned.map((b) => b.id), contains('words10'));
      expect(app.profile.badges, contains('words10'));
    });
  });
}
