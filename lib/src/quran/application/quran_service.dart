import 'package:flutter/foundation.dart';

import '../../core/database/db_helper.dart';
import '../data/datasources/quran_local_datasource.dart';
import '../domain/entities/chapter.dart';
import '../domain/entities/verse.dart';
import '../domain/entities/verse_with_tafseer.dart';
import '../domain/entities/verse_with_translation.dart';
import '../domain/enums/dialect_enum.dart';
import '../domain/enums/tafseer_enum.dart';
import '../domain/enums/translation_enum.dart';
import '../domain/repositories/quran_repository.dart';
import '../domain/repositories/quran_repository_impl.dart';

/// Public API for the Quran module.
///
/// Usage:
/// ```dart
/// final quran = QuranService();
///
/// final chapter = await quran.getChapterById(1);
/// final verse   = await quran.getVerse(1, 1);
/// final verses  = await quran.getVersesWithTranslation(
///   [(chapterId: 2, verseId: 255)],
///   translation: TranslationEnum.french,
/// );
/// ```
class QuranService {
  QuranService({QuranRepository? repository})
    : _repository =
          repository ??
          QuranRepositoryImpl(QuranLocalDatasource(DbHelper.instance));

  final QuranRepository _repository;

  Future<void> init({
    VoidCallback? onDownloadStart,
    void Function(double progress)? onProgress,
  }) => DbHelper.instance.init(
    onDownloadStart: onDownloadStart,
    onProgress: onProgress,
  );

  /// Returns all 114 chapters (metadata only, no verses).
  Future<List<Chapter>> getAllChapters() => _repository.getAllChapters();

  /// Returns a chapter by number [1–114].
  ///
  /// Throws [InvalidArgumentException] if out of range.
  /// Throws [NotFoundException] if not found.
  Future<Chapter> getChapterById(int chapterId) =>
      _repository.getChapterById(chapterId);

  /// Returns a chapter by English transliteration, e.g. `'Al-Fatihah'`.
  /// Case-insensitive.
  ///
  /// Throws [NotFoundException] if not found.
  Future<Chapter> getChapterByName(String name) =>
      _repository.getChapterByName(name);

  /// Returns all verses in a chapter.
  Future<List<Verse>> getVersesByChapter(
    int chapterId, {
    DialectEnum dialect = DialectEnum.hafs,
  }) => _repository.getVersesByChapter(chapterId, dialect: dialect);

  /// Returns a single verse.
  ///
  /// Throws [InvalidArgumentException] for invalid IDs.
  /// Throws [NotFoundException] if the verse doesn't exist.
  Future<Verse> getVerse(
    int chapterId,
    int verseId, {
    DialectEnum dialect = DialectEnum.hafs,
  }) => _repository.getVerse(chapterId, verseId, dialect: dialect);

  /// Returns one or more verses each paired with its translation.
  ///
  /// Example — Ayat al-Kursi in French:
  /// ```dart
  /// final verses = await quran.getVersesWithTranslation(
  ///   [(chapterId: 2, verseId: 255)],
  ///   translation: TranslationEnum.french,
  /// );
  /// ```
  Future<List<VerseWithTranslation>> getVersesWithTranslation(
    List<({int chapterId, int verseId})> refs, {
    TranslationEnum translation = TranslationEnum.english,
    DialectEnum dialect = DialectEnum.hafs,
  }) => _repository.getVersesWithTranslation(
    refs,
    translation: translation,
    dialect: dialect,
  );

  /// Returns a verse with its translation and tafseer commentary.
  ///
  /// Throws [NotFoundException] if the verse or tafseer entry doesn't exist.
  Future<VerseWithTafseer> getVerseWithTafseer(
    int chapterId,
    int verseId, {
    TranslationEnum translation = TranslationEnum.english,
    TafseerEnum tafseer = TafseerEnum.jalalayn,
    DialectEnum dialect = DialectEnum.hafs,
  }) => _repository.getVerseWithTafseer(
    chapterId,
    verseId,
    translation: translation,
    tafseer: tafseer,
    dialect: dialect,
  );

  Future<void> reset() => DbHelper.instance.reset();
}
