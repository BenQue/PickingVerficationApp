import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/order_verification/data/datasources/verification_remote_datasource.dart';
import 'package:picking_verification_app/features/order_verification/data/models/verification_request_model.dart';

void main() {
  group('VerificationRemoteDataSourceImpl', () {
    late VerificationRemoteDataSourceImpl dataSource;

    setUp(() {
      dataSource = VerificationRemoteDataSourceImpl();
    });

    test('should return successful verification when order IDs match', () async {
      // Arrange
      const request = VerificationRequestModel(
        scannedOrderId: 'ORD123',
        expectedOrderId: 'ORD123',
        taskId: 'TASK456',
      );

      // Act
      final result = await dataSource.verifyOrder(request);

      // Assert
      expect(result.orderId, equals('ORD123'));
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
      expect(result.verifiedAt, isA<DateTime>());
    });

    test('should return failed verification when order IDs do not match', () async {
      // Arrange
      const request = VerificationRequestModel(
        scannedOrderId: 'ORD123',
        expectedOrderId: 'ORD456',
        taskId: 'TASK789',
      );

      // Act
      final result = await dataSource.verifyOrder(request);

      // Assert
      expect(result.orderId, equals('ORD123'));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('订单号不匹配，请重新扫描'));
      expect(result.verifiedAt, isA<DateTime>());
    });

    test('should complete within reasonable time', () async {
      // Arrange
      const request = VerificationRequestModel(
        scannedOrderId: 'ORD123',
        expectedOrderId: 'ORD123',
        taskId: 'TASK456',
      );
      final stopwatch = Stopwatch()..start();

      // Act
      await dataSource.verifyOrder(request);
      stopwatch.stop();

      // Assert
      // Should complete within 1 second (includes 500ms delay)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      // Should take at least 400ms (accounting for test timing variance)
      expect(stopwatch.elapsedMilliseconds, greaterThan(400));
    });

    test('should handle empty order IDs correctly', () async {
      // Arrange
      const request = VerificationRequestModel(
        scannedOrderId: '',
        expectedOrderId: 'ORD123',
        taskId: 'TASK456',
      );

      // Act
      final result = await dataSource.verifyOrder(request);

      // Assert
      expect(result.orderId, equals(''));
      expect(result.isValid, isFalse);
      expect(result.errorMessage, equals('订单号不匹配，请重新扫描'));
    });
  });
}