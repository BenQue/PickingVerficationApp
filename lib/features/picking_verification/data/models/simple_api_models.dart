/// SimpleAPI 数据模型 - 匹配新的API结构
/// API Endpoint: /api/WorkOrderPickVerf
library;

/// 物料项简化模型
class SimpleMaterialItem {
  final String itemNo;
  final String materialCode;
  final String materialDesc;
  final int quantity;
  final int completedQuantity;

  SimpleMaterialItem({
    required this.itemNo,
    required this.materialCode,
    required this.materialDesc,
    required this.quantity,
    required this.completedQuantity,
  });

  factory SimpleMaterialItem.fromJson(Map<String, dynamic> json) {
    return SimpleMaterialItem(
      itemNo: json['itemNo'] as String,
      materialCode: json['materialCode'] as String,
      materialDesc: json['materialDesc'] as String,
      quantity: json['quantity'] as int,
      completedQuantity: json['completedQuantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemNo': itemNo,
      'materialCode': materialCode,
      'materialDesc': materialDesc,
      'quantity': quantity,
      'completedQuantity': completedQuantity,
    };
  }

  /// 检查物料是否已完成
  bool get isCompleted => completedQuantity >= quantity;

  /// 获取完成百分比
  double get completionPercentage {
    if (quantity == 0) return 0.0;
    return (completedQuantity / quantity).clamp(0.0, 1.0);
  }
}

/// 工单拣货验证响应模型
class WorkOrderPickVerfResponse {
  final bool isSuccess;
  final String message;
  final WorkOrderData? data;

  WorkOrderPickVerfResponse({
    required this.isSuccess,
    required this.message,
    this.data,
  });

  factory WorkOrderPickVerfResponse.fromJson(Map<String, dynamic> json) {
    return WorkOrderPickVerfResponse(
      isSuccess: json['isSuccess'] as bool,
      message: json['message'] as String,
      data: json['data'] != null 
          ? WorkOrderData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 工单数据模型
class WorkOrderData {
  final int orderId;
  final String orderNo;
  final String operationNo;
  final String operationStatus;
  final int cableItemCount;
  final int rawItemCount;
  final int labelCount;
  
  // 三种物料类别
  final List<SimpleMaterialItem> cabelItems;      // 断线物料
  final List<SimpleMaterialItem> centerStockItems; // 中央仓库物料
  final List<SimpleMaterialItem> autoStockItems;   // 自动化仓库物料

  WorkOrderData({
    required this.orderId,
    required this.orderNo,
    required this.operationNo,
    required this.operationStatus,
    required this.cableItemCount,
    required this.rawItemCount,
    required this.labelCount,
    required this.cabelItems,
    required this.centerStockItems,
    required this.autoStockItems,
  });

  factory WorkOrderData.fromJson(Map<String, dynamic> json) {
    return WorkOrderData(
      orderId: json['orderId'] as int,
      orderNo: json['orderNo'] as String,
      operationNo: json['operationNo'] as String,
      operationStatus: json['operationStatus'] as String,
      cableItemCount: json['cableItemCount'] as int,
      rawItemCount: json['rawItemCount'] as int,
      labelCount: json['labelCount'] as int,
      cabelItems: (json['cabelItems'] as List<dynamic>? ?? [])
          .map((item) => SimpleMaterialItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      centerStockItems: (json['centerStockItems'] as List<dynamic>? ?? [])
          .map((item) => SimpleMaterialItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      autoStockItems: (json['autoStockItems'] as List<dynamic>? ?? [])
          .map((item) => SimpleMaterialItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// 获取所有物料项
  List<SimpleMaterialItem> get allItems {
    return [...cabelItems, ...centerStockItems, ...autoStockItems];
  }

  /// 获取总物料数量
  int get totalItemCount => allItems.length;

  /// 获取已完成的物料数量
  int get completedItemCount {
    return allItems.where((item) => item.isCompleted).length;
  }

  /// 获取总体完成百分比
  double get overallCompletionPercentage {
    if (totalItemCount == 0) return 0.0;
    return completedItemCount / totalItemCount;
  }

  /// 检查所有物料是否已完成
  bool get isAllCompleted => completedItemCount == totalItemCount;

  /// 按类别获取完成状态
  Map<String, bool> get categoryCompletionStatus {
    return {
      '断线物料': cabelItems.every((item) => item.isCompleted),
      '中央仓库物料': centerStockItems.every((item) => item.isCompleted),
      '自动化仓库物料': autoStockItems.every((item) => item.isCompleted),
    };
  }
}

/// 工单状态更新请求模型 (PUT方法)
class WorkOrderStatusUpdateRequest {
  final int workOrderId;
  final String operation;
  final String status;
  final String workCenter;
  final DateTime updateOn;
  final String updateBy;

  WorkOrderStatusUpdateRequest({
    required this.workOrderId,
    required this.operation,
    required this.status,
    required this.workCenter,
    required this.updateOn,
    required this.updateBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'workOrderId': workOrderId,
      'operation': operation,
      'status': status,
      'workCenter': workCenter,
      'updateOn': updateOn.toIso8601String(),
      'updateBy': updateBy,
    };
  }
}

/// 工单状态更新响应模型
class WorkOrderStatusUpdateResponse {
  final bool isSuccess;
  final String message;
  final bool data;

  WorkOrderStatusUpdateResponse({
    required this.isSuccess,
    required this.message,
    required this.data,
  });

  factory WorkOrderStatusUpdateResponse.fromJson(Map<String, dynamic> json) {
    return WorkOrderStatusUpdateResponse(
      isSuccess: json['isSuccess'] as bool,
      message: json['message'] as String,
      data: json['data'] as bool,
    );
  }
}