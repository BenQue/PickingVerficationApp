import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/simple_api_models.dart';

/// 简化的拣货校验数据源 - 使用新的SimpleAPI
class SimplePickingDataSource {
  final Dio dio;
  
  // API基础URL - 可以从环境配置中读取
  static const String baseUrl = 'http://10.163.130.173:8001';

  SimplePickingDataSource({required this.dio});

  /// 获取工单详情 - 优先使用模拟数据进行测试
  Future<WorkOrderData> getWorkOrderDetails(String orderNo) async {
    try {
      debugPrint('正在获取工单详情: $orderNo');
      
      // 开发测试阶段：优先使用模拟数据
      debugPrint('使用模拟数据进行测试 - 工单号: $orderNo');
      await Future.delayed(const Duration(milliseconds: 800)); // 模拟网络延迟
      return _getMockWorkOrderData(orderNo);
      
      // 真实API调用代码（切换到生产环境时启用）
      /*
      final response = await dio.get(
        '$baseUrl/api/WorkOrderPickVerf',
        queryParameters: {'orderno': orderNo},
      );

      if (response.statusCode == 200) {
        final apiResponse = WorkOrderPickVerfResponse.fromJson(response.data);
        
        if (apiResponse.isSuccess && apiResponse.data != null) {
          debugPrint('工单详情获取成功: ${apiResponse.message}');
          return apiResponse.data!;
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: apiResponse.message,
          );
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '获取工单详情失败',
        );
      }
      */
    } catch (e) {
      debugPrint('使用模拟数据进行测试: $e');
      return _getMockWorkOrderData(orderNo);
    }
  }

  /// 更新工单状态 - 优先使用模拟响应
  Future<bool> updateWorkOrderStatus({
    required int workOrderId,
    required String operation,
    required String status,
    required String workCenter,
    required String updateBy,
  }) async {
    try {
      debugPrint('正在更新工单状态: $workOrderId');
      
      // 开发测试阶段：模拟成功提交
      debugPrint('模拟提交成功 - 工单ID: $workOrderId, 状态: $status, 操作员: $updateBy');
      await Future.delayed(const Duration(milliseconds: 1200)); // 模拟网络延迟
      return true; // 模拟成功响应
      
      // 真实API调用代码（切换到生产环境时启用）
      /*
      final request = WorkOrderStatusUpdateRequest(
        workOrderId: workOrderId,
        operation: operation,
        status: status,
        workCenter: workCenter,
        updateOn: DateTime.now(),
        updateBy: updateBy,
      );

      final response = await dio.put(
        '$baseUrl/api/WorkOrderPickVerf',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final apiResponse = WorkOrderStatusUpdateResponse.fromJson(response.data);
        
        if (apiResponse.isSuccess) {
          debugPrint('工单状态更新成功: ${apiResponse.message}');
          return apiResponse.data;
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: apiResponse.message,
          );
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '更新工单状态失败',
        );
      }
      */
    } catch (e) {
      debugPrint('使用模拟响应: $e');
      return true; // 测试阶段总是返回成功
    }
  }

  /// 更新单个物料的完成数量
  /// 注意：这可能需要根据实际API调整，如果API不支持单个物料更新，
  /// 则需要在前端维护状态，最后统一提交
  Future<bool> updateMaterialCompletedQuantity({
    required String orderNo,
    required String itemNo,
    required int completedQuantity,
    required String materialCategory, // 'cable', 'center', 'auto'
  }) async {
    // TODO: 根据实际API实现
    // 如果没有单独的物料更新接口，可以在前端维护状态
    debugPrint('更新物料完成数量: $orderNo - $itemNo - $completedQuantity');
    return true;
  }

