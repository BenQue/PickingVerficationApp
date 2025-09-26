import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/picking_order_model.dart';
import '../models/submission_models.dart';


/// 拣货校验远程数据源抽象接口
abstract class PickingRemoteDataSource {
  Future<PickingOrderModel> getPickingOrder(String orderNumber);
  Future<bool> activatePickingVerification(String orderNumber);
  Future<bool> verifyPickingItem(String orderId, String itemId, bool isVerified);
  Future<bool> completeOrderVerification(String orderId);
  Future<PickingOrderModel> getOrderDetails(String orderNumber);
  Future<VerificationSubmissionResponse> submitVerification(VerificationSubmissionRequest request);
}

/// 拣货校验远程数据源实现
class PickingRemoteDataSourceImpl implements PickingRemoteDataSource {
  final Dio dio;

  PickingRemoteDataSourceImpl({required this.dio});

  @override
  Future<PickingOrderModel> getPickingOrder(String orderNumber) async {
    try {
      final response = await dio.get('/api/orders/$orderNumber/picking');
      
      if (response.statusCode == 200) {
        return PickingOrderModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '获取拣货订单信息失败',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/orders/$orderNumber/picking'),
        message: '网络请求异常: $e',
      );
    }
  }

  @override
  Future<bool> activatePickingVerification(String orderNumber) async {
    try {
      final response = await dio.post('/api/orders/$orderNumber/picking/activate');
      
      if (response.statusCode == 200) {
        return response.data['success'] == true;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '激活拣货校验模式失败',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/orders/$orderNumber/picking/activate'),
        message: '网络请求异常: $e',
      );
    }
  }

  @override
  Future<bool> verifyPickingItem(String orderId, String itemId, bool isVerified) async {
    try {
      final response = await dio.put(
        '/api/orders/$orderId/items/$itemId/verify',
        data: {'isVerified': isVerified},
      );
      
      if (response.statusCode == 200) {
        return response.data['success'] == true;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '验证拣货项目失败',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/orders/$orderId/items/$itemId/verify'),
        message: '网络请求异常: $e',
      );
    }
  }

