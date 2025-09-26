import '../entities/permission.dart';
import '../entities/user_entity.dart';

/// Service for handling permission-related business logic
class PermissionService {
  /// Determine the appropriate route based on user permissions
  String? getInitialRoute(UserEntity user) {
    // If user has no permissions in raw data, redirect to login
    if (user.permissions.isEmpty) {
      return '/login';
    }
    
    final userPermissions = UserPermissions.fromStrings(user.permissions);
    
    // If user has single valid permission, go directly to that feature
    if (userPermissions.hasSinglePermission) {
      return userPermissions.singlePermission!.routePath;
    }
    
    // If user has multiple valid permissions, show home/navigation screen
    if (userPermissions.hasMultiplePermissions) {
      return '/home';
    }
    
    // Fallback to home for users with unrecognized permissions (they have permissions but none are valid)
    return '/home';
  }

  /// Check if user can access a specific route
  bool canAccessRoute(UserEntity user, String route) {
    final userPermissions = UserPermissions.fromStrings(user.permissions);
    
    // Always allow access to home, login, and tasks
    if (route == '/home' || route == '/login' || route == '/tasks') {
      return true;
    }
    
    // Check permission-specific routes
    for (Permission permission in Permission.values) {
      if (route == permission.routePath) {
        return userPermissions.hasPermission(permission);
      }
    }
    
    // Unknown routes are not accessible
    return false;
  }

  /// Get list of available navigation options for user
  List<NavigationOption> getNavigationOptions(UserEntity user) {
    final userPermissions = UserPermissions.fromStrings(user.permissions);
    final options = <NavigationOption>[];
    
    for (Permission permission in userPermissions.permissions) {
      options.add(NavigationOption(
        permission: permission,
        title: permission.displayName,
        route: permission.routePath,
      ));
    }
    
    return options;
  }

  /// Check if user should see the home navigation screen
  bool shouldShowHomeScreen(UserEntity user) {
    final userPermissions = UserPermissions.fromStrings(user.permissions);
    return userPermissions.hasMultiplePermissions;
  }

  /// Validate that user has required permissions
  bool validatePermissions(UserEntity user, List<Permission> requiredPermissions) {
    final userPermissions = UserPermissions.fromStrings(user.permissions);
    
    return requiredPermissions.every((required) => 
        userPermissions.hasPermission(required));
  }
}

/// Navigation option for home screen
class NavigationOption {
  final Permission permission;
  final String title;
  final String route;

  const NavigationOption({
    required this.permission,
    required this.title,
    required this.route,
  });
}