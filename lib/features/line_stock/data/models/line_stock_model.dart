import '../../domain/entities/line_stock_entity.dart';

/// Line Stock Model - Data Transfer Object
/// Maps to API JSON response
class LineStockModel {
  final int? stockId;
  final String? materialCode;
  final String? materialDesc;
  final double? quantity;
  final double? lastQuantity; // Remaining quantity
  final String? baseUnit;
  final String? batchCode;
  final String? locationCode;
  final String? locationDesc; // Location description
  final String? barcode;

  const LineStockModel({
    this.stockId,
    this.materialCode,
    this.materialDesc,
    this.quantity,
    this.lastQuantity,
    this.baseUnit,
    this.batchCode,
    this.locationCode,
    this.locationDesc,
    this.barcode,
  });

  factory LineStockModel.fromJson(Map<String, dynamic> json) {
    return LineStockModel(
      stockId: json['id'] as int? ?? json['stockId'] as int?,
      materialCode: json['materialCode'] as String?,
      materialDesc: json['materialDesc'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      lastQuantity: (json['lastQuantity'] as num?)?.toDouble(),
      baseUnit: json['baseUnit'] as String?,
      batchCode: json['batchCode'] as String?,
      locationCode: json['locationCode'] as String?,
      locationDesc: json['locationDesc'] as String?,
      barcode: json['barCode'] as String?, // API uses 'barCode' with capital C
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockId': stockId,
      'materialCode': materialCode,
      'materialDesc': materialDesc,
      'quantity': quantity,
      'lastQuantity': lastQuantity,
      'baseUnit': baseUnit,
      'batchCode': batchCode,
      'locationCode': locationCode,
      'locationDesc': locationDesc,
      'barcode': barcode,
    };
  }

  /// Convert to domain entity
  LineStock toEntity() {
    return LineStock(
      stockId: stockId,
      materialCode: materialCode ?? '',
      materialDesc: materialDesc ?? '',
      quantity: quantity ?? 0.0,
      lastQuantity: lastQuantity ?? quantity ?? 0.0, // Default to quantity if not provided
      baseUnit: baseUnit ?? '米', // Default to '米' if not provided
      batchCode: batchCode ?? '',
      locationCode: locationCode ?? '',
      locationDesc: locationDesc ?? '',
      barcode: barcode ?? '',
    );
  }
}
