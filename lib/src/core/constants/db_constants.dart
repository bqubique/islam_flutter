abstract final class DbConstants {
  static const dbName = 'islam.db';
  static const dbUrl =
      'https://pub-27c74a9876e94f6ca601bc94f1bad503.r2.dev/$dbName';
  static const dbSha256 =
      'cdd1f0d0710be818161268f763fb7c777a38e4d5f147afc01e5a1aece9689192';

  static const int dbVersion = 1;

  static const String chaptersTable = 'chapters';
  static const String colId = 'id';
  static const String colName = 'name';
  static const String colTransliteration = 'transliteration';
  static const String colType = 'type';
  static const String colTotalVerses = 'total_verses';

  static const String versesTable = 'verses';
  static const String colChapterId = 'chapter_id';
  static const String colVerseId = 'verse_id';
  static const String colHafs = 'hafs';
  static const String colWarsh = 'warsh';

  static const String translationsTable = 'translations';
  static const String colLangCode = 'lang_code';
  static const String colText = 'text';

  static const String tafseersTable = 'tafseers';
  static const String colEditionSlug = 'edition_slug';

  static const String colTafseerText = 'tafseer_text';
}
