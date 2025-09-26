import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/picking_order.dart';

void main() {
  group('PickingOrder Entity Tests', () {
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

    final pickingOrder = PickingOrder(
      orderId: 'order123',
      orderNumber: 'PO-2024-001',
      status: 'verification',
      createdAt: mockDateTime,
      items: mockItems,
      isVerified: false,
    );

    test('should create PickingOrder with required fields', () {
      expect(pickingOrder.orderId, 'order123');
      expect(pickingOrder.orderNumber, 'PO-2024-001');
      expect(pickingOrder.status, 'verification');
      expect(pickingOrder.createdAt, mockDateTime);
      expect(pickingOrder.items, mockItems);
      expect(pickingOrder.isVerified, false);
    });

    test('should create PickingOrder with optional fields', () {
      final orderWithOptionals = PickingOrder(
        orderId: 'order123',
        orderNumber: 'PO-2024-001',
        status: 'verification',
        createdAt: mockDateTime,
        updatedAt: mockDateTime.add(const Duration(hours: 1)),
        items: mockItems,
        customerInfo: 'Customer ABC',
        notes: 'Test notes',
        isVerified: true,
        verifiedBy: 'user123',
        verifiedAt: mockDateTime.add(const Duration(hours: 2)),
      );

      expect(orderWithOptionals.updatedAt, mockDateTime.add(const Duration(hours: 1)));
      expect(orderWithOptionals.customerInfo, 'Customer ABC');
      expect(orderWithOptionals.notes, 'Test notes');
      expect(orderWithOptionals.isVerified, true);
      expect(orderWithOptionals.verifiedBy, 'user123');
      expect(orderWithOptionals.verifiedAt, mockDateTime.add(const Duration(hours: 2)));
    });

    test('should support copyWith functionality', () {
      final updatedOrder = pickingOrder.copyWith(
        status: 'completed',
        isVerified: true,
        verifiedBy: 'user456',
      );

      expect(updatedOrder.status, 'completed');
      expect(updatedOrder.isVerified, true);
      expect(updatedOrder.verifiedBy, 'user456');
      // Unchanged fields should remain the same
      expect(updatedOrder.orderId, pickingOrder.orderId);
      expect(updatedOrder.orderNumber, pickingOrder.orderNumber);
      expect(updatedOrder.createdAt, pickingOrder.createdAt);
    });

    test('should support equality comparison', () {
      final sameOrder = PickingOrder(
        orderId: 'order123',
        orderNumber: 'PO-2024-001',
        status: 'verification',
        createdAt: mockDateTime,
        items: mockItems,
        isVerified: false,
      );

      final differentOrder = pickingOrder.copyWith(orderId: 'order456');

      expect(pickingOrder, equals(sameOrder));
      expect(pickingOrder, isNot(equals(differentOrder)));
    });
  });

  group('PickingItem Entity Tests', () {
    const pickingItem = PickingItem(
      itemId: 'item1',
      productCode: 'P001',
      productName: 'Product 1',
      specification: 'Spec 1',
      requiredQuantity: 10,
      pickedQuantity: 8,
      unit: 'pcs',
      location: 'A1-01',
      isVerified: false,
    );

    test('should create PickingItem with required fields', () {
      expect(pickingItem.itemId, 'item1');
      expect(pickingItem.productCode, 'P001');
      expect(pickingItem.productName, 'Product 1');
      expect(pickingItem.specification, 'Spec 1');
      expect(pickingItem.requiredQuantity, 10);
      expect(pickingItem.pickedQuantity, 8);
      expect(pickingItem.unit, 'pcs');
      expect(pickingItem.location, 'A1-01');
      expect(pickingItem.isVerified, false);
    });

    test('should create PickingItem with optional fields', () {
      final itemWithOptionals = pickingItem.copyWith(
        batchNumber: 'B20240101',
        expiryDate: DateTime(2024, 12, 31),
      );

      expect(itemWithOptionals.batchNumber, 'B20240101');
      expect(itemWithOptionals.expiryDate, DateTime(2024, 12, 31));
    });

    test('should check quantity match correctly', () {
      const matchedItem = PickingItem(
        itemId: 'item1',
        productCode: 'P001',
        productName: 'Product 1',
        specification: 'Spec 1',
        requiredQuantity: 10,
        pickedQuantity: 10,
        unit: 'pcs',
        location: 'A1-01',
        isVerified: true,
      );

      expect(pickingItem.isQuantityMatched, false);
      expect(matchedItem.isQuantityMatched, true);
    });

    test('should calculate quantity difference correctly', () {
      const overPickedItem = PickingItem(
        itemId: 'item1',
        productCode: 'P001',
        productName: 'Product 1',
        specification: 'Spec 1',
        requiredQuantity: 10,
        pickedQuantity: 12,
        unit: 'pcs',
        location: 'A1-01',
        isVerified: false,
      );

      expect(pickingItem.quantityDifference, -2); // 8 - 10 = -2
      expect(overPickedItem.quantityDifference, 2); // 12 - 10 = 2
    });

    test('should support copyWith functionality', () {
      final updatedItem = pickingItem.copyWith(
        pickedQuantity: 10,
        isVerified: true,
      );

      expect(updatedItem.pickedQuantity, 10);
      expect(updatedItem.isVerified, true);
      // Unchanged fields should remain the same
      expect(updatedItem.itemId, pickingItem.itemId);
      expect(updatedItem.productCode, pickingItem.productCode);
    });

    test('should support equality comparison', () {
      const sameItem = PickingItem(
        itemId: 'item1',
        productCode: 'P001',
        productName: 'Product 1',
        specification: 'Spec 1',
        requiredQuantity: 10,
        pickedQuantity: 8,
        unit: 'pcs',
        location: 'A1-01',
        isVerified: false,
      );

      final differentItem = pickingItem.copyWith(itemId: 'item2');

      expect(pickingItem, equals(sameItem));
      expect(pickingItem, isNot(equals(differentItem)));
    });
  });
}