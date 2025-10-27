import 'package:flutter/material.dart';

/// Error dialog with friendly error messages and optional retry action
class ErrorDialog extends StatelessWidget {
  /// Error message to display
  final String message;

  /// Whether to show a retry button
  final bool canRetry;

  /// Callback when retry button is pressed
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.message,
    this.canRetry = true,
    this.onRetry,
  });

  /// Show the error dialog
  static Future<void> show(
    BuildContext context, {
    required String message,
    bool canRetry = true,
    VoidCallback? onRetry,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !canRetry, // Only dismissible if no retry
      builder: (context) => ErrorDialog(
        message: message,
        canRetry: canRetry,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            '操作失败',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Error message
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              // Close button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text(
                    '关闭',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              // Retry button (if enabled)
              if (canRetry && onRetry != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onRetry!();
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text(
                      '重试',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
