import 'package:flutter/material.dart';

import '../../models/progress.dart';
import '../../models/vocab_entry.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';

/// Where the words for a session come from.
enum WordSource {
  smart('Smart mix', 'Words to review and new words'),
  lesson('A lesson', 'Words from one lesson'),
  practice('Needs practice', 'Words that were tricky'),
  mastered('Mastered words', 'Review words you know'),
  all('Whole grade', 'Every word, in order');

  const WordSource(this.label, this.description);
  final String label;
  final String description;
}

/// What the parent/child chose in the picker.
class WordPick {
  const WordPick(this.words, {this.level = 1, this.grade = 1});
  final List<VocabEntry> words;
  final int level; // fill-in-the-blank difficulty (1..3)
  final int grade;
}

/// Opens the "which words?" sheet. Returns null if closed.
Future<WordPick?> showWordPicker(
  BuildContext context, {
  required String title,
  bool showLevel = false,
  List<int> counts = const [5, 10, 15, 20, 0],
  bool Function(VocabEntry e)? filter,
}) {
  return showModalBottomSheet<WordPick>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _WordPickerSheet(
        title: title, showLevel: showLevel, counts: counts, filter: filter),
  );
}

class _WordPickerSheet extends StatefulWidget {
  const _WordPickerSheet({
    required this.title,
    required this.showLevel,
    required this.counts,
    this.filter,
  });

  final String title;
  final bool showLevel;
  final List<int> counts;
  final bool Function(VocabEntry e)? filter;

  @override
  State<_WordPickerSheet> createState() => _WordPickerSheetState();
}

class _WordPickerSheetState extends State<_WordPickerSheet> {
  late int _grade;
  WordSource _source = WordSource.smart;
  int _count = 10;
  int _lesson = 1;
  late int _level;
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_init) return;
    _init = true;
    final app = AppScope.read(context);
    _grade = app.settings.grade;
    _level = app.settings.fillLevel;
    _lesson = app.currentLesson(_grade).number;
    _count = widget.counts.contains(10) ? 10 : widget.counts.first;
  }

  List<VocabEntry> _resolve(AppState app) {
    var words = app.vocab.grade(_grade);
    final f = widget.filter;
    if (f != null) words = words.where(f).toList();
    final n = _count == 0 ? words.length : _count;
    switch (_source) {
      case WordSource.smart:
        return app.scheduler.pick(words, app.profile, n);
      case WordSource.lesson:
        final ls = app.vocab.lessons(_grade);
        final l = ls[(_lesson - 1).clamp(0, ls.length - 1)];
        final lw = l.words.where((e) => f == null || f(e)).toList();
        return _count == 0 ? lw : lw.take(n).toList();
      case WordSource.practice:
        final p = words.where((e) => app.levelOf(e) == MasteryLevel.needsPractice).toList();
        return app.scheduler.pick(p, app.profile, n);
      case WordSource.mastered:
        final m = words.where((e) => app.levelOf(e) == MasteryLevel.mastered).toList();
        return app.scheduler.pick(m, app.profile, n);
      case WordSource.all:
        return words.take(n).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final lessons = app.vocab.lessons(_grade);
    final preview = _resolve(app);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            const _Label('Grade'),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Grade 1'), icon: Text('🐣')),
                ButtonSegment(value: 2, label: Text('Grade 2'), icon: Text('🚀')),
              ],
              selected: {_grade},
              onSelectionChanged: (s) => setState(() {
                _grade = s.first;
                _lesson = app.currentLesson(_grade).number;
              }),
            ),
            const SizedBox(height: 16),
            const _Label('Which words?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in WordSource.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _source == s,
                    onSelected: (_) => setState(() => _source = s),
                  ),
              ],
            ),
            if (_source == WordSource.lesson) ...[
              const SizedBox(height: 12),
              Row(children: [
                const Text('Lesson ', style: TextStyle(fontSize: 18)),
                DropdownButton<int>(
                  value: _lesson.clamp(1, lessons.length),
                  items: [
                    for (final l in lessons)
                      DropdownMenuItem(
                        value: l.number,
                        child: Text('${l.number}: ${l.preview}…'),
                      ),
                  ],
                  onChanged: (v) => setState(() => _lesson = v ?? 1),
                ),
              ]),
            ],
            const SizedBox(height: 16),
            const _Label('How many?'),
            Wrap(
              spacing: 8,
              children: [
                for (final n in widget.counts)
                  ChoiceChip(
                    label: Text(n == 0 ? 'All' : '$n'),
                    selected: _count == n,
                    onSelected: (_) => setState(() => _count = n),
                  ),
              ],
            ),
            if (widget.showLevel) ...[
              const SizedBox(height: 16),
              const _Label('How hard?'),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 1, label: Text('Easy'), icon: Icon(Icons.touch_app)),
                  ButtonSegment(value: 2, label: Text('Medium'), icon: Icon(Icons.pan_tool_alt)),
                  ButtonSegment(value: 3, label: Text('Hard'), icon: Icon(Icons.keyboard)),
                ],
                selected: {_level},
                onSelectionChanged: (s) => setState(() => _level = s.first),
              ),
              const SizedBox(height: 4),
              Text(
                switch (_level) {
                  2 => 'Drag the word into the sentence',
                  3 => 'Type the missing word',
                  _ => 'Tap the right word',
                },
                style: const TextStyle(color: AppColors.soft),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              preview.isEmpty
                  ? 'No words here yet. Try another choice!'
                  : '${preview.length} words ready',
              style: const TextStyle(fontSize: 16, color: AppColors.soft),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('picker-go'),
                onPressed: preview.isEmpty
                    ? null
                    : () => Navigator.pop(
                        context, WordPick(preview, level: _level, grade: _grade)),
                child: const Text("Let's go! 🚀", style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      );
}
