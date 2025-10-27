import 'package:flutter/material.dart';
import 'dart:async';

/// Success dialog with auto-dismiss and optional statistics display
class SuccessDialog extends StatefulWidget {
  /// Success message to display
  final String message;

  /// Optional statistics to display (e.g., "已转移 5 件物料")
  final Map<String, String>? statistics;

  /// Auto-dismiss duration (default: 2 seconds)
  final Duration autoDismissDuration;

  /// Callback when dialog is dismissed
  final VoidCallback? onDismissed;

  const SuccessDialog({
    super.key,
    required this.message,
    this.statistics,
    this.autoDismissDuration = const Duration(seconds: 2),
    this.onDismissed,
  });

  /// Show the success dialog with auto-dismiss
  static Future<void> show(
    BuildContext context, {
    required String message,
    Map<String, String>? statistics,
    Duration autoDismissDuration = const Duration(seconds: 2),
    VoidCallback? onDismissed,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        message: message,
        statistics: statistics,
        autoDismissDuration: autoDismissDuration,
        onDismissed: onDismissed,
      ),
    );
  }

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog> {
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    // Start auto-dismiss timer
    _autoDismissTimer = Timer(widget.autoDismissDuration, () {
      if (mounted) {
        Navigator.of(context).pop();
        widget.onDismissed?.call();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    super.dispose();
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
          // Success icon with animation
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green.shade700,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Title
          const Text(
            '操作成功',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),

          // Success message
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          // Statistics (if provided)
          if (widget.statistics != null && widget.statistics!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: widget.statistics!.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Manual close button
          TextButton(
            onPressed: () {
              _autoDismissTimer?.cancel();
              Navigator.of(context).pop();
              widget.onDismissed?.call();
            },
            child: const Text(
              '关闭',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
