import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/simple_picking_bloc.dart';
import 'simple_picking_screen.dart';
import '../../data/repositories/simple_picking_repository_impl.dart';
import '../../data/datasources/simple_picking_datasource.dart';
import '../../../../core/api/dio_client.dart';
import '../../../../core/theme/workbench_theme.dart';

/// 工作台首页 - 模拟登录后的主界面
class WorkbenchHomeScreen extends StatelessWidget {
  const WorkbenchHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WMS工作台',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // 用户信息 - 可点击查看版本
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () => _showUserInfo(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.white),
                  const SizedBox(width: 4),
                  const Text(
                    '操作员001',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 状态栏
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue.shade600, size: 24),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '当前时间',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        StreamBuilder(
                          stream: Stream.periodic(const Duration(seconds: 1)),
                          builder: (context, snapshot) {
                            final now = DateTime.now();
                            return Text(
                              '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '今日任务',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 功能区域
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      
                      // 物料拣配合箱功能组
                      _buildFunctionGroupHeader(
                        context,
                        icon: Icons.inventory_2,
                        title: '物料拣配合箱',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildMaterialPickingGroup(context),
                      
                      const SizedBox(height: 24),
                      
                      // 断线线边管理功能组
                      _buildFunctionGroupHeader(
                        context,
                        icon: Icons.cable,
                        title: '断线线边管理',
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildLineStockGroup(context),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  /// 构建启用的功能卡片 - 使用统一主题
  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return WorkbenchTheme.buildFeatureMenuCard(
      context: context,
      icon: icon,
      iconColor: color,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      backgroundColor: color.withOpacity(0.1),
    );
  }

  /// 构建禁用的功能卡片 - 使用统一主题
  Widget _buildDisabledFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color baseColor,
  }) {
    return WorkbenchTheme.buildDevelopingMenuCard(
      context: context,
      icon: icon,
      iconColor: baseColor,
      title: title,
    );
  }

  /// 构建功能组标题
  Widget _buildFunctionGroupHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建物料拣配合箱功能组
  Widget _buildMaterialPickingGroup(BuildContext context) {
    return Column(
      children: [
        // 第一行：合箱校验和订单查询
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context: context,
                icon: Icons.inventory_2,
                title: '合箱校验',
                subtitle: '工单物料拣配校验',
                color: const Color(0xFF2196F3), // 明亮蓝色 Material Blue 500
                onTap: () => _navigateToPickingVerification(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDisabledFeatureCard(
                context: context,
                icon: Icons.search,
                title: '订单查询',
                baseColor: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 第二行：平台收料和产线配送
        Row(
          children: [
            Expanded(
              child: _buildDisabledFeatureCard(
                context: context,
                icon: Icons.input,
                title: '平台收料',
                baseColor: const Color(0xFF2196F3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDisabledFeatureCard(
                context: context,
                icon: Icons.local_shipping,
                title: '产线配送',
                baseColor: const Color(0xFF2196F3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建断线线边管理功能组
  Widget _buildLineStockGroup(BuildContext context) {
    return Column(
      children: [
        // 第一行：电缆上架和电缆下架
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context: context,
                icon: Icons.upload,
                title: '电缆上架',
                subtitle: '电缆上架或转移',
                color: const Color(0xFFFF9800), // 明亮橙色 Material Orange 500
                onTap: () => _navigateToShelving(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                context: context,
                icon: Icons.download,
                title: '电缆下架',
                subtitle: '下架到线边库',
                color: const Color(0xFF9C27B0), // 明亮紫色 Material Purple 500
                onTap: () => _navigateToRemoval(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 第二行：电缆退库和库存查询
        Row(
          children: [
            Expanded(
              child: _buildDisabledFeatureCard(
                context: context,
                icon: Icons.unarchive,
                title: '电缆退库',
                baseColor: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                context: context,
                icon: Icons.search,
                title: '库存查询',
                subtitle: '扫码查询',
                color: const Color(0xFF4CAF50), // 明亮绿色 Material Green 500
                onTap: () => _navigateToStockQuery(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 显示用户信息和版本号 - 紧凑优化版
  void _showUserInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, 
                      color: Theme.of(context).colorScheme.primary, 
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '应用信息',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // 内容区
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 用户信息 - 紧凑版
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200, width: 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 28, color: Colors.blue.shade700),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '当前用户',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                '操作员001',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 应用信息 - 紧凑版
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.apps, size: 18, color: Colors.green.shade700),
                              const SizedBox(width: 6),
                              Text(
                                '应用名称',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Padding(
                            padding: EdgeInsets.only(left: 24),
                            child: Text(
                              '仓库应用',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.verified, size: 18, color: Colors.green.shade700),
                              const SizedBox(width: 6),
                              Text(
                                '版本号',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Padding(
                            padding: EdgeInsets.only(left: 24),
                            child: Text(
                              'V1.3.2',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 导航到库存查询功能
  void _navigateToStockQuery(BuildContext context) {
    context.go('/line-stock');
  }

  /// 导航到电缆上架功能
  void _navigateToShelving(BuildContext context) {
    context.go('/line-stock/shelving');
  }

  /// 导航到电缆下架功能
  void _navigateToRemoval(BuildContext context) {
    context.go('/line-stock/removal');
  }

  /// 导航到电缆退库功能
  void _navigateToReturn(BuildContext context) {
    context.go('/line-stock/return');
  }

  /// 导航到合箱校验功能
  void _navigateToPickingVerification(BuildContext context) {
    // 简化版直接导航到合箱校验界面，创建必要的依赖
    final dioClient = DioClient();
    final datasource = SimplePickingDataSource(dio: dioClient.dio);
    final repository = SimplePickingRepositoryImpl(dataSource: datasource);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => SimplePickingBloc(
            repository: repository,
          ),
          child: const SimplePickingScreen(),
        ),
      ),
    );
  }
}