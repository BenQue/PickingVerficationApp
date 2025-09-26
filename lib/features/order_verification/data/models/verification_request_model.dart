class VerificationRequestModel {
  final String scannedOrderId;
  final String expectedOrderId;
  final String taskId;

  const VerificationRequestModel({
    required this.scannedOrderId,
    required this.expectedOrderId,
    required this.taskId,
  });

  Map<String, dynamic> toJson() {
    return {
      'scannedOrderId': scannedOrderId,
      'expectedOrderId': expectedOrderId,
      'taskId': taskId,
    };
  }

  factory VerificationRequestModel.fromJson(Map<String, dynamic> json) {
    return VerificationRequestModel(
      scannedOrderId: json['scannedOrderId'] as String,
      expectedOrderId: json['expectedOrderId'] as String,
      taskId: json['taskId'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationRequestModel &&
          runtimeType == other.runtimeType &&
          scannedOrderId == other.scannedOrderId &&
          expectedOrderId == other.expectedOrderId &&
          taskId == other.taskId;

  @override
  int get hashCode => scannedOrderId.hashCode ^ expectedOrderId.hashCode ^ taskId.hashCode;
}