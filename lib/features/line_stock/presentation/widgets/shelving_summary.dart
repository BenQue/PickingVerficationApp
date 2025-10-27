import 'package:flutter/material.dart';

/// Shelving Summary Widget
/// Displays transfer summary information
class ShelvingSummary extends StatelessWidget {
  final String? targetLocation;
  final int cableCount;

  const ShelvingSummary({
    super.key,
    required this.targetLocation,
    required this.cableCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '转移信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              '目标库位',
              targetLocation ?? '未设置',
              targetLocation != null,
            ),
            _buildSummaryRow(
              '转移数量',
              '$cableCount 个电缆',
              cableCount > 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isValid) {
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
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isValid ? Colors.black : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
