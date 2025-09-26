import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String employeeId;
  final String password;

  const AuthLoginRequested({
    required this.employeeId,
    required this.password,
  });

  @override
  List<Object?> get props => [employeeId, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthPermissionCheckRequested extends AuthEvent {
  final String route;

  const AuthPermissionCheckRequested({required this.route});

  @override
  List<Object?> get props => [route];
}

class AuthInitialRouteRequested extends AuthEvent {
  const AuthInitialRouteRequested();
}