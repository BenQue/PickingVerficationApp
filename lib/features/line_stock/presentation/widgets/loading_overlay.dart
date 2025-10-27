import 'package:flutter/material.dart';

/// Loading overlay widget that can be shown on top of other widgets
/// Provides a semi-transparent background with loading indicator
class LoadingOverlay extends StatelessWidget {
  /// Optional message to display below the loading indicator
  final String? message;

  /// Whether to show the overlay
  final bool isLoading;

  /// Child widget to display behind the overlay
  final Widget child;

  const LoadingOverlay({
    super.key,
    this.message,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 4,
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          message!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
