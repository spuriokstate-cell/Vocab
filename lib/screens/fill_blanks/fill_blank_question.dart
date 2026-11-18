import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../models/vocab_entry.dart';
import '../../services/question_engine.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/write_box.dart';

/// Fill in the Blanks. Level 1 = tap one of four words, level 2 = drag the
/// word into the blank, level 3 = type the word.
class FillBlankQuestion extends StatefulWidget {
  const FillBlankQuestion({
    super.key,
    required this.entry,
    required this.level,
    required this.onDone,
  });

  final VocabEntry entry;
  final int level;
  final ValueChanged<ItemOutcome> onDone;

  @override
  State<FillBlankQuestion> createState() => _FillBlankQuestionState();
}

class _FillBlankQuestionState extends State<FillBlankQuestion> {
  BlankQuestion? _q;
  bool _built = false;
  final _typed = TextEditingController();
  final _focus = FocusNode();
  final _started = DateTime.now();
  final Set<String> _wrongPicks = {};

  int _attempts = 0;
  int _hints = 0; // 1 = meaning clue, 2 = first letter (typing)
  bool _done = false;
  bool _correct = false;
  String? _lastWrong;

  int get _maxWrong => widget.level == 3 ? 3 : 2;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_built) return;
    _built = true;
    final app = AppScope.read(context);
    _q = app.engine.blank(widget.entry);
    if (app.settings.autoRead && _q != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        app.speech.speak(
            'Find the missing word. ${_q!.parts.map((p) => p.isBlank ? ' blank ' : p.text).join()}');
      });
    }
  }

  @override
  void dispose() {
    _typed.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final q = _q;
    if (q == null || _done || value.trim().isEmpty) return;
    _attempts++;
    final app = AppScope.read(context);
    if (q.isCorrect(value)) {
      setState(() {
        _done = true;
        _correct = true;
      });
      app.speech.speak('Wonderful! You found the missing word! ${q.fullSentence}');
    } else {
      setState(() {
        _wrongPicks.add(value);
        _lastWrong = value;
        if (_attempts >= _maxWrong) {
          _done = true;
          _correct = false;
        }
      });
      if (_done) {
        app.speech.speak(
            'The missing word is ${widget.entry.word}. ${q.fullSentence}');
      } else {
        app.speech.speak("Nice try! Let's try again!");
        if (widget.level == 3) {
          _typed.selection =
              TextSelection(baseOffset: 0, extentOffset: _typed.text.length);
          _focus.requestFocus();
        }
      }
    }
  }

  void _hint() {
    setState(() => _hints++);
    if (_hints == 1) {
      AppScope.read(context).speech.speak('Clue: ${widget.entry.meaning}');
    }
  }

  void _finish() => widget.onDone(ItemOutcome(
        correct: _correct,
        attempts: _attempts == 0 ? 1 : _attempts,
        hintsUsed: _hints,
        duration: DateTime.now().difference(_started),
      ));

  @override
  Widget build(BuildContext context) {
    final q = _q;
    if (q == null) {
      // Only happens if a word without a usable sentence slips through.
      return Column(children: [
        const Text('This sentence is being checked by a grown-up. Let\'s skip it!',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
        const SizedBox(height: 16),
        BigButton(label: 'Skip', onPressed: () => widget.onDone(
            const ItemOutcome(correct: true, attempts: 1, hintsUsed: 0,
                duration: Duration.zero))),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          switch (widget.level) {
            2 => 'Drag the right word into the blank ✋',
            3 => 'Type the missing word ⌨️',
            _ => 'Which word fits? 🧩',
          },
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, color: AppColors.soft, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        _sentenceCard(q),
        if (_hints >= 1 && !_done) ...[
          const SizedBox(height: 10),
          _clue('Clue: ${widget.entry.meaning}'),
        ],
        if (_hints >= 2 && widget.level == 3 && !_done) ...[
          const SizedBox(height: 8),
          _clue('It starts with "${q.answer[0]}" and has ${q.answer.length} letters'),
        ],
        const SizedBox(height: 18),
        if (!_done) ...[
          if (_lastWrong != null) ...[
            const FeedbackBanner(good: false, message: "Nice try! Let's try again! 💪"),
            const SizedBox(height: 12),
          ],
          switch (widget.level) {
            2 => _dragBank(q),
            3 => _typing(),
            _ => _choices(q),
          },
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              key: const ValueKey('fill-hint'),
              onPressed: (_hints >= 1 && widget.level != 3) || _hints >= 2 ? null : _hint,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Need a hint?'),
            ),
          ),
        ] else
          _result(q),
      ],
    );
  }

  Widget _clue(String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.sunny.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text('💡 $text',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      );

  Widget _sentenceCard(BlankQuestion q) {
    final shownWord = _done ? q.answer : null;
    final color = !_done
        ? AppColors.purple
        : _correct
            ? AppColors.right
            : AppColors.tryAgain;
    const style = TextStyle(fontSize: 30, height: 1.6, color: AppColors.ink);
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 12, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: _done ? q.fullSentence : q.parts.map((p) => p.isBlank ? ' blank ' : p.text).join(),
              excludeSemantics: true,
              child: Text.rich(
                TextSpan(style: style, children: [
                  for (final p in q.parts)
                    if (p.isBlank)
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: _blank(q, shownWord, color),
                      )
                    else
                      TextSpan(text: p.text),
                ]),
              ),
            ),
          ),
          SpeakButton(
            text: _done
                ? q.fullSentence
                : q.parts.map((p) => p.isBlank ? ' blank ' : p.text).join(),
            size: 48,
            tooltip: 'Read the sentence',
          ),
        ],
      ),
    );
  }

  Widget _blank(BlankQuestion q, String? shownWord, Color color) {
    final width = (q.answer.length * 18.0 + 40).clamp(80.0, 260.0);
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      constraints: BoxConstraints(minWidth: width),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color, width: 4)),
        color: shownWord == null ? color.withValues(alpha: 0.08) : color.withValues(alpha: 0.15),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Text(
        shownWord ?? ' ',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: color),
      ),
    );
    if (widget.level != 2 || _done) return box;
    return DragTarget<String>(
      key: const ValueKey('drop-blank'),
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) => _submit(d.data),
      builder: (context, candidates, rejected) => candidates.isEmpty
          ? box
          : Container(
              decoration: BoxDecoration(
                color: AppColors.sunny.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: box,
            ),
    );
  }

  Widget _choices(BlankQuestion q) {
    return LayoutBuilder(builder: (context, box) {
      final cols = box.maxWidth > 520 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: cols == 4 ? 1.8 : 2.4,
        children: [
          for (final c in q.choices)
            _WordButton(
              key: ValueKey('choice-$c'),
              label: c,
              enabled: !_wrongPicks.contains(c),
              wrong: _wrongPicks.contains(c),
              onTap: () => _submit(c),
            ),
        ],
      );
    });
  }

  Widget _dragBank(BlankQuestion q) {
    return Column(
      children: [
        const Text('Word bank — drag a word, or tap it',
            style: TextStyle(fontSize: 16, color: AppColors.soft)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in q.choices)
              if (_wrongPicks.contains(c))
                _WordChip(label: c, faded: true)
              else
                Draggable<String>(
                  key: ValueKey('drag-$c'),
                  data: c,
                  feedback: Material(
                    color: Colors.transparent,
                    child: _WordChip(label: c, lifted: true),
                  ),
                  childWhenDragging: _WordChip(label: c, faded: true),
                  child: Semantics(
                    button: true,
                    label: 'Put $c in the blank',
                    excludeSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _submit(c),
                      child: _WordChip(label: c),
                    ),
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _typing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WriteBox(
          controller: _typed,
          focusNode: _focus,
          onSubmit: _submit,
          showTiles: AppScope.of(context).settings.letterTiles,
          hint: 'Type the missing word',
        ),
        const SizedBox(height: 12),
        BigButton(
          key: const ValueKey('fill-check'),
          label: 'Check',
          emoji: '✅',
          color: AppColors.right,
          onPressed: () => _submit(_typed.text),
        ),
      ],
    );
  }

  Widget _result(BlankQuestion q) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_correct) ...[
              FeedbackBanner(
                good: true,
                message: 'Wonderful! You found the missing word! 🌟',
                detail: q.fullSentence,
              ),
              const SizedBox(height: 10),
              Center(child: StarReward(count: _attempts == 1 && _hints == 0 ? 2 : 1)),
            ] else
              FeedbackBanner(
                good: false,
                message: 'The missing word is "${q.answer}".',
                detail: '"${widget.entry.word}" means: ${widget.entry.meaning}\n${q.fullSentence}',
              ),
            const SizedBox(height: 16),
            BigButton(
              key: const ValueKey('fill-next'),
              label: 'Next',
              emoji: '➡️',
              onPressed: _finish,
            ),
          ],
        ),
        if (_correct) const Positioned.fill(child: Confetti(pieces: 40)),
      ],
    );
  }
}

class _WordButton extends StatelessWidget {
  const _WordButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.wrong,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final bool wrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: wrong ? const Color(0xFFF1EEF6) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: enabled ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: enabled ? onTap : null,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                wrong ? '✖ $label' : label,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: wrong ? AppColors.soft : AppColors.deepPurple,
                  decoration: wrong ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.label, this.faded = false, this.lifted = false});
  final String label;
  final bool faded;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: faded ? const Color(0xFFEDEAF3) : AppColors.purple,
        borderRadius: BorderRadius.circular(18),
        boxShadow: lifted
            ? const [BoxShadow(color: Color(0x44000000), blurRadius: 16, offset: Offset(0, 8))]
            : null,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: faded ? AppColors.soft : Colors.white)),
    );
  }
}
