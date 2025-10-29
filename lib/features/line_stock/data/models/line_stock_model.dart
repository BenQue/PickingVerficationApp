import '../../domain/entities/line_stock_entity.dart';

/// Line Stock Model - Data Transfer Object
/// Maps to API JSON response
class LineStockModel {
  final int? stockId;
  final String? materialCode;
  final String? materialDesc;
  final double? quantity;
  final String? baseUnit;
  final String? batchCode;
  final String? locationCode;
  final String? barcode;

  const LineStockModel({
    this.stockId,
    this.materialCode,
    this.materialDesc,
    this.quantity,
    this.baseUnit,
    this.batchCode,
    this.locationCode,
    this.barcode,
  });

  factory LineStockModel.fromJson(Map<String, dynamic> json) {
    return LineStockModel(
      stockId: json['stockId'] as int?,
      materialCode: json['materialCode'] as String?,
      materialDesc: json['materialDesc'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      baseUnit: json['baseUnit'] as String?,
      batchCode: json['batchCode'] as String?,
      locationCode: json['locationCode'] as String?,
      barcode: json['barCode'] as String?, // API uses 'barCode' with capital C
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockId': stockId,
      'materialCode': materialCode,
      'materialDesc': materialDesc,
      'quantity': quantity,
      'baseUnit': baseUnit,
      'batchCode': batchCode,
      'locationCode': locationCode,
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
      baseUnit: '米', // Temporarily fixed to '米' until server provides correct unit
      batchCode: batchCode ?? '',
      locationCode: locationCode ?? '',
      barcode: barcode ?? '',
    );
  }
}
