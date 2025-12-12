import 'package:equatable/equatable.dart';

/// Line Stock Entity - Domain Model
/// Represents line-side inventory information
class LineStock extends Equatable {
  final int? stockId;
  final String materialCode;
  final String materialDesc;
  final double quantity;
  final double lastQuantity; // Remaining quantity
  final String baseUnit;
  final String batchCode;
  final String locationCode;
  final String locationDesc; // Location description
  final String barcode;

  const LineStock({
    this.stockId,
    required this.materialCode,
    required this.materialDesc,
    required this.quantity,
    required this.lastQuantity,
    required this.baseUnit,
    required this.batchCode,
    required this.locationCode,
    required this.locationDesc,
    required this.barcode,
  });

  @override
  List<Object?> get props => [
        stockId,
        materialCode,
        materialDesc,
        quantity,
        lastQuantity,
        baseUnit,
        batchCode,
        locationCode,
        locationDesc,
        barcode,
      ];

  // Business logic methods
  bool get hasStock => quantity > 0;

  String get displayInfo => '$materialDesc ($materialCode)';

  String get quantityInfo => '$quantity $baseUnit';

  /// Used quantity (original - remaining)
  double get usedQuantity => quantity - lastQuantity;

  // Copy method for state updates
  LineStock copyWith({
    int? stockId,
    String? materialCode,
    String? materialDesc,
    double? quantity,
    double? lastQuantity,
    String? baseUnit,
    String? batchCode,
    String? locationCode,
    String? locationDesc,
    String? barcode,
  }) {
    return LineStock(
      stockId: stockId ?? this.stockId,
      materialCode: materialCode ?? this.materialCode,
      materialDesc: materialDesc ?? this.materialDesc,
      quantity: quantity ?? this.quantity,
      lastQuantity: lastQuantity ?? this.lastQuantity,
      baseUnit: baseUnit ?? this.baseUnit,
      batchCode: batchCode ?? this.batchCode,
      locationCode: locationCode ?? this.locationCode,
      locationDesc: locationDesc ?? this.locationDesc,
      barcode: barcode ?? this.barcode,
    );
  }
}
