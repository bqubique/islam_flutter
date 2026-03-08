import '../../../core/constants/db_constants.dart';
import '../../domain/entities/chapter.dart';

class ChapterModel extends Chapter {
  const ChapterModel({
    required super.id,
    required super.name,
    required super.transliteration,
    required super.type,
    required super.totalVerses,
  });

  factory ChapterModel.fromMap(Map<String, dynamic> map) {
    return ChapterModel(
      id: map[DbConstants.colId] as int,
      name: map[DbConstants.colName] as String,
      transliteration: map[DbConstants.colTransliteration] as String,
      type: map[DbConstants.colType] as String,
      totalVerses: map[DbConstants.colTotalVerses] as int,
    );
  }
}
