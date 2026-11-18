import 'dart:math';

import 'package:flutter/widgets.dart';

import '../data/profile_store.dart';
import '../data/vocabulary_repository.dart';
import '../models/activity.dart';
import '../models/profile.dart';
import '../models/progress.dart';
import '../models/vocab_entry.dart';
import '../services/achievements.dart';
import '../services/question_engine.dart';
import '../services/scheduler.dart';
import '../services/speech_service.dart';

/// Word counts for a grade, shown on the home screen.
class GradeStats {
  const GradeStats(this.total, this.learned, this.mastered, this.lessonsPassed,
      this.lessonCount);
  final int total;
  final int learned;
  final int mastered;
  final int lessonsPassed;
  final int lessonCount;
  double get learnedFraction => total == 0 ? 0 : learned / total;
}

/// The whole app's state: vocabulary, the current child and their progress.
class AppState extends ChangeNotifier {
  AppState({
    required this.vocab,
    required this.store,
    required this.speech,
    Random? random,
  })  : engine = QuestionEngine(vocab.all, random: random),
        scheduler = WordScheduler(random: random),
        rng = random ?? Random();

  final VocabularyRepository vocab;
  final ProfileStore store;
  final SpeechService speech;
  final QuestionEngine engine;
  final WordScheduler scheduler;
  final Random rng;

  final List<ChildProfile> profiles = [];
  late ChildProfile profile;

  AppSettings get settings => profile.settings;

  /// Loads saved profiles, creating a first one if there are none.
  Future<void> init() async {
    profiles
      ..clear()
      ..addAll(store.loadAll());
    if (profiles.isEmpty) {
      final p = ChildProfile(id: _newId(), name: 'Explorer');
      profiles.add(p);
      await store.save(p);
    }
    final active = store.activeId;
    profile = profiles.firstWhere((p) => p.id == active,
        orElse: () => profiles.first);
    await store.setActive(profile.id);
    _applySettings();
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}${rng.nextInt(9999)}';

  void _applySettings() {
    speech.enabled = settings.sound;
    speech.rate = settings.speechRate;
  }

  void _changed() {
    store.saveSoon(profile);
    notifyListeners();
  }

  Future<void> saveNow() => store.save(profile);

  // ------------------------------------------------------------ profiles

  Future<void> switchProfile(ChildProfile p) async {
    await store.flush(profiles);
    profile = p;
    await store.setActive(p.id);
    _applySettings();
    notifyListeners();
  }

  Future<ChildProfile> addProfile(String name, String avatar) async {
    final p = ChildProfile(
        id: _newId(),
        name: name.trim().isEmpty ? 'Explorer' : name.trim(),
        avatar: avatar);
    profiles.add(p);
    await store.save(p);
    notifyListeners();
    return p;
  }

  Future<void> renameProfile(ChildProfile p, String name, String avatar) async {
    if (name.trim().isNotEmpty) p.name = name.trim();
    p.avatar = avatar;
    await store.save(p);
    notifyListeners();
  }

  Future<void> deleteProfile(ChildProfile p) async {
    if (profiles.length <= 1) return;
    profiles.remove(p);
    await store.delete(p.id);
    if (profile.id == p.id) await switchProfile(profiles.first);
    notifyListeners();
  }

  void updateSettings(void Function(AppSettings s) change) {
    change(settings);
    _applySettings();
    _changed();
  }

  /// Clears this child's progress (settings, name and avatar are kept).
  Future<void> resetProgress() async {
    profile.words.clear();
    profile.lessons.clear();
    profile.history.clear();
    profile.badges.clear();
    profile.dailyLog.clear();
    profile.counters.clear();
    profile.stars = 0;
    await store.save(profile);
    notifyListeners();
  }

  // ------------------------------------------------------------ recording

  WordProgress? progressOf(VocabEntry e) => profile.words[e.id];
  MasteryLevel levelOf(VocabEntry e) =>
      profile.words[e.id]?.level ?? MasteryLevel.newWord;

  void _bump(String key, [int by = 1]) =>
      profile.counters[key] = (profile.counters[key] ?? 0) + by;

  /// Saves one answer. Returns the stars earned for it.
  int recordAnswer(ActivityItem item, ItemOutcome o, {DateTime? now}) {
    final t = now ?? DateTime.now();
    profile.progressFor(item.entry.id).record(item.type, o, t);
    final day = dayKey(t);
    profile.dailyLog[day] = (profile.dailyLog[day] ?? 0) + 1;
    var stars = 0;
    if (o.correct) {
      _bump('skill_${item.type.skill.name}');
      stars = o.firstTry ? 2 : 1;
      if (o.firstTry &&
          (item.type == ActivityType.flipWrite ||
              item.type == ActivityType.memoryWrite)) {
        _bump('flipFirstTry');
      }
    }
    profile.stars += stars;
    _changed();
    return stars;
  }

  void recordFlashcard(VocabEntry e, bool known, {DateTime? now}) {
    final t = now ?? DateTime.now();
    profile.progressFor(e.id).recordFlashcard(known, t);
    final day = dayKey(t);
    profile.dailyLog[day] = (profile.dailyLog[day] ?? 0) + 1;
    _changed();
  }

