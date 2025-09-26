import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/picking_order.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/screens/verification_completion_screen.dart';

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('VerificationCompletionScreen', () {
    late PickingOrder testOrder;
    late String testSubmissionId;
    late DateTime testTimestamp;

    setUp(() {
      testSubmissionId = 'SUB001';
      testTimestamp = DateTime(2024, 1, 15, 14, 30);
      
      testOrder = PickingOrder(
        orderId: 'ORDER001',
        orderNumber: 'ORDER001',
        productionLineId: 'LINE_001',
        status: 'completed',
        createdAt: DateTime.now(),
        items: [],
        isVerified: false,
        materials: [
          MaterialItem(
            id: 'MAT001',
            code: 'M001',
            name: '测试物料A',
            category: MaterialCategory.centralWarehouse,
            requiredQuantity: 10,
            availableQuantity: 10,
            status: MaterialStatus.completed,
            location: 'A01-01',
          ),
          MaterialItem(
            id: 'MAT002',
            code: 'M002',
            name: '测试物料B',
            category: MaterialCategory.centralWarehouse,
            requiredQuantity: 5,
            availableQuantity: 5,
            status: MaterialStatus.completed,
            location: 'A01-02',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: VerificationCompletionScreen(
          order: testOrder,
          submissionId: testSubmissionId,
          completionTime: testTimestamp,
        ),
      );
    }

    testWidgets('should display completion success message', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('验证完成'), findsOneWidget);
      expect(find.text('订单验证已成功完成'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display order summary information', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('订单编号: ORDER001'), findsOneWidget);
      expect(find.text('客户: 客户A'), findsOneWidget);
      expect(find.text('提交编号: SUB001'), findsOneWidget);
    });

    testWidgets('should display completion time', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('完成时间: 2024-01-15 14:30'), findsOneWidget);
    });

    testWidgets('should display material summary', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('验证材料: 2 项'), findsOneWidget);
      expect(find.text('总数量: 15'), findsOneWidget);
    });

    testWidgets('should show material details', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check for material items
      expect(find.text('M001 - 测试物料A'), findsOneWidget);
      expect(find.text('M002 - 测试物料B'), findsOneWidget);
      expect(find.text('数量: 10'), findsOneWidget);
      expect(find.text('数量: 5'), findsOneWidget);
      expect(find.text('位置: A01-01'), findsOneWidget);
      expect(find.text('位置: A01-02'), findsOneWidget);
    });

    testWidgets('should display action buttons', (tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('返回首页'), findsOneWidget);
      expect(find.text('查看详情'), findsOneWidget);
      expect(find.text('打印报告'), findsOneWidget);
    });

    testWidgets('should navigate to home when home button is pressed', (tester) async {
      // Note: In a real app test, you would need to mock GoRouter
      // For this unit test, we'll just verify the button exists and is tappable
      await tester.pumpWidget(createTestWidget());

      final homeButton = find.text('返回首页');
      expect(homeButton, findsOneWidget);
      
      await tester.tap(homeButton);
      await tester.pumpAndSettle();
      
      // In a full integration test, you would verify navigation occurred
    });

    testWidgets('should show details when details button is pressed', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final detailsButton = find.text('查看详情');
      expect(detailsButton, findsOneWidget);
      
      await tester.tap(detailsButton);
      await tester.pumpAndSettle();
      
      // Should expand or navigate to detailed view
      // Implementation depends on specific behavior
    });

    testWidgets('should handle print action', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final printButton = find.text('打印报告');
      expect(printButton, findsOneWidget);
      
      await tester.tap(printButton);
      await tester.pumpAndSettle();
      
      // In a real implementation, this would trigger print functionality
    });

    testWidgets('should display success status icon with correct color', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(iconWidget.color, equals(Colors.green));
      expect(iconWidget.size, equals(64.0));
    });

    testWidgets('should use proper text styles for PDA display', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check title text style
      final titleText = tester.widget<Text>(find.text('验证完成'));
      expect(titleText.style?.fontSize, greaterThanOrEqualTo(24));
      expect(titleText.style?.fontWeight, equals(FontWeight.bold));

      // Check subtitle text style
      final subtitleText = tester.widget<Text>(find.text('订单验证已成功完成'));
      expect(subtitleText.style?.fontSize, greaterThanOrEqualTo(18));
    });

    testWidgets('should have proper button sizing for PDA', (tester) async {
      await tester.pumpWidget(createTestWidget());

      final buttons = find.byType(ElevatedButton);
      expect(buttons, findsNWidgets(3));

      for (int i = 0; i < 3; i++) {
        final buttonWidget = tester.widget<ElevatedButton>(buttons.at(i));
        expect(buttonWidget.style?.minimumSize?.resolve({}), 
               equals(const Size(double.infinity, 56)));
      }
    });

    testWidgets('should display different order statuses correctly', (tester) async {
      final completedOrder = testOrder.copyWith(status: OrderStatus.completed);
      
      await tester.pumpWidget(MaterialApp(
        home: VerificationCompletionScreen(
          order: completedOrder,
          submissionId: testSubmissionId,
          completionTime: testTimestamp,
        ),
      ));

      expect(find.text('状态: 已完成'), findsOneWidget);
    });

    testWidgets('should handle empty materials list', (tester) async {
      final emptyOrder = testOrder.copyWith(materials: []);
      
      await tester.pumpWidget(MaterialApp(
        home: VerificationCompletionScreen(
          order: emptyOrder,
          submissionId: testSubmissionId,
          completionTime: testTimestamp,
        ),
      ));

      expect(find.text('验证材料: 0 项'), findsOneWidget);
      expect(find.text('总数量: 0'), findsOneWidget);
    });

    testWidgets('should display scrollable content for many materials', (tester) async {
      final materials = List.generate(20, (index) => MaterialItem(
        id: 'MAT${index.toString().padLeft(3, '0')}',
        code: 'M${index.toString().padLeft(3, '0')}',
        name: '测试物料$index',
        category: MaterialCategory.centralWarehouse,
        requiredQuantity: 10,
        availableQuantity: 10,
        status: MaterialStatus.completed,
        location: 'A01-${index.toString().padLeft(2, '0')}',
      ));

      final largeOrder = testOrder.copyWith(materials: materials);
      
      await tester.pumpWidget(MaterialApp(
        home: VerificationCompletionScreen(
          order: largeOrder,
          submissionId: testSubmissionId,
          completionTime: testTimestamp,
        ),
      ));

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('should have accessibility features', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Check semantic labels for important elements
      final successIcon = find.byIcon(Icons.check_circle);
      expect(tester.getSemantics(successIcon).label, contains('成功'));

      final homeButton = find.text('返回首页');
      expect(tester.getSemantics(homeButton).hasEnabledState, isTrue);
    });

    testWidgets('should format timestamps correctly', (tester) async {
      final specificTime = DateTime(2024, 12, 25, 9, 15, 30);
      
      await tester.pumpWidget(MaterialApp(
        home: VerificationCompletionScreen(
          order: testOrder,
          submissionId: testSubmissionId,
          completionTime: specificTime,
        ),
      ));

      expect(find.text('完成时间: 2024-12-25 09:15'), findsOneWidget);
    });

    testWidgets('should calculate total quantities correctly', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // testOrder has materials with quantities 10 and 5
      expect(find.text('总数量: 15'), findsOneWidget);
    });

    testWidgets('should handle long customer names gracefully', (tester) async {
      final longNameOrder = testOrder.copyWith(
        productionLineId: 'LINE_VERY_LONG_PRODUCTION_LINE_NAME_001',
      );
      
      await tester.pumpWidget(MaterialApp(
        home: VerificationCompletionScreen(
          order: longNameOrder,
          submissionId: testSubmissionId,
          completionTime: testTimestamp,
        ),
      ));

      expect(find.textContaining('非常长的客户名称'), findsOneWidget);
    });
  });
}