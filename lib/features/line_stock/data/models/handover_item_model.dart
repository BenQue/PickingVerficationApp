import '../../domain/entities/handover_item.dart';

/// Data model for handover/receiving cable item from API
///
/// Maps to API response from GetHandoverListByBarcode endpoint
class HandoverItemModel {
  final int id;
  final int factoryId;
  final int materialId;
  final String materialCode;
  final String materialDesc;
  final String baseUnit;
  final String batchCode;
  final String barCode;
  final double quantity;
  final double lastQuantity;
  final String status;
  final String sapStatus;
  final int locationId;
  final String locationCode;
  final String locationDesc;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updateBy;

  const HandoverItemModel({
    required this.id,
    required this.factoryId,
    required this.materialId,
    required this.materialCode,
    required this.materialDesc,
    required this.baseUnit,
    required this.batchCode,
    required this.barCode,
    required this.quantity,
    required this.lastQuantity,
    required this.status,
    required this.sapStatus,
    required this.locationId,
    required this.locationCode,
    required this.locationDesc,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updateBy,
  });

  /// Create model from JSON response
  factory HandoverItemModel.fromJson(Map<String, dynamic> json) {
    return HandoverItemModel(
      id: json['id'] as int? ?? 0,
      factoryId: json['factoryId'] as int? ?? 0,
      materialId: json['materialId'] as int? ?? 0,
      materialCode: json['materialCode'] as String? ?? '',
      materialDesc: json['materialDesc'] as String? ?? '',
      baseUnit: json['baseUnit'] as String? ?? 'M',
      batchCode: json['batchCode'] as String? ?? '',
      barCode: json['barCode'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      lastQuantity: (json['lastQuantity'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '',
      sapStatus: json['sapStatus'] as String? ?? '',
      locationId: json['locationId'] as int? ?? 0,
      locationCode: json['locationCode'] as String? ?? '',
      locationDesc: json['locationDesc'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      createdBy: json['createdBy'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      updateBy: json['updateBy'] as String?,
    );
  }

  /// Convert to domain entity
  HandoverItem toEntity() {
    return HandoverItem(
      barCode: barCode,
      materialCode: materialCode,
      materialDesc: materialDesc,
      baseUnit: baseUnit,
      batchCode: batchCode,
      quantity: quantity,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'factoryId': factoryId,
      'materialId': materialId,
      'materialCode': materialCode,
      'materialDesc': materialDesc,
      'baseUnit': baseUnit,
      'batchCode': batchCode,
      'barCode': barCode,
      'quantity': quantity,
      'lastQuantity': lastQuantity,
      'status': status,
      'sapStatus': sapStatus,
      'locationId': locationId,
      'locationCode': locationCode,
      'locationDesc': locationDesc,
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedAt': updatedAt?.toIso8601String(),
      'updateBy': updateBy,
    };
  }
}
