import '../../domain/entities/prayer_timings.dart';

/// Parses an Aladhan `/timings*` response payload into a [PrayerTimings].
class PrayerTimingsModel extends PrayerTimings {
  const PrayerTimingsModel({
    required super.fajr,
    required super.sunrise,
    required super.dhuhr,
    required super.asr,
    required super.sunset,
    required super.maghrib,
    required super.isha,
    required super.imsak,
    required super.midnight,
    required super.firstThird,
    required super.lastThird,
    required super.gregorianDate,
    required super.hijriDate,
    required super.timezone,
    required super.latitude,
    required super.longitude,
    required super.method,
  });

  /// [json] is the `data` object from an Aladhan `/timings*` response.
  factory PrayerTimingsModel.fromAladhanData(Map<String, dynamic> json) {
    final timings = (json['timings'] as Map).cast<String, dynamic>();
    final date = (json['date'] as Map).cast<String, dynamic>();
    final gregorian = (date['gregorian'] as Map).cast<String, dynamic>();
    final hijri = (date['hijri'] as Map).cast<String, dynamic>();
    final meta = (json['meta'] as Map).cast<String, dynamic>();
    final method = (meta['method'] as Map).cast<String, dynamic>();

    String clean(String key) => (timings[key] as String).split(' ').first;

    return PrayerTimingsModel(
      fajr: clean('Fajr'),
      sunrise: clean('Sunrise'),
      dhuhr: clean('Dhuhr'),
      asr: clean('Asr'),
      sunset: clean('Sunset'),
      maghrib: clean('Maghrib'),
      isha: clean('Isha'),
      imsak: clean('Imsak'),
      midnight: clean('Midnight'),
      firstThird: clean('Firstthird'),
      lastThird: clean('Lastthird'),
      gregorianDate: _parseGregorian(gregorian['date'] as String),
      hijriDate: hijri['date'] as String,
      timezone: meta['timezone'] as String,
      latitude: (meta['latitude'] as num).toDouble(),
      longitude: (meta['longitude'] as num).toDouble(),
      method: (method['id'] as num).toInt(),
    );
  }

  /// Aladhan gregorian date format: `DD-MM-YYYY`.
  static DateTime _parseGregorian(String value) {
    final parts = value.split('-');
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  }
}
