import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/order_verification/domain/entities/verification_result.dart';

void main() {
  group('VerificationResult', () {
    test('should create VerificationResult with required properties', () {
      // Arrange
      const orderId = 'ORD123';
      const isValid = true;
      final verifiedAt = DateTime(2023, 12, 25, 10, 30);

      // Act
      final result = VerificationResult(
        orderId: orderId,
        isValid: isValid,
        verifiedAt: verifiedAt,
      );

      // Assert
      expect(result.orderId, equals(orderId));
      expect(result.isValid, equals(isValid));
      expect(result.errorMessage, isNull);
      expect(result.verifiedAt, equals(verifiedAt));
    });

    test('should create VerificationResult with error message', () {
      // Arrange
      const orderId = 'ORD123';
      const isValid = false;
      const errorMessage = '订单号不匹配';
      final verifiedAt = DateTime(2023, 12, 25, 10, 30);

      // Act
      final result = VerificationResult(
        orderId: orderId,
        isValid: isValid,
        errorMessage: errorMessage,
        verifiedAt: verifiedAt,
      );

      // Assert
      expect(result.orderId, equals(orderId));
      expect(result.isValid, equals(isValid));
      expect(result.errorMessage, equals(errorMessage));
      expect(result.verifiedAt, equals(verifiedAt));
    });

    test('should support equality comparison', () {
      // Arrange
      final verifiedAt = DateTime(2023, 12, 25, 10, 30);
      
      final result1 = VerificationResult(
        orderId: 'ORD123',
        isValid: true,
        verifiedAt: verifiedAt,
      );
      
      final result2 = VerificationResult(
        orderId: 'ORD123',
        isValid: true,
        verifiedAt: verifiedAt,
      );

      final result3 = VerificationResult(
        orderId: 'ORD456',
        isValid: true,
        verifiedAt: verifiedAt,
      );

      // Assert
      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
      expect(result1.hashCode, equals(result2.hashCode));
      expect(result1.hashCode, isNot(equals(result3.hashCode)));
    });

    test('should provide meaningful toString', () {
      // Arrange
      final verifiedAt = DateTime(2023, 12, 25, 10, 30);
      final result = VerificationResult(
        orderId: 'ORD123',
        isValid: true,
        verifiedAt: verifiedAt,
      );

      // Act
      final stringRepresentation = result.toString();

      // Assert
      expect(stringRepresentation, contains('VerificationResult'));
      expect(stringRepresentation, contains('ORD123'));
      expect(stringRepresentation, contains('true'));
    });
  });
}