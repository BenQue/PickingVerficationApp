import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wrapper widget that provides bottom navigation for main app screens
class BottomNavigationWrapper extends StatelessWidget {
  const BottomNavigationWrapper({
    super.key,
    required this.child,
  });

  /// The current page to display
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            offset: Offset(0, -1),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                label: '首页',
                isActive: currentRoute == '/home',
                onTap: () {
                  if (currentRoute != '/home') {
                    context.go('/home');
                  }
                },
              ),
              _buildNavItem(
                context,
                icon: Icons.task_alt,
                label: '我的任务',
                isActive: currentRoute == '/tasks',
                onTap: () {
                  if (currentRoute != '/tasks') {
                    context.go('/tasks');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final color = isActive ? const Color(0xFF2196F3) : Colors.grey;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}