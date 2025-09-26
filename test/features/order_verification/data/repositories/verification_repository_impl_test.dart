import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:picking_verification_app/features/order_verification/data/datasources/verification_remote_datasource.dart';
import 'package:picking_verification_app/features/order_verification/data/repositories/verification_repository_impl.dart';
import 'package:picking_verification_app/features/order_verification/domain/entities/verification_result.dart' as domain;

import 'verification_repository_impl_test.mocks.dart';

@GenerateMocks([VerificationRemoteDataSource])
void main() {
  group('VerificationRepositoryImpl', () {
    late MockVerificationRemoteDataSource mockRemoteDataSource;
    late VerificationRepositoryImpl repository;

    setUp(() {
      mockRemoteDataSource = MockVerificationRemoteDataSource();
      repository = VerificationRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
      );
    });

    test('should return verification result from remote data source', () async {
      // Arrange
      const scannedOrderId = 'ORD123';
      const expectedOrderId = 'ORD123';
      final mockResult = domain.VerificationResult(
        orderId: scannedOrderId,
        isValid: true,
        verifiedAt: DateTime(2023, 12, 25, 10, 30),
      );

      when(mockRemoteDataSource.verifyOrder(any))
          .thenAnswer((_) async => mockResult);

      // Act
      final result = await repository.verifyOrder(
        scannedOrderId: scannedOrderId,
        expectedOrderId: expectedOrderId,
      );

      // Assert
      expect(result, equals(mockResult));
      verify(mockRemoteDataSource.verifyOrder(any)).called(1);
    });

    test('should pass correct parameters to remote data source', () async {
      // Arrange
      const scannedOrderId = 'ORD123';
      const expectedOrderId = 'ORD456';
      final mockResult = domain.VerificationResult(
        orderId: scannedOrderId,
        isValid: false,
        errorMessage: '订单号不匹配',
        verifiedAt: DateTime(2023, 12, 25, 10, 30),
      );

      when(mockRemoteDataSource.verifyOrder(any))
          .thenAnswer((_) async => mockResult);

      // Act
      await repository.verifyOrder(
        scannedOrderId: scannedOrderId,
        expectedOrderId: expectedOrderId,
      );

      // Assert
      final captured = verify(mockRemoteDataSource.verifyOrder(captureAny))
          .captured.single;
      expect(captured.scannedOrderId, equals(scannedOrderId));
      expect(captured.expectedOrderId, equals(expectedOrderId));
      expect(captured.taskId, equals(''));
    });

    test('should handle remote data source errors', () async {
      // Arrange
      const scannedOrderId = 'ORD123';
      const expectedOrderId = 'ORD123';
      
      when(mockRemoteDataSource.verifyOrder(any))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => repository.verifyOrder(
          scannedOrderId: scannedOrderId,
          expectedOrderId: expectedOrderId,
        ),
        throwsException,
      );
    });

    test('should handle null or empty order IDs', () async {
      // Arrange
      const scannedOrderId = '';
      const expectedOrderId = 'ORD123';
      final mockResult = domain.VerificationResult(
        orderId: scannedOrderId,
        isValid: false,
        errorMessage: '订单号不匹配',
        verifiedAt: DateTime(2023, 12, 25, 10, 30),
      );

      when(mockRemoteDataSource.verifyOrder(any))
          .thenAnswer((_) async => mockResult);

      // Act
      final result = await repository.verifyOrder(
        scannedOrderId: scannedOrderId,
        expectedOrderId: expectedOrderId,
      );

      // Assert
      expect(result.isValid, isFalse);
      expect(result.orderId, equals(scannedOrderId));
    });
  });
}