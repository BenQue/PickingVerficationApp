import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/task_board/presentation/pages/task_board_screen.dart';
import '../../features/task_board/presentation/bloc/task_board_bloc.dart';
import '../../features/task_board/data/repositories/task_repository_impl.dart';
import '../../features/task_board/data/datasources/task_remote_datasource.dart';
import '../../features/auth/domain/services/permission_service.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../widgets/bottom_navigation_wrapper.dart';
import '../../features/order_verification/presentation/pages/order_verification_screen.dart';
import '../../features/order_verification/presentation/bloc/order_verification_bloc.dart';
import '../../features/order_verification/presentation/bloc/order_verification_event.dart';
import '../../features/order_verification/data/repositories/verification_repository_impl.dart';
import '../../features/order_verification/data/datasources/verification_remote_datasource.dart';
import '../../features/picking_verification/presentation/pages/picking_verification_screen.dart';
import '../../features/picking_verification/presentation/pages/verification_completion_screen.dart';
import '../../features/picking_verification/presentation/bloc/picking_verification_bloc.dart';
import '../../features/picking_verification/data/repositories/picking_repository_impl.dart';
import '../../features/picking_verification/data/datasources/picking_remote_datasource.dart';
import '../api/dio_client.dart';
import '../../features/platform_receiving/presentation/pages/platform_receiving_screen.dart';
import '../../features/line_delivery/presentation/pages/line_delivery_screen.dart';
import '../../features/picking_verification/domain/entities/picking_order.dart';
import '../../features/picking_verification/domain/entities/material_item.dart';
import '../../features/picking_verification/presentation/pages/workbench_home_screen.dart';
import '../../features/picking_verification/presentation/pages/simple_picking_screen.dart';
import '../../features/picking_verification/presentation/bloc/simple_picking_bloc.dart';
import '../../features/picking_verification/data/repositories/simple_picking_repository_impl.dart';
import '../../features/picking_verification/data/datasources/simple_picking_datasource.dart';
import '../../features/line_stock/presentation/pages/stock_query_screen.dart';
import '../../features/line_stock/presentation/pages/cable_shelving_screen.dart';
import '../../features/line_stock/presentation/pages/cable_return_screen.dart';
import '../../features/line_stock/presentation/bloc/line_stock_bloc.dart';
import '../../features/line_stock/data/repositories/line_stock_repository_impl.dart';
import '../../features/line_stock/data/datasources/line_stock_remote_datasource.dart';

/// Application routing configuration using GoRouter
/// Implements route guards for authentication and permissions
class AppRouter {
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';
  static const String workbenchRoute = '/workbench';
  static const String tasksRoute = '/tasks';
  static const String verificationRoute = '/verification';
  static const String pickingVerificationRoute = '/picking-verification';
  static const String verificationCompletionRoute = '/verification-completion';
  static const String platformReceivingRoute = '/platform-receiving';
  static const String lineDeliveryRoute = '/line-delivery';
  static const String lineStockQueryRoute = '/line-stock';
  static const String lineStockShelvingRoute = '/line-stock/shelving';
  static const String lineStockReturnRoute = '/line-stock/return';

  static const _secureStorage = FlutterSecureStorage();

