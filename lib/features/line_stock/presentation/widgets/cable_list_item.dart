import 'package:flutter/material.dart';
import '../../domain/entities/cable_item.dart';

/// Cable List Item Widget
/// Displays a single cable item in the shelving list
class CableListItem extends StatelessWidget {
  final int index;
  final CableItem cable;
  final VoidCallback onDelete;

  const CableListItem({
    super.key,
    required this.index,
    required this.cable,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cable.barcode,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    cable.displayInfo,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '当前位置: ${cable.currentLocation}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
