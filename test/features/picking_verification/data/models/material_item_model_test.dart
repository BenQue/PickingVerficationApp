import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/data/models/material_item_model.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';

void main() {
  group('MaterialItemModel', () {
    const testModel = MaterialItemModel(
      id: '1',
      code: 'MAT001',
      name: '测试物料',
      description: '测试物料描述',
      category: 'central_warehouse',
      requiredQuantity: 10,
      availableQuantity: 8,
      status: 'pending',
      location: 'A1-B2',
      unit: '个',
      remarks: '测试备注',
    );

    final testJson = {
      'id': '1',
      'code': 'MAT001',
      'name': '测试物料',
      'description': '测试物料描述',
      'category': 'central_warehouse',
      'required_quantity': 10,
      'available_quantity': 8,
      'status': 'pending',
      'location': 'A1-B2',
      'unit': '个',
      'remarks': '测试备注',
    };

    test('should create MaterialItemModel from JSON', () {
      final model = MaterialItemModel.fromJson(testJson);
      
      expect(model.id, '1');
      expect(model.code, 'MAT001');
      expect(model.name, '测试物料');
      expect(model.description, '测试物料描述');
      expect(model.category, 'central_warehouse');
      expect(model.requiredQuantity, 10);
      expect(model.availableQuantity, 8);
      expect(model.status, 'pending');
      expect(model.location, 'A1-B2');
      expect(model.unit, '个');
      expect(model.remarks, '测试备注');
    });

    test('should convert MaterialItemModel to JSON', () {
      final json = testModel.toJson();
      expect(json, testJson);
    });

    test('should convert MaterialItemModel to entity', () {
      final entity = testModel.toEntity();
      
      expect(entity.id, '1');
      expect(entity.code, 'MAT001');
      expect(entity.name, '测试物料');
      expect(entity.description, '测试物料描述');
      expect(entity.category, MaterialCategory.centralWarehouse);
      expect(entity.requiredQuantity, 10);
      expect(entity.availableQuantity, 8);
      expect(entity.status, MaterialStatus.pending);
      expect(entity.location, 'A1-B2');
      expect(entity.unit, '个');
      expect(entity.remarks, '测试备注');
    });

    test('should create MaterialItemModel from entity', () {
      const entity = MaterialItem(
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

      final model = MaterialItemModel.fromEntity(entity);
      
      expect(model.id, '1');
      expect(model.code, 'MAT001');
      expect(model.name, '测试物料');
      expect(model.description, '测试物料描述');
      expect(model.category, 'central_warehouse');
      expect(model.requiredQuantity, 10);
      expect(model.availableQuantity, 8);
      expect(model.status, 'pending');
      expect(model.location, 'A1-B2');
      expect(model.unit, '个');
      expect(model.remarks, '测试备注');
    });

    group('Category mapping', () {
      test('should map all category variations correctly', () {
        final lineBreakJson = {'category': 'line_break'};
        final lineBreakJson2 = {'category': 'linebreak'};
        final lineBreakJson3 = {'category': '断线物料'};
        
        expect(
          MaterialItemModel.fromJson({...testJson, ...lineBreakJson}).toEntity().category,
          MaterialCategory.lineBreak,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...lineBreakJson2}).toEntity().category,
          MaterialCategory.lineBreak,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...lineBreakJson3}).toEntity().category,
          MaterialCategory.lineBreak,
        );
        
        final centralJson = {'category': 'central_warehouse'};
        final centralJson2 = {'category': 'centralwarehouse'};
        final centralJson3 = {'category': '中央仓物料'};
        
        expect(
          MaterialItemModel.fromJson({...testJson, ...centralJson}).toEntity().category,
          MaterialCategory.centralWarehouse,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...centralJson2}).toEntity().category,
          MaterialCategory.centralWarehouse,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...centralJson3}).toEntity().category,
          MaterialCategory.centralWarehouse,
        );
        
        final automatedJson = {'category': 'automated'};
        final automatedJson2 = {'category': 'automation'};
        final automatedJson3 = {'category': '自动化库物料'};
        
        expect(
          MaterialItemModel.fromJson({...testJson, ...automatedJson}).toEntity().category,
          MaterialCategory.automated,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...automatedJson2}).toEntity().category,
          MaterialCategory.automated,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...automatedJson3}).toEntity().category,
          MaterialCategory.automated,
        );
      });

      test('should default to central warehouse for unknown category', () {
        final unknownJson = {'category': 'unknown'};
        expect(
          MaterialItemModel.fromJson({...testJson, ...unknownJson}).toEntity().category,
          MaterialCategory.centralWarehouse,
        );
      });
    });

    group('Status mapping', () {
      test('should map all status variations correctly', () {
        final pendingJson = {'status': 'pending'};
        final pendingJson2 = {'status': '待处理'};
        
        expect(
          MaterialItemModel.fromJson({...testJson, ...pendingJson}).toEntity().status,
          MaterialStatus.pending,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...pendingJson2}).toEntity().status,
          MaterialStatus.pending,
        );
        
        final inProgressJson = {'status': 'in_progress'};
        final inProgressJson2 = {'status': 'inprogress'};
        final inProgressJson3 = {'status': '处理中'};
        
        expect(
          MaterialItemModel.fromJson({...testJson, ...inProgressJson}).toEntity().status,
          MaterialStatus.inProgress,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...inProgressJson2}).toEntity().status,
          MaterialStatus.inProgress,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...inProgressJson3}).toEntity().status,
          MaterialStatus.inProgress,
        );
        
        final completedJson = {'status': 'completed'};
        final completedJson2 = {'status': 'complete'};
        final completedJson3 = {'status': '已完成'};
        
        expect(
          MaterialItemModel.fromJson({...testJson, ...completedJson}).toEntity().status,
          MaterialStatus.completed,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...completedJson2}).toEntity().status,
          MaterialStatus.completed,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...completedJson3}).toEntity().status,
          MaterialStatus.completed,
        );
        
        final errorJson = {'status': 'error'};
        final errorJson2 = {'status': '异常'};
        
        expect(
          MaterialItemModel.fromJson({...testJson, ...errorJson}).toEntity().status,
          MaterialStatus.error,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...errorJson2}).toEntity().status,
          MaterialStatus.error,
        );
        
        final missingJson = {'status': 'missing'};
        final missingJson2 = {'status': '缺失'};
        
        expect(
          MaterialItemModel.fromJson({...testJson, ...missingJson}).toEntity().status,
          MaterialStatus.missing,
        );
        expect(
          MaterialItemModel.fromJson({...testJson, ...missingJson2}).toEntity().status,
          MaterialStatus.missing,
        );
      });

      test('should default to pending for unknown status', () {
        final unknownJson = {'status': 'unknown'};
        expect(
          MaterialItemModel.fromJson({...testJson, ...unknownJson}).toEntity().status,
          MaterialStatus.pending,
        );
      });
    });
  });
}