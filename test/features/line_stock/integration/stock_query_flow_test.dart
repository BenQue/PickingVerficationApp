import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_bloc.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_event.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_state.dart';
import 'package:picking_verification_app/features/line_stock/data/repositories/line_stock_repository_impl.dart';
import 'package:picking_verification_app/features/line_stock/data/datasources/line_stock_remote_datasource.dart';
import 'package:picking_verification_app/features/line_stock/domain/entities/line_stock_entity.dart';
import 'package:picking_verification_app/features/line_stock/data/models/line_stock_model.dart';
import 'package:picking_verification_app/core/error/exceptions.dart';

/// Mock DataSource for network layer
class MockLineStockRemoteDataSource extends Mock
    implements LineStockRemoteDataSource {}

/// Integration Test: Complete Stock Query Flow
///
/// Verifies the complete flow from barcode query to navigation to shelving screen.
/// Uses real BLoC and Repository implementations, only mocking the network datasource.
void main() {
  group('Stock Query Flow Integration Tests', () {
    late LineStockBloc bloc;
    late MockLineStockRemoteDataSource mockDataSource;

    // Test fixtures
    const testBarcode = 'BC123456';
    const testFactoryId = 1;

    const testStockModel = LineStockModel(
      stockId: 1,
      materialCode: 'MAT001',
      materialDesc: '测试电缆A',
      quantity: 150.0,
      baseUnit: 'M',
      batchCode: 'BATCH001',
      locationCode: 'WH-A-01-01',
      barcode: testBarcode,
    );

    final testStockEntity = testStockModel.toEntity();

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

    test('should be in LineStockInitial state initially', () {
      expect(bloc.state, equals(const LineStockInitial()));
    });

    group('Successful Query Flow', () {
      blocTest<LineStockBloc, LineStockState>(
        'should emit [Loading, Success] when query succeeds',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);
          return bloc;
        },
        act: (bloc) => bloc.add(const QueryStockByBarcode(
          barcode: testBarcode,
          factoryId: testFactoryId,
        )),
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          StockQuerySuccess(testStockEntity),
        ],
        verify: (_) {
          verify(() => mockDataSource.queryByBarcode(
                barcode: testBarcode,
                factoryId: testFactoryId,
              )).called(1);
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should display correct stock information in success state',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);
          return bloc;
        },
        act: (bloc) => bloc.add(const QueryStockByBarcode(
          barcode: testBarcode,
          factoryId: testFactoryId,
        )),
        verify: (bloc) {
          final state = bloc.state as StockQuerySuccess;
          expect(state.stock.materialCode, equals('MAT001'));
          expect(state.stock.materialDesc, equals('测试电缆A'));
          expect(state.stock.quantity, equals(150.0));
          expect(state.stock.baseUnit, equals('M'));
          expect(state.stock.batchCode, equals('BATCH001'));
          expect(state.stock.locationCode, equals('WH-A-01-01'));
          expect(state.stock.barcode, equals(testBarcode));
        },
      );
    });

    group('Query to Shelving Transition', () {
      blocTest<LineStockBloc, LineStockState>(
        'should transition from query success to shelving location set',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);
          return bloc;
        },
        act: (bloc) async {
          // Step 1: Query stock
          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode,
            factoryId: testFactoryId,
          ));
          await Future.delayed(const Duration(milliseconds: 100));

          // Step 2: User clicks "立即上架" - set target location
          bloc.add(const SetTargetLocation('TARGET-LOC-01'));
        },
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          StockQuerySuccess(testStockEntity),
          const ShelvingInProgress(
            targetLocation: 'TARGET-LOC-01',
            cableList: [],
            canSubmit: false,
          ),
        ],
      );

      blocTest<LineStockBloc, LineStockState>(
        'should preserve location after query when navigating to shelving',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode,
            factoryId: testFactoryId,
          ));
          await Future.delayed(const Duration(milliseconds: 100));
          bloc.add(const SetTargetLocation('TARGET-LOC-01'));
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.targetLocation, equals('TARGET-LOC-01'));
          expect(state.cableList, isEmpty);
        },
      );
    });

    group('Clear Query Result', () {
      blocTest<LineStockBloc, LineStockState>(
        'should return to initial state when clearing query result',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);
          return bloc;
        },
        act: (bloc) async {
          // Query first
          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode,
            factoryId: testFactoryId,
          ));
          await Future.delayed(const Duration(milliseconds: 100));

          // Clear result
          bloc.add(const ClearQueryResult());
        },
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          StockQuerySuccess(testStockEntity),
          const LineStockInitial(),
        ],
      );
    });

    group('Multiple Sequential Queries', () {
      const testBarcode2 = 'BC789012';
      const testStockModel2 = LineStockModel(
        stockId: 2,
        materialCode: 'MAT002',
        materialDesc: '测试电缆B',
        quantity: 200.0,
        baseUnit: 'M',
        batchCode: 'BATCH002',
        locationCode: 'WH-A-01-02',
        barcode: testBarcode2,
      );

      final testStockEntity2 = testStockModel2.toEntity();

      blocTest<LineStockBloc, LineStockState>(
        'should handle multiple sequential queries correctly',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: testBarcode,
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel);

          when(() => mockDataSource.queryByBarcode(
                barcode: testBarcode2,
                factoryId: any(named: 'factoryId'),
              )).thenAnswer((_) async => testStockModel2);

          return bloc;
        },
        act: (bloc) async {
          // First query
          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode,
            factoryId: testFactoryId,
          ));
          await Future.delayed(const Duration(milliseconds: 100));

          // Clear and second query
          bloc.add(const ClearQueryResult());
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode2,
            factoryId: testFactoryId,
          ));
        },
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          StockQuerySuccess(testStockEntity),
          const LineStockInitial(),
          const LineStockLoading(message: '查询中...'),
          StockQuerySuccess(testStockEntity2),
        ],
      );
    });

    group('Network Error Handling', () {
      blocTest<LineStockBloc, LineStockState>(
        'should emit error state when network fails',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenThrow(NetworkException('网络连接失败'));
          return bloc;
        },
        act: (bloc) => bloc.add(const QueryStockByBarcode(
          barcode: testBarcode,
          factoryId: testFactoryId,
        )),
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          const LineStockError(message: '网络连接失败'),
        ],
      );

      blocTest<LineStockBloc, LineStockState>(
        'should emit error state when server returns error',
        build: () {
          when(() => mockDataSource.queryByBarcode(
                barcode: any(named: 'barcode'),
                factoryId: any(named: 'factoryId'),
              )).thenThrow(ServerException('未找到库存记录'));
          return bloc;
        },
        act: (bloc) => bloc.add(const QueryStockByBarcode(
          barcode: testBarcode,
          factoryId: testFactoryId,
        )),
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          const LineStockError(message: '未找到库存记录'),
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
            factoryId: testFactoryId,
          ));
          await Future.delayed(const Duration(milliseconds: 100));

          // Retry - succeeds
          bloc.add(const QueryStockByBarcode(
            barcode: testBarcode,
            factoryId: testFactoryId,
          ));
        },
        expect: () => [
          const LineStockLoading(message: '查询中...'),
          const LineStockError(message: '网络连接失败'),
          const LineStockLoading(message: '查询中...'),
          StockQuerySuccess(testStockEntity),
        ],
      );
    });
  });
}
