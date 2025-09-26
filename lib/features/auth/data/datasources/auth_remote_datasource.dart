import 'package:flutter/foundation.dart';
import '../../../../core/api/dio_client.dart';
import '../models/auth_request_model.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login(AuthRequestModel request);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  const AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AuthResponseModel> login(AuthRequestModel request) async {
    try {
      // 暂时使用模拟数据进行登录测试
      debugPrint('使用模拟数据登录: ${request.employeeId}');

      // 模拟网络延迟
      await Future.delayed(const Duration(milliseconds: 500));

      // 检查模拟用户凭据
      if (_isValidMockUser(request.employeeId, request.password)) {
        debugPrint('模拟登录成功');
        return _createMockAuthResponse(request.employeeId);
      } else {
        throw Exception('用户名或密码错误');
      }

      // 原始真实 API 代码 (暂时注释)
      /*
      debugPrint('尝试使用真实API登录: ${request.employeeId}');
      final response = await dioClient.dio.post(
        '/api/auth/login',
        data: request.toJson(),
      );
      */

      // 原始API代码已被注释掉，现在使用模拟数据
      /*
      if (response.statusCode == 200) {
        debugPrint('真实API登录成功');
        return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: '登录失败: ${response.data}',
        );
      }
      */
    } catch (e) {
      // 模拟数据代码已经处理了所有情况
      rethrow;
    }

    // 旧的错误处理代码 (注释掉)
    /*
    } on DioException catch (e) {
      debugPrint('真实API请求失败: ${e.message}');
      debugPrint('错误类型: ${e.type}');
      debugPrint('响应状态码: ${e.response?.statusCode}');
      debugPrint('响应数据: ${e.response?.data}');
      
      // 提取详细错误信息
      String errorDetails = '';
      if (e.response?.data != null) {
        if (e.response?.data is Map) {
          final data = e.response?.data as Map;
          // 尝试获取错误信息，支持多种响应格式
          errorDetails = data['message'] ?? 
                        data['detail'] ?? 
                        (data['error'] is Map ? data['error']['message'] : data['error']) ?? 
                        '';
          debugPrint('解析出的错误详情: $errorDetails');
        } else {
          errorDetails = e.response?.data.toString() ?? '';
          debugPrint('字符串格式错误详情: $errorDetails');
        }
      }
      debugPrint('最终错误详情: $errorDetails');
      
      if (e.response?.statusCode == 401) {
        // 401 Unauthorized - 用户名或密码错误
        final message = errorDetails.isNotEmpty 
            ? '认证失败: $errorDetails' 
            : '用户名或密码错误，请检查您的登录信息';
        throw Exception(message);
      } else if (e.response?.statusCode == 403) {
        // 403 Forbidden - 没有权限
        final message = errorDetails.isNotEmpty 
            ? '权限不足: $errorDetails' 
            : '您没有访问此系统的权限，请联系管理员';
        throw Exception(message);
      } else if (e.response?.statusCode == 404) {
        // 404 Not Found - 用户不存在或API端点错误
        final message = errorDetails.isNotEmpty 
            ? '请求失败: $errorDetails' 
            : '用户不存在或服务端点不可用';
        throw Exception(message);
      } else if (e.response?.statusCode == 500) {
        // 500 Internal Server Error
        final message = errorDetails.isNotEmpty 
            ? '服务器错误: $errorDetails' 
            : '服务器内部错误，请稍后重试或联系技术支持';
        throw Exception(message);
      } else if (e.response?.statusCode == 501) {
        // 501 Not Implemented - 后端认证服务未实现
        final message = errorDetails.isNotEmpty 
            ? '服务未实现: $errorDetails' 
            : '后端认证服务尚未实现，请联系开发团队';
        throw Exception(message);
      } else if (e.response?.statusCode == 503) {
        // 503 Service Unavailable
        final message = errorDetails.isNotEmpty 
            ? '服务不可用: $errorDetails' 
            : '服务暂时不可用，请稍后重试';
        throw Exception(message);
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        // 尝试切换到设备IP（仅限Android）
        try {
          final switched = await dioClient.switchToDeviceUrl();
          if (switched) {
            debugPrint('已切换到设备IP，重试登录');
            final response = await dioClient.dio.post(
              '/api/auth/login', 
              data: request.toJson(),
            );
            
            debugPrint('切换后API响应状态码: ${response.statusCode}');
            debugPrint('切换后API响应数据: ${response.data}');
            
            if (response.statusCode == 200) {
              debugPrint('使用设备IP登录成功');
              return AuthResponseModel.fromJson(response.data as Map<String, dynamic>);
            } else {
              throw Exception('登录失败: ${response.data?['message'] ?? '未知错误'}');
            }
          }
        } catch (switchError) {
          debugPrint('切换URL后仍然失败: $switchError');
          throw Exception('无法连接到服务器 (超时)。请检查:\n'
              '1. 网络连接是否正常\n'
              '2. 服务器地址是否正确 (${dioClient.dio.options.baseUrl})\n'
              '3. 服务器是否正在运行');
        }
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('连接错误。请检查:\n'
            '1. 网络是否已连接\n'
            '2. 服务器地址是否可访问\n'
            '3. 防火墙或代理设置');
      } else if (e.type == DioExceptionType.badResponse) {
        // 处理其他非标准HTTP状态码
        final statusCode = e.response?.statusCode ?? 0;
        final message = errorDetails.isNotEmpty 
            ? '请求失败 ($statusCode): $errorDetails'
            : '请求失败，状态码: $statusCode';
        throw Exception(message);
      }
      
      // 其他错误
      debugPrint('API登录失败，错误详情: ${e.toString()}');
      if (e.response != null) {
        debugPrint('错误响应数据: ${e.response?.data}');
        final message = errorDetails.isNotEmpty 
            ? '登录失败: $errorDetails'
            : '登录失败: ${e.message ?? '未知错误'}';
        throw Exception(message);
      } else {
        // 没有响应的网络错误
        String message = '网络请求失败';
        if (e.type == DioExceptionType.cancel) {
          message = '请求已取消';
        } else if (e.type == DioExceptionType.unknown) {
          message = '未知错误: ${e.message ?? '请检查网络连接'}';
        } else {
          message = '网络错误: ${e.message ?? e.type.toString()}';
        }
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('登录过程发生未知错误: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('登录失败: $e');
    }
    */
  }

  // 模拟用户验证
  bool _isValidMockUser(String employeeId, String password) {
    final mockUsers = {
      'ADM001': 'Admin@123',
      'OPR001': 'Operator@123',
      'QC001': 'QC@123',
      'MGR001': 'Manager@123',
      'WRK001': 'Worker@123',
    };
    return mockUsers[employeeId] == password;
  }

  // 创建模拟认证响应
  AuthResponseModel _createMockAuthResponse(String employeeId) {
    final mockUserData = _getMockUserData(employeeId);
    return AuthResponseModel(
      user: mockUserData,
      message: '登录成功',
      success: true,
      accessToken: 'mock_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // 获取模拟用户数据
  UserModel _getMockUserData(String employeeId) {
    switch (employeeId) {
      case 'ADM001':
        return const UserModel(
          id: '1',
          employeeId: 'ADM001',
          name: '系统管理员',
          email: 'admin@company.com',
          role: 'admin',
          department: 'IT部门',
          permissions: ['picking_verification', 'order_verification', 'platform_receiving', 'line_delivery', 'admin'],
        );
      case 'OPR001':
        return const UserModel(
          id: '2',
          employeeId: 'OPR001',
          name: '操作员',
          email: 'operator@company.com',
          role: 'operator',
          department: '生产部门',
          permissions: ['picking_verification', 'order_verification'],
        );
      case 'QC001':
        return const UserModel(
          id: '3',
          employeeId: 'QC001',
          name: '质检员',
          email: 'qc@company.com',
          role: 'qc',
          department: '质检部门',
          permissions: ['picking_verification', 'order_verification', 'platform_receiving'],
        );
      case 'MGR001':
        return const UserModel(
          id: '4',
          employeeId: 'MGR001',
          name: '生产经理',
          email: 'manager@company.com',
          role: 'manager',
          department: '生产部门',
          permissions: ['picking_verification', 'order_verification', 'platform_receiving', 'line_delivery'],
        );
      case 'WRK001':
        return const UserModel(
          id: '5',
          employeeId: 'WRK001',
          name: '工人',
          email: 'worker@company.com',
          role: 'worker',
          department: '生产部门',
          permissions: ['picking_verification'],
        );
      default:
        return const UserModel(
          id: '999',
          employeeId: 'GUEST',
          name: '访客用户',
          email: 'guest@company.com',
          role: 'guest',
          department: '临时',
          permissions: [],
        );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.dio.post('/api/v1/auth/logout');
      debugPrint('真实API登出成功');
    } catch (e) {
      // Logout API failure is not critical - we'll clear local data anyway
      debugPrint('Logout API call failed: $e');
    }
  }
}