import '../../domain/entities/picking_order.dart';
import 'material_item_model.dart';

/// 拣货订单数据模型
class PickingOrderModel extends PickingOrder {
  const PickingOrderModel({
    required super.orderId,
    required super.orderNumber,
    required super.status,
    required super.createdAt,
    super.updatedAt,
    required super.items,
    super.materials,
    super.productionLineId,
    super.notes,
    required super.isVerified,
    super.verifiedBy,
    super.verifiedAt,
  });

  factory PickingOrderModel.fromJson(Map<String, dynamic> json) {
    return PickingOrderModel(
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      items: (json['items'] as List<dynamic>)
          .map((item) => PickingItemModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      materials: (json['materials'] as List<dynamic>?)
          ?.map((material) => MaterialItemModel.fromJson(material as Map<String, dynamic>).toEntity())
          .toList() ?? [],
      productionLineId: json['productionLineId'] as String?,
      notes: json['notes'] as String?,
      isVerified: json['isVerified'] as bool,
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.parse(json['verifiedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'items': items.map((item) => (item as PickingItemModel).toJson()).toList(),
      'materials': materials.map((material) => (material as MaterialItemModel).toJson()).toList(),
      'productionLineId': productionLineId,
      'notes': notes,
      'isVerified': isVerified,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  factory PickingOrderModel.fromEntity(PickingOrder entity) {
    return PickingOrderModel(
      orderId: entity.orderId,
      orderNumber: entity.orderNumber,
      status: entity.status,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      items: entity.items
          .map((item) => PickingItemModel.fromEntity(item))
          .toList(),
      materials: entity.materials
          .map((material) => MaterialItemModel.fromEntity(material).toEntity())
          .toList(),
      productionLineId: entity.productionLineId,
      notes: entity.notes,
      isVerified: entity.isVerified,
      verifiedBy: entity.verifiedBy,
      verifiedAt: entity.verifiedAt,
    );
  }
}

/// 拣货项目数据模型
class PickingItemModel extends PickingItem {
  const PickingItemModel({
    required super.itemId,
    required super.productCode,
    required super.productName,
    required super.specification,
    required super.requiredQuantity,
    required super.pickedQuantity,
    required super.unit,
    super.batchNumber,
    super.expiryDate,
    required super.location,
    required super.isVerified,
  });

  factory PickingItemModel.fromJson(Map<String, dynamic> json) {
    return PickingItemModel(
      itemId: json['itemId'] as String,
      productCode: json['productCode'] as String,
      productName: json['productName'] as String,
      specification: json['specification'] as String,
      requiredQuantity: json['requiredQuantity'] as int,
      pickedQuantity: json['pickedQuantity'] as int,
      unit: json['unit'] as String,
      batchNumber: json['batchNumber'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      location: json['location'] as String,
      isVerified: json['isVerified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'productCode': productCode,
      'productName': productName,
      'specification': specification,
      'requiredQuantity': requiredQuantity,
      'pickedQuantity': pickedQuantity,
      'unit': unit,
      'batchNumber': batchNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'location': location,
      'isVerified': isVerified,
    };
  }

  factory PickingItemModel.fromEntity(PickingItem entity) {
    return PickingItemModel(
      itemId: entity.itemId,
      productCode: entity.productCode,
      productName: entity.productName,
      specification: entity.specification,
      requiredQuantity: entity.requiredQuantity,
      pickedQuantity: entity.pickedQuantity,
      unit: entity.unit,
      batchNumber: entity.batchNumber,
      expiryDate: entity.expiryDate,
      location: entity.location,
      isVerified: entity.isVerified,
    );
  }
}