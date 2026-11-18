import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/activity.dart';
import '../../models/profile.dart';
import '../../models/progress.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// The grown-ups' area: progress, difficult words, history, settings and
/// child profiles. Reached only through the parent gate.
class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Parent Dashboard · ${app.profile.avatar} ${app.profile.name}'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.insights), text: 'Progress'),
              Tab(icon: Icon(Icons.spellcheck), text: 'Words'),
              Tab(icon: Icon(Icons.history), text: 'History'),
              Tab(icon: Icon(Icons.tune), text: 'Settings'),
              Tab(icon: Icon(Icons.people_alt), text: 'Profiles'),
            ],
          ),
        ),
        body: const TabBarView(children: [
          _ProgressTab(),
          _WordsTab(),
          _HistoryTab(),
          _SettingsTab(),
          _ProfilesTab(),
        ]),
      ),
    );
  }
}

Widget _section(String title, List<Widget> children) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final g1 = app.gradeStats(1), g2 = app.gradeStats(2);
    final learned = g1.learned + g2.learned;
    final mastered = g1.mastered + g2.mastered;
    final needs = app.wordsAt(MasteryLevel.needsPractice).length;
    final days = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContentWidth(
          child: Column(children: [
            _section('Overview', [
              Wrap(spacing: 12, runSpacing: 12, children: [
                _Stat('Words learned', '$learned', '📘'),
                _Stat('Words mastered', '$mastered', '🏆'),
                _Stat('Need practice', '$needs', '💪'),
                _Stat('Stars', '${app.profile.stars}', '⭐'),
                _Stat('Today', '${app.practicedToday} answers', '📅'),
              ]),
            ]),
            _section('Grade completion', [
              for (final (g, s) in [(1, g1), (2, g2)]) ...[
                Text('Grade $g: ${s.learned}/${s.total} learned · ${s.mastered} mastered · '
                    '${s.lessonsPassed}/${s.lessonCount} lessons passed',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                SoftProgressBar(value: s.learnedFraction, color: AppColors.forGrade(g)),
                const SizedBox(height: 14),
              ],
            ]),
            _section('Accuracy by skill', [
              for (final skill in Skill.values)
                Builder(builder: (context) {
                  final (right, total) = app.skillAccuracy(skill);
                  final pct = total == 0 ? 0.0 : right / total;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      SizedBox(width: 110, child: Text(skill.label, style: const TextStyle(fontSize: 16))),
                      Expanded(child: SoftProgressBar(value: pct, color: AppColors.purple)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: Text(total == 0 ? 'not yet' : '${(pct * 100).round()}% of $total',
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ]),
                  );
                }),
            ]),
            _section('Last 7 days', [
              _BarChart(
                values: [for (final d in days) (app.profile.dailyLog[dayKey(d)] ?? 0).toDouble()],
                labels: [for (final d in days) dayNames[d.weekday - 1]],
                color: AppColors.mint,
              ),
              const SizedBox(height: 6),
              const Text('Questions answered each day',
                  style: TextStyle(color: AppColors.soft)),
            ]),
          ]),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.emoji);
  final String label, value, emoji;

  @override
  Widget build(BuildContext context) => Container(
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: AppColors.soft)),
        ]),
      );
}

