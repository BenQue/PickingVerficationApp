import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/simple_api_models.dart';

/// 简化的拣货校验数据源 - 使用新的SimpleAPI
class SimplePickingDataSource {
  final Dio dio;
  
  // API基础URL - 使用真实的生产服务器地址(来自API文档)
  static const String baseUrl = 'http://10.163.130.173:8001';

  SimplePickingDataSource({required this.dio});

  /// 获取工单详情 - 使用真实API
  Future<WorkOrderData> getWorkOrderDetails(String orderNo) async {
    try {
      debugPrint('正在获取工单详情: $orderNo');

      // 使用真实API调用
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
          // API返回成功但isSuccess=false的情况
          debugPrint('API返回错误: ${apiResponse.message}');
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception('获取工单详情失败: HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('网络请求异常 - 状态码: ${e.response?.statusCode}');

      // 处理Dio异常 (包括400, 404, 500等HTTP错误)
      if (e.response != null) {
        // 有响应数据,尝试解析
        if (e.response!.data != null) {
          try {
            final errorResponse = WorkOrderPickVerfResponse.fromJson(e.response!.data as Map<String, dynamic>);
            debugPrint('服务器返回错误: ${errorResponse.message}');

            // 直接抛出服务器返回的message
            throw Exception(errorResponse.message);
          } catch (parseError) {
            // 检查parseError是否已经是我们抛出的Exception
            if (parseError is Exception && parseError.toString().startsWith('Exception: ')) {
              // 这是我们上面throw的Exception,直接重新抛出
              rethrow;
            }

            // 真正的解析失败,使用HTTP状态码提示
            debugPrint('解析错误响应失败,使用默认提示');
            if (e.response!.statusCode == 400) {
              throw Exception('扫码订单出现未知错误');
            } else if (e.response!.statusCode == 404) {
              throw Exception('服务器接口不存在,请联系技术支持');
            } else if (e.response!.statusCode == 500) {
              throw Exception('服务器内部错误,请稍后重试');
            } else {
              throw Exception('获取工单失败: HTTP ${e.response!.statusCode}');
            }
          }
        } else {
          // 有响应但没有数据
          if (e.response!.statusCode == 400) {
            throw Exception('扫码订单出现未知错误');
          } else {
            throw Exception('服务器返回错误: HTTP ${e.response!.statusCode}');
          }
        }
      } else {
        // 没有响应,网络问题
        if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('连接超时,请检查网络连接');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception('服务器响应超时,请重试');
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception('网络连接失败,请检查网络设置');
        } else {
          throw Exception('网络错误,请检查网络连接');
        }
      }
    } catch (e) {
      // 其他异常
      debugPrint('获取工单详情异常: $e');
      // 如果已经是Exception,直接抛出
      if (e is Exception) {
        rethrow;
      }
      // 否则包装为用户友好的消息
      throw Exception('获取工单失败,请重试');
    }
  }

  /// 更新工单状态 - 使用真实API
  Future<bool> updateWorkOrderStatus({
    required int workOrderId,
    required String operation,
    required String status,
    required String workCenter,
    required String updateBy,
  }) async {
    debugPrint('正在更新工单状态: $workOrderId');

    // 使用真实API调用
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
}