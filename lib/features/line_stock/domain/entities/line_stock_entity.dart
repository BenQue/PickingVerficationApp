import 'package:equatable/equatable.dart';

/// Line Stock Entity - Domain Model
/// Represents line-side inventory information
class LineStock extends Equatable {
  final int? stockId;
  final String materialCode;
  final String materialDesc;
  final double quantity;
  final String baseUnit;
  final String batchCode;
  final String locationCode;
  final String barcode;

  const LineStock({
    this.stockId,
    required this.materialCode,
    required this.materialDesc,
    required this.quantity,
    required this.baseUnit,
    required this.batchCode,
    required this.locationCode,
    required this.barcode,
  });

  @override
  List<Object?> get props => [
        stockId,
        materialCode,
        materialDesc,
        quantity,
        baseUnit,
        batchCode,
        locationCode,
        barcode,
      ];

  // Business logic methods
  bool get hasStock => quantity > 0;

  String get displayInfo => '$materialDesc ($materialCode)';

  String get quantityInfo => '$quantity $baseUnit';

  // Copy method for state updates
  LineStock copyWith({
    int? stockId,
    String? materialCode,
    String? materialDesc,
    double? quantity,
    String? baseUnit,
    String? batchCode,
    String? locationCode,
    String? barcode,
  }) {
    return LineStock(
      stockId: stockId ?? this.stockId,
      materialCode: materialCode ?? this.materialCode,
      materialDesc: materialDesc ?? this.materialDesc,
      quantity: quantity ?? this.quantity,
      baseUnit: baseUnit ?? this.baseUnit,
      batchCode: batchCode ?? this.batchCode,
      locationCode: locationCode ?? this.locationCode,
      barcode: barcode ?? this.barcode,
    );
  }
}
