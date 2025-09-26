import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';

void main() {
  group('MaterialItem', () {
    const testMaterialItem = MaterialItem(
      id: '1',
      code: 'MAT001',
      name: '测试物料',
      description: '测试物料描述',
      category: MaterialCategory.centralWarehouse,
      requiredQuantity: 10,
      availableQuantity: 8,
      status: MaterialStatus.pending,
      location: 'A1-B2',
      unit: '个',
      remarks: '测试备注',
    );

    test('should create MaterialItem with correct properties', () {
      expect(testMaterialItem.id, '1');
      expect(testMaterialItem.code, 'MAT001');
      expect(testMaterialItem.name, '测试物料');
      expect(testMaterialItem.description, '测试物料描述');
      expect(testMaterialItem.category, MaterialCategory.centralWarehouse);
      expect(testMaterialItem.requiredQuantity, 10);
      expect(testMaterialItem.availableQuantity, 8);
      expect(testMaterialItem.status, MaterialStatus.pending);
      expect(testMaterialItem.location, 'A1-B2');
      expect(testMaterialItem.unit, '个');
      expect(testMaterialItem.remarks, '测试备注');
    });

    test('should calculate isFulfilled correctly', () {
      expect(testMaterialItem.isFulfilled, false);

      const fulfilledItem = MaterialItem(
        id: '2',
        code: 'MAT002',
        name: '充足物料',
        category: MaterialCategory.automated,
        requiredQuantity: 5,
        availableQuantity: 10,
        status: MaterialStatus.completed,
        location: 'A2-B3',
      );
      expect(fulfilledItem.isFulfilled, true);

      const exactItem = MaterialItem(
        id: '3',
        code: 'MAT003',
        name: '刚好物料',
        category: MaterialCategory.lineBreak,
        requiredQuantity: 5,
        availableQuantity: 5,
        status: MaterialStatus.completed,
        location: 'A3-B4',
      );
      expect(exactItem.isFulfilled, true);
    });

    test('should calculate shortageQuantity correctly', () {
      expect(testMaterialItem.shortageQuantity, 2);

      const noShortageItem = MaterialItem(
        id: '2',
        code: 'MAT002',
        name: '充足物料',
        category: MaterialCategory.automated,
        requiredQuantity: 5,
        availableQuantity: 10,
        status: MaterialStatus.completed,
        location: 'A2-B3',
      );
      expect(noShortageItem.shortageQuantity, 0);
    });

    test('should copy with new values', () {
      final copiedItem = testMaterialItem.copyWith(
        availableQuantity: 10,
        status: MaterialStatus.completed,
      );

      expect(copiedItem.id, testMaterialItem.id);
      expect(copiedItem.code, testMaterialItem.code);
      expect(copiedItem.name, testMaterialItem.name);
      expect(copiedItem.availableQuantity, 10);
      expect(copiedItem.status, MaterialStatus.completed);
      expect(copiedItem.isFulfilled, true);
    });

    test('should support value equality', () {
      const item1 = MaterialItem(
        id: '1',
        code: 'MAT001',
        name: '测试物料',
        category: MaterialCategory.centralWarehouse,
        requiredQuantity: 10,
        availableQuantity: 8,
        status: MaterialStatus.pending,
        location: 'A1-B2',
      );

      const item2 = MaterialItem(
        id: '1',
        code: 'MAT001',
        name: '测试物料',
        category: MaterialCategory.centralWarehouse,
        requiredQuantity: 10,
        availableQuantity: 8,
        status: MaterialStatus.pending,
        location: 'A1-B2',
      );

      const item3 = MaterialItem(
        id: '2',
        code: 'MAT001',
        name: '测试物料',
        category: MaterialCategory.centralWarehouse,
        requiredQuantity: 10,
        availableQuantity: 8,
        status: MaterialStatus.pending,
        location: 'A1-B2',
      );

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
    });

    group('MaterialStatus', () {
      test('should have correct labels', () {
        expect(MaterialStatus.pending.label, '待处理');
        expect(MaterialStatus.inProgress.label, '处理中');
        expect(MaterialStatus.completed.label, '已完成');
        expect(MaterialStatus.error.label, '异常');
        expect(MaterialStatus.missing.label, '缺失');
      });
    });

    group('MaterialCategory', () {
      test('should have correct labels', () {
        expect(MaterialCategory.lineBreak.label, '断线物料');
        expect(MaterialCategory.centralWarehouse.label, '中央仓物料');
        expect(MaterialCategory.automated.label, '自动化库物料');
      });
    });
  });
}