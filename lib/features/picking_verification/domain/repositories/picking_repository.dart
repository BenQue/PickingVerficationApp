import '../entities/picking_order.dart';
import '../entities/material_item.dart';

/// 拣货校验仓储接口
abstract class PickingRepository {
  /// 根据订单号获取拣货订单信息
  Future<PickingOrder> getPickingOrder(String orderNumber);

  /// 激活拣货校验模式
  Future<bool> activatePickingVerification(String orderNumber);

  /// 验证拣货项目
  Future<bool> verifyPickingItem(String orderId, String itemId, bool isVerified);

  /// 完成订单校验
  Future<bool> completeOrderVerification(String orderId);
  
  /// 获取订单详细信息（包含物料清单）
  Future<PickingOrder> getOrderDetails(String orderNumber);
  
  /// 提交校验结果
  Future<Map<String, dynamic>> submitVerification({
    required String orderId,
    required List<MaterialItem> materials,
    String? operatorId,
    String? submissionId,
    Map<String, dynamic>? metadata,
  });
}