import 'package:flutter/material.dart';

import '../../core/word_sets.dart';
import '../../models/activity.dart';
import '../../models/vocab_entry.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/flip_card.dart';
import '../../widgets/mascot.dart';

/// Traditional flashcards: word on the front, meaning and sentence on the
/// back, then "I Know It!" or "Practice Again".
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, required this.words, this.title = 'Flashcards'});
  final List<VocabEntry> words;
  final String title;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  int _index = 0;
  bool _back = false;
  int _known = 0;
  final List<String> _practice = [];
  bool _finished = false;

  VocabEntry get _e => widget.words[_index];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _readFront());
  }

  void _readFront() {
    if (!mounted || widget.words.isEmpty || _finished) return;
    final app = AppScope.read(context);
    if (app.settings.autoRead) app.speech.word(_e);
  }

  void _flip() {
    setState(() => _back = !_back);
    final app = AppScope.read(context);
    if (_back && app.settings.autoRead) {
      app.speech.speak('${_e.word}. ${_e.meaning} For example: ${_e.example}');
    }
  }

  void _answer(bool known) {
    final app = AppScope.read(context);
    app.recordFlashcard(_e, known);
    if (known) {
      _known++;
    } else {
      _practice.add(_e.id);
    }
    if (_index + 1 >= widget.words.length) {
      app.finishSession(
        SessionSummary(
          title: widget.title,
          total: widget.words.length,
          correct: _known,
          firstTry: _known,
          missedIds: _practice,
        ),
        'flashcards',
      );
      setState(() => _finished = true);
      app.speech.speak('All done! Great job!');
    } else {
      setState(() {
        _index++;
        _back = false;
      });
      _readFront();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.words.length;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: total == 0
            ? const Center(child: Text('No cards here yet!', style: TextStyle(fontSize: 22)))
            : _finished
                ? _done()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    child: ContentWidth(
                      maxWidth: 680,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(child: SoftProgressBar(value: _index / total, color: AppColors.sky)),
                            const SizedBox(width: 12),
                            Text('${_index + 1} / $total',
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                          ]),
                          const SizedBox(height: 18),
                          FlipCard(
                            key: ValueKey(_e.id),
                            showBack: _back,
                            onTap: _flip,
                            front: _front(),
                            back: _backFace(),
                          ),
                          const SizedBox(height: 16),
                          if (!_back)
                            BigButton(
                              key: const ValueKey('flash-flip'),
                              label: 'Flip to see the meaning',
                              emoji: '🔄',
                              color: AppColors.sky,
                              onPressed: _flip,
                            )
                          else
                            Row(children: [
                              Expanded(
                                child: BigButton(
                                  key: const ValueKey('flash-practice'),
                                  label: 'Practice Again',
                                  emoji: '🔁',
                                  color: AppColors.tryAgain,
                                  fontSize: 18,
                                  onPressed: () => _answer(false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: BigButton(
                                  key: const ValueKey('flash-known'),
                                  label: 'I Know It!',
                                  emoji: '⭐',
                                  color: AppColors.right,
                                  fontSize: 18,
                                  onPressed: () => _answer(true),
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

  Widget _front() {
    final pic = pictureWords[_e.word.toLowerCase()];
    return CardFace(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (pic != null)
          ExcludeSemantics(child: Text(pic, style: const TextStyle(fontSize: 64))),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(_e.word,
              style: const TextStyle(
                  fontSize: 72, fontWeight: FontWeight.w900, color: AppColors.deepPurple)),
        ),
        const SizedBox(height: 12),
        SpeakButton(text: _e.word, tooltip: 'Hear the word'),
        const SizedBox(height: 12),
        const Text('Tap the card to flip it',
            style: TextStyle(color: AppColors.soft, fontSize: 16)),
      ]),
    );
  }

  Widget _backFace() {
    return CardFace(
      color: const Color(0xFFEAF6FF),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(_e.word,
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.deepPurple)),
            ),
            SpeakButton(text: _e.word, size: 48, tooltip: 'Hear the word'),
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(_e.meaning, style: const TextStyle(fontSize: 24, height: 1.3))),
            SpeakButton(text: '${_e.word}. ${_e.meaning}', size: 44, tooltip: 'Read the meaning'),
          ]),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text('"${_e.example}"',
                  style: const TextStyle(
                      fontSize: 21, fontStyle: FontStyle.italic, color: AppColors.soft)),
            ),
            SpeakButton(text: _e.example, size: 44, tooltip: 'Read the sentence'),
          ]),
        ],
      ),
    );
  }

  Widget _done() {
    return Stack(children: [
      Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Mascot(mood: MascotMood.cheer, size: 140),
            const SizedBox(height: 10),
            const Text('All done!', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('⭐ You know $_known words', style: const TextStyle(fontSize: 22)),
            Text('🔁 ${_practice.length} to practice again', style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 24),
            BigButton(label: 'Done', emoji: '🎉', onPressed: () => Navigator.pop(context)),
          ]),
        ),
      ),
      const Positioned.fill(child: Confetti()),
    ]);
  }
}
