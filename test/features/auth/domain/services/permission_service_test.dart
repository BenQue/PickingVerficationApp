import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/auth/domain/entities/user_entity.dart';
import 'package:picking_verification_app/features/auth/domain/entities/permission.dart';
import 'package:picking_verification_app/features/auth/domain/services/permission_service.dart';

void main() {
  late PermissionService permissionService;

  setUp(() {
    permissionService = PermissionService();
  });

  group('PermissionService', () {
    group('getInitialRoute', () {
      test('should return /login for user with no permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: [],
          token: 'test_token',
        );

        // Act
        final result = permissionService.getInitialRoute(user);

        // Assert
        expect(result, '/login');
      });

      test('should return direct route for user with single permission', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification'],
          token: 'test_token',
        );

        // Act
        final result = permissionService.getInitialRoute(user);

        // Assert
        expect(result, '/picking-verification');
      });

      test('should return /home for user with multiple permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification', 'platform_receiving'],
          token: 'test_token',
        );

        // Act
        final result = permissionService.getInitialRoute(user);

        // Assert
        expect(result, '/home');
      });

      test('should return /home for fallback case', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['unknown_permission'],
          token: 'test_token',
        );

        // Act
        final result = permissionService.getInitialRoute(user);

        // Assert
        expect(result, '/home');
      });
    });

    group('canAccessRoute', () {
      test('should allow access to public routes', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: [],
          token: 'test_token',
        );

        // Act & Assert
        expect(permissionService.canAccessRoute(user, '/home'), true);
        expect(permissionService.canAccessRoute(user, '/login'), true);
        expect(permissionService.canAccessRoute(user, '/tasks'), true);
      });

      test('should allow access to routes with matching permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification', 'platform_receiving'],
          token: 'test_token',
        );

        // Act & Assert
        expect(permissionService.canAccessRoute(user, '/picking-verification'), true);
        expect(permissionService.canAccessRoute(user, '/platform-receiving'), true);
        expect(permissionService.canAccessRoute(user, '/line-delivery'), false);
      });

      test('should deny access to routes without matching permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification'],
          token: 'test_token',
        );

        // Act & Assert
        expect(permissionService.canAccessRoute(user, '/platform-receiving'), false);
        expect(permissionService.canAccessRoute(user, '/line-delivery'), false);
      });

      test('should deny access to unknown routes', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification'],
          token: 'test_token',
        );

        // Act & Assert
        expect(permissionService.canAccessRoute(user, '/unknown-route'), false);
      });
    });

    group('getNavigationOptions', () {
      test('should return empty list for user with no permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: [],
          token: 'test_token',
        );

        // Act
        final result = permissionService.getNavigationOptions(user);

        // Assert
        expect(result, isEmpty);
      });

      test('should return navigation options for user permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification', 'platform_receiving'],
          token: 'test_token',
        );

        // Act
        final result = permissionService.getNavigationOptions(user);

        // Assert
        expect(result, hasLength(2));
        expect(result[0].permission, Permission.pickingVerification);
        expect(result[0].title, '合箱校验');
        expect(result[0].route, '/picking-verification');
        expect(result[1].permission, Permission.platformReceiving);
        expect(result[1].title, '平台收料');
        expect(result[1].route, '/platform-receiving');
      });

      test('should handle unknown permissions gracefully', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['unknown_permission', 'picking_verification'],
          token: 'test_token',
        );

        // Act
        final result = permissionService.getNavigationOptions(user);

        // Assert
        expect(result, hasLength(1));
        expect(result[0].permission, Permission.pickingVerification);
      });
    });

    group('shouldShowHomeScreen', () {
      test('should return false for user with no permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: [],
          token: 'test_token',
        );

        // Act
        final result = permissionService.shouldShowHomeScreen(user);

        // Assert
        expect(result, false);
      });

      test('should return false for user with single permission', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification'],
          token: 'test_token',
        );

        // Act
        final result = permissionService.shouldShowHomeScreen(user);

        // Assert
        expect(result, false);
      });

      test('should return true for user with multiple permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification', 'platform_receiving'],
          token: 'test_token',
        );

        // Act
        final result = permissionService.shouldShowHomeScreen(user);

        // Assert
        expect(result, true);
      });
    });

    group('validatePermissions', () {
      test('should return true when user has all required permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification', 'platform_receiving', 'line_delivery'],
          token: 'test_token',
        );

        // Act
        final result = permissionService.validatePermissions(
          user, 
          [Permission.pickingVerification, Permission.platformReceiving],
        );

        // Assert
        expect(result, true);
      });

      test('should return false when user is missing required permissions', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: ['picking_verification'],
          token: 'test_token',
        );

        // Act
        final result = permissionService.validatePermissions(
          user, 
          [Permission.pickingVerification, Permission.platformReceiving],
        );

        // Assert
        expect(result, false);
      });

      test('should return true for empty required permissions list', () {
        // Arrange
        const user = UserEntity(
          id: '1',
          employeeId: 'EMP001',
          name: 'Test User',
          permissions: [],
          token: 'test_token',
        );

        // Act
        final result = permissionService.validatePermissions(user, []);

        // Assert
        expect(result, true);
      });
    });
  });

  group('Permission enum', () {
    test('should convert string values to enum correctly', () {
      expect(Permission.fromString('picking_verification'), Permission.pickingVerification);
      expect(Permission.fromString('platform_receiving'), Permission.platformReceiving);
      expect(Permission.fromString('line_delivery'), Permission.lineDelivery);
      expect(Permission.fromString('unknown'), null);
    });

    test('should provide correct display names', () {
      expect(Permission.pickingVerification.displayName, '合箱校验');
      expect(Permission.platformReceiving.displayName, '平台收料');
      expect(Permission.lineDelivery.displayName, '产线送料');
    });

    test('should provide correct route paths', () {
      expect(Permission.pickingVerification.routePath, '/picking-verification');
      expect(Permission.platformReceiving.routePath, '/platform-receiving');
      expect(Permission.lineDelivery.routePath, '/line-delivery');
    });
  });

  group('UserPermissions', () {
    test('should create from string list correctly', () {
      // Arrange
      final permissionStrings = ['picking_verification', 'unknown', 'platform_receiving'];

      // Act
      final userPermissions = UserPermissions.fromStrings(permissionStrings);

      // Assert
      expect(userPermissions.permissions, hasLength(2));
      expect(userPermissions.hasPermission(Permission.pickingVerification), true);
      expect(userPermissions.hasPermission(Permission.platformReceiving), true);
      expect(userPermissions.hasPermission(Permission.lineDelivery), false);
    });

    test('should correctly identify multiple vs single permissions', () {
      // Single permission
      final singlePermission = UserPermissions.fromStrings(['picking_verification']);
      expect(singlePermission.hasSinglePermission, true);
      expect(singlePermission.hasMultiplePermissions, false);
      expect(singlePermission.singlePermission, Permission.pickingVerification);

      // Multiple permissions
      final multiplePermissions = UserPermissions.fromStrings(['picking_verification', 'platform_receiving']);
      expect(multiplePermissions.hasSinglePermission, false);
      expect(multiplePermissions.hasMultiplePermissions, true);
      expect(multiplePermissions.singlePermission, null);

      // No permissions
      final noPermissions = UserPermissions.fromStrings([]);
      expect(noPermissions.hasNoPermissions, true);
      expect(noPermissions.hasSinglePermission, false);
      expect(noPermissions.hasMultiplePermissions, false);
    });
  });
}