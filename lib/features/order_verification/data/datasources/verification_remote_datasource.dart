import '../../domain/entities/verification_result.dart';
import '../models/verification_request_model.dart';

abstract class VerificationRemoteDataSource {
  Future<VerificationResult> verifyOrder(VerificationRequestModel request);
}

class VerificationRemoteDataSourceImpl implements VerificationRemoteDataSource {
  @override
  Future<VerificationResult> verifyOrder(VerificationRequestModel request) async {
    try {
      // 首先尝试使用真实的验证API
      // 这里我们使用扫描验证端点
      await Future.delayed(const Duration(milliseconds: 500)); // 模拟网络延迟
      
      // 检查订单是否存在并且有效
      // 在真实环境中，这将调用 /api/v1/verification/scan 端点
      final isValid = await _validateOrderExists(request.scannedOrderId);
      final orderMatches = request.scannedOrderId == request.expectedOrderId;
      
      if (isValid && orderMatches) {
        return VerificationResult(
          orderId: request.scannedOrderId,
          isValid: true,
          errorMessage: null,
          verifiedAt: DateTime.now(),
        );
      } else if (!orderMatches) {
        return VerificationResult(
          orderId: request.scannedOrderId,
          isValid: false,
          errorMessage: '订单号不匹配，请重新扫描',
          verifiedAt: DateTime.now(),
        );
      } else {
        return VerificationResult(
          orderId: request.scannedOrderId,
          isValid: false,
          errorMessage: '订单不存在或无效',
          verifiedAt: DateTime.now(),
        );
      }
    } catch (e) {
      // 如果API调用失败，回退到本地验证逻辑
      final isValid = request.scannedOrderId == request.expectedOrderId;
      
      return VerificationResult(
        orderId: request.scannedOrderId,
        isValid: isValid,
        errorMessage: isValid ? null : '订单号不匹配，请重新扫描',
        verifiedAt: DateTime.now(),
      );
    }
  }
  
  /// 验证订单是否存在
  Future<bool> _validateOrderExists(String orderId) async {
    try {
      // 这里应该调用真实的API来检查订单是否存在
      // 比如: GET /api/v1/orders/{orderId}
      // 目前使用简单的逻辑作为占位符
      
      // 模拟一些有效的订单ID
      final validOrderIds = [
        'ORD2024001', 'ORD2024002', 'ORD2024003',
        'PO-20241206-001', 'PO-20241206-002', 'PO-20241206-003',
        'PO-20241206-101', 'PO-20241206-102',
        'PO-20241206-DEFAULT',
      ];
      
      return validOrderIds.contains(orderId);
    } catch (e) {
      // 如果验证失败，假设订单无效
      return false;
    }
  }
}