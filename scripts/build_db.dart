/// build_db.dart
///
/// One-time CLI tool to compile all Quran source JSONs into assets/islam.db
///
/// Run from the package root:
///   dart run scripts/build_db.dart
///
/// Requirements in pubspec.yaml (dev_dependencies or a separate script pubspec):
///   sqflite_common_ffi: ^2.3.0
///   http: ^1.2.0
///   path: ^1.9.0
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _quranJsonCdn = 'https://cdn.jsdelivr.net/npm/quran-json@3.1.2/dist';
const _tafsirCdn = 'https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir';

const _translationLangs = [
  'en',
  'fr',
  'id',
  'ru',
  'tr',
  'ur',
  'bn',
  'zh',
  'es',
  'sv',
];

// Full list: https://cdn.jsdelivr.net/gh/spa5k/tafsir_api@main/tafsir/editions.json

const _tafseerEditions = [
  'en-al-jalalayn',
  'en-tafisr-ibn-kathir',
  'en-al-qushairi-tafsir',
  'ar-tafsir-al-tabari',
  'ar-tafsir-al-qurtubi',
  'ar-tafsir-al-saddi',
  'ur-tafseer-ibn-e-kaseer',
  'bn-tafisr-fathul-majid',
  // Add more slugs as needed up to 28
];

final _outputPath = p.join(Directory.current.path, 'assets', 'islam.db');

Future<void> main() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  print('🕌 islam_flutter DB Builder');
  print('Output → $_outputPath\n');

  // Delete old DB if exists
  final dbFile = File(_outputPath);
  if (await dbFile.exists()) {
    await dbFile.delete();
    print('🗑  Deleted old islam.db');
  }

  final db = await _openDb();

  try {
    await _createSchema(db);
    await _insertChaptersAndVerses(db);
    await _insertTranslations(db);
    await _insertTafseers(db);
    print('\n✅ islam.db built successfully → $_outputPath');
  } catch (e, st) {
    print('\n❌ Build failed: $e\n$st');
    exit(1);
  } finally {
    await db.close();
  }
}

Future<Database> _openDb() async {
  await Directory(p.dirname(_outputPath)).create(recursive: true);
  return databaseFactoryFfi.openDatabase(_outputPath);
}

Future<void> _createSchema(Database db) async {
  print('📐 Creating schema...');
  await db.execute('PRAGMA journal_mode=WAL;');
  await db.execute('PRAGMA synchronous=NORMAL;');

  await db.execute('''
    CREATE TABLE chapters (
      id                INTEGER PRIMARY KEY,
      name              TEXT NOT NULL,
      transliteration   TEXT NOT NULL,
      type              TEXT NOT NULL,
      total_verses      INTEGER NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE verses (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      chapter_id  INTEGER NOT NULL,
      verse_id    INTEGER NOT NULL,
      hafs        TEXT NOT NULL,
      warsh       TEXT,
      FOREIGN KEY (chapter_id) REFERENCES chapters(id)
    )
  ''');
  await db.execute('CREATE INDEX idx_verses ON verses(chapter_id, verse_id)');

  await db.execute('''
    CREATE TABLE translations (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      chapter_id  INTEGER NOT NULL,
      verse_id    INTEGER NOT NULL,
      lang_code   TEXT NOT NULL,
      text        TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_trans ON translations(chapter_id, verse_id, lang_code)',
  );

  await db.execute('''
    CREATE TABLE tafseers (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      chapter_id    INTEGER NOT NULL,
      verse_id      INTEGER NOT NULL,
      edition_slug  TEXT NOT NULL,
      text          TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_tafseer ON tafseers(chapter_id, verse_id, edition_slug)',
  );

  print('   Schema created ✓');
}

Future<void> _insertChaptersAndVerses(Database db) async {
  print('\n📖 Fetching Arabic Quran (Hafs)...');
  final data = await _fetchJson('$_quranJsonCdn/quran.json') as List<dynamic>;
  print('   Fetched ${data.length} chapters');

  var totalVerses = 0;
  await db.transaction((txn) async {
    for (final chapterJson in data) {
      final chapterMap = chapterJson as Map<String, dynamic>;
      final chapterId = chapterMap['id'] as int;

      await txn.insert('chapters', {
        'id': chapterId,
        'name': chapterMap['name'] as String,
        'transliteration': chapterMap['transliteration'] as String,
        'type': chapterMap['type'] as String,
        'total_verses': chapterMap['total_verses'] as int,
      });

      for (final verseJson in chapterMap['verses'] as List<dynamic>) {
        final v = verseJson as Map<String, dynamic>;
        await txn.insert('verses', {
          'chapter_id': chapterId,
          'verse_id': v['id'] as int,
          'hafs': v['text'] as String,
          'warsh': null, // populated separately if Warsh source available
        });
        totalVerses++;
      }
    }
  });

  print('   Inserted $totalVerses verses ✓');
}

Future<void> _insertTranslations(Database db) async {
  print('\n🌍 Inserting translations...');

  for (final lang in _translationLangs) {
    stdout.write('   [$lang] Fetching...');
    final url = '$_quranJsonCdn/quran_$lang.json';
    final data = await _fetchJson(url) as List<dynamic>;

    var count = 0;
    await db.transaction((txn) async {
      for (final chapterJson in data) {
        final chapterMap = chapterJson as Map<String, dynamic>;
        final chapterId = chapterMap['id'] as int;

        for (final verseJson in chapterMap['verses'] as List<dynamic>) {
          final v = verseJson as Map<String, dynamic>;
          final translation = v['translation'] as String?;
          if (translation == null || translation.isEmpty) continue;

          await txn.insert('translations', {
            'chapter_id': chapterId,
            'verse_id': v['id'] as int,
            'lang_code': lang,
            'text': translation,
          });
          count++;
        }
      }
    });

    print(' $count rows ✓');
  }
}

Future<void> _insertTafseers(Database db) async {
  print('\n📚 Inserting tafseers...');

  for (final slug in _tafseerEditions) {
    stdout.write('   [$slug] Fetching all 114 surahs...');
    var count = 0;

    await db.transaction((txn) async {
      for (var surahNo = 1; surahNo <= 114; surahNo++) {
        final url = '$_tafsirCdn/$slug/$surahNo.json';
        try {
          final data = await _fetchJson(url) as Map<String, dynamic>;
          final ayahs = data['ayahs'] as List<dynamic>;

          for (final ayahJson in ayahs) {
            final a = ayahJson as Map<String, dynamic>;
            final text = a['text'] as String?;
            if (text == null || text.isEmpty) continue;

            await txn.insert('tafseers', {
              'chapter_id': a['surah'] as int,
              'verse_id': a['ayah'] as int,
              'edition_slug': slug,
              'text': text,
            });
            count++;
          }
        } catch (_) {
          // Some surahs may be missing for certain editions — skip silently
        }
      }
    });

    print(' $count rows ✓');
  }
}

Future<dynamic> _fetchJson(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode} for $url');
  }
  return jsonDecode(response.body);
}
