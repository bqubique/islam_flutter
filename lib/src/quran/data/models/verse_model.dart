import '../../../core/constants/db_constants.dart';
import '../../domain/entities/verse.dart';
import '../../domain/enums/dialect_enum.dart';

class VerseModel extends Verse {
  const VerseModel({
    required super.chapterId,
    required super.verseId,
    required super.text,
  });

  factory VerseModel.fromMap(Map<String, dynamic> map, DialectEnum dialect) {
    return VerseModel(
      chapterId: map[DbConstants.colChapterId] as int,
      verseId: map[DbConstants.colVerseId] as int,
      text: map[dialect.columnName] as String,
    );
  }
}
