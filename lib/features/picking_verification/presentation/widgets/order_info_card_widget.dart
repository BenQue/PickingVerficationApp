import 'package:flutter/material.dart';
import '../../domain/entities/picking_order.dart';

/// 订单信息卡片组件
class OrderInfoCardWidget extends StatelessWidget {
  final PickingOrder order;
  final bool isActivated;
  final VoidCallback? onRefresh;

  const OrderInfoCardWidget({
    super.key,
    required this.order,
    required this.isActivated,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isActivated ? Colors.green.shade50 : Colors.blue.shade50,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildOrderDetails(),
            const SizedBox(height: 16),
            _buildItemSummary(),
            if (order.notes != null) ...[
              const SizedBox(height: 16),
              _buildNotes(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          isActivated ? Icons.check_circle : Icons.inventory_2,
          size: 32,
          color: isActivated ? Colors.green.shade700 : Colors.blue.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isActivated ? '合箱校验已激活' : '合箱校验作业',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isActivated) ...[
                const SizedBox(height: 4),
                Text(
                  '模式已激活，可以开始校验',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onRefresh,
            tooltip: '刷新订单信息',
          ),
      ],
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActivated ? Colors.green.shade200 : Colors.blue.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('订单号:', order.orderNumber, isMonospace: true),
          const SizedBox(height: 8),
          _buildDetailRow('订单状态:', _getStatusText(order.status)),
          const SizedBox(height: 8),
          _buildDetailRow('创建时间:', _formatDateTime(order.createdAt)),

          if (order.isVerified && order.verifiedAt != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow('校验时间:', _formatDateTime(order.verifiedAt!)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isMonospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isActivated ? Colors.green.shade700 : Colors.blue.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontFamily: isMonospace ? 'monospace' : null,
              fontWeight: isMonospace ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemSummary() {
    final totalItems = order.items.length;
    final verifiedItems = order.items.where((item) => item.isVerified).length;
    final totalQuantity = order.items.fold<int>(0, (sum, item) => sum + item.requiredQuantity);
    final pickedQuantity = order.items.fold<int>(0, (sum, item) => sum + item.pickedQuantity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '拣货汇总:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  '商品种类',
                  '$verifiedItems/$totalItems',
                  verifiedItems == totalItems ? Colors.green : Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  '拣货数量',
                  '$pickedQuantity/$totalQuantity',
                  pickedQuantity == totalQuantity ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildNotes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.yellow.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_alt,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '备注信息:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.notes!,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}