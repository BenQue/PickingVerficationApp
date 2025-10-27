import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:picking_verification_app/core/error/exceptions.dart';
import 'package:picking_verification_app/features/line_stock/core/constants.dart';
import 'package:picking_verification_app/features/line_stock/data/datasources/line_stock_remote_datasource.dart';
import 'package:picking_verification_app/features/line_stock/data/models/line_stock_model.dart';

import 'line_stock_remote_datasource_test.mocks.dart';

@GenerateMocks([Dio])
void main() {
  group('LineStockRemoteDataSourceImpl', () {
    late MockDio mockDio;
    late LineStockRemoteDataSourceImpl dataSource;

    setUp(() {
      mockDio = MockDio();
      dataSource = LineStockRemoteDataSourceImpl(dio: mockDio);
    });

    group('queryByBarcode', () {
      const testBarcode = 'BC123456789';
      const testFactoryId = 1;

      final successResponse = {
        'isSuccess': true,
        'message': '查询成功',
        'data': {
          'stockId': 12345,
          'materialCode': 'C100001',
          'materialDesc': 'Test Cable Material',
          'quantity': 150.5,
          'baseUnit': 'M',
          'batchCode': 'BATCH-2025-001',
          'locationCode': 'A-01-05',
          'barcode': testBarcode,
        },
      };

      test('should return LineStockModel when API call is successful', () async {
        // Arrange
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await dataSource.queryByBarcode(barcode: testBarcode);

        // Assert
        expect(result, isA<LineStockModel>());
        expect(result.materialCode, 'C100001');
        expect(result.barcode, testBarcode);
        expect(result.quantity, 150.5);

        // Verify correct endpoint was called
        verify(mockDio.get(
          LineStockConstants.queryApiPath,
          queryParameters: {'barcode': testBarcode},
        )).called(1);
      });

      test('should include factoryId in query parameters when provided', () async {
        // Arrange
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        await dataSource.queryByBarcode(
          barcode: testBarcode,
          factoryId: testFactoryId,
        );

        // Assert
        verify(mockDio.get(
          LineStockConstants.queryApiPath,
          queryParameters: {
            'barcode': testBarcode,
            'factoryid': testFactoryId,
          },
        )).called(1);
      });

      test('should not include factoryId when not provided', () async {
        // Arrange
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        await dataSource.queryByBarcode(barcode: testBarcode);

        // Assert
        verify(mockDio.get(
          LineStockConstants.queryApiPath,
          queryParameters: {'barcode': testBarcode},
        )).called(1);
      });

      test('should throw ServerException when API returns isSuccess false', () async {
        // Arrange
        final errorResponse = {
          'isSuccess': false,
          'message': '条码不存在',
          'data': null,
        };

        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: errorResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act & Assert
        expect(
          () => dataSource.queryByBarcode(barcode: testBarcode),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            '条码不存在',
          )),
        );
      });

      test('should throw ServerException when data is null despite success', () async {
        // Arrange
        final responseWithNullData = {
          'isSuccess': true,
          'message': '查询成功',
          'data': null,
        };

        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: responseWithNullData,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act & Assert
        expect(
          () => dataSource.queryByBarcode(barcode: testBarcode),
          throwsA(isA<ServerException>()),
        );
      });

      test('should throw NetworkException on connection timeout', () async {
        // Arrange
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.queryByBarcode(barcode: testBarcode),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            '网络连接超时',
          )),
        );
      });

      test('should throw NetworkException on receive timeout', () async {
        // Arrange
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.queryByBarcode(barcode: testBarcode),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            '网络连接超时',
          )),
        );
      });

      test('should throw ServerException on bad response with error message', () async {
        // Arrange
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              data: {'message': '数据库连接失败'},
              statusCode: 500,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.queryByBarcode(barcode: testBarcode),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            '数据库连接失败',
          )),
        );
      });

      test('should throw ServerException with default message on bad response without message', () async {
        // Arrange
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              data: {},
              statusCode: 500,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.queryByBarcode(barcode: testBarcode),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            LineStockConstants.serverError,
          )),
        );
      });

      test('should throw NetworkException on other Dio errors', () async {
        // Arrange
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.cancel,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.queryByBarcode(barcode: testBarcode),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            LineStockConstants.networkError,
          )),
        );
      });

      test('should throw ServerException on non-Dio exceptions', () async {
        // Arrange
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          () => dataSource.queryByBarcode(barcode: testBarcode),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains(LineStockConstants.unknownError),
          )),
        );
      });
    });

    group('transferStock', () {
      const testLocationCode = 'B-02-05';
      const testBarCodes = ['BC123456789', 'BC987654321', 'BC555666777'];

      final successResponse = {
        'isSuccess': true,
        'message': '转移成功，共处理 3 条记录',
        'data': true,
      };

      test('should return true when transfer is successful', () async {
        // Arrange
        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await dataSource.transferStock(
          locationCode: testLocationCode,
          barCodes: testBarCodes,
        );

        // Assert
        expect(result, true);

        // Verify correct endpoint and data were used
        final captured = verify(mockDio.post(
          captureAny,
          data: captureAnyNamed('data'),
        )).captured;

        expect(captured[0], LineStockConstants.transferApiPath);
        expect(captured[1]['locationCode'], testLocationCode);
        expect(captured[1]['barCodes'], testBarCodes);
      });

      test('should return false when data is null despite success', () async {
        // Arrange
        final responseWithNullData = {
          'isSuccess': true,
          'message': '转移成功',
          'data': null,
        };

        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              data: responseWithNullData,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await dataSource.transferStock(
          locationCode: testLocationCode,
          barCodes: testBarCodes,
        );

        // Assert
        expect(result, false);
      });

      test('should handle single barcode transfer', () async {
        // Arrange
        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              data: successResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act
        final result = await dataSource.transferStock(
          locationCode: testLocationCode,
          barCodes: ['BC123456789'],
        );

        // Assert
        expect(result, true);

        final captured = verify(mockDio.post(
          any,
          data: captureAnyNamed('data'),
        )).captured;

        expect(captured[0]['barCodes'], ['BC123456789']);
      });

      test('should throw ServerException when API returns isSuccess false', () async {
        // Arrange
        final errorResponse = {
          'isSuccess': false,
          'message': '目标库位不存在',
          'data': null,
        };

        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenAnswer((_) async => Response(
              data: errorResponse,
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act & Assert
        expect(
          () => dataSource.transferStock(
            locationCode: testLocationCode,
            barCodes: testBarCodes,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            '目标库位不存在',
          )),
        );
      });

      test('should throw NetworkException on connection timeout', () async {
        // Arrange
        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.transferStock(
            locationCode: testLocationCode,
            barCodes: testBarCodes,
          ),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            '网络连接超时',
          )),
        );
      });

      test('should throw ServerException on bad response', () async {
        // Arrange
        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              data: {'message': '权限不足'},
              statusCode: 403,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.transferStock(
            locationCode: testLocationCode,
            barCodes: testBarCodes,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            '权限不足',
          )),
        );
      });

      test('should throw NetworkException on network errors', () async {
        // Arrange
        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.unknown,
          ),
        );

        // Act & Assert
        expect(
          () => dataSource.transferStock(
            locationCode: testLocationCode,
            barCodes: testBarCodes,
          ),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            LineStockConstants.networkError,
          )),
        );
      });

      test('should throw ServerException on non-Dio exceptions', () async {
        // Arrange
        when(mockDio.post(
          any,
          data: anyNamed('data'),
        )).thenThrow(FormatException('Invalid data format'));

        // Act & Assert
        expect(
          () => dataSource.transferStock(
            locationCode: testLocationCode,
            barCodes: testBarCodes,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains(LineStockConstants.unknownError),
          )),
        );
      });
    });

    group('Error Handling', () {
      test('should handle multiple error types correctly', () async {
        // Test connection timeout
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(
          () => dataSource.queryByBarcode(barcode: 'BC123'),
          throwsA(isA<NetworkException>()),
        );

        // Test receive timeout
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.receiveTimeout,
          ),
        );

        expect(
          () => dataSource.queryByBarcode(barcode: 'BC123'),
          throwsA(isA<NetworkException>()),
        );

        // Test bad response
        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.badResponse,
            response: Response(
              data: {'message': 'Error'},
              statusCode: 500,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );

        expect(
          () => dataSource.queryByBarcode(barcode: 'BC123'),
          throwsA(isA<ServerException>()),
        );
      });

      test('should preserve error messages from API', () async {
        // Arrange
        const customErrorMessage = '自定义错误消息：权限验证失败';

        when(mockDio.get(
          any,
          queryParameters: anyNamed('queryParameters'),
        )).thenAnswer((_) async => Response(
              data: {
                'isSuccess': false,
                'message': customErrorMessage,
                'data': null,
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: ''),
            ));

        // Act & Assert
        try {
          await dataSource.queryByBarcode(barcode: 'BC123');
          fail('Should have thrown ServerException');
        } on ServerException catch (e) {
          expect(e.message, customErrorMessage);
        }
      });
    });
  });
}