  /// Saves a finished session and returns any badges that were just earned.
  List<AchievementBadge> finishSession(SessionSummary s, String skill) {
    profile.history.insert(
        0,
        SessionRecord(
            at: DateTime.now(),
            title: s.title,
            skill: skill,
            total: s.total,
            correct: s.correct,
            firstTry: s.firstTry));
    if (profile.history.length > 300) profile.history.removeLast();
    if (s.total > 0) profile.stars += 3; // finishing bonus
    final earned = _checkBadges();
    store.save(profile);
    notifyListeners();
    return earned;
  }

  List<AchievementBadge> _checkBadges() {
    final newOnes = <AchievementBadge>[];
    for (final st in badgeStatus()) {
      if (st.earned && profile.badges.add(st.badge.id)) {
        newOnes.add(st.badge);
        profile.stars += 10;
      }
    }
    return newOnes;
  }

  List<BadgeStatus> badgeStatus() => Achievements.status(
        profile,
        lessonIdsByGrade: {
          for (final g in const [1, 2])
            g: vocab.lessons(g).map((l) => l.id).toList(),
        },
        skillCorrect: {
          for (final s in Skill.values) s.name: profile.counters['skill_${s.name}'] ?? 0,
        },
        passMark: settings.passMark,
      );

  // ------------------------------------------------------------ lessons

  LessonProgress lessonProgress(Lesson l) =>
      profile.lessons[l.id] ?? LessonProgress();

  bool isLessonUnlocked(Lesson l) {
    if (!settings.lessonLocking || l.number == 1) return true;
    final prev = vocab.lessons(l.grade)[l.number - 2];
    return lessonProgress(prev).passed;
  }

  /// Marks a lesson step done. For step 5 (mastery quiz) pass the score.
  void completeLessonStep(Lesson l, int step, {double? score}) {
    final lp = profile.lessonFor(l.id);
    lp.stepsDone.add(step);
    if (score != null && score > lp.bestScore) {
      lp.bestScore = score;
      lp.stars = score >= 0.95
          ? 3
          : score >= 0.88
              ? 2
              : score >= settings.passMark
                  ? 1
                  : 0;
      if (score >= settings.passMark) profile.stars += 5 * lp.stars;
    }
    _changed();
  }

  bool lessonPassed(Lesson l) {
    final lp = lessonProgress(l);
    return lp.stepsDone.contains(5) && lp.bestScore >= settings.passMark;
  }

  /// First lesson in a grade that isn't passed yet (where to continue).
  Lesson currentLesson(int grade) {
    final ls = vocab.lessons(grade);
    return ls.firstWhere((l) => !lessonPassed(l), orElse: () => ls.last);
  }

  // ------------------------------------------------------------ stats

  GradeStats gradeStats(int grade) {
    final words = vocab.grade(grade);
    var learned = 0, mastered = 0;
    for (final e in words) {
      final p = profile.words[e.id];
      if (p == null) continue;
      if (p.learned) learned++;
      if (p.level == MasteryLevel.mastered) mastered++;
    }
    final ls = vocab.lessons(grade);
    return GradeStats(words.length, learned, mastered,
        ls.where(lessonPassed).length, ls.length);
  }

  List<VocabEntry> wordsAt(MasteryLevel level, {int? grade}) => vocab.all
      .where((e) => grade == null || e.grade == grade)
      .where((e) => levelOf(e) == level)
      .toList();

  /// Words the child finds hardest: most wrong answers first.
  List<VocabEntry> difficultWords({int limit = 30}) {
    final list = vocab.all
        .where((e) => (profile.words[e.id]?.incorrect ?? 0) > 0)
        .toList()
      ..sort((a, b) => (profile.words[b.id]!.incorrect)
          .compareTo(profile.words[a.id]!.incorrect));
    return list.take(limit).toList();
  }

  /// [right, total] for a skill across all words.
  (int, int) skillAccuracy(Skill s) {
    var right = 0, total = 0;
    for (final w in profile.words.values) {
      final c = w.skill[s.name];
      if (c == null) continue;
      right += c[0];
      total += c[1];
    }
    return (right, total);
  }

  int get practicedToday => profile.dailyLog[dayKey(DateTime.now())] ?? 0;

  // ------------------------------------------------------------ export

  /// Progress for every word, as CSV (opens in Excel, Numbers, Sheets).
  String exportCsv() {
    String q(String s) => '"${s.replaceAll('"', '""')}"';
    final b = StringBuffer(
        'id,grade,word,level,attempts,correct,incorrect,first_try,hints,last_practiced,next_review\n');
    for (final e in vocab.all) {
      final p = profile.words[e.id];
      b.writeln([
        e.id,
        e.grade,
        q(e.word),
        (p?.level ?? MasteryLevel.newWord).label,
        p?.attempts ?? 0,
        p?.correct ?? 0,
        p?.incorrect ?? 0,
        p?.firstTry ?? 0,
        p?.hints ?? 0,
        p?.lastPracticed?.toIso8601String() ?? '',
        p?.dueAt?.toIso8601String() ?? '',
      ].join(','));
    }
    b.writeln();
    b.writeln('session_date,activity,skill,questions,correct,first_try');
    for (final h in profile.history) {
      b.writeln([
        h.at.toIso8601String(),
        q(h.title),
        h.skill,
        h.total,
        h.correct,
        h.firstTry
      ].join(','));
    }
    return b.toString();
  }
}

/// Makes [AppState] available to every screen: `AppScope.of(context)`.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads the state without rebuilding when it changes (for callbacks).
  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
