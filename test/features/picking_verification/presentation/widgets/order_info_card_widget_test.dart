import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/picking_order.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/widgets/order_info_card_widget.dart';

void main() {
  group('OrderInfoCardWidget Tests', () {
    final mockDateTime = DateTime(2024, 1, 1, 12, 0, 0);
    
    final mockItems = [
      const PickingItem(
        itemId: 'item1',
        productCode: 'P001',
        productName: 'Product 1',
        specification: 'Spec 1',
        requiredQuantity: 10,
        pickedQuantity: 10,
        unit: 'pcs',
        location: 'A1-01',
        isVerified: true,
      ),
      const PickingItem(
        itemId: 'item2',
        productCode: 'P002',
        productName: 'Product 2',
        specification: 'Spec 2',
        requiredQuantity: 5,
        pickedQuantity: 3,
        unit: 'pcs',
        location: 'A1-02',
        isVerified: false,
      ),
    ];

    final mockOrder = PickingOrder(
      orderId: 'order123',
      orderNumber: 'PO-2024-001',
      status: 'verification',
      createdAt: mockDateTime,
      items: mockItems,
      customerInfo: 'Customer ABC',
      notes: 'This is a test order',
      isVerified: false,
    );

    Widget createWidget({
      required PickingOrder order,
      bool isActivated = false,
      VoidCallback? onRefresh,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrderInfoCardWidget(
              order: order,
              isActivated: isActivated,
              onRefresh: onRefresh,
            ),
          ),
        ),
      );
    }

    testWidgets('should display order information correctly', (tester) async {
      await tester.pumpWidget(createWidget(order: mockOrder));

      // Check if order number is displayed
      expect(find.text('PO-2024-001'), findsOneWidget);
      
      // Check if order status is displayed
      expect(find.text('校验中'), findsOneWidget);
      
      // Check if customer info is displayed
      expect(find.text('Customer ABC'), findsOneWidget);
      
      // Check if notes are displayed
      expect(find.text('This is a test order'), findsOneWidget);
      
      // Check if creation time is displayed
      expect(find.text('2024-01-01 12:00'), findsOneWidget);
    });

    testWidgets('should display correct header for non-activated mode', (tester) async {
      await tester.pumpWidget(createWidget(order: mockOrder, isActivated: false));

      expect(find.text('合箱校验作业'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2), findsOneWidget);
    });

    testWidgets('should display correct header for activated mode', (tester) async {
      await tester.pumpWidget(createWidget(order: mockOrder, isActivated: true));

      expect(find.text('合箱校验已激活'), findsOneWidget);
      expect(find.text('模式已激活，可以开始校验'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display item summary correctly', (tester) async {
      await tester.pumpWidget(createWidget(order: mockOrder));

      // Check verified items count (1 out of 2 items verified)
      expect(find.text('1/2'), findsOneWidget);
      
      // Check picked quantity (13 out of 15 total required)
      expect(find.text('13/15'), findsOneWidget);
    });

    testWidgets('should display refresh button when onRefresh is provided', (tester) async {
      bool refreshCalled = false;
      
      await tester.pumpWidget(createWidget(
        order: mockOrder,
        onRefresh: () => refreshCalled = true,
      ));

      final refreshButton = find.byIcon(Icons.refresh);
      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pump();

      expect(refreshCalled, true);
    });

    testWidgets('should not display refresh button when onRefresh is null', (tester) async {
      await tester.pumpWidget(createWidget(order: mockOrder));

      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('should display different colors based on activation state', (tester) async {
      // Test non-activated state
      await tester.pumpWidget(createWidget(order: mockOrder, isActivated: false));
      
      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.color, Colors.blue.shade50);

      // Test activated state
      await tester.pumpWidget(createWidget(order: mockOrder, isActivated: true));
      await tester.pump();
      
      final activatedCardWidget = tester.widget<Card>(find.byType(Card));
      expect(activatedCardWidget.color, Colors.green.shade50);
    });

    testWidgets('should handle order without optional fields', (tester) async {
      final minimalOrder = PickingOrder(
        orderId: 'order123',
        orderNumber: 'PO-2024-001',
        status: 'pending',
        createdAt: mockDateTime,
        items: const [],
        isVerified: false,
      );

      await tester.pumpWidget(createWidget(order: minimalOrder));

      // Should still display basic info
      expect(find.text('PO-2024-001'), findsOneWidget);
      expect(find.text('待处理'), findsOneWidget);
      
      // Should not display optional fields
      expect(find.text('Customer ABC'), findsNothing);
      expect(find.byIcon(Icons.note_alt), findsNothing);
    });

    testWidgets('should display correct status text for different statuses', (tester) async {
      final statuses = {
        'pending': '待处理',
        'picking': '拣货中',
        'verification': '校验中',
        'completed': '已完成',
        'cancelled': '已取消',
        'unknown': 'unknown', // Should display as-is for unknown statuses
      };

      for (final entry in statuses.entries) {
        final orderWithStatus = mockOrder.copyWith(status: entry.key);
        
        await tester.pumpWidget(createWidget(order: orderWithStatus));
        
        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('should display verified order information when verified', (tester) async {
      final verifiedOrder = mockOrder.copyWith(
        isVerified: true,
        verifiedAt: mockDateTime.add(const Duration(hours: 2)),
      );

      await tester.pumpWidget(createWidget(order: verifiedOrder));

      // Should display verification time
      expect(find.text('2024-01-01 14:00'), findsOneWidget);
    });

    testWidgets('should display notes section when notes are provided', (tester) async {
      await tester.pumpWidget(createWidget(order: mockOrder));

      // Check if notes icon and text are displayed
      expect(find.byIcon(Icons.note_alt), findsOneWidget);
      expect(find.text('备注信息:'), findsOneWidget);
      expect(find.text('This is a test order'), findsOneWidget);
    });

    testWidgets('should not display notes section when notes are null', (tester) async {
      final orderWithoutNotes = PickingOrder(
        orderId: mockOrder.orderId,
        orderNumber: mockOrder.orderNumber,
        status: mockOrder.status,
        createdAt: mockOrder.createdAt,
        items: mockOrder.items,
        customerInfo: mockOrder.customerInfo,
        notes: null,
        isVerified: mockOrder.isVerified,
      );
      
      await tester.pumpWidget(createWidget(order: orderWithoutNotes));

      // Should not display notes section
      expect(find.byIcon(Icons.note_alt), findsNothing);
      expect(find.text('备注信息:'), findsNothing);
    });
  });
}