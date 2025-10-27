import 'package:flutter/material.dart';
import '../../domain/entities/line_stock_entity.dart';

/// Stock Information Card Widget
/// Displays detailed stock information
class StockInfoCard extends StatelessWidget {
  final LineStock stock;

  const StockInfoCard({
    super.key,
    required this.stock,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 物料信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('物料编码', stock.materialCode),
            _buildInfoRow('物料描述', stock.materialDesc),
            const Divider(height: 24),
            const Text(
              '📊 库存状态',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('当前数量', stock.quantityInfo),
            _buildInfoRow('批次号', stock.batchCode),
            _buildInfoRow('当前库位', stock.locationCode),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '• $label: ',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
