import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/text_utils.dart';
import '../../models/activity.dart';
import '../../models/vocab_entry.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/flip_card.dart';
import '../../widgets/mascot.dart';
import '../../widgets/write_box.dart';

/// Which memory mode to use.
enum FlipWriteMode {
  look, // Mode A: see the word, flip, write
  listen, // Mode B: hear the word, write
  memory; // Mode C: see the word for a few seconds, card flips by itself

  static FlipWriteMode of(ActivityType t) => switch (t) {
        ActivityType.listenWrite => FlipWriteMode.listen,
        ActivityType.memoryWrite => FlipWriteMode.memory,
        _ => FlipWriteMode.look,
      };
}

enum _Stage { study, write, correct, meaning }

/// LOOK → FLIP → WRITE → CHECK, then learn the meaning.
class FlipWriteQuestion extends StatefulWidget {
  const FlipWriteQuestion({
    super.key,
    required this.entry,
    required this.mode,
    required this.onDone,
  });

  final VocabEntry entry;
  final FlipWriteMode mode;
  final ValueChanged<ItemOutcome> onDone;

  @override
  State<FlipWriteQuestion> createState() => _FlipWriteQuestionState();
}

class _FlipWriteQuestionState extends State<FlipWriteQuestion> {
  final _answer = TextEditingController();
  final _focus = FocusNode();
  final _started = DateTime.now();
  Timer? _memoryTimer;

  _Stage _stage = _Stage.study;
  int _attempts = 0;
  int _hintLevel = 0; // 0 none, 1 first letter, 2 letter count, 3 peeked
  int _hintsUsed = 0;
  bool _wrongShown = false;
  bool _revealed = false; // child asked to see the answer after trying
  bool _tilesOn = false;

