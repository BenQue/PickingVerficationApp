import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/order_verification/presentation/widgets/verification_result_widget.dart';

void main() {
  group('VerificationResultWidget', () {
    testWidgets('should display success result correctly', (tester) async {
      // Arrange
      const widget = VerificationResultWidget(
        isSuccess: true,
        message: '验证成功！',
        scannedOrderId: 'ORD123',
        expectedOrderId: 'ORD123',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert
      expect(find.text('验证成功！'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('扫描结果:'), findsOneWidget);
      expect(find.text('期望订单号:'), findsOneWidget);
      expect(find.text('ORD123'), findsNWidgets(2));
      
      // Check success colors
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, equals(Colors.green.shade50));
      
      final icon = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(icon.color, equals(Colors.green));
    });

    testWidgets('should display failure result correctly', (tester) async {
      // Arrange
      const widget = VerificationResultWidget(
        isSuccess: false,
        message: '验证失败',
        scannedOrderId: 'ORD999',
        expectedOrderId: 'ORD123',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert
      expect(find.text('验证失败'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('扫描结果:'), findsOneWidget);
      expect(find.text('期望订单号:'), findsOneWidget);
      expect(find.text('ORD999'), findsOneWidget);
      expect(find.text('ORD123'), findsOneWidget);
      
      // Check failure colors
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, equals(Colors.red.shade50));
      
      final icon = tester.widget<Icon>(find.byIcon(Icons.error));
      expect(icon.color, equals(Colors.red));
    });

    testWidgets('should display mismatch warning when order IDs do not match', (tester) async {
      // Arrange
      const widget = VerificationResultWidget(
        isSuccess: false,
        message: '验证失败',
        scannedOrderId: 'ORD999',
        expectedOrderId: 'ORD123',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert
      expect(find.text('订单号不匹配，请检查是否选择了正确的任务'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('should not display warning when order IDs match even on failure', (tester) async {
      // Arrange
      const widget = VerificationResultWidget(
        isSuccess: false,
        message: '网络错误',
        scannedOrderId: 'ORD123',
        expectedOrderId: 'ORD123',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert
      expect(find.text('订单号不匹配，请检查是否选择了正确的任务'), findsNothing);
      expect(find.byIcon(Icons.warning), findsNothing);
    });

    testWidgets('should handle null scannedOrderId', (tester) async {
      // Arrange
      const widget = VerificationResultWidget(
        isSuccess: false,
        message: '扫描失败',
        scannedOrderId: null,
        expectedOrderId: 'ORD123',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert
      expect(find.text('扫描结果:'), findsNothing);
      expect(find.text('期望订单号:'), findsOneWidget);
      expect(find.text('ORD123'), findsOneWidget);
      
      // Should not show mismatch warning when scannedOrderId is null
      expect(find.text('订单号不匹配，请检查是否选择了正确的任务'), findsNothing);
    });

    testWidgets('should use monospace font family for order numbers', (tester) async {
      // Arrange
      const widget = VerificationResultWidget(
        isSuccess: true,
        message: '验证成功',
        scannedOrderId: 'ORD123',
        expectedOrderId: 'ORD123',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Assert
      final orderNumberTexts = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(Container),
          matching: find.text('ORD123'),
        ),
      );

      for (final text in orderNumberTexts) {
        expect(text.style?.fontFamily, equals('monospace'));
        expect(text.style?.fontWeight, equals(FontWeight.bold));
      }
    });
  });
}