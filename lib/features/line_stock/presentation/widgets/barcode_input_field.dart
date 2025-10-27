import 'package:flutter/material.dart';
import 'dart:async';

/// Barcode Input Field Widget
/// Specialized input field for barcode scanning
class BarcodeInputField extends StatefulWidget {
  final String label;
  final String hint;
  final Function(String) onSubmit;
  final bool autofocus;
  final bool enabled;

  const BarcodeInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.onSubmit,
    this.autofocus = true,
    this.enabled = true,
  });

  @override
  State<BarcodeInputField> createState() => _BarcodeInputFieldState();
}

class _BarcodeInputFieldState extends State<BarcodeInputField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      style: const TextStyle(fontSize: 20),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.qr_code_scanner, size: 28),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => _controller.clear(),
        ),
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 100), () {
          if (value.isNotEmpty) {
            widget.onSubmit(value);
            _controller.clear();
          }
        });
      },
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          widget.onSubmit(value);
          _controller.clear();
        }
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
