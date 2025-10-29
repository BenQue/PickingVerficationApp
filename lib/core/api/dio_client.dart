import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Global Dio client for API requests with authentication interceptor
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  /// Get appropriate base URL based on platform and connection type
  static String get _baseUrl {
    // Use the real API server URL with IP address from documentation
    return 'http://10.163.130.173:8001';
  }

  /// Alternative URL for real devices (when primary URL fails)
  static const String _deviceBaseUrl = 'http://10.163.130.173:8001';
  static const _secureStorage = FlutterSecureStorage();

  Dio? _dio;
  bool _isRefreshing = false;
  String _currentBaseUrl = _baseUrl;

  Dio get dio {
    if (_dio == null) {
      throw StateError('DioClient must be initialized before use. Call initialize() first.');
    }
    return _dio!;
  }

  void initialize() {
    // Allow multiple calls to initialize() safely
    if (_dio != null) return;
    
    _dio = Dio(BaseOptions(
      baseUrl: _currentBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      // Accept 400 as valid response for business logic errors
      validateStatus: (status) {
        return status != null && status >= 200 && status < 500;
      },
    ));

    // Add all interceptors
    _addInterceptors();
  }

  /// Store authentication token securely
  Future<void> storeToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  /// Retrieve authentication token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }

  /// Clear authentication token
  Future<void> clearToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }

  /// Store refresh token securely
  Future<void> storeRefreshToken(String refreshToken) async {
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: 'refresh_token');
  }

  /// Clear refresh token
  Future<void> clearRefreshToken() async {
    await _secureStorage.delete(key: 'refresh_token');
  }

  /// Clear all authentication data
  Future<void> clearAllAuthData() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'refresh_token');
  }

  /// Refresh authentication token
  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;
    
    _isRefreshing = true;
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio!.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await storeToken(data['access_token']);
        if (data['refresh_token'] != null) {
          await storeRefreshToken(data['refresh_token']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Try to connect to alternative base URL if current one fails
  Future<bool> switchToDeviceUrl() async {
    if (Platform.isAndroid && _currentBaseUrl != _deviceBaseUrl) {
      try {
        debugPrint('尝试切换到设备IP: $_deviceBaseUrl');
        _currentBaseUrl = _deviceBaseUrl;
        
        // Recreate Dio instance with new base URL
        _dio = Dio(BaseOptions(
          baseUrl: _currentBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          // Accept 400 as valid response for business logic errors
          validateStatus: (status) {
            return status != null && status >= 200 && status < 500;
          },
        ));

        // Re-add interceptors
        _addInterceptors();
        
        // Test connection with health check
        final response = await _dio!.get('/health');
        if (response.statusCode == 200) {
          debugPrint('成功连接到设备IP: $_deviceBaseUrl');
          return true;
        }
      } catch (e) {
        debugPrint('无法连接到设备IP: $e');
      }
    }
    return false;
  }

  /// Add interceptors to Dio instance
  void _addInterceptors() {
    // Add authentication interceptor
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach token to requests
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle token expiration and refresh
          if (error.response?.statusCode == 401 && !_isRefreshing) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              // Retry the original request with new token
              final newToken = await getToken();
              if (newToken != null) {
                error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio!.fetch(error.requestOptions);
                handler.resolve(response);
                return;
              }
            }
            // If refresh failed, clear stored token
            await clearToken();
          }
          handler.next(error);
        },
      ),
    );

    // Add logging interceptor for debug builds
    _dio!.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }
}