import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../services/achievements.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mascot.dart';
import '../fill_blanks/fill_blank_question.dart';
import '../flip_write/flip_write_question.dart';
import '../games/choice_question.dart';
import '../games/spelling_questions.dart';

/// Shows one question of any type.
class ActivityView extends StatelessWidget {
  const ActivityView({
    super.key,
    required this.item,
    required this.onDone,
    this.fillLevel,
  });

  final ActivityItem item;
  final ValueChanged<ItemOutcome> onDone;

  /// Overrides the fill-in-the-blank level (otherwise taken from the type).
  final int? fillLevel;

  @override
  Widget build(BuildContext context) {
    final e = item.entry;
    return switch (item.type) {
      ActivityType.flipWrite ||
      ActivityType.listenWrite ||
      ActivityType.memoryWrite =>
        FlipWriteQuestion(
            entry: e, mode: FlipWriteMode.of(item.type), onDone: onDone),
      ActivityType.fillChoice =>
        FillBlankQuestion(entry: e, level: fillLevel ?? 1, onDone: onDone),
      ActivityType.fillDrag =>
        FillBlankQuestion(entry: e, level: fillLevel ?? 2, onDone: onDone),
      ActivityType.fillType =>
        FillBlankQuestion(entry: e, level: fillLevel ?? 3, onDone: onDone),
      ActivityType.spelling => SpellingQuestion(entry: e, onDone: onDone),
      ActivityType.scramble => ScrambleQuestion(entry: e, onDone: onDone),
      ActivityType.wordToMeaning ||
      ActivityType.meaningToWord ||
      ActivityType.listenChoose ||
      ActivityType.picture =>
        ChoiceQuestion(type: item.type, entry: e, onDone: onDone),
    };
  }
}

/// Runs a list of questions, saves every answer, then celebrates.
/// Returns a [SessionSummary] when the child taps Done.
class SessionRunner extends StatefulWidget {
  const SessionRunner({
    super.key,
    required this.title,
    required this.items,
    this.skillTag = 'mixed',
    this.color = AppColors.purple,
  });

  final String title;
  final List<ActivityItem> items;
  final String skillTag;
  final Color color;

  static Future<SessionSummary?> open(
    BuildContext context, {
    required String title,
    required List<ActivityItem> items,
    String skillTag = 'mixed',
    Color color = AppColors.purple,
  }) =>
      Navigator.of(context).push<SessionSummary>(MaterialPageRoute(
        builder: (_) => SessionRunner(
            title: title, items: items, skillTag: skillTag, color: color),
      ));

  @override
  State<SessionRunner> createState() => _SessionRunnerState();
}

class _SessionRunnerState extends State<SessionRunner> {
  int _index = 0;
  int _stars = 0;
  final List<ItemOutcome> _outcomes = [];
  SessionSummary? _summary;
  List<AchievementBadge> _newBadges = const [];

  void _onDone(ItemOutcome o) {
    final app = AppScope.read(context);
    final item = widget.items[_index];
    _stars += app.recordAnswer(item, o);
    _outcomes.add(o);
    if (_index + 1 >= widget.items.length) {
      final missed = <String>[];
      for (var i = 0; i < _outcomes.length; i++) {
        if (!_outcomes[i].correct) missed.add(widget.items[i].entry.id);
      }
      final summary = SessionSummary(
        title: widget.title,
        total: _outcomes.length,
        correct: _outcomes.where((x) => x.correct).length,
        firstTry: _outcomes.where((x) => x.firstTry).length,
        missedIds: missed,
      );
      final badges = app.finishSession(summary, widget.skillTag);
      setState(() {
        _summary = summary;
        _newBadges = badges;
      });
      app.speech.speak(summary.score >= 0.8
          ? 'Amazing work! You finished!'
          : 'Great job finishing! Keep practicing!');
    } else {
      setState(() => _index++);
    }
  }

  Future<bool> _confirmQuit() async {
    if (_summary != null || _outcomes.isEmpty) return true;
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop for now?'),
        content: const Text('Your answers so far are saved.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep going')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Stop')),
        ],
      ),
    );
    return quit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.items.length;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded, size: 30),
          onPressed: () async {
            final nav = Navigator.of(context);
            if (await _confirmQuit()) nav.pop(_summary);
          },
        ),
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text('⭐ $_stars',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: total == 0
            ? _empty()
            : _summary != null
                ? _results(_summary!)
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    child: ContentWidth(
                      maxWidth: 720,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(
                              child: SoftProgressBar(
                                value: _index / total,
                                color: widget.color,
                                semanticLabel: 'Session progress',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text('${_index + 1} of $total',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ]),
                          const SizedBox(height: 18),
                          ActivityView(
                            key: ValueKey('item-$_index'),
                            item: widget.items[_index],
                            onDone: _onDone,
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Mascot(mood: MascotMood.thinking, size: 120),
            const SizedBox(height: 16),
            const Text('No words to practice here right now!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            BigButton(label: 'Go back', onPressed: () => Navigator.pop(context)),
          ]),
        ),
      );

  Widget _results(SessionSummary s) {
    final app = AppScope.of(context);
    final rating = s.score >= 0.95
        ? 3
        : s.score >= 0.8
            ? 2
            : s.total > 0
                ? 1
                : 0;
    final missed = s.missedIds.map(app.vocab.byId).whereType<Object>().toList();
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ContentWidth(
            maxWidth: 640,
            child: Column(
              children: [
                const Mascot(mood: MascotMood.cheer, size: 140),
                const SizedBox(height: 8),
                Text('⭐' * rating + '☆' * (3 - rating),
                    style: const TextStyle(fontSize: 52)),
                Text(rating >= 2 ? 'Amazing work!' : 'Great job finishing!',
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('You got ${s.correct} of ${s.total} right',
                    style: const TextStyle(fontSize: 22)),
                Text('You earned ⭐ $_stars stars (+3 for finishing)',
                    style: const TextStyle(fontSize: 18, color: AppColors.soft)),
                if (_newBadges.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('New badge!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.coral)),
                  const SizedBox(height: 8),
                  for (final b in _newBadges)
                    Card(
                      child: ListTile(
                        leading: Text(b.emoji, style: const TextStyle(fontSize: 40)),
                        title: Text(b.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        subtitle: Text(b.description),
                      ),
                    ),
                ],
                if (missed.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Words to practice again:',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in s.missedIds)
                        if (app.vocab.byId(id) case final e?)
                          ActionChip(
                            avatar: const Icon(Icons.volume_up, size: 18),
                            label: Text(e.word, style: const TextStyle(fontSize: 18)),
                            onPressed: () => app.speech.word(e),
                          ),
                    ],
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: BigButton(
                    key: const ValueKey('session-done'),
                    label: 'Done',
                    emoji: '🎉',
                    onPressed: () => Navigator.pop(context, s),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Positioned.fill(child: Confetti(pieces: 90)),
      ],
    );
  }
}
