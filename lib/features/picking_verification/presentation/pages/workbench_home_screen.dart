import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/simple_picking_bloc.dart';
import 'simple_picking_screen.dart';
import '../../data/repositories/simple_picking_repository_impl.dart';
import '../../data/datasources/simple_picking_datasource.dart';
import '../../../../core/api/dio_client.dart';

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
          // 模拟用户信息
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 4),
                Text(
                  '操作员001',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
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

  /// 构建启用的功能卡片
  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.9),
                color.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建禁用的功能卡片
  Widget _buildDisabledFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
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
        // 第一行：合箱校验
        _buildFeatureCard(
          context: context,
          icon: Icons.inventory_2,
          title: '合箱校验',
          subtitle: '扫描工单进行物料校验',
          color: Colors.blue,
          onTap: () => _navigateToPickingVerification(context),
        ),
        const SizedBox(height: 12),
        // 第二行：平台收料和产线配送
        Row(
          children: [
            Expanded(
              child: _buildDisabledFeatureCard(
                icon: Icons.input,
                title: '平台收料',
                subtitle: '暂未开放',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDisabledFeatureCard(
                icon: Icons.local_shipping,
                title: '产线配送',
                subtitle: '暂未开放',
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
        // 第一行：库存查询和电缆上架
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context: context,
                icon: Icons.search,
                title: '库存查询',
                subtitle: '扫码查询',
                color: Colors.green,
                onTap: () => _navigateToStockQuery(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                context: context,
                icon: Icons.upload,
                title: '电缆上架',
                subtitle: '断线上架',
                color: Colors.orange,
                onTap: () => _navigateToShelving(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 第二行：电缆退库（暂未开放）
        Row(
          children: [
            Expanded(
              child: _buildDisabledFeatureCard(
                icon: Icons.unarchive,
                title: '电缆退库',
                subtitle: '暂未开放',
              ),
            ),
            const SizedBox(width: 12),
            // 占位，保持对称
            Expanded(child: Container()),
          ],
        ),
      ],
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