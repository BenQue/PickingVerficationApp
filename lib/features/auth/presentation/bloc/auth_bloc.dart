import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/services/permission_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final PermissionService permissionService;

  AuthBloc({
    required this.authRepository,
    required this.permissionService,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthPermissionCheckRequested>(_onAuthPermissionCheckRequested);
    on<AuthInitialRouteRequested>(_onAuthInitialRouteRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(AuthSuccess(user: user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      final user = await authRepository.login(
        event.employeeId,
        event.password,
      );
      
      emit(AuthSuccess(user: user));
    } catch (e) {
      String errorMessage;
      
      // 优先使用底层异常的详细错误信息
      if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        
        // 如果错误信息为空或太通用，使用备用信息
        if (errorMessage.isEmpty || errorMessage == 'Exception') {
          errorMessage = '登录失败，请重试';
        }
      } else {
        errorMessage = '登录失败，请重试';
      }
      
      emit(AuthFailure(message: errorMessage));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthPermissionCheckRequested(
    AuthPermissionCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      if (permissionService.canAccessRoute(user, event.route)) {
        emit(AuthSuccess(user: user));
      } else {
        emit(AuthPermissionDenied(
          message: '您没有访问该功能的权限',
          route: event.route,
        ));
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthInitialRouteRequested(
    AuthInitialRouteRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await authRepository.getCurrentUser();
      if (user == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      final initialRoute = permissionService.getInitialRoute(user);
      if (initialRoute != null) {
        emit(AuthInitialRouteReady(route: initialRoute, user: user));
      } else {
        emit(AuthSuccess(user: user));
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }
}