  /// 获取模拟数据（用于开发测试）- 支持多种测试场景
  WorkOrderData _getMockWorkOrderData(String orderNo) {
    debugPrint('生成模拟数据 - 工单号: $orderNo');
    
    // 根据工单号返回不同的测试场景
    switch (orderNo.toUpperCase()) {
      case '123456789':
      case 'TEST001':
        return _getCompleteTestOrder(orderNo);
      
      case 'TEST002':
      case 'EMPTY':
        return _getEmptyTestOrder(orderNo);
      
      case 'TEST003':
      case 'PARTIAL':
        return _getPartialCompleteOrder(orderNo);
      
      case 'TEST004':
      case 'LARGE':
        return _getLargeTestOrder(orderNo);
      
      case 'ERROR':
      case 'FAIL':
        throw DioException(
          requestOptions: RequestOptions(path: '/mock'),
          message: '模拟API错误 - 工单号不存在',
        );
      
      default:
        return _getRandomTestOrder(orderNo);
    }
  }

  /// 完整测试工单 - 包含所有三类物料
  WorkOrderData _getCompleteTestOrder(String orderNo) {
    return WorkOrderData(
      orderId: 1001,
      orderNo: orderNo,
      operationNo: '0001',
      operationStatus: '1',
      cableItemCount: 3,
      rawItemCount: 8,
      labelCount: 5,
      cabelItems: [
        SimpleMaterialItem(
          itemNo: 'C001',
          materialCode: 'CBL-001',
          materialDesc: '电源线缆 - 220V/50A',
          quantity: 10,
          completedQuantity: 7,
        ),
        SimpleMaterialItem(
          itemNo: 'C002',
          materialCode: 'CBL-002', 
          materialDesc: '信号线缆 - RS485',
          quantity: 5,
          completedQuantity: 0,
        ),
        SimpleMaterialItem(
          itemNo: 'C003',
          materialCode: 'CBL-003',
          materialDesc: '网络线缆 - CAT6',
          quantity: 8,
          completedQuantity: 8,
        ),
      ],
      centerStockItems: [
        SimpleMaterialItem(
          itemNo: 'CS001',
          materialCode: 'CS-001',
          materialDesc: '标准螺栓 M8x20',
          quantity: 20,
          completedQuantity: 20,
        ),
        SimpleMaterialItem(
          itemNo: 'CS002', 
          materialCode: 'CS-002',
          materialDesc: '垫圈 φ8',
          quantity: 40,
          completedQuantity: 35,
        ),
        SimpleMaterialItem(
          itemNo: 'CS003',
          materialCode: 'CS-003',
          materialDesc: '接线端子 2.5mm²',
          quantity: 15,
          completedQuantity: 10,
        ),
      ],
      autoStockItems: [
        SimpleMaterialItem(
          itemNo: 'AS001',
          materialCode: 'AS-001', 
          materialDesc: '精密轴承 6200ZZ',
          quantity: 4,
          completedQuantity: 4,
        ),
        SimpleMaterialItem(
          itemNo: 'AS002',
          materialCode: 'AS-002',
          materialDesc: '伺服电机 200W',
          quantity: 2,
          completedQuantity: 2,
        ),
      ],
    );
  }

  /// 空工单测试数据
  WorkOrderData _getEmptyTestOrder(String orderNo) {
    return WorkOrderData(
      orderId: 1002,
      orderNo: orderNo,
      operationNo: '0002',
      operationStatus: '1',
      cableItemCount: 0,
      rawItemCount: 0,
      labelCount: 0,
      cabelItems: [],
      centerStockItems: [],
      autoStockItems: [],
    );
  }

  /// 部分完成工单
  WorkOrderData _getPartialCompleteOrder(String orderNo) {
    return WorkOrderData(
      orderId: 1003,
      orderNo: orderNo,
      operationNo: '0003',
      operationStatus: '1',
      cableItemCount: 2,
      rawItemCount: 3,
      labelCount: 1,
      cabelItems: [
        SimpleMaterialItem(
          itemNo: 'C101',
          materialCode: 'CBL-101',
          materialDesc: '控制电缆 KVVP-7x1.5',
          quantity: 12,
          completedQuantity: 12,
        ),
        SimpleMaterialItem(
          itemNo: 'C102',
          materialCode: 'CBL-102',
          materialDesc: '电源电缆 YJV-3x16',
          quantity: 6,
          completedQuantity: 6,
        ),
      ],
      centerStockItems: [
        SimpleMaterialItem(
          itemNo: 'CS101',
          materialCode: 'CS-101',
          materialDesc: '接线盒 IP65',
          quantity: 3,
          completedQuantity: 2,
        ),
        SimpleMaterialItem(
          itemNo: 'CS102',
          materialCode: 'CS-102',
          materialDesc: '密封圈 NBR',
          quantity: 6,
          completedQuantity: 0,
        ),
      ],
      autoStockItems: [
        SimpleMaterialItem(
          itemNo: 'AS101',
          materialCode: 'AS-101',
          materialDesc: '变频器 0.75KW',
          quantity: 1,
          completedQuantity: 0,
        ),
      ],
    );
  }

