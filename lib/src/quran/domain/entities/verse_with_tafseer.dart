class VerseWithTafseer {
  const VerseWithTafseer({
    required this.chapterId,
    required this.verseId,
    required this.text,
    required this.translation,
    required this.tafseer,
  });

  final int chapterId;
  final int verseId;

  /// Arabic text.
  final String text;

  /// Translated text.
  final String translation;

  /// Tafseer commentary text.
  final String tafseer;

  @override
  String toString() => 'VerseWithTafseer($chapterId:$verseId)';
}
