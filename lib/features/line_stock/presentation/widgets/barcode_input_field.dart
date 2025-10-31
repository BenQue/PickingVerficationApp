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
/// - Optional keyboard hiding for scanner-only mode
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

  /// Optional FocusNode for external focus control
  final FocusNode? focusNode;

  /// Minimum barcode length (default: 3)
  final int minLength;

  /// Whether to auto-submit on text change (default: false)
  /// When false, only submits on Enter key press
  final bool autoSubmitOnChange;

  /// Whether to show keyboard on focus (default: true)
  /// Set to false for PDA scanner-only mode
  final bool showKeyboard;

  /// Whether to enable text selection (default: true)
  final bool enableInteractiveSelection;

  /// Whether to make the field read-only (default: false)
  final bool readOnly;

  /// Whether to show cursor (default: true)
  final bool showCursor;

  const BarcodeInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.onSubmit,
    this.autofocus = true,
    this.enabled = true,
    this.prefixIcon,
    this.controller,
    this.focusNode,
    this.minLength = 3,
    this.autoSubmitOnChange = false,
    this.showKeyboard = true,
    this.enableInteractiveSelection = true,
    this.readOnly = false,
    this.showCursor = true,
  });

  @override
  State<BarcodeInputField> createState() => _BarcodeInputFieldState();
}

class _BarcodeInputFieldState extends State<BarcodeInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounce;
  bool _isProcessing = false;
  bool _shouldShowKeyboard = false; // Track if keyboard should be shown

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller.addListener(_onTextChanged);

    // Initialize keyboard state based on showKeyboard parameter
    _shouldShowKeyboard = widget.showKeyboard;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChanged);
    // Only dispose if we created the focus node
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    // Only dispose if we created the controller
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    // Call setState to rebuild and update clear button visibility
    if (mounted) {
      setState(() {});
    }

    // Only auto-submit if enabled
    if (!widget.autoSubmitOnChange) return;

    if (_isProcessing) return;

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Validate minimum length before processing
    if (text.length < widget.minLength) return;

    // Cancel previous debounce timer
    _debounce?.cancel();

    // Start new debounce timer (100ms)
    _debounce = Timer(const Duration(milliseconds: 100), () {
      if (mounted && text.isNotEmpty && text.length >= widget.minLength) {
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

    // Clear the input field after a delay ONLY if no external controller provided
    // If external controller is provided, let the parent handle clearing
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Only auto-clear if we own the controller
        if (widget.controller == null) {
          _controller.clear();
        }
        setState(() {
          _isProcessing = false;
        });
        // Reset keyboard state after processing (for PDA mode)
        if (!widget.showKeyboard) {
          _shouldShowKeyboard = false;
        }
      }
    });
  }

  void _onTap() {
    // When user manually taps the field, enable keyboard
    // This only applies when showKeyboard is false (PDA mode)
    if (!widget.showKeyboard && mounted) {
      setState(() {
        _shouldShowKeyboard = true;
      });
      
      // Request focus to show the keyboard
      if (!_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    }
  }

  void _toggleKeyboard() {
    if (!widget.showKeyboard && mounted) {
      setState(() {
        _shouldShowKeyboard = !_shouldShowKeyboard;
      });
      
      // Force keyboard to show/hide by manipulating focus
      if (_shouldShowKeyboard) {
        // To show keyboard: unfocus then refocus to trigger keyboard
        _focusNode.unfocus();
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            _focusNode.requestFocus();
          }
        });
      } else {
        // To hide keyboard: just unfocus
        _focusNode.unfocus();
      }
    }
  }

  Widget? _buildSuffixIcon() {
    // In PDA mode, show keyboard toggle button + clear button
    if (!widget.showKeyboard) {
      if (_controller.text.isNotEmpty) {
        // Show both keyboard toggle and clear button
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _shouldShowKeyboard ? Icons.keyboard_hide : Icons.keyboard,
                size: 24,
              ),
              tooltip: _shouldShowKeyboard ? '隐藏键盘' : '显示键盘',
              onPressed: _isProcessing ? null : _toggleKeyboard,
            ),
            IconButton(
              icon: const Icon(Icons.clear, size: 28),
              tooltip: '清空',
              onPressed: _isProcessing ? null : () => _controller.clear(),
            ),
          ],
        );
      } else {
        // Show only keyboard toggle button
        return IconButton(
          icon: Icon(
            _shouldShowKeyboard ? Icons.keyboard_hide : Icons.keyboard,
            size: 24,
          ),
          tooltip: _shouldShowKeyboard ? '隐藏键盘' : '显示键盘',
          onPressed: _isProcessing ? null : _toggleKeyboard,
        );
      }
    }
    
    // Normal mode: show only clear button when text is not empty
    if (_controller.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear, size: 28),
        tooltip: '清空',
        onPressed: _isProcessing ? null : () => _controller.clear(),
      );
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      enabled: widget.enabled && !_isProcessing,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      // Control keyboard display based on current state
      keyboardType: _shouldShowKeyboard ? TextInputType.text : TextInputType.none,
      onTap: _onTap, // Handle manual tap to show keyboard
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
        suffixIcon: _buildSuffixIcon(),
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
        if (trimmed.isNotEmpty && trimmed.length >= widget.minLength && !_isProcessing) {
          _processScan(trimmed);
        }
      },
    );
  }
}
