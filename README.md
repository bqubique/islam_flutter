# islam_flutter

Flutter package for accessing Quran text, translations, tafseer, and prayer times. Heavily inspired by [islam.js](https://github.com/dev-ahmadbilal/islam.js).

## Features

- All 114 chapters with metadata (name, transliteration, type, verse count)
- Verses in Hafs and Warsh dialects
- 10 translations (English, French, Urdu, Indonesian, Russian, Turkish, Bengali, Chinese, Spanish, Swedish)
- 8 tafseer editions (Al-Jalalayn, Ibn Kathir, Al-Qurtubi, Al-Tabari, Al-Saddi, Qushairi, Ibn Kathir Urdu, Fathul Majid)
- One-time database download with progress callback
- Fully offline after first run
- SHA-256 integrity check on the downloaded database
- Prayer times via the [Aladhan API](https://aladhan.com/prayer-times-api) with 24 calculation methods, Shafi/Hanafi Asr, and a pluggable cache

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

## Prayer times

`PrayerService` wraps the [Aladhan REST API](https://aladhan.com/prayer-times-api). No init step — construct and call.

```dart
final prayer = PrayerService();

// By coordinates
final timings = await prayer.getTimingsByCoordinates(
  latitude: 41.0082,
  longitude: 28.9784,
  date: DateTime.now(),
  method: CalculationMethod.turkey,
  madhab: Madhab.shafi,
);

print(timings.fajr);    // "05:12"
print(timings.dhuhr);   // "13:04"
print(timings.hijriDate); // "12-08-1447"

// By city
final byCity = await prayer.getTimingsByCity(
  city: 'Istanbul',
  country: 'Turkey',
  date: DateTime.now(),
);

// By free-form address
final byAddress = await prayer.getTimingsByAddress(
  address: '1600 Amphitheatre Parkway, Mountain View, CA',
  date: DateTime.now(),
);

// Full month calendar
final month = await prayer.getMonthlyCalendar(
  latitude: 41.0082,
  longitude: 28.9784,
  year: 2026,
  month: 8,
);

prayer.dispose(); // closes the underlying http client
```

### Caching

Every read goes through a `PrayerCache` governed by a `CachePolicy`. Defaults to an in-memory cache with a 24-hour TTL.

```dart
final prayer = PrayerService(
  policy: const CachePolicy(ttl: Duration(days: 7)),
);
```

**Freshness rule.** An entry is fresh while `now - cachedAt <= ttl`. Once older than `ttl` it's stale and the next call re-fetches from the network. Cache keys include date + location + method + madhab, so changing any parameter produces a new entry rather than a stale hit.

**Per-call override.** Pass `policy:` to force behavior for a single call — most useful for a manual "refresh" button:

```dart
final fresh = await prayer.getTimingsByCity(
  city: 'Istanbul',
  country: 'Turkey',
  date: DateTime.now(),
  policy: CachePolicy.disabled, // bypass cache this call only
);
```

**Choosing a TTL.**

| Use case                                | Suggested TTL         |
| --------------------------------------- | --------------------- |
| Past dates (times never change)         | `Duration(days: 365)` |
| "Today" widget refreshed occasionally   | `Duration(hours: 6)`  |
| Live prayer clock                       | `Duration(minutes: 30)` or `CachePolicy.disabled` |

**Custom cache backend.** Implement `PrayerCache` to persist across app restarts (shared_preferences, sqflite, hive, disk). Values are opaque JSON strings so any key-value store works:

```dart
class MyDiskCache implements PrayerCache {
  @override
  Future<CacheEntry?> read(String key) async { /* ... */ }

  @override
  Future<void> write(String key, String json) async { /* ... */ }

  @override
  Future<void> clear() async { /* ... */ }
}

final prayer = PrayerService(cache: MyDiskCache());
```

Clear everything with `await prayer.clearCache();`.

### Calculation methods

`CalculationMethod` mirrors Aladhan's method ids — full list at [aladhan.com/calculation-methods](https://aladhan.com/calculation-methods). Common values:

| Value                  | Region / body                          |
| ---------------------- | -------------------------------------- |
| `muslimWorldLeague`    | Muslim World League (default)          |
| `isna`                 | Islamic Society of North America       |
| `egypt`                | Egyptian General Authority of Survey   |
| `karachi`              | University of Islamic Sciences, Karachi|
| `ummAlQura`            | Umm Al-Qura University, Makkah         |
| `turkey`               | Diyanet İşleri Başkanlığı              |
| `tehran`               | Institute of Geophysics, Tehran        |
| `moonsightingCommittee`| Moonsighting Committee Worldwide       |

### Madhab

`Madhab` selects the Asr shadow ratio:

| Value    | Ratio |
| -------- | ----- |
| `shafi`  | 1 (Shafi'i, Maliki, Hanbali — default) |
| `hanafi` | 2 (Hanafi)                             |

## Error handling

All methods throw typed exceptions from the package:

- `IslamFlutterDatabaseException` - database open or query failure
- `NotFoundException` - chapter or verse not found
- `InvalidArgumentException` - chapter/verse ID out of valid range
- `NetworkException` - Aladhan API request failed (includes HTTP `statusCode` when available)
- `ParseException` - Aladhan response was malformed

## Platform support

| Android | iOS | Web | macOS | Windows | Linux |
| ------- | --- | --- | ----- | ------- | ----- |
| ✅      | ✅  | —   | ✅    | —       | —     |

## Requirements

- Flutter 3.x or later
- Dart 3.x or later
- Internet connection on first launch for database download
- Internet connection for `PrayerService` requests (cached results are served offline)