  /// 大批量工单测试
  WorkOrderData _getLargeTestOrder(String orderNo) {
    return WorkOrderData(
      orderId: 1004,
      orderNo: orderNo,
      operationNo: '0004',
      operationStatus: '1',
      cableItemCount: 8,
      rawItemCount: 15,
      labelCount: 12,
      cabelItems: List.generate(8, (index) => SimpleMaterialItem(
        itemNo: 'C${(index + 1).toString().padLeft(3, '0')}',
        materialCode: 'CBL-${(index + 1).toString().padLeft(3, '0')}',
        materialDesc: '电缆线束 ${index + 1}#',
        quantity: (index + 1) * 5,
        completedQuantity: (index % 3 == 0) ? (index + 1) * 5 : (index + 1) * 2,
      )),
      centerStockItems: List.generate(15, (index) => SimpleMaterialItem(
        itemNo: 'CS${(index + 1).toString().padLeft(3, '0')}',
        materialCode: 'CS-${(index + 1).toString().padLeft(3, '0')}',
        materialDesc: '中央仓库物料 ${index + 1}#',
        quantity: (index + 1) * 3,
        completedQuantity: (index % 2 == 0) ? (index + 1) * 3 : 0,
      )),
      autoStockItems: List.generate(12, (index) => SimpleMaterialItem(
        itemNo: 'AS${(index + 1).toString().padLeft(3, '0')}',
        materialCode: 'AS-${(index + 1).toString().padLeft(3, '0')}',
        materialDesc: '自动化物料 ${index + 1}#',
        quantity: (index + 1) * 2,
        completedQuantity: (index + 1) * 2,
      )),
    );
  }

  /// 随机生成测试工单
  WorkOrderData _getRandomTestOrder(String orderNo) {
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return WorkOrderData(
      orderId: 2000 + (random % 100),
      orderNo: orderNo,
      operationNo: '${(random % 9999).toString().padLeft(4, '0')}',
      operationStatus: '1',
      cableItemCount: 2,
      rawItemCount: 4,
      labelCount: 3,
      cabelItems: [
        SimpleMaterialItem(
          itemNo: 'R001',
          materialCode: 'RND-001',
          materialDesc: '随机电缆物料 A',
          quantity: 5 + (random % 10),
          completedQuantity: random % 8,
        ),
        SimpleMaterialItem(
          itemNo: 'R002',
          materialCode: 'RND-002',
          materialDesc: '随机电缆物料 B',
          quantity: 3 + (random % 7),
          completedQuantity: 0,
        ),
      ],
      centerStockItems: [
        SimpleMaterialItem(
          itemNo: 'R101',
          materialCode: 'RND-101',
          materialDesc: '随机中央仓库物料 A',
          quantity: 10 + (random % 20),
          completedQuantity: random % 15,
        ),
        SimpleMaterialItem(
          itemNo: 'R102',
          materialCode: 'RND-102',
          materialDesc: '随机中央仓库物料 B',
          quantity: 8 + (random % 12),
          completedQuantity: random % 10,
        ),
      ],
      autoStockItems: [
        SimpleMaterialItem(
          itemNo: 'R201',
          materialCode: 'RND-201',
          materialDesc: '随机自动化物料 A',
          quantity: 2 + (random % 5),
          completedQuantity: random % 4,
        ),
      ],
    );
  }
}