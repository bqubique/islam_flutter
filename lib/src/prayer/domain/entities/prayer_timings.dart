/// A day's set of prayer timings for a given location.
///
/// All time fields are strings in `HH:mm` (24h) format as returned by the
/// Aladhan API. Use [DateTime.parse] with the [gregorianDate] plus the time
/// string if you need a fully qualified [DateTime].
class PrayerTimings {
  const PrayerTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.sunset,
    required this.maghrib,
    required this.isha,
    required this.imsak,
    required this.midnight,
    required this.firstThird,
    required this.lastThird,
    required this.gregorianDate,
    required this.hijriDate,
    required this.timezone,
    required this.latitude,
    required this.longitude,
    required this.method,
  });

  /// Dawn prayer.
  final String fajr;

  /// Sunrise (not a prayer; boundary for the Fajr window).
  final String sunrise;

  /// Noon prayer.
  final String dhuhr;

  /// Afternoon prayer.
  final String asr;

  /// Sunset time.
  final String sunset;

  /// Sunset prayer.
  final String maghrib;

  /// Night prayer.
  final String isha;

  /// Cut-off time for the pre-dawn meal (Suhoor).
  final String imsak;

  /// Islamic midnight (used for optional night prayer boundaries).
  final String midnight;

  /// Start of the last third of the night.
  final String firstThird;

  /// Start of the last third of the night — recommended for Tahajjud.
  final String lastThird;

  /// Gregorian date these timings apply to.
  final DateTime gregorianDate;

  /// Hijri date in `DD-MM-YYYY` format as returned by Aladhan.
  final String hijriDate;

  /// IANA timezone identifier (e.g. `Europe/Istanbul`).
  final String timezone;

  final double latitude;
  final double longitude;

  /// Calculation method id used to produce these timings.
  final int method;

  @override
  String toString() =>
      'PrayerTimings(fajr: $fajr, dhuhr: $dhuhr, asr: $asr, '
      'maghrib: $maghrib, isha: $isha, date: $gregorianDate)';
}
