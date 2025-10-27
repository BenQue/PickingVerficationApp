/// Base Exception class for application errors
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

/// Server Exception - API errors
class ServerException extends AppException {
  ServerException(super.message);
}

/// Network Exception - Connectivity errors
class NetworkException extends AppException {
  NetworkException(super.message);
}

/// Cache Exception - Local storage errors
class CacheException extends AppException {
  CacheException(super.message);
}

/// Validation Exception - Input validation errors
class ValidationException extends AppException {
  ValidationException(super.message);
}
