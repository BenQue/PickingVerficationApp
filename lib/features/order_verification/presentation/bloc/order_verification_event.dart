import 'package:equatable/equatable.dart';

abstract class OrderVerificationEvent extends Equatable {
  const OrderVerificationEvent();

  @override
  List<Object> get props => [];
}

class StartVerificationEvent extends OrderVerificationEvent {
  final String taskId;
  final String expectedOrderId;

  const StartVerificationEvent({
    required this.taskId,
    required this.expectedOrderId,
  });

  @override
  List<Object> get props => [taskId, expectedOrderId];
}

class ScanQRCodeEvent extends OrderVerificationEvent {
  final String scannedOrderId;

  const ScanQRCodeEvent({required this.scannedOrderId});

  @override
  List<Object> get props => [scannedOrderId];
}

class VerifyManualInputEvent extends OrderVerificationEvent {
  final String inputOrderId;

  const VerifyManualInputEvent({required this.inputOrderId});

  @override
  List<Object> get props => [inputOrderId];
}

class ResetVerificationEvent extends OrderVerificationEvent {}

class CancelVerificationEvent extends OrderVerificationEvent {}