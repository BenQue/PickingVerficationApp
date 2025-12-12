import 'package:equatable/equatable.dart';

/// Domain entity representing a cable item for handover/receiving
///
/// Contains the essential information needed for display in the receiving list
class HandoverItem extends Equatable {
  /// Cable barcode (unique identifier)
  final String barCode;

  /// Material code (物料号)
  final String materialCode;

  /// Material description (物料描述)
  final String materialDesc;

  /// Base unit of measurement (单位)
  final String baseUnit;

  /// Batch code (批次号)
  final String batchCode;

  /// Quantity (数量)
  final double quantity;

  const HandoverItem({
    required this.barCode,
    required this.materialCode,
    required this.materialDesc,
    required this.baseUnit,
    required this.batchCode,
    required this.quantity,
  });

  /// Display-friendly quantity string with unit
  String get quantityInfo => '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} $baseUnit';

  /// Short description for list display
  String get shortDesc {
    if (materialDesc.length > 30) {
      return '${materialDesc.substring(0, 30)}...';
    }
    return materialDesc;
  }

  @override
  List<Object?> get props => [
        barCode,
        materialCode,
        materialDesc,
        baseUnit,
        batchCode,
        quantity,
      ];
}
