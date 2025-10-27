import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/data/models/line_stock_model.dart';
import 'package:picking_verification_app/features/line_stock/domain/entities/line_stock_entity.dart';

void main() {
  group('LineStockModel Tests', () {
    const testLineStockModel = LineStockModel(
      stockId: 12345,
      materialCode: 'C100001',
      materialDesc: 'Test Cable Material',
      quantity: 150.5,
      baseUnit: 'M',
      batchCode: 'BATCH-2025-001',
      locationCode: 'A-01-05',
      barcode: 'BC123456789',
    );

    const testJson = {
      'stockId': 12345,
      'materialCode': 'C100001',
      'materialDesc': 'Test Cable Material',
      'quantity': 150.5,
      'baseUnit': 'M',
      'batchCode': 'BATCH-2025-001',
      'locationCode': 'A-01-05',
      'barcode': 'BC123456789',
    };

    group('JSON Serialization', () {
      test('should create LineStockModel from complete JSON', () {
        // Act
        final result = LineStockModel.fromJson(testJson);

        // Assert
        expect(result.stockId, 12345);
        expect(result.materialCode, 'C100001');
        expect(result.materialDesc, 'Test Cable Material');
        expect(result.quantity, 150.5);
        expect(result.baseUnit, 'M');
        expect(result.batchCode, 'BATCH-2025-001');
        expect(result.locationCode, 'A-01-05');
        expect(result.barcode, 'BC123456789');
      });

      test('should convert LineStockModel to JSON', () {
        // Act
        final result = testLineStockModel.toJson();

        // Assert
        expect(result, testJson);
      });

      test('should handle JSON with null values', () {
        // Arrange
        const jsonWithNulls = {
          'stockId': null,
          'materialCode': null,
          'materialDesc': null,
          'quantity': null,
          'baseUnit': null,
          'batchCode': null,
          'locationCode': null,
          'barcode': null,
        };

        // Act
        final result = LineStockModel.fromJson(jsonWithNulls);

        // Assert
        expect(result.stockId, isNull);
        expect(result.materialCode, isNull);
        expect(result.materialDesc, isNull);
        expect(result.quantity, isNull);
        expect(result.baseUnit, isNull);
        expect(result.batchCode, isNull);
        expect(result.locationCode, isNull);
        expect(result.barcode, isNull);
      });

      test('should handle JSON with partial values', () {
        // Arrange
        const partialJson = {
          'materialCode': 'C100001',
          'materialDesc': 'Test Cable',
          'quantity': 100.0,
        };

        // Act
        final result = LineStockModel.fromJson(partialJson);

        // Assert
        expect(result.materialCode, 'C100001');
        expect(result.materialDesc, 'Test Cable');
        expect(result.quantity, 100.0);
        expect(result.stockId, isNull);
        expect(result.baseUnit, isNull);
        expect(result.batchCode, isNull);
        expect(result.locationCode, isNull);
        expect(result.barcode, isNull);
      });

      test('should handle quantity as integer in JSON', () {
        // Arrange
        const jsonWithIntQuantity = {
          'quantity': 150,
        };

        // Act
        final result = LineStockModel.fromJson(jsonWithIntQuantity);

        // Assert
        expect(result.quantity, 150.0);
        expect(result.quantity, isA<double>());
      });

      test('should handle quantity as double in JSON', () {
        // Arrange
        const jsonWithDoubleQuantity = {
          'quantity': 150.75,
        };

        // Act
        final result = LineStockModel.fromJson(jsonWithDoubleQuantity);

        // Assert
        expect(result.quantity, 150.75);
        expect(result.quantity, isA<double>());
      });

      test('should convert model with null values to JSON correctly', () {
        // Arrange
        const modelWithNulls = LineStockModel(
          stockId: null,
          materialCode: null,
          materialDesc: null,
          quantity: null,
          baseUnit: null,
          batchCode: null,
          locationCode: null,
          barcode: null,
        );

        // Act
        final result = modelWithNulls.toJson();

        // Assert
        expect(result['stockId'], isNull);
        expect(result['materialCode'], isNull);
        expect(result['materialDesc'], isNull);
        expect(result['quantity'], isNull);
        expect(result['baseUnit'], isNull);
        expect(result['batchCode'], isNull);
        expect(result['locationCode'], isNull);
        expect(result['barcode'], isNull);
      });
    });

    group('Entity Conversion', () {
      test('should convert LineStockModel to LineStock entity', () {
        // Act
        final result = testLineStockModel.toEntity();

        // Assert
        expect(result, isA<LineStock>());
        expect(result.stockId, testLineStockModel.stockId);
        expect(result.materialCode, testLineStockModel.materialCode);
        expect(result.materialDesc, testLineStockModel.materialDesc);
        expect(result.quantity, testLineStockModel.quantity);
        expect(result.baseUnit, testLineStockModel.baseUnit);
        expect(result.batchCode, testLineStockModel.batchCode);
        expect(result.locationCode, testLineStockModel.locationCode);
        expect(result.barcode, testLineStockModel.barcode);
      });

      test('should handle null values with defaults when converting to entity', () {
        // Arrange
        const modelWithNulls = LineStockModel(
          stockId: null,
          materialCode: null,
          materialDesc: null,
          quantity: null,
          baseUnit: null,
          batchCode: null,
          locationCode: null,
          barcode: null,
        );

        // Act
        final result = modelWithNulls.toEntity();

        // Assert
        expect(result, isA<LineStock>());
        expect(result.stockId, isNull);
        expect(result.materialCode, '');
        expect(result.materialDesc, '');
        expect(result.quantity, 0.0);
        expect(result.baseUnit, 'PCS');
        expect(result.batchCode, '');
        expect(result.locationCode, '');
        expect(result.barcode, '');
      });

      test('should use default baseUnit when converting null to entity', () {
        // Arrange
        const modelWithNullUnit = LineStockModel(
          materialCode: 'C100001',
          materialDesc: 'Test',
          quantity: 100.0,
          baseUnit: null,
        );

        // Act
        final result = modelWithNullUnit.toEntity();

        // Assert
        expect(result.baseUnit, 'PCS');
      });
    });

    group('Round-trip Conversion', () {
      test('should maintain data integrity through JSON round-trip', () {
        // Act
        final json = testLineStockModel.toJson();
        final reconstructed = LineStockModel.fromJson(json);

        // Assert
        expect(reconstructed.stockId, testLineStockModel.stockId);
        expect(reconstructed.materialCode, testLineStockModel.materialCode);
        expect(reconstructed.materialDesc, testLineStockModel.materialDesc);
        expect(reconstructed.quantity, testLineStockModel.quantity);
        expect(reconstructed.baseUnit, testLineStockModel.baseUnit);
        expect(reconstructed.batchCode, testLineStockModel.batchCode);
        expect(reconstructed.locationCode, testLineStockModel.locationCode);
        expect(reconstructed.barcode, testLineStockModel.barcode);
      });

      test('should maintain data through model -> entity conversion', () {
        // Act
        final entity = testLineStockModel.toEntity();

        // Assert - all non-null values should be preserved
        expect(entity.stockId, testLineStockModel.stockId);
        expect(entity.materialCode, testLineStockModel.materialCode);
        expect(entity.materialDesc, testLineStockModel.materialDesc);
        expect(entity.quantity, testLineStockModel.quantity);
        expect(entity.baseUnit, testLineStockModel.baseUnit);
        expect(entity.batchCode, testLineStockModel.batchCode);
        expect(entity.locationCode, testLineStockModel.locationCode);
        expect(entity.barcode, testLineStockModel.barcode);
      });
    });

    group('Edge Cases', () {
      test('should handle zero quantity', () {
        // Arrange
        const jsonWithZero = {
          'quantity': 0.0,
        };

        // Act
        final result = LineStockModel.fromJson(jsonWithZero);

        // Assert
        expect(result.quantity, 0.0);
      });

      test('should handle negative quantity', () {
        // Arrange
        const jsonWithNegative = {
          'quantity': -10.5,
        };

        // Act
        final result = LineStockModel.fromJson(jsonWithNegative);

        // Assert
        expect(result.quantity, -10.5);
      });

      test('should handle empty strings', () {
        // Arrange
        const jsonWithEmptyStrings = {
          'materialCode': '',
          'materialDesc': '',
          'baseUnit': '',
          'batchCode': '',
          'locationCode': '',
          'barcode': '',
        };

        // Act
        final result = LineStockModel.fromJson(jsonWithEmptyStrings);

        // Assert
        expect(result.materialCode, '');
        expect(result.materialDesc, '');
        expect(result.baseUnit, '');
        expect(result.batchCode, '');
        expect(result.locationCode, '');
        expect(result.barcode, '');
      });

      test('should handle very large quantity values', () {
        // Arrange
        const jsonWithLargeValue = {
          'quantity': 999999999.99,
        };

        // Act
        final result = LineStockModel.fromJson(jsonWithLargeValue);

        // Assert
        expect(result.quantity, 999999999.99);
      });

      test('should handle special characters in strings', () {
        // Arrange
        const jsonWithSpecialChars = {
          'materialDesc': 'Test & Special <> Characters "quotes"',
          'batchCode': 'BATCH-2025/001#A',
        };

        // Act
        final result = LineStockModel.fromJson(jsonWithSpecialChars);

        // Assert
        expect(result.materialDesc, 'Test & Special <> Characters "quotes"');
        expect(result.batchCode, 'BATCH-2025/001#A');
      });
    });
  });
}
