import 'package:equatable/equatable.dart';
import 'line_stock_entity.dart';

/// Cable Item Value Object
/// Represents a scanned cable barcode item for shelving
class CableItem extends Equatable {
  final String barcode;
  final String batchCode;
  final String materialCode;
  final String materialDesc;
  final double quantity;
  final String baseUnit;
  final String currentLocation;

  const CableItem({
    required this.barcode,
    required this.batchCode,
    required this.materialCode,
    required this.materialDesc,
    required this.quantity,
    required this.baseUnit,
    required this.currentLocation,
  });

  @override
  List<Object?> get props => [
        barcode,
        batchCode,
        materialCode,
        materialDesc,
        quantity,
        baseUnit,
        currentLocation,
      ];

  /// Create from LineStock entity
  factory CableItem.fromLineStock(LineStock stock) {
    return CableItem(
      barcode: stock.barcode,
      batchCode: stock.batchCode,
      materialCode: stock.materialCode,
      materialDesc: stock.materialDesc,
      quantity: stock.quantity,
      baseUnit: stock.baseUnit,
      currentLocation: stock.locationCode,
    );
  }

  String get displayInfo => '$materialCode - $materialDesc';

  String get quantityInfo => '$quantity $baseUnit';

  CableItem copyWith({
    String? barcode,
    String? batchCode,
    String? materialCode,
    String? materialDesc,
    double? quantity,
    String? baseUnit,
    String? currentLocation,
  }) {
    return CableItem(
      barcode: barcode ?? this.barcode,
      batchCode: batchCode ?? this.batchCode,
      materialCode: materialCode ?? this.materialCode,
      materialDesc: materialDesc ?? this.materialDesc,
      quantity: quantity ?? this.quantity,
      baseUnit: baseUnit ?? this.baseUnit,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}
