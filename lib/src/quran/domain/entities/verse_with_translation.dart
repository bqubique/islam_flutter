class VerseWithTranslation {
  const VerseWithTranslation({
    required this.chapterId,
    required this.verseId,
    required this.text,
    required this.translation,
  });

  final int chapterId;
  final int verseId;

  /// Arabic text.
  final String text;

  /// Translated text in the requested language.
  final String translation;

  @override
  String toString() => 'VerseWithTranslation($chapterId:$verseId)';
}
