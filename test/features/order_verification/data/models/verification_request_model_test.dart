import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/order_verification/data/models/verification_request_model.dart';

void main() {
  group('VerificationRequestModel', () {
    const testModel = VerificationRequestModel(
      scannedOrderId: 'SCAN123',
      expectedOrderId: 'EXP456',
      taskId: 'TASK789',
    );

    test('should create VerificationRequestModel with required properties', () {
      // Assert
      expect(testModel.scannedOrderId, equals('SCAN123'));
      expect(testModel.expectedOrderId, equals('EXP456'));
      expect(testModel.taskId, equals('TASK789'));
    });

    test('should serialize to JSON correctly', () {
      // Act
      final json = testModel.toJson();

      // Assert
      expect(json, equals({
        'scannedOrderId': 'SCAN123',
        'expectedOrderId': 'EXP456',
        'taskId': 'TASK789',
      }));
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'scannedOrderId': 'SCAN123',
        'expectedOrderId': 'EXP456',
        'taskId': 'TASK789',
      };

      // Act
      final model = VerificationRequestModel.fromJson(json);

      // Assert
      expect(model.scannedOrderId, equals('SCAN123'));
      expect(model.expectedOrderId, equals('EXP456'));
      expect(model.taskId, equals('TASK789'));
    });

    test('should handle JSON round-trip correctly', () {
      // Act
      final json = testModel.toJson();
      final jsonString = jsonEncode(json);
      final decodedJson = jsonDecode(jsonString) as Map<String, dynamic>;
      final recreatedModel = VerificationRequestModel.fromJson(decodedJson);

      // Assert
      expect(recreatedModel, equals(testModel));
    });

    test('should support equality comparison', () {
      // Arrange
      const model1 = VerificationRequestModel(
        scannedOrderId: 'SCAN123',
        expectedOrderId: 'EXP456',
        taskId: 'TASK789',
      );

      const model2 = VerificationRequestModel(
        scannedOrderId: 'SCAN123',
        expectedOrderId: 'EXP456',
        taskId: 'TASK789',
      );

      const model3 = VerificationRequestModel(
        scannedOrderId: 'DIFFERENT',
        expectedOrderId: 'EXP456',
        taskId: 'TASK789',
      );

      // Assert
      expect(model1, equals(model2));
      expect(model1, isNot(equals(model3)));
      expect(model1.hashCode, equals(model2.hashCode));
      expect(model1.hashCode, isNot(equals(model3.hashCode)));
    });
  });
}