import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:picking_verification_app/features/picking_verification/data/repositories/picking_verification_repository_impl.dart';
import 'package:picking_verification_app/features/picking_verification/data/datasources/picking_verification_remote_datasource.dart';
import 'package:picking_verification_app/features/picking_verification/data/datasources/picking_verification_local_datasource.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/picking_order.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';
import 'package:picking_verification_app/features/picking_verification/data/models/submission_models.dart';
import 'package:picking_verification_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';

class MockPickingVerificationRemoteDataSource extends Mock 
    implements PickingVerificationRemoteDataSource {}

class MockPickingVerificationLocalDataSource extends Mock 
    implements PickingVerificationLocalDataSource {}

void main() {
  group('PickingVerificationRepositoryImpl - Submission', () {
    late PickingVerificationRepositoryImpl repository;
    late MockPickingVerificationRemoteDataSource mockRemoteDataSource;
    late MockPickingVerificationLocalDataSource mockLocalDataSource;
    late PickingOrder testOrder;

    setUp(() {
      mockRemoteDataSource = MockPickingVerificationRemoteDataSource();
      mockLocalDataSource = MockPickingVerificationLocalDataSource();
      repository = PickingVerificationRepositoryImpl(
        remoteDataSource: mockRemoteDataSource,
        localDataSource: mockLocalDataSource,
      );

      testOrder = PickingOrder(
        orderId: 'ORDER001',
        orderNumber: 'ORDER001',
        productionLineId: 'LINE_001',
        status: 'inProgress',
        createdAt: DateTime.now(),
        items: [],
        isVerified: false,
        materials: [
          MaterialItem(
            id: 'MAT001',
            code: 'M001',
            name: '测试物料',
            category: MaterialCategory.centralWarehouse,
            requiredQuantity: 10,
            availableQuantity: 10,
            status: MaterialStatus.completed,
            location: 'A01-01',
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    group('submitVerification', () {
      test('should return submission response when API call succeeds', () async {
        // Arrange
        final expectedResponse = VerificationSubmissionResponse(
          submissionId: 'SUB001',
          status: 'success',
          timestamp: DateTime.now(),
          message: '验证提交成功',
        );

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenAnswer((_) async => expectedResponse);

        // Act
        final result = await repository.submitVerification(testOrder);

        // Assert
        expect(result, isA<Right<Failure, VerificationSubmissionResponse>>());
        result.fold(
          (failure) => fail('Expected success, got failure: $failure'),
          (response) {
            expect(response.submissionId, equals('SUB001'));
            expect(response.status, equals('success'));
            expect(response.message, equals('验证提交成功'));
          },
        );

        verify(() => mockRemoteDataSource.submitVerification(any())).called(1);
      });

      test('should return ServerFailure when API call fails with DioException', () async {
        // Arrange
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/api/submit'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/submit'),
            statusCode: 500,
            statusMessage: 'Internal Server Error',
          ),
          type: DioExceptionType.badResponse,
        );

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenThrow(dioError);

        // Act
        final result = await repository.submitVerification(testOrder);

        // Assert
        expect(result, isA<Left<Failure, VerificationSubmissionResponse>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('服务器错误'));
          },
          (response) => fail('Expected failure, got success: $response'),
        );
      });

      test('should return NetworkFailure when network connection fails', () async {
        // Arrange
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/api/submit'),
          type: DioExceptionType.connectionError,
          error: 'Network unreachable',
        );

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenThrow(dioError);

        // Act
        final result = await repository.submitVerification(testOrder);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, contains('网络连接失败'));
          },
          (response) => fail('Expected failure, got success: $response'),
        );
      });

      test('should return TimeoutFailure when request times out', () async {
        // Arrange
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/api/submit'),
          type: DioExceptionType.connectionTimeout,
        );

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenThrow(dioError);

        // Act
        final result = await repository.submitVerification(testOrder);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<TimeoutFailure>());
            expect(failure.message, contains('请求超时'));
          },
          (response) => fail('Expected failure, got success: $response'),
        );
      });

      test('should return AuthenticationFailure for 401 status code', () async {
        // Arrange
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/api/submit'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/submit'),
            statusCode: 401,
            statusMessage: 'Unauthorized',
          ),
          type: DioExceptionType.badResponse,
        );

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenThrow(dioError);

        // Act
        final result = await repository.submitVerification(testOrder);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<AuthenticationFailure>());
            expect(failure.message, contains('认证失败'));
          },
          (response) => fail('Expected failure, got success: $response'),
        );
      });

      test('should return ValidationFailure for 400 status code', () async {
        // Arrange
        final dioError = DioException(
          requestOptions: RequestOptions(path: '/api/submit'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/submit'),
            statusCode: 400,
            statusMessage: 'Bad Request',
            data: {'message': '数据验证失败', 'errors': ['物料数量不匹配']},
          ),
          type: DioExceptionType.badResponse,
        );

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenThrow(dioError);

        // Act
        final result = await repository.submitVerification(testOrder);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.message, contains('数据验证失败'));
          },
          (response) => fail('Expected failure, got success: $response'),
        );
      });

      test('should pass correct submission request to remote data source', () async {
        // Arrange
        final expectedResponse = VerificationSubmissionResponse(
          submissionId: 'SUB001',
          status: 'success',
          timestamp: DateTime.now(),
          message: '成功',
        );

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenAnswer((_) async => expectedResponse);

        // Act
        await repository.submitVerification(testOrder);

        // Assert
        final captured = verify(() => mockRemoteDataSource.submitVerification(captureAny()))
            .captured.single as VerificationSubmissionRequest;

        expect(captured.orderId, equals('ORDER001'));
        expect(captured.customerName, equals('测试客户'));
        expect(captured.materials, hasLength(1));
        expect(captured.materials.first.materialCode, equals('M001'));
        expect(captured.materials.first.actualQuantity, equals(10));
      });

      test('should handle concurrent submission attempts', () async {
        // Arrange
        final response1 = VerificationSubmissionResponse(
          submissionId: 'SUB001',
          status: 'success',
          timestamp: DateTime.now(),
          message: '成功',
        );

        final response2 = VerificationSubmissionResponse(
          submissionId: 'SUB002',
          status: 'success',
          timestamp: DateTime.now(),
          message: '成功',
        );

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return response1;
            });

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 50));
              return response2;
            });

        // Act
        final futures = [
          repository.submitVerification(testOrder),
          repository.submitVerification(testOrder.copyWith(id: 'ORDER002')),
        ];

        final results = await Future.wait(futures);

        // Assert
        expect(results, hasLength(2));
        expect(results.every((r) => r.isRight()), isTrue);
      });

      test('should handle malformed server response gracefully', () async {
        // Arrange
        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenThrow(const FormatException('Invalid JSON'));

        // Act
        final result = await repository.submitVerification(testOrder);

        // Assert
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('数据格式错误'));
          },
          (response) => fail('Expected failure, got success: $response'),
        );
      });

      test('should retry failed requests according to configuration', () async {
        // Arrange
        var callCount = 0;
        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenAnswer((_) async {
              callCount++;
              if (callCount < 3) {
                throw DioException(
                  requestOptions: RequestOptions(path: '/api/submit'),
                  type: DioExceptionType.connectionError,
                );
              }
              return VerificationSubmissionResponse(
                submissionId: 'SUB001',
                status: 'success',
                timestamp: DateTime.now(),
                message: '重试成功',
              );
            });

        // Act
        final result = await repository.submitVerification(testOrder);

        // Assert
        expect(result.isRight(), isTrue);
        expect(callCount, equals(3));
      });

      test('should include audit trail information in submission', () async {
        // Arrange
        final expectedResponse = VerificationSubmissionResponse(
          submissionId: 'SUB001',
          status: 'success',
          timestamp: DateTime.now(),
          message: '成功',
        );

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenAnswer((_) async => expectedResponse);

        // Act
        await repository.submitVerification(testOrder);

        // Assert
        final captured = verify(() => mockRemoteDataSource.submitVerification(captureAny()))
            .captured.single as VerificationSubmissionRequest;

        expect(captured.auditInfo, isNotNull);
        expect(captured.auditInfo!.operatorId, isNotEmpty);
        expect(captured.auditInfo!.timestamp, isNotNull);
        expect(captured.auditInfo!.deviceInfo, isNotNull);
      });
    });

    group('Error Handling Edge Cases', () {
      test('should handle empty order submission', () async {
        // Arrange
        final emptyOrder = testOrder.copyWith(materials: []);

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenAnswer((_) async => VerificationSubmissionResponse(
              submissionId: 'SUB001',
              status: 'success',
              timestamp: DateTime.now(),
              message: '成功',
            ));

        // Act
        final result = await repository.submitVerification(emptyOrder);

        // Assert
        expect(result.isRight(), isTrue);
        final captured = verify(() => mockRemoteDataSource.submitVerification(captureAny()))
            .captured.single as VerificationSubmissionRequest;
        expect(captured.materials, isEmpty);
      });

      test('should handle very large material lists', () async {
        // Arrange
        final largeMaterialsList = List.generate(1000, (index) => MaterialItem(
          id: 'MAT${index.toString().padLeft(4, '0')}',
          code: 'M${index.toString().padLeft(4, '0')}',
          name: '物料$index',
          category: MaterialCategory.centralWarehouse,
          requiredQuantity: 10,
          availableQuantity: 10,
          status: MaterialStatus.completed,
          location: 'A${(index ~/ 100).toString().padLeft(2, '0')}-${(index % 100).toString().padLeft(2, '0')}',
        ));

        final largeOrder = testOrder.copyWith(materials: largeMaterialsList);

        when(() => mockRemoteDataSource.submitVerification(any()))
            .thenAnswer((_) async => VerificationSubmissionResponse(
              submissionId: 'SUB001',
              status: 'success',
              timestamp: DateTime.now(),
              message: '成功',
            ));

        // Act
        final result = await repository.submitVerification(largeOrder);

        // Assert
        expect(result.isRight(), isTrue);
        final captured = verify(() => mockRemoteDataSource.submitVerification(captureAny()))
            .captured.single as VerificationSubmissionRequest;
        expect(captured.materials, hasLength(1000));
      });
    });
  });
}