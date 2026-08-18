## Unreleased

- Add `PrayerService` backed by the [Aladhan API](https://aladhan.com/prayer-times-api).
  - `getTimingsByCoordinates`, `getTimingsByCity`, `getTimingsByAddress`, `getMonthlyCalendar`.
  - `CalculationMethod` (24 methods) and `Madhab` (Shafi/Hanafi) enums.
  - Pluggable `PrayerCache` with default `InMemoryPrayerCache`.
  - `CachePolicy(enabled, ttl)` for staleness control; per-call override supported.
- Example app: new `PrayerPage` demonstrating city lookup, method/madhab pickers, and cache bypass.

## 0.0.4 Aug 11, 2026

- Remove deprecated CocoaPods integration
- Add `getNextVerse` and `getPreviousVerse` to QuranRepository and QuranService.
- Export `QuranBoundaryException` for boundary handling.
- Bump outdated package dependencies.

## 0.0.3 Mar 8, 2026

- `pub.dev` improvements

## 0.0.2 Mar 8, 2026

- Fix an issue with iOS devices when updating the app

## 0.0.1 Mar 8, 2026

- Initial release
