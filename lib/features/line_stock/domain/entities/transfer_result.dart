import 'package:equatable/equatable.dart';

/// Transfer Result Entity
/// Represents the result of a stock transfer operation
class TransferResult extends Equatable {
  final bool isSuccess;
  final String message;
  final String targetLocation;
  final int transferredCount;
  final DateTime timestamp;

  const TransferResult({
    required this.isSuccess,
    required this.message,
    required this.targetLocation,
    required this.transferredCount,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        isSuccess,
        message,
        targetLocation,
        transferredCount,
        timestamp,
      ];

  String get successMessage => '成功上架 $transferredCount 个电缆到 $targetLocation';
}
