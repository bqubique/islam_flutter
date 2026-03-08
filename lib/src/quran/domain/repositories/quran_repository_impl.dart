import '../../data/datasources/quran_local_datasource.dart';
import '../entities/chapter.dart';
import '../entities/verse.dart';
import '../entities/verse_with_tafseer.dart';
import '../entities/verse_with_translation.dart';
import '../enums/dialect_enum.dart';
import '../enums/tafseer_enum.dart';
import '../enums/translation_enum.dart';
import 'quran_repository.dart';

class QuranRepositoryImpl implements QuranRepository {
  const QuranRepositoryImpl(this._datasource);

  final QuranLocalDatasource _datasource;

  @override
  Future<List<Chapter>> getAllChapters() => _datasource.getAllChapters();

  @override
  Future<Chapter> getChapterById(int chapterId) =>
      _datasource.getChapterById(chapterId);

  @override
  Future<Chapter> getChapterByName(String transliteration) =>
      _datasource.getChapterByName(transliteration);

  @override
  Future<List<Verse>> getVersesByChapter(
    int chapterId, {
    DialectEnum dialect = DialectEnum.hafs,
  }) => _datasource.getVersesByChapter(chapterId, dialect: dialect);

  @override
  Future<Verse> getVerse(
    int chapterId,
    int verseId, {
    DialectEnum dialect = DialectEnum.hafs,
  }) => _datasource.getVerse(chapterId, verseId, dialect: dialect);

  @override
  Future<List<VerseWithTranslation>> getVersesWithTranslation(
    List<({int chapterId, int verseId})> refs, {
    TranslationEnum translation = TranslationEnum.english,
    DialectEnum dialect = DialectEnum.hafs,
  }) => _datasource.getVersesWithTranslation(
    refs,
    translation: translation,
    dialect: dialect,
  );

  @override
  Future<VerseWithTafseer> getVerseWithTafseer(
    int chapterId,
    int verseId, {
    TranslationEnum translation = TranslationEnum.english,
    TafseerEnum tafseer = TafseerEnum.jalalayn,
    DialectEnum dialect = DialectEnum.hafs,
  }) => _datasource.getVerseWithTafseer(
    chapterId,
    verseId,
    translation: translation,
    tafseer: tafseer,
    dialect: dialect,
  );
}