  VocabEntry get e => widget.entry;
  bool get _listen => widget.mode == FlipWriteMode.listen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStudy());
  }

  void _startStudy() {
    if (!mounted) return;
    final app = AppScope.read(context);
    _tilesOn = app.settings.letterTiles;
    if (_listen) {
      app.speech.wordInContext(e);
    } else if (app.settings.autoRead) {
      app.speech.word(e);
    }
    if (widget.mode == FlipWriteMode.memory) {
      _memoryTimer?.cancel();
      _memoryTimer = Timer(Duration(seconds: app.settings.memorySeconds), () {
        if (mounted && _stage == _Stage.study) _flip();
      });
    }
    setState(() {});
  }

  @override
  void dispose() {
    _memoryTimer?.cancel();
    _answer.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _flip() {
    _memoryTimer?.cancel();
    setState(() => _stage = _Stage.write);
    // Give the flip a moment, then put the cursor in the box.
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted && _stage == _Stage.write) _focus.requestFocus();
    });
  }

  void _showWordAgain() {
    _hintsUsed++;
    _hintLevel = _hintLevel < 3 ? 3 : _hintLevel;
    setState(() => _stage = _Stage.study);
    final app = AppScope.read(context);
    if (_listen) app.speech.wordInContext(e);
  }

  void _nextHint() {
    if (_hintLevel >= 2) {
      _showWordAgain();
      return;
    }
    setState(() {
      _hintLevel++;
      _hintsUsed++;
    });
  }

  void _check() {
    if (normalizeAnswer(_answer.text).isEmpty) {
      _focus.requestFocus();
      return;
    }
    _attempts++;
    final app = AppScope.read(context);
    if (answerMatches(_answer.text, e.word)) {
      setState(() => _stage = _Stage.correct);
      app.speech.speak('Excellent! You remembered the word! ${e.word}.');
    } else {
      setState(() => _wrongShown = true);
      app.speech.speak("Good try! Let's try again!");
      _answer.selection =
          TextSelection(baseOffset: 0, extentOffset: _answer.text.length);
      _focus.requestFocus();
    }
  }

  void _giveUp() {
    _revealed = true;
    setState(() => _stage = _Stage.meaning);
    AppScope.read(context).speech.meaning(e);
  }

  void _toMeaning() {
    setState(() => _stage = _Stage.meaning);
    final app = AppScope.read(context);
    if (app.settings.autoRead) {
      app.speech.speak('${e.word}. ${e.meaning} For example: ${e.example}');
    }
  }

  void _finish() {
    widget.onDone(ItemOutcome(
      correct: !_revealed,
      attempts: _attempts == 0 ? 1 : _attempts,
      hintsUsed: _hintsUsed,
      duration: DateTime.now().difference(_started),
    ));
  }

  // -------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    if (_stage == _Stage.meaning) return _meaningCard();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FlipCard(
          showBack: _stage != _Stage.study,
          onTap: _stage == _Stage.study ? _flip : null,
          front: _front(),
          back: _back(),
        ),
        const SizedBox(height: 20),
        if (_stage == _Stage.study) _studyControls(),
        if (_stage == _Stage.write) _writeControls(),
        if (_stage == _Stage.correct) _correctControls(),
      ],
    );
  }

  Widget _front() {
    if (_listen) {
      return CardFace(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎧', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 8),
            const Text('Listen carefully!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            SpeakButton(
                text: '${e.word}. As in: ${e.example} ... ${e.word}.',
                size: 72,
                tooltip: 'Hear the word'),
            if (_hintLevel >= 3) ...[
              const SizedBox(height: 16),
              Text(e.word,
                  style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: AppColors.deepPurple)),
            ],
          ],
        ),
      );
    }
    final memory = widget.mode == FlipWriteMode.memory;
    return CardFace(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Mascot(size: 64),
              SpeakButton(text: e.word, tooltip: 'Hear the word'),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              e.word,
              key: const ValueKey('study-word'),
              style: const TextStyle(
                  fontSize: 76,
                  fontWeight: FontWeight.w900,
                  color: AppColors.deepPurple,
                  letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Look carefully and remember this word!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: AppColors.soft)),
          if (memory) ...[
            const SizedBox(height: 16),
            _GentleTimer(seconds: AppScope.read(context).settings.memorySeconds),
          ],
        ],
      ),
    );
  }

  Widget _back() {
    return CardFace(
      color: const Color(0xFFF3EEFF),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_listen ? '✏️' : '🤔', style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            _listen
                ? 'Write the word you heard!'
                : 'Can you remember the word?\nWrite it below!',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          if (_listen) ...[
            const SizedBox(height: 12),
            SpeakButton(
                text: '${e.word}. As in: ${e.example} ... ${e.word}.',
                tooltip: 'Hear it again'),
          ],
          if (_hintLevel >= 1) ...[
            const SizedBox(height: 14),
            _hintChip('It starts with "${e.word[0]}"'),
          ],
          if (_hintLevel >= 2) ...[
            const SizedBox(height: 8),
            _hintChip('It has ${e.word.length} letters: '
                '${e.word[0]} ${List.filled(e.word.length - 1, '_').join(' ')}'),
          ],
        ],
      ),
    );
  }

  Widget _hintChip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.sunny.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14)),
        child: Text('💡 $text',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      );

  Widget _studyControls() {
    final again = _attempts > 0 || _hintLevel > 0;
    return BigButton(
      key: const ValueKey('flip-button'),
      label: _listen
          ? "I'm ready to write"
          : again
              ? 'Flip and try again'
              : 'Flip Card',
      emoji: _listen ? '✏️' : '🔄',
      onPressed: _flip,
    );
  }

  Widget _writeControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WriteBox(
          controller: _answer,
          focusNode: _focus,
          onSubmit: (_) => _check(),
          showTiles: _tilesOn,
        ),
        const SizedBox(height: 12),
        if (_wrongShown) ...[
          const FeedbackBanner(
              good: false, message: "Good try! Let's try again! 💪"),
          const SizedBox(height: 12),
        ],
        BigButton(
          key: const ValueKey('check-button'),
          label: 'Check Answer',
          emoji: '✅',
          color: AppColors.right,
          onPressed: _check,
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('clear-button'),
              onPressed: () {
                _answer.clear();
                _focus.requestFocus();
              },
              icon: const Icon(Icons.backspace_outlined),
              label: const Text('Clear'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('hint-button'),
              onPressed: _nextHint,
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(_hintLevel == 0
                  ? 'Hint'
                  : _hintLevel == 1
                      ? 'Another hint'
                      : 'Peek at the word'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('show-again-button'),
              onPressed: _showWordAgain,
              icon: Icon(_listen ? Icons.visibility : Icons.flip),
              label: Text(_listen ? 'Show the word' : 'Show Word Again'),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _tilesOn = !_tilesOn),
              icon: const Icon(Icons.grid_view_rounded),
              label: Text(_tilesOn ? 'Hide letter tiles' : 'Letter tiles'),
            ),
            if (_attempts >= 3)
              TextButton(
                onPressed: _giveUp,
                child: const Text('Show me the answer'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _correctControls() {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FeedbackBanner(
              good: true,
              message: 'Excellent! You remembered the word! 🎉',
              detail: _attempts == 1 && _hintsUsed == 0
                  ? 'Right on the first try!'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StarReward(count: _attempts == 1 && _hintsUsed == 0 ? 2 : 1),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(e.word,
                      key: const ValueKey('correct-word'),
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: AppColors.right)),
                ),
                const SizedBox(width: 12),
                SpeakButton(text: e.word, size: 48, color: AppColors.right),
              ],
            ),
            const SizedBox(height: 16),
            BigButton(
              key: const ValueKey('next-button'),
              label: 'Next',
              emoji: '➡️',
              onPressed: _toMeaning,
            ),
          ],
        ),
        const Positioned.fill(child: Confetti()),
      ],
    );
  }

  Widget _meaningCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_revealed)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: FeedbackBanner(
              good: false,
              message: "That's a tricky one!",
              detail: "Here's how we spell it. You'll see it again soon.",
            ),
          ),
        CardFace(
          color: const Color(0xFFFFF4DA),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(e.word,
                      key: const ValueKey('meaning-word'),
                      style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: AppColors.deepPurple)),
                ),
                SpeakButton(text: e.word, tooltip: 'Hear the word'),
              ]),
              const SizedBox(height: 16),
              _labelRow('Meaning', e.meaning, '${e.word}. ${e.meaning}'),
              const SizedBox(height: 16),
              _labelRow('Sentence', e.example, e.example),
            ],
          ),
        ),
        const SizedBox(height: 20),
        BigButton(
          key: const ValueKey('continue-button'),
          label: 'Continue',
          emoji: '⭐',
          color: AppColors.purple,
          onPressed: _finish,
        ),
      ],
    );
  }

  Widget _labelRow(String label, String text, String speak) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.soft,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(text,
                    style: const TextStyle(fontSize: 22, height: 1.35)),
              ],
            ),
          ),
          SpeakButton(text: speak, size: 44, tooltip: 'Read the $label'),
        ],
      );
}

/// A calm "almost time" bar for Memory Challenge. No numbers, no ticking.
class _GentleTimer extends StatefulWidget {
  const _GentleTimer({required this.seconds});
  final int seconds;

  @override
  State<_GentleTimer> createState() => _GentleTimerState();
}

class _GentleTimerState extends State<_GentleTimer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: Duration(seconds: widget.seconds));

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Remember it... the card will flip soon ✨',
            style: TextStyle(fontSize: 16, color: AppColors.soft)),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _c,
          builder: (context, _) => SoftProgressBar(
              value: _c.value, color: AppColors.sunny, height: 10),
        ),
      ],
    );
  }
}
