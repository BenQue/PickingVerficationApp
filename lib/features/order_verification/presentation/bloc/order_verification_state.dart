import 'package:equatable/equatable.dart';
import '../../domain/entities/verification_result.dart';

abstract class OrderVerificationState extends Equatable {
  const OrderVerificationState();

  @override
  List<Object?> get props => [];
}

class VerificationInitial extends OrderVerificationState {}

class VerificationReady extends OrderVerificationState {
  final String taskId;
  final String expectedOrderId;

  const VerificationReady({
    required this.taskId,
    required this.expectedOrderId,
  });

  @override
  List<Object> get props => [taskId, expectedOrderId];
}

class VerificationLoading extends OrderVerificationState {
  final String scannedOrderId;

  const VerificationLoading({required this.scannedOrderId});

  @override
  List<Object> get props => [scannedOrderId];
}

class VerificationSuccess extends OrderVerificationState {
  final VerificationResult result;
  final String taskId;

  const VerificationSuccess({
    required this.result,
    required this.taskId,
  });

  @override
  List<Object> get props => [result, taskId];
}

class VerificationFailure extends OrderVerificationState {
  final String errorMessage;
  final String? scannedOrderId;
  final String expectedOrderId;
  final String taskId;

  const VerificationFailure({
    required this.errorMessage,
    this.scannedOrderId,
    required this.expectedOrderId,
    required this.taskId,
  });

  @override
  List<Object?> get props => [errorMessage, scannedOrderId, expectedOrderId, taskId];
}

class VerificationCancelled extends OrderVerificationState {}