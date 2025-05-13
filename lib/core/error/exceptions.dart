// lib/core/error/exceptions.dart

class ServerException implements Exception {
  final String? message;
  final String? code;

  const ServerException({this.message, this.code});

  @override
  String toString() {
    return 'ServerException: ${code != null ? '($code) ' : ''}${message ?? 'An unexpected server error occurred.'}';
  }
}

class CacheException implements Exception {
  final String? message;
  const CacheException({this.message});
}

class LocationException implements Exception {
  final String? message;
  final String? code;
  const LocationException({this.message, this.code});
}
