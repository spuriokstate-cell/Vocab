import 'package:flutter/material.dart';

import '../../core/text_utils.dart';
import '../../models/activity.dart';
import '../../models/vocab_entry.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/write_box.dart';

/// Spelling Challenge: hear the word (with its sentence) and spell it.
class SpellingQuestion extends StatefulWidget {
  const SpellingQuestion({super.key, required this.entry, required this.onDone});
  final VocabEntry entry;
  final ValueChanged<ItemOutcome> onDone;

  @override
  State<SpellingQuestion> createState() => _SpellingQuestionState();
}

class _SpellingQuestionState extends State<SpellingQuestion> {
  final _typed = TextEditingController();
  final _focus = FocusNode();
  final _started = DateTime.now();
  int _attempts = 0;
  int _hints = 0;
  bool _done = false;
  bool _correct = false;
  bool _tiles = false;
  bool _wrongShown = false;

  VocabEntry get e => widget.entry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = AppScope.read(context);
      setState(() => _tiles = app.settings.letterTiles);
      app.speech.wordInContext(e);
      _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _typed.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _check() {
    if (_done || normalizeAnswer(_typed.text).isEmpty) return;
    _attempts++;
    final app = AppScope.read(context);
    if (answerMatches(_typed.text, e.word)) {
      setState(() {
        _done = true;
        _correct = true;
      });
      app.speech.speak('Perfect spelling! ${e.word}.');
    } else if (_attempts >= 3) {
      setState(() => _done = true);
      app.speech.speak('${e.word} is spelled ${e.word.split('').join(', ')}.');
    } else {
      setState(() => _wrongShown = true);
      app.speech.speak("Good try! Let's try again!");
      _typed.selection = TextSelection(baseOffset: 0, extentOffset: _typed.text.length);
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(children: [
            const Text('🐝 Listen, then spell the word',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            SpeakButton(
                text: '${e.word}. As in: ${e.example} ... ${e.word}.',
                size: 84,
                tooltip: 'Hear the word'),
            if (_hints >= 1 && !_done) ...[
              const SizedBox(height: 12),
              Text('💡 It starts with "${e.word[0]}" and has ${e.word.length} letters',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        if (!_done) ...[
          WriteBox(controller: _typed, focusNode: _focus, onSubmit: (_) => _check(), showTiles: _tiles),
          const SizedBox(height: 12),
          if (_wrongShown) ...[
            const FeedbackBanner(good: false, message: "Good try! Let's try again! 💪"),
            const SizedBox(height: 12),
          ],
          BigButton(
              key: const ValueKey('spell-check'),
              label: 'Check',
              emoji: '✅',
              color: AppColors.right,
              onPressed: _check),
          const SizedBox(height: 8),
          Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            TextButton.icon(
              onPressed: _hints >= 1 ? null : () => setState(() => _hints++),
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Hint'),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _tiles = !_tiles),
              icon: const Icon(Icons.grid_view_rounded),
              label: Text(_tiles ? 'Hide letter tiles' : 'Letter tiles'),
            ),
          ]),
        ] else ...[
          FeedbackBanner(
            good: _correct,
            message: _correct ? 'Perfect spelling! 🐝' : 'This is how we spell it:',
            detail: _correct ? null : e.word,
          ),
          if (_correct) ...[
            const SizedBox(height: 8),
            Center(child: StarReward(count: _attempts == 1 && _hints == 0 ? 2 : 1)),
          ],
          const SizedBox(height: 12),
          BigButton(
            key: const ValueKey('spell-next'),
            label: 'Next',
            emoji: '➡️',
            onPressed: () => widget.onDone(ItemOutcome(
                correct: _correct,
                attempts: _attempts,
                hintsUsed: _hints,
                duration: DateTime.now().difference(_started))),
          ),
        ],
      ],
    );
  }
}

/// Word Scramble: tap the mixed-up letters in the right order.
class ScrambleQuestion extends StatefulWidget {
  const ScrambleQuestion({super.key, required this.entry, required this.onDone});
  final VocabEntry entry;
  final ValueChanged<ItemOutcome> onDone;

  @override
  State<ScrambleQuestion> createState() => _ScrambleQuestionState();
}

class _ScrambleQuestionState extends State<ScrambleQuestion> {
  late List<String> _letters; // scrambled letters
  final List<int> _picked = []; // indexes into _letters, in order chosen
  bool _built = false;
  final _started = DateTime.now();
  int _attempts = 0;
  int _hints = 0;
  bool _done = false;
  bool _correct = false;
  bool _wrongShown = false;

  VocabEntry get e => widget.entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_built) return;
    _built = true;
    final app = AppScope.read(context);
    _letters = app.engine.scrambled(e);
    if (app.settings.autoRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) app.speech.speak('Unscramble the letters to make the word. ${e.meaning}');
      });
    }
  }

  void _tapLetter(int i) {
    if (_done || _picked.contains(i)) return;
    setState(() {
      _picked.add(i);
      _wrongShown = false;
    });
    if (_picked.length == _letters.length) _check();
  }

  void _undo(int slot) {
    if (_done) return;
    setState(() => _picked.removeRange(slot, _picked.length));
  }

  void _hint() {
    // Place the correct letters at the start of the answer.
    final word = e.word;
    final want = _hints + 1;
    if (want > word.length - 1) return;
    final used = <int>{};
    final fixed = <int>[];
    for (var k = 0; k < want; k++) {
      final idx = List.generate(_letters.length, (i) => i).firstWhere(
          (i) => !used.contains(i) && _letters[i].toLowerCase() == word[k].toLowerCase(),
          orElse: () => -1);
      if (idx < 0) return;
      used.add(idx);
      fixed.add(idx);
    }
    setState(() {
      _hints++;
      _picked
        ..clear()
        ..addAll(fixed);
    });
  }

  void _check() {
    _attempts++;
    final built = _picked.map((i) => _letters[i]).join();
    final app = AppScope.read(context);
    if (answerMatches(built, e.word)) {
      setState(() {
        _done = true;
        _correct = true;
      });
      app.speech.speak('You did it! ${e.word}.');
    } else if (_attempts >= 3) {
      setState(() => _done = true);
      app.speech.speak('The word is ${e.word}.');
    } else {
      setState(() {
        _wrongShown = true;
        _picked.clear();
      });
      app.speech.speak("Good try! Let's try again!");
    }
  }

  String _slotLetter(int s) {
    if (_done && !_correct) return s < e.word.length ? e.word[s] : '';
    return s < _picked.length ? _letters[_picked[s]] : '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
          child: Column(children: [
            const Text('🔀 Unscramble the word',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Text('Clue: ${e.meaning}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: AppColors.soft)),
              ),
              SpeakButton(text: e.meaning, size: 44, tooltip: 'Read the clue'),
            ]),
          ]),
        ),
        const SizedBox(height: 18),
        // Answer slots.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var s = 0; s < _letters.length; s++)
              _LetterBox(
                key: ValueKey('slot-$s'),
                letter: _slotLetter(s),
                color: _done ? (_correct ? AppColors.right : AppColors.tryAgain) : AppColors.purple,
                filled: _slotLetter(s).isNotEmpty,
                onTap: s < _picked.length && !_done ? () => _undo(s) : null,
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (!_done) ...[
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _letters.length; i++)
                _LetterBox(
                  key: ValueKey('tile-$i'),
                  letter: _letters[i],
                  color: _picked.contains(i) ? const Color(0xFFDDD8E6) : AppColors.coral,
                  filled: !_picked.contains(i),
                  onTap: _picked.contains(i) ? null : () => _tapLetter(i),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_wrongShown) ...[
            const FeedbackBanner(good: false, message: "Good try! Let's try again! 💪"),
            const SizedBox(height: 8),
          ],
          Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
            OutlinedButton.icon(
              onPressed: () => setState(() => _picked.clear()),
              icon: const Icon(Icons.refresh),
              label: const Text('Start over'),
            ),
            OutlinedButton.icon(
              onPressed: _hints + 1 >= e.word.length ? null : _hint,
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Hint'),
            ),
          ]),
        ] else ...[
          FeedbackBanner(
            good: _correct,
            message: _correct ? 'You did it! 🎉' : 'The word is "${e.word}".',
          ),
          if (_correct) Center(child: StarReward(count: _attempts == 1 && _hints == 0 ? 2 : 1)),
          const SizedBox(height: 12),
          BigButton(
            key: const ValueKey('scramble-next'),
            label: 'Next',
            emoji: '➡️',
            onPressed: () => widget.onDone(ItemOutcome(
                correct: _correct,
                attempts: _attempts,
                hintsUsed: _hints,
                duration: DateTime.now().difference(_started))),
          ),
        ],
      ],
    );
  }
}

class _LetterBox extends StatelessWidget {
  const _LetterBox({
    super.key,
    required this.letter,
    required this.color,
    required this.filled,
    this.onTap,
  });

  final String letter;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: letter.isEmpty ? 'empty space' : 'letter $letter',
      excludeSemantics: true,
      child: Material(
        color: filled ? color : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: filled ? BorderSide.none : BorderSide(color: color, width: 3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 58,
            child: Center(
              child: Text(letter,
                  style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: filled ? Colors.white : AppColors.ink)),
            ),
          ),
        ),
      ),
    );
  }
}
