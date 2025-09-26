import '../entities/verification_result.dart';

abstract class VerificationRepository {
  Future<VerificationResult> verifyOrder({
    required String scannedOrderId,
    required String expectedOrderId,
  });
}