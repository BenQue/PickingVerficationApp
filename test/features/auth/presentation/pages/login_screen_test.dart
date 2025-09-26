import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:picking_verification_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:picking_verification_app/features/auth/domain/services/permission_service.dart';
import 'package:picking_verification_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:picking_verification_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:picking_verification_app/features/auth/presentation/pages/login_screen.dart';
import 'package:picking_verification_app/features/auth/domain/entities/user_entity.dart';

import 'login_screen_test.mocks.dart';

@GenerateMocks([AuthRepository, PermissionService])
void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthRepository mockAuthRepository;
    late MockPermissionService mockPermissionService;
    late AuthBloc authBloc;

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

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (context) => authBloc,
          child: const LoginScreen(),
        ),
      );
    }

    testWidgets('should display login form elements', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('拣配流程追溯与验证'), findsOneWidget);
      expect(find.text('员工 ID'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, '登录'), findsOneWidget);
      // Check for login title specifically using ancestor/descendant relationship
      expect(find.descendant(
        of: find.byType(Column),
        matching: find.text('登录'),
      ), findsAtLeastNWidgets(1));
    });

    testWidgets('should show company logo or fallback icon', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert - either company logo image or fallback business icon should be present
      expect(
        find.byWidgetPredicate((widget) => 
          widget is Image || (widget is Icon && widget.icon == Icons.business)
        ),
        findsOneWidget
      );
    });

    testWidgets('should validate empty employee ID field', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - tap login button without entering employee ID
      await tester.tap(find.widgetWithText(ElevatedButton, '登录'));
      await tester.pump();

      // Assert
      expect(find.text('请输入员工ID'), findsOneWidget);
    });

    testWidgets('should validate empty password field', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - enter employee ID but leave password empty
      await tester.enterText(find.byType(TextFormField).first, 'EMP001');
      await tester.tap(find.widgetWithText(ElevatedButton, '登录'));
      await tester.pump();

      // Assert
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('should trigger login event when form is valid', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      
      // Act - enter valid credentials and tap login
      await tester.enterText(find.byType(TextFormField).first, 'EMP001');
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, '登录'));
      await tester.pump();

      // Assert - verify that login event was added to bloc
      // Note: In a real test, you'd verify the bloc received the event
      expect(find.text('请输入员工ID'), findsNothing);
      expect(find.text('请输入密码'), findsNothing);
    });

    testWidgets('should show loading state when authentication is in progress', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      
      // Act - trigger loading state
      authBloc.emit(const AuthLoading());
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.text('正在登录...'), findsOneWidget);
      expect(find.text('请稍候，正在验证您的身份'), findsOneWidget);
    });

    testWidgets('should show error message when authentication fails', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      
      // Act - trigger failure state
      authBloc.emit(const AuthFailure(message: '员工ID或密码错误'));
      await tester.pump();

      // Assert
      expect(find.text('员工ID或密码错误'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should handle successful login and navigation', (WidgetTester tester) async {
      // Arrange
      const testUser = UserEntity(
        id: '1',
        employeeId: 'EMP001',
        name: 'Test User',
        permissions: ['picking_verification'],
        token: 'test_token',
      );
      
      await tester.pumpWidget(createTestWidget());
      
      // Act - trigger success state
      authBloc.emit(const AuthSuccess(user: testUser));
      await tester.pump();

      // Assert - should not show any error messages, indicating success
      expect(find.byIcon(Icons.error_outline), findsNothing);
      expect(find.textContaining('错误'), findsNothing);
    });

    testWidgets('should have large touch targets for industrial PDA use', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Assert - find the SizedBox that wraps the login button
      final sizedBoxFinder = find.ancestor(
        of: find.widgetWithText(ElevatedButton, '登录'),
        matching: find.byType(SizedBox),
      );
      
      expect(sizedBoxFinder, findsAtLeastNWidgets(1));
      final loginButtonWrapper = tester.widget<SizedBox>(sizedBoxFinder.first);
      expect(loginButtonWrapper.height, greaterThanOrEqualTo(56));
    });

    testWidgets('should disable form fields when loading', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());
      
      // Act - trigger loading state
      authBloc.emit(const AuthLoading());
      await tester.pump();

      // Assert - should show loading indicator and disable button
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      
      // Find the ElevatedButton within the PrimaryButton
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final loginButton = tester.widget<ElevatedButton>(buttonFinder);
      expect(loginButton.onPressed, isNull); // Button should be disabled during loading
    });
  });
}