import 'dart:convert';

import '../data/datasources/prayer_cache.dart';
import '../data/datasources/prayer_remote_datasource.dart';
import '../data/models/prayer_timings_model.dart';
import '../domain/entities/prayer_timings.dart';
import '../domain/enums/calculation_method.dart';
import '../domain/enums/madhab.dart';

/// Public API for prayer timings, backed by the Aladhan REST API.
///
/// ## Caching
///
/// Every read goes through a [PrayerCache] governed by a [CachePolicy]:
///
/// * [CachePolicy.enabled] toggles the cache off entirely.
/// * [CachePolicy.ttl] defines how long an entry is considered **fresh**.
///   Once `now - cachedAt > ttl`, the entry is **stale** and the next call
///   refetches from the network.
///
/// The default policy caches for 24 hours in memory. Pass a longer [ttl]
/// (e.g. `Duration(days: 30)`) if you request past dates that never change,
/// or a shorter one if you want frequent revalidation. Provide a persistent
/// [PrayerCache] implementation (disk, sqflite, hive) if you need cache
/// survival across app restarts.
///
/// ## Usage
///
/// ```dart
/// final prayer = PrayerService();
///
/// final timings = await prayer.getTimingsByCoordinates(
///   latitude: 41.0082,
///   longitude: 28.9784,
///   date: DateTime.now(),
///   method: CalculationMethod.turkey,
/// );
///
/// print(timings.fajr); // "05:12"
/// ```
class PrayerService {
  PrayerService({
    PrayerRemoteDatasource? remote,
    PrayerCache? cache,
    CachePolicy policy = const CachePolicy(),
  }) : _remote = remote ?? PrayerRemoteDatasource(),
       _cache = cache ?? InMemoryPrayerCache(),
       _policy = policy;

  final PrayerRemoteDatasource _remote;
  final PrayerCache _cache;
  final CachePolicy _policy;

  /// Prayer timings for a coordinate pair on [date].
  ///
  /// Set [policy] to override the service-wide [CachePolicy] for this call
  /// only (e.g. force a refresh with [CachePolicy.disabled]).
  Future<PrayerTimings> getTimingsByCoordinates({
    required double latitude,
    required double longitude,
    required DateTime date,
    CalculationMethod method = CalculationMethod.muslimWorldLeague,
    Madhab madhab = Madhab.shafi,
    CachePolicy? policy,
  }) => _cached(
    key: _coordKey(latitude, longitude, date, method, madhab),
    policy: policy,
    fetch: () => _remote.getTimingsByCoordinates(
      latitude: latitude,
      longitude: longitude,
      date: date,
      method: method,
      madhab: madhab,
    ),
  );

  /// Prayer timings for a city on [date].
  Future<PrayerTimings> getTimingsByCity({
    required String city,
    required String country,
    required DateTime date,
    String? state,
    CalculationMethod method = CalculationMethod.muslimWorldLeague,
    Madhab madhab = Madhab.shafi,
    CachePolicy? policy,
  }) => _cached(
    key: _cityKey(city, country, state, date, method, madhab),
    policy: policy,
    fetch: () => _remote.getTimingsByCity(
      city: city,
      country: country,
      state: state,
      date: date,
      method: method,
      madhab: madhab,
    ),
  );

  /// Prayer timings resolved from a free-form [address] on [date].
  Future<PrayerTimings> getTimingsByAddress({
    required String address,
    required DateTime date,
    CalculationMethod method = CalculationMethod.muslimWorldLeague,
    Madhab madhab = Madhab.shafi,
    CachePolicy? policy,
  }) => _cached(
    key: _addressKey(address, date, method, madhab),
    policy: policy,
    fetch: () => _remote.getTimingsByAddress(
      address: address,
      date: date,
      method: method,
      madhab: madhab,
    ),
  );

