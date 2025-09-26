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
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isCompleted ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                // 完成状态指示器 - 绿色✓ 或 红色✗
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check : Icons.close,
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
                  color: theme.colorScheme.primary,
                ),
                _buildQuantityInfo(
                  label: '完成数量',
                  value: material.completedQuantity.toString(),
                  color: isCompleted ? Colors.green : Colors.orange,
                ),
                _buildQuantityInfo(
                  label: '剩余数量',
                  value: material.remainingQuantity.toString(),
                  color: material.remainingQuantity > 0 ? Colors.red : Colors.green,
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