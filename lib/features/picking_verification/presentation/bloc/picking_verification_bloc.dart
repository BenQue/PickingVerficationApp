import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/picking_repository.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/entities/picking_order.dart';
import 'picking_verification_event.dart';
import 'picking_verification_state.dart';
import '../services/audit_trail_service.dart';
import '../utils/submission_validator.dart';
import '../utils/data_integrity_validator.dart';


/// 拣货校验BLoC
class PickingVerificationBloc extends Bloc<PickingVerificationEvent, PickingVerificationState> {
  final PickingRepository pickingRepository;

  PickingVerificationBloc({
    required this.pickingRepository,
  }) : super(PickingVerificationInitial()) {
    on<ActivatePickingVerificationEvent>(_onActivatePickingVerification);
    on<LoadPickingOrderEvent>(_onLoadPickingOrder);
    on<VerifyPickingItemEvent>(_onVerifyPickingItem);
    on<CompleteOrderVerificationEvent>(_onCompleteOrderVerification);
    on<ResetPickingVerificationEvent>(_onResetPickingVerification);
    on<NavigateBackToTasksEvent>(_onNavigateBackToTasks);
    // Scanning event handlers
    on<StartScanning>(_onStartScanning);
    on<ScanOrderCode>(_onScanOrderCode);
    on<EnterOrderManually>(_onEnterOrderManually);
    on<SwitchToManualInput>(_onSwitchToManualInput);
    on<LoadOrderDetails>(_onLoadOrderDetails);
    // Status management event handlers
    on<UpdateMaterialStatus>(_onUpdateMaterialStatus);
    on<ToggleCategorySection>(_onToggleCategorySection);
    on<ResetMaterialStatus>(_onResetMaterialStatus);
    on<PersistStatusChanges>(_onPersistStatusChanges);
    on<UndoStatusChange>(_onUndoStatusChange);
    on<RedoStatusChange>(_onRedoStatusChange);
    // Submission workflow event handlers
    on<SubmitVerificationEvent>(_onSubmitVerification);
    on<RetrySubmissionEvent>(_onRetrySubmission);
    on<ClearSubmissionDataEvent>(_onClearSubmissionData);
    on<CancelSubmissionEvent>(_onCancelSubmission);
    on<NavigateToCompletionEvent>(_onNavigateToCompletion);
  }

  Future<void> _onActivatePickingVerification(
    ActivatePickingVerificationEvent event,
    Emitter<PickingVerificationState> emit,
  ) async {
    emit(PickingVerificationLoading(message: '正在激活拣货校验模式...'));

    try {
      // 激活拣货校验模式
      final isActivated = await pickingRepository.activatePickingVerification(event.orderNumber);
      
      if (isActivated) {
        emit(PickingVerificationModeActivated(
          orderNumber: event.orderNumber,
          taskId: event.taskId,
          activatedAt: DateTime.now(),
        ));

        // 自动加载订单详情
        add(LoadPickingOrderEvent(orderNumber: event.orderNumber));
      } else {
        emit(PickingVerificationError(
          errorMessage: '激活拣货校验模式失败，请重试',
          orderNumber: event.orderNumber,
          taskId: event.taskId,
          errorType: PickingVerificationErrorType.activationFailed,
        ));
      }
    } catch (error) {
      emit(PickingVerificationError(
        errorMessage: _getErrorMessage(error),
        orderNumber: event.orderNumber,
        taskId: event.taskId,
        errorType: _getErrorType(error),
      ));
    }
  }

  Future<void> _onLoadPickingOrder(
    LoadPickingOrderEvent event,
    Emitter<PickingVerificationState> emit,
  ) async {
    emit(PickingVerificationLoading(message: '正在加载订单信息...'));

    try {
      final order = await pickingRepository.getPickingOrder(event.orderNumber);
      
      emit(PickingOrderLoaded(
        order: order,
        isModeActivated: true,
        taskId: _getTaskIdFromCurrentState(),
      ));
    } catch (error) {
      emit(PickingVerificationError(
        errorMessage: _getErrorMessage(error),
        orderNumber: event.orderNumber,
        taskId: _getTaskIdFromCurrentState(),
        errorType: _getErrorType(error),
      ));
    }
  }

