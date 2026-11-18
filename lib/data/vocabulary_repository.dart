import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/vocab_entry.dart';

/// Loads the 1,165 words shipped with the app and splits them into lessons.
class VocabularyRepository {
  VocabularyRepository(List<VocabEntry> entries)
      : all = List.unmodifiable(entries),
        _byId = {for (final e in entries) e.id: e} {
    for (final g in const [1, 2]) {
      final words = entries.where((e) => e.grade == g).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      _lessons[g] = buildLessons(g, words);
    }
  }

  static const expectedCounts = {1: 339, 2: 826};
  static const assetPaths = {
    1: 'assets/vocabulary/grade1.json',
    2: 'assets/vocabulary/grade2.json',
  };

  final List<VocabEntry> all;
  final Map<String, VocabEntry> _byId;
  final Map<int, List<Lesson>> _lessons = {};

  static Future<VocabularyRepository> loadFromAssets() async {
    final entries = <VocabEntry>[];
    for (final path in assetPaths.values) {
      entries.addAll(parse(await rootBundle.loadString(path)));
    }
    return VocabularyRepository(entries);
  }

  static List<VocabEntry> parse(String json) => (jsonDecode(json) as List)
      .map((e) => VocabEntry.fromJson(e as Map<String, dynamic>))
      .toList();

  VocabEntry? byId(String id) => _byId[id];
  List<VocabEntry> grade(int g) => all.where((e) => e.grade == g).toList();
  List<Lesson> lessons(int g) => _lessons[g] ?? const [];

  Lesson? lessonOf(VocabEntry e) {
    for (final l in lessons(e.grade)) {
      if (l.words.any((w) => w.id == e.id)) return l;
    }
    return null;
  }

  /// Splits words (already in order) into lessons of 10-15 words, as even as
  /// possible, never changing the order.
  static List<Lesson> buildLessons(int grade, List<VocabEntry> words,
      {int target = 12}) {
    if (words.isEmpty) return const [];
    final count = (words.length / target).ceil();
    final base = words.length ~/ count;
    final extra = words.length % count;
    final lessons = <Lesson>[];
    var i = 0;
    for (var n = 0; n < count; n++) {
      final size = base + (n < extra ? 1 : 0);
      lessons.add(Lesson(
          grade: grade, number: n + 1, words: words.sublist(i, i + size)));
      i += size;
    }
    return lessons;
  }

  /// Problems found in the loaded data (empty when everything is fine).
  List<String> validate() {
    final problems = <String>[];
    for (final g in const [1, 2]) {
      final n = grade(g).length;
      if (n != expectedCounts[g]) {
        problems.add('Grade $g has $n words (expected ${expectedCounts[g]}).');
      }
    }
    final ids = <String>{};
    for (final e in all) {
      if (!ids.add(e.id)) problems.add('Duplicate id ${e.id}.');
      if (e.word.trim().isEmpty ||
          e.meaning.trim().isEmpty ||
          e.example.trim().isEmpty) {
        problems.add('${e.id} is missing its word, meaning or example.');
      }
    }
    return problems;
  }
}
