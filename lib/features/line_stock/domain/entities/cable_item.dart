import 'package:equatable/equatable.dart';
import 'line_stock_entity.dart';

/// Cable Item Value Object
/// Represents a scanned cable barcode item for shelving
class CableItem extends Equatable {
  final String barcode;
  final String materialCode;
  final String materialDesc;
  final String currentLocation;

  const CableItem({
    required this.barcode,
    required this.materialCode,
    required this.materialDesc,
    required this.currentLocation,
  });

  @override
  List<Object?> get props => [
        barcode,
        materialCode,
        materialDesc,
        currentLocation,
      ];

  /// Create from LineStock entity
  factory CableItem.fromLineStock(LineStock stock) {
    return CableItem(
      barcode: stock.barcode,
      materialCode: stock.materialCode,
      materialDesc: stock.materialDesc,
      currentLocation: stock.locationCode,
    );
  }

  String get displayInfo => '$materialCode - $materialDesc';

  CableItem copyWith({
    String? barcode,
    String? materialCode,
    String? materialDesc,
    String? currentLocation,
  }) {
    return CableItem(
      barcode: barcode ?? this.barcode,
      materialCode: materialCode ?? this.materialCode,
      materialDesc: materialDesc ?? this.materialDesc,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}
