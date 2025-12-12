import 'package:flutter/material.dart';
import '../../domain/entities/handover_item.dart';

/// Widget displaying a single handover item in the receiving list
///
/// Shows:
/// - Material code and barcode
/// - Material description
/// - Batch code
/// - Quantity with unit
/// - Delete button
class HandoverListItem extends StatelessWidget {
  final HandoverItem item;
  final VoidCallback? onRemove;
  final int index;

  const HandoverListItem({
    super.key,
    required this.item,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: index, material code, and delete button
            Row(
              children: [
                // Index badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Material code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.materialCode,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '条码: ${item.barCode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete button
                if (onRemove != null)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: onRemove,
                    tooltip: '移除',
                  ),
              ],
            ),

            const Divider(height: 16),

            // Material description
            Text(
              item.materialDesc,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Bottom row: batch and quantity
            Row(
              children: [
                // Batch code
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '批次: ${item.batchCode}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Quantity with unit
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.quantityInfo,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
