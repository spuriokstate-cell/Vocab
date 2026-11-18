import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/vocab_entry.dart';
import '../../services/session_builder.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../session/session_runner.dart';

/// The five steps of a lesson.
class LessonStep {
  const LessonStep(this.number, this.title, this.emoji, this.description);
  final int number;
  final String title;
  final String emoji;
  final String description;

  static const all = [
    LessonStep(1, 'Learn', '📖', 'Meet the words, their meanings and sentences'),
    LessonStep(2, 'Look, Flip & Write', '🃏', 'Remember each word and write it'),
    LessonStep(3, 'Fill in the Blanks', '🧩', 'Use the words in sentences'),
    LessonStep(4, 'Word Games', '🎮', 'Meanings, spelling and listening'),
    LessonStep(5, 'Mastery Quiz', '🏆', 'Score 80% to unlock the next lesson'),
  ];
}

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key, required this.lesson});
  final Lesson lesson;

  Future<void> _runStep(BuildContext context, LessonStep step) async {
    final app = AppScope.read(context);
    final builder = SessionBuilder(random: app.rng);
    final words = lesson.words;
    final color = AppColors.forGrade(lesson.grade);
    switch (step.number) {
      case 1: {
        final done = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => LearnScreen(lesson: lesson)));
        if (done == true) app.completeLessonStep(lesson, 1);
      }
      case 2: {
        final s = await SessionRunner.open(context,
            title: 'Look, Flip & Write',
            items: builder.single(ActivityType.flipWrite, words),
            skillTag: 'spelling',
            color: color);
        if (s != null) app.completeLessonStep(lesson, 2);
      }
      case 3: {
        final type = SessionBuilder.fillTypeForLevel(app.settings.fillLevel);
        final items = builder.single(type, words);
        if (items.isEmpty) {
          app.completeLessonStep(lesson, 3);
          return;
        }
        final s = await SessionRunner.open(context,
            title: 'Fill in the Blanks', items: items, skillTag: 'sentences', color: color);
        if (s != null) app.completeLessonStep(lesson, 3);
      }
      case 4: {
        final s = await SessionRunner.open(context,
            title: 'Word Games',
            items: builder.lessonGames(words),
            skillTag: 'mixed',
            color: color);
        if (s != null) app.completeLessonStep(lesson, 4);
      }
      case 5: {
        final s = await SessionRunner.open(context,
            title: 'Mastery Quiz',
            items: builder.masteryQuiz(words, fillLevel: app.settings.fillLevel),
            skillTag: 'quiz',
            color: color);
        if (s == null || !context.mounted) return;
        final wasPassed = app.lessonPassed(lesson);
        app.completeLessonStep(lesson, 5, score: s.score);
        await _showQuizResult(context, s.score, wasPassed);
      }
    }
  }

  Future<void> _showQuizResult(BuildContext context, double score, bool wasPassed) {
    final app = AppScope.read(context);
    final passed = score >= app.settings.passMark;
    final lessons = app.vocab.lessons(lesson.grade);
    final hasNext = lesson.number < lessons.length;
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(passed ? 'You passed! 🎉' : 'Almost there! 💪',
            textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Mascot(mood: passed ? MascotMood.cheer : MascotMood.thinking, size: 110),
          const SizedBox(height: 8),
          Text('Your score: ${(score * 100).round()}%',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            passed
                ? (hasNext && !wasPassed
                    ? 'Lesson ${lesson.number + 1} is now open!'
                    : 'Wonderful work!')
                : 'You need ${(app.settings.passMark * 100).round()}% to pass. '
                    'Practice the words and try again. You can do it!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ]),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lp = app.lessonProgress(lesson);
    final color = AppColors.forGrade(lesson.grade);
    final nextStep = LessonStep.all
        .firstWhere((s) => !lp.stepsDone.contains(s.number), orElse: () => LessonStep.all.last);
    return Scaffold(
      appBar: AppBar(title: Text('Grade ${lesson.grade} · ${lesson.title}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: ContentWidth(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${lesson.words.length} words in this lesson',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final w in lesson.words)
                          ActionChip(
                            label: Text('${app.levelOf(w).emoji} ${w.word}',
                                style: const TextStyle(fontSize: 17)),
                            onPressed: () => app.speech.word(w),
                          ),
                      ]),
                      if (lp.bestScore > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                            'Best quiz score: ${(lp.bestScore * 100).round()}%  ${'⭐' * lp.stars}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                for (final step in LessonStep.all)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _StepCard(
                      step: step,
                      done: lp.stepsDone.contains(step.number),
                      isNext: step.number == nextStep.number && !lp.stepsDone.contains(step.number),
                      color: color,
                      onTap: () => _runStep(context, step),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.done,
    required this.isNext,
    required this.color,
    required this.onTap,
  });

  final LessonStep step;
  final bool done;
  final bool isNext;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isNext ? color : Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: isNext ? 4 : 1,
      child: InkWell(
        key: ValueKey('lesson-step-${step.number}'),
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isNext ? Colors.white : color.withValues(alpha: 0.2),
              child: Text(step.emoji, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Step ${step.number}: ${step.title}',
                    style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: isNext ? Colors.white : AppColors.ink)),
                const SizedBox(height: 2),
                Text(step.description,
                    style: TextStyle(
                        fontSize: 15, color: isNext ? Colors.white : AppColors.soft)),
              ]),
            ),
            Icon(
              done ? Icons.check_circle_rounded : Icons.play_circle_fill_rounded,
              size: 36,
              color: done ? AppColors.right : (isNext ? Colors.white : color),
              semanticLabel: done ? 'Done' : 'Start',
            ),
          ]),
        ),
      ),
    );
  }
}

