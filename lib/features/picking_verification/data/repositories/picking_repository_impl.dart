import '../../domain/entities/picking_order.dart';
import '../../domain/entities/material_item.dart';
import '../../domain/repositories/picking_repository.dart';
import '../datasources/picking_remote_datasource.dart';
import '../models/submission_models.dart';

/// 拣货校验仓储实现
class PickingRepositoryImpl implements PickingRepository {
  final PickingRemoteDataSource remoteDataSource;

  PickingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PickingOrder> getPickingOrder(String orderNumber) async {
    try {
      final orderModel = await remoteDataSource.getPickingOrder(orderNumber);
      return orderModel;
    } catch (e) {
      throw Exception('获取拣货订单失败: $e');
    }
  }

  @override
  Future<bool> activatePickingVerification(String orderNumber) async {
    try {
      return await remoteDataSource.activatePickingVerification(orderNumber);
    } catch (e) {
      throw Exception('激活拣货校验模式失败: $e');
    }
  }

  @override
  Future<bool> verifyPickingItem(String orderId, String itemId, bool isVerified) async {
    try {
      return await remoteDataSource.verifyPickingItem(orderId, itemId, isVerified);
    } catch (e) {
      throw Exception('验证拣货项目失败: $e');
    }
  }

  @override
  Future<bool> completeOrderVerification(String orderId) async {
    try {
      return await remoteDataSource.completeOrderVerification(orderId);
    } catch (e) {
      throw Exception('完成订单校验失败: $e');
    }
  }

  @override
  Future<PickingOrder> getOrderDetails(String orderNumber) async {
    try {
      final orderModel = await remoteDataSource.getOrderDetails(orderNumber);
      return orderModel;
    } catch (e) {
      throw Exception('获取订单详情失败: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> submitVerification({
    required String orderId,
    required List<MaterialItem> materials,
    String? operatorId,
    String? submissionId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 构建提交请求
      final submissionRequest = VerificationSubmissionRequest(
        orderId: orderId,
        submissionId: submissionId ?? _generateSubmissionId(),
        submissionTimestamp: DateTime.now(),
        operatorId: operatorId,
        deviceId: await _getDeviceId(),
        materials: materials.map((m) => MaterialSubmissionItem.fromMaterialItem(
          m,
          statusUpdatedAt: DateTime.now(),
          statusUpdatedBy: operatorId,
        )).toList(),
        metadata: metadata,
      );

      // 提交到远程 API
      final response = await remoteDataSource.submitVerification(submissionRequest);
      
      // 验证响应
      if (response.success) {
        return {
          'success': true,
          'submissionId': response.submissionId,
          'orderId': response.orderId,
          'orderStatus': response.orderStatus,
          'processedAt': response.processedAt,
          'message': response.message,
          'data': response.data ?? {},
        };
      } else {
        throw Exception('提交失败: ${response.message}');
      }
    } catch (e) {
      throw Exception('提交校验结果失败: $e');
    }
  }

  String _generateSubmissionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'SUB_${timestamp}_$random';
  }

  Future<String> _getDeviceId() async {
    // TODO: 在实际应用中应该使用 device_info_plus 等包获取设备信息
    return 'device_${DateTime.now().millisecondsSinceEpoch % 100000}';
  }
}