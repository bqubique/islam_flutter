# islam_flutter

Flutter package for accessing Quran text, translations, and tafseer. Heavily inspired by [islam.js](https://github.com/dev-ahmadbilal/islam.js).

## Features

- All 114 chapters with metadata (name, transliteration, type, verse count)
- Verses in Hafs and Warsh dialects
- 10 translations (English, French, Urdu, Indonesian, Russian, Turkish, Bengali, Chinese, Spanish, Swedish)
- 8 tafseer editions (Al-Jalalayn, Ibn Kathir, Al-Qurtubi, Al-Tabari, Al-Saddi, Qushairi, Ibn Kathir Urdu, Fathul Majid)
- One-time database download with progress callback
- Fully offline after first run
- SHA-256 integrity check on the downloaded database

## Installation

```yaml
dependencies:
  islam_flutter: ^0.0.1
```

## Setup

Call `QuranService.init()` once at app startup before using the service. This checks whether the database is cached locally and downloads it if not.

```dart
await QuranService().init(
  onDownloadStart: () {
    // show progress UI
  },
  onProgress: (double progress) {
    // progress is 0.0–1.0
  },
);
```

The database is downloaded only on the first launch (or when the package ships a new DB version).

## Usage

```dart
final quran = QuranService();

// All chapters
final chapters = await quran.getAllChapters();

// Single chapter
final fatiha = await quran.getChapterById(1);

// Verses (Hafs dialect by default)
final verses = await quran.getVersesByChapter(1);

// Verses in Warsh dialect
final warsh = await quran.getVersesByChapter(1, dialect: DialectEnum.warsh);

// Single verse
final verse = await quran.getVerse(2, 255);

// Verse with translation
final translated = await quran.getVersesWithTranslation(
  [(chapterId: 2, verseId: 255)],
  translation: TranslationEnum.french,
);

// Verse with translation and tafseer
final detailed = await quran.getVerseWithTafseer(
  1,
  1,
  translation: TranslationEnum.english,
  tafseer: TafseerEnum.ibnKathir,
);
```

## Enums

**TranslationEnum**

| Value        | Language                                   |
| ------------ | ------------------------------------------ |
| `english`    | English — Saheeh International             |
| `french`     | French — Muhammad Hamidullah               |
| `urdu`       | Urdu — Abul A'ala Maududi                  |
| `indonesian` | Indonesian — Ministry of Religious Affairs |
| `russian`    | Russian — Elmir Kuliev                     |
| `turkish`    | Turkish — Diyanet Isleri                   |
| `bengali`    | Bengali — Muhiuddin Khan                   |
| `chinese`    | Chinese — Ma Jian                          |
| `spanish`    | Spanish — Muhammad Isa Garcia              |
| `swedish`    | Swedish — Knut Bernström                   |

**TafseerEnum**

| Value           | Name                         | Language |
| --------------- | ---------------------------- | -------- |
| `jalalayn`      | Tafsir Al-Jalalayn           | English  |
| `ibnKathir`     | Tafsir Ibn Kathir (abridged) | English  |
| `qushayri`      | Al-Qushairi Tafsir           | English  |
| `tabari`        | تفسير الطبري                 | Arabic   |
| `qurtubi`       | تفسير القرطبي                | Arabic   |
| `saddi`         | تفسير السعدي                 | Arabic   |
| `ibnKathirUrdu` | تفسیر ابن کثیر               | Urdu     |
| `fathulMajid`   | تاফসীর ফাতহুল মাজিদ          | Bengali  |

**DialectEnum**

| Value   | Description            |
| ------- | ---------------------- |
| `hafs`  | Hafs an Asim (default) |
| `warsh` | Warsh an Nafi          |

## Error handling

All methods throw typed exceptions from the package:

- `IslamFlutterDatabaseException` - database open or query failure
- `NotFoundException` - chapter or verse not found
- `InvalidArgumentException` - chapter/verse ID out of valid range

## Platform support

| Android | iOS | Web | macOS | Windows | Linux |
| ------- | --- | --- | ----- | ------- | ----- |
| ✅      | ✅  | —   | ✅    | —       | —     |

## Requirements

- Flutter 3.x or later
- Dart 3.x or later
- Internet connection on first launch for database download
