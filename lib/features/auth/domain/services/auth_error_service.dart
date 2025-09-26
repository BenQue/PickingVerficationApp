import 'package:dio/dio.dart';

/// Service for handling authentication and permission-related errors
/// Provides Chinese error messages and user-friendly feedback
class AuthErrorService {
  /// Convert exception to user-friendly Chinese message
  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      return _handleDioException(error);
    } else if (error is AuthException) {
      return error.message;
    } else if (error is PermissionException) {
      return error.message;
    } else {
      return '发生未知错误，请重试';
    }
  }

  /// Handle Dio network exceptions
  static String _handleDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络连接';
      case DioExceptionType.receiveTimeout:
        return '响应超时，请重试';
      case DioExceptionType.sendTimeout:
        return '发送超时，请重试';
      case DioExceptionType.unknown:
        return '网络连接失败，请检查网络设置';
      case DioExceptionType.cancel:
        return '请求已取消';
      case DioExceptionType.badResponse:
        return _handleHttpError(error.response?.statusCode ?? 0, error.response?.data);
      default:
        return '网络错误，请重试';
    }
  }

  /// Handle HTTP error responses
  static String _handleHttpError(int statusCode, dynamic responseData) {
    // Try to extract message from response
    String? serverMessage;
    if (responseData is Map<String, dynamic> && responseData.containsKey('message')) {
      serverMessage = responseData['message'] as String?;
    }

    switch (statusCode) {
      case 400:
        return serverMessage ?? '请求参数错误';
      case 401:
        return serverMessage ?? '认证失败，请重新登录';
      case 403:
        return serverMessage ?? '您没有执行此操作的权限';
      case 404:
        return serverMessage ?? '请求的资源不存在';
      case 409:
        return serverMessage ?? '操作冲突，请重试';
      case 422:
        return serverMessage ?? '提交的数据格式不正确';
      case 429:
        return serverMessage ?? '请求过于频繁，请稍后重试';
      case 500:
        return serverMessage ?? '服务器内部错误，请稍后重试';
      case 502:
        return serverMessage ?? '网关错误，请稍后重试';
      case 503:
        return serverMessage ?? '服务暂时不可用，请稍后重试';
      case 504:
        return serverMessage ?? '网关超时，请重试';
      default:
        return serverMessage ?? '服务器错误（$statusCode），请稍后重试';
    }
  }

  /// Get permission-specific error messages
  static String getPermissionErrorMessage(String route, List<String> userPermissions) {
    final routeNames = {
      '/picking-verification': '合箱校验',
      '/platform-receiving': '平台收料',
      '/line-delivery': '产线送料',
      '/home': '主页面',
      '/tasks': '任务列表',
    };

    final routeName = routeNames[route] ?? '该功能';
    
    if (userPermissions.isEmpty) {
      return '您还没有分配任何权限，请联系管理员';
    } else {
      return '您没有访问$routeName的权限\n当前权限：${_formatPermissions(userPermissions)}';
    }
  }

  /// Format permissions for display
  static String _formatPermissions(List<String> permissions) {
    final permissionNames = {
      'picking_verification': '合箱校验',
      'platform_receiving': '平台收料',
      'line_delivery': '产线送料',
    };

    return permissions
        .map((p) => permissionNames[p] ?? p)
        .join('、');
  }

  /// Check if error requires re-authentication
  static bool requiresReAuth(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 401;
    } else if (error is AuthException) {
      return error.requiresReAuth;
    }
    return false;
  }

  /// Check if error is a permission denial
  static bool isPermissionError(dynamic error) {
    if (error is DioException) {
      return error.response?.statusCode == 403;
    } else if (error is PermissionException) {
      return true;
    }
    return false;
  }
}

/// Custom exception for authentication errors
class AuthException implements Exception {
  final String message;
  final bool requiresReAuth;

  const AuthException({
    required this.message,
    this.requiresReAuth = false,
  });

  @override
  String toString() => 'AuthException: $message';
}

/// Custom exception for permission errors
class PermissionException implements Exception {
  final String message;
  final String route;
  final List<String> requiredPermissions;
  final List<String> userPermissions;

  const PermissionException({
    required this.message,
    required this.route,
    required this.requiredPermissions,
    required this.userPermissions,
  });

  @override
  String toString() => 'PermissionException: $message';
}

/// Custom exception for session timeout
class SessionTimeoutException extends AuthException {
  const SessionTimeoutException() : super(
    message: '登录会话已过期，请重新登录',
    requiresReAuth: true,
  );
}

/// Custom exception for token refresh failure
class TokenRefreshException extends AuthException {
  const TokenRefreshException() : super(
    message: '身份验证已过期，请重新登录',
    requiresReAuth: true,
  );
}