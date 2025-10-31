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
    on<StartShelvingWithCable>(_onStartShelvingWithCable);
    on<SetTargetLocation>(_onSetTargetLocation);
    on<ModifyTargetLocation>(_onModifyTargetLocation);
    on<AddCableBarcode>(_onAddCableBarcode);
    on<RemoveCableBarcode>(_onRemoveCableBarcode);
    on<ClearCableList>(_onClearCableList);
    on<ConfirmShelving>(_onConfirmShelving);
    on<ResetShelving>(_onResetShelving);
    on<ResetLineStock>(_onResetLineStock);
  }

  /// Recursively find the ShelvingInProgress state from error chain
  ShelvingInProgress? _findShelvingState(LineStockState state) {
    if (state is ShelvingInProgress) {
      return state;
    }
    if (state is LineStockError && state.previousState != null) {
      return _findShelvingState(state.previousState!);
    }
    return null;
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

  Future<void> _onStartShelvingWithCable(
    StartShelvingWithCable event,
    Emitter<LineStockState> emit,
  ) async {
    // Query the cable information first
    emit(const LineStockLoading(message: '正在获取电缆信息...'));

    final result = await repository.queryByBarcode(
      barcode: event.barcode,
    );

    result.fold(
      (failure) => emit(LineStockError(
        message: '无法获取电缆信息: ${failure.message}',
        previousState: const ShelvingInProgress(
          cableList: [],
          canSubmit: false,
        ),
      )),
      (stock) {
        // Create cable item from stock
        final cable = CableItem.fromLineStock(stock);
        print('[DEBUG] Created cable item from stock: ${cable.barcode}');
        
        // Start shelving with this cable pre-filled
        print('[DEBUG] Emitting ShelvingInProgress with 1 cable');
        emit(ShelvingInProgress(
          targetLocation: null,
          cableList: [cable],
          canSubmit: false, // Cannot submit until location is set
        ));
      },
    );
  }

  void _onSetTargetLocation(
    SetTargetLocation event,
    Emitter<LineStockState> emit,
  ) {
    print('[DEBUG] _onSetTargetLocation called with location: ${event.locationCode}');
    final currentState = state;
    print('[DEBUG] Current state type: ${currentState.runtimeType}');
    
    // Try to find ShelvingInProgress from current or error chain
    ShelvingInProgress? shelvingState;
    if (currentState is ShelvingInProgress) {
      shelvingState = currentState;
    } else if (currentState is LineStockError) {
      shelvingState = _findShelvingState(currentState);
    }
    
    // Preserve existing cable list if modifying location or recovering from error
    List<CableItem> existingCables = [];
    if (shelvingState != null) {
      existingCables = shelvingState.cableList;
      print('[DEBUG] Found shelving state with ${existingCables.length} cables');
    } else {
      print('[DEBUG] No shelving state found, starting with empty list');
    }
    
    emit(ShelvingInProgress(
      targetLocation: event.locationCode,
      cableList: existingCables,
      canSubmit: existingCables.isNotEmpty, // Can submit if cables exist
    ));
  }

  void _onModifyTargetLocation(
    ModifyTargetLocation event,
    Emitter<LineStockState> emit,
  ) {
    final currentState = state;
    
    // Try to find ShelvingInProgress from current or error chain
    ShelvingInProgress? shelvingState;
    if (currentState is ShelvingInProgress) {
      shelvingState = currentState;
    } else if (currentState is LineStockError) {
      shelvingState = _findShelvingState(currentState);
    }
    
    // Preserve cable list when modifying target location
    if (shelvingState != null) {
      emit(ShelvingInProgress(
        targetLocation: null, // Clear location but keep cables
        cableList: shelvingState.cableList,
        canSubmit: false, // Cannot submit without target location
      ));
    } else {
      emit(const LineStockInitial());
    }
  }

  Future<void> _onAddCableBarcode(
    AddCableBarcode event,
    Emitter<LineStockState> emit,
  ) async {
    final currentState = state;

    // Find the ShelvingInProgress state (could be current or in error chain)
    ShelvingInProgress? shelvingState;
    if (currentState is ShelvingInProgress) {
      shelvingState = currentState;
    } else if (currentState is LineStockError && currentState.previousState != null) {
      shelvingState = _findShelvingState(currentState.previousState!);
    }

    // If no shelving state exists, create a new one without target location
    // This allows adding cables before setting the target location
    if (shelvingState == null) {
      shelvingState = const ShelvingInProgress(
        targetLocation: null,
        cableList: [],
        canSubmit: false,
      );
    }

    // Check for duplicate barcode using the found shelving state
    print('[LineStock] 检查重复条码: ${event.barcode}');
    print('[LineStock] 当前列表中的条码: ${shelvingState.cableList.map((c) => c.barcode).toList()}');

    final isDuplicate = shelvingState.cableList.any((c) => c.barcode == event.barcode);
    print('[LineStock] 是否重复: $isDuplicate');

    if (isDuplicate) {
      print('[LineStock] ⚠️ 检测到重复条码，拒绝添加');
      emit(LineStockError(
        message: '⚠️ 重复条码：${event.barcode}\n该电缆已在上架清单中',
        canRetry: true,
        previousState: shelvingState,
      ));
      // Don't auto-recover - let UI handle display with previousState
      return;
    }

    print('[LineStock] ✓ 条码验证通过，继续处理');

    // Save the shelving state BEFORE emitting Loading
    final stateBeforeLoading = shelvingState;

    emit(const LineStockLoading(message: '验证条码...'));

    // Query and validate barcode
    final result = await repository.queryByBarcode(barcode: event.barcode);

    result.fold(
(failure) {
        emit(LineStockError(
          message: '条码验证失败：${failure.message}',
          canRetry: true,
          previousState: stateBeforeLoading, // Use state BEFORE loading
        ));
        // Don't auto-recover - let UI handle display with previousState
      },
(stock) {
        // Check if cable is already at target location (only if target location is set)
        if (stateBeforeLoading.hasTargetLocation &&
            stock.locationCode == stateBeforeLoading.targetLocation) {
          emit(LineStockError(
            message: '电缆已在目标库位 ${stateBeforeLoading.targetLocation},无需转移',
            canRetry: true,
            previousState: stateBeforeLoading, // Use state BEFORE loading
          ));
          // Don't auto-recover - let UI handle display with previousState
          return;
        }

        final newCable = CableItem.fromLineStock(stock);
        final updatedList = [...stateBeforeLoading.cableList, newCable];

        emit(ShelvingInProgress(
          targetLocation: stateBeforeLoading.targetLocation,
          cableList: updatedList,
          canSubmit: stateBeforeLoading.hasTargetLocation && updatedList.isNotEmpty,
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
    final currentState = state;
    
    // Find the ShelvingInProgress state to preserve for error recovery
    final shelvingState = _findShelvingState(currentState);
    
    if (shelvingState == null) {
      emit(const LineStockError(
        message: '无效的上架状态，请重新开始',
        canRetry: false,
      ));
      return;
    }
    
    emit(const LineStockLoading(message: '上架中...'));

    final result = await repository.transferStock(
      locationCode: event.locationCode,
      barCodes: event.barCodes,
    );

    result.fold(
      (failure) => emit(LineStockError(
        message: failure.message,
        canRetry: true,
        previousState: shelvingState, // Use the found shelving state for retry
      )),
      (success) {
        if (success) {
          emit(ShelvingSuccess(
            message: '上架成功',
            targetLocation: event.locationCode,
            transferredCount: event.barCodes.length,
          ));
        } else {
          emit(LineStockError(
            message: '上架失败',
            canRetry: true,
            previousState: shelvingState, // Use the found shelving state for retry
          ));
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
