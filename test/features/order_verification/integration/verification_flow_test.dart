import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:picking_verification_app/features/order_verification/domain/entities/verification_result.dart' as domain;
import 'package:picking_verification_app/features/order_verification/domain/repositories/verification_repository.dart';

import 'package:picking_verification_app/features/order_verification/presentation/pages/order_verification_screen.dart';

import 'verification_flow_test.mocks.dart';

@GenerateMocks([VerificationRepository])
void main() {
  group('Verification Flow Integration Tests', () {
    late MockVerificationRepository mockRepository;

    setUp(() {
      mockRepository = MockVerificationRepository();
    });

    testWidgets('should complete successful verification flow', (tester) async {
      // Arrange
      when(mockRepository.verifyOrder(
        scannedOrderId: anyNamed('scannedOrderId'),
        expectedOrderId: anyNamed('expectedOrderId'),
      )).thenAnswer((_) async => domain.VerificationResult(
        orderId: 'ORD123',
        isValid: true,
        verifiedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<VerificationRepository>.value(
            value: mockRepository,
            child: const OrderVerificationScreen(
              taskId: 'TASK456',
              expectedOrderId: 'ORD123',
            ),
          ),
        ),
      );

      // Wait for initial state
      await tester.pumpAndSettle();

      // Assert initial screen
      expect(find.text('请验证订单号'), findsOneWidget);
      expect(find.text('ORD123'), findsOneWidget);
      expect(find.text('扫描二维码'), findsOneWidget);
      expect(find.text('手动输入订单号'), findsOneWidget);

      // Act - tap manual input
      await tester.tap(find.text('手动输入订单号'));
      await tester.pumpAndSettle();

      // Assert manual input screen appears
      expect(find.text('手动输入订单号'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);

      // Act - enter order number and submit
      await tester.enterText(find.byType(TextFormField), 'ORD123');
      await tester.tap(find.text('确认验证'));
      await tester.pumpAndSettle();

      // Wait for loading and success states
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Assert verification success
      expect(find.text('订单验证成功！'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('进入作业界面'), findsOneWidget);

      // Verify repository was called correctly
      verify(mockRepository.verifyOrder(
        scannedOrderId: 'ORD123',
        expectedOrderId: 'ORD123',
      )).called(1);
    });

    testWidgets('should handle verification failure flow', (tester) async {
      // Arrange
      when(mockRepository.verifyOrder(
        scannedOrderId: anyNamed('scannedOrderId'),
        expectedOrderId: anyNamed('expectedOrderId'),
      )).thenAnswer((_) async => domain.VerificationResult(
        orderId: 'ORD999',
        isValid: false,
        errorMessage: '订单号不匹配，请重新扫描',
        verifiedAt: DateTime.now(),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<VerificationRepository>.value(
            value: mockRepository,
            child: const OrderVerificationScreen(
              taskId: 'TASK456',
              expectedOrderId: 'ORD123',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - tap manual input
      await tester.tap(find.text('手动输入订单号'));
      await tester.pumpAndSettle();

      // Act - enter wrong order number and submit
      await tester.enterText(find.byType(TextFormField), 'ORD999');
      await tester.tap(find.text('确认验证'));
      await tester.pumpAndSettle();

      // Wait for loading and failure states
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Assert verification failure
      expect(find.text('订单号不匹配，请重新扫描'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('重新验证'), findsOneWidget);
      expect(find.text('返回任务列表'), findsOneWidget);

      // Assert mismatch warning is shown
      expect(find.text('订单号不匹配，请检查是否选择了正确的任务'), findsOneWidget);

      // Act - tap retry
      await tester.tap(find.text('重新验证'));
      await tester.pumpAndSettle();

      // Assert back to ready state
      expect(find.text('请验证订单号'), findsOneWidget);
      expect(find.text('扫描二维码'), findsOneWidget);
    });

    testWidgets('should handle network error during verification', (tester) async {
      // Arrange
      when(mockRepository.verifyOrder(
        scannedOrderId: anyNamed('scannedOrderId'),
        expectedOrderId: anyNamed('expectedOrderId'),
      )).thenThrow(Exception('Network connection failed'));

      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<VerificationRepository>.value(
            value: mockRepository,
            child: const OrderVerificationScreen(
              taskId: 'TASK456',
              expectedOrderId: 'ORD123',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - tap manual input and submit
      await tester.tap(find.text('手动输入订单号'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'ORD123');
      await tester.tap(find.text('确认验证'));
      await tester.pumpAndSettle();

      // Wait for error state
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Assert error message is displayed
      expect(find.textContaining('验证过程中出现错误'), findsOneWidget);
      expect(find.textContaining('Network connection failed'), findsOneWidget);
    });

    testWidgets('should validate manual input form', (tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<VerificationRepository>.value(
            value: mockRepository,
            child: const OrderVerificationScreen(
              taskId: 'TASK456',
              expectedOrderId: 'ORD123',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - open manual input
      await tester.tap(find.text('手动输入订单号'));
      await tester.pumpAndSettle();

      // Act - try to submit empty form
      await tester.tap(find.text('确认验证'));
      await tester.pump();

      // Assert validation error
      expect(find.text('请输入订单号'), findsOneWidget);

      // Act - enter short order number
      await tester.enterText(find.byType(TextFormField), 'AB');
      await tester.tap(find.text('确认验证'));
      await tester.pump();

      // Assert length validation error
      expect(find.text('订单号长度不能少于3位'), findsOneWidget);

      // Verify repository was not called due to validation failure
      verifyNever(mockRepository.verifyOrder(
        scannedOrderId: anyNamed('scannedOrderId'),
        expectedOrderId: anyNamed('expectedOrderId'),
      ));
    });

    testWidgets('should show loading state during verification', (tester) async {
      // Arrange
      when(mockRepository.verifyOrder(
        scannedOrderId: anyNamed('scannedOrderId'),
        expectedOrderId: anyNamed('expectedOrderId'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 500));
        return domain.VerificationResult(
          orderId: 'ORD123',
          isValid: true,
          verifiedAt: DateTime.now(),
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: RepositoryProvider<VerificationRepository>.value(
            value: mockRepository,
            child: const OrderVerificationScreen(
              taskId: 'TASK456',
              expectedOrderId: 'ORD123',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - submit verification
      await tester.tap(find.text('手动输入订单号'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'ORD123');
      await tester.tap(find.text('确认验证'));
      
      // Don't settle - check loading state
      await tester.pump(const Duration(milliseconds: 100));

      // Assert loading state
      expect(find.text('正在验证订单号...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for completion
      await tester.pumpAndSettle();

      // Assert success state
      expect(find.text('订单验证成功！'), findsOneWidget);
    });
  });
}