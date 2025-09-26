import '../../domain/entities/verification_result.dart';
import '../../domain/repositories/verification_repository.dart';
import '../datasources/verification_remote_datasource.dart';
import '../models/verification_request_model.dart';

class VerificationRepositoryImpl implements VerificationRepository {
  final VerificationRemoteDataSource remoteDataSource;

  const VerificationRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<VerificationResult> verifyOrder({
    required String scannedOrderId,
    required String expectedOrderId,
  }) async {
    final request = VerificationRequestModel(
      scannedOrderId: scannedOrderId,
      expectedOrderId: expectedOrderId,
      taskId: '', // Will be passed from UI context
    );

    return await remoteDataSource.verifyOrder(request);
  }
}