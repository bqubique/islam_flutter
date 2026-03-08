/// Base exception for all islam_flutter errors.
class IslamFlutterException implements Exception {
  const IslamFlutterException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'IslamFlutterException: $message'
      '${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when a SQLite operation fails.
class IslamFlutterDatabaseException extends IslamFlutterException {
  const IslamFlutterDatabaseException(super.message, {super.cause});

  @override
  String toString() =>
      'IslamFlutterDatabaseException: $message'
      '${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when a requested record is not found.
class NotFoundException extends IslamFlutterException {
  const NotFoundException(super.message);

  @override
  String toString() => 'NotFoundException: $message';
}

/// Thrown when an asset file cannot be loaded.
class AssetLoadException extends IslamFlutterException {
  const AssetLoadException(super.message, {super.cause});

  @override
  String toString() =>
      'AssetLoadException: $message'
      '${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when JSON parsing fails.
class ParseException extends IslamFlutterException {
  const ParseException(super.message, {super.cause});

  @override
  String toString() =>
      'ParseException: $message'
      '${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when an HTTP request fails (prayer timings, hijri calendar).
class NetworkException extends IslamFlutterException {
  const NetworkException(super.message, {this.statusCode, super.cause});

  final int? statusCode;

  @override
  String toString() =>
      'NetworkException: $message'
      '${statusCode != null ? ' (status: $statusCode)' : ''}'
      '${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when an invalid argument is passed (e.g. chapter 0, verse -1).
class InvalidArgumentException extends IslamFlutterException {
  const InvalidArgumentException(super.message);

  @override
  String toString() => 'InvalidArgumentException: $message';
}
