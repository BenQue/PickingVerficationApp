import 'package:equatable/equatable.dart';
import '../../domain/entities/line_stock_entity.dart';
import '../../domain/entities/cable_item.dart';
import '../../domain/entities/handover_item.dart';

/// Line Stock States
abstract class LineStockState extends Equatable {
  const LineStockState();

  @override
  List<Object?> get props => [];
}

// ============ Initial State ============

class LineStockInitial extends LineStockState {
  const LineStockInitial();
}

// ============ Loading State ============

class LineStockLoading extends LineStockState {
  final String? message;

  const LineStockLoading({this.message});

  @override
  List<Object?> get props => [message];
}

// ============ Query States ============

/// Query success with stock information (single item by barcode)
class StockQuerySuccess extends LineStockState {
  final LineStock stock;

  const StockQuerySuccess(this.stock);

  @override
  List<Object?> get props => [stock];
}

/// Query success with stock list (multiple batches by material code)
class MaterialQuerySuccess extends LineStockState {
  final String materialCode;
  final List<LineStock> stockList;

  const MaterialQuerySuccess({
    required this.materialCode,
    required this.stockList,
  });

  @override
  List<Object?> get props => [materialCode, stockList];

  /// Get total quantity across all batches
  double get totalQuantity =>
      stockList.fold(0, (sum, stock) => sum + stock.quantity);

  /// Get total last quantity across all batches
  double get totalLastQuantity =>
      stockList.fold(0, (sum, stock) => sum + stock.lastQuantity);

  /// Get material description (from first item)
  String get materialDesc =>
      stockList.isNotEmpty ? stockList.first.materialDesc : '';

  /// Get base unit (from first item)
  String get baseUnit => stockList.isNotEmpty ? stockList.first.baseUnit : '';

  /// Number of batches
  int get batchCount => stockList.length;
}

// ============ Shelving States ============

/// Shelving in progress with current list
class ShelvingInProgress extends LineStockState {
  final String? targetLocation;
  final List<CableItem> cableList;
  final bool canSubmit;

  const ShelvingInProgress({
    this.targetLocation,
    required this.cableList,
    required this.canSubmit,
  });

  @override
  List<Object?> get props => [targetLocation, cableList, canSubmit];

  bool get hasTargetLocation =>
      targetLocation != null && targetLocation!.isNotEmpty;
  bool get hasCables => cableList.isNotEmpty;
  int get cableCount => cableList.length;

  ShelvingInProgress copyWith({
    String? targetLocation,
    List<CableItem>? cableList,
    bool? canSubmit,
  }) {
    return ShelvingInProgress(
      targetLocation: targetLocation ?? this.targetLocation,
      cableList: cableList ?? this.cableList,
      canSubmit: canSubmit ?? this.canSubmit,
    );
  }
}

/// Shelving success
class ShelvingSuccess extends LineStockState {
  final String message;
  final String targetLocation;
  final int transferredCount;

  const ShelvingSuccess({
    required this.message,
    required this.targetLocation,
    required this.transferredCount,
  });

  @override
  List<Object?> get props => [message, targetLocation, transferredCount];

  String get displayMessage => '成功上架 $transferredCount 个电缆到 $targetLocation';
}

// ============ Error State ============

class LineStockError extends LineStockState {
  final String message;
  final bool canRetry;
  final LineStockState? previousState;

  const LineStockError({
    required this.message,
    this.canRetry = true,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, canRetry, previousState];
}

// ============ Handover/Receiving States ============

/// Handover in progress with current receiving list
class HandoverInProgress extends LineStockState {
  final List<HandoverItem> itemList;
  final bool isLoading;

  const HandoverInProgress({
    required this.itemList,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [itemList, isLoading];

  bool get canSubmit => itemList.isNotEmpty && !isLoading;
  int get itemCount => itemList.length;

  HandoverInProgress copyWith({
    List<HandoverItem>? itemList,
    bool? isLoading,
  }) {
    return HandoverInProgress(
      itemList: itemList ?? this.itemList,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Handover confirmation success
class HandoverSuccess extends LineStockState {
  final String message;
  final int confirmedCount;

  const HandoverSuccess({
    required this.message,
    required this.confirmedCount,
  });

  @override
  List<Object?> get props => [message, confirmedCount];
}
