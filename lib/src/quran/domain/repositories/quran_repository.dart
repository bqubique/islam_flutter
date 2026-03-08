import '../entities/chapter.dart';
import '../entities/verse.dart';
import '../entities/verse_with_tafseer.dart';
import '../entities/verse_with_translation.dart';
import '../enums/dialect_enum.dart';
import '../enums/tafseer_enum.dart';
import '../enums/translation_enum.dart';

/// Contract that any Quran data source must fulfil.
/// The [data] layer provides the concrete implementation.
/// The [application] layer depends only on this interface.
abstract interface class QuranRepository {
  /// Returns all 114 chapters (metadata only, no verses).
  Future<List<Chapter>> getAllChapters();

  /// Returns a single chapter by its number [1–114].
  ///
  /// Throws [NotFoundException] if [chapterId] is out of range.
  Future<Chapter> getChapterById(int chapterId);

  /// Returns a single chapter by its English [transliteration],
  /// e.g. `'Al-Fatihah'`. Case-insensitive.
  ///
  /// Throws [NotFoundException] if not found.
  Future<Chapter> getChapterByName(String transliteration);

  /// Returns all verses in a chapter in the given [dialect].
  Future<List<Verse>> getVersesByChapter(
    int chapterId, {
    DialectEnum dialect = DialectEnum.hafs,
  });

  /// Returns a single verse.
  ///
  /// Throws [NotFoundException] if [chapterId]/[verseId] is invalid.
  Future<Verse> getVerse(
    int chapterId,
    int verseId, {
    DialectEnum dialect = DialectEnum.hafs,
  });

  /// Returns one or more verses each paired with its translation.
  Future<List<VerseWithTranslation>> getVersesWithTranslation(
    List<({int chapterId, int verseId})> refs, {
    TranslationEnum translation = TranslationEnum.english,
    DialectEnum dialect = DialectEnum.hafs,
  });

  /// Returns a single verse with its translation and tafseer commentary.
  ///
  /// Throws [NotFoundException] if the verse or tafseer entry doesn't exist.
  Future<VerseWithTafseer> getVerseWithTafseer(
    int chapterId,
    int verseId, {
    TranslationEnum translation = TranslationEnum.english,
    TafseerEnum tafseer = TafseerEnum.jalalayn,
    DialectEnum dialect = DialectEnum.hafs,
  });
}
