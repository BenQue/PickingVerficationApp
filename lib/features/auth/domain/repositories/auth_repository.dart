import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String employeeId, String password);
  Future<void> logout();
  Future<String?> getStoredToken();
  Future<UserEntity?> getCurrentUser();
  Future<void> storeUser(UserEntity user);
  Future<void> clearStoredData();
}