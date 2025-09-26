import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final UserEntity user;

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPermissionDenied extends AuthState {
  final String message;
  final String route;

  const AuthPermissionDenied({
    required this.message,
    required this.route,
  });

  @override
  List<Object?> get props => [message, route];
}

class AuthInitialRouteReady extends AuthState {
  final String route;
  final UserEntity user;

  const AuthInitialRouteReady({
    required this.route,
    required this.user,
  });

  @override
  List<Object?> get props => [route, user];
}