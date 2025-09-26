/// Enumeration of user permissions in the warehouse system
enum Permission {
  /// 合箱校验 - Picking verification permission
  pickingVerification('picking_verification'),
  
  /// 平台收料 - Platform receiving permission
  platformReceiving('platform_receiving'),
  
  /// 产线送料 - Line delivery permission
  lineDelivery('line_delivery'),
  
  /// 任务查看 - Task view permission (maps to TASK_VIEW)
  taskView('TASK_VIEW'),
  
  /// 订单查看 - Order view permission (maps to ORDER_VIEW)
  orderView('ORDER_VIEW'),
  
  /// 用户查看 - User view permission (maps to USER_VIEW) 
  userView('USER_VIEW'),
  
  /// 系统配置 - System config permission (maps to SYSTEM_CONFIG)
  systemConfig('SYSTEM_CONFIG');

  const Permission(this.value);
  
  /// The string value of the permission as received from API
  final String value;

  /// Convert string value to Permission enum
  static Permission? fromString(String value) {
    for (Permission permission in Permission.values) {
      if (permission.value == value) {
        return permission;
      }
    }
    return null;
  }

  /// Get display name in Chinese
  String get displayName {
    switch (this) {
      case Permission.pickingVerification:
        return '合箱校验';
      case Permission.platformReceiving:
        return '平台收料';
      case Permission.lineDelivery:
        return '产线送料';
      case Permission.taskView:
        return '任务管理';
      case Permission.orderView:
        return '订单管理';
      case Permission.userView:
        return '用户管理';
      case Permission.systemConfig:
        return '系统设置';
    }
  }

  /// Get the route path for this permission
  String get routePath {
    switch (this) {
      case Permission.pickingVerification:
        return '/picking-verification';
      case Permission.platformReceiving:
        return '/platform-receiving';
      case Permission.lineDelivery:
        return '/line-delivery';
      case Permission.taskView:
        return '/tasks';
      case Permission.orderView:
        return '/orders';
      case Permission.userView:
        return '/users';
      case Permission.systemConfig:
        return '/settings';
    }
  }
}

/// Helper class for managing user permissions
class UserPermissions {
  final List<Permission> permissions;

  const UserPermissions(this.permissions);

  /// Create from list of string values
  factory UserPermissions.fromStrings(List<String> permissionStrings) {
    final permissions = permissionStrings
        .map((str) => Permission.fromString(str))
        .where((p) => p != null)
        .cast<Permission>()
        .toList();
    return UserPermissions(permissions);
  }

  /// Check if user has a specific permission
  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  /// Check if user has multiple permissions
  bool get hasMultiplePermissions => permissions.length > 1;

  /// Check if user has single permission
  bool get hasSinglePermission => permissions.length == 1;

  /// Get the single permission if user has only one
  Permission? get singlePermission {
    return hasSinglePermission ? permissions.first : null;
  }

  /// Check if user has no permissions
  bool get hasNoPermissions => permissions.isEmpty;
}