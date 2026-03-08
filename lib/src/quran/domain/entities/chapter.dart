class Chapter {
  const Chapter({
    required this.id,
    required this.name,
    required this.transliteration,
    required this.type,
    required this.totalVerses,
  });

  final int id;

  /// Arabic name, e.g. "الفاتحة"
  final String name;

  /// English transliteration, e.g. "Al-Fatihah"
  final String transliteration;

  /// Revelation type: "meccan" or "medinan"
  final String type;

  final int totalVerses;

  @override
  String toString() => 'Chapter($id: $transliteration, $totalVerses verses)';
}
