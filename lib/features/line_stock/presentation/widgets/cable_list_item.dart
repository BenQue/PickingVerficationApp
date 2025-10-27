import 'package:flutter/material.dart';
import '../../domain/entities/cable_item.dart';

/// Cable list item widget for displaying a single cable in the shelving list
///
/// Features:
/// - Index indicator with circle avatar
/// - Cable barcode and material information
/// - Current location display
/// - Delete button with large touch target
/// - PDA-optimized font sizes and spacing
class CableListItem extends StatelessWidget {
  /// Position index in the list (0-based)
  final int index;

  /// The cable item to display
  final CableItem cable;

  /// Callback when delete button is pressed
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Index indicator
            Container(
              width: 44,
              height: 44,
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
                  // Barcode
                  Text(
                    cable.barcode,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Display info (material code + description)
                  Text(
                    cable.displayInfo,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 15,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Current location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '当前位置: ${cable.currentLocation}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 14,
                          color: colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete button with large touch target
            Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.delete_outline, size: 28),
                color: colorScheme.error,
                onPressed: onDelete,
                tooltip: '删除电缆',
                // Large touch target for gloved hands
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
