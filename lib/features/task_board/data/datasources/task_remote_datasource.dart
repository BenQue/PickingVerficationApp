import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/api/dio_client.dart';
import '../models/task_list_response_model.dart';
import '../models/task_model.dart';


abstract class TaskRemoteDataSource {
  /// Get assigned tasks for the current user
  Future<TaskListResponseModel> getAssignedTasks();
  
  /// Refresh task list
  Future<TaskListResponseModel> refreshTasks();
  
  /// Get tasks filtered by type
  Future<TaskListResponseModel> getTasksByType(String type);
  
  /// Update task status
  Future<TaskModel> updateTaskStatus(String taskId, String status);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final DioClient _dioClient;
  
  TaskRemoteDataSourceImpl({DioClient? dioClient}) 
      : _dioClient = dioClient ?? DioClient();

  @override
  Future<TaskListResponseModel> getAssignedTasks() async {
    try {
      debugPrint('TaskRemoteDataSource: 使用真实API获取任务');
      
      // 使用真实的任务API端点
      final response = await _dioClient.dio.get('/api/tasks');
      
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        debugPrint('真实API获取任务成功: ${response.data}');
        
        return TaskListResponseModel.fromJson(responseData);
      } else {
        throw Exception('任务API返回无效响应');
      }
    } catch (e) {
      debugPrint('任务API调用失败: $e');
      rethrow;
    }
  }

  @override
  Future<TaskListResponseModel> refreshTasks() async {
    // For now, refreshing is the same as getting assigned tasks
    // In future, this could include cache-busting parameters
    return getAssignedTasks();
  }

  @override
  Future<TaskListResponseModel> getTasksByType(String type) async {
    try {
      final response = await _dioClient.dio.get(
        '/api/tasks/assigned',
        queryParameters: {'type': type},
      );
      
      if (response.statusCode == 200) {
        return TaskListResponseModel.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          message: '获取特定类型任务失败',
          response: response,
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('获取特定类型任务时发生未知错误: ${e.toString()}');
    }
  }

  @override
  Future<TaskModel> updateTaskStatus(String taskId, String status) async {
    try {
      // 根据状态选择合适的端点
      String endpoint;
      if (status == 'IN_PROGRESS' || status == 'started') {
        endpoint = '/api/tasks/$taskId/start';
      } else if (status == 'COMPLETED' || status == 'completed') {
        endpoint = '/api/tasks/$taskId/complete';
      } else {
        // 对于其他状态，使用通用状态更新端点
        endpoint = '/api/tasks/$taskId/status';
      }
      
      final response = await _dioClient.dio.patch(endpoint, 
        data: status.startsWith('/api/tasks/$taskId/status') ? {'status': status} : null);
      
      if (response.statusCode == 200) {
        debugPrint('任务状态更新成功: $taskId -> $status');
        return TaskModel.fromJson(response.data);
      } else {
        throw Exception('更新任务状态失败');
      }
    } catch (e) {
      debugPrint('任务状态更新失败: $e');
      rethrow;
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('网络连接超时，请检查网络连接');
        
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? e.message;
        
        switch (statusCode) {
          case 400:
            return Exception('请求参数错误: $message');
          case 401:
            return Exception('身份验证失败，请重新登录');
          case 403:
            return Exception('权限不足，无法执行该操作');
          case 404:
            return Exception('请求的资源不存在');
          case 500:
            return Exception('服务器内部错误，请稍后重试');
          default:
            return Exception('请求失败 ($statusCode): $message');
        }
        
      case DioExceptionType.cancel:
        return Exception('请求已取消');
        
      case DioExceptionType.connectionError:
        return Exception('网络连接失败，请检查网络设置');
        
      default:
        return Exception('网络请求失败: ${e.message}');
    }
  }
}