/// A simple bar chart drawn with plain widgets (no chart package needed).
class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.labels, required this.color});
  final List<double> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxV = values.fold<double>(1, (a, b) => b > a ? b : a);
    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Semantics(
                label: '${labels[i]}: ${values[i].round()}',
                excludeSemantics: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${values[i].round()}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        height: 120 * (values[i] / maxV),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(labels[i], style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WordsTab extends StatelessWidget {
  const _WordsTab();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final needs = app.wordsAt(MasteryLevel.needsPractice);
    final hard = app.difficultWords();
    final flagged = app.engine.invalidBlankEntries();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContentWidth(
          child: Column(children: [
            _section('Needs practice (${needs.length})', [
              if (needs.isEmpty) const Text('Nothing here. Great job!'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final e in needs)
                  ActionChip(label: Text(e.word), onPressed: () => app.speech.word(e)),
              ]),
            ]),
            _section('Most difficult words', [
              if (hard.isEmpty) const Text('No mistakes recorded yet.'),
              for (final e in hard)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.word, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  subtitle: Text(e.meaning),
                  trailing: Text(
                      '${app.progressOf(e)!.incorrect} wrong · ${app.progressOf(e)!.hints} hints'),
                ),
            ]),
            _section('Sentences waiting for your review (${flagged.length})', [
              const Text(
                'These example sentences in the PDF use a different form of the word '
                '(for example "thumbs" for "thumb"), so they are left out of '
                'Fill in the Blanks until approved. See docs/VOCABULARY_REVIEW_FLAGS.md '
                'for suggested replacements.',
                style: TextStyle(color: AppColors.soft),
              ),
              const SizedBox(height: 8),
              for (final f in flagged)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text('${f.entry.word}  (${f.entry.id})',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(f.entry.example),
                ),
            ]),
          ]),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final h = app.profile.history;
    if (h.isEmpty) {
      return const Center(
          child: Text('No sessions yet.', style: TextStyle(fontSize: 18)));
    }
    String two(int n) => n.toString().padLeft(2, '0');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: h.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final r = h[i];
        final pct = r.total == 0 ? 0 : (r.correct * 100 / r.total).round();
        return ContentWidth(
          child: ListTile(
            leading: CircleAvatar(child: Text('$pct%', style: const TextStyle(fontSize: 12))),
            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${r.at.year}-${two(r.at.month)}-${two(r.at.day)} '
                '${two(r.at.hour)}:${two(r.at.minute)} · ${r.correct}/${r.total} correct · '
                '${r.firstTry} first try'),
          ),
        );
      },
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  Future<void> _export(BuildContext context) async {
    final app = AppScope.read(context);
    final csv = app.exportCsv();
    final messenger = ScaffoldMessenger.of(context);
    String where;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final safeName = app.profile.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      final file = File('${dir.path}${Platform.pathSeparator}'
          'vocab_ishtika_${safeName}_${dayKey(now)}.csv');
      await file.writeAsString(csv);
      where = 'Saved to ${file.path}';
    } catch (_) {
      where = 'Could not save a file on this device';
    }
    await Clipboard.setData(ClipboardData(text: csv));
    messenger.showSnackBar(SnackBar(
      duration: const Duration(seconds: 8),
      content: Text('$where.\nThe report is also copied, so you can paste it into an email or spreadsheet.'),
    ));
  }

  Future<void> _reset(BuildContext context) async {
    final app = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset ${app.profile.name}\'s progress?'),
        content: const Text(
            'This clears all words learned, lesson results, stars, badges and history '
            'for this child on this device. It cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset progress'),
          ),
        ],
      ),
    );
    if (ok == true) await app.resetProgress();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = app.settings;
    Widget choice<T>(String label, T value, List<(T, String)> options, void Function(T) set) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final (v, text) in options)
                ChoiceChip(
                  label: Text(text),
                  selected: v == value,
                  onSelected: (_) => app.updateSettings((_) => set(v)),
                ),
            ]),
          ]),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContentWidth(
          child: Column(children: [
            _section('Learning', [
              choice<int>('Learning grade', s.grade, [(1, 'Grade 1'), (2, 'Grade 2')],
                  (v) => s.grade = v),
              choice<int>('Daily goal (questions)', s.dailyGoal,
                  [(5, '5'), (10, '10'), (15, '15'), (20, '20')], (v) => s.dailyGoal = v),
              choice<int>('Fill-in-the-blank difficulty', s.fillLevel,
                  [(1, 'Easy: tap'), (2, 'Medium: drag'), (3, 'Hard: type')],
                  (v) => s.fillLevel = v),
              choice<double>('Mastery quiz pass mark', s.passMark,
                  [(0.7, '70%'), (0.8, '80%'), (0.9, '90%')], (v) => s.passMark = v),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Lesson locking'),
                subtitle: const Text('Open each lesson only after passing the one before'),
                value: s.lessonLocking,
                onChanged: (v) => app.updateSettings((x) => x.lessonLocking = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Letter tiles keyboard'),
                subtitle: const Text('Show colorful A–Z tiles under writing boxes'),
                value: s.letterTiles,
                onChanged: (v) => app.updateSettings((x) => x.letterTiles = v),
              ),
              const SizedBox(height: 8),
              Text('Memory Challenge study time: ${s.memorySeconds} seconds',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Slider(
                value: s.memorySeconds.toDouble(),
                min: 3,
                max: 12,
                divisions: 9,
                label: '${s.memorySeconds}s',
                onChanged: (v) => app.updateSettings((x) => x.memorySeconds = v.round()),
              ),
            ]),
            _section('Sound and motion', [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Sound and speech'),
                value: s.sound,
                onChanged: (v) => app.updateSettings((x) => x.sound = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Read questions aloud automatically'),
                value: s.autoRead,
                onChanged: (v) => app.updateSettings((x) => x.autoRead = v),
              ),
              Text('Speech speed', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Row(children: [
                const Text('🐢'),
                Expanded(
                  child: Slider(
                    value: s.speechRate.clamp(0.2, 0.7).toDouble(),
                    min: 0.2,
                    max: 0.7,
                    divisions: 10,
                    onChanged: (v) => app.updateSettings((x) => x.speechRate = v),
                    onChangeEnd: (_) => app.speech.speak('This is how fast I will talk.'),
                  ),
                ),
                const Text('🐇'),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Reduce motion'),
                subtitle: const Text('No card flips, confetti or bouncing'),
                value: s.reducedMotion,
                onChanged: (v) => app.updateSettings((x) => x.reducedMotion = v),
              ),
            ]),
            _section('Reports and data', [
              const Text('Progress is stored only on this device. Nothing is sent online.',
                  style: TextStyle(color: AppColors.soft)),
              const SizedBox(height: 10),
              Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                  key: const ValueKey('export-csv'),
                  onPressed: () => _export(context),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export progress (CSV)'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('reset-progress'),
                  onPressed: () => _reset(context),
                  icon: const Icon(Icons.restart_alt, color: Colors.red),
                  label: const Text('Reset progress', style: TextStyle(color: Colors.red)),
                ),
              ]),
            ]),
          ]),
        ),
      ],
    );
  }
}

