/// One vocabulary word from the PDF, exactly as written there.
class VocabEntry {
  const VocabEntry({
    required this.id,
    required this.grade,
    required this.order,
    required this.word,
    required this.meaning,
    required this.example,
  });

  /// e.g. "g1_0008" (grade 1, 8th word in the original list).
  final String id;
  final int grade;
  final int order;
  final String word;
  final String meaning;
  final String example;

  factory VocabEntry.fromJson(Map<String, dynamic> j) => VocabEntry(
        id: j['id'] as String,
        grade: (j['grade'] as num).toInt(),
        order: (j['order'] as num).toInt(),
        word: j['word'] as String,
        meaning: j['meaning'] as String,
        example: j['example'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'grade': grade,
        'order': order,
        'word': word,
        'meaning': meaning,
        'example': example,
      };

  @override
  String toString() => 'VocabEntry($id, $word)';
}

/// A small group of 10-15 words in their original order.
class Lesson {
  const Lesson({
    required this.grade,
    required this.number,
    required this.words,
  });

  final int grade;

  /// 1-based lesson number within the grade.
  final int number;
  final List<VocabEntry> words;

  String get id => 'g${grade}_l$number';
  String get title => 'Lesson $number';
  String get preview => words.take(3).map((w) => w.word).join(', ');
}
