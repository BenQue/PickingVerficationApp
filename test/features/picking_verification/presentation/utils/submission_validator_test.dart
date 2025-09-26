import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/picking_order.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/utils/submission_validator.dart';

void main() {
  group('SubmissionValidator', () {
    late PickingOrder testOrder;
    late List<MaterialItem> testMaterials;

    setUp(() {
      testMaterials = [
        const MaterialItem(
          id: '1',
          code: 'MAT001',
          name: '测试物料1',
          category: MaterialCategory.lineBreak,
          requiredQuantity: 10,
          availableQuantity: 10,
          status: MaterialStatus.completed,
          location: 'A-01-001',
        ),
        const MaterialItem(
          id: '2',
          code: 'MAT002',
          name: '测试物料2',
          category: MaterialCategory.centralWarehouse,
          requiredQuantity: 5,
          availableQuantity: 5,
          status: MaterialStatus.completed,
          location: 'B-02-003',
        ),
        const MaterialItem(
          id: '3',
          code: 'MAT003',
          name: '测试物料3',
          category: MaterialCategory.automated,
          requiredQuantity: 8,
          availableQuantity: 8,
          status: MaterialStatus.completed,
          location: 'C-03-005',
        ),
      ];

      testOrder = PickingOrder(
        orderId: 'ORDER001',
        orderNumber: 'ORD20250105001',
        productionLineId: 'LINE_001',
        materials: testMaterials,
        status: 'active',
        createdAt: DateTime.now(),
        items: [],
        isVerified: false,
      );
    });

    group('validateOrderSubmission', () {
      test('should return valid result when all materials are completed', () {
        // Act
        final result = SubmissionValidator.validateOrderSubmission(testOrder);

        // Assert
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.completionPercentage, equals(1.0));
        expect(result.categoryCompletionStatus[MaterialCategory.lineBreak], equals(1));
        expect(result.categoryCompletionStatus[MaterialCategory.centralWarehouse], equals(1));
        expect(result.categoryCompletionStatus[MaterialCategory.automated], equals(1));
      });

      test('should return invalid result when some materials are pending', () {
        // Arrange
        final materialsWithPending = [
          testMaterials[0],
          testMaterials[1].copyWith(status: MaterialStatus.pending),
          testMaterials[2],
        ];
        final orderWithPending = testOrder.copyWith(materials: materialsWithPending);

        // Act
        final result = SubmissionValidator.validateOrderSubmission(orderWithPending);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('还有 1 个物料待处理'));
        expect(result.completionPercentage, equals(2.0 / 3.0));
      });

      test('should return invalid result when materials have errors', () {
        // Arrange
        final materialsWithError = [
          testMaterials[0].copyWith(status: MaterialStatus.error),
          testMaterials[1],
          testMaterials[2],
        ];
        final orderWithError = testOrder.copyWith(materials: materialsWithError);

        // Act
        final result = SubmissionValidator.validateOrderSubmission(orderWithError);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('有 1 个物料状态异常，需要处理'));
        expect(result.completionPercentage, equals(2.0 / 3.0));
      });

      test('should return invalid result when materials are missing', () {
        // Arrange
        final materialsWithMissing = [
          testMaterials[0],
          testMaterials[1].copyWith(status: MaterialStatus.missing),
          testMaterials[2],
        ];
        final orderWithMissing = testOrder.copyWith(materials: materialsWithMissing);

        // Act
        final result = SubmissionValidator.validateOrderSubmission(orderWithMissing);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('有 1 个物料缺失，需要确认'));
      });

      test('should return invalid result when order number is empty', () {
        // Arrange
        final orderWithEmptyNumber = testOrder.copyWith(orderNumber: '');

        // Act
        final result = SubmissionValidator.validateOrderSubmission(orderWithEmptyNumber);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('订单号不能为空'));
      });

      test('should return invalid result when order has no materials', () {
        // Arrange
        final orderWithNoMaterials = testOrder.copyWith(materials: []);

        // Act
        final result = SubmissionValidator.validateOrderSubmission(orderWithNoMaterials);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('订单中没有物料项目'));
        expect(result.completionPercentage, equals(0.0));
      });

      test('should detect incomplete data for materials', () {
        // Arrange
        final materialsWithIncompleteData = [
          const MaterialItem(
            id: '',
            code: '',
            name: '',
            category: MaterialCategory.lineBreak,
            requiredQuantity: 0,
            availableQuantity: 5,
            status: MaterialStatus.completed,
            location: 'A-01-001',
          ),
        ];
        final orderWithIncompleteData = testOrder.copyWith(materials: materialsWithIncompleteData);

        // Act
        final result = SubmissionValidator.validateOrderSubmission(orderWithIncompleteData);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('有 1 个物料数据不完整'));
      });

      test('should detect quantity mismatch for completed materials', () {
        // Arrange
        final materialsWithQuantityMismatch = [
          testMaterials[0].copyWith(
            status: MaterialStatus.completed,
            requiredQuantity: 10,
            availableQuantity: 8, // Less than required
          ),
        ];
        final orderWithQuantityMismatch = testOrder.copyWith(materials: materialsWithQuantityMismatch);

        // Act
        final result = SubmissionValidator.validateOrderSubmission(orderWithQuantityMismatch);

        // Assert
        expect(result.isValid, isFalse);
        expect(result.errors, contains('有 1 个物料数量不匹配'));
      });
    });

    group('canEnableSubmitButton', () {
      test('should return true when order is valid for submission', () {
        // Act
        final result = SubmissionValidator.canEnableSubmitButton(testOrder);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when order is not valid for submission', () {
        // Arrange
        final invalidOrder = testOrder.copyWith(
          materials: [testMaterials[0].copyWith(status: MaterialStatus.pending)],
        );

        // Act
        final result = SubmissionValidator.canEnableSubmitButton(invalidOrder);

        // Assert
        expect(result, isFalse);
      });
    });

    group('getSubmitButtonText', () {
      test('should return submit text when order is valid', () {
        // Act
        final result = SubmissionValidator.getSubmitButtonText(testOrder);

        // Assert
        expect(result, equals('提交校验'));
      });

      test('should return progress text when order is not complete', () {
        // Arrange
        final incompleteOrder = testOrder.copyWith(
          materials: [
            testMaterials[0],
            testMaterials[1].copyWith(status: MaterialStatus.pending),
          ],
        );

        // Act
        final result = SubmissionValidator.getSubmitButtonText(incompleteOrder);

        // Assert
        expect(result, contains('完成所有物料后提交'));
        expect(result, contains('50%')); // 1 out of 2 materials completed
      });
    });

    group('isCategoryCompleted', () {
      test('should return true when all materials in category are completed', () {
        // Act
        final result = SubmissionValidator.isCategoryCompleted(testOrder, MaterialCategory.lineBreak);

        // Assert
        expect(result, isTrue);
      });

      test('should return false when some materials in category are not completed', () {
        // Arrange
        final orderWithPending = testOrder.copyWith(
          materials: [testMaterials[0].copyWith(status: MaterialStatus.pending)],
        );

        // Act
        final result = SubmissionValidator.isCategoryCompleted(orderWithPending, MaterialCategory.lineBreak);

        // Assert
        expect(result, isFalse);
      });

      test('should return true when category has no materials', () {
        // Arrange
        final orderWithNoLineBreak = testOrder.copyWith(
          materials: testMaterials.where((m) => m.category != MaterialCategory.lineBreak).toList(),
        );

        // Act
        final result = SubmissionValidator.isCategoryCompleted(orderWithNoLineBreak, MaterialCategory.lineBreak);

        // Assert
        expect(result, isTrue);
      });
    });

    group('getCategoryCompletionProgress', () {
      test('should return 1.0 when all materials in category are completed', () {
        // Act
        final result = SubmissionValidator.getCategoryCompletionProgress(testOrder, MaterialCategory.lineBreak);

        // Assert
        expect(result, equals(1.0));
      });

      test('should return correct progress when some materials are completed', () {
        // Arrange
        final mixedMaterials = [
          testMaterials[0], // completed
          testMaterials[0].copyWith(id: '1b', status: MaterialStatus.pending), // pending
        ];
        final orderWithMixed = testOrder.copyWith(materials: mixedMaterials);

        // Act
        final result = SubmissionValidator.getCategoryCompletionProgress(orderWithMixed, MaterialCategory.lineBreak);

        // Assert
        expect(result, equals(0.5));
      });

      test('should return 1.0 when category has no materials', () {
        // Arrange
        final orderWithNoMaterials = testOrder.copyWith(materials: []);

        // Act
        final result = SubmissionValidator.getCategoryCompletionProgress(orderWithNoMaterials, MaterialCategory.lineBreak);

        // Assert
        expect(result, equals(1.0));
      });
    });

    group('getOverallCompletionProgress', () {
      test('should return 1.0 when all materials are completed', () {
        // Act
        final result = SubmissionValidator.getOverallCompletionProgress(testOrder);

        // Assert
        expect(result, equals(1.0));
      });

      test('should return correct progress with mixed materials', () {
        // Arrange
        final mixedMaterials = [
          testMaterials[0], // completed
          testMaterials[1].copyWith(status: MaterialStatus.pending), // pending
          testMaterials[2], // completed
        ];
        final orderWithMixed = testOrder.copyWith(materials: mixedMaterials);

        // Act
        final result = SubmissionValidator.getOverallCompletionProgress(orderWithMixed);

        // Assert
        expect(result, equals(2.0 / 3.0));
      });

      test('should return 0.0 when order has no materials', () {
        // Arrange
        final orderWithNoMaterials = testOrder.copyWith(materials: []);

        // Act
        final result = SubmissionValidator.getOverallCompletionProgress(orderWithNoMaterials);

        // Assert
        expect(result, equals(0.0));
      });
    });

    group('getBlockingIssues', () {
      test('should return empty list when no blocking issues exist', () {
        // Act
        final result = SubmissionValidator.getBlockingIssues(testOrder);

        // Assert
        expect(result, isEmpty);
      });

      test('should detect error materials as blocking issues', () {
        // Arrange
        final materialsWithError = [testMaterials[0].copyWith(status: MaterialStatus.error)];
        final orderWithError = testOrder.copyWith(materials: materialsWithError);

        // Act
        final result = SubmissionValidator.getBlockingIssues(orderWithError);

        // Assert
        expect(result, contains('有 1 个物料状态异常'));
      });

      test('should detect missing materials as blocking issues', () {
        // Arrange
        final materialsWithMissing = [testMaterials[0].copyWith(status: MaterialStatus.missing)];
        final orderWithMissing = testOrder.copyWith(materials: materialsWithMissing);

        // Act
        final result = SubmissionValidator.getBlockingIssues(orderWithMissing);

        // Assert
        expect(result, contains('有 1 个物料缺失'));
      });

      test('should detect quantity shortfall as blocking issues', () {
        // Arrange
        final materialsWithShortfall = [
          testMaterials[0].copyWith(
            requiredQuantity: 10,
            availableQuantity: 8,
          ),
        ];
        final orderWithShortfall = testOrder.copyWith(materials: materialsWithShortfall);

        // Act
        final result = SubmissionValidator.getBlockingIssues(orderWithShortfall);

        // Assert
        expect(result, contains('有 1 个物料数量不足'));
      });

      test('should detect multiple blocking issues', () {
        // Arrange
        final problematicMaterials = [
          testMaterials[0].copyWith(status: MaterialStatus.error),
          testMaterials[1].copyWith(status: MaterialStatus.missing),
          testMaterials[2].copyWith(requiredQuantity: 10, availableQuantity: 5),
        ];
        final orderWithProblems = testOrder.copyWith(materials: problematicMaterials);

        // Act
        final result = SubmissionValidator.getBlockingIssues(orderWithProblems);

        // Assert
        expect(result.length, equals(3));
        expect(result, contains('有 1 个物料状态异常'));
        expect(result, contains('有 1 个物料缺失'));
        expect(result, contains('有 1 个物料数量不足'));
      });
    });
  });

  group('SubmissionGuard', () {
    setUp(() {
      // Reset guard state before each test
      SubmissionGuard.reset();
    });

    test('should allow submission initially', () {
      // Act
      final canSubmit = SubmissionGuard.canSubmit();

      // Assert
      expect(canSubmit, isTrue);
      expect(SubmissionGuard.getCurrentState(), equals(SubmissionState.idle));
    });

    test('should prevent submission when already submitting', () {
      // Arrange
      SubmissionGuard.startSubmission();

      // Act
      final canSubmit = SubmissionGuard.canSubmit();

      // Assert
      expect(canSubmit, isFalse);
      expect(SubmissionGuard.getCurrentState(), equals(SubmissionState.submitting));
    });

    test('should allow submission after completion', () {
      // Arrange
      SubmissionGuard.startSubmission();
      SubmissionGuard.completeSubmission();

      // Act
      final canSubmit = SubmissionGuard.canSubmit();

      // Assert
      expect(canSubmit, isTrue);
      expect(SubmissionGuard.getCurrentState(), equals(SubmissionState.completed));
    });

    test('should allow submission after failure', () {
      // Arrange
      SubmissionGuard.startSubmission();
      SubmissionGuard.failSubmission();

      // Act
      final canSubmit = SubmissionGuard.canSubmit();

      // Assert
      expect(canSubmit, isTrue);
      expect(SubmissionGuard.getCurrentState(), equals(SubmissionState.failed));
    });

    test('should prevent rapid successive submissions', () async {
      // Arrange
      SubmissionGuard.startSubmission();
      SubmissionGuard.completeSubmission();

      // Act - try to submit immediately after completion
      final canSubmitImmediately = SubmissionGuard.canSubmit();

      // Wait for minimum interval
      await Future.delayed(const Duration(milliseconds: 2100));
      final canSubmitAfterDelay = SubmissionGuard.canSubmit();

      // Assert
      expect(canSubmitImmediately, isFalse);
      expect(canSubmitAfterDelay, isTrue);
    });

    test('should provide correct state descriptions', () {
      // Test each state
      expect(SubmissionGuard.getStateDescription(), equals('空闲'));
      
      SubmissionGuard.startSubmission();
      expect(SubmissionGuard.getStateDescription(), equals('提交中'));
      
      SubmissionGuard.completeSubmission();
      expect(SubmissionGuard.getStateDescription(), equals('已完成'));
      
      SubmissionGuard.failSubmission();
      expect(SubmissionGuard.getStateDescription(), equals('失败'));
      
      SubmissionGuard.reset();
      expect(SubmissionGuard.getStateDescription(), equals('空闲'));
    });

    test('should handle reset correctly', () {
      // Arrange
      SubmissionGuard.startSubmission();

      // Act
      SubmissionGuard.reset();

      // Assert
      expect(SubmissionGuard.getCurrentState(), equals(SubmissionState.idle));
      expect(SubmissionGuard.canSubmit(), isTrue);
    });
  });
}