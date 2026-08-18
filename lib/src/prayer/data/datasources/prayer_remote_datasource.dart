import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/errors/exceptions.dart';
import '../../domain/enums/calculation_method.dart';
import '../../domain/enums/madhab.dart';
import '../models/prayer_timings_model.dart';

/// Thin wrapper over the public Aladhan REST API.
///
/// See https://aladhan.com/prayer-times-api. This class is intentionally
/// stateless — caching is handled one layer up in the service.
class PrayerRemoteDatasource {
  PrayerRemoteDatasource({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? 'https://api.aladhan.com/v1';

  final http.Client _client;
  final String _baseUrl;

  /// `GET /timings/{date}?latitude=..&longitude=..&method=..&school=..`
  Future<PrayerTimingsModel> getTimingsByCoordinates({
    required double latitude,
    required double longitude,
    required DateTime date,
    required CalculationMethod method,
    required Madhab madhab,
  }) => _fetchTimings(
    path: '/timings/${_formatDate(date)}',
    query: {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'method': '${method.id}',
      'school': '${madhab.id}',
    },
  );

  /// `GET /timingsByCity/{date}?city=..&country=..&method=..&school=..`
  Future<PrayerTimingsModel> getTimingsByCity({
    required String city,
    required String country,
    required DateTime date,
    required CalculationMethod method,
    required Madhab madhab,
    String? state,
  }) => _fetchTimings(
    path: '/timingsByCity/${_formatDate(date)}',
    query: {
      'city': city,
      'country': country,
      if (state != null) 'state': state,
      'method': '${method.id}',
      'school': '${madhab.id}',
    },
  );

  /// `GET /timingsByAddress/{date}?address=..&method=..&school=..`
  Future<PrayerTimingsModel> getTimingsByAddress({
    required String address,
    required DateTime date,
    required CalculationMethod method,
    required Madhab madhab,
  }) => _fetchTimings(
    path: '/timingsByAddress/${_formatDate(date)}',
    query: {
      'address': address,
      'method': '${method.id}',
      'school': '${madhab.id}',
    },
  );

  /// `GET /calendar/{year}/{month}?latitude=..&longitude=..`
  /// Returns one [PrayerTimingsModel] per day of the requested month.
  Future<List<PrayerTimingsModel>> getMonthlyCalendar({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    required CalculationMethod method,
    required Madhab madhab,
  }) async {
    final uri = _uri('/calendar/$year/$month', {
      'latitude': '$latitude',
      'longitude': '$longitude',
      'method': '${method.id}',
      'school': '${madhab.id}',
    });
    final payload = await _get(uri);
    final list = (payload['data'] as List).cast<Map>();
    return list
        .map((e) => PrayerTimingsModel.fromAladhanData(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  Future<PrayerTimingsModel> _fetchTimings({
    required String path,
    required Map<String, String> query,
  }) async {
    final payload = await _get(_uri(path, query));
    return PrayerTimingsModel.fromAladhanData(
      (payload['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    final http.Response response;
    try {
      response = await _client.get(uri);
    } catch (e) {
      throw NetworkException('Prayer API request failed', cause: e);
    }
    if (response.statusCode != 200) {
      throw NetworkException(
        'Prayer API returned non-200 for ${uri.path}',
        statusCode: response.statusCode,
      );
    }
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ParseException('Malformed Prayer API response', cause: e);
    }
  }

  Uri _uri(String path, Map<String, String> query) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  /// Aladhan expects `DD-MM-YYYY` on the path.
  static String _formatDate(DateTime date) =>
      '${_pad(date.day)}-${_pad(date.month)}-${date.year}';

  static String _pad(int n) => n.toString().padLeft(2, '0');

  void dispose() => _client.close();
}
