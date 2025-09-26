import 'package:equatable/equatable.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/entities/picking_order.dart';

/// 拣货校验事件基类
abstract class PickingVerificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 激活拣货校验模式事件
class ActivatePickingVerificationEvent extends PickingVerificationEvent {
  final String orderNumber;
  final String? taskId;

  ActivatePickingVerificationEvent({
    required this.orderNumber,
    this.taskId,
  });

  @override
  List<Object?> get props => [orderNumber, taskId];
}

/// 加载拣货订单详情事件
class LoadPickingOrderEvent extends PickingVerificationEvent {
  final String orderNumber;

  LoadPickingOrderEvent({required this.orderNumber});

  @override
  List<Object?> get props => [orderNumber];
}

/// 验证拣货项目事件
class VerifyPickingItemEvent extends PickingVerificationEvent {
  final String orderId;
  final String itemId;
  final bool isVerified;

  VerifyPickingItemEvent({
    required this.orderId,
    required this.itemId,
    required this.isVerified,
  });

  @override
  List<Object?> get props => [orderId, itemId, isVerified];
}

/// 完成订单校验事件
class CompleteOrderVerificationEvent extends PickingVerificationEvent {
  final String orderId;

  CompleteOrderVerificationEvent({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

/// 重置状态事件
class ResetPickingVerificationEvent extends PickingVerificationEvent {}

/// 返回任务列表事件
class NavigateBackToTasksEvent extends PickingVerificationEvent {}

/// 开始扫描事件
class StartScanning extends PickingVerificationEvent {}

/// 扫描订单码事件
class ScanOrderCode extends PickingVerificationEvent {
  final String orderCode;

  ScanOrderCode({required this.orderCode});

  @override
  List<Object> get props => [orderCode];
}

/// 手动输入订单号事件
class EnterOrderManually extends PickingVerificationEvent {
  final String orderNumber;

  EnterOrderManually({required this.orderNumber});

  @override
  List<Object> get props => [orderNumber];
}

/// 切换到手动输入事件
class SwitchToManualInput extends PickingVerificationEvent {}

/// 加载订单详情事件
class LoadOrderDetails extends PickingVerificationEvent {
  final String orderNumber;

  LoadOrderDetails({required this.orderNumber});

  @override
  List<Object> get props => [orderNumber];
}

/// 更新物料状态事件
class UpdateMaterialStatus extends PickingVerificationEvent {
  final String materialId;
  final MaterialStatus newStatus;
  final MaterialStatus? previousStatus; // For undo functionality

  UpdateMaterialStatus({
    required this.materialId,
    required this.newStatus,
    this.previousStatus,
  });

  @override
  List<Object?> get props => [materialId, newStatus, previousStatus];
}

/// 切换分类区块展开/折叠事件
class ToggleCategorySection extends PickingVerificationEvent {
  final MaterialCategory category;
  final bool? isExpanded; // null means toggle current state

  ToggleCategorySection({
    required this.category,
    this.isExpanded,
  });

  @override
  List<Object?> get props => [category, isExpanded];
}

/// 重置物料状态事件
class ResetMaterialStatus extends PickingVerificationEvent {
  final String? materialId; // null means reset all materials
  
  ResetMaterialStatus({this.materialId});

  @override
  List<Object?> get props => [materialId];
}

/// 持久化状态更改事件
class PersistStatusChanges extends PickingVerificationEvent {
  final String orderId;

  PersistStatusChanges({required this.orderId});

  @override
  List<Object> get props => [orderId];
}

/// 撤销状态更改事件
class UndoStatusChange extends PickingVerificationEvent {
  final String materialId;

  UndoStatusChange({required this.materialId});

  @override
  List<Object> get props => [materialId];
}

/// 重做状态更改事件
class RedoStatusChange extends PickingVerificationEvent {
  final String materialId;

  RedoStatusChange({required this.materialId});

  @override
  List<Object> get props => [materialId];
}

/// 提交校验事件
class SubmitVerificationEvent extends PickingVerificationEvent {
  final String orderId;
  final String? operatorId;
  final Map<String, dynamic>? metadata;

  SubmitVerificationEvent({
    required this.orderId,
    this.operatorId,
    this.metadata,
  });

  @override
  List<Object?> get props => [orderId, operatorId, metadata];
}

/// 重试提交事件
class RetrySubmissionEvent extends PickingVerificationEvent {
  final String orderId;
  final String? operatorId;
  final Map<String, dynamic>? metadata;

  RetrySubmissionEvent({
    required this.orderId,
    this.operatorId,
    this.metadata,
  });

  @override
  List<Object?> get props => [orderId, operatorId, metadata];
}

/// 清除提交数据事件
class ClearSubmissionDataEvent extends PickingVerificationEvent {
  final String orderId;

  ClearSubmissionDataEvent({required this.orderId});

  @override
  List<Object> get props => [orderId];
}

/// 取消提交事件
class CancelSubmissionEvent extends PickingVerificationEvent {
  final String orderId;

  CancelSubmissionEvent({required this.orderId});

  @override
  List<Object> get props => [orderId];
}

/// 导航到完成页面事件
class NavigateToCompletionEvent extends PickingVerificationEvent {
  final PickingOrder completedOrder;
  final String? operatorId;

  NavigateToCompletionEvent({
    required this.completedOrder,
    this.operatorId,
  });

  @override
  List<Object?> get props => [completedOrder, operatorId];
}