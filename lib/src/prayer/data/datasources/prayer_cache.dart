import 'dart:convert';

/// Controls freshness of cached prayer timing responses.
///
/// A cache entry is considered **fresh** while
/// `now - cachedAt <= ttl`. After that it is treated as **stale** and the
/// service will re-fetch from the API.
///
/// Prayer times for a given date + location + method + madhab never change,
/// so once a past date is cached the [ttl] can safely be very large. For
/// "today"-style requests you may want a shorter [ttl] (e.g. 6 hours) so
/// that any method/schema updates on the Aladhan side are eventually picked
/// up.
class CachePolicy {
  const CachePolicy({
    this.enabled = true,
    this.ttl = const Duration(hours: 24),
  });

  /// Disable the cache entirely — every call hits the network.
  static const CachePolicy disabled = CachePolicy(enabled: false);

  /// Whether reads/writes go through the cache.
  final bool enabled;

  /// Maximum age a cached entry may reach before it is considered stale.
  final Duration ttl;
}

/// Cache abstraction for prayer timings.
///
/// Implementations must be safe to call from any isolate the service is
/// running on. Values are stored as opaque JSON strings so consumers can
/// swap in disk-backed caches (shared_preferences, hive, sqflite) without
/// changing the service.
abstract class PrayerCache {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, String json);
  Future<void> clear();
}

/// A cached value together with the timestamp it was written at.
class CacheEntry {
  const CacheEntry(this.json, this.cachedAt);

  final String json;
  final DateTime cachedAt;

  bool isFresh(Duration ttl) =>
      DateTime.now().difference(cachedAt) <= ttl;

  String encode() =>
      jsonEncode({'cachedAt': cachedAt.toIso8601String(), 'json': json});

  static CacheEntry decode(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return CacheEntry(
      map['json'] as String,
      DateTime.parse(map['cachedAt'] as String),
    );
  }
}

/// Default in-memory cache. Cleared when the process exits.
class InMemoryPrayerCache implements PrayerCache {
  final Map<String, CacheEntry> _store = {};

  @override
  Future<CacheEntry?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String json) async {
    _store[key] = CacheEntry(json, DateTime.now());
  }

  @override
  Future<void> clear() async => _store.clear();
}
