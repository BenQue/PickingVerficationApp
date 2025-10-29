import '../../domain/entities/simple_picking_entities.dart';
import '../../domain/repositories/simple_picking_repository.dart';
import '../datasources/simple_picking_datasource.dart';
import '../models/simple_api_models.dart';

/// 简化的拣货验证仓储实现
class SimplePickingRepositoryImpl implements SimplePickingRepository {
  final SimplePickingDataSource dataSource;
  
  // 本地缓存的工单数据（用于临时状态管理）
  final Map<String, SimpleWorkOrder> _orderCache = {};

  SimplePickingRepositoryImpl({required this.dataSource});

  @override
  Future<SimpleWorkOrder> getWorkOrderDetails(String orderNo) async {
    try {
      // 从API获取数据
      final workOrderData = await dataSource.getWorkOrderDetails(orderNo);
      
      // 转换为领域实体
      final workOrder = _convertToEntity(workOrderData);
      
      // 缓存工单数据
      _orderCache[orderNo] = workOrder;
      
      return workOrder;
    } catch (e) {
      // 如果失败，尝试返回缓存的数据
      if (_orderCache.containsKey(orderNo)) {
        return _orderCache[orderNo]!;
      }
      rethrow;
    }
  }

  @override
  Future<bool> submitVerification({
    required int workOrderId,
    required String orderNo,
    required String operation,
    required String status,
    required String workCenter,
    required String updateBy,
  }) async {
    try {
      final result = await dataSource.updateWorkOrderStatus(
        workOrderId: workOrderId,
        operation: operation,
        status: status,
        workCenter: workCenter,
        updateBy: updateBy,
      );
      
      // 如果提交成功，清除缓存
      if (result) {
        _orderCache.remove(orderNo);
      }
      
      return result;
    } catch (e) {
      throw Exception('提交验证失败: $e');
    }
  }

  @override
  Future<bool> updateMaterialQuantity({
    required String orderNo,
    required String itemNo,
    required int completedQuantity,
  }) async {
    try {
      // 更新本地缓存的工单数据
      if (_orderCache.containsKey(orderNo)) {
        final currentOrder = _orderCache[orderNo]!;
        _orderCache[orderNo] = currentOrder.updateMaterialQuantity(
          itemNo,
          completedQuantity,
        );
        return true;
      }
      
      // 如果没有缓存，先获取工单数据
      final workOrder = await getWorkOrderDetails(orderNo);
      _orderCache[orderNo] = workOrder.updateMaterialQuantity(
        itemNo,
        completedQuantity,
      );
      
      return true;
    } catch (e) {
      throw Exception('更新物料数量失败: $e');
    }
  }

  /// 将API模型转换为领域实体
  SimpleWorkOrder _convertToEntity(WorkOrderData data) {
    return SimpleWorkOrder(
      orderId: data.orderId,
      orderNo: data.orderNo,
      operationNo: data.operationNo,
      operationStatus: data.operationStatus,
      cableItemCount: data.cableItemCount,
      rawItemCount: data.rawItemCount,
      rawMtrBatchCount: data.rawMtrBatchCount,
      labelCount: data.labelCount,
      cableMaterials: _convertMaterials(data.cableItems, MaterialCategoryType.cable),
      centerMaterials: _convertMaterials(data.centerStockItems, MaterialCategoryType.center),
      autoMaterials: _convertMaterials(data.autoStockItems, MaterialCategoryType.auto),
    );
  }

  /// 转换物料列表
  List<SimpleMaterial> _convertMaterials(
    List<SimpleMaterialItem> items,
    MaterialCategoryType category,
  ) {
    return items.map((item) => SimpleMaterial(
      itemNo: item.itemNo,
      materialCode: item.materialCode,
      materialDesc: item.materialDesc,
      quantity: item.quantity,
      completedQuantity: item.completedQuantity,
      category: category,
    )).toList();
  }

  /// 获取缓存的工单（用于状态管理）
  SimpleWorkOrder? getCachedOrder(String orderNo) {
    return _orderCache[orderNo];
  }

  /// 清除所有缓存
  void clearCache() {
    _orderCache.clear();
  }
}