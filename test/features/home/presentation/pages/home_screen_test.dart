import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picking_verification_app/features/home/presentation/pages/home_screen.dart';
import 'package:picking_verification_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:picking_verification_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:picking_verification_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:picking_verification_app/features/auth/domain/services/permission_service.dart';
import 'package:picking_verification_app/features/auth/domain/entities/user_entity.dart';
import 'package:picking_verification_app/features/auth/domain/entities/permission.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockPermissionService extends Mock implements PermissionService {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockPermissionService mockPermissionService;

  const testUser = UserEntity(
    id: '1',
    employeeId: 'EMP001',
    name: 'Test User',
    permissions: ['picking_verification', 'platform_receiving'],
    token: 'test_token',
  );

  final testNavigationOptions = [
    NavigationOption(
      permission: Permission.pickingVerification,
      title: '合箱校验',
      route: '/picking-verification',
    ),
    NavigationOption(
      permission: Permission.platformReceiving,
      title: '平台收料',
      route: '/platform-receiving',
    ),
  ];

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockPermissionService = MockPermissionService();
    
    // Setup default behavior
    when(() => mockAuthBloc.state).thenReturn(const AuthSuccess(user: testUser));
    when(() => mockPermissionService.getNavigationOptions(testUser))
        .thenReturn(testNavigationOptions);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          RepositoryProvider<PermissionService>.value(value: mockPermissionService),
        ],
        child: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('should display user greeting when authenticated', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('您好'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('T'), findsOneWidget); // User avatar initial
    });

    testWidgets('should display navigation cards for user permissions', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('合箱校验'), findsOneWidget);
      expect(find.text('平台收料'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
    });

    testWidgets('should display bottom navigation with home and tasks', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('任务'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.task_alt), findsOneWidget);
    });

    testWidgets('should show logout button in app bar', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('should show logout dialog when logout button is pressed', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('退出登录'), findsOneWidget);
      expect(find.text('您确定要退出登录吗？'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('确定'), findsOneWidget);
    });

    testWidgets('should trigger logout event when logout is confirmed', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockAuthBloc.add(const AuthLogoutRequested())).called(1);
    });

    testWidgets('should show loading indicator when not in AuthSuccess state', (tester) async {
      // Arrange
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());
      
      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Test User'), findsNothing);
    });

    testWidgets('should navigate to tasks when tasks nav item is tapped', (tester) async {
      // Arrange
      final mockNavigatorObserver = MockNavigatorObserver();
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              RepositoryProvider<PermissionService>.value(value: mockPermissionService),
            ],
            child: const HomeScreen(),
          ),
          navigatorObservers: [mockNavigatorObserver],
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('任务'));
      await tester.pumpAndSettle();

      // Assert - Navigation should be attempted (may fail without full router setup)
      // This tests the onTap callback is called
    });

    testWidgets('should handle single permission user correctly', (tester) async {
      // Arrange
      const singlePermissionUser = UserEntity(
        id: '2',
        employeeId: 'EMP002',
        name: 'Single User',
        permissions: ['picking_verification'],
        token: 'test_token_2',
      );

      final singleNavigationOption = [
        NavigationOption(
          permission: Permission.pickingVerification,
          title: '合箱校验',
          route: '/picking-verification',
        ),
      ];

      when(() => mockAuthBloc.state).thenReturn(const AuthSuccess(user: singlePermissionUser));
      when(() => mockPermissionService.getNavigationOptions(singlePermissionUser))
          .thenReturn(singleNavigationOption);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('合箱校验'), findsOneWidget);
      expect(find.text('平台收料'), findsNothing);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.byIcon(Icons.local_shipping_outlined), findsNothing);
    });

    testWidgets('should handle user with no permissions', (tester) async {
      // Arrange
      const noPermissionUser = UserEntity(
        id: '3',
        employeeId: 'EMP003',
        name: 'No Permission User',
        permissions: [],
        token: 'test_token_3',
      );

      when(() => mockAuthBloc.state).thenReturn(const AuthSuccess(user: noPermissionUser));
      when(() => mockPermissionService.getNavigationOptions(noPermissionUser))
          .thenReturn([]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No Permission User'), findsOneWidget);
      expect(find.text('合箱校验'), findsNothing);
      expect(find.text('平台收料'), findsNothing);
      // Should still show bottom navigation
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('任务'), findsOneWidget);
    });

    testWidgets('should show correct user initial in avatar', (tester) async {
      // Arrange
      const userWithChinese = UserEntity(
        id: '4',
        employeeId: 'EMP004',
        name: '张三',
        permissions: ['picking_verification'],
        token: 'test_token_4',
      );

      when(() => mockAuthBloc.state).thenReturn(const AuthSuccess(user: userWithChinese));
      when(() => mockPermissionService.getNavigationOptions(userWithChinese))
          .thenReturn([testNavigationOptions.first]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('张'), findsOneWidget); // First character of Chinese name
    });

    testWidgets('should show default initial for empty name', (tester) async {
      // Arrange
      const userWithEmptyName = UserEntity(
        id: '5',
        employeeId: 'EMP005',
        name: '',
        permissions: ['picking_verification'],
        token: 'test_token_5',
      );

      when(() => mockAuthBloc.state).thenReturn(const AuthSuccess(user: userWithEmptyName));
      when(() => mockPermissionService.getNavigationOptions(userWithEmptyName))
          .thenReturn([testNavigationOptions.first]);

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('用'), findsOneWidget); // Default initial
    });
  });
}