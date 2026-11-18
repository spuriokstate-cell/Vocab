import 'progress.dart';

/// Parent-controlled settings, stored per child.
class AppSettings {
  AppSettings({
    this.grade = 1,
    this.dailyGoal = 10,
    this.fillLevel = 1,
    this.lessonLocking = true,
    this.sound = true,
    this.speechRate = 0.42,
    this.autoRead = true,
    this.reducedMotion = false,
    this.memorySeconds = 5,
    this.letterTiles = false,
    this.passMark = 0.8,
  });

  /// Grade shown first on the home screen (1 or 2).
  int grade;

  /// Words per Daily Practice session.
  int dailyGoal;

  /// Fill-in-the-blank difficulty used inside lessons: 1 easy, 2 medium, 3 hard.
  int fillLevel;

  /// When on, a lesson opens only after the one before it is passed.
  bool lessonLocking;

  bool sound;

  /// Speech speed, 0.2 (slow) .. 0.7 (fast).
  double speechRate;

  /// Read instructions and questions aloud automatically.
  bool autoRead;

  /// Turn off flips, confetti and bouncing.
  bool reducedMotion;

  /// Seconds the word stays visible in Memory Challenge.
  int memorySeconds;

  /// Show the colorful letter-tile keyboard under writing boxes.
  bool letterTiles;

  /// Mastery quiz pass mark (0.8 = 80%).
  double passMark;

  Map<String, dynamic> toJson() => {
        'grade': grade,
        'dailyGoal': dailyGoal,
        'fillLevel': fillLevel,
        'lessonLocking': lessonLocking,
        'sound': sound,
        'speechRate': speechRate,
        'autoRead': autoRead,
        'reducedMotion': reducedMotion,
        'memorySeconds': memorySeconds,
        'letterTiles': letterTiles,
        'passMark': passMark,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        grade: (j['grade'] as num?)?.toInt() ?? 1,
        dailyGoal: (j['dailyGoal'] as num?)?.toInt() ?? 10,
        fillLevel: (j['fillLevel'] as num?)?.toInt() ?? 1,
        lessonLocking: j['lessonLocking'] as bool? ?? true,
        sound: j['sound'] as bool? ?? true,
        speechRate: (j['speechRate'] as num?)?.toDouble() ?? 0.42,
        autoRead: j['autoRead'] as bool? ?? true,
        reducedMotion: j['reducedMotion'] as bool? ?? false,
        memorySeconds: (j['memorySeconds'] as num?)?.toInt() ?? 5,
        letterTiles: j['letterTiles'] as bool? ?? false,
        passMark: (j['passMark'] as num?)?.toDouble() ?? 0.8,
      );
}

/// A child using the app. Only a first name or nickname and an avatar are
/// stored, on this device only.
class ChildProfile {
  ChildProfile({
    required this.id,
    required this.name,
    this.avatar = '🦉',
    AppSettings? settings,
    Map<String, WordProgress>? words,
    Map<String, LessonProgress>? lessons,
    List<SessionRecord>? history,
    Set<String>? badges,
    Map<String, int>? dailyLog,
    Map<String, int>? counters,
    this.stars = 0,
  })  : settings = settings ?? AppSettings(),
        words = words ?? {},
        lessons = lessons ?? {},
        history = history ?? [],
        badges = badges ?? {},
        dailyLog = dailyLog ?? {},
        counters = counters ?? {};

  final String id;
  String name;
  String avatar;
  final AppSettings settings;
  final Map<String, WordProgress> words;
  final Map<String, LessonProgress> lessons;
  final List<SessionRecord> history;
  final Set<String> badges;

  /// Questions answered per day, keyed "yyyy-mm-dd".
  final Map<String, int> dailyLog;

  /// Running totals, e.g. 'flipFirstTry', 'skill_spelling'.
  final Map<String, int> counters;
  int stars;

  WordProgress progressFor(String wordId) =>
      words.putIfAbsent(wordId, WordProgress.new);

  LessonProgress lessonFor(String lessonId) =>
      lessons.putIfAbsent(lessonId, LessonProgress.new);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'settings': settings.toJson(),
        'words': words.map((k, v) => MapEntry(k, v.toJson())),
        'lessons': lessons.map((k, v) => MapEntry(k, v.toJson())),
        'history': history.map((h) => h.toJson()).toList(),
        'badges': badges.toList(),
        'daily': dailyLog,
        'counters': counters,
        'stars': stars,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> j) => ChildProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? 'Explorer',
        avatar: j['avatar'] as String? ?? '🦉',
        settings: AppSettings.fromJson(
            (j['settings'] as Map<String, dynamic>?) ?? const {}),
        words: ((j['words'] as Map<String, dynamic>?) ?? const {}).map(
            (k, v) => MapEntry(k, WordProgress.fromJson(v as Map<String, dynamic>))),
        lessons: ((j['lessons'] as Map<String, dynamic>?) ?? const {}).map(
            (k, v) =>
                MapEntry(k, LessonProgress.fromJson(v as Map<String, dynamic>))),
        history: ((j['history'] as List?) ?? const [])
            .map((h) => SessionRecord.fromJson(h as Map<String, dynamic>))
            .toList(),
        badges: ((j['badges'] as List?) ?? const []).cast<String>().toSet(),
        dailyLog: ((j['daily'] as Map<String, dynamic>?) ?? const {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        counters: ((j['counters'] as Map<String, dynamic>?) ?? const {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
        stars: (j['stars'] as num?)?.toInt() ?? 0,
      );
}

String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
