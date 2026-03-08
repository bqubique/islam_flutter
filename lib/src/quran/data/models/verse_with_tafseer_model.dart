import '../../../core/constants/db_constants.dart';
import '../../domain/entities/verse_with_tafseer.dart';

class VerseWithTafseerModel extends VerseWithTafseer {
  const VerseWithTafseerModel({
    required super.chapterId,
    required super.verseId,
    required super.text,
    required super.translation,
    required super.tafseer,
  });

  factory VerseWithTafseerModel.fromMap(Map<String, dynamic> map) {
    return VerseWithTafseerModel(
      chapterId: map[DbConstants.colChapterId] as int,
      verseId: map[DbConstants.colVerseId] as int,
      text: map[DbConstants.colHafs] as String,
      translation: map[DbConstants.colText] as String,
      tafseer: map[DbConstants.colTafseerText] as String,
    );
  }
}
