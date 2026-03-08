class Verse {
  const Verse({
    required this.chapterId,
    required this.verseId,
    required this.text,
  });

  final int chapterId;
  final int verseId;

  /// Arabic text in the selected dialect (Hafs or Warsh).
  final String text;

  @override
  String toString() => 'Verse($chapterId:$verseId)';
}