const avatarChoices = ['🦉', '🦊', '🐼', '🐯', '🦄', '🐸', '🐙', '🦋', '🐢', '🐬', '🦁', '🐰'];

class _ProfilesTab extends StatelessWidget {
  const _ProfilesTab();

  Future<void> _edit(BuildContext context, {ChildProfile? profile}) async {
    final app = AppScope.read(context);
    final name = TextEditingController(text: profile?.name ?? '');
    var avatar = profile?.avatar ?? avatarChoices[app.profiles.length % avatarChoices.length];
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(profile == null ? 'Add a child' : 'Edit profile'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              key: const ValueKey('profile-name'),
              controller: name,
              maxLength: 20,
              decoration: const InputDecoration(labelText: 'First name or nickname'),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final a in avatarChoices)
                ChoiceChip(
                  label: Text(a, style: const TextStyle(fontSize: 24)),
                  selected: a == avatar,
                  onSelected: (_) => setD(() => avatar = a),
                ),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
                key: const ValueKey('profile-save'),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    if (profile == null) {
      await app.addProfile(name.text, avatar);
    } else {
      await app.renameProfile(profile, name.text, avatar);
    }
  }

  Future<void> _delete(BuildContext context, ChildProfile p) async {
    final app = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${p.name}?'),
        content: const Text('Their progress on this device will be removed. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await app.deleteProfile(p);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContentWidth(
          child: Column(children: [
            _section('Children on this device', [
              for (final p in app.profiles)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(p.avatar, style: const TextStyle(fontSize: 34)),
                  title: Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  subtitle: Text('${p.words.values.where((w) => w.learned).length} words learned · ⭐ ${p.stars}'),
                  trailing: Wrap(spacing: 4, children: [
                    if (p.id == app.profile.id)
                      const Chip(label: Text('Active'))
                    else
                      TextButton(
                          onPressed: () => app.switchProfile(p), child: const Text('Switch')),
                    IconButton(
                        tooltip: 'Edit',
                        onPressed: () => _edit(context, profile: p),
                        icon: const Icon(Icons.edit)),
                    if (app.profiles.length > 1)
                      IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _delete(context, p),
                          icon: const Icon(Icons.delete_outline)),
                  ]),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('add-profile'),
                onPressed: () => _edit(context),
                icon: const Icon(Icons.person_add),
                label: const Text('Add a child'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Only a first name or nickname and an emoji are stored, on this device only.',
                style: TextStyle(color: AppColors.soft),
              ),
            ]),
          ]),
        ),
      ],
    );
  }
}
