/// Custom exception classes for RentNear
library;

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class StorageUploadException implements Exception {
  final String message;
  StorageUploadException(this.message);

  @override
  String toString() => 'StorageUploadException: $message';
}