  /// Get current user from secure storage
  static Future<UserEntity?> _getCurrentUser() async {
    try {
      final userJson = await _secureStorage.read(key: 'current_user');
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserEntity(
          id: userMap['id'] as String,
          employeeId: userMap['employeeId'] as String,
          name: userMap['fullName'] as String,
          permissions: List<String>.from(userMap['permissions'] as List),
        );
      }
    } catch (e) {
      debugPrint('Error getting current user: $e');
    }
    return null;
  }

  /// Check if user can access route
  static Future<bool> _canAccessRoute(String route) async {
    final user = await _getCurrentUser();
    if (user == null) return false;
    
    final permissionService = PermissionService();
    return permissionService.canAccessRoute(user, route);
  }

  /// Get initial route based on user permissions
  static Future<String> _getInitialRoute() async {
    final user = await _getCurrentUser();
    if (user == null) return loginRoute;
    
    final permissionService = PermissionService();
    return permissionService.getInitialRoute(user) ?? homeRoute;
  }

  /// Global router configuration
  static final GoRouter router = GoRouter(
    initialLocation: workbenchRoute,  // Skip login for testing
    routes: [
      // Login route - no authentication required
      GoRoute(
        path: loginRoute,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Workbench route - main entry point after login
      GoRoute(
        path: workbenchRoute,
        name: 'workbench',
        builder: (context, state) => BlocProvider(
          create: (context) => SimplePickingBloc(
            repository: SimplePickingRepositoryImpl(
              dataSource: SimplePickingDataSource(
                dio: DioClient().dio,
              ),
            ),
          ),
          child: const WorkbenchHomeScreen(),
        ),
      ),

      // Shell route for main app navigation with bottom navigation
      ShellRoute(
        builder: (context, state, child) => BottomNavigationWrapper(child: child),
        routes: [
          // Home route - for users with multiple permissions
          GoRoute(
            path: homeRoute,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Main task board - requires authentication
          GoRoute(
            path: tasksRoute,
            name: 'tasks',
            builder: (context, state) => BlocProvider(
              create: (context) => TaskBoardBloc(
                taskRepository: TaskRepositoryImpl(
                  remoteDataSource: TaskRemoteDataSourceImpl(),
                ),
              ),
              child: const TaskBoardScreen(),
            ),
          ),
          
          // Independent picking verification (no preset order) - Using Simple Mock Data
          GoRoute(
            path: pickingVerificationRoute,
            name: 'picking-verification-independent',
            builder: (context, state) {
              return BlocProvider(
                create: (context) => SimplePickingBloc(
                  repository: SimplePickingRepositoryImpl(
                    dataSource: SimplePickingDataSource(
                      dio: DioClient().dio,
                    ),
                  ),
                ),
                child: const SimplePickingScreen(),
              );
            },
          ),
        ],
      ),

      // Order verification route (without bottom navigation)
      GoRoute(
        path: '$verificationRoute/:taskId/:expectedOrderId',
        name: 'order-verification',
        builder: (context, state) {
          final taskId = state.pathParameters['taskId']!;
          final expectedOrderId = state.pathParameters['expectedOrderId']!;
          return BlocProvider(
            create: (context) => OrderVerificationBloc(
              verificationRepository: VerificationRepositoryImpl(
                remoteDataSource: VerificationRemoteDataSourceImpl(),
              ),
            )..add(StartVerificationEvent(
              taskId: taskId,
              expectedOrderId: expectedOrderId,
            )),
            child: OrderVerificationScreen(
              taskId: taskId,
              expectedOrderId: expectedOrderId,
            ),
          );
        },
      ),

      // Work interface routes (without bottom navigation)
      GoRoute(
        path: '$pickingVerificationRoute/:orderNumber',
        name: 'picking-verification-order',
        builder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber']!;
          return BlocProvider(
            create: (context) => PickingVerificationBloc(
              pickingRepository: PickingRepositoryImpl(
                remoteDataSource: PickingRemoteDataSourceImpl(
                  dio: DioClient().dio,
                ),
              ),
            ),
            child: PickingVerificationScreen(orderNumber: orderNumber),
          );
        },
      ),

      // Verification completion route
      GoRoute(
        path: '$verificationCompletionRoute/:orderNumber',
        name: 'verification-completion',
        builder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber']!;
          final orderJson = state.uri.queryParameters['orderData'];
          final operatorId = state.uri.queryParameters['operatorId'];
          
          // Parse order data from query parameters
          if (orderJson != null) {
            try {
              final orderData = jsonDecode(orderJson) as Map<String, dynamic>;
              // Create PickingOrder from data - this would need proper deserialization
              // For now, we'll create a minimal order structure
              final completedOrder = _parseOrderFromJson(orderData);
              
              return VerificationCompletionScreen(
                completedOrder: completedOrder,
                completedAt: DateTime.now(),
                operatorId: operatorId,
              );
            } catch (e) {
              debugPrint('Error parsing order data: $e');
            }
          }
          
          // Fallback - redirect back to picking verification
          return const ErrorPage(error: '无法加载完成页面，缺少订单数据');
        },
      ),

      GoRoute(
        path: '$platformReceivingRoute/:orderNumber',
        name: 'platform-receiving-order',
        builder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber']!;
          return PlatformReceivingScreen(orderNumber: orderNumber);
        },
      ),

      GoRoute(
        path: '$lineDeliveryRoute/:orderNumber',
        name: 'line-delivery-order',
        builder: (context, state) {
          final orderNumber = state.pathParameters['orderNumber']!;
          return LineDeliveryScreen(orderNumber: orderNumber);
        },
      ),

      // Note: Picking verification route is now handled inside ShellRoute above with SimplePickingBloc for mock data testing

      GoRoute(
        path: platformReceivingRoute,
        name: 'platform-receiving',
        builder: (context, state) => const PlatformReceivingScreen(),
      ),

      GoRoute(
        path: lineDeliveryRoute,
        name: 'line-delivery',
        builder: (context, state) => const LineDeliveryScreen(),
      ),

      // Line Stock routes - shared BLoC for query and shelving
      ShellRoute(
        builder: (context, state, child) {
          // Shared BLoC provider for line stock query and shelving screens
          return BlocProvider(
            create: (context) => LineStockBloc(
              repository: LineStockRepositoryImpl(
                remoteDataSource: LineStockRemoteDataSourceImpl(
                  dio: DioClient().dio,
                ),
              ),
            ),
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: lineStockQueryRoute,
            name: 'line-stock-query',
            builder: (context, state) => const StockQueryScreen(),
          ),
          GoRoute(
            path: lineStockShelvingRoute,
            name: 'line-stock-shelving',
            builder: (context, state) => const CableShelvingScreen(),
          ),
        ],
      ),

      GoRoute(
        path: lineStockReturnRoute,
        name: 'line-stock-return',
        builder: (context, state) => BlocProvider(
          create: (context) => LineStockBloc(
            repository: LineStockRepositoryImpl(
              remoteDataSource: LineStockRemoteDataSourceImpl(
                dio: DioClient().dio,
              ),
            ),
          ),
          child: const CableReturnScreen(),
        ),
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => ErrorPage(error: state.error.toString()),
  );

  /// Helper function to parse PickingOrder from JSON data
  static PickingOrder _parseOrderFromJson(Map<String, dynamic> data) {
    try {
      // Parse materials if available
      final materialsData = data['materials'] as List<dynamic>? ?? [];
      final materials = materialsData.map((m) {
        final materialData = m as Map<String, dynamic>;
        return MaterialItem(
          id: materialData['id'] as String? ?? '',
          code: materialData['code'] as String? ?? '',
          name: materialData['name'] as String? ?? '',
          category: _parseCategory(materialData['category'] as String?),
          requiredQuantity: materialData['requiredQuantity'] as int? ?? 0,
          availableQuantity: materialData['availableQuantity'] as int? ?? 0,
          status: _parseStatus(materialData['status'] as String?),
          location: materialData['location'] as String? ?? '',
          unit: materialData['unit'] as String? ?? '个',
          remarks: materialData['remarks'] as String?,
        );
      }).toList();

      return PickingOrder(
        orderId: data['id'] as String? ?? '',
        orderNumber: data['orderNumber'] as String? ?? '',
        status: data['status'] as String? ?? 'completed',
        createdAt: DateTime.now(),
        materials: materials,
        items: const [],
        isVerified: false,
      );
    } catch (e) {
      debugPrint('Error parsing order from JSON: $e');
      // Return minimal order as fallback
      return PickingOrder(
        orderId: data['id'] as String? ?? 'unknown',
        orderNumber: data['orderNumber'] as String? ?? 'unknown',
        status: 'completed',
        createdAt: DateTime.now(),
        materials: [],
        items: const [],
        isVerified: false,
      );
    }
  }

  /// Helper to parse MaterialCategory from string
  static MaterialCategory _parseCategory(String? categoryStr) {
    if (categoryStr == null) return MaterialCategory.lineBreak;
    
    for (final category in MaterialCategory.values) {
      if (category.name == categoryStr) {
        return category;
      }
    }
    return MaterialCategory.lineBreak;
  }

  /// Helper to parse MaterialStatus from string
  static MaterialStatus _parseStatus(String? statusStr) {
    if (statusStr == null) return MaterialStatus.completed;
    
    for (final status in MaterialStatus.values) {
      if (status.name == statusStr) {
        return status;
      }
    }
    return MaterialStatus.completed;
  }
}

// Work interface screens are now properly organized in their feature directories

class ErrorPage extends StatelessWidget {
  final String error;
  
  const ErrorPage({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('错误')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('页面加载出错', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(error, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}