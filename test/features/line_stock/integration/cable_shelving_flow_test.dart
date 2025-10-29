import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_bloc.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_event.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_state.dart';
import 'package:picking_verification_app/features/line_stock/data/repositories/line_stock_repository_impl.dart';
import 'package:picking_verification_app/features/line_stock/data/datasources/line_stock_remote_datasource.dart';
import 'package:picking_verification_app/features/line_stock/domain/entities/line_stock_entity.dart';
import 'package:picking_verification_app/features/line_stock/domain/entities/cable_item.dart';
import 'package:picking_verification_app/features/line_stock/data/models/line_stock_model.dart';
import 'package:picking_verification_app/core/error/exceptions.dart';

/// Mock DataSource for network layer
class MockLineStockRemoteDataSource extends Mock
    implements LineStockRemoteDataSource {}

/// Integration Test: Complete Cable Shelving Flow
///
/// This test verifies the complete shelving workflow from setting target
/// location to confirming shelving with multiple cables.
void main() {
  group('Cable Shelving Flow Integration Tests', () {
    late LineStockBloc bloc;
    late MockLineStockRemoteDataSource mockDataSource;

    // Test fixtures
    const targetLocation = 'TARGET-A-01';

    const cable1Barcode = 'CABLE001';
    const cable1Model = LineStockModel(
      stockId: 101,
      materialCode: 'MAT101',
      materialDesc: '电缆A',
      quantity: 100.0,
      baseUnit: 'M',
      batchCode: 'BATCH101',
      locationCode: 'WH-A-01',
      barcode: cable1Barcode,
    );

    const cable2Barcode = 'CABLE002';
    const cable2Model = LineStockModel(
      stockId: 102,
      materialCode: 'MAT102',
      materialDesc: '电缆B',
      quantity: 150.0,
      baseUnit: 'M',
      batchCode: 'BATCH102',
      locationCode: 'WH-A-02',
      barcode: cable2Barcode,
    );

    const cable3Barcode = 'CABLE003';
    const cable3Model = LineStockModel(
      stockId: 103,
      materialCode: 'MAT103',
      materialDesc: '电缆C',
      quantity: 200.0,
      baseUnit: 'M',
      batchCode: 'BATCH103',
      locationCode: 'WH-A-03',
      barcode: cable3Barcode,
    );

    final cable1Entity = cable1Model.toEntity();
    final cable2Entity = cable2Model.toEntity();
    final cable3Entity = cable3Model.toEntity();

    setUp(() {
      mockDataSource = MockLineStockRemoteDataSource();
      final repository = LineStockRepositoryImpl(
        remoteDataSource: mockDataSource,
      );
      bloc = LineStockBloc(repository: repository);

      // Setup mock responses for cable queries
      when(() => mockDataSource.queryByBarcode(
            barcode: cable1Barcode,
            factoryId: any(named: 'factoryId'),
          )).thenAnswer((_) async => cable1Model);

      when(() => mockDataSource.queryByBarcode(
            barcode: cable2Barcode,
            factoryId: any(named: 'factoryId'),
          )).thenAnswer((_) async => cable2Model);

      when(() => mockDataSource.queryByBarcode(
            barcode: cable3Barcode,
            factoryId: any(named: 'factoryId'),
          )).thenAnswer((_) async => cable3Model);

      // Setup mock response for transfer
      when(() => mockDataSource.transferStock(
            locationCode: any(named: 'locationCode'),
            barCodes: any(named: 'barCodes'),
          )).thenAnswer((_) async => true);
    });

    tearDown(() {
      bloc.close();
    });

    group('Set Target Location', () {
      blocTest<LineStockBloc, LineStockState>(
        'should set target location and prepare for shelving',
        build: () => bloc,
        act: (bloc) => bloc.add(const SetTargetLocation(targetLocation)),
        expect: () => [
          const ShelvingInProgress(
            targetLocation: targetLocation,
            cableList: [],
            canSubmit: false,
          ),
        ],
      );
    });

    group('Add Cables to List', () {
      blocTest<LineStockBloc, LineStockState>(
        'should add first cable to empty list',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
        },
        skip: 1, // Skip initial state from SetTargetLocation
        expect: () => [
          const LineStockLoading(message: '验证条码...'),
          ShelvingInProgress(
            targetLocation: targetLocation,
            cableList: [CableItem.fromLineStock(cable1Entity)],
            canSubmit: true,
          ),
        ],
      );

      blocTest<LineStockBloc, LineStockState>(
        'should add multiple cables maintaining order',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable2Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable3Barcode));
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList.length, equals(3));
          expect(state.cableList[0].barcode, equals(cable1Barcode));
          expect(state.cableList[1].barcode, equals(cable2Barcode));
          expect(state.cableList[2].barcode, equals(cable3Barcode));
          expect(state.canSubmit, isTrue);
        },
      );
    });

    group('Remove Cables from List', () {
      blocTest<LineStockBloc, LineStockState>(
        'should remove cable from middle of list',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable2Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable3Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const RemoveCableBarcode(cable2Barcode));
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList.length, equals(2));
          expect(state.cableList[0].barcode, equals(cable1Barcode));
          expect(state.cableList[1].barcode, equals(cable3Barcode));
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should disable submit when removing last cable',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const RemoveCableBarcode(cable1Barcode));
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList, isEmpty);
          expect(state.canSubmit, isFalse);
        },
      );
    });

    group('Clear Cable List', () {
      blocTest<LineStockBloc, LineStockState>(
        'should clear all cables but keep location',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable2Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ClearCableList());
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList, isEmpty);
          expect(state.targetLocation, equals(targetLocation));
          expect(state.canSubmit, isFalse);
        },
      );
    });

    group('Confirm Shelving', () {
      blocTest<LineStockBloc, LineStockState>(
        'should successfully complete shelving with transfer',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable2Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ConfirmShelving(
            locationCode: targetLocation,
            barCodes: [cable1Barcode, cable2Barcode],
          ));
        },
        skip: 5, // Skip setup states (SetLocation + LoadingCable1 + Shelving1 + LoadingCable2 + Shelving2)
        expect: () => [
          const LineStockLoading(message: '上架中...'),
          const ShelvingSuccess(
            message: '上架成功',
            targetLocation: targetLocation,
            transferredCount: 2,
          ),
        ],
        verify: (_) {
          verify(() => mockDataSource.transferStock(
                locationCode: targetLocation,
                barCodes: [cable1Barcode, cable2Barcode],
              )).called(1);
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should handle transfer API failure',
        build: () {
          when(() => mockDataSource.transferStock(
                locationCode: any(named: 'locationCode'),
                barCodes: any(named: 'barCodes'),
              )).thenThrow(ServerException('上架失败：服务器错误'));
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ConfirmShelving(
            locationCode: targetLocation,
            barCodes: [cable1Barcode],
          ));
        },
        skip: 3, // Skip setup states (SetLocation + Loading + ShelvingInProgress)
        expect: () => [
          const LineStockLoading(message: '上架中...'),
          const LineStockError(
            message: '上架失败：服务器错误',
            canRetry: true,
          ),
        ],
      );
    });

    group('Modify Location', () {
      blocTest<LineStockBloc, LineStockState>(
        'should clear cables when modifying location',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable2Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ModifyTargetLocation());
        },
        verify: (bloc) {
          expect(bloc.state, equals(const LineStockInitial()));
        },
      );
    });

    group('Reset Operations', () {
      blocTest<LineStockBloc, LineStockState>(
        'should reset to initial after successful shelving',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ConfirmShelving(
            locationCode: targetLocation,
            barCodes: [cable1Barcode],
          ));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ResetShelving());
        },
        verify: (bloc) {
          expect(bloc.state, isA<LineStockInitial>());
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should reset to initial on ResetLineStock',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ResetLineStock());
        },
        verify: (bloc) {
          expect(bloc.state, equals(const LineStockInitial()));
        },
      );
    });
  });
}
