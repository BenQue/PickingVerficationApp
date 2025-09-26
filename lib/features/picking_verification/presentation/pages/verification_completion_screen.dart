import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/picking_order.dart';
import '../../domain/entities/material_item.dart';

/// 校验完成屏幕
class VerificationCompletionScreen extends StatefulWidget {
  final PickingOrder completedOrder;
  final DateTime completedAt;
  final String? operatorId;

  const VerificationCompletionScreen({
    super.key,
    required this.completedOrder,
    required this.completedAt,
    this.operatorId,
  });

  @override
  State<VerificationCompletionScreen> createState() => _VerificationCompletionScreenState();
}

class _VerificationCompletionScreenState extends State<VerificationCompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // 开始动画
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          '校验完成',
          style: TextStyle(
            fontSize: 22.0, // PDA适配大字体
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 32.0),
                        
                        // 成功指示器
                        _buildSuccessIndicator(),
                        
                        const SizedBox(height: 32.0),
                        
                        // 订单完成摘要
                        _buildOrderSummary(),
                        
                        const SizedBox(height: 24.0),
                        
                        // 物料完成统计
                        _buildMaterialStatistics(),
                        
                        const SizedBox(height: 24.0),
                        
                        // 完成详情
                        _buildCompletionDetails(),
                        
                        const SizedBox(height: 32.0),
                      ],
                    ),
                  ),
                ),
                
                // 底部操作按钮
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建成功指示器
  Widget _buildSuccessIndicator() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 120.0, // PDA适配大图标
        height: 120.0,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 20.0,
              spreadRadius: 5.0,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_circle,
          size: 72.0, // PDA适配大图标
          color: Colors.green,
        ),
      ),
    );
  }

  /// 构建订单摘要
  Widget _buildOrderSummary() {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              '校验任务完成',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 24.0, // PDA适配大字体
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    '订单号',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16.0,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    widget.completedOrder.orderNumber,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28.0, // PDA适配大字体
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '生产线: ${widget.completedOrder.productionLineId ?? '未知'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18.0, // PDA适配大字体
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建物料统计
  Widget _buildMaterialStatistics() {
    final totalMaterials = widget.completedOrder.materials.length;
    final completedMaterials = widget.completedOrder.materials
        .where((m) => m.status == MaterialStatus.completed)
        .length;
    
    // 按类别统计
    final categoryStats = <MaterialCategory, Map<String, int>>{};
    for (final category in MaterialCategory.values) {
      final categoryMaterials = widget.completedOrder.materials
          .where((m) => m.category == category)
          .toList();
      final completedCount = categoryMaterials
          .where((m) => m.status == MaterialStatus.completed)
          .length;
      
      if (categoryMaterials.isNotEmpty) {
        categoryStats[category] = {
          'total': categoryMaterials.length,
          'completed': completedCount,
        };
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 28.0, // PDA适配大图标
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12.0),
                Text(
                  '完成统计',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20.0, // PDA适配大字体
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            
            // 总体统计
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('总物料', '$totalMaterials', Icons.inventory_2),
                  Container(
                    height: 40.0,
                    width: 1.0,
                    color: Colors.green.shade300,
                  ),
                  _buildStatItem('已完成', '$completedMaterials', Icons.check_circle),
                  Container(
                    height: 40.0,
                    width: 1.0,
                    color: Colors.green.shade300,
                  ),
                  _buildStatItem('完成率', '${((completedMaterials / totalMaterials) * 100).toInt()}%', Icons.trending_up),
                ],
              ),
            ),
            
            const SizedBox(height: 16.0),
            
            // 类别统计
            ...categoryStats.entries.map((entry) {
              final category = entry.key;
              final stats = entry.value;
              final total = stats['total']!;
              final completed = stats['completed']!;
              final percentage = ((completed / total) * 100).toInt();
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.label,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 16.0, // PDA适配大字体
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$completed/$total',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16.0, // PDA适配大字体
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      '$percentage%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14.0,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 构建统计项目
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32.0, // PDA适配大图标
          color: Colors.green.shade600,
        ),
        const SizedBox(height: 8.0),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 24.0, // PDA适配大字体
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 14.0,
            color: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  /// 构建完成详情
  Widget _buildCompletionDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 28.0, // PDA适配大图标
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12.0),
                Text(
                  '完成详情',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20.0, // PDA适配大字体
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            _buildDetailRow('完成时间', _formatDateTime(widget.completedAt)),
            if (widget.operatorId != null)
              _buildDetailRow('操作员', widget.operatorId!),
            _buildDetailRow('订单状态', '已完成校验'),
            _buildDetailRow('数据状态', '已提交到系统'),
          ],
        ),
      ),
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.0,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16.0, // PDA适配大字体
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 16.0, // PDA适配大字体
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // 返回任务列表
                  context.go('/task-board');
                },
                icon: const Icon(Icons.list_alt, size: 24.0),
                label: const Text('返回任务列表'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56.0), // PDA适配大按钮
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  textStyle: const TextStyle(
                    fontSize: 18.0, // PDA适配大字体
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // 开始新任务
                  context.go('/picking-verification');
                },
                icon: const Icon(Icons.add_task, size: 24.0),
                label: const Text('新任务'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56.0), // PDA适配大按钮
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  textStyle: const TextStyle(
                    fontSize: 18.0, // PDA适配大字体
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month.toString().padLeft(2, '0')}月${dateTime.day.toString().padLeft(2, '0')}日 '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}