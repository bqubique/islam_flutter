import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../errors/exceptions.dart';

/// Utility for loading and decoding JSON assets from the bundle.
abstract final class AssetLoader {
  /// Loads a JSON asset and returns it as a decoded [Map].
  static Future<Map<String, dynamic>> loadMap(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FlutterError catch (e) {
      throw AssetLoadException('Failed to load asset: $assetPath', cause: e);
    } on FormatException catch (e) {
      throw ParseException('Failed to parse JSON at: $assetPath', cause: e);
    }
  }

  /// Loads a JSON asset and returns it as a decoded [List].
  static Future<List<dynamic>> loadList(String assetPath) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      return jsonDecode(raw) as List<dynamic>;
    } on FlutterError catch (e) {
      throw AssetLoadException('Failed to load asset: $assetPath', cause: e);
    } on FormatException catch (e) {
      throw ParseException('Failed to parse JSON at: $assetPath', cause: e);
    }
  }
}
