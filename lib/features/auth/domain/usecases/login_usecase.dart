import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase({required this.repository});

  Future<UserEntity> call(String employeeId, String password) async {
    return await repository.login(employeeId, password);
  }
}