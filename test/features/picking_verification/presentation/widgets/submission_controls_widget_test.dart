import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/picking_order.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/bloc/picking_verification_bloc.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/widgets/submission_controls_widget.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/services/navigation_service.dart';

class MockPickingVerificationBloc extends MockBloc<PickingVerificationEvent, PickingVerificationState>
    implements PickingVerificationBloc {}

class MockNavigationService extends Mock implements NavigationService {}

void main() {
  group('SubmissionControlsWidget', () {
    late MockPickingVerificationBloc mockBloc;
    late MockNavigationService mockNavigationService;
    late PickingOrder testOrder;

    setUp(() {
      mockBloc = MockPickingVerificationBloc();
      mockNavigationService = MockNavigationService();
      
      testOrder = PickingOrder(
        orderId: 'ORDER001',
        orderNumber: 'ORDER001',
        productionLineId: 'LINE_001',
        status: 'inProgress',
        createdAt: DateTime.now(),
        items: [],
        isVerified: false,
        materials: [
          MaterialItem(
            id: 'MAT001',
            materialCode: 'M001',
            description: '测试物料',
            plannedQuantity: 10,
            actualQuantity: 10,
            status: MaterialStatus.verified,
            location: 'A01-01',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockBloc.state).thenReturn(PickingVerificationInitial());
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<PickingVerificationBloc>(
            create: (_) => mockBloc,
            child: SubmissionControlsWidget(
              order: testOrder,
              navigationService: mockNavigationService,
            ),
          ),
        ),
      );
    }

    testWidgets('should display submit button with correct text', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('提交验证'), findsOneWidget);
      
      final submitButton = find.byType(ElevatedButton);
      expect(submitButton, findsOneWidget);
      
      final buttonWidget = tester.widget<ElevatedButton>(submitButton);
      expect(buttonWidget.child, isA<Text>());
    });

    testWidgets('should enable submit button when validation passes', (tester) async {
      when(() => mockBloc.state).thenReturn(PickingVerificationLoaded(
        order: testOrder,
        validationResults: [],
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final submitButton = find.byType(ElevatedButton);
      final buttonWidget = tester.widget<ElevatedButton>(submitButton);
      expect(buttonWidget.onPressed, isNotNull);
    });

    testWidgets('should disable submit button when validation fails', (tester) async {
      when(() => mockBloc.state).thenReturn(SubmissionValidationError(
        errors: ['验证失败'],
        order: testOrder,
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final submitButton = find.byType(ElevatedButton);
      final buttonWidget = tester.widget<ElevatedButton>(submitButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('should show progress indicator during submission', (tester) async {
      when(() => mockBloc.state).thenReturn(SubmissionInProgress(order: testOrder));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在提交...'), findsOneWidget);
      
      final submitButton = find.byType(ElevatedButton);
      final buttonWidget = tester.widget<ElevatedButton>(submitButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('should display validation errors', (tester) async {
      final validationErrors = ['物料数量不匹配', '缺少必要信息'];
      when(() => mockBloc.state).thenReturn(SubmissionValidationError(
        errors: validationErrors,
        order: testOrder,
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      for (final error in validationErrors) {
        expect(find.text(error), findsOneWidget);
      }
      
      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets('should dispatch SubmitVerificationEvent when submit button is pressed', (tester) async {
      when(() => mockBloc.state).thenReturn(PickingVerificationLoaded(
        order: testOrder,
        validationResults: [],
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final submitButton = find.byType(ElevatedButton);
      await tester.tap(submitButton);

      verify(() => mockBloc.add(any(that: isA<SubmitVerificationEvent>()))).called(1);
    });

    testWidgets('should show retry button on submission error', (tester) async {
      when(() => mockBloc.state).thenReturn(SubmissionError(
        errorType: SubmissionErrorType.networkError,
        message: '网络连接失败',
        order: testOrder,
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('重试'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should dispatch RetrySubmissionEvent when retry button is pressed', (tester) async {
      when(() => mockBloc.state).thenReturn(SubmissionError(
        errorType: SubmissionErrorType.networkError,
        message: '网络连接失败',
        order: testOrder,
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final retryButton = find.text('重试');
      await tester.tap(retryButton);

      verify(() => mockBloc.add(any(that: isA<RetrySubmissionEvent>()))).called(1);
    });

    testWidgets('should navigate to completion screen on submission success', (tester) async {
      when(() => mockBloc.state).thenReturn(SubmissionSuccess(
        submissionId: 'SUB001',
        timestamp: DateTime.now(),
        order: testOrder,
      ));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      verify(() => mockNavigationService.navigateToCompletion(any())).called(1);
    });

    testWidgets('should display different error messages based on error type', (tester) async {
      final errorScenarios = {
        SubmissionErrorType.networkError: '网络连接失败，请检查网络设置',
        SubmissionErrorType.serverError: '服务器错误，请稍后重试',
        SubmissionErrorType.validationError: '数据验证失败',
        SubmissionErrorType.timeoutError: '请求超时，请重试',
        SubmissionErrorType.authenticationError: '认证失败，请重新登录',
      };

      for (final entry in errorScenarios.entries) {
        when(() => mockBloc.state).thenReturn(SubmissionError(
          errorType: entry.key,
          message: entry.value,
          order: testOrder,
        ));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining(entry.value), findsOneWidget);
      }
    });

    testWidgets('should have proper accessibility features', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final submitButton = find.byType(ElevatedButton);
      final semantics = tester.getSemantics(submitButton);
      
      expect(semantics.label, contains('提交'));
      expect(semantics.hasEnabledState, isTrue);
    });

    testWidgets('should meet PDA design requirements', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final submitButton = find.byType(ElevatedButton);
      final buttonWidget = tester.widget<ElevatedButton>(submitButton);
      
      expect(buttonWidget.style?.minimumSize?.resolve({}), 
             equals(const Size(double.infinity, 56)));
      
      final text = tester.widget<Text>(find.text('提交验证'));
      expect(text.style?.fontSize, greaterThanOrEqualTo(18));
    });
  });
}