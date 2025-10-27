import 'package:equatable/equatable.dart';

/// Base Failure class for error handling
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];

  @override
  String toString() => message;
}

/// Server Failure - API errors
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Network Failure - Connectivity errors
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Cache Failure - Local storage errors
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Validation Failure - Input validation errors
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
