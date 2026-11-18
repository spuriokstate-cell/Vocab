import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/vocab_entry.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../lessons/lesson_screen.dart';

/// The lesson adventure map for one grade.
class GradeMapScreen extends StatelessWidget {
  const GradeMapScreen({super.key, required this.grade});
  final int grade;

  void _open(BuildContext context, Lesson l) {
    final app = AppScope.read(context);
    if (!app.isLessonUnlocked(l)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pass Lesson ${l.number - 1} to open this one! 🔒',
            style: const TextStyle(fontSize: 18)),
      ));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: l)));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lessons = app.vocab.lessons(grade);
    final stats = app.gradeStats(grade);
    final color = AppColors.forGrade(grade);
    final current = app.currentLesson(grade);
    return Scaffold(
      appBar: AppBar(title: Text('Grade $grade Adventure')),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ContentWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(children: [
                      const Mascot(size: 80),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${stats.learned} of ${stats.total} words learned',
                                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            SoftProgressBar(
                                value: stats.learnedFraction,
                                color: color,
                                semanticLabel: 'Grade $grade words learned'),
                            const SizedBox(height: 6),
                            Text('🏆 ${stats.mastered} mastered · '
                                '🎒 ${stats.lessonsPassed}/${stats.lessonCount} lessons passed',
                                style: const TextStyle(fontSize: 15, color: AppColors.soft)),
                            const SizedBox(height: 10),
                            FilledButton.icon(
                              key: const ValueKey('continue-lesson'),
                              style: FilledButton.styleFrom(backgroundColor: color),
                              onPressed: () => _open(context, current),
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: Text('Continue: Lesson ${current.number}'),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 40, top: 8),
              sliver: SliverList.builder(
                itemCount: lessons.length,
                itemBuilder: (context, i) => ContentWidth(
                  maxWidth: 560,
                  child: _MapNode(
                    lesson: lessons[i],
                    index: i,
                    isLast: i == lessons.length - 1,
                    unlocked: app.isLessonUnlocked(lessons[i]),
                    passed: app.lessonPassed(lessons[i]),
                    stars: app.lessonProgress(lessons[i]).stars,
                    current: lessons[i].number == current.number,
                    color: color,
                    onTap: () => _open(context, lessons[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapNode extends StatelessWidget {
  const _MapNode({
    required this.lesson,
    required this.index,
    required this.isLast,
    required this.unlocked,
    required this.passed,
    required this.stars,
    required this.current,
    required this.color,
    required this.onTap,
  });

  final Lesson lesson;
  final int index;
  final bool isLast;
  final bool unlocked;
  final bool passed;
  final int stars;
  final bool current;
  final Color color;
  final VoidCallback onTap;

  static double offsetFor(int i) => math.sin(i * 0.9) * 0.32;

  @override
  Widget build(BuildContext context) {
    const rowHeight = 132.0;
    return SizedBox(
      height: rowHeight,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final x = w / 2 + offsetFor(index) * w;
        final nx = w / 2 + offsetFor(index + 1) * w;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (!isLast)
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(
                      from: Offset(x, 48), to: Offset(nx, rowHeight + 48), color: color, done: passed),
                ),
              ),
            Positioned(
              left: x - 48,
              top: 0,
              width: 96,
              child: Semantics(
                button: true,
                label: '${lesson.title}${passed ? ', passed' : ''}${unlocked ? '' : ', locked'}',
                excludeSemantics: true,
                child: GestureDetector(
                  key: ValueKey('map-lesson-${lesson.number}'),
                  onTap: onTap,
                  child: Column(children: [
                    Container(
                      width: current ? 96 : 84,
                      height: current ? 96 : 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: !unlocked
                            ? const Color(0xFFD9D4E3)
                            : passed
                                ? color
                                : Colors.white,
                        border: Border.all(color: unlocked ? color : const Color(0xFFBDB6CC), width: 5),
                        boxShadow: current
                            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 18, spreadRadius: 2)]
                            : const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: !unlocked
                          ? const Icon(Icons.lock_rounded, size: 34, color: Color(0xFF8E87A3))
                          : Text('${lesson.number}',
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: passed ? Colors.white : color)),
                    ),
                    const SizedBox(height: 2),
                    Text(passed ? '⭐' * stars.clamp(1, 3) : (current ? 'You are here!' : ''),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.from, required this.to, required this.color, required this.done});
  final Offset from;
  final Offset to;
  final Color color;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = done ? color : color.withValues(alpha: 0.3)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(from.dx, mid.dy, mid.dx, mid.dy)
      ..quadraticBezierTo(to.dx, mid.dy, to.dx, to.dy);
    // Dashed look.
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 14), paint);
        d += 26;
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.from != from || old.to != to || old.done != done || old.color != color;
}
