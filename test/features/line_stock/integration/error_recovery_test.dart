import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_bloc.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_event.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_state.dart';
import 'package:picking_verification_app/features/line_stock/data/repositories/line_stock_repository_impl.dart';
import 'package:picking_verification_app/features/line_stock/data/datasources/line_stock_remote_datasource.dart';
import 'package:picking_verification_app/features/line_stock/data/models/line_stock_model.dart';
import 'package:picking_verification_app/core/error/exceptions.dart';

/// Mock DataSource for network layer
class MockLineStockRemoteDataSource extends Mock
    implements LineStockRemoteDataSource {}

/// Integration Test: Error Recovery Scenarios
///
/// Tests how the application handles and recovers from various error conditions
void main() {
  group('Error Recovery Integration Tests', () {
    late LineStockBloc bloc;
    late MockLineStockRemoteDataSource mockDataSource;

    const testBarcode = 'TEST123';
    const targetLocation = 'TARGET-A-01';

    const testStockModel = LineStockModel(
      stockId: 1,
      materialCode: 'MAT001',
      materialDesc: '测试物料',
      quantity: 100.0,
      baseUnit: 'M',
      batchCode: 'BATCH001',
      locationCode: 'WH-A-01',
      barcode: testBarcode,
    );

    setUp(() {
      mockDataSource = MockLineStockRemoteDataSource();
      final repository = LineStockRepositoryImpl(
        remoteDataSource: mockDataSource,
      );
      bloc = LineStockBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    group('Query Network Errors', () {
      blocTest<LineStockBloc, LineStockState>(
        'should emit error state when network times out',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenThrow(NetworkException('网络连接超时'));
          return bloc;
        },
        act: (bloc) => bloc.add(const QueryStockByBarcode(
          barcode: testBarcode,
          factoryId: 1,
        )),
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          const LineStockError(
            message: '网络连接超时',
            canRetry: true,
          ),
        ],
      );

      blocTest<LineStockBloc, LineStockState>(
        'should allow retry after network error',
        build: () {
          var callCount = 0;
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw NetworkException('网络连接失败');
            }
            return testStockModel;
          });
          return bloc;
        },
        act: (bloc) async {
          // First attempt - fails
          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode,
            factoryId: 1,
          ));
          await Future.delayed(const Duration(milliseconds: 100));

          // Retry - succeeds
          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode,
            factoryId: 1,
          ));
        },
        verify: (bloc) {
          expect(bloc.state, isA<StockQuerySuccess>());
        },
      );
    });

    group('Query Server Errors', () {
      blocTest<LineStockBloc, LineStockState>(
        'should handle barcode not found error',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenThrow(ServerException('未找到该条码'));
          return bloc;
        },
        act: (bloc) => bloc.add(const QueryStockByBarcode(
          barcode: 'INVALID',
          factoryId: 1,
        )),
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          const LineStockError(
            message: '未找到该条码',
            canRetry: true,
          ),
        ],
      );

      blocTest<LineStockBloc, LineStockState>(
        'should handle server internal error',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenThrow(ServerException('服务器内部错误'));
          return bloc;
        },
        act: (bloc) => bloc.add(const QueryStockByBarcode(
          barcode: testBarcode,
          factoryId: 1,
        )),
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          const LineStockError(
            message: '服务器内部错误',
            canRetry: true,
          ),
        ],
      );
    });

    group('Shelving Duplicate Barcode', () {
      blocTest<LineStockBloc, LineStockState>(
        'should prevent adding duplicate cable barcode',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: testBarcode,
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add cable first time
          bloc.add(const AddCableBarcode(testBarcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // Try to add same cable again
          bloc.add(const AddCableBarcode(testBarcode));
        },
        verify: (bloc) {
          final state = bloc.state;
          if (state is ShelvingInProgress) {
            // Should still have only one cable
            expect(state.cableList.length, equals(1));
          } else if (state is LineStockError) {
            // Or should show error about duplicate
            expect(state.message, anyOf(contains('已存在'), contains('重复')));
          }
        },
      );
    });

    group('Shelving Transfer Errors', () {
      blocTest<LineStockBloc, LineStockState>(
        'should handle transfer network error',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: testBarcode,
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);

          when(() => mockDataSource.transferStock(
                locationCode: any(named: 'locationCode'),
                barCodes: any(named: 'barCodes'),
              )).thenThrow(NetworkException('网络连接失败'));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(testBarcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ConfirmShelving(
            locationCode: targetLocation,
            barCodes: [testBarcode],
          ));
        },
        skip: 3, // Skip setup states (SetLocation + Loading + ShelvingInProgress)
        expect: () => [
          const LineStockLoading(message: '上架中...'),
          const LineStockError(
            message: '网络连接失败',
            canRetry: true,
          ),
        ],
      );

      blocTest<LineStockBloc, LineStockState>(
        'should handle transfer server error',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: testBarcode,
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);

          when(() => mockDataSource.transferStock(
                locationCode: any(named: 'locationCode'),
                barCodes: any(named: 'barCodes'),
              )).thenThrow(ServerException('上架失败：目标库位不存在'));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(testBarcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ConfirmShelving(
            locationCode: targetLocation,
            barCodes: [testBarcode],
          ));
        },
        skip: 3, // Skip setup states (SetLocation + Loading + ShelvingInProgress)
        expect: () => [
          const LineStockLoading(message: '上架中...'),
          const LineStockError(
            message: '上架失败：目标库位不存在',
            canRetry: true,
          ),
        ],
      );
    });

    group('State Recovery After Errors', () {
      blocTest<LineStockBloc, LineStockState>(
        'should allow new query after query error',
        build: () {
          var callCount = 0;
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw ServerException('查询失败');
            }
            return testStockModel;
          });
          return bloc;
        },
        act: (bloc) async {
          // First query - fails
          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode,
            factoryId: 1,
          ));
          await Future.delayed(const Duration(milliseconds: 100));

          // Second query - succeeds
          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode,
            factoryId: 1,
          ));
        },
        verify: (bloc) {
          expect(bloc.state, isA<StockQuerySuccess>());
          final state = bloc.state as StockQuerySuccess;
          expect(state.stock.barcode, equals(testBarcode));
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should allow retry after shelving error',
        build: () {
          var callCount = 0;
          when(() => mockDataSource.queryByBarcode(
                barcode: testBarcode,
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);

          when(() => mockDataSource.transferStock(
                locationCode: any(named: 'locationCode'),
                barCodes: any(named: 'barCodes'),
              )).thenAnswer((_) async {
            callCount++;
            if (callCount == 1) {
              throw NetworkException('网络错误');
            }
            return true;
          });
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(testBarcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // First attempt - fails
          bloc.add(const ConfirmShelving(
            locationCode: targetLocation,
            barCodes: [testBarcode],
          ));
          await Future.delayed(const Duration(milliseconds: 100));

          // Retry - succeeds
          bloc.add(const ConfirmShelving(
            locationCode: targetLocation,
            barCodes: [testBarcode],
          ));
        },
        verify: (bloc) {
          expect(bloc.state, isA<ShelvingSuccess>());
        },
      );
    });
  });
}
