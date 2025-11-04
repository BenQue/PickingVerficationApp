/// 简化的拣货验证领域实体
library;

/// 简化的物料项实体
class SimpleMaterial {
  final String itemNo;
  final String materialCode;
  final String materialDesc;
  final int quantity;
  final int completedQuantity;
  final MaterialCategoryType category; // 物料类别

  SimpleMaterial({
    required this.itemNo,
    required this.materialCode,
    required this.materialDesc,
    required this.quantity,
    required this.completedQuantity,
    required this.category,
  });

  /// 检查需求数量是否有效（不为0）
  ///
  /// 当API返回的需求数量为0时，表示数据异常
  bool get hasValidQuantity => quantity > 0;

  /// 检查数据是否异常
  ///
  /// 数据异常包括：
  /// - 需求数量为0（数据错误）
  /// - 物料编码或描述为空
  bool get hasDataAnomaly => !hasValidQuantity || materialCode.isEmpty || materialDesc.isEmpty;

  /// 是否已完成
  ///
  /// 注意：需求数量为0时视为数据异常，不应标记为完成
  bool get isCompleted {
    if (!hasValidQuantity) return false;  // 数据异常，不能标记为完成
    return completedQuantity >= quantity;
  }

  /// 是否显示为异常状态（红色）
  ///
  /// 需求数量为0时应显示为异常状态
  bool get isError => hasDataAnomaly;

  /// 完成进度（0.0 - 1.0）
  double get progress {
    if (quantity == 0) return 0.0;
    return (completedQuantity / quantity).clamp(0.0, 1.0);
  }

  /// 剩余数量
  int get remainingQuantity => (quantity - completedQuantity).clamp(0, quantity);

  /// 创建更新后的副本
  SimpleMaterial copyWith({
    int? completedQuantity,
  }) {
    return SimpleMaterial(
      itemNo: itemNo,
      materialCode: materialCode,
      materialDesc: materialDesc,
      quantity: quantity,
      completedQuantity: completedQuantity ?? this.completedQuantity,
      category: category,
    );
  }
}

/// 物料类别枚举
enum MaterialCategoryType {
  cable,      // 断线物料 (cabelItems)
  center,     // 中央仓库物料 (centerStockItems)
  auto,       // 自动化仓库物料 (autoStockItems)
}

/// 物料类别扩展方法
extension MaterialCategoryExtension on MaterialCategoryType {
  String get displayName {
    switch (this) {
      case MaterialCategoryType.cable:
        return '断线物料';
      case MaterialCategoryType.center:
        return '中央仓库物料';
      case MaterialCategoryType.auto:
        return '自动化仓库物料';
    }
  }

  String get icon {
    switch (this) {
      case MaterialCategoryType.cable:
        return '🔌'; // 断线物料图标
      case MaterialCategoryType.center:
        return '📦'; // 中央仓库图标
      case MaterialCategoryType.auto:
        return '🤖'; // 自动化仓库图标
    }
  }
}

/// 简化的工单实体
class SimpleWorkOrder {
  final int orderId;
  final String orderNo;
  final String operationNo;
  final String operationStatus;
  
  // 物料统计
  final int cableItemCount;
  final int rawItemCount;
  final int rawMtrBatchCount;
  final int labelCount;
  
  // 按类别分组的物料
  final List<SimpleMaterial> cableMaterials;     // 断线物料
  final List<SimpleMaterial> centerMaterials;     // 中央仓库物料
  final List<SimpleMaterial> autoMaterials;       // 自动化仓库物料

  SimpleWorkOrder({
    required this.orderId,
    required this.orderNo,
    required this.operationNo,
    required this.operationStatus,
    required this.cableItemCount,
    required this.rawItemCount,
    required this.rawMtrBatchCount,
    required this.labelCount,
    required this.cableMaterials,
    required this.centerMaterials,
    required this.autoMaterials,
  });

  /// 获取所有物料
  List<SimpleMaterial> get allMaterials {
    return [
      ...cableMaterials,
      ...centerMaterials,
      ...autoMaterials,
    ];
  }

  /// 总物料数量
  int get totalMaterialCount => allMaterials.length;

  /// 已完成物料数量
  int get completedMaterialCount {
    return allMaterials.where((m) => m.isCompleted).length;
  }

  /// 总体完成进度
  double get overallProgress {
    if (totalMaterialCount == 0) return 0.0;
    return completedMaterialCount / totalMaterialCount;
  }

  /// 是否全部完成
  bool get isAllCompleted => completedMaterialCount == totalMaterialCount;

  /// 按类别获取物料
  List<SimpleMaterial> getMaterialsByCategory(MaterialCategoryType category) {
    switch (category) {
      case MaterialCategoryType.cable:
        return cableMaterials;
      case MaterialCategoryType.center:
        return centerMaterials;
      case MaterialCategoryType.auto:
        return autoMaterials;
    }
  }

  /// 按类别检查是否完成
  bool isCategoryCompleted(MaterialCategoryType category) {
    final materials = getMaterialsByCategory(category);
    return materials.isNotEmpty && materials.every((m) => m.isCompleted);
  }

  /// 获取各类别完成状态
  Map<MaterialCategoryType, bool> get categoryCompletionStatus {
    return {
      MaterialCategoryType.cable: isCategoryCompleted(MaterialCategoryType.cable),
      MaterialCategoryType.center: isCategoryCompleted(MaterialCategoryType.center),
      MaterialCategoryType.auto: isCategoryCompleted(MaterialCategoryType.auto),
    };
  }

  /// 获取各类别进度
  Map<MaterialCategoryType, double> get categoryProgress {
    return {
      MaterialCategoryType.cable: _getCategoryProgress(cableMaterials),
      MaterialCategoryType.center: _getCategoryProgress(centerMaterials),
      MaterialCategoryType.auto: _getCategoryProgress(autoMaterials),
    };
  }

  double _getCategoryProgress(List<SimpleMaterial> materials) {
    if (materials.isEmpty) return 0.0;
    final completed = materials.where((m) => m.isCompleted).length;
    return completed / materials.length;
  }

  /// 更新物料完成数量
  SimpleWorkOrder updateMaterialQuantity(String itemNo, int completedQuantity) {
    return SimpleWorkOrder(
      orderId: orderId,
      orderNo: orderNo,
      operationNo: operationNo,
      operationStatus: operationStatus,
      cableItemCount: cableItemCount,
      rawItemCount: rawItemCount,
      rawMtrBatchCount: rawMtrBatchCount,
      labelCount: labelCount,
      cableMaterials: _updateMaterialInList(cableMaterials, itemNo, completedQuantity),
      centerMaterials: _updateMaterialInList(centerMaterials, itemNo, completedQuantity),
      autoMaterials: _updateMaterialInList(autoMaterials, itemNo, completedQuantity),
    );
  }

  List<SimpleMaterial> _updateMaterialInList(
    List<SimpleMaterial> materials,
    String itemNo,
    int completedQuantity,
  ) {
    return materials.map((m) {
      if (m.itemNo == itemNo) {
        return m.copyWith(completedQuantity: completedQuantity);
      }
      return m;
    }).toList();
  }
}

/// 验证提交状态
class VerificationStatus {
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final DateTime? submittedAt;
  final String? submittedBy;

  const VerificationStatus({
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.submittedAt,
    this.submittedBy,
  });

  VerificationStatus copyWith({
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    DateTime? submittedAt,
    String? submittedBy,
  }) {
    return VerificationStatus(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
    );
  }
}