import 'package:flutter/material.dart';

import '../../core/word_sets.dart';
import '../../models/activity.dart';
import '../../models/vocab_entry.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Multiple-choice games: Word to Meaning, Meaning to Word, Listen & Choose
/// and Picture to Word. Two wrong tries, then the answer is shown.
class ChoiceQuestion extends StatefulWidget {
  const ChoiceQuestion({
    super.key,
    required this.type,
    required this.entry,
    required this.onDone,
  });

  final ActivityType type;
  final VocabEntry entry;
  final ValueChanged<ItemOutcome> onDone;

  @override
  State<ChoiceQuestion> createState() => _ChoiceQuestionState();
}

class _ChoiceQuestionState extends State<ChoiceQuestion> {
  late List<String> _options;
  bool _built = false;
  final Set<String> _wrong = {};
  final _started = DateTime.now();
  int _attempts = 0;
  bool _done = false;
  bool _correct = false;

  VocabEntry get e => widget.entry;
  String get _answer =>
      widget.type == ActivityType.wordToMeaning ? e.meaning : e.word;
  bool get _longOptions => widget.type == ActivityType.wordToMeaning;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_built) return;
    _built = true;
    final app = AppScope.read(context);
    final engine = app.engine;
    _options = switch (widget.type) {
      ActivityType.wordToMeaning => engine.meaningChoices(e),
      ActivityType.listenChoose => engine.listeningChoices(e),
      ActivityType.picture => engine.pictureChoices(e),
      _ => engine.wordChoicesForMeaning(e),
    };
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (widget.type) {
        case ActivityType.listenChoose:
          app.speech.word(e);
        case ActivityType.meaningToWord:
          if (app.settings.autoRead) app.speech.speak(e.meaning);
        case ActivityType.wordToMeaning:
          if (app.settings.autoRead) app.speech.speak('What does ${e.word} mean?');
        default:
          if (app.settings.autoRead) app.speech.speak('Which word matches the picture?');
      }
    });
  }

  void _pick(String option) {
    if (_done) return;
    _attempts++;
    final app = AppScope.read(context);
    if (option == _answer) {
      setState(() {
        _done = true;
        _correct = true;
      });
      app.speech.speak('Great job! ${e.word}.');
    } else {
      setState(() {
        _wrong.add(option);
        if (_attempts >= 2) _done = true;
      });
      app.speech.speak(_done ? 'The answer is ${e.word}.' : "Nice try! Let's try again!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _prompt(),
        const SizedBox(height: 18),
        if (!_done && _wrong.isNotEmpty) ...[
          const FeedbackBanner(good: false, message: "Nice try! Let's try again! 💪"),
          const SizedBox(height: 12),
        ],
        if (_longOptions)
          ...[
            for (final o in _options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionTile(
                  key: ValueKey('opt-$o'),
                  text: o,
                  big: false,
                  state: _stateOf(o),
                  onTap: () => _pick(o),
                ),
              ),
          ]
        else
          LayoutBuilder(builder: (context, box) {
            final cols = box.maxWidth > 520 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: cols == 4 ? 1.8 : 2.4,
              children: [
                for (final o in _options)
                  _OptionTile(
                    key: ValueKey('opt-$o'),
                    text: o,
                    big: true,
                    state: _stateOf(o),
                    onTap: () => _pick(o),
                  ),
              ],
            );
          }),
        if (_done) ...[
          const SizedBox(height: 16),
          _correct
              ? const FeedbackBanner(good: true, message: 'Great job! ⭐')
              : FeedbackBanner(
                  good: false,
                  message: 'The answer is "${e.word}".',
                  detail: '${e.word}: ${e.meaning}'),
          const SizedBox(height: 12),
          BigButton(
            key: const ValueKey('choice-next'),
            label: 'Next',
            emoji: '➡️',
            onPressed: () => widget.onDone(ItemOutcome(
              correct: _correct,
              attempts: _attempts,
              hintsUsed: 0,
              duration: DateTime.now().difference(_started),
            )),
          ),
        ],
      ],
    );
  }

  _OptState _stateOf(String o) {
    if (_done && o == _answer) return _OptState.right;
    if (_wrong.contains(o)) return _OptState.wrong;
    if (_done) return _OptState.faded;
    return _OptState.idle;
  }

  Widget _prompt() {
    switch (widget.type) {
      case ActivityType.wordToMeaning:
        return _PromptCard(
          title: 'What does this word mean?',
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(
              child: Text(e.word,
                  style: const TextStyle(
                      fontSize: 56, fontWeight: FontWeight.w900, color: AppColors.deepPurple)),
            ),
            const SizedBox(width: 12),
            SpeakButton(text: e.word, tooltip: 'Hear the word'),
          ]),
        );
      case ActivityType.listenChoose:
        return _PromptCard(
          title: 'Listen and tap the word you hear',
          child: SpeakButton(text: e.word, size: 96, tooltip: 'Play the word again'),
        );
      case ActivityType.picture:
        return _PromptCard(
          title: 'Which word matches the picture?',
          child: Semantics(
            label: 'Picture',
            excludeSemantics: true,
            child: Text(pictureWords[e.word.toLowerCase()] ?? '❓',
                style: const TextStyle(fontSize: 110)),
          ),
        );
      default:
        return _PromptCard(
          title: 'Which word has this meaning?',
          child: Row(children: [
            Expanded(
              child: Text(e.meaning,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, height: 1.35, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            SpeakButton(text: e.meaning, size: 48, tooltip: 'Read the meaning'),
          ]),
        );
    }
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, color: AppColors.soft, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

enum _OptState { idle, right, wrong, faded }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    super.key,
    required this.text,
    required this.big,
    required this.state,
    required this.onTap,
  });

  final String text;
  final bool big;
  final _OptState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (state) {
      _OptState.idle => (Colors.white, AppColors.deepPurple),
      _OptState.right => (AppColors.right, Colors.white),
      _OptState.wrong => (const Color(0xFFF1EEF6), AppColors.soft),
      _OptState.faded => (const Color(0xFFF7F5FA), const Color(0xFFB9B3C7)),
    };
    final label = switch (state) {
      _OptState.right => '✅ $text',
      _OptState.wrong => '✖ $text',
      _ => text,
    };
    final textWidget = Text(label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: big ? 26 : 19,
          fontWeight: big ? FontWeight.w800 : FontWeight.w600,
          color: fg,
          decoration: state == _OptState.wrong ? TextDecoration.lineThrough : null,
        ));
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      elevation: state == _OptState.idle ? 2 : 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: state == _OptState.idle ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Center(
            child: big ? FittedBox(fit: BoxFit.scaleDown, child: textWidget) : textWidget,
          ),
        ),
      ),
    );
  }
}
