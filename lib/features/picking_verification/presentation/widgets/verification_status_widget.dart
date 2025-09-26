import 'package:flutter/material.dart';
import '../../domain/entities/picking_order.dart';

/// 校验状态指示器组件
class VerificationStatusWidget extends StatelessWidget {
  final PickingOrder order;
  final bool isModeActivated;

  const VerificationStatusWidget({
    super.key,
    required this.order,
    required this.isModeActivated,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStatusIndicators(),
            const SizedBox(height: 16),
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          isModeActivated ? Icons.verified : Icons.pending,
          color: isModeActivated ? Colors.green : Colors.orange,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          isModeActivated ? '校验状态' : '等待激活',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicators() {
    final totalItems = order.items.length;
    final verifiedItems = order.items.where((item) => item.isVerified).length;
    final matchedItems = order.items.where((item) => item.isQuantityMatched).length;

    return Column(
      children: [
        _buildStatusRow(
          '激活状态',
          isModeActivated ? '已激活' : '未激活',
          isModeActivated ? Colors.green : Colors.grey,
          isModeActivated ? Icons.check_circle : Icons.radio_button_unchecked,
        ),
        const SizedBox(height: 12),
        _buildStatusRow(
          '校验进度',
          '$verifiedItems / $totalItems 项',
          verifiedItems == totalItems ? Colors.green : Colors.orange,
          verifiedItems == totalItems ? Icons.check_circle : Icons.schedule,
        ),
        const SizedBox(height: 12),
        _buildStatusRow(
          '数量匹配',
          '$matchedItems / $totalItems 项',
          matchedItems == totalItems ? Colors.green : Colors.red,
          matchedItems == totalItems ? Icons.check_circle : Icons.warning,
        ),
        const SizedBox(height: 12),
        _buildStatusRow(
          '订单状态',
          _getStatusText(order.status),
          _getStatusColor(order.status),
          _getStatusIcon(order.status),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final totalItems = order.items.length;
    final verifiedItems = order.items.where((item) => item.isVerified).length;
    final progress = totalItems > 0 ? verifiedItems / totalItems : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '校验进度',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: progress == 1.0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress == 1.0 ? Colors.green : Colors.orange,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Text(
          progress == 1.0
              ? '所有商品已完成校验'
              : '已校验 $verifiedItems 项，还剩 ${totalItems - verifiedItems} 项',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return '待处理';
      case 'picking':
        return '拣货中';
      case 'verification':
        return '校验中';
      case 'completed':
        return '已完成';
      case 'cancelled':
        return '已取消';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'picking':
        return Colors.blue;
      case 'verification':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'picking':
        return Icons.shopping_cart;
      case 'verification':
        return Icons.verified_user;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}