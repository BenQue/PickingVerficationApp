import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_bloc.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_event.dart';
import 'package:picking_verification_app/features/line_stock/presentation/bloc/line_stock_state.dart';
import 'package:picking_verification_app/features/line_stock/data/repositories/line_stock_repository_impl.dart';
import 'package:picking_verification_app/features/line_stock/data/datasources/line_stock_remote_datasource.dart';
import 'package:picking_verification_app/features/line_stock/data/models/line_stock_model.dart';

/// Mock DataSource for network layer
class MockLineStockRemoteDataSource extends Mock
    implements LineStockRemoteDataSource {}

/// Integration Test: Edge Cases and Boundary Scenarios
///
/// Tests boundary conditions and edge cases in the Line Stock workflow
void main() {
  group('Edge Cases Integration Tests', () {
    late LineStockBloc bloc;
    late MockLineStockRemoteDataSource mockDataSource;

    const targetLocation = 'TARGET-A-01';

    const cable1Barcode = 'CABLE001';
    const cable1Model = LineStockModel(
      stockId: 1,
      materialCode: 'MAT001',
      materialDesc: '电缆A',
      quantity: 100.0,
      baseUnit: 'M',
      batchCode: 'BATCH001',
      locationCode: 'WH-A-01',
      barcode: cable1Barcode,
    );

    const cable2Barcode = 'CABLE002';
    const cable2Model = LineStockModel(
      stockId: 2,
      materialCode: 'MAT002',
      materialDesc: '电缆B',
      quantity: 150.0,
      baseUnit: 'M',
      batchCode: 'BATCH002',
      locationCode: 'WH-A-02',
      barcode: cable2Barcode,
    );

    const cable3Barcode = 'CABLE003';
    const cable3Model = LineStockModel(
      stockId: 3,
      materialCode: 'MAT003',
      materialDesc: '电缆C',
      quantity: 200.0,
      baseUnit: 'M',
      batchCode: 'BATCH003',
      locationCode: 'WH-A-03',
      barcode: cable3Barcode,
    );

    setUp(() {
      mockDataSource = MockLineStockRemoteDataSource();
      final repository = LineStockRepositoryImpl(
        remoteDataSource: mockDataSource,
      );
      bloc = LineStockBloc(repository: repository);

      // Setup mock responses
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

      when(() => mockDataSource.transferStock(
            locationCode: any(named: 'locationCode'),
            barCodes: any(named: 'barCodes'),
          )).thenAnswer((_) async => true);
    });

    tearDown(() {
      bloc.close();
    });

    group('Duplicate Barcode Prevention', () {
      blocTest<LineStockBloc, LineStockState>(
        'should prevent adding duplicate cable barcode',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add cable first time
          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // Try to add same cable again - should be prevented or show error
          bloc.add(const AddCableBarcode(cable1Barcode));
        },
        verify: (bloc) {
          final state = bloc.state;
          // Either stays in ShelvingInProgress with only one cable
          // or shows an error
          if (state is ShelvingInProgress) {
            expect(state.cableList.length, lessThanOrEqualTo(1));
          } else if (state is LineStockError) {
            expect(state.message, isNotEmpty);
          }
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should allow same barcode after removing it',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add cable
          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // Remove cable
          bloc.add(const RemoveCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add same cable again - should be allowed
          bloc.add(const AddCableBarcode(cable1Barcode));
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList.length, equals(1));
          expect(state.cableList[0].barcode, equals(cable1Barcode));
        },
      );
    });

    group('Modify Location Clears List', () {
      blocTest<LineStockBloc, LineStockState>(
        'should clear cable list when modifying location',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add multiple cables
          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable2Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable3Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // Modify location - should clear cables
          bloc.add(const ModifyTargetLocation());
        },
        verify: (bloc) {
          // Should return to initial state
          expect(bloc.state, isA<LineStockInitial>());
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should allow setting new location after modify',
        build: () => bloc,
        act: (bloc) async {
          // Set initial location with cables
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // Modify location
          bloc.add(const ModifyTargetLocation());
          await Future.delayed(const Duration(milliseconds: 50));

          // Set new location
          const newLocation = 'TARGET-B-01';
          bloc.add(const SetTargetLocation(newLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add cables to new location
          bloc.add(const AddCableBarcode(cable2Barcode));
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.targetLocation, equals('TARGET-B-01'));
          expect(state.cableList.length, equals(1));
          expect(state.cableList[0].barcode, equals(cable2Barcode));
        },
      );
    });

    group('Empty List Submit Prevention', () {
      blocTest<LineStockBloc, LineStockState>(
        'should have canSubmit=false when list is empty',
        build: () => bloc,
        act: (bloc) => bloc.add(const SetTargetLocation(targetLocation)),
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList, isEmpty);
          expect(state.canSubmit, isFalse);
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should have canSubmit=true when list has items',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList, isNotEmpty);
          expect(state.canSubmit, isTrue);
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should set canSubmit=false after removing last item',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add cable
          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // Remove last cable
          bloc.add(const RemoveCableBarcode(cable1Barcode));
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList, isEmpty);
          expect(state.canSubmit, isFalse);
        },
      );
    });

    group('Large Cable List', () {
      blocTest<LineStockBloc, LineStockState>(
        'should handle adding many cables',
        build: () {
          // Setup mocks for 10 different cables
          for (int i = 1; i <= 10; i++) {
            final barcode = 'CABLE${i.toString().padLeft(3, '0')}';
            final model = LineStockModel(
              stockId: i,
              materialCode: 'MAT${i.toString().padLeft(3, '0')}',
              materialDesc: '电缆$i',
              quantity: 100.0 + i,
              baseUnit: 'M',
              batchCode: 'BATCH${i.toString().padLeft(3, '0')}',
              locationCode: 'WH-A-${i.toString().padLeft(2, '0')}',
              barcode: barcode,
            );

            when(() => mockDataSource.queryByBarcode(
                  barcode: barcode,
                  factoryId: any(named: 'factoryId'),
                )).thenAnswer((_) async => model);
          }
          return bloc;
        },
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add 10 cables
          for (int i = 1; i <= 10; i++) {
            final barcode = 'CABLE${i.toString().padLeft(3, '0')}';
            bloc.add(AddCableBarcode(barcode));
            await Future.delayed(const Duration(milliseconds: 50));
          }
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList.length, equals(10));
          expect(state.canSubmit, isTrue);
        },
      );
    });

    group('Clear List Operation', () {
      blocTest<LineStockBloc, LineStockState>(
        'should clear all cables but keep location',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add multiple cables
          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable2Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // Clear list
          bloc.add(const ClearCableList());
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList, isEmpty);
          expect(state.targetLocation, equals(targetLocation));
          expect(state.canSubmit, isFalse);
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should allow adding cables after clear',
        build: () => bloc,
        act: (bloc) async {
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // Add and clear
          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const ClearCableList());
          await Future.delayed(const Duration(milliseconds: 50));

          // Add new cable
          bloc.add(const AddCableBarcode(cable2Barcode));
        },
        verify: (bloc) {
          final state = bloc.state as ShelvingInProgress;
          expect(state.cableList.length, equals(1));
          expect(state.cableList[0].barcode, equals(cable2Barcode));
          expect(state.canSubmit, isTrue);
        },
      );
    });

    group('State Transitions', () {
      blocTest<LineStockBloc, LineStockState>(
        'should handle complete workflow with all operations',
        build: () => bloc,
        act: (bloc) async {
          // 1. Set location
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          // 2. Add cables
          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          bloc.add(const AddCableBarcode(cable2Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // 3. Remove one cable
          bloc.add(const RemoveCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 50));

          // 4. Add another cable
          bloc.add(const AddCableBarcode(cable3Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // 5. Confirm shelving
          bloc.add(const ConfirmShelving(
            locationCode: targetLocation,
            barCodes: [cable2Barcode, cable3Barcode],
          ));
        },
        verify: (bloc) {
          // Should end in success state
          expect(bloc.state, isA<ShelvingSuccess>());
          final state = bloc.state as ShelvingSuccess;
          expect(state.transferredCount, equals(2));
        },
      );

      blocTest<LineStockBloc, LineStockState>(
        'should reset to initial after ResetLineStock',
        build: () => bloc,
        act: (bloc) async {
          // Setup some state
          bloc.add(const SetTargetLocation(targetLocation));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(const AddCableBarcode(cable1Barcode));
          await Future.delayed(const Duration(milliseconds: 100));

          // Reset everything
          bloc.add(const ResetLineStock());
        },
        verify: (bloc) {
          expect(bloc.state, equals(const LineStockInitial()));
        },
      );
    });
  });
}
