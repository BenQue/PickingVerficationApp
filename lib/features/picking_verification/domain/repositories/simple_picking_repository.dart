import '../entities/simple_picking_entities.dart';

/// 简化的拣货验证仓储接口
abstract class SimplePickingRepository {
  /// 获取工单详情
  Future<SimpleWorkOrder> getWorkOrderDetails(String orderNo);
  
  /// 更新工单状态（提交验证）
  Future<bool> submitVerification({
    required int workOrderId,
    required String orderNo,
    required String operation,
    required String status,
    required String workCenter,
    required String updateBy,
  });
  
  /// 更新单个物料的完成数量（本地状态）
  Future<bool> updateMaterialQuantity({
    required String orderNo,
    required String itemNo,
    required int completedQuantity,
  });
}