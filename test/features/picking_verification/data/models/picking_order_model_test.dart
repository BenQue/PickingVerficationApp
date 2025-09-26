import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/data/models/picking_order_model.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/picking_order.dart';

void main() {
  group('PickingOrderModel Tests', () {
    final mockDateTime = DateTime(2024, 1, 1, 12, 0, 0);
    
    final mockJson = {
      'orderId': 'order123',
      'orderNumber': 'PO-2024-001',
      'status': 'verification',
      'createdAt': '2024-01-01T12:00:00.000',
      'updatedAt': '2024-01-01T13:00:00.000',
      'items': [
        {
          'itemId': 'item1',
          'productCode': 'P001',
          'productName': 'Product 1',
          'specification': 'Spec 1',
          'requiredQuantity': 10,
          'pickedQuantity': 10,
          'unit': 'pcs',
          'batchNumber': 'B20240101',
          'expiryDate': '2024-12-31T00:00:00.000',
          'location': 'A1-01',
          'isVerified': true,
        },
        {
          'itemId': 'item2',
          'productCode': 'P002',
          'productName': 'Product 2',
          'specification': 'Spec 2',
          'requiredQuantity': 5,
          'pickedQuantity': 5,
          'unit': 'pcs',
          'batchNumber': null,
          'expiryDate': null,
          'location': 'A1-02',
          'isVerified': false,
        },
      ],
      'customerInfo': 'Customer ABC',
      'notes': 'Test notes',
      'isVerified': false,
      'verifiedBy': 'user123',
      'verifiedAt': '2024-01-01T14:00:00.000',
    };

    final mockOrderModel = PickingOrderModel(
      orderId: 'order123',
      orderNumber: 'PO-2024-001',
      status: 'verification',
      createdAt: mockDateTime,
      updatedAt: mockDateTime.add(const Duration(hours: 1)),
      items: [
        const PickingItemModel(
          itemId: 'item1',
          productCode: 'P001',
          productName: 'Product 1',
          specification: 'Spec 1',
          requiredQuantity: 10,
          pickedQuantity: 10,
          unit: 'pcs',
          batchNumber: 'B20240101',
          expiryDate: null, // Will be set in individual tests
          location: 'A1-01',
          isVerified: true,
        ),
        const PickingItemModel(
          itemId: 'item2',
          productCode: 'P002',
          productName: 'Product 2',
          specification: 'Spec 2',
          requiredQuantity: 5,
          pickedQuantity: 5,
          unit: 'pcs',
          location: 'A1-02',
          isVerified: false,
        ),
      ],
      customerInfo: 'Customer ABC',
      notes: 'Test notes',
      isVerified: false,
      verifiedBy: 'user123',
      verifiedAt: mockDateTime.add(const Duration(hours: 2)),
    );

    test('should create PickingOrderModel from JSON', () {
      final result = PickingOrderModel.fromJson(mockJson);

      expect(result.orderId, 'order123');
      expect(result.orderNumber, 'PO-2024-001');
      expect(result.status, 'verification');
      expect(result.createdAt, DateTime(2024, 1, 1, 12, 0, 0));
      expect(result.updatedAt, DateTime(2024, 1, 1, 13, 0, 0));
      expect(result.items.length, 2);
      expect(result.customerInfo, 'Customer ABC');
      expect(result.notes, 'Test notes');
      expect(result.isVerified, false);
      expect(result.verifiedBy, 'user123');
      expect(result.verifiedAt, DateTime(2024, 1, 1, 14, 0, 0));
    });

    test('should handle null optional fields in JSON', () {
      final jsonWithNulls = {
        'orderId': 'order123',
        'orderNumber': 'PO-2024-001',
        'status': 'verification',
        'createdAt': '2024-01-01T12:00:00.000',
        'updatedAt': null,
        'items': [],
        'customerInfo': null,
        'notes': null,
        'isVerified': false,
        'verifiedBy': null,
        'verifiedAt': null,
      };

      final result = PickingOrderModel.fromJson(jsonWithNulls);

      expect(result.updatedAt, isNull);
      expect(result.customerInfo, isNull);
      expect(result.notes, isNull);
      expect(result.verifiedBy, isNull);
      expect(result.verifiedAt, isNull);
    });

    test('should convert PickingOrderModel to JSON', () {
      final result = mockOrderModel.toJson();

      expect(result['orderId'], 'order123');
      expect(result['orderNumber'], 'PO-2024-001');
      expect(result['status'], 'verification');
      expect(result['createdAt'], '2024-01-01T12:00:00.000');
      expect(result['updatedAt'], '2024-01-01T13:00:00.000');
      expect(result['items'], isA<List>());
      expect(result['items'].length, 2);
      expect(result['customerInfo'], 'Customer ABC');
      expect(result['notes'], 'Test notes');
      expect(result['isVerified'], false);
      expect(result['verifiedBy'], 'user123');
      expect(result['verifiedAt'], '2024-01-01T14:00:00.000');
    });

    test('should create PickingOrderModel from entity', () {
      final entity = PickingOrder(
        orderId: 'order123',
        orderNumber: 'PO-2024-001',
        status: 'verification',
        createdAt: mockDateTime,
        items: const [],
        isVerified: false,
      );

      final result = PickingOrderModel.fromEntity(entity);

      expect(result.orderId, entity.orderId);
      expect(result.orderNumber, entity.orderNumber);
      expect(result.status, entity.status);
      expect(result.createdAt, entity.createdAt);
      expect(result.isVerified, entity.isVerified);
    });
  });

  group('PickingItemModel Tests', () {
    final mockItemJson = {
      'itemId': 'item1',
      'productCode': 'P001',
      'productName': 'Product 1',
      'specification': 'Spec 1',
      'requiredQuantity': 10,
      'pickedQuantity': 8,
      'unit': 'pcs',
      'batchNumber': 'B20240101',
      'expiryDate': '2024-12-31T00:00:00.000',
      'location': 'A1-01',
      'isVerified': false,
    };

    const mockItemModel = PickingItemModel(
      itemId: 'item1',
      productCode: 'P001',
      productName: 'Product 1',
      specification: 'Spec 1',
      requiredQuantity: 10,
      pickedQuantity: 8,
      unit: 'pcs',
      batchNumber: 'B20240101',
      location: 'A1-01',
      isVerified: false,
    );

    test('should create PickingItemModel from JSON', () {
      final result = PickingItemModel.fromJson(mockItemJson);

      expect(result.itemId, 'item1');
      expect(result.productCode, 'P001');
      expect(result.productName, 'Product 1');
      expect(result.specification, 'Spec 1');
      expect(result.requiredQuantity, 10);
      expect(result.pickedQuantity, 8);
      expect(result.unit, 'pcs');
      expect(result.batchNumber, 'B20240101');
      expect(result.expiryDate, DateTime(2024, 12, 31));
      expect(result.location, 'A1-01');
      expect(result.isVerified, false);
    });

    test('should handle null optional fields in item JSON', () {
      final jsonWithNulls = Map<String, dynamic>.from(mockItemJson);
      jsonWithNulls['batchNumber'] = null;
      jsonWithNulls['expiryDate'] = null;

      final result = PickingItemModel.fromJson(jsonWithNulls);

      expect(result.batchNumber, isNull);
      expect(result.expiryDate, isNull);
    });

    test('should convert PickingItemModel to JSON', () {
      final result = mockItemModel.toJson();

      expect(result['itemId'], 'item1');
      expect(result['productCode'], 'P001');
      expect(result['productName'], 'Product 1');
      expect(result['requiredQuantity'], 10);
      expect(result['pickedQuantity'], 8);
      expect(result['unit'], 'pcs');
      expect(result['batchNumber'], 'B20240101');
      expect(result['location'], 'A1-01');
      expect(result['isVerified'], false);
    });

    test('should create PickingItemModel from entity', () {
      const entity = PickingItem(
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

      final result = PickingItemModel.fromEntity(entity);

      expect(result.itemId, entity.itemId);
      expect(result.productCode, entity.productCode);
      expect(result.productName, entity.productName);
      expect(result.requiredQuantity, entity.requiredQuantity);
      expect(result.pickedQuantity, entity.pickedQuantity);
      expect(result.isVerified, entity.isVerified);
    });

    test('should maintain entity functionality in model', () {
      const matchedItem = PickingItemModel(
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

      expect(mockItemModel.isQuantityMatched, false);
      expect(matchedItem.isQuantityMatched, true);
      expect(mockItemModel.quantityDifference, -2); // 8 - 10 = -2
      expect(matchedItem.quantityDifference, 0); // 10 - 10 = 0
    });
  });
}