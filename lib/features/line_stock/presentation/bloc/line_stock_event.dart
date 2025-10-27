import 'package:equatable/equatable.dart';

/// Line Stock Events
abstract class LineStockEvent extends Equatable {
  const LineStockEvent();

  @override
  List<Object?> get props => [];
}

// ============ Query Events ============

/// Query stock by barcode
class QueryStockByBarcode extends LineStockEvent {
  final String barcode;
  final int? factoryId;

  const QueryStockByBarcode({
    required this.barcode,
    this.factoryId,
  });

  @override
  List<Object?> get props => [barcode, factoryId];
}

/// Clear query result
class ClearQueryResult extends LineStockEvent {
  const ClearQueryResult();
}

// ============ Shelving Events ============

/// Set target location for shelving
class SetTargetLocation extends LineStockEvent {
  final String locationCode;

  const SetTargetLocation(this.locationCode);

  @override
  List<Object?> get props => [locationCode];
}

/// Modify target location
class ModifyTargetLocation extends LineStockEvent {
  const ModifyTargetLocation();
}

/// Add cable barcode to shelving list
class AddCableBarcode extends LineStockEvent {
  final String barcode;

  const AddCableBarcode(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// Remove cable barcode from shelving list
class RemoveCableBarcode extends LineStockEvent {
  final String barcode;

  const RemoveCableBarcode(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// Clear all cable barcodes from shelving list
class ClearCableList extends LineStockEvent {
  const ClearCableList();
}

/// Confirm shelving and submit transfer
class ConfirmShelving extends LineStockEvent {
  final String locationCode;
  final List<String> barCodes;

  const ConfirmShelving({
    required this.locationCode,
    required this.barCodes,
  });

  @override
  List<Object?> get props => [locationCode, barCodes];
}

/// Reset shelving state
class ResetShelving extends LineStockEvent {
  const ResetShelving();
}

// ============ General Events ============

/// Reset all states
class ResetLineStock extends LineStockEvent {
  const ResetLineStock();
}