  /// A full calendar month of prayer timings for a coordinate pair.
  ///
  /// The result is cached as a single entry; requesting the same
  /// `(year, month, lat, lon, method, madhab)` again within the TTL window
  /// returns the cached list.
  Future<List<PrayerTimings>> getMonthlyCalendar({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    CalculationMethod method = CalculationMethod.muslimWorldLeague,
    Madhab madhab = Madhab.shafi,
    CachePolicy? policy,
  }) async {
    final effective = policy ?? _policy;
    final key = _calendarKey(latitude, longitude, year, month, method, madhab);

    if (effective.enabled) {
      final entry = await _cache.read(key);
      if (entry != null && entry.isFresh(effective.ttl)) {
        return _decodeList(entry.json);
      }
    }

    final fresh = await _remote.getMonthlyCalendar(
      latitude: latitude,
      longitude: longitude,
      year: year,
      month: month,
      method: method,
      madhab: madhab,
    );

    if (effective.enabled) {
      await _cache.write(key, jsonEncode(fresh.map(_encode).toList()));
    }
    return fresh;
  }

  /// Drops every cached entry.
  Future<void> clearCache() => _cache.clear();

  /// Releases the underlying HTTP client.
  void dispose() => _remote.dispose();

  Future<PrayerTimings> _cached({
    required String key,
    required CachePolicy? policy,
    required Future<PrayerTimingsModel> Function() fetch,
  }) async {
    final effective = policy ?? _policy;
    if (effective.enabled) {
      final entry = await _cache.read(key);
      if (entry != null && entry.isFresh(effective.ttl)) {
        return _decode(entry.json);
      }
    }
    final fresh = await fetch();
    if (effective.enabled) {
      await _cache.write(key, jsonEncode(_encode(fresh)));
    }
    return fresh;
  }

  static String _coordKey(
    double lat,
    double lon,
    DateTime d,
    CalculationMethod m,
    Madhab s,
  ) => 'coord:${lat.toStringAsFixed(4)}:${lon.toStringAsFixed(4)}:'
      '${_dateKey(d)}:${m.id}:${s.id}';

  static String _cityKey(
    String city,
    String country,
    String? state,
    DateTime d,
    CalculationMethod m,
    Madhab s,
  ) => 'city:${city.toLowerCase()}:${country.toLowerCase()}:'
      '${state?.toLowerCase() ?? ''}:${_dateKey(d)}:${m.id}:${s.id}';

  static String _addressKey(
    String address,
    DateTime d,
    CalculationMethod m,
    Madhab s,
  ) => 'addr:${address.toLowerCase()}:${_dateKey(d)}:${m.id}:${s.id}';

  static String _calendarKey(
    double lat,
    double lon,
    int y,
    int mo,
    CalculationMethod m,
    Madhab s,
  ) => 'cal:${lat.toStringAsFixed(4)}:${lon.toStringAsFixed(4)}:$y-$mo:'
      '${m.id}:${s.id}';

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Map<String, dynamic> _encode(PrayerTimings t) => {
    'fajr': t.fajr,
    'sunrise': t.sunrise,
    'dhuhr': t.dhuhr,
    'asr': t.asr,
    'sunset': t.sunset,
    'maghrib': t.maghrib,
    'isha': t.isha,
    'imsak': t.imsak,
    'midnight': t.midnight,
    'firstThird': t.firstThird,
    'lastThird': t.lastThird,
    'gregorianDate': t.gregorianDate.toIso8601String(),
    'hijriDate': t.hijriDate,
    'timezone': t.timezone,
    'latitude': t.latitude,
    'longitude': t.longitude,
    'method': t.method,
  };

  static PrayerTimings _decode(String raw) {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return _decodeMap(m);
  }

  static List<PrayerTimings> _decodeList(String raw) {
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => _decodeMap((e as Map).cast<String, dynamic>()))
        .toList(growable: false);
  }

  static PrayerTimings _decodeMap(Map<String, dynamic> m) => PrayerTimings(
    fajr: m['fajr'] as String,
    sunrise: m['sunrise'] as String,
    dhuhr: m['dhuhr'] as String,
    asr: m['asr'] as String,
    sunset: m['sunset'] as String,
    maghrib: m['maghrib'] as String,
    isha: m['isha'] as String,
    imsak: m['imsak'] as String,
    midnight: m['midnight'] as String,
    firstThird: m['firstThird'] as String,
    lastThird: m['lastThird'] as String,
    gregorianDate: DateTime.parse(m['gregorianDate'] as String),
    hijriDate: m['hijriDate'] as String,
    timezone: m['timezone'] as String,
    latitude: (m['latitude'] as num).toDouble(),
    longitude: (m['longitude'] as num).toDouble(),
    method: (m['method'] as num).toInt(),
  );
}
