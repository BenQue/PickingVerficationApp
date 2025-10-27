import 'package:flutter/material.dart';

/// Shelving summary widget for displaying transfer information
///
/// Shows a summary card with:
/// - Target location code
/// - Number of cables to be transferred
/// - Visual indicators for valid/invalid states
class ShelvingSummary extends StatelessWidget {
  /// Target location code (null if not set)
  final String? targetLocation;

  /// Number of cables in the transfer list
  final int cableCount;

  const ShelvingSummary({
    super.key,
    required this.targetLocation,
    required this.cableCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasTarget = targetLocation != null && targetLocation!.isNotEmpty;
    final hasCables = cableCount > 0;
    final isReady = hasTarget && hasCables;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: isReady
          ? colorScheme.primaryContainer.withOpacity(0.3)
          : colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  isReady ? Icons.check_circle_outline : Icons.info_outline,
                  size: 24,
                  color: isReady ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '转移摘要',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target location
            _buildSummaryRow(
              context,
              icon: Icons.location_on_outlined,
              label: '目标库位',
              value: targetLocation ?? '未设置',
              isValid: hasTarget,
            ),
            const SizedBox(height: 12),

            // Cable count
            _buildSummaryRow(
              context,
              icon: Icons.cable,
              label: '电缆数量',
              value: hasCables ? '$cableCount 条' : '未添加',
              isValid: hasCables,
            ),

            // Status message
            if (!isReady) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.error.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !hasTarget
                            ? '请先设置目标库位'
                            : '请添加至少一条电缆',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isValid,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(
          icon,
          size: 22,
          color: isValid ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isValid ? colorScheme.onSurface : colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