/// Step 1: meet each word, one card at a time.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _i = 0;

  List<VocabEntry> get _words => widget.lesson.words;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }

  void _read() {
    if (!mounted) return;
    final app = AppScope.read(context);
    final e = _words[_i];
    if (app.settings.autoRead) {
      app.speech.speak('${e.word}. ${e.meaning} For example: ${e.example}');
    }
  }

  void _go(int d) {
    setState(() => _i = (_i + d).clamp(0, _words.length - 1));
    _read();
  }

  @override
  Widget build(BuildContext context) {
    final e = _words[_i];
    final last = _i == _words.length - 1;
    final color = AppColors.forGrade(widget.lesson.grade);
    return Scaffold(
      appBar: AppBar(title: Text('Learn · ${widget.lesson.title}')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          child: ContentWidth(
            maxWidth: 680,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(child: SoftProgressBar(value: (_i + 1) / _words.length, color: color)),
                  const SizedBox(width: 12),
                  Text('${_i + 1} / ${_words.length}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 18),
                Container(
                  key: ValueKey('learn-${e.id}'),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: color, width: 4),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(e.word,
                            style: const TextStyle(
                                fontSize: 56, fontWeight: FontWeight.w900, color: AppColors.deepPurple)),
                      ),
                      SpeakButton(text: e.word, size: 60, tooltip: 'Hear the word'),
                    ]),
                    const SizedBox(height: 16),
                    const Text('MEANING',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.soft, letterSpacing: 1.2)),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Text(e.meaning, style: const TextStyle(fontSize: 24, height: 1.35))),
                      SpeakButton(text: '${e.word}. ${e.meaning}', size: 44, tooltip: 'Read the meaning'),
                    ]),
                    const SizedBox(height: 16),
                    const Text('SENTENCE',
                        style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.soft, letterSpacing: 1.2)),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Text(e.example,
                            style: const TextStyle(fontSize: 24, fontStyle: FontStyle.italic, height: 1.35)),
                      ),
                      SpeakButton(text: e.example, size: 44, tooltip: 'Read the sentence'),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _i == 0 ? null : () => _go(-1),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: BigButton(
                      key: const ValueKey('learn-next'),
                      label: last ? 'I learned them all!' : 'Next word',
                      emoji: last ? '🎉' : '➡️',
                      color: color,
                      onPressed: last ? () => Navigator.pop(context, true) : () => _go(1),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
