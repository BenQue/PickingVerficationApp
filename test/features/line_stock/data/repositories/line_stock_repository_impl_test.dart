import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:picking_verification_app/core/error/exceptions.dart';
import 'package:picking_verification_app/core/error/failures.dart';
import 'package:picking_verification_app/features/line_stock/data/datasources/line_stock_remote_datasource.dart';
import 'package:picking_verification_app/features/line_stock/data/models/line_stock_model.dart';
import 'package:picking_verification_app/features/line_stock/data/repositories/line_stock_repository_impl.dart';
import 'package:picking_verification_app/features/line_stock/domain/entities/line_stock_entity.dart';

import 'line_stock_repository_impl_test.mocks.dart';

@GenerateMocks([LineStockRemoteDataSource])
void main() {
  group('LineStockRepositoryImpl', () {
    late MockLineStockRemoteDataSource mockDataSource;
    late LineStockRepositoryImpl repository;

    setUp(() {
      mockDataSource = MockLineStockRemoteDataSource();
      repository = LineStockRepositoryImpl(remoteDataSource: mockDataSource);
    });

    group('queryByBarcode', () {
      const testBarcode = 'BC123456789';
      const testFactoryId = 1;

      const testModel = LineStockModel(
        stockId: 12345,
        materialCode: 'C100001',
        materialDesc: 'Test Cable Material',
        quantity: 150.5,
        baseUnit: 'M',
        batchCode: 'BATCH-2025-001',
        locationCode: 'A-01-05',
        barcode: testBarcode,
      );

      test('should return Right(LineStock) when remote call succeeds', () async {
        // Arrange
        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenAnswer((_) async => testModel);

        // Act
        final result = await repository.queryByBarcode(barcode: testBarcode);

        // Assert
        expect(result, isA<Right<Failure, LineStock>>());
        result.fold(
          (failure) => fail('Should return Right'),
          (lineStock) {
            expect(lineStock, isA<LineStock>());
            expect(lineStock.materialCode, testModel.materialCode);
            expect(lineStock.barcode, testModel.barcode);
            expect(lineStock.quantity, testModel.quantity);
            expect(lineStock.stockId, testModel.stockId);
          },
        );

        verify(mockDataSource.queryByBarcode(barcode: testBarcode)).called(1);
      });

      test('should pass factoryId to data source when provided', () async {
        // Arrange
        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenAnswer((_) async => testModel);

        // Act
        await repository.queryByBarcode(
          barcode: testBarcode,
          factoryId: testFactoryId,
        );

        // Assert
        verify(mockDataSource.queryByBarcode(
          barcode: testBarcode,
          factoryId: testFactoryId,
        )).called(1);
      });

      test('should convert model to entity correctly', () async {
        // Arrange
        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenAnswer((_) async => testModel);

        // Act
        final result = await repository.queryByBarcode(barcode: testBarcode);

        // Assert
        result.fold(
          (failure) => fail('Should return Right'),
          (lineStock) {
            // Verify all fields are correctly converted
            expect(lineStock.stockId, testModel.stockId);
            expect(lineStock.materialCode, testModel.materialCode);
            expect(lineStock.materialDesc, testModel.materialDesc);
            expect(lineStock.quantity, testModel.quantity);
            expect(lineStock.baseUnit, testModel.baseUnit);
            expect(lineStock.batchCode, testModel.batchCode);
            expect(lineStock.locationCode, testModel.locationCode);
            expect(lineStock.barcode, testModel.barcode);
          },
        );
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        const errorMessage = '条码不存在';
        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenThrow(ServerException(errorMessage));

        // Act
        final result = await repository.queryByBarcode(barcode: testBarcode);

        // Assert
        expect(result, isA<Left<Failure, LineStock>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, errorMessage);
          },
          (lineStock) => fail('Should return Left'),
        );
      });

      test('should return Left(NetworkFailure) when NetworkException is thrown', () async {
        // Arrange
        const errorMessage = '网络连接失败';
        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenThrow(NetworkException(errorMessage));

        // Act
        final result = await repository.queryByBarcode(barcode: testBarcode);

        // Assert
        expect(result, isA<Left<Failure, LineStock>>());
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, errorMessage);
          },
          (lineStock) => fail('Should return Left'),
        );
      });

      test('should return Left(ServerFailure) when unknown exception is thrown', () async {
        // Arrange
        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenThrow(Exception('Unexpected error'));

        // Act
        final result = await repository.queryByBarcode(barcode: testBarcode);

        // Assert
        expect(result, isA<Left<Failure, LineStock>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('未知错误'));
          },
          (lineStock) => fail('Should return Left'),
        );
      });

      test('should preserve error messages from exceptions', () async {
        // Arrange
        const customError = '自定义错误消息：数据库连接失败';
        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenThrow(ServerException(customError));

        // Act
        final result = await repository.queryByBarcode(barcode: testBarcode);

        // Assert
        result.fold(
          (failure) => expect(failure.message, customError),
          (lineStock) => fail('Should return Left'),
        );
      });

      test('should handle null values in model correctly', () async {
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

        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenAnswer((_) async => modelWithNulls);

        // Act
        final result = await repository.queryByBarcode(barcode: testBarcode);

        // Assert
        result.fold(
          (failure) => fail('Should return Right'),
          (lineStock) {
            // Verify default values are applied
            expect(lineStock.materialCode, '');
            expect(lineStock.materialDesc, '');
            expect(lineStock.quantity, 0.0);
            expect(lineStock.baseUnit, 'PCS');
            expect(lineStock.batchCode, '');
            expect(lineStock.locationCode, '');
            expect(lineStock.barcode, '');
          },
        );
      });
    });

    group('transferStock', () {
      const testLocationCode = 'B-02-05';
      const testBarCodes = ['BC123456789', 'BC987654321', 'BC555666777'];

      test('should return Right(true) when transfer succeeds', () async {
        // Arrange
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await repository.transferStock(
          locationCode: testLocationCode,
          barCodes: testBarCodes,
        );

        // Assert
        expect(result, isA<Right<Failure, bool>>());
        result.fold(
          (failure) => fail('Should return Right'),
          (success) => expect(success, true),
        );

        verify(mockDataSource.transferStock(
          locationCode: testLocationCode,
          barCodes: testBarCodes,
        )).called(1);
      });

      test('should return Right(false) when transfer fails but no exception', () async {
        // Arrange
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenAnswer((_) async => false);

        // Act
        final result = await repository.transferStock(
          locationCode: testLocationCode,
          barCodes: testBarCodes,
        );

        // Assert
        expect(result, isA<Right<Failure, bool>>());
        result.fold(
          (failure) => fail('Should return Right'),
          (success) => expect(success, false),
        );
      });

      test('should handle single barcode transfer', () async {
        // Arrange
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await repository.transferStock(
          locationCode: testLocationCode,
          barCodes: ['BC123456789'],
        );

        // Assert
        result.fold(
          (failure) => fail('Should return Right'),
          (success) => expect(success, true),
        );

        verify(mockDataSource.transferStock(
          locationCode: testLocationCode,
          barCodes: ['BC123456789'],
        )).called(1);
      });

      test('should handle empty barcode list', () async {
        // Arrange
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenAnswer((_) async => true);

        // Act
        final result = await repository.transferStock(
          locationCode: testLocationCode,
          barCodes: [],
        );

        // Assert
        result.fold(
          (failure) => fail('Should return Right'),
          (success) => expect(success, true),
        );
      });

      test('should return Left(ServerFailure) when ServerException is thrown', () async {
        // Arrange
        const errorMessage = '目标库位不存在';
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenThrow(ServerException(errorMessage));

        // Act
        final result = await repository.transferStock(
          locationCode: testLocationCode,
          barCodes: testBarCodes,
        );

        // Assert
        expect(result, isA<Left<Failure, bool>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, errorMessage);
          },
          (success) => fail('Should return Left'),
        );
      });

      test('should return Left(NetworkFailure) when NetworkException is thrown', () async {
        // Arrange
        const errorMessage = '网络超时';
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenThrow(NetworkException(errorMessage));

        // Act
        final result = await repository.transferStock(
          locationCode: testLocationCode,
          barCodes: testBarCodes,
        );

        // Assert
        expect(result, isA<Left<Failure, bool>>());
        result.fold(
          (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.message, errorMessage);
          },
          (success) => fail('Should return Left'),
        );
      });

      test('should return Left(ServerFailure) when unknown exception is thrown', () async {
        // Arrange
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenThrow(FormatException('Invalid format'));

        // Act
        final result = await repository.transferStock(
          locationCode: testLocationCode,
          barCodes: testBarCodes,
        );

        // Assert
        expect(result, isA<Left<Failure, bool>>());
        result.fold(
          (failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('未知错误'));
          },
          (success) => fail('Should return Left'),
        );
      });

      test('should preserve error messages from exceptions', () async {
        // Arrange
        const customError = '权限不足：无法执行转移操作';
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenThrow(ServerException(customError));

        // Act
        final result = await repository.transferStock(
          locationCode: testLocationCode,
          barCodes: testBarCodes,
        );

        // Assert
        result.fold(
          (failure) => expect(failure.message, customError),
          (success) => fail('Should return Left'),
        );
      });
    });

    group('Exception to Failure Conversion', () {
      const testBarcode = 'BC123';

      test('should consistently convert ServerException to ServerFailure', () async {
        // Arrange
        final errors = [
          '条码不存在',
          '数据库错误',
          '服务器内部错误',
          'API版本不匹配',
        ];

        for (final error in errors) {
          when(mockDataSource.queryByBarcode(
            barcode: anyNamed('barcode'),
            factoryId: anyNamed('factoryId'),
          )).thenThrow(ServerException(error));

          // Act
          final result = await repository.queryByBarcode(barcode: testBarcode);

          // Assert
          result.fold(
            (failure) {
              expect(failure, isA<ServerFailure>());
              expect(failure.message, error);
            },
            (lineStock) => fail('Should return Left'),
          );
        }
      });

      test('should consistently convert NetworkException to NetworkFailure', () async {
        // Arrange
        final errors = [
          '网络连接失败',
          '连接超时',
          '无法连接到服务器',
          'DNS解析失败',
        ];

        for (final error in errors) {
          when(mockDataSource.queryByBarcode(
            barcode: anyNamed('barcode'),
            factoryId: anyNamed('factoryId'),
          )).thenThrow(NetworkException(error));

          // Act
          final result = await repository.queryByBarcode(barcode: testBarcode);

          // Assert
          result.fold(
            (failure) {
              expect(failure, isA<NetworkFailure>());
              expect(failure.message, error);
            },
            (lineStock) => fail('Should return Left'),
          );
        }
      });

      test('should convert all other exceptions to ServerFailure with prefix', () async {
        // Arrange
        final exceptions = [
          Exception('Generic exception'),
          FormatException('Format error'),
          StateError('State error'),
          ArgumentError('Argument error'),
        ];

        for (final exception in exceptions) {
          when(mockDataSource.queryByBarcode(
            barcode: anyNamed('barcode'),
            factoryId: anyNamed('factoryId'),
          )).thenThrow(exception);

          // Act
          final result = await repository.queryByBarcode(barcode: testBarcode);

          // Assert
          result.fold(
            (failure) {
              expect(failure, isA<ServerFailure>());
              expect(failure.message, startsWith('未知错误'));
            },
            (lineStock) => fail('Should return Left'),
          );
        }
      });
    });

    group('Integration Scenarios', () {
      test('should handle successful query and transfer flow', () async {
        // Arrange - Query
        const testBarcode = 'BC123456789';
        const testModel = LineStockModel(
          stockId: 12345,
          materialCode: 'C100001',
          materialDesc: 'Test Cable',
          quantity: 100.0,
          baseUnit: 'M',
          batchCode: 'BATCH-001',
          locationCode: 'A-01-05',
          barcode: testBarcode,
        );

        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenAnswer((_) async => testModel);

        // Act - Query
        final queryResult = await repository.queryByBarcode(barcode: testBarcode);

        // Assert - Query
        expect(queryResult.isRight(), true);

        // Arrange - Transfer
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenAnswer((_) async => true);

        // Act - Transfer
        final transferResult = await repository.transferStock(
          locationCode: 'B-02-05',
          barCodes: [testBarcode],
        );

        // Assert - Transfer
        expect(transferResult.isRight(), true);
      });

      test('should handle query success followed by transfer failure', () async {
        // Arrange - Query success
        const testBarcode = 'BC123456789';
        const testModel = LineStockModel(
          materialCode: 'C100001',
          materialDesc: 'Test',
          quantity: 100.0,
        );

        when(mockDataSource.queryByBarcode(
          barcode: anyNamed('barcode'),
          factoryId: anyNamed('factoryId'),
        )).thenAnswer((_) async => testModel);

        // Act - Query
        final queryResult = await repository.queryByBarcode(barcode: testBarcode);

        // Assert - Query success
        expect(queryResult.isRight(), true);

        // Arrange - Transfer failure
        when(mockDataSource.transferStock(
          locationCode: anyNamed('locationCode'),
          barCodes: anyNamed('barCodes'),
        )).thenThrow(ServerException('目标库位不存在'));

        // Act - Transfer
        final transferResult = await repository.transferStock(
          locationCode: 'INVALID',
          barCodes: [testBarcode],
        );

        // Assert - Transfer failure
        expect(transferResult.isLeft(), true);
        transferResult.fold(
          (failure) => expect(failure.message, '目标库位不存在'),
          (success) => fail('Should return Left'),
        );
      });
    });
  });
}
