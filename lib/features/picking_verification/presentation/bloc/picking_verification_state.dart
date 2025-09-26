import 'package:equatable/equatable.dart';
import '../../domain/entities/picking_order.dart';
import '../../domain/entities/material_item.dart';

/// 拣货校验状态基类
abstract class PickingVerificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// 初始状态
class PickingVerificationInitial extends PickingVerificationState {}

/// 加载中状态
class PickingVerificationLoading extends PickingVerificationState {
  final String? message;

  PickingVerificationLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// 模式激活成功状态
class PickingVerificationModeActivated extends PickingVerificationState {
  final String orderNumber;
  final String? taskId;
  final DateTime activatedAt;

  PickingVerificationModeActivated({
    required this.orderNumber,
    this.taskId,
    required this.activatedAt,
  });

  @override
  List<Object?> get props => [orderNumber, taskId, activatedAt];
}

/// 订单加载成功状态
class PickingOrderLoaded extends PickingVerificationState {
  final PickingOrder order;
  final bool isModeActivated;
  final String? taskId;

  PickingOrderLoaded({
    required this.order,
    required this.isModeActivated,
    this.taskId,
  });

  @override
  List<Object?> get props => [order, isModeActivated, taskId];
}

/// 项目验证成功状态
class PickingItemVerified extends PickingVerificationState {
  final PickingOrder updatedOrder;
  final String verifiedItemId;
  final bool isVerified;

  PickingItemVerified({
    required this.updatedOrder,
    required this.verifiedItemId,
    required this.isVerified,
  });

  @override
  List<Object?> get props => [updatedOrder, verifiedItemId, isVerified];
}

/// 订单校验完成状态
class OrderVerificationCompleted extends PickingVerificationState {
  final PickingOrder completedOrder;
  final DateTime completedAt;

  OrderVerificationCompleted({
    required this.completedOrder,
    required this.completedAt,
  });

  @override
  List<Object?> get props => [completedOrder, completedAt];
}

/// 错误状态
class PickingVerificationError extends PickingVerificationState {
  final String errorMessage;
  final String? orderNumber;
  final String? taskId;
  final PickingVerificationErrorType errorType;

  PickingVerificationError({
    required this.errorMessage,
    this.orderNumber,
    this.taskId,
    required this.errorType,
  });

  @override
  List<Object?> get props => [errorMessage, orderNumber, taskId, errorType];
}

/// 导航返回状态
class PickingVerificationNavigateBack extends PickingVerificationState {}

/// 错误类型枚举
enum PickingVerificationErrorType {
  networkError,
  orderNotFound,
  activationFailed,
  verificationFailed,
  completionFailed,
  unknownError,
  cameraPermissionDenied,
  scanningFailed,
  invalidOrderNumber,
}

/// 扫描模式状态
class ScanningMode extends PickingVerificationState {
  final String? lastScannedCode;
  
  ScanningMode({this.lastScannedCode});
  
  @override
  List<Object?> get props => [lastScannedCode];
}

/// 手动输入模式状态
class ManualInputMode extends PickingVerificationState {}

/// 订单查找中状态
class OrderLookupLoading extends PickingVerificationState {
  final String orderNumber;
  
  OrderLookupLoading({required this.orderNumber});
  
  @override
  List<Object> get props => [orderNumber];
}

/// 订单详情加载成功状态
class OrderDetailsLoaded extends PickingVerificationState {
  final PickingOrder order;
  final bool isModeActivated;
  final Map<MaterialCategory, bool>? categorySectionStates; // Track expanded states
  final Map<String, MaterialStatus>? statusChangeHistory; // Track status changes
  
  OrderDetailsLoaded({
    required this.order,
    this.isModeActivated = true,
    this.categorySectionStates,
    this.statusChangeHistory,
  });
  
  OrderDetailsLoaded copyWith({
    PickingOrder? order,
    bool? isModeActivated,
    Map<MaterialCategory, bool>? categorySectionStates,
    Map<String, MaterialStatus>? statusChangeHistory,
  }) {
    return OrderDetailsLoaded(
      order: order ?? this.order,
      isModeActivated: isModeActivated ?? this.isModeActivated,
      categorySectionStates: categorySectionStates ?? this.categorySectionStates,
      statusChangeHistory: statusChangeHistory ?? this.statusChangeHistory,
    );
  }
  
  @override
  List<Object?> get props => [order, isModeActivated, categorySectionStates, statusChangeHistory];
}

/// 物料状态已更新状态
class MaterialStatusUpdated extends PickingVerificationState {
  final PickingOrder order;
  final String materialId;
  final MaterialStatus oldStatus;
  final MaterialStatus newStatus;
  final DateTime updatedAt;
  
  MaterialStatusUpdated({
    required this.order,
    required this.materialId,
    required this.oldStatus,
    required this.newStatus,
    required this.updatedAt,
  });
  
