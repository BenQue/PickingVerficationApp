import 'package:flutter/material.dart';
import '../../domain/entities/line_stock_entity.dart';

/// Stock information card widget
///
/// Displays detailed stock information in a card format optimized for PDA viewing
/// Includes material details, quantity info, batch code, and location
class StockInfoCard extends StatelessWidget {
  /// The line stock entity containing all stock information
  final LineStock stock;

  /// Optional callback when card is tapped
  final VoidCallback? onTap;

  const StockInfoCard({
    super.key,
    required this.stock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material Information Section
              Row(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '物料信息',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                label: '物料编码',
                value: stock.materialCode,
                valueStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                label: '物料描述',
                value: stock.materialDesc,
              ),

              const Divider(height: 32, thickness: 1),

              // Stock Status Section
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '库存状态',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                label: '当前数量',
                value: stock.quantityInfo,
                valueStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                label: '批次号',
                value: stock.batchCode,
                valueStyle: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                label: '当前库位',
                value: stock.locationCode,
                valueStyle: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}
