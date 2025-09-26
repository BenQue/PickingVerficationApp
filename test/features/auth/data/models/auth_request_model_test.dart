import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/auth/data/models/auth_request_model.dart';

void main() {
  group('AuthRequestModel Tests', () {
    const testAuthRequest = AuthRequestModel(
      employeeId: 'EMP001',
      password: 'password123',
    );

    const testJson = {
      'employee_id': 'EMP001',
      'password': 'password123',
    };

    test('should create AuthRequestModel correctly', () {
      // Assert
      expect(testAuthRequest.employeeId, 'EMP001');
      expect(testAuthRequest.password, 'password123');
    });

    test('should convert AuthRequestModel to JSON', () {
      // Act
      final result = testAuthRequest.toJson();

      // Assert
      expect(result, testJson);
    });

    test('should support equality comparison', () {
      // Arrange
      const authRequest1 = AuthRequestModel(
        employeeId: 'EMP001',
        password: 'password123',
      );

      const authRequest2 = AuthRequestModel(
        employeeId: 'EMP001',
        password: 'password123',
      );

      const authRequest3 = AuthRequestModel(
        employeeId: 'EMP002',
        password: 'different_password',
      );

      // Assert
      expect(authRequest1, equals(authRequest2));
      expect(authRequest1, isNot(equals(authRequest3)));
    });
  });
}