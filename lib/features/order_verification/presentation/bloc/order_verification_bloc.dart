import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/verification_repository.dart';
import 'order_verification_event.dart';
import 'order_verification_state.dart';

class OrderVerificationBloc extends Bloc<OrderVerificationEvent, OrderVerificationState> {
  final VerificationRepository verificationRepository;

  OrderVerificationBloc({
    required this.verificationRepository,
  }) : super(VerificationInitial()) {
    on<StartVerificationEvent>(_onStartVerification);
    on<ScanQRCodeEvent>(_onScanQRCode);
    on<VerifyManualInputEvent>(_onVerifyManualInput);
    on<ResetVerificationEvent>(_onResetVerification);
    on<CancelVerificationEvent>(_onCancelVerification);
  }

  void _onStartVerification(
    StartVerificationEvent event,
    Emitter<OrderVerificationState> emit,
  ) {
    emit(VerificationReady(
      taskId: event.taskId,
      expectedOrderId: event.expectedOrderId,
    ));
  }

  Future<void> _onScanQRCode(
    ScanQRCodeEvent event,
    Emitter<OrderVerificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! VerificationReady) return;

    emit(VerificationLoading(scannedOrderId: event.scannedOrderId));

    try {
      final result = await verificationRepository.verifyOrder(
        scannedOrderId: event.scannedOrderId,
        expectedOrderId: currentState.expectedOrderId,
      );

      if (result.isValid) {
        emit(VerificationSuccess(
          result: result,
          taskId: currentState.taskId,
        ));
      } else {
        emit(VerificationFailure(
          errorMessage: result.errorMessage ?? '验证失败',
          scannedOrderId: event.scannedOrderId,
          expectedOrderId: currentState.expectedOrderId,
          taskId: currentState.taskId,
        ));
      }
    } catch (error) {
      emit(VerificationFailure(
        errorMessage: '验证过程中出现错误：${error.toString()}',
        scannedOrderId: event.scannedOrderId,
        expectedOrderId: currentState.expectedOrderId,
        taskId: currentState.taskId,
      ));
    }
  }

  Future<void> _onVerifyManualInput(
    VerifyManualInputEvent event,
    Emitter<OrderVerificationState> emit,
  ) async {
    final currentState = state;
    String expectedOrderId;
    String taskId;

    if (currentState is VerificationReady) {
      expectedOrderId = currentState.expectedOrderId;
      taskId = currentState.taskId;
    } else if (currentState is VerificationFailure) {
      expectedOrderId = currentState.expectedOrderId;
      taskId = currentState.taskId;
    } else {
      return;
    }

    emit(VerificationLoading(scannedOrderId: event.inputOrderId));

    try {
      final result = await verificationRepository.verifyOrder(
        scannedOrderId: event.inputOrderId,
        expectedOrderId: expectedOrderId,
      );

      if (result.isValid) {
        emit(VerificationSuccess(
          result: result,
          taskId: taskId,
        ));
      } else {
        emit(VerificationFailure(
          errorMessage: result.errorMessage ?? '手动输入验证失败',
          scannedOrderId: event.inputOrderId,
          expectedOrderId: expectedOrderId,
          taskId: taskId,
        ));
      }
    } catch (error) {
      emit(VerificationFailure(
        errorMessage: '验证过程中出现错误：${error.toString()}',
        scannedOrderId: event.inputOrderId,
        expectedOrderId: expectedOrderId,
        taskId: taskId,
      ));
    }
  }

  void _onResetVerification(
    ResetVerificationEvent event,
    Emitter<OrderVerificationState> emit,
  ) {
    final currentState = state;
    if (currentState is VerificationFailure) {
      emit(VerificationReady(
        taskId: currentState.taskId,
        expectedOrderId: currentState.expectedOrderId,
      ));
    }
  }

  void _onCancelVerification(
    CancelVerificationEvent event,
    Emitter<OrderVerificationState> emit,
  ) {
    emit(VerificationCancelled());
  }
}