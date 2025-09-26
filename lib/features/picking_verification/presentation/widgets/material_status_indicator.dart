import 'package:flutter/material.dart';
import '../../../../core/theme/material_status_theme.dart';
import '../../domain/entities/material_item.dart';

/// Widget to display material status with color and icon
class MaterialStatusIndicator extends StatelessWidget {
  final MaterialStatus status;
  final double iconSize;
  final bool showLabel;
  final bool compact;

  const MaterialStatusIndicator({
    Key? key,
    required this.status,
    this.iconSize = 24.0,
    this.showLabel = true,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = MaterialStatusTheme.getStatusColor(status);
    final icon = MaterialStatusTheme.getStatusIcon(status);
    final text = MaterialStatusTheme.getStatusText(status);
    final backgroundColor = MaterialStatusTheme.getStatusBackgroundColor(status);

    if (compact) {
      // Compact mode - just icon with colored background
      return Container(
        width: iconSize + 16,
        height: iconSize + 16,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2),
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: iconSize,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: iconSize,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              text,
              style: MaterialStatusTheme.bodyMediumStyle.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}