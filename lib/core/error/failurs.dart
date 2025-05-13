// lib/core/error/failures.dart

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final List properties;
  final String message;

  const Failure({required this.message, this.properties = const <dynamic>[]})
    : super();

  @override
  List<Object?> get props => [message, ...properties];
}

// General failures
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'An unexpected server error occurred.'});
}

class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Failed to retrieve data from cache.'});
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message =
        'No internet connection. Please check your network settings.',
  });
}

// Authentication specific failures
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({
    super.message = 'Invalid email or password.',
  });
}

class UserNotFoundFailure extends Failure {
  const UserNotFoundFailure({super.message = 'User not found.'});
}

class EmailAlreadyInUseFailure extends Failure {
  const EmailAlreadyInUseFailure({
    super.message = 'The email address is already in use by another account.',
  });
}

class WeakPasswordFailure extends Failure {
  const WeakPasswordFailure({
    super.message = 'The password provided is too weak.',
  });
}

class OperationNotAllowedFailure extends Failure {
  const OperationNotAllowedFailure({
    super.message = 'Operation is not allowed.',
  });
}

class UserDisabledFailure extends Failure {
  const UserDisabledFailure({
    super.message = 'The user account has been disabled.',
  });
}

class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure({
    super.message = 'Too many requests. Please try again later.',
  });
}

class UnknownAuthFailure extends Failure {
  const UnknownAuthFailure({
    super.message = 'An unknown authentication error occurred.',
  });
}

// Location specific failures
class LocationPermissionDeniedFailure extends Failure {
  const LocationPermissionDeniedFailure({
    super.message = 'Location permission denied.',
  });
}

class LocationServiceDisabledFailure extends Failure {
  const LocationServiceDisabledFailure({
    super.message = 'Location services are disabled.',
  });
}

class LocationFetchFailure extends Failure {
  const LocationFetchFailure({
    super.message = 'Could not determine your location.',
  });
}
