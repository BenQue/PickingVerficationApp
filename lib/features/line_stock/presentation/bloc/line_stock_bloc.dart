import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/line_stock_repository.dart';
import '../../domain/entities/cable_item.dart';
import 'line_stock_event.dart';
import 'line_stock_state.dart';

/// Line Stock BLoC
/// Manages state for line stock query and shelving operations
class LineStockBloc extends Bloc<LineStockEvent, LineStockState> {
  final LineStockRepository repository;

  LineStockBloc({required this.repository}) : super(const LineStockInitial()) {
    on<QueryStockByBarcode>(_onQueryStockByBarcode);
    on<ClearQueryResult>(_onClearQueryResult);
    on<SetTargetLocation>(_onSetTargetLocation);
    on<ModifyTargetLocation>(_onModifyTargetLocation);
    on<AddCableBarcode>(_onAddCableBarcode);
    on<RemoveCableBarcode>(_onRemoveCableBarcode);
    on<ClearCableList>(_onClearCableList);
    on<ConfirmShelving>(_onConfirmShelving);
    on<ResetShelving>(_onResetShelving);
    on<ResetLineStock>(_onResetLineStock);
  }

  Future<void> _onQueryStockByBarcode(
    QueryStockByBarcode event,
    Emitter<LineStockState> emit,
  ) async {
    emit(const LineStockLoading(message: '查询中...'));

    final result = await repository.queryByBarcode(
      barcode: event.barcode,
      factoryId: event.factoryId,
    );

    result.fold(
      (failure) => emit(LineStockError(message: failure.message)),
      (stock) => emit(StockQuerySuccess(stock)),
    );
  }

  void _onClearQueryResult(
    ClearQueryResult event,
    Emitter<LineStockState> emit,
  ) {
    emit(const LineStockInitial());
  }

  void _onSetTargetLocation(
    SetTargetLocation event,
    Emitter<LineStockState> emit,
  ) {
    emit(ShelvingInProgress(
      targetLocation: event.locationCode,
      cableList: const [],
      canSubmit: false,
    ));
  }

  void _onModifyTargetLocation(
    ModifyTargetLocation event,
    Emitter<LineStockState> emit,
  ) {
    emit(const LineStockInitial());
  }

  Future<void> _onAddCableBarcode(
    AddCableBarcode event,
    Emitter<LineStockState> emit,
  ) async {
    final currentState = state;

    if (currentState is! ShelvingInProgress) {
      emit(const LineStockError(
        message: '请先设置目标库位',
        canRetry: false,
      ));
      return;
    }

    // Check for duplicate barcode
    if (currentState.cableList.any((c) => c.barcode == event.barcode)) {
      emit(LineStockError(
        message: '条码已存在：${event.barcode}',
        canRetry: true,
        previousState: currentState,
      ));
      await Future.delayed(const Duration(seconds: 2));
      emit(currentState);
      return;
    }

    emit(const LineStockLoading(message: '验证条码...'));

    // Query and validate barcode
    final result = await repository.queryByBarcode(barcode: event.barcode);

    result.fold(
      (failure) {
        emit(LineStockError(
          message: '条码验证失败：${failure.message}',
          canRetry: true,
          previousState: currentState,
        ));
        Future.delayed(const Duration(seconds: 2), () {
          if (state is LineStockError) {
            emit(currentState);
          }
        });
      },
      (stock) {
        final newCable = CableItem.fromLineStock(stock);
        final updatedList = [...currentState.cableList, newCable];

        emit(ShelvingInProgress(
          targetLocation: currentState.targetLocation,
          cableList: updatedList,
          canSubmit: currentState.hasTargetLocation && updatedList.isNotEmpty,
        ));
      },
    );
  }

  void _onRemoveCableBarcode(
    RemoveCableBarcode event,
    Emitter<LineStockState> emit,
  ) {
    final currentState = state;

    if (currentState is! ShelvingInProgress) {
      return;
    }

    final updatedList =
        currentState.cableList.where((c) => c.barcode != event.barcode).toList();

    emit(ShelvingInProgress(
      targetLocation: currentState.targetLocation,
      cableList: updatedList,
      canSubmit: currentState.hasTargetLocation && updatedList.isNotEmpty,
    ));
  }

  void _onClearCableList(
    ClearCableList event,
    Emitter<LineStockState> emit,
  ) {
    final currentState = state;

    if (currentState is! ShelvingInProgress) {
      return;
    }

    emit(ShelvingInProgress(
      targetLocation: currentState.targetLocation,
      cableList: const [],
      canSubmit: false,
    ));
  }

  Future<void> _onConfirmShelving(
    ConfirmShelving event,
    Emitter<LineStockState> emit,
  ) async {
    emit(const LineStockLoading(message: '上架中...'));

    final result = await repository.transferStock(
      locationCode: event.locationCode,
      barCodes: event.barCodes,
    );

    result.fold(
      (failure) => emit(LineStockError(message: failure.message)),
      (success) {
        if (success) {
          emit(ShelvingSuccess(
            message: '上架成功',
            targetLocation: event.locationCode,
            transferredCount: event.barCodes.length,
          ));
        } else {
          emit(const LineStockError(message: '上架失败'));
        }
      },
    );
  }

  void _onResetShelving(
    ResetShelving event,
    Emitter<LineStockState> emit,
  ) {
    emit(const LineStockInitial());
  }

  void _onResetLineStock(
    ResetLineStock event,
    Emitter<LineStockState> emit,
  ) {
    emit(const LineStockInitial());
  }
}
