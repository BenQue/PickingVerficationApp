import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/data/models/transfer_request_model.dart';

void main() {
  group('TransferRequestModel Tests', () {
    const testTransferRequest = TransferRequestModel(
      locationCode: 'B-02-05',
      barCodes: [
        'BC123456789',
        'BC987654321',
        'BC555666777',
      ],
    );

    const testJson = {
      'locationCode': 'B-02-05',
      'barCodes': [
        'BC123456789',
        'BC987654321',
        'BC555666777',
      ],
    };

    group('JSON Serialization', () {
      test('should create TransferRequestModel from JSON', () {
        // Act
        final result = TransferRequestModel.fromJson(testJson);

        // Assert
        expect(result.locationCode, 'B-02-05');
        expect(result.barCodes, isA<List<String>>());
        expect(result.barCodes.length, 3);
        expect(result.barCodes[0], 'BC123456789');
        expect(result.barCodes[1], 'BC987654321');
        expect(result.barCodes[2], 'BC555666777');
      });

      test('should convert TransferRequestModel to JSON', () {
        // Act
        final result = testTransferRequest.toJson();

        // Assert
        expect(result, testJson);
      });

      test('should handle single barcode in list', () {
        // Arrange
        const jsonWithSingleBarcode = {
          'locationCode': 'A-01-01',
          'barCodes': ['BC123456789'],
        };

        // Act
        final result = TransferRequestModel.fromJson(jsonWithSingleBarcode);

        // Assert
        expect(result.locationCode, 'A-01-01');
        expect(result.barCodes.length, 1);
        expect(result.barCodes[0], 'BC123456789');
      });

      test('should handle empty barcode list', () {
        // Arrange
        const jsonWithEmptyList = {
          'locationCode': 'C-03-10',
          'barCodes': <String>[],
        };

        // Act
        final result = TransferRequestModel.fromJson(jsonWithEmptyList);

        // Assert
        expect(result.locationCode, 'C-03-10');
        expect(result.barCodes, isEmpty);
      });

      test('should handle many barcodes in list', () {
        // Arrange
        final jsonWithManyBarcodes = {
          'locationCode': 'D-04-15',
          'barCodes': List.generate(50, (index) => 'BC${index.toString().padLeft(9, '0')}'),
        };

        // Act
        final result = TransferRequestModel.fromJson(jsonWithManyBarcodes);

        // Assert
        expect(result.locationCode, 'D-04-15');
        expect(result.barCodes.length, 50);
        expect(result.barCodes[0], 'BC000000000');
        expect(result.barCodes[49], 'BC000000049');
      });

      test('should preserve barcode order in JSON conversion', () {
        // Arrange
        const orderedBarcodes = [
          'BC111111111',
          'BC222222222',
          'BC333333333',
          'BC444444444',
        ];
        const request = TransferRequestModel(
          locationCode: 'E-05-20',
          barCodes: orderedBarcodes,
        );

        // Act
        final json = request.toJson();
        final reconstructed = TransferRequestModel.fromJson(json);

        // Assert
        expect(reconstructed.barCodes, orderedBarcodes);
      });
    });

    group('Round-trip Conversion', () {
      test('should maintain data integrity through JSON round-trip', () {
        // Act
        final json = testTransferRequest.toJson();
        final reconstructed = TransferRequestModel.fromJson(json);

        // Assert
        expect(reconstructed.locationCode, testTransferRequest.locationCode);
        expect(reconstructed.barCodes, testTransferRequest.barCodes);
        expect(reconstructed.barCodes.length, testTransferRequest.barCodes.length);
      });

      test('should handle round-trip with empty list', () {
        // Arrange
        const requestWithEmptyList = TransferRequestModel(
          locationCode: 'F-06-25',
          barCodes: [],
        );

        // Act
        final json = requestWithEmptyList.toJson();
        final reconstructed = TransferRequestModel.fromJson(json);

        // Assert
        expect(reconstructed.locationCode, requestWithEmptyList.locationCode);
        expect(reconstructed.barCodes, isEmpty);
      });

      test('should handle round-trip with single item', () {
        // Arrange
        const requestWithSingleItem = TransferRequestModel(
          locationCode: 'G-07-30',
          barCodes: ['BC999999999'],
        );

        // Act
        final json = requestWithSingleItem.toJson();
        final reconstructed = TransferRequestModel.fromJson(json);

        // Assert
        expect(reconstructed.locationCode, requestWithSingleItem.locationCode);
        expect(reconstructed.barCodes, ['BC999999999']);
      });
    });

    group('Edge Cases', () {
      test('should handle location code with various formats', () {
        // Arrange
        final testCases = [
          {'locationCode': 'A-01-01', 'barCodes': <String>[]},
          {'locationCode': 'Z-99-99', 'barCodes': <String>[]},
          {'locationCode': 'AA-10-20', 'barCodes': <String>[]},
          {'locationCode': 'B02-05', 'barCodes': <String>[]},
          {'locationCode': 'ZONE-A-001', 'barCodes': <String>[]},
        ];

        for (final testCase in testCases) {
          // Act
          final result = TransferRequestModel.fromJson(testCase);

          // Assert
          expect(result.locationCode, testCase['locationCode']);
        }
      });

      test('should handle barcodes with different formats', () {
        // Arrange
        const jsonWithVariousBarcodes = {
          'locationCode': 'H-08-35',
          'barCodes': [
            'BC123456789',          // Standard format
            '1234567890123',        // Numeric only
            'CABLE-2025-001',       // With dashes
            'BC_TEST_001',          // With underscores
            'bc-lowercase',         // Lowercase
            '条码123',               // Chinese characters
          ],
        };

        // Act
        final result = TransferRequestModel.fromJson(jsonWithVariousBarcodes);

        // Assert
        expect(result.barCodes.length, 6);
        expect(result.barCodes[0], 'BC123456789');
        expect(result.barCodes[1], '1234567890123');
        expect(result.barCodes[2], 'CABLE-2025-001');
        expect(result.barCodes[3], 'BC_TEST_001');
        expect(result.barCodes[4], 'bc-lowercase');
        expect(result.barCodes[5], '条码123');
      });

      test('should handle duplicate barcodes in list', () {
        // Arrange
        const jsonWithDuplicates = {
          'locationCode': 'I-09-40',
          'barCodes': [
            'BC123456789',
            'BC987654321',
            'BC123456789', // duplicate
            'BC555666777',
            'BC987654321', // duplicate
          ],
        };

        // Act
        final result = TransferRequestModel.fromJson(jsonWithDuplicates);

        // Assert
        expect(result.barCodes.length, 5);
        expect(result.barCodes, [
          'BC123456789',
          'BC987654321',
          'BC123456789',
          'BC555666777',
          'BC987654321',
        ]);
      });

      test('should handle empty location code', () {
        // Arrange
        const jsonWithEmptyLocation = {
          'locationCode': '',
          'barCodes': ['BC123456789'],
        };

        // Act
        final result = TransferRequestModel.fromJson(jsonWithEmptyLocation);

        // Assert
        expect(result.locationCode, '');
        expect(result.barCodes, ['BC123456789']);
      });

      test('should handle location with special characters', () {
        // Arrange
        const jsonWithSpecialChars = {
          'locationCode': 'A-01/05#B',
          'barCodes': ['BC123456789'],
        };

        // Act
        final result = TransferRequestModel.fromJson(jsonWithSpecialChars);

        // Assert
        expect(result.locationCode, 'A-01/05#B');
      });

      test('should handle very long barcode strings', () {
        // Arrange
        final longBarcode = 'BC${'1' * 100}'; // 102 characters
        final jsonWithLongBarcode = {
          'locationCode': 'J-10-45',
          'barCodes': [longBarcode],
        };

        // Act
        final result = TransferRequestModel.fromJson(jsonWithLongBarcode);

        // Assert
        expect(result.barCodes[0], longBarcode);
        expect(result.barCodes[0].length, 102);
      });
    });

    group('Data Validation Context', () {
      test('should create valid request for typical use case', () {
        // Arrange - simulate real-world scenario
        const realWorldRequest = TransferRequestModel(
          locationCode: 'B-02-05',
          barCodes: [
            'BC20250127001',
            'BC20250127002',
            'BC20250127003',
          ],
        );

        // Act
        final json = realWorldRequest.toJson();

        // Assert
        expect(json['locationCode'], isNotEmpty);
        expect(json['barCodes'], isA<List>());
        expect((json['barCodes'] as List).isNotEmpty, true);
      });

      test('should handle API request format correctly', () {
        // Arrange - ensure API-compatible format
        const apiRequest = TransferRequestModel(
          locationCode: 'C-03-10',
          barCodes: ['BC123', 'BC456'],
        );

        // Act
        final json = apiRequest.toJson();

        // Assert - verify JSON structure matches API expectations
        expect(json.containsKey('locationCode'), true);
        expect(json.containsKey('barCodes'), true);
        expect(json['locationCode'], isA<String>());
        expect(json['barCodes'], isA<List>());
      });
    });
  });
}
