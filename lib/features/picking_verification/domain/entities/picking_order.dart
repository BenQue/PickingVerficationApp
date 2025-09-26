import 'package:equatable/equatable.dart';
import 'material_item.dart';

/// 拣货订单实体
class PickingOrder extends Equatable {
  final String orderId;
  final String orderNumber;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<PickingItem> items;
  final List<MaterialItem> materials; // 物料清单
  final String? productionLineId; // 生产线ID
  final String? notes;
  final bool isVerified;
  final String? verifiedBy;
  final DateTime? verifiedAt;

  const PickingOrder({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.items,
    this.materials = const [],
    this.productionLineId,
    this.notes,
    required this.isVerified,
    this.verifiedBy,
    this.verifiedAt,
  });

  PickingOrder copyWith({
    String? orderId,
    String? orderNumber,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PickingItem>? items,
    List<MaterialItem>? materials,
    String? productionLineId,
    String? notes,
    bool? isVerified,
    String? verifiedBy,
    DateTime? verifiedAt,
  }) {
    return PickingOrder(
      orderId: orderId ?? this.orderId,
      orderNumber: orderNumber ?? this.orderNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
      materials: materials ?? this.materials,
      productionLineId: productionLineId ?? this.productionLineId,
      notes: notes ?? this.notes,
      isVerified: isVerified ?? this.isVerified,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        orderNumber,
        status,
        createdAt,
        updatedAt,
        items,
        materials,
        productionLineId,
        notes,
        isVerified,
        verifiedBy,
        verifiedAt,
      ];
  
  /// 按类别分组的物料
  Map<MaterialCategory, List<MaterialItem>> get materialsByCategory {
    final Map<MaterialCategory, List<MaterialItem>> grouped = {};
    for (final material in materials) {
      grouped.putIfAbsent(material.category, () => []).add(material);
    }
    return grouped;
  }
  
  /// 检查所有物料是否已完成
  bool get allMaterialsCompleted {
    return materials.every((m) => m.status == MaterialStatus.completed);
  }
}

/// 拣货项目实体
class PickingItem extends Equatable {
  final String itemId;
  final String productCode;
  final String productName;
  final String specification;
  final int requiredQuantity;
  final int pickedQuantity;
  final String unit;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String location;
  final bool isVerified;

  const PickingItem({
    required this.itemId,
    required this.productCode,
    required this.productName,
    required this.specification,
    required this.requiredQuantity,
    required this.pickedQuantity,
    required this.unit,
    this.batchNumber,
    this.expiryDate,
    required this.location,
    required this.isVerified,
  });

  PickingItem copyWith({
    String? itemId,
    String? productCode,
    String? productName,
    String? specification,
    int? requiredQuantity,
    int? pickedQuantity,
    String? unit,
    String? batchNumber,
    DateTime? expiryDate,
    String? location,
    bool? isVerified,
  }) {
    return PickingItem(
      itemId: itemId ?? this.itemId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      specification: specification ?? this.specification,
      requiredQuantity: requiredQuantity ?? this.requiredQuantity,
      pickedQuantity: pickedQuantity ?? this.pickedQuantity,
      unit: unit ?? this.unit,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      location: location ?? this.location,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  /// 检查是否数量匹配
  bool get isQuantityMatched => pickedQuantity == requiredQuantity;

  /// 获取数量差异
  int get quantityDifference => pickedQuantity - requiredQuantity;

  @override
  List<Object?> get props => [
        itemId,
        productCode,
        productName,
        specification,
        requiredQuantity,
        pickedQuantity,
        unit,
        batchNumber,
        expiryDate,
        location,
        isVerified,
      ];
}