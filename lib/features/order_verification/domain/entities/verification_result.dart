class VerificationResult {
  final String orderId;
  final bool isValid;
  final String? errorMessage;
  final DateTime verifiedAt;

  const VerificationResult({
    required this.orderId,
    required this.isValid,
    this.errorMessage,
    required this.verifiedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VerificationResult &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          isValid == other.isValid &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => 
      orderId.hashCode ^ isValid.hashCode ^ errorMessage.hashCode;

  @override
  String toString() {
    return 'VerificationResult{orderId: $orderId, isValid: $isValid, errorMessage: $errorMessage, verifiedAt: $verifiedAt}';
  }
}