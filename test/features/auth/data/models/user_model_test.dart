import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/auth/data/models/user_model.dart';
import 'package:picking_verification_app/features/auth/domain/entities/user_entity.dart';

void main() {
  group('UserModel Tests', () {
    const testUserModel = UserModel(
      id: '1',
      employeeId: 'EMP001',
      name: 'Test User',
      permissions: ['picking_verification', 'platform_receiving'],
      token: 'test_token_12345',
    );

    const testJson = {
      'id': '1',
      'employee_id': 'EMP001',
      'name': 'Test User',
      'permissions': ['picking_verification', 'platform_receiving'],
      'token': 'test_token_12345',
    };

    test('should create UserModel from JSON', () {
      // Act
      final result = UserModel.fromJson(testJson);

      // Assert
      expect(result.id, '1');
      expect(result.employeeId, 'EMP001');
      expect(result.name, 'Test User');
      expect(result.permissions, ['picking_verification', 'platform_receiving']);
      expect(result.token, 'test_token_12345');
    });

    test('should convert UserModel to JSON', () {
      // Act
      final result = testUserModel.toJson();

      // Assert
      expect(result, testJson);
    });

    test('should convert UserModel to UserEntity', () {
      // Act
      final result = testUserModel.toEntity();

      // Assert
      expect(result, isA<UserEntity>());
      expect(result.id, testUserModel.id);
      expect(result.employeeId, testUserModel.employeeId);
      expect(result.name, testUserModel.name);
      expect(result.permissions, testUserModel.permissions);
      expect(result.token, testUserModel.token);
    });

    test('should support equality comparison', () {
      // Arrange
      const userModel1 = UserModel(
        id: '1',
        employeeId: 'EMP001',
        name: 'Test User',
        permissions: ['picking_verification'],
        token: 'token',
      );

      const userModel2 = UserModel(
        id: '1',
        employeeId: 'EMP001',
        name: 'Test User',
        permissions: ['picking_verification'],
        token: 'token',
      );

      const userModel3 = UserModel(
        id: '2',
        employeeId: 'EMP002',
        name: 'Different User',
        permissions: ['platform_receiving'],
        token: 'different_token',
      );

      // Assert
      expect(userModel1, equals(userModel2));
      expect(userModel1, isNot(equals(userModel3)));
    });
  });
}