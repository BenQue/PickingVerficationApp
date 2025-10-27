import 'dart:async';
import 'package:flutter/material.dart';

/// Barcode input field optimized for PDA scanner devices
///
/// Features:
/// - Auto-focus on mount for immediate scanner input
/// - Debounce handling (100ms) to prevent double scans
/// - Auto-clear after successful scan
/// - Large font size (22sp) for easy reading on PDA
/// - Custom callback on barcode submission
class BarcodeInputField extends StatefulWidget {
  /// Label text for the input field
  final String label;

  /// Hint text shown when empty
  final String hint;

  /// Callback fired when a barcode is scanned/entered
  final ValueChanged<String> onSubmit;

  /// Whether to auto-focus on mount (default: true)
  final bool autofocus;

  /// Whether the input field is enabled
  final bool enabled;

  /// Optional prefix icon (default: qr_code_scanner)
  final IconData? prefixIcon;

  /// Optional TextEditingController for external control
  final TextEditingController? controller;

  const BarcodeInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.onSubmit,
    this.autofocus = true,
    this.enabled = true,
    this.prefixIcon,
    this.controller,
  });

  @override
  State<BarcodeInputField> createState() => _BarcodeInputFieldState();
}

class _BarcodeInputFieldState extends State<BarcodeInputField> {
  late TextEditingController _controller;
  Timer? _debounce;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    // Only dispose if we created the controller
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    if (_isProcessing) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Cancel previous debounce timer
    _debounce?.cancel();

    // Start new debounce timer (100ms)
    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (mounted && text.isNotEmpty) {
        _processScan(text);
      }
    });
  }

  void _processScan(String barcode) {
    if (!mounted || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Call the callback
    widget.onSubmit(barcode);

    // Clear the input field
    _controller.clear();

    // Reset processing flag after a short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled && !_isProcessing,
      autofocus: widget.autofocus,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: const TextStyle(fontSize: 18),
        hintText: widget.hint,
        hintStyle: const TextStyle(fontSize: 16),
        prefixIcon: Icon(
          widget.prefixIcon ?? Icons.qr_code_scanner,
          size: 32,
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 28),
                onPressed: _isProcessing
                    ? null
                    : () {
                        _controller.clear();
                      },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
      onSubmitted: (value) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty && !_isProcessing) {
          _processScan(trimmed);
        }
      },
    );
  }
}
