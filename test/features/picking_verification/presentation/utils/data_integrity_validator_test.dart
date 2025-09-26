import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/picking_order.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/utils/data_integrity_validator.dart';

void main() {
  group('DataIntegrityValidator', () {
    late PickingOrder validOrder;
    late List<MaterialItem> validMaterials;

    setUp(() {
      validMaterials = [
        const MaterialItem(
          id: 'MAT001',
          code: 'CODE001',
          name: '测试物料1',
          category: MaterialCategory.lineBreak,
          requiredQuantity: 10,
          availableQuantity: 10,
          status: MaterialStatus.completed,
          location: 'A-01-001',
          remarks: '正常物料',
        ),
        const MaterialItem(
          id: 'MAT002',
          code: 'CODE002',
          name: '测试物料2',
          category: MaterialCategory.centralWarehouse,
          requiredQuantity: 5,
          availableQuantity: 5,
          status: MaterialStatus.completed,
          location: 'B-02-003',
        ),
      ];

      validOrder = PickingOrder(
        orderId: 'ORDER001',
        orderNumber: 'ORD20250105001',
        productionLineId: 'LINE_001',
        materials: validMaterials,
        status: 'active',
        createdAt: DateTime.now(),
        items: [],
        isVerified: false,
      );
    });

    group('validateOrderDataIntegrity', () {
      test('should return valid result for well-formed order', () {
        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(validOrder);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.issues, isEmpty);
        expect(result.metadata['orderBasicInfoChecked'], isTrue);
        expect(result.metadata['materialsCount'], equals(2));
        expect(result.metadata['uniqueIds'], equals(2));
        expect(result.metadata['uniqueCodes'], equals(2));
      });

      test('should detect empty order number', () {
        // Arrange
        final orderWithEmptyNumber = validOrder.copyWith(orderNumber: '');

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithEmptyNumber);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.missingData && 
          i.description == '订单号为空'
        ), isTrue);
      });

      test('should detect invalid order number format', () {
        // Arrange
        final orderWithInvalidNumber = validOrder.copyWith(orderNumber: 'invalid@#\$%');

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithInvalidNumber);

        // Assert
        expect(result.isValid, isTrue); // Warning, not critical
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.invalidData && 
          i.description == '订单号格式不正确' &&
          i.severity == DataIntegrityIssueSeverity.warning
        ), isTrue);
      });

      test('should detect missing customer code', () {
        // Arrange
        final orderWithoutCustomerCode = validOrder.copyWith(customerCode: null);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithoutCustomerCode);

        // Assert
        expect(result.isValid, isTrue); // Warning, not critical
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.missingData && 
          i.description == '客户代码缺失' &&
          i.severity == DataIntegrityIssueSeverity.warning
        ), isTrue);
      });

      test('should detect empty material ID', () {
        // Arrange
        final materialsWithEmptyId = [
          validMaterials[0].copyWith(id: ''),
          validMaterials[1],
        ];
        final orderWithEmptyId = validOrder.copyWith(materials: materialsWithEmptyId);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithEmptyId);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.missingData && 
          i.description == '物料ID为空' &&
          i.severity == DataIntegrityIssueSeverity.critical
        ), isTrue);
      });

      test('should detect duplicate material IDs', () {
        // Arrange
        final materialsWithDuplicateId = [
          validMaterials[0],
          validMaterials[1].copyWith(id: 'MAT001'), // Duplicate ID
        ];
        final orderWithDuplicateId = validOrder.copyWith(materials: materialsWithDuplicateId);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithDuplicateId);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.duplicateData && 
          i.description == '物料ID重复: MAT001' &&
          i.severity == DataIntegrityIssueSeverity.critical
        ), isTrue);
      });

      test('should detect duplicate material codes', () {
        // Arrange
        final materialsWithDuplicateCode = [
          validMaterials[0],
          validMaterials[1].copyWith(code: 'CODE001'), // Duplicate code
        ];
        final orderWithDuplicateCode = validOrder.copyWith(materials: materialsWithDuplicateCode);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithDuplicateCode);

        // Assert
        expect(result.isValid, isTrue); // Warning, not critical
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.duplicateData && 
          i.description == '物料编码重复: CODE001' &&
          i.severity == DataIntegrityIssueSeverity.warning
        ), isTrue);
      });

      test('should detect missing material names', () {
        // Arrange
        final materialsWithEmptyName = [
          validMaterials[0].copyWith(name: ''),
          validMaterials[1],
        ];
        final orderWithEmptyName = validOrder.copyWith(materials: materialsWithEmptyName);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithEmptyName);

        // Assert
        expect(result.isValid, isTrue); // Warning, not critical
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.missingData && 
          i.description == '物料名称为空' &&
          i.severity == DataIntegrityIssueSeverity.warning
        ), isTrue);
      });

      test('should detect missing storage locations', () {
        // Arrange
        final materialsWithEmptyLocation = [
          validMaterials[0].copyWith(location: ''),
          validMaterials[1],
        ];
        final orderWithEmptyLocation = validOrder.copyWith(materials: materialsWithEmptyLocation);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithEmptyLocation);

        // Assert
        expect(result.isValid, isTrue); // Warning, not critical
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.missingData && 
          i.description == '存储位置为空' &&
          i.severity == DataIntegrityIssueSeverity.warning
        ), isTrue);
      });

      test('should detect status inconsistency - completed but insufficient quantity', () {
        // Arrange
        final materialsWithInconsistency = [
          validMaterials[0].copyWith(
            status: MaterialStatus.completed,
            requiredQuantity: 10,
            availableQuantity: 8, // Less than required but marked as completed
          ),
        ];
        final orderWithInconsistency = validOrder.copyWith(materials: materialsWithInconsistency);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithInconsistency);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.statusInconsistency && 
          i.description == '标记为完成但数量不足' &&
          i.severity == DataIntegrityIssueSeverity.critical
        ), isTrue);
      });

      test('should detect error status without remarks', () {
        // Arrange
        final materialsWithErrorNoRemarks = [
          validMaterials[0].copyWith(
            status: MaterialStatus.error,
            remarks: null,
          ),
        ];
        final orderWithErrorNoRemarks = validOrder.copyWith(materials: materialsWithErrorNoRemarks);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithErrorNoRemarks);

        // Assert
        expect(result.isValid, isTrue); // Warning, not critical
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.statusInconsistency && 
          i.description == '异常状态但无备注说明' &&
          i.severity == DataIntegrityIssueSeverity.warning
        ), isTrue);
      });

      test('should detect missing status with available quantity', () {
        // Arrange
        final materialsWithInconsistentMissing = [
          validMaterials[0].copyWith(
            status: MaterialStatus.missing,
            availableQuantity: 5, // Has quantity but marked as missing
          ),
        ];
        final orderWithInconsistentMissing = validOrder.copyWith(materials: materialsWithInconsistentMissing);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithInconsistentMissing);

        // Assert
        expect(result.isValid, isTrue); // Warning, not critical
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.statusInconsistency && 
          i.description == '标记为缺失但有可用数量' &&
          i.severity == DataIntegrityIssueSeverity.warning
        ), isTrue);
      });

      test('should detect invalid required quantity', () {
        // Arrange
        final materialsWithInvalidQuantity = [
          validMaterials[0].copyWith(requiredQuantity: 0),
        ];
        final orderWithInvalidQuantity = validOrder.copyWith(materials: materialsWithInvalidQuantity);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithInvalidQuantity);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.invalidData && 
          i.description == '需求数量必须大于0' &&
          i.severity == DataIntegrityIssueSeverity.critical
        ), isTrue);
      });

      test('should detect negative available quantity', () {
        // Arrange
        final materialsWithNegativeQuantity = [
          validMaterials[0].copyWith(availableQuantity: -1),
        ];
        final orderWithNegativeQuantity = validOrder.copyWith(materials: materialsWithNegativeQuantity);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithNegativeQuantity);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.invalidData && 
          i.description == '可用数量不能为负数' &&
          i.severity == DataIntegrityIssueSeverity.critical
        ), isTrue);
      });

      test('should detect unusually high available quantity', () {
        // Arrange
        final materialsWithHighQuantity = [
          validMaterials[0].copyWith(
            requiredQuantity: 10,
            availableQuantity: 25, // More than double the required quantity
          ),
        ];
        final orderWithHighQuantity = validOrder.copyWith(materials: materialsWithHighQuantity);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithHighQuantity);

        // Assert
        expect(result.isValid, isTrue); // Info level, not critical
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.quantityMismatch && 
          i.description == '可用数量异常高于需求数量' &&
          i.severity == DataIntegrityIssueSeverity.info
        ), isTrue);
      });

      test('should detect inconsistent data for same material code', () {
        // Arrange
        final materialsWithInconsistentData = [
          validMaterials[0],
          validMaterials[0].copyWith(
            id: 'MAT001_B',
            name: '不同名称', // Different name for same code
            unit: 'kg', // Different unit for same code
          ),
        ];
        final orderWithInconsistentData = validOrder.copyWith(materials: materialsWithInconsistentData);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithInconsistentData);

        // Assert
        expect(result.isValid, isTrue); // Warning level
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.duplicateData && 
          i.description == '相同编码的物料名称不一致'
        ), isTrue);
        expect(result.issues.any((i) => 
          i.type == DataIntegrityIssueType.duplicateData && 
          i.description == '相同编码的物料单位不一致'
        ), isTrue);
      });

      test('should populate metadata correctly', () {
        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(validOrder);

        // Assert
        expect(result.metadata['orderBasicInfoChecked'], isTrue);
        expect(result.metadata['orderNumber'], equals(validOrder.orderNumber));
        expect(result.metadata['materialsCount'], equals(2));
        expect(result.metadata['uniqueIds'], equals(2));
        expect(result.metadata['uniqueCodes'], equals(2));
        expect(result.metadata['statusDistribution'], isA<Map<MaterialStatus, int>>());
        expect(result.metadata['quantityIssuesCount'], equals(0));
        expect(result.metadata['duplicateCodeGroups'], equals(2));
      });

      test('should track status distribution correctly', () {
        // Arrange
        final mixedStatusMaterials = [
          validMaterials[0], // completed
          validMaterials[1].copyWith(status: MaterialStatus.pending),
        ];
        final orderWithMixedStatus = validOrder.copyWith(materials: mixedStatusMaterials);

        // Act
        final result = DataIntegrityValidator.validateOrderDataIntegrity(orderWithMixedStatus);

        // Assert
        final statusDistribution = result.metadata['statusDistribution'] as Map<MaterialStatus, int>;
        expect(statusDistribution[MaterialStatus.completed], equals(1));
        expect(statusDistribution[MaterialStatus.pending], equals(1));
      });
    });

    group('getValidationSummary', () {
      test('should provide correct summary for valid data', () {
        // Arrange
        final result = DataIntegrityValidator.validateOrderDataIntegrity(validOrder);

        // Act
        final summary = DataIntegrityValidator.getValidationSummary(result);

        // Assert
        expect(summary['isValid'], isTrue);
        expect(summary['totalIssues'], equals(0));
        expect(summary['criticalIssues'], equals(0));
        expect(summary['warningIssues'], equals(0));
        expect(summary['infoIssues'], equals(0));
        expect(summary['canProceedWithWarnings'], isTrue);
      });

      test('should provide correct summary with mixed severity issues', () {
        // Arrange
        final problemOrder = validOrder.copyWith(
          materials: [
            validMaterials[0].copyWith(id: ''), // Critical: empty ID
            validMaterials[1].copyWith(name: ''), // Warning: empty name
          ],
        );
        final result = DataIntegrityValidator.validateOrderDataIntegrity(problemOrder);

        // Act
        final summary = DataIntegrityValidator.getValidationSummary(result);

        // Assert
        expect(summary['isValid'], isFalse);
        expect(summary['totalIssues'], greaterThan(0));
        expect(summary['criticalIssues'], equals(1));
        expect(summary['warningIssues'], greaterThan(0));
        expect(summary['canProceedWithWarnings'], isFalse);
      });

      test('should allow proceeding with warnings only', () {
        // Arrange
        final warningOnlyOrder = validOrder.copyWith(
          materials: [
            validMaterials[0].copyWith(name: ''), // Warning: empty name
            validMaterials[1],
          ],
        );
        final result = DataIntegrityValidator.validateOrderDataIntegrity(warningOnlyOrder);

        // Act
        final summary = DataIntegrityValidator.getValidationSummary(result);

        // Assert
        expect(summary['isValid'], isTrue);
        expect(summary['criticalIssues'], equals(0));
        expect(summary['warningIssues'], greaterThan(0));
        expect(summary['canProceedWithWarnings'], isTrue);
      });
    });
  });
}