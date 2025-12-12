import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/config/app_config.dart';
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
      debugPrint('=== 开始获取工单详情 ===');
      debugPrint('订单号: $orderNo');
      debugPrint('请求URL: $baseUrl/api/WorkOrderPickVerf?orderno=$orderNo');

      // 使用真实API调用
      final response = await dio.get(
        '$baseUrl/api/WorkOrderPickVerf',
        queryParameters: {'orderno': orderNo},
      );

      debugPrint('响应状态码: ${response.statusCode}');
      debugPrint('响应数据: ${response.data}');

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
      debugPrint('=== 网络请求异常 ===');
      debugPrint('异常类型: ${e.type}');
      debugPrint('状态码: ${e.response?.statusCode}');
      debugPrint('响应数据: ${e.response?.data}');

      // 处理Dio异常 (包括400, 404, 500等HTTP错误)
      if (e.response != null) {
        // 有响应数据,尝试解析
        if (e.response!.data != null) {
          try {
            // 尝试解析服务器返回的错误响应
            final errorResponse = WorkOrderPickVerfResponse.fromJson(
              e.response!.data is Map<String, dynamic>
                ? e.response!.data as Map<String, dynamic>
                : {'isSuccess': false, 'message': e.response!.data.toString(), 'data': null}
            );

            debugPrint('服务器返回错误消息: ${errorResponse.message}');

            // 直接抛出服务器返回的message（这是用户应该看到的详细错误）
            throw Exception(errorResponse.message);
          } catch (parseError) {
            // 检查parseError是否已经是我们抛出的Exception
            if (parseError is Exception && parseError.toString().startsWith('Exception: ')) {
              // 这是我们上面throw的Exception,直接重新抛出
              debugPrint('重新抛出服务器错误消息');
              rethrow;
            }

            // 真正的解析失败,使用HTTP状态码提示
            debugPrint('解析错误响应失败: $parseError');
            debugPrint('使用HTTP状态码提供默认错误提示');
            if (e.response!.statusCode == 400) {
              throw Exception('扫码订单出现未知错误（无法解析服务器响应）');
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
          debugPrint('服务器返回空数据');
          if (e.response!.statusCode == 400) {
            throw Exception('扫码订单出现未知错误（服务器未返回详细信息）');
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
    try {
      if (AppConfig.enableApiDebugLogging) {
        debugPrint('=== 开始提交工单验证 ===');
        debugPrint('工单ID: $workOrderId');
        debugPrint('工序: $operation');
        debugPrint('状态: $status');
        debugPrint('工作中心: $workCenter');
        debugPrint('操作人: $updateBy');
      }

      // 使用真实API调用
      final request = WorkOrderStatusUpdateRequest(
        workOrderId: workOrderId,
        operation: operation,
        status: status,
        workCenter: workCenter,
        updateOn: DateTime.now(),
        updateBy: updateBy,
      );

      final requestJson = request.toJson();

      if (AppConfig.enableApiDebugLogging) {
        debugPrint('请求URL: $baseUrl/api/WorkOrderPickVerf');
        debugPrint('请求方法: PUT');
        debugPrint('请求体: $requestJson');
      }

      final response = await dio.put(
        '$baseUrl/api/WorkOrderPickVerf',
        data: requestJson,
      );

      if (AppConfig.enableApiDebugLogging) {
        debugPrint('响应状态码: ${response.statusCode}');
        debugPrint('响应数据: ${response.data}');
      }

      if (response.statusCode == 200) {
        final apiResponse = WorkOrderStatusUpdateResponse.fromJson(response.data);

        if (apiResponse.isSuccess) {
          debugPrint('✅ 工单状态更新成功: ${apiResponse.message}');
          return apiResponse.data;
        } else {
          debugPrint('❌ API返回失败: ${apiResponse.message}');
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: apiResponse.message,
          );
        }
      } else {
        debugPrint('❌ HTTP错误: ${response.statusCode}');
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '更新工单状态失败',
        );
      }
    } on DioException catch (e) {
      debugPrint('=== 工单提交异常 ===');
      debugPrint('异常类型: ${e.type}');
      debugPrint('状态码: ${e.response?.statusCode}');
      debugPrint('错误消息: ${e.message}');

      if (AppConfig.enableApiDebugLogging) {
        debugPrint('响应头: ${e.response?.headers}');
        debugPrint('响应数据: ${e.response?.data}');
        debugPrint('请求数据: ${e.requestOptions.data}');
      }

      // 处理HTTP 400错误
      if (e.response?.statusCode == 400) {
        debugPrint('');
        debugPrint('🔍 HTTP 400 错误诊断信息:');
        debugPrint('1. 检查员工ID是否有效: $updateBy');
        debugPrint('2. 检查工作中心代码是否有效: $workCenter');
        debugPrint('3. 检查工单状态是否允许提交');
        debugPrint('4. 请联系服务器管理员确认有效的配置值');
        debugPrint('');

        // 尝试提取服务器错误消息
        String errorMessage = '提交验证失败';
        if (e.response?.data != null) {
          try {
            if (e.response!.data is Map) {
              final data = e.response!.data as Map<String, dynamic>;
              // 按优先级尝试提取错误消息
              if (data.containsKey('message') && data['message'] != null) {
                errorMessage = data['message'] as String;
              } else if (data.containsKey('Message') && data['Message'] != null) {
                errorMessage = data['Message'] as String;
              } else if (data.containsKey('error') && data['error'] != null) {
                errorMessage = data['error'] as String;
              } else if (data.containsKey('Error') && data['Error'] != null) {
                errorMessage = data['Error'] as String;
              } else if (data.containsKey('msg') && data['msg'] != null) {
                errorMessage = data['msg'] as String;
              } else {
                // 如果没有明确的错误字段，尝试格式化整个响应
                errorMessage = '服务器返回错误: ${data.toString()}';
              }
            } else if (e.response!.data is String) {
              final dataStr = e.response!.data as String;
              if (dataStr.isNotEmpty) {
                errorMessage = dataStr;
              }
            }
          } catch (parseError) {
            debugPrint('解析服务器错误消息失败: $parseError');
            errorMessage = '服务器返回了无法解析的错误信息';
          }
        } else {
          errorMessage = '服务器未返回错误详情';
        }

        if (AppConfig.enableApiDebugLogging) {
          debugPrint('最终错误消息: $errorMessage');
        }

        // 直接抛出服务器错误消息，不添加额外的配置信息
        // 配置信息已经在日志中输出了
        throw Exception(errorMessage);
      }

      // 处理其他HTTP错误 (401, 403, 404, 500等)
      if (e.response != null) {
        String serverMessage = '未知错误';

        // 尝试从响应中提取服务器错误消息
        if (e.response!.data != null) {
          try {
            if (e.response!.data is Map) {
              final data = e.response!.data as Map<String, dynamic>;
              if (data.containsKey('message') && data['message'] != null) {
                serverMessage = data['message'] as String;
              } else if (data.containsKey('Message') && data['Message'] != null) {
                serverMessage = data['Message'] as String;
              } else if (data.containsKey('error') && data['error'] != null) {
                serverMessage = data['error'] as String;
              }
            } else if (e.response!.data is String) {
              serverMessage = e.response!.data as String;
            }
          } catch (_) {
            serverMessage = e.message ?? '未知错误';
          }
        }

        throw Exception('提交失败 (HTTP ${e.response!.statusCode}): $serverMessage');
      }

      // 处理网络错误
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('连接服务器超时,请检查网络');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('服务器响应超时,请重试');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('网络连接失败,请检查网络设置');
      } else {
        throw Exception('网络错误: ${e.message ?? "请检查网络连接"}');
      }
    } catch (e) {
      debugPrint('❌ 未知异常: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('提交工单失败: $e');
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