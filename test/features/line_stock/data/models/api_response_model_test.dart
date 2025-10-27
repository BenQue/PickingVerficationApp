import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/data/models/api_response_model.dart';

void main() {
  group('ApiResponse Tests', () {
    // Helper class for testing generic type
    const testData = TestData(
      id: 1,
      name: 'Test Item',
      value: 42.5,
    );

    const testJson = {
      'id': 1,
      'name': 'Test Item',
      'value': 42.5,
    };

    group('String Type Response', () {
      test('should create ApiResponse<String> with success', () {
        // Arrange
        const responseJson = {
          'isSuccess': true,
          'message': '操作成功',
          'data': 'Test string data',
        };

        // Act
        final result = ApiResponse<String>.fromJson(
          responseJson,
          (data) => data as String,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.message, '操作成功');
        expect(result.data, 'Test string data');
      });

      test('should create ApiResponse<String> with failure', () {
        // Arrange
        const responseJson = {
          'isSuccess': false,
          'message': '操作失败',
          'data': null,
        };

        // Act
        final result = ApiResponse<String>.fromJson(
          responseJson,
          (data) => data as String,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.message, '操作失败');
        expect(result.data, isNull);
      });

      test('should convert ApiResponse<String> to JSON', () {
        // Arrange
        const response = ApiResponse<String>(
          isSuccess: true,
          message: '查询成功',
          data: 'Result data',
        );

        // Act
        final result = response.toJson((data) => data);

        // Assert
        expect(result, {
          'isSuccess': true,
          'message': '查询成功',
          'data': 'Result data',
        });
      });
    });

    group('Custom Object Type Response', () {
      test('should create ApiResponse<TestData> with success', () {
        // Arrange
        const responseJson = {
          'isSuccess': true,
          'message': '获取成功',
          'data': testJson,
        };

        // Act
        final result = ApiResponse<TestData>.fromJson(
          responseJson,
          (data) => TestData.fromJson(data as Map<String, dynamic>),
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.message, '获取成功');
        expect(result.data, isA<TestData>());
        expect(result.data?.id, 1);
        expect(result.data?.name, 'Test Item');
        expect(result.data?.value, 42.5);
      });

      test('should convert ApiResponse<TestData> to JSON', () {
        // Arrange
        const response = ApiResponse<TestData>(
          isSuccess: true,
          message: '保存成功',
          data: testData,
        );

        // Act
        final result = response.toJson((data) => data.toJson());

        // Assert
        expect(result['isSuccess'], true);
        expect(result['message'], '保存成功');
        expect(result['data'], testJson);
      });
    });

    group('List Type Response', () {
      test('should create ApiResponse<List<TestData>> with success', () {
        // Arrange
        const responseJson = {
          'isSuccess': true,
          'message': '查询列表成功',
          'data': [
            {'id': 1, 'name': 'Item 1', 'value': 10.0},
            {'id': 2, 'name': 'Item 2', 'value': 20.0},
            {'id': 3, 'name': 'Item 3', 'value': 30.0},
          ],
        };

        // Act
        final result = ApiResponse<List<TestData>>.fromJson(
          responseJson,
          (data) => (data as List)
              .map((item) => TestData.fromJson(item as Map<String, dynamic>))
              .toList(),
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.message, '查询列表成功');
        expect(result.data, isA<List<TestData>>());
        expect(result.data?.length, 3);
        expect(result.data?[0].id, 1);
        expect(result.data?[1].id, 2);
        expect(result.data?[2].id, 3);
      });

      test('should convert ApiResponse<List<TestData>> to JSON', () {
        // Arrange
        final response = ApiResponse<List<TestData>>(
          isSuccess: true,
          message: '列表数据',
          data: [
            const TestData(id: 1, name: 'A', value: 1.0),
            const TestData(id: 2, name: 'B', value: 2.0),
          ],
        );

        // Act
        final result = response.toJson(
          (data) => data.map((item) => item.toJson()).toList(),
        );

        // Assert
        expect(result['data'], isA<List>());
        expect((result['data'] as List).length, 2);
      });

      test('should handle empty list in response', () {
        // Arrange
        const responseJson = {
          'isSuccess': true,
          'message': '无数据',
          'data': <Map<String, dynamic>>[],
        };

        // Act
        final result = ApiResponse<List<TestData>>.fromJson(
          responseJson,
          (data) => (data as List)
              .map((item) => TestData.fromJson(item as Map<String, dynamic>))
              .toList(),
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.data, isA<List<TestData>>());
        expect(result.data?.isEmpty, true);
      });
    });

    group('Null Data Handling', () {
      test('should handle null data in success response', () {
        // Arrange
        const responseJson = {
          'isSuccess': true,
          'message': '操作成功但无返回数据',
          'data': null,
        };

        // Act
        final result = ApiResponse<String>.fromJson(
          responseJson,
          (data) => data as String,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.message, '操作成功但无返回数据');
        expect(result.data, isNull);
      });

      test('should handle null data in failure response', () {
        // Arrange
        const responseJson = {
          'isSuccess': false,
          'message': '操作失败',
          'data': null,
        };

        // Act
        final result = ApiResponse<TestData>.fromJson(
          responseJson,
          (data) => TestData.fromJson(data as Map<String, dynamic>),
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.message, '操作失败');
        expect(result.data, isNull);
      });

      test('should convert response with null data to JSON', () {
        // Arrange
        const response = ApiResponse<String>(
          isSuccess: false,
          message: '无数据',
          data: null,
        );

        // Act
        final result = response.toJson((data) => data);

        // Assert
        expect(result, {
          'isSuccess': false,
          'message': '无数据',
          'data': null,
        });
      });
    });

    group('Message Handling', () {
      test('should handle various message formats', () {
        // Arrange
        final testMessages = [
          '操作成功',
          'Success',
          '查询失败：数据库连接错误',
          'Error: Invalid request parameters',
          '请求超时，请重试',
          '',
        ];

        for (final message in testMessages) {
          final responseJson = {
            'isSuccess': true,
            'message': message,
            'data': null,
          };

          // Act
          final result = ApiResponse<String>.fromJson(
            responseJson,
            (data) => data as String,
          );

          // Assert
          expect(result.message, message);
        }
      });

      test('should handle long error messages', () {
        // Arrange
        final longMessage = '操作失败：' * 50;
        final responseJson = {
          'isSuccess': false,
          'message': longMessage,
          'data': null,
        };

        // Act
        final result = ApiResponse<String>.fromJson(
          responseJson,
          (data) => data as String,
        );

        // Assert
        expect(result.message, longMessage);
        expect(result.message.length, greaterThan(100));
      });
    });

    group('Round-trip Conversion', () {
      test('should maintain data through round-trip with String', () {
        // Arrange
        const original = ApiResponse<String>(
          isSuccess: true,
          message: 'Test message',
          data: 'Test data',
        );

        // Act
        final json = original.toJson((data) => data);
        final reconstructed = ApiResponse<String>.fromJson(
          json,
          (data) => data as String,
        );

        // Assert
        expect(reconstructed.isSuccess, original.isSuccess);
        expect(reconstructed.message, original.message);
        expect(reconstructed.data, original.data);
      });

      test('should maintain data through round-trip with custom object', () {
        // Arrange
        const original = ApiResponse<TestData>(
          isSuccess: true,
          message: 'Test',
          data: testData,
        );

        // Act
        final json = original.toJson((data) => data.toJson());
        final reconstructed = ApiResponse<TestData>.fromJson(
          json,
          (data) => TestData.fromJson(data as Map<String, dynamic>),
        );

        // Assert
        expect(reconstructed.isSuccess, original.isSuccess);
        expect(reconstructed.message, original.message);
        expect(reconstructed.data?.id, original.data?.id);
        expect(reconstructed.data?.name, original.data?.name);
        expect(reconstructed.data?.value, original.data?.value);
      });

      test('should maintain null data through round-trip', () {
        // Arrange
        const original = ApiResponse<String>(
          isSuccess: false,
          message: 'Error',
          data: null,
        );

        // Act
        final json = original.toJson((data) => data);
        final reconstructed = ApiResponse<String>.fromJson(
          json,
          (data) => data as String,
        );

        // Assert
        expect(reconstructed.isSuccess, original.isSuccess);
        expect(reconstructed.message, original.message);
        expect(reconstructed.data, isNull);
      });
    });

    group('Edge Cases', () {
      test('should handle boolean isSuccess correctly', () {
        // Arrange
        const successJson = {
          'isSuccess': true,
          'message': 'Success',
          'data': null,
        };
        const failureJson = {
          'isSuccess': false,
          'message': 'Failure',
          'data': null,
        };

        // Act
        final successResult = ApiResponse<String>.fromJson(
          successJson,
          (data) => data as String,
        );
        final failureResult = ApiResponse<String>.fromJson(
          failureJson,
          (data) => data as String,
        );

        // Assert
        expect(successResult.isSuccess, true);
        expect(failureResult.isSuccess, false);
      });

      test('should handle numeric types in data', () {
        // Arrange
        const responseJson = {
          'isSuccess': true,
          'message': 'Count result',
          'data': 12345,
        };

        // Act
        final result = ApiResponse<int>.fromJson(
          responseJson,
          (data) => data as int,
        );

        // Assert
        expect(result.data, 12345);
        expect(result.data, isA<int>());
      });

      test('should handle double type in data', () {
        // Arrange
        const responseJson = {
          'isSuccess': true,
          'message': 'Calculation result',
          'data': 3.14159,
        };

        // Act
        final result = ApiResponse<double>.fromJson(
          responseJson,
          (data) => (data as num).toDouble(),
        );

        // Assert
        expect(result.data, 3.14159);
        expect(result.data, isA<double>());
      });

      test('should handle Map type in data', () {
        // Arrange
        const responseJson = {
          'isSuccess': true,
          'message': 'Config data',
          'data': {
            'key1': 'value1',
            'key2': 'value2',
          },
        };

        // Act
        final result = ApiResponse<Map<String, String>>.fromJson(
          responseJson,
          (data) => Map<String, String>.from(data as Map),
        );

        // Assert
        expect(result.data, isA<Map<String, String>>());
        expect(result.data?['key1'], 'value1');
        expect(result.data?['key2'], 'value2');
      });

      test('should handle special characters in message', () {
        // Arrange
        const responseJson = {
          'isSuccess': false,
          'message': '错误：无效的参数 <parameter> "value"',
          'data': null,
        };

        // Act
        final result = ApiResponse<String>.fromJson(
          responseJson,
          (data) => data as String,
        );

        // Assert
        expect(result.message, '错误：无效的参数 <parameter> "value"');
      });
    });

    group('Real-world Scenarios', () {
      test('should handle typical success response from stock query API', () {
        // Arrange
        const stockResponse = {
          'isSuccess': true,
          'message': '查询成功',
          'data': {
            'stockId': 12345,
            'materialCode': 'C100001',
            'materialDesc': 'Test Cable',
            'quantity': 150.5,
            'baseUnit': 'M',
            'batchCode': 'BATCH-001',
            'locationCode': 'A-01-05',
            'barcode': 'BC123456789',
          },
        };

        // Act
        final result = ApiResponse<Map<String, dynamic>>.fromJson(
          stockResponse,
          (data) => data as Map<String, dynamic>,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.message, '查询成功');
        expect(result.data, isNotNull);
        expect(result.data?['materialCode'], 'C100001');
      });

      test('should handle typical error response from API', () {
        // Arrange
        const errorResponse = {
          'isSuccess': false,
          'message': '条码不存在',
          'data': null,
        };

        // Act
        final result = ApiResponse<Map<String, dynamic>>.fromJson(
          errorResponse,
          (data) => data as Map<String, dynamic>,
        );

        // Assert
        expect(result.isSuccess, false);
        expect(result.message, '条码不存在');
        expect(result.data, isNull);
      });

      test('should handle typical success response from transfer API', () {
        // Arrange
        const transferResponse = {
          'isSuccess': true,
          'message': '转移成功，共处理 3 条记录',
          'data': true,
        };

        // Act
        final result = ApiResponse<bool>.fromJson(
          transferResponse,
          (data) => data as bool,
        );

        // Assert
        expect(result.isSuccess, true);
        expect(result.message, '转移成功，共处理 3 条记录');
        expect(result.data, true);
      });
    });
  });
}

/// Test helper class for testing generic types
class TestData {
  final int id;
  final String name;
  final double value;

  const TestData({
    required this.id,
    required this.name,
    required this.value,
  });

  factory TestData.fromJson(Map<String, dynamic> json) {
    return TestData(
      id: json['id'] as int,
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value': value,
    };
  }
}