  Future<void> _onVerifyPickingItem(
    VerifyPickingItemEvent event,
    Emitter<PickingVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PickingOrderLoaded) return;

    emit(PickingVerificationLoading(message: '正在验证拣货项目...'));

    try {
      final isVerified = await pickingRepository.verifyPickingItem(
        event.orderId,
        event.itemId,
        event.isVerified,
      );

      if (isVerified) {
        // 更新订单中的项目状态
        final updatedItems = currentState.order.items.map((item) {
          if (item.itemId == event.itemId) {
            return item.copyWith(isVerified: event.isVerified);
          }
          return item;
        }).toList();

        final updatedOrder = currentState.order.copyWith(items: updatedItems);

        emit(PickingItemVerified(
          updatedOrder: updatedOrder,
          verifiedItemId: event.itemId,
          isVerified: event.isVerified,
        ));

        // 返回到订单加载状态以显示更新后的数据
        emit(PickingOrderLoaded(
          order: updatedOrder,
          isModeActivated: currentState.isModeActivated,
          taskId: currentState.taskId,
        ));
      } else {
        emit(PickingVerificationError(
          errorMessage: '验证拣货项目失败，请重试',
          orderNumber: currentState.order.orderNumber,
          taskId: currentState.taskId,
          errorType: PickingVerificationErrorType.verificationFailed,
        ));
      }
    } catch (error) {
      emit(PickingVerificationError(
        errorMessage: _getErrorMessage(error),
        orderNumber: currentState.order.orderNumber,
        taskId: currentState.taskId,
        errorType: _getErrorType(error),
      ));
    }
  }

  Future<void> _onCompleteOrderVerification(
    CompleteOrderVerificationEvent event,
    Emitter<PickingVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PickingOrderLoaded) return;

    emit(PickingVerificationLoading(message: '正在完成订单校验...'));

    try {
      final isCompleted = await pickingRepository.completeOrderVerification(event.orderId);

      if (isCompleted) {
        final completedOrder = currentState.order.copyWith(
          status: 'completed',
          isVerified: true,
          verifiedAt: DateTime.now(),
        );

        emit(OrderVerificationCompleted(
          completedOrder: completedOrder,
          completedAt: DateTime.now(),
        ));
      } else {
        emit(PickingVerificationError(
          errorMessage: '完成订单校验失败，请重试',
          orderNumber: currentState.order.orderNumber,
          taskId: currentState.taskId,
          errorType: PickingVerificationErrorType.completionFailed,
        ));
      }
    } catch (error) {
      emit(PickingVerificationError(
        errorMessage: _getErrorMessage(error),
        orderNumber: currentState.order.orderNumber,
        taskId: currentState.taskId,
        errorType: _getErrorType(error),
      ));
    }
  }

  void _onResetPickingVerification(
    ResetPickingVerificationEvent event,
    Emitter<PickingVerificationState> emit,
  ) {
    emit(PickingVerificationInitial());
  }

  void _onNavigateBackToTasks(
    NavigateBackToTasksEvent event,
    Emitter<PickingVerificationState> emit,
  ) {
    emit(PickingVerificationNavigateBack());
  }

  String? _getTaskIdFromCurrentState() {
    if (state is PickingVerificationModeActivated) {
      return (state as PickingVerificationModeActivated).taskId;
    } else if (state is PickingOrderLoaded) {
      return (state as PickingOrderLoaded).taskId;
    } else if (state is PickingVerificationError) {
      return (state as PickingVerificationError).taskId;
    }
    return null;
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return '未知错误: $error';
  }

  PickingVerificationErrorType _getErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('网络') || errorString.contains('network')) {
      return PickingVerificationErrorType.networkError;
    } else if (errorString.contains('订单') && errorString.contains('不存在')) {
      return PickingVerificationErrorType.orderNotFound;
    } else if (errorString.contains('激活')) {
      return PickingVerificationErrorType.activationFailed;
    } else if (errorString.contains('验证')) {
      return PickingVerificationErrorType.verificationFailed;
    } else if (errorString.contains('完成')) {
      return PickingVerificationErrorType.completionFailed;
    } else if (errorString.contains('相机') || errorString.contains('camera')) {
      return PickingVerificationErrorType.cameraPermissionDenied;
    } else if (errorString.contains('扫描') || errorString.contains('scan')) {
      return PickingVerificationErrorType.scanningFailed;
    } else if (errorString.contains('无效') || errorString.contains('invalid')) {
      return PickingVerificationErrorType.invalidOrderNumber;
    } else {
      return PickingVerificationErrorType.unknownError;
    }
  }

  // Scanning event handlers
  void _onStartScanning(
    StartScanning event,
    Emitter<PickingVerificationState> emit,
  ) {
    emit(ScanningMode());
  }

  void _onSwitchToManualInput(
    SwitchToManualInput event,
    Emitter<PickingVerificationState> emit,
  ) {
    emit(ManualInputMode());
  }

  Future<void> _onScanOrderCode(
    ScanOrderCode event,
    Emitter<PickingVerificationState> emit,
  ) async {
    emit(OrderLookupLoading(orderNumber: event.orderCode));
    
    try {
      // Validate and extract order number from QR code
      final orderNumber = _extractOrderNumber(event.orderCode);
      if (orderNumber == null) {
        emit(PickingVerificationError(
          errorMessage: '无效的二维码格式',
          orderNumber: event.orderCode,
          errorType: PickingVerificationErrorType.invalidOrderNumber,
        ));
        return;
      }

      // Load order details
      final order = await pickingRepository.getOrderDetails(orderNumber);
      
      emit(OrderDetailsLoaded(
        order: order,
        isModeActivated: true,
      ));
    } catch (error) {
      emit(PickingVerificationError(
        errorMessage: _getErrorMessage(error),
        orderNumber: event.orderCode,
        errorType: _getErrorType(error),
      ));
    }
  }

  Future<void> _onEnterOrderManually(
    EnterOrderManually event,
    Emitter<PickingVerificationState> emit,
  ) async {
    emit(OrderLookupLoading(orderNumber: event.orderNumber));
    
    try {
      // Load order details
      final order = await pickingRepository.getOrderDetails(event.orderNumber);
      
      emit(OrderDetailsLoaded(
        order: order,
        isModeActivated: true,
      ));
    } catch (error) {
      emit(PickingVerificationError(
        errorMessage: _getErrorMessage(error),
        orderNumber: event.orderNumber,
        errorType: _getErrorType(error),
      ));
    }
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetails event,
    Emitter<PickingVerificationState> emit,
  ) async {
    emit(OrderLookupLoading(orderNumber: event.orderNumber));
    
    try {
      final order = await pickingRepository.getOrderDetails(event.orderNumber);
      
      emit(OrderDetailsLoaded(
        order: order,
        isModeActivated: true,
      ));
    } catch (error) {
      emit(PickingVerificationError(
        errorMessage: _getErrorMessage(error),
        orderNumber: event.orderNumber,
        errorType: _getErrorType(error),
      ));
    }
  }

  String? _extractOrderNumber(String qrCode) {
    // Basic validation: order number should match pattern
    // Adjust pattern based on actual business requirements
    final RegExp orderPattern = RegExp(r'^ORD\d{11}$|^\d{6,20}$');
    
    if (orderPattern.hasMatch(qrCode)) {
      return qrCode;
    }
    
    // Try to extract order number from a URL or formatted QR code
    final RegExp extractPattern = RegExp(r'order[_-]?(?:number|id|no)?[=:]?\s*([A-Z0-9]+)', caseSensitive: false);
    final match = extractPattern.firstMatch(qrCode);
    
    if (match != null && match.group(1) != null) {
      return match.group(1);
    }
    
    return null;
  }

  // Status Management Event Handlers

  Future<void> _onUpdateMaterialStatus(
    UpdateMaterialStatus event,
    Emitter<PickingVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrderDetailsLoaded) {
      try {
        // Find and update the material in the order
        final updatedMaterials = currentState.order.materials.map((material) {
          if (material.id == event.materialId) {
            return material.copyWith(status: event.newStatus);
          }
          return material;
        }).toList();

        final updatedOrder = currentState.order.copyWith(materials: updatedMaterials);
        
        // Track status change history
        final statusHistory = Map<String, MaterialStatus>.from(
          currentState.statusChangeHistory ?? {},
        );
        statusHistory[event.materialId] = event.newStatus;

        // Emit updated state
        emit(OrderDetailsLoaded(
          order: updatedOrder,
          isModeActivated: currentState.isModeActivated,
          categorySectionStates: currentState.categorySectionStates,
          statusChangeHistory: statusHistory,
        ));

        // Also emit a specific status updated event for UI feedback
        emit(MaterialStatusUpdated(
          order: updatedOrder,
          materialId: event.materialId,
          oldStatus: event.previousStatus ?? MaterialStatus.pending,
          newStatus: event.newStatus,
          updatedAt: DateTime.now(),
        ));

        // Return to the main state
        emit(OrderDetailsLoaded(
          order: updatedOrder,
          isModeActivated: currentState.isModeActivated,
          categorySectionStates: currentState.categorySectionStates,
          statusChangeHistory: statusHistory,
        ));
      } catch (e) {
        emit(StatusUpdateError(
          errorMessage: '更新物料状态失败: ${e.toString()}',
          materialId: event.materialId,
          order: currentState.order,
        ));
      }
    }
  }

  Future<void> _onToggleCategorySection(
    ToggleCategorySection event,
    Emitter<PickingVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrderDetailsLoaded) {
      final sectionStates = Map<MaterialCategory, bool>.from(
        currentState.categorySectionStates ?? {
          MaterialCategory.lineBreak: true,
          MaterialCategory.centralWarehouse: true,
          MaterialCategory.automated: true,
        },
      );
      
      // Toggle or set the section state
      if (event.isExpanded != null) {
        sectionStates[event.category] = event.isExpanded!;
      } else {
        sectionStates[event.category] = !(sectionStates[event.category] ?? true);
      }

      emit(CategorySectionToggled(
        order: currentState.order,
        category: event.category,
        isExpanded: sectionStates[event.category]!,
        allSectionStates: sectionStates,
      ));

      // Return to main state with updated section states
      emit(OrderDetailsLoaded(
        order: currentState.order,
        isModeActivated: currentState.isModeActivated,
        categorySectionStates: sectionStates,
        statusChangeHistory: currentState.statusChangeHistory,
      ));
    }
  }

  Future<void> _onResetMaterialStatus(
    ResetMaterialStatus event,
    Emitter<PickingVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrderDetailsLoaded) {
      List<MaterialItem>? updatedMaterials;
      
      if (event.materialId != null) {
        // Reset specific material
        updatedMaterials = currentState.order.materials.map((material) {
          if (material.id == event.materialId) {
            return material.copyWith(status: MaterialStatus.pending);
          }
          return material;
        }).toList();
      } else {
        // Reset all materials
        updatedMaterials = currentState.order.materials.map((material) {
          return material.copyWith(status: MaterialStatus.pending);
        }).toList();
      }

      final updatedOrder = currentState.order.copyWith(materials: updatedMaterials);
      
      // Clear status history if resetting all
      final statusHistory = event.materialId == null
          ? <String, MaterialStatus>{}
          : currentState.statusChangeHistory ?? {};

      emit(OrderDetailsLoaded(
        order: updatedOrder,
        isModeActivated: currentState.isModeActivated,
        categorySectionStates: currentState.categorySectionStates,
        statusChangeHistory: statusHistory,
      ));
    }
  }

  Future<void> _onPersistStatusChanges(
    PersistStatusChanges event,
    Emitter<PickingVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is OrderDetailsLoaded) {
      try {
        // TODO: Implement actual persistence to local storage in Story 3.4
        // For now, just emit a success state
        final changesCount = currentState.statusChangeHistory?.length ?? 0;
        
        emit(StatusChangesPersisted(
          order: currentState.order,
          changesCount: changesCount,
          persistedAt: DateTime.now(),
        ));

        // Return to main state
        emit(currentState);
      } catch (e) {
        emit(PickingVerificationError(
          errorMessage: '保存状态更改失败: ${e.toString()}',
          orderNumber: event.orderId,
          errorType: PickingVerificationErrorType.unknownError,
        ));
      }
    }
  }

  Future<void> _onUndoStatusChange(
    UndoStatusChange event,
    Emitter<PickingVerificationState> emit,
  ) async {
    // TODO: Implement undo functionality with history tracking
    // For now, this is a placeholder for Story 3.4
  }

  Future<void> _onRedoStatusChange(
    RedoStatusChange event,
    Emitter<PickingVerificationState> emit,
  ) async {
    // TODO: Implement redo functionality with history tracking
    // For now, this is a placeholder for Story 3.4
  }

  // Submission Workflow Event Handlers

  Future<void> _onSubmitVerification(
    SubmitVerificationEvent event,
    Emitter<PickingVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OrderDetailsLoaded) {
      emit(SubmissionError(
        order: _createEmptyOrder(event.orderId),
        errorMessage: '无法提交：订单数据未加载',
        errorType: SubmissionErrorType.validationError,
        occurredAt: DateTime.now(),
        canRetry: false,
      ));
      return;
    }

    final order = currentState.order;
    final submissionId = _generateSubmissionId();
    final auditService = AuditTrailService();
    final startTime = DateTime.now();

    try {
      // Step 1: Pre-submission validation
      emit(SubmissionInProgress(
        order: order,
        submissionId: submissionId,
        startedAt: startTime,
        currentStep: '验证数据完整性',
        progress: 0.1,
      ));

      // Validate submission requirements
      final validationResult = SubmissionValidator.validateOrderSubmission(order);
      if (!validationResult.isValid) {
        await auditService.logValidationError(
          orderId: event.orderId,
          orderNumber: order.orderNumber,
          order: order,
          validationErrors: validationResult.errors,
          operatorId: event.operatorId,
        );

        emit(SubmissionValidationError(
          order: order,
          validationErrors: validationResult.errors,
          occurredAt: DateTime.now(),
          validationDetails: {
            'categoryCompletionStatus': validationResult.categoryCompletionStatus,
            'completionPercentage': validationResult.completionPercentage,
          },
        ));
        return;
      }

      // Step 2: Data integrity check
      emit(SubmissionInProgress(
        order: order,
        submissionId: submissionId,
        startedAt: startTime,
        currentStep: '检查数据完整性',
        progress: 0.2,
      ));

      final integrityResult = DataIntegrityValidator.validateOrderDataIntegrity(order);
      if (!integrityResult.isValid) {
        final criticalIssues = integrityResult.issues
            .where((i) => i.severity == DataIntegrityIssueSeverity.critical)
            .map((i) => i.description)
            .toList();

        if (criticalIssues.isNotEmpty) {
          emit(SubmissionError(
            order: order,
            errorMessage: '数据完整性检查失败: ${criticalIssues.join(', ')}',
            errorType: SubmissionErrorType.dataIntegrityError,
            occurredAt: DateTime.now(),
            submissionId: submissionId,
            errorDetails: DataIntegrityValidator.getValidationSummary(integrityResult),
          ));
          return;
        }
      }

      // Step 3: Check duplicate submission protection
      if (!SubmissionGuard.canSubmit()) {
        emit(SubmissionError(
          order: order,
          errorMessage: '请稍候再试，提交间隔时间太短',
          errorType: SubmissionErrorType.duplicateSubmissionError,
          occurredAt: DateTime.now(),
          submissionId: submissionId,
          canRetry: true,
        ));
        return;
      }

      SubmissionGuard.startSubmission();

      // Log submission start
      await auditService.logSubmissionStarted(
        orderId: event.orderId,
        orderNumber: order.orderNumber,
        order: order,
        operatorId: event.operatorId,
        submissionId: submissionId,
        metadata: event.metadata,
      );

      // Step 4: Submit to API
      emit(SubmissionInProgress(
        order: order,
        submissionId: submissionId,
        startedAt: startTime,
        currentStep: '提交到服务器',
        progress: 0.6,
      ));

      final submissionResult = await pickingRepository.submitVerification(
        orderId: event.orderId,
        materials: order.materials,
        operatorId: event.operatorId,
        submissionId: submissionId,
        metadata: {
          ...?event.metadata,
          'submissionTimestamp': startTime.toIso8601String(),
          'materialSummary': _generateMaterialSummaryForSubmission(order),
        },
      );

      // Step 5: Process response
      emit(SubmissionInProgress(
        order: order,
        submissionId: submissionId,
        startedAt: startTime,
        currentStep: '处理服务器响应',
        progress: 0.9,
      ));

      SubmissionGuard.completeSubmission();
      final processingTime = DateTime.now().difference(startTime);

      // Log successful submission
      await auditService.logSubmissionCompleted(
        orderId: event.orderId,
        orderNumber: order.orderNumber,
        order: order,
        submissionId: submissionId,
        submissionResult: submissionResult,
        operatorId: event.operatorId,
        processingTime: processingTime,
      );

      // Clear local data after successful submission
      add(ClearSubmissionDataEvent(orderId: event.orderId));

      emit(SubmissionSuccess(
        order: order,
        submissionId: submissionId,
        completedAt: DateTime.now(),
        submissionResult: submissionResult,
        operatorId: event.operatorId,
      ));

    } catch (error) {
      SubmissionGuard.failSubmission();
      final processingTime = DateTime.now().difference(startTime);
      final errorType = _determineSubmissionErrorType(error);

      await auditService.logSubmissionFailed(
        orderId: event.orderId,
        orderNumber: order.orderNumber,
        order: order,
        errorMessage: error.toString(),
        errorType: errorType.name,
        submissionId: submissionId,
        operatorId: event.operatorId,
        errorDetails: {'exception': error.toString()},
        processingTime: processingTime,
      );

      emit(SubmissionError(
        order: order,
        errorMessage: _getSubmissionErrorMessage(error),
        errorType: errorType,
        occurredAt: DateTime.now(),
        submissionId: submissionId,
        errorDetails: {'exception': error.toString()},
      ));
    }
  }

  Future<void> _onRetrySubmission(
    RetrySubmissionEvent event,
    Emitter<PickingVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is SubmissionError) {
      if (!currentState.canRetry) {
        emit(SubmissionError(
          order: currentState.order,
          errorMessage: '该错误无法重试，请重新开始流程',
          errorType: currentState.errorType,
          occurredAt: DateTime.now(),
          canRetry: false,
        ));
        return;
      }

      // Log retry attempt
      if (currentState.submissionId != null) {
        final auditService = AuditTrailService();
        await auditService.logSubmissionRetried(
          orderId: event.orderId,
          orderNumber: currentState.order.orderNumber,
          order: currentState.order,
          originalSubmissionId: currentState.submissionId!,
          newSubmissionId: _generateSubmissionId(),
          operatorId: event.operatorId,
          retryReason: '用户手动重试',
        );
      }

      // Retry by triggering a new submission
      add(SubmitVerificationEvent(
        orderId: event.orderId,
        operatorId: event.operatorId,
        metadata: event.metadata,
      ));
    } else {
      emit(SubmissionError(
        order: _createEmptyOrder(event.orderId),
        errorMessage: '无法重试：当前状态不允许重试',
        errorType: SubmissionErrorType.validationError,
        occurredAt: DateTime.now(),
        canRetry: false,
      ));
    }
  }

  Future<void> _onClearSubmissionData(
    ClearSubmissionDataEvent event,
    Emitter<PickingVerificationState> emit,
  ) async {
    try {
      final auditService = AuditTrailService();
      
      // Clear local storage data (placeholder for actual implementation)
      final itemsCleared = await _clearLocalData(event.orderId);
      
      await auditService.logDataCleared(
        orderId: event.orderId,
        orderNumber: event.orderId, // Fallback if order number not available
        itemsCleared: itemsCleared,
        clearReason: '提交成功后自动清理',
      );

      emit(LocalDataCleared(
        orderId: event.orderId,
        clearedAt: DateTime.now(),
        itemsCleared: itemsCleared,
      ));
    } catch (error) {
      // Log error but don't fail the overall flow
      debugPrint('Error clearing local data: $error');
    }
  }

  Future<void> _onCancelSubmission(
    CancelSubmissionEvent event,
    Emitter<PickingVerificationState> emit,
  ) async {
    final currentState = state;
    
    if (currentState is SubmissionInProgress) {
      SubmissionGuard.reset();
      
      final auditService = AuditTrailService();
      await auditService.logSubmissionCancelled(
        orderId: event.orderId,
        orderNumber: currentState.order.orderNumber,
        order: currentState.order,
        submissionId: currentState.submissionId,
        cancelReason: '用户取消提交',
      );

      emit(SubmissionCancelled(
        order: currentState.order,
        cancelledAt: DateTime.now(),
        reason: '用户取消提交',
      ));
      
      // Return to order details state
      emit(OrderDetailsLoaded(
        order: currentState.order,
        isModeActivated: true,
      ));
    }
  }

  // Helper methods

  String _generateSubmissionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'SUB_${timestamp}_$random';
  }

  SubmissionErrorType _determineSubmissionErrorType(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('网络')) {
      return SubmissionErrorType.networkError;
    } else if (errorString.contains('timeout') || errorString.contains('超时')) {
      return SubmissionErrorType.timeoutError;
    } else if (errorString.contains('authentication') || errorString.contains('认证')) {
      return SubmissionErrorType.authenticationError;
    } else if (errorString.contains('permission') || errorString.contains('权限')) {
      return SubmissionErrorType.insufficientPermissionError;
    } else if (errorString.contains('server') || errorString.contains('服务器')) {
      return SubmissionErrorType.serverError;
    } else if (errorString.contains('maintenance') || errorString.contains('维护')) {
      return SubmissionErrorType.systemMaintenanceError;
    } else {
      return SubmissionErrorType.unknownError;
    }
  }

  String _getSubmissionErrorMessage(dynamic error) {
    final errorType = _determineSubmissionErrorType(error);
    
    switch (errorType) {
      case SubmissionErrorType.networkError:
        return '网络连接失败，请检查网络设置后重试';
      case SubmissionErrorType.timeoutError:
        return '请求超时，请稍后重试';
      case SubmissionErrorType.authenticationError:
        return '身份验证失败，请重新登录';
      case SubmissionErrorType.insufficientPermissionError:
        return '权限不足，请联系管理员';
      case SubmissionErrorType.serverError:
        return '服务器错误，请稍后重试';
      case SubmissionErrorType.systemMaintenanceError:
        return '系统正在维护，请稍后再试';
      default:
        return '提交失败: ${error.toString()}';
    }
  }

  Future<int> _clearLocalData(String orderId) async {
    // TODO: Implement actual local data clearing logic
    // This could include:
    // - Clearing SharedPreferences data
    // - Clearing local database entries
    // - Clearing cached files
    // - Resetting SubmissionGuard state
    
    SubmissionGuard.reset();
    return 1; // Placeholder return value
  }

  // Helper to create empty order for error states
  PickingOrder _createEmptyOrder(String orderId) {
    // This is a placeholder - in real implementation, you'd fetch from cache or create minimal order
    return PickingOrder(
      orderId: orderId,
      orderNumber: orderId,
      productionLineId: 'LINE_UNKNOWN',
      materials: [],
      status: 'error',
      createdAt: DateTime.now(),
      items: [],
      isVerified: false,
    );
  }

  // Helper to generate material summary for submission
  Map<String, dynamic> _generateMaterialSummaryForSubmission(PickingOrder order) {
    final summary = <String, dynamic>{};
    
    // 总体统计
    summary['totalMaterials'] = order.materials.length;
    
    // 按状态统计
    for (final status in MaterialStatus.values) {
      final count = order.materials.where((m) => m.status == status).length;
      summary['${status.name}Count'] = count;
    }
    
    // 按类别统计
    for (final category in MaterialCategory.values) {
      final categoryMaterials = order.materials.where((m) => m.category == category).toList();
      if (categoryMaterials.isNotEmpty) {
        summary['${category.name}Total'] = categoryMaterials.length;
        summary['${category.name}Completed'] = categoryMaterials
            .where((m) => m.status == MaterialStatus.completed)
            .length;
      }
    }
    
    // 计算完成率
    final completedCount = order.materials.where((m) => m.status == MaterialStatus.completed).length;
    summary['completionRate'] = order.materials.isNotEmpty 
        ? (completedCount / order.materials.length)
        : 0.0;
    
    return summary;
  }

  // Navigation Event Handler

  Future<void> _onNavigateToCompletion(
    NavigateToCompletionEvent event,
    Emitter<PickingVerificationState> emit,
  ) async {
    // This event is primarily handled by the UI layer
    // The BLoC just maintains state consistency
    emit(OrderVerificationCompleted(
      completedOrder: event.completedOrder,
      completedAt: DateTime.now(),
    ));
  }
}