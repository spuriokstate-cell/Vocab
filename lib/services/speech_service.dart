import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models/vocab_entry.dart';

/// Reads words and sentences aloud using the device's own offline voice
/// (Android, iOS and Windows all include one). No internet needed.
abstract class SpeechService {
  bool enabled = true;
  double rate = 0.42;

  Future<void> speak(String text);
  Future<void> stop();

  /// Say just the word.
  Future<void> word(VocabEntry e) => speak(e.word);

  /// Say the word with its sentence, so sound-alike words (write / right)
  /// are clear when the child has to spell from hearing.
  Future<void> wordInContext(VocabEntry e) =>
      speak('${e.word}. As in: ${e.example} ... ${e.word}.');

  Future<void> meaning(VocabEntry e) => speak('${e.word}. ${e.meaning}');
  Future<void> sentence(VocabEntry e) => speak(e.example);
}

class DeviceSpeechService extends SpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.setLanguage('en-US');
    } catch (_) {/* some Windows voices don't support switching language */}
    try {
      await _tts.setPitch(1.1); // a little brighter, friendlier for kids
      await _tts.setVolume(1.0);
    } catch (_) {}
  }

  @override
  Future<void> speak(String text) async {
    if (!enabled || text.trim().isEmpty) return;
    try {
      await _init();
      await _tts.stop();
      await _tts.setSpeechRate(rate);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('Speech unavailable: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}

/// Used in tests and when the device has no voice: records what would be said.
class SilentSpeechService extends SpeechService {
  final List<String> spoken = [];

  @override
  Future<void> speak(String text) async {
    if (enabled) spoken.add(text);
  }

  @override
  Future<void> stop() async {}
}
