import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/domain/services/permission_service.dart';

/// Home screen for users with multiple permissions
/// Shows navigation options based on user's permissions
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          '工作台',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back button since we have bottom nav
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthSuccess) {
            return _buildHomeContent(context, state);
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context, AuthSuccess state) {
    final permissionService = context.read<PermissionService>();
    final navigationOptions = permissionService.getNavigationOptions(state.user);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User greeting
          _buildUserGreeting(state.user.name),
          const SizedBox(height: 32),
          
          // Permission-based navigation cards
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: navigationOptions.length,
              itemBuilder: (context, index) {
                final option = navigationOptions[index];
                return _buildNavigationCard(context, option);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGreeting(String userName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2196F3),
            child: Text(
              userName.isNotEmpty ? userName[0] : '用',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '您好',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(BuildContext context, NavigationOption option) {
    IconData iconData;
    Color cardColor;
    
    // Assign icons and colors based on permission type
    switch (option.permission.value) {
      case 'picking_verification':
        iconData = Icons.inventory_2_outlined;
        cardColor = const Color(0xFF4CAF50);
        break;
      case 'platform_receiving':
        iconData = Icons.local_shipping_outlined;
        cardColor = const Color(0xFFFF9800);
        break;
      case 'line_delivery':
        iconData = Icons.factory_outlined;
        cardColor = const Color(0xFF9C27B0);
        break;
      case 'TASK_VIEW':
        iconData = Icons.assignment_outlined;
        cardColor = const Color(0xFF2196F3);
        break;
      case 'ORDER_VIEW':
        iconData = Icons.receipt_long_outlined;
        cardColor = const Color(0xFFE91E63);
        break;
      case 'USER_VIEW':
        iconData = Icons.people_outline;
        cardColor = const Color(0xFF607D8B);
        break;
      case 'SYSTEM_CONFIG':
        iconData = Icons.settings_outlined;
        cardColor = const Color(0xFF795548);
        break;
      default:
        iconData = Icons.work_outline;
        cardColor = const Color(0xFF2196F3);
    }

    return InkWell(
      onTap: () {
        // Use GoRouter for navigation
        context.push(option.route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                iconData,
                size: 28,
                color: cardColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              option.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('您确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Listen for auth state changes and navigate to login when logged out
              context.read<AuthBloc>().stream.listen((state) {
                if (state is AuthUnauthenticated) {
                  // Navigate to login screen, replacing current route stack
                  context.go('/login');
                }
              });
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}