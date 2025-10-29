import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/simple_picking_entities.dart';
import '../../domain/repositories/simple_picking_repository.dart';

// Events
abstract class SimplePickingEvent extends Equatable {
  const SimplePickingEvent();

  @override
  List<Object?> get props => [];
}

/// 加载工单详情事件
class LoadWorkOrder extends SimplePickingEvent {
  final String orderNo;

  const LoadWorkOrder(this.orderNo);

  @override
  List<Object?> get props => [orderNo];
}

/// 更新物料完成数量事件
class UpdateMaterialQuantity extends SimplePickingEvent {
  final String itemNo;
  final int completedQuantity;

  const UpdateMaterialQuantity({
    required this.itemNo,
    required this.completedQuantity,
  });

  @override
  List<Object?> get props => [itemNo, completedQuantity];
}

/// 提交验证事件
class SubmitVerification extends SimplePickingEvent {
  final String updateBy;
  final String workCenter;

  const SubmitVerification({
    required this.updateBy,
    required this.workCenter,
  });

  @override
  List<Object?> get props => [updateBy, workCenter];
}

/// 重置状态事件
class ResetPickingState extends SimplePickingEvent {}

// States
abstract class SimplePickingState extends Equatable {
  const SimplePickingState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class SimplePickingInitial extends SimplePickingState {}

/// 加载中状态
class SimplePickingLoading extends SimplePickingState {}

/// 工单已加载状态
class SimplePickingLoaded extends SimplePickingState {
  final SimpleWorkOrder workOrder;
  final bool isModified; // 是否有未保存的修改

  const SimplePickingLoaded({
    required this.workOrder,
    this.isModified = false,
  });

  @override
  List<Object?> get props => [workOrder, isModified];

  SimplePickingLoaded copyWith({
    SimpleWorkOrder? workOrder,
    bool? isModified,
  }) {
    return SimplePickingLoaded(
      workOrder: workOrder ?? this.workOrder,
      isModified: isModified ?? this.isModified,
    );
  }
}

/// 提交中状态
class SimplePickingSubmitting extends SimplePickingState {
  final SimpleWorkOrder workOrder;

  const SimplePickingSubmitting(this.workOrder);

  @override
  List<Object?> get props => [workOrder];
}

/// 提交成功状态
class SimplePickingSubmitted extends SimplePickingState {
  final SimpleWorkOrder workOrder;
  final String message;

  const SimplePickingSubmitted({
    required this.workOrder,
    required this.message,
  });

  @override
  List<Object?> get props => [workOrder, message];
}

/// 错误状态
class SimplePickingError extends SimplePickingState {
  final String message;
  final SimpleWorkOrder? lastWorkOrder; // 保留最后的工单数据

  const SimplePickingError({
    required this.message,
    this.lastWorkOrder,
  });

  @override
  List<Object?> get props => [message, lastWorkOrder];
}

// BLoC
class SimplePickingBloc extends Bloc<SimplePickingEvent, SimplePickingState> {
  final SimplePickingRepository repository;
  String? _currentOrderNo; // 当前工单号

  SimplePickingBloc({required this.repository}) : super(SimplePickingInitial()) {
    on<LoadWorkOrder>(_onLoadWorkOrder);
    on<UpdateMaterialQuantity>(_onUpdateMaterialQuantity);
    on<SubmitVerification>(_onSubmitVerification);
    on<ResetPickingState>(_onResetPickingState);
  }

  /// 处理加载工单事件
  Future<void> _onLoadWorkOrder(
    LoadWorkOrder event,
    Emitter<SimplePickingState> emit,
  ) async {
    emit(SimplePickingLoading());
    
    try {
      _currentOrderNo = event.orderNo;
      final workOrder = await repository.getWorkOrderDetails(event.orderNo);

      emit(SimplePickingLoaded(
        workOrder: workOrder,
        isModified: false,
      ));
    } catch (e) {
      // 提取纯错误消息,去掉"Exception: "前缀
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }

      emit(SimplePickingError(
        message: errorMessage,
      ));
    }
  }

  /// 处理更新物料数量事件
  Future<void> _onUpdateMaterialQuantity(
    UpdateMaterialQuantity event,
    Emitter<SimplePickingState> emit,
  ) async {
    if (state is SimplePickingLoaded && _currentOrderNo != null) {
      final currentState = state as SimplePickingLoaded;
      
      try {
        // 更新本地状态
        await repository.updateMaterialQuantity(
          orderNo: _currentOrderNo!,
          itemNo: event.itemNo,
          completedQuantity: event.completedQuantity,
        );
        
        // 更新工单数据
        final updatedOrder = currentState.workOrder.updateMaterialQuantity(
          event.itemNo,
          event.completedQuantity,
        );
        
        emit(currentState.copyWith(
          workOrder: updatedOrder,
          isModified: true, // 标记为已修改
        ));
      } catch (e) {
        emit(SimplePickingError(
          message: '更新物料数量失败: ${e.toString()}',
          lastWorkOrder: currentState.workOrder,
        ));
      }
    }
  }

  /// 处理提交验证事件
  Future<void> _onSubmitVerification(
    SubmitVerification event,
    Emitter<SimplePickingState> emit,
  ) async {
    if (state is SimplePickingLoaded && _currentOrderNo != null) {
      final currentState = state as SimplePickingLoaded;
      final workOrder = currentState.workOrder;
      
      // 检查是否所有物料都已完成
      if (!workOrder.isAllCompleted) {
        emit(SimplePickingError(
          message: '还有未完成的物料，请完成所有物料后再提交',
          lastWorkOrder: workOrder,
        ));
        
        // 恢复到加载状态
        await Future.delayed(const Duration(seconds: 2));
        emit(currentState);
        return;
      }
      
      emit(SimplePickingSubmitting(workOrder));

      try {
        final success = await repository.submitVerification(
          workOrderId: workOrder.orderId,
          orderNo: workOrder.orderNo,
          operation: workOrder.operationNo,
          status: 'verfSuccess', // 校验成功状态
          workCenter: event.workCenter,
          updateBy: event.updateBy,
        );
        
        if (success) {
          emit(SimplePickingSubmitted(
            workOrder: workOrder,
            message: '验证提交成功！',
          ));
        } else {
          emit(SimplePickingError(
            message: '提交失败，请重试',
            lastWorkOrder: workOrder,
          ));
          
          // 恢复到加载状态
          await Future.delayed(const Duration(seconds: 2));
          emit(currentState);
        }
      } catch (e) {
        emit(SimplePickingError(
          message: '提交验证失败: ${e.toString()}',
          lastWorkOrder: workOrder,
        ));
        
        // 恢复到加载状态
        await Future.delayed(const Duration(seconds: 2));
        emit(currentState);
      }
    }
  }

  /// 处理重置状态事件
  Future<void> _onResetPickingState(
    ResetPickingState event,
    Emitter<SimplePickingState> emit,
  ) async {
    _currentOrderNo = null;
    emit(SimplePickingInitial());
  }

  /// 获取当前工单号
  String? get currentOrderNo => _currentOrderNo;

  /// 检查是否有未保存的修改
  bool get hasUnsavedChanges {
    final currentState = state;
    return currentState is SimplePickingLoaded && currentState.isModified;
  }
}