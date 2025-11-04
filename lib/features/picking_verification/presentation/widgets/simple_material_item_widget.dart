import 'package:flutter/material.dart';
import '../../domain/entities/simple_picking_entities.dart';

/// 简化的物料项显示组件 - 只读显示，不可修改
class SimpleMaterialItemWidget extends StatelessWidget {
  final SimpleMaterial material;

  const SimpleMaterialItemWidget({
    Key? key,
    required this.material,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = material.isCompleted;
    final hasDataAnomaly = material.hasDataAnomaly;

    // 确定卡片状态：数据异常 > 已完成 > 未完成
    final Color cardColor;
    final Color statusColor;
    final IconData statusIcon;

    if (hasDataAnomaly) {
      // 数据异常：红色背景和错误图标
      cardColor = Colors.red.shade50;
      statusColor = Colors.red.shade700;
      statusIcon = Icons.error_outline;
    } else if (isCompleted) {
      // 已完成：绿色背景和对勾图标
      cardColor = Colors.green.shade50;
      statusColor = Colors.green;
      statusIcon = Icons.check;
    } else {
      // 未完成：橙色背景和关闭图标
      cardColor = Colors.orange.shade50;
      statusColor = Colors.orange;
      statusIcon = Icons.close;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 数据异常警告（如果存在）
            if (hasDataAnomaly)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !material.hasValidQuantity
                            ? '数据异常：需求数量为 0'
                            : '数据异常：物料信息不完整',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 物料代码和名称与状态指示器
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.materialCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        material.materialDesc,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                // 状态指示器 - 数据异常（红色错误） / 已完成（绿色✓） / 未完成（橙色✗）
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 数量信息 - 只读显示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuantityInfo(
                  label: '需求数量',
                  value: material.quantity.toString(),
                  color: hasDataAnomaly ? Colors.red.shade700 : theme.colorScheme.primary,
                ),
                _buildQuantityInfo(
                  label: '完成数量',
                  value: material.completedQuantity.toString(),
                  color: hasDataAnomaly ? Colors.red.shade700 : (isCompleted ? Colors.green : Colors.orange),
                ),
                _buildQuantityInfo(
                  label: '剩余数量',
                  value: material.remainingQuantity.toString(),
                  color: hasDataAnomaly ? Colors.red.shade700 : (material.remainingQuantity > 0 ? Colors.red : Colors.green),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityInfo({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}