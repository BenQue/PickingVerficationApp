import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picking_verification_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:picking_verification_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:picking_verification_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:picking_verification_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:picking_verification_app/features/auth/domain/services/permission_service.dart';
import 'package:picking_verification_app/features/auth/domain/entities/user_entity.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockPermissionService extends Mock implements PermissionService {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;
  late MockPermissionService mockPermissionService;

  const testUser = UserEntity(
    id: '1',
    employeeId: 'EMP001',
    name: 'Test User',
    permissions: ['picking_verification'],
    token: 'test_token',
  );

  const multiPermissionUser = UserEntity(
    id: '2',
    employeeId: 'EMP002',
    name: 'Multi User',
    permissions: ['picking_verification', 'platform_receiving'],
    token: 'test_token_2',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockPermissionService = MockPermissionService();
    authBloc = AuthBloc(
      authRepository: mockAuthRepository,
      permissionService: mockPermissionService,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state should be AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    group('AuthCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit AuthSuccess when user is authenticated',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthSuccess(user: testUser),
        ],
        verify: (bloc) {
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthUnauthenticated when no user found',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthUnauthenticated when exception occurs',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenThrow(Exception('Database error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthCheckRequested()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );
    });

    group('AuthLoginRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit AuthLoading then AuthSuccess on successful login',
        build: () {
          when(() => mockAuthRepository.login('EMP001', 'password123'))
              .thenAnswer((_) async => testUser);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          employeeId: 'EMP001',
          password: 'password123',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthSuccess(user: testUser),
        ],
        verify: (bloc) {
          verify(() => mockAuthRepository.login('EMP001', 'password123')).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthLoading then AuthFailure on login failure',
        build: () {
          when(() => mockAuthRepository.login('EMP001', 'wrong_password'))
              .thenThrow(Exception('Invalid credentials'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLoginRequested(
          employeeId: 'EMP001',
          password: 'wrong_password',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthFailure(message: '登录失败，请重试'),
        ],
      );
    });

    group('AuthLogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit AuthUnauthenticated after successful logout',
        build: () {
          when(() => mockAuthRepository.logout())
              .thenAnswer((_) async {});
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
        verify: (bloc) {
          verify(() => mockAuthRepository.logout()).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthUnauthenticated even if logout fails',
        build: () {
          when(() => mockAuthRepository.logout())
              .thenThrow(Exception('Network error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthLogoutRequested()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );
    });

    group('AuthPermissionCheckRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit AuthSuccess when user has permission',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testUser);
          when(() => mockPermissionService.canAccessRoute(testUser, '/picking-verification'))
              .thenReturn(true);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthPermissionCheckRequested(
          route: '/picking-verification',
        )),
        expect: () => [
          const AuthSuccess(user: testUser),
        ],
        verify: (bloc) {
          verify(() => mockAuthRepository.getCurrentUser()).called(1);
          verify(() => mockPermissionService.canAccessRoute(testUser, '/picking-verification')).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthPermissionDenied when user lacks permission',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testUser);
          when(() => mockPermissionService.canAccessRoute(testUser, '/platform-receiving'))
              .thenReturn(false);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthPermissionCheckRequested(
          route: '/platform-receiving',
        )),
        expect: () => [
          const AuthPermissionDenied(
            message: '您没有访问该功能的权限',
            route: '/platform-receiving',
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthUnauthenticated when no user found',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthPermissionCheckRequested(
          route: '/picking-verification',
        )),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );
    });

    group('AuthInitialRouteRequested', () {
      blocTest<AuthBloc, AuthState>(
        'should emit AuthInitialRouteReady with correct route for single permission user',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testUser);
          when(() => mockPermissionService.getInitialRoute(testUser))
              .thenReturn('/picking-verification');
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthInitialRouteRequested()),
        expect: () => [
          const AuthInitialRouteReady(
            route: '/picking-verification',
            user: testUser,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthInitialRouteReady with home route for multi permission user',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => multiPermissionUser);
          when(() => mockPermissionService.getInitialRoute(multiPermissionUser))
              .thenReturn('/home');
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthInitialRouteRequested()),
        expect: () => [
          const AuthInitialRouteReady(
            route: '/home',
            user: multiPermissionUser,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthSuccess when getInitialRoute returns null',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => testUser);
          when(() => mockPermissionService.getInitialRoute(testUser))
              .thenReturn(null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthInitialRouteRequested()),
        expect: () => [
          const AuthSuccess(user: testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthUnauthenticated when no user found',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => null);
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthInitialRouteRequested()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'should emit AuthUnauthenticated when exception occurs',
        build: () {
          when(() => mockAuthRepository.getCurrentUser())
              .thenThrow(Exception('Storage error'));
          return authBloc;
        },
        act: (bloc) => bloc.add(const AuthInitialRouteRequested()),
        expect: () => [
          const AuthUnauthenticated(),
        ],
      );
    });
  });
}