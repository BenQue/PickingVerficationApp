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

/// Query stock by material code
/// Returns list of stock items for all batches of the material
class QueryStockByMaterialCode extends LineStockEvent {
  final String materialCode;
  final int? factoryId;

  const QueryStockByMaterialCode({
    required this.materialCode,
    this.factoryId,
  });

  @override
  List<Object?> get props => [materialCode, factoryId];
}

// ============ Shelving Events ============

/// Start shelving with pre-filled cable from query
class StartShelvingWithCable extends LineStockEvent {
  final String barcode;

  const StartShelvingWithCable(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

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

// ============ Handover/Receiving Events ============

/// Scan barcode to add to receiving list
/// This will query the API first, then add to list if successful
class ScanHandoverBarcode extends LineStockEvent {
  final String barcode;

  const ScanHandoverBarcode(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// Remove item from receiving list by barcode
class RemoveHandoverItem extends LineStockEvent {
  final String barcode;

  const RemoveHandoverItem(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// Clear all items from receiving list
class ClearHandoverList extends LineStockEvent {
  const ClearHandoverList();
}

/// Confirm handover/receiving for all items in list
class ConfirmHandover extends LineStockEvent {
  const ConfirmHandover();
}

/// Reset handover state to initial
class ResetHandover extends LineStockEvent {
  const ResetHandover();
}
