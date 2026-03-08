import 'package:sqflite/sqflite.dart' as sqflite;

import '../../../core/constants/db_constants.dart';
import '../../../core/database/db_helper.dart';
import '../../../core/errors/exceptions.dart';
import '../../domain/enums/dialect_enum.dart';
import '../../domain/enums/tafseer_enum.dart';
import '../../domain/enums/translation_enum.dart';
import '../models/chapter_model.dart';
import '../models/verse_model.dart';
import '../models/verse_with_tafseer_model.dart';
import '../models/verse_with_translation_model.dart';

class QuranLocalDatasource {
  QuranLocalDatasource(this._dbHelper);

  final DbHelper _dbHelper;

  Future<sqflite.Database> get _db => _dbHelper.database;

  Future<List<ChapterModel>> getAllChapters() async {
    try {
      final db = await _db;
      final rows = await db.query(DbConstants.chaptersTable);
      return rows.map(ChapterModel.fromMap).toList();
    } catch (e) {
      throw IslamFlutterDatabaseException(
        'Failed to get all chapters',
        cause: e,
      );
    }
  }

  Future<ChapterModel> getChapterById(int chapterId) async {
    _validateChapterId(chapterId);
    try {
      final db = await _db;
      final rows = await db.query(
        DbConstants.chaptersTable,
        where: '${DbConstants.colId} = ?',
        whereArgs: [chapterId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw NotFoundException('Chapter $chapterId not found');
      }
      return ChapterModel.fromMap(rows.first);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw IslamFlutterDatabaseException(
        'Failed to get chapter $chapterId',
        cause: e,
      );
    }
  }

  Future<ChapterModel> getChapterByName(String transliteration) async {
    try {
      final db = await _db;
      final rows = await db.query(
        DbConstants.chaptersTable,
        where: 'LOWER(${DbConstants.colTransliteration}) = ?',
        whereArgs: [transliteration.toLowerCase()],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw NotFoundException('Chapter "$transliteration" not found');
      }
      return ChapterModel.fromMap(rows.first);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw IslamFlutterDatabaseException(
        'Failed to get chapter "$transliteration"',
        cause: e,
      );
    }
  }

  Future<List<VerseModel>> getVersesByChapter(
    int chapterId, {
    DialectEnum dialect = DialectEnum.hafs,
  }) async {
    _validateChapterId(chapterId);
    try {
      final db = await _db;
      final rows = await db.query(
        DbConstants.versesTable,
        columns: [
          DbConstants.colChapterId,
          DbConstants.colVerseId,
          dialect.columnName,
        ],
        where: '${DbConstants.colChapterId} = ?',
        whereArgs: [chapterId],
        orderBy: DbConstants.colVerseId,
      );
      return rows.map((r) => VerseModel.fromMap(r, dialect)).toList();
    } catch (e) {
      throw IslamFlutterDatabaseException(
        'Failed to get verses for chapter $chapterId',
        cause: e,
      );
    }
  }

  Future<VerseModel> getVerse(
    int chapterId,
    int verseId, {
    DialectEnum dialect = DialectEnum.hafs,
  }) async {
    _validateChapterId(chapterId);
    _validateVerseId(verseId);
    try {
      final db = await _db;
      final rows = await db.query(
        DbConstants.versesTable,
        columns: [
          DbConstants.colChapterId,
          DbConstants.colVerseId,
          dialect.columnName,
        ],
        where:
            '${DbConstants.colChapterId} = ? AND ${DbConstants.colVerseId} = ?',
        whereArgs: [chapterId, verseId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw NotFoundException('Verse $chapterId:$verseId not found');
      }
      return VerseModel.fromMap(rows.first, dialect);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw IslamFlutterDatabaseException(
        'Failed to get verse $chapterId:$verseId',
        cause: e,
      );
    }
  }

  Future<List<VerseWithTranslationModel>> getVersesWithTranslation(
    List<({int chapterId, int verseId})> refs, {
    TranslationEnum translation = TranslationEnum.english,
    DialectEnum dialect = DialectEnum.hafs,
  }) async {
    if (refs.isEmpty) return [];
    try {
      final db = await _db;

      // Build WHERE clause: (v.chapter_id = ? AND v.verse_id = ?) OR ...
      final placeholders = refs
          .map(
            (_) =>
                '(v.${DbConstants.colChapterId} = ? AND v.${DbConstants.colVerseId} = ?)',
          )
          .join(' OR ');

      // lang_code arg must come before verse ref args to match JOIN ON clause
      final args = <dynamic>[
        translation.code,
        ...refs.expand((r) => [r.chapterId, r.verseId]),
      ];

      final rows = await db.rawQuery('''
        SELECT
          v.${DbConstants.colChapterId},
          v.${DbConstants.colVerseId},
          v.${dialect.columnName} AS ${DbConstants.colHafs},
          t.${DbConstants.colText}
        FROM ${DbConstants.versesTable} v
        INNER JOIN ${DbConstants.translationsTable} t
          ON  t.${DbConstants.colChapterId} = v.${DbConstants.colChapterId}
          AND t.${DbConstants.colVerseId}   = v.${DbConstants.colVerseId}
          AND t.${DbConstants.colLangCode}  = ?
        WHERE $placeholders
        ORDER BY v.${DbConstants.colChapterId}, v.${DbConstants.colVerseId}
      ''', args);

      return rows.map(VerseWithTranslationModel.fromMap).toList();
    } catch (e) {
      throw IslamFlutterDatabaseException(
        'Failed to get verses with translation',
        cause: e,
      );
    }
  }

  Future<VerseWithTafseerModel> getVerseWithTafseer(
    int chapterId,
    int verseId, {
    TranslationEnum translation = TranslationEnum.english,
    TafseerEnum tafseer = TafseerEnum.jalalayn,
    DialectEnum dialect = DialectEnum.hafs,
  }) async {
    _validateChapterId(chapterId);
    _validateVerseId(verseId);
    try {
      final db = await _db;
      final rows = await db.rawQuery(
        '''
        SELECT
          v.${DbConstants.colChapterId},
          v.${DbConstants.colVerseId},
          v.${dialect.columnName}         AS ${DbConstants.colHafs},
          t.${DbConstants.colText},
          tf.${DbConstants.colText}       AS ${DbConstants.colTafseerText}
        FROM ${DbConstants.versesTable} v
        INNER JOIN ${DbConstants.translationsTable} t
          ON  t.${DbConstants.colChapterId} = v.${DbConstants.colChapterId}
          AND t.${DbConstants.colVerseId}   = v.${DbConstants.colVerseId}
          AND t.${DbConstants.colLangCode}  = ?
        INNER JOIN ${DbConstants.tafseersTable} tf
          ON  tf.${DbConstants.colChapterId}  = v.${DbConstants.colChapterId}
          AND tf.${DbConstants.colVerseId}    = v.${DbConstants.colVerseId}
          AND tf.${DbConstants.colEditionSlug}= ?
        WHERE v.${DbConstants.colChapterId} = ?
          AND v.${DbConstants.colVerseId}   = ?
        LIMIT 1
      ''',
        [translation.code, tafseer.slug, chapterId, verseId],
      );

      if (rows.isEmpty) {
        throw NotFoundException(
          'Verse $chapterId:$verseId not found '
          'for translation "${translation.code}" '
          'and tafseer "${tafseer.slug}"',
        );
      }
      return VerseWithTafseerModel.fromMap(rows.first);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw IslamFlutterDatabaseException(
        'Failed to get verse $chapterId:$verseId with tafseer',
        cause: e,
      );
    }
  }

  void _validateChapterId(int id) {
    if (id < 1 || id > 114) {
      throw InvalidArgumentException(
        'Chapter ID must be between 1 and 114, got $id',
      );
    }
  }

  void _validateVerseId(int id) {
    if (id < 1) {
      throw InvalidArgumentException('Verse ID must be >= 1, got $id');
    }
  }
}