  @override
  Future<bool> completeOrderVerification(String orderId) async {
    try {
      final response = await dio.post('/api/orders/$orderId/picking/complete');
      
      if (response.statusCode == 200) {
        return response.data['success'] == true;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '完成订单校验失败',
        );
      }
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/orders/$orderId/picking/complete'),
        message: '网络请求异常: $e',
      );
    }
  }

  @override
  Future<PickingOrderModel> getOrderDetails(String orderNumber) async {
    try {
      // 首先尝试真实 API
      debugPrint('尝试获取订单详情: $orderNumber');
      final response = await dio.get('/api/v1/orders/$orderNumber');
      
      if (response.statusCode == 200) {
        debugPrint('订单详情获取成功');
        return PickingOrderModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '获取订单详情失败',
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          message: '订单号不存在',
        );
      }
      
      debugPrint('API失败，使用模拟数据: $e');
      // 其他 API 错误，回退到模拟数据
      rethrow;
    } catch (e) {
      debugPrint('网络请求异常，使用模拟数据: $e');
      rethrow;
    }
  }

  @override
  Future<VerificationSubmissionResponse> submitVerification(
    VerificationSubmissionRequest request,
  ) async {
    const retryConfig = SubmissionRetryConfig();
    int attemptCount = 0;
    DioException? lastException;

    while (attemptCount <= retryConfig.maxRetries) {
      try {
        // 配置超时时间 - 使用真实API端点
        final requestOptions = RequestOptions(
          path: '/api/v1/verification/complete/${request.orderId}',
          method: 'POST',
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          data: request.toJson(),
          headers: {
            'Content-Type': 'application/json',
            'X-Submission-ID': request.submissionId,
            'X-Request-Attempt': attemptCount + 1,
            if (request.operatorId != null) 'X-Operator-ID': request.operatorId!,
          },
        );

        final response = await dio.request(
          requestOptions.path,
          options: Options(
            method: requestOptions.method,
            sendTimeout: requestOptions.sendTimeout,
            receiveTimeout: requestOptions.receiveTimeout,
            headers: requestOptions.headers,
          ),
          data: requestOptions.data,
        );
        
        // 成功响应处理
        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('验证提交成功');
          return _parseSuccessResponse(response.data, request);
        } else {
          return _parseErrorResponse(
            response.data, 
            response.statusCode ?? 500,
            request,
          );
        }
        
      } on DioException catch (e) {
        lastException = e;
        attemptCount++;
        
        final statusCode = e.response?.statusCode ?? 0;
        
        // 检查是否应该重试
        if (!retryConfig.shouldRetry(statusCode, attemptCount)) {
          return _handleDioException(e, request);
        }
        
        // 等待后重试
        if (attemptCount <= retryConfig.maxRetries) {
          final delay = retryConfig.getDelayForAttempt(attemptCount);
          await Future.delayed(delay);
          debugPrint('重试提交第 $attemptCount 次, 延迟 ${delay.inMilliseconds}ms');
        }
        
      } catch (e) {
        debugPrint('验证提交失败，使用模拟提交: $e');
        // 如果真实API失败，使用模拟提交
        rethrow;
      }
    }
    
    // 所有重试都失败
    return lastException != null 
        ? _handleDioException(lastException, request)
        : VerificationSubmissionResponse(
            success: false,
            message: '提交失败，已超过最大重试次数',
            submissionId: request.submissionId,
            orderId: request.orderId,
          );
  }

  /// 解析成功响应
  VerificationSubmissionResponse _parseSuccessResponse(
    dynamic responseData, 
    VerificationSubmissionRequest request,
  ) {
    try {
      final data = responseData as Map<String, dynamic>? ?? {};
      
      return VerificationSubmissionResponse(
        success: true,
        message: data['message'] as String? ?? '提交成功',
        submissionId: data['submissionId'] as String? ?? request.submissionId,
        orderId: data['orderId'] as String? ?? request.orderId,
        processedAt: data['processedAt'] != null
            ? DateTime.tryParse(data['processedAt'] as String)
            : DateTime.now(),
        orderStatus: data['orderStatus'] as String?,
        data: data['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      // 解析失败但响应成功
      return VerificationSubmissionResponse(
        success: true,
        message: '提交成功但响应解析失败',
        submissionId: request.submissionId,
        orderId: request.orderId,
        processedAt: DateTime.now(),
        errors: {'parseError': e.toString()},
      );
    }
  }

  /// 解析错误响应
  VerificationSubmissionResponse _parseErrorResponse(
    dynamic responseData, 
    int statusCode,
    VerificationSubmissionRequest request,
  ) {
    try {
      final data = responseData as Map<String, dynamic>? ?? {};
      
      return VerificationSubmissionResponse(
        success: false,
        message: data['message'] as String? ?? _getStatusCodeMessage(statusCode),
        submissionId: request.submissionId,
        orderId: request.orderId,
        errors: {
          'statusCode': statusCode,
          'serverError': data,
        },
      );
    } catch (e) {
      return VerificationSubmissionResponse(
        success: false,
        message: _getStatusCodeMessage(statusCode),
        submissionId: request.submissionId,
        orderId: request.orderId,
        errors: {
          'statusCode': statusCode,
          'parseError': e.toString(),
        },
      );
    }
  }

  /// 处理 Dio 异常
  VerificationSubmissionResponse _handleDioException(
    DioException e, 
    VerificationSubmissionRequest request,
  ) {
    final statusCode = e.response?.statusCode ?? 0;
    String message;
    Map<String, dynamic> errors = {};
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        message = '连接超时，请检查网络后重试';
        errors['timeoutType'] = 'connection';
        break;
      case DioExceptionType.receiveTimeout:
        message = '响应超时，服务器处理时间过长';
        errors['timeoutType'] = 'receive';
        break;
      case DioExceptionType.badResponse:
        message = _getStatusCodeMessage(statusCode);
        errors['statusCode'] = statusCode;
        errors['responseData'] = e.response?.data;
        break;
      case DioExceptionType.cancel:
        message = '请求被取消';
        errors['cancelled'] = true;
        break;
      case DioExceptionType.unknown:
      default:
        message = '网络连接失败，请检查网络连接';
        errors['networkError'] = true;
        errors['exception'] = e.message;
        break;
    }
    
    return VerificationSubmissionResponse(
      success: false,
      message: message,
      submissionId: request.submissionId,
      orderId: request.orderId,
      errors: errors,
    );
  }

  /// 根据 HTTP 状态码获取错误消息
  String _getStatusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return '请求参数错误，请检查数据格式';
      case 401:
        return '身份验证失败，请重新登录';
      case 403:
        return '权限不足，无法执行此操作';
      case 404:
        return '订单不存在或已被删除';
      case 409:
        return '订单状态冲突，请刷新后重试';
      case 422:
        return '数据验证失败，请检查输入信息';
      case 429:
        return '请求过于频繁，请稍后再试';
      case 500:
        return '服务器内部错误，请稍后重试';
      case 502:
      case 503:
        return '服务器正在维护，请稍后再试';
      case 504:
        return '服务器响应超时，请稍后重试';
      default:
        return '网络错误 ($statusCode)，请稍后重试';
    }
  }
}