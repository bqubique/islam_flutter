import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../constants/db_constants.dart';
import '../errors/exceptions.dart';

/// Manages the SQLite database lifecycle.
///
/// On first run, downloads [islam.db] from R2 to the device's support
/// directory. Subsequent runs open the existing cached file instantly.
///
/// Call [init] once at app startup (via [QuranService.init]) to handle
/// the download with progress feedback before any queries are made.
///
/// Usage:
/// ```dart
/// await QuranService.init(
///   onDownloadStart: () => showProgress(),
///   onProgress: (p) => updateBar(p),
/// );
/// ```
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  static const _dbVersion = 2;

  sqflite.Database? _db;

  /// Returns the open [Database], initializing it on first access.
  /// Prefer calling [init] at startup instead so downloads have progress.
  Future<sqflite.Database> get database async {
    _db ??= await _openDb(await _dbPath());
    return _db!;
  }

  /// Call once at startup. Downloads the DB if not cached, then opens it.
  ///
  /// [onDownloadStart] fires when a download is about to begin.
  /// [onProgress] fires with values 0.0–1.0 during the download.
  Future<void> init({
    VoidCallback? onDownloadStart,
    void Function(double progress)? onProgress,
  }) async {
    if (_db != null) return; // already initialised
    final path = await _dbPath();

    debugPrint('DB path: $path');
    debugPrint('Is cached: ${await _isCached(path)}');
    final vf = File('$path.version');
    debugPrint('Stored version: ${await vf.readAsString()}');

    if (!await _isCached(path)) {
      onDownloadStart?.call();
      await _download(path, onProgress: onProgress);
    }

    _db = await _openDb(path);
  }

  Future<String> _dbPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, DbConstants.dbName);
  }

  Future<bool> _isCached(String path) async {
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) return false;
    final vf = File('$path.version');
    if (!await vf.exists()) return false;
    final stored = int.tryParse(await vf.readAsString());
    debugPrint(
      'Stored: $stored, Current: $_dbVersion, Match: ${stored == _dbVersion}',
    );
    return stored == _dbVersion;
  }

  Future<void> _download(
    String path, {
    void Function(double)? onProgress,
  }) async {
    final request = http.Request('GET', Uri.parse(DbConstants.dbUrl));
    final response = await request.send();

    if (response.statusCode != 200) {
      throw IslamFlutterDatabaseException(
        'Failed to download islam.db (HTTP ${response.statusCode})',
      );
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = File(path).openWrite();

    try {
      await response.stream
          .map((chunk) {
            received += chunk.length;
            if (total > 0) onProgress?.call(received / total);
            return chunk;
          })
          .pipe(sink);
    } on FileSystemException catch (e) {
      throw IslamFlutterDatabaseException(
        'Could not write islam.db to device storage at $path',
        cause: e,
      );
    } finally {
      await sink.close();
    }

    final bytes = await File(path).readAsBytes();
    final digest = sha256.convert(bytes);
    if (digest.toString() != DbConstants.dbSha256) {
      await File(path).delete();
      throw const IslamFlutterDatabaseException(
        'DB integrity check failed — file may be corrupted or tampered with.',
      );
    }

    await File('$path.version').writeAsString('$_dbVersion');
  }

  Future<sqflite.Database> _openDb(String path) async {
    try {
      return await sqflite.openDatabase(path);
    } on sqflite.DatabaseException catch (e) {
      throw IslamFlutterDatabaseException('Failed to open islam.db', cause: e);
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Deletes the cached DB and version marker, forcing a fresh download
  /// on next [init] or [database] access. Useful during development.
  Future<void> reset() async {
    await close();
    final path = await _dbPath();
    final file = File(path);
    if (await file.exists()) await file.delete();
    final vf = File('$path.version');
    if (await vf.exists()) await vf.delete();
  }
}
