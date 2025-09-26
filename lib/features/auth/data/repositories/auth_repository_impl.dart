import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_request_model.dart';
import '../models/user_model.dart';
import '../../../../core/api/dio_client.dart';
import 'dart:convert';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
  });

  @override
  Future<UserEntity> login(String employeeId, String password) async {
    final request = AuthRequestModel(
      employeeId: employeeId,
      password: password,
    );

    final response = await remoteDataSource.login(request);
    
    if (response.success) {
      // Store tokens separately in DioClient
      await DioClient().storeToken(response.accessToken);
      await DioClient().storeRefreshToken(response.refreshToken);
      
      // Store user info
      await storeUser(response.user.toEntity());
      return response.user.toEntity();
    } else {
      throw Exception(response.message);
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Call logout API endpoint
      await remoteDataSource.logout();
    } catch (e) {
      // Even if API call fails, clear local data
      debugPrint('Logout API call failed: $e');
    } finally {
      // Always clear stored data and DioClient tokens
      await clearStoredData();
      await DioClient().clearAllAuthData();
    }
  }

  @override
  Future<String?> getStoredToken() async {
    return await DioClient().getToken();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userJson = await secureStorage.read(key: _userKey);
    if (userJson != null) {
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(userMap).toEntity();
    }
    return null;
  }

  @override
  Future<void> storeUser(UserEntity user) async {
    final userModel = UserModel(
      id: user.id,
      employeeId: user.employeeId,
      name: user.name,
      email: '', // 默认值
      role: '', // 默认值
      department: '', // 默认值
      permissions: user.permissions,
    );
    
    await secureStorage.write(
      key: _userKey,
      value: jsonEncode(userModel.toJson()),
    );
  }

  @override
  Future<void> clearStoredData() async {
    await secureStorage.delete(key: _tokenKey);
    await secureStorage.delete(key: _userKey);
  }
}