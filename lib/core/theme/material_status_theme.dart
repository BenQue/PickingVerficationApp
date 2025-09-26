import 'package:flutter/material.dart';
import '../../features/picking_verification/domain/entities/material_item.dart';

/// Material status theme configuration
class MaterialStatusTheme {
  MaterialStatusTheme._();

  /// Get color for material status
  static Color getStatusColor(MaterialStatus status) {
    switch (status) {
      case MaterialStatus.pending:
        return Colors.grey.shade600;
      case MaterialStatus.inProgress:
        return Colors.orange.shade700;
      case MaterialStatus.completed:
        return Colors.green.shade700;
      case MaterialStatus.error:
        return Colors.red.shade700;
      case MaterialStatus.missing:
        return Colors.red.shade900;
    }
  }

  /// Get background color for material status (lighter variant)
  static Color getStatusBackgroundColor(MaterialStatus status) {
    switch (status) {
      case MaterialStatus.pending:
        return Colors.grey.shade100;
      case MaterialStatus.inProgress:
        return Colors.orange.shade50;
      case MaterialStatus.completed:
        return Colors.green.shade50;
      case MaterialStatus.error:
        return Colors.red.shade50;
      case MaterialStatus.missing:
        return Colors.red.shade100;
    }
  }

  /// Get icon for material status
  static IconData getStatusIcon(MaterialStatus status) {
    switch (status) {
      case MaterialStatus.pending:
        return Icons.access_time; // Clock icon
      case MaterialStatus.inProgress:
        return Icons.autorenew; // Progress spinner icon
      case MaterialStatus.completed:
        return Icons.check_circle; // Checkmark icon
      case MaterialStatus.error:
        return Icons.error_outline; // Error warning icon
      case MaterialStatus.missing:
        return Icons.cancel_outlined; // Missing/cross icon
    }
  }

  /// Get status display text in Chinese
  static String getStatusText(MaterialStatus status) {
    return status.label; // Already has Chinese labels from enum
  }

  /// PDA optimized text styles
  static const TextStyle titleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const TextStyle bodyLargeStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static const TextStyle bodyMediumStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const TextStyle labelStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  /// Minimum touch target size for PDA (44dp as per requirements)
  static const double minTouchTargetSize = 44.0;

  /// Standard padding for industrial PDA usage
  static const EdgeInsets itemPadding = EdgeInsets.all(12.0);
  static const EdgeInsets sectionPadding = EdgeInsets.all(16.0);

  /// Animation durations
  static const Duration expandAnimationDuration = Duration(milliseconds: 300);
  static const Duration statusChangeAnimationDuration = Duration(milliseconds: 200);
}