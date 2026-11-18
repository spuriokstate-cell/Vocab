import '../models/profile.dart';
import '../models/progress.dart';

/// A badge the child can earn.
class AchievementBadge {
  const AchievementBadge(this.id, this.title, this.emoji, this.description, this.target);
  final String id;
  final String title;
  final String emoji;
  final String description;

  /// Goal number, shown as progress toward the badge.
  final int target;
}

class BadgeStatus {
  const BadgeStatus(this.badge, this.current);
  final AchievementBadge badge;
  final int current;
  bool get earned => current >= badge.target;
  double get fraction => (current / badge.target).clamp(0, 1).toDouble();
}

/// Badge rules. Badges reward effort and learning, never speed or
/// competition, and are never taken away.
class Achievements {
  static const badges = [
    AchievementBadge('words10', 'First 10 Words', '🌱', 'Learn 10 words', 10),
    AchievementBadge('words50', 'First 50 Words', '🌿', 'Learn 50 words', 50),
    AchievementBadge('words100', 'First 100 Words', '🌳', 'Learn 100 words', 100),
    AchievementBadge('words250', 'Word Explorer', '🧭', 'Learn 250 words', 250),
    AchievementBadge('spelling', 'Spelling Star', '⭐', 'Spell 25 words correctly', 25),
    AchievementBadge('memory', 'Memory Champion', '🧠', 'Get 20 Look, Flip & Write words right with no hints', 20),
    AchievementBadge('sentence', 'Sentence Superstar', '🧩', 'Fill in 50 blanks correctly', 50),
    AchievementBadge('listening', 'Listening Champion', '👂', 'Answer 30 listening questions correctly', 30),
    AchievementBadge('meanings', 'Meaning Master', '📖', 'Match 30 words and meanings', 30),
    AchievementBadge('lesson1', 'Lesson Hero', '🎒', 'Pass your first lesson', 1),
    AchievementBadge('lessons10', 'Adventure Pro', '🗺️', 'Pass 10 lessons', 10),
    AchievementBadge('mastered25', 'Word Wizard', '🪄', 'Master 25 words', 25),
    AchievementBadge('streak3', 'Practice Pal', '📅', 'Practice on 3 different days', 3),
    AchievementBadge('grade1', 'Grade 1 Champion', '🥇', 'Pass every Grade 1 lesson', 1),
    AchievementBadge('grade2', 'Grade 2 Champion', '🏆', 'Pass every Grade 2 lesson', 1),
  ];

  /// Current progress toward every badge.
  static List<BadgeStatus> status(
    ChildProfile p, {
    required Map<int, List<String>> lessonIdsByGrade,
    required Map<String, int> skillCorrect,
    double passMark = 0.8,
  }) {
    bool lessonPassed(LessonProgress? l) =>
        l != null && l.stepsDone.contains(5) && l.bestScore >= passMark;
    final memoryFirstTry = p.counters['flipFirstTry'] ?? 0;
    final learned = p.words.values.where((w) => w.learned).length;
    final mastered =
        p.words.values.where((w) => w.level == MasteryLevel.mastered).length;
    final passed = p.lessons.values.where(lessonPassed).length;
    bool gradeDone(int g) {
      final ids = lessonIdsByGrade[g] ?? const [];
      return ids.isNotEmpty && ids.every((id) => lessonPassed(p.lessons[id]));
    }

    int value(String id) => switch (id) {
          'words10' || 'words50' || 'words100' || 'words250' => learned,
          'spelling' => skillCorrect['spelling'] ?? 0,
          'memory' => memoryFirstTry,
          'sentence' => skillCorrect['sentences'] ?? 0,
          'listening' => skillCorrect['listening'] ?? 0,
          'meanings' => skillCorrect['meaning'] ?? 0,
          'lesson1' || 'lessons10' => passed,
          'mastered25' => mastered,
          'streak3' => p.dailyLog.keys.length,
          'grade1' => gradeDone(1) ? 1 : 0,
          'grade2' => gradeDone(2) ? 1 : 0,
          _ => 0,
        };

    return [for (final b in badges) BadgeStatus(b, value(b.id))];
  }
}
