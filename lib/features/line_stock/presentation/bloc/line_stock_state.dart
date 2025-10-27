import 'package:equatable/equatable.dart';
import '../../domain/entities/line_stock_entity.dart';
import '../../domain/entities/cable_item.dart';

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

/// Query success with stock information
class StockQuerySuccess extends LineStockState {
  final LineStock stock;

  const StockQuerySuccess(this.stock);

  @override
  List<Object?> get props => [stock];
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
