import 'package:flutter/material.dart';
import '../../domain/entities/cable_item.dart';

/// Cable list item widget for displaying a single cable in the shelving list
///
/// Features:
/// - Index indicator with circle avatar
/// - Swipe-to-delete gesture with confirmation
/// - Three-line display: material code, batch code, quantity
/// - PDA-optimized font sizes and spacing
class CableListItem extends StatelessWidget {
  /// Position index in the list (0-based)
  final int index;

  /// The cable item to display
  final CableItem cable;

  /// Callback when delete is confirmed
  final VoidCallback onDelete;

  const CableListItem({
    super.key,
    required this.index,
    required this.cable,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: Key(cable.barcode),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Show confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('确认删除'),
              content: Text(
                '确定要删除这盘电缆吗？\n\n物料：${cable.materialCode}\n批次：${cable.batchCode}'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  child: const Text('删除'),
                ),
              ],
            );
          },
        ) ?? false;
      },
      onDismissed: (direction) {
        onDelete();
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              color: colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '删除',
              style: TextStyle(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Index indicator
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Cable information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line 1: Material code (bold)
                    Row(
                      children: [
                        Text(
                          '物料：',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          cable.materialCode,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Line 2: Batch code
                    Text(
                      '批次：${cable.batchCode}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Line 3: Quantity with icon
                    Row(
                      children: [
                        Icon(
                          Icons.straighten,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '数量：${cable.quantity} ${cable.baseUnit}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Line 4: Current location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: colorScheme.tertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '当前库位：${cable.currentLocation}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            color: colorScheme.tertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