  @override
  List<Object> get props => [order, materialId, oldStatus, newStatus, updatedAt];
}

/// 分类区块切换状态
class CategorySectionToggled extends PickingVerificationState {
  final PickingOrder order;
  final MaterialCategory category;
  final bool isExpanded;
  final Map<MaterialCategory, bool> allSectionStates;
  
  CategorySectionToggled({
    required this.order,
    required this.category,
    required this.isExpanded,
    required this.allSectionStates,
  });
  
  @override
  List<Object> get props => [order, category, isExpanded, allSectionStates];
}

/// 状态更新错误状态
class StatusUpdateError extends PickingVerificationState {
  final String errorMessage;
  final String materialId;
  final PickingOrder order;
  
  StatusUpdateError({
    required this.errorMessage,
    required this.materialId,
    required this.order,
  });
  
  @override
  List<Object> get props => [errorMessage, materialId, order];
}

/// 状态变更已持久化状态
class StatusChangesPersisted extends PickingVerificationState {
  final PickingOrder order;
  final int changesCount;
  final DateTime persistedAt;
  
  StatusChangesPersisted({
    required this.order,
    required this.changesCount,
    required this.persistedAt,
  });
  
  @override
  List<Object> get props => [order, changesCount, persistedAt];
}

/// 提交校验进行中状态
class SubmissionInProgress extends PickingVerificationState {
  final PickingOrder order;
  final String submissionId;
  final DateTime startedAt;
  final String? currentStep;
  final double? progress;
  
  SubmissionInProgress({
    required this.order,
    required this.submissionId,
    required this.startedAt,
    this.currentStep,
    this.progress,
  });
  
  SubmissionInProgress copyWith({
    PickingOrder? order,
    String? submissionId,
    DateTime? startedAt,
    String? currentStep,
    double? progress,
  }) {
    return SubmissionInProgress(
      order: order ?? this.order,
      submissionId: submissionId ?? this.submissionId,
      startedAt: startedAt ?? this.startedAt,
      currentStep: currentStep ?? this.currentStep,
      progress: progress ?? this.progress,
    );
  }
  
  @override
  List<Object?> get props => [order, submissionId, startedAt, currentStep, progress];
}

/// 提交成功状态
class SubmissionSuccess extends PickingVerificationState {
  final PickingOrder order;
  final String submissionId;
  final DateTime completedAt;
  final Map<String, dynamic> submissionResult;
  final String? operatorId;
  
  SubmissionSuccess({
    required this.order,
    required this.submissionId,
    required this.completedAt,
    required this.submissionResult,
    this.operatorId,
  });
  
  @override
  List<Object?> get props => [order, submissionId, completedAt, submissionResult, operatorId];
}

/// 提交错误状态
class SubmissionError extends PickingVerificationState {
  final PickingOrder order;
  final String errorMessage;
  final SubmissionErrorType errorType;
  final DateTime occurredAt;
  final String? submissionId;
  final Map<String, dynamic>? errorDetails;
  final bool canRetry;
  
  SubmissionError({
    required this.order,
    required this.errorMessage,
    required this.errorType,
    required this.occurredAt,
    this.submissionId,
    this.errorDetails,
    this.canRetry = true,
  });
  
  @override
  List<Object?> get props => [order, errorMessage, errorType, occurredAt, submissionId, errorDetails, canRetry];
}

/// 提交验证错误状态
class SubmissionValidationError extends PickingVerificationState {
  final PickingOrder order;
  final List<String> validationErrors;
  final DateTime occurredAt;
  final Map<String, dynamic>? validationDetails;
  
  SubmissionValidationError({
    required this.order,
    required this.validationErrors,
    required this.occurredAt,
    this.validationDetails,
  });
  
  @override
  List<Object?> get props => [order, validationErrors, occurredAt, validationDetails];
}

/// 提交已取消状态
class SubmissionCancelled extends PickingVerificationState {
  final PickingOrder order;
  final DateTime cancelledAt;
  final String? reason;
  
  SubmissionCancelled({
    required this.order,
    required this.cancelledAt,
    this.reason,
  });
  
  @override
  List<Object?> get props => [order, cancelledAt, reason];
}

/// 本地数据已清除状态
class LocalDataCleared extends PickingVerificationState {
  final String orderId;
  final DateTime clearedAt;
  final int itemsCleared;
  
  LocalDataCleared({
    required this.orderId,
    required this.clearedAt,
    required this.itemsCleared,
  });
  
  @override
  List<Object> get props => [orderId, clearedAt, itemsCleared];
}

/// 提交错误类型枚举
enum SubmissionErrorType {
  networkError('网络错误'),
  serverError('服务器错误'),
  authenticationError('认证错误'),
  validationError('验证错误'),
  timeoutError('超时错误'),
  dataIntegrityError('数据完整性错误'),
  duplicateSubmissionError('重复提交错误'),
  insufficientPermissionError('权限不足错误'),
  systemMaintenanceError('系统维护错误'),
  unknownError('未知错误');

  final String label;
  const SubmissionErrorType(this.label);
}