import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../bloc/line_stock_bloc.dart';
import '../bloc/line_stock_event.dart';
import '../bloc/line_stock_state.dart';
import '../widgets/barcode_input_field.dart';
import '../widgets/cable_list_item.dart';
// ShelvingSummary widget removed - no longer needed

/// Cable shelving screen for transferring cables to a target location
///
/// Two-step workflow:
/// 1. Scan/enter target location code
/// 2. Scan/add cable barcodes to transfer list
/// 3. Review and confirm transfer
///
/// Features:
/// - Target location management
/// - Cable list with add/remove operations
/// - Transfer summary display
/// - Confirmation with success feedback
class CableShelvingScreen extends StatefulWidget {
  const CableShelvingScreen({super.key});

  @override
  State<CableShelvingScreen> createState() => _CableShelvingScreenState();
}

class _CableShelvingScreenState extends State<CableShelvingScreen> {
  final _locationController = TextEditingController();
  final _cableController = TextEditingController(); // Controller for cable barcode input
  bool _isLocationSet = false;
  int _previousCableCount = 0; // Track previous cable count to detect successful additions

  @override
  void initState() {
    super.initState();
    // Add listener to rebuild when location text changes
    _locationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _cableController.dispose();
    super.dispose();
  }

  /// Recursively find the ShelvingInProgress state from error chain
  ShelvingInProgress? _findShelvingState(LineStockState state) {
    if (state is ShelvingInProgress) {
      return state;
    }
    if (state is LineStockError && state.previousState != null) {
      return _findShelvingState(state.previousState!);
    }
    return null;
  }

  void _setTargetLocation() {
    final location = _locationController.text.trim();
    if (location.isNotEmpty) {
      context.read<LineStockBloc>().add(
            SetTargetLocation(location),
          );
      setState(() {
        _isLocationSet = true;
      });
    }
  }

  void _modifyTargetLocation() {
    // Clear location input and allow re-entry
    // BLoC will preserve cable list
    _locationController.clear();
    context.read<LineStockBloc>().add(const ModifyTargetLocation());
    setState(() {
      _isLocationSet = false;
    });
  }

  void _onCableScanned(String barcode) {
    context.read<LineStockBloc>().add(
          AddCableBarcode(barcode),
        );
  }

  void _onCableRemoved(String barcode) {
    context.read<LineStockBloc>().add(
          RemoveCableBarcode(barcode),
        );
  }

  void _clearAllCables() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有已添加的电缆吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              this.context.read<LineStockBloc>().add(const ClearCableList());
              Navigator.of(context).pop();
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _confirmShelving() {
    final state = context.read<LineStockBloc>().state;
    if (state is ShelvingInProgress && state.canSubmit) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认上架'),
          content: Text('确定要将 ${state.cableCount} 盘电缆转移到 ${state.targetLocation} 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                this.context.read<LineStockBloc>().add(
                      ConfirmShelving(
                        locationCode: state.targetLocation!,
                        barCodes: state.cableList.map((c) => c.barcode).toList(),
                      ),
                    );
                Navigator.of(context).pop();
              },
              child: const Text('确认'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('电缆上架'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/workbench'),
        ),
        actions: [
          // Reset button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '重置',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认重置'),
                  content: const Text('确定要重置所有数据吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        this.context.read<LineStockBloc>().add(
                              const ResetShelving(),
                            );
                        Navigator.of(context).pop();
                        this.context.pop(); // Go back to query screen
                      },
                      child: const Text('确认'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<LineStockBloc, LineStockState>(
        listener: (context, state) {
          // Handle error states - clear input and preserve previous state data
          if (state is LineStockError) {
            // Provide haptic feedback for errors
            HapticFeedback.mediumImpact();
            
            // Show snackbar for better visibility
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontSize: 16),
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: '知道了',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
            
            // Clear the input field on error
            _cableController.clear();
            // Don't update _previousCableCount - keep it to preserve state
          }

          // Handle successful cable addition by tracking cable count
          if (state is ShelvingInProgress) {
            if (state.cableCount > _previousCableCount) {
              // Successfully added a cable - dismiss any error snackbar
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              
              // Clear the input
              _cableController.clear();
              // Update previous count to new count
              _previousCableCount = state.cableCount;
            }
          }

          // Handle success states
          if (state is ShelvingSuccess) {
            _showSuccessDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is LineStockLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text(
                    state.message ?? '正在处理...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          // Recursively find the ShelvingInProgress state from error chain
          final displayState = _findShelvingState(state) ?? state;

          return SafeArea(
            child: Column(
              children: [
                // Step 1: Target Location Input (scrollable)
                if (!_isLocationSet)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildLocationInput(theme),
                    ),
                  )
                else
                  _buildLocationDisplay(displayState, theme),

                if (_isLocationSet) const Divider(height: 1),

                // Step 2: Cable List
                if (_isLocationSet) ...[
                  Expanded(
                    child: _buildCableListSection(displayState, theme),
                  ),

                  // Bottom action bar
                  _buildBottomActions(displayState, theme),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationInput(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warehouse,
                  color: theme.colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '设置目标库位',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '扫描或输入目标库位代码',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          BarcodeInputField(
            label: '目标库位',
            hint: '扫描或输入库位代码(至少4位)',
            controller: _locationController,
            prefixIcon: Icons.location_on,
            minLength: 4,
            autoSubmitOnChange: false,
            showKeyboard: false, // PDA模式: 禁用自动弹出键盘
            onSubmit: (_) => _setTargetLocation(),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: '确认库位',
            icon: Icons.check,
            onPressed: _locationController.text.trim().length >= 4
                ? _setTargetLocation
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDisplay(LineStockState state, ThemeData theme) {
    final shelvingState = state is ShelvingInProgress ? state : null;
    final location = shelvingState?.targetLocation ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '目标库位',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: _modifyTargetLocation,
            icon: const Icon(Icons.edit),
            label: const Text('修改'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCableListSection(LineStockState state, ThemeData theme) {
    if (state is! ShelvingInProgress) {
      return const SizedBox();
    }

    return Column(
      children: [
        // Barcode input (always visible at top, fixed position)
        Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // Reduced vertical padding
          child: BarcodeInputField(
            label: '扫描电缆条码',
            hint: '扫码枪扫描或手动输入13位条码',
            controller: _cableController, // Use controller for manual clearing
            onSubmit: _onCableScanned,
            minLength: 13,
            autoSubmitOnChange: false,
            showKeyboard: false, // PDA模式: 禁用自动弹出键盘
            enableInteractiveSelection: false, // 禁用文本选择
            readOnly: false, // 保持可编辑(扫码枪可输入)
            showCursor: true, // 显示光标
          ),
        ),

        const Divider(height: 1),

        // Cable list header with count (moved count to right side)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6), // Reduced padding
          child: Row(
            children: [
              Icon(
                Icons.cable,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '添加电缆',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: state.cableCount > 0
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.cableCount} 盘',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: state.cableCount > 0
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              if (state.cableCount > 0)
                TextButton.icon(
                  onPressed: _clearAllCables,
                  icon: Icon(Icons.clear_all, size: 20, color: theme.colorScheme.error),
                  label: Text('清空', style: TextStyle(color: theme.colorScheme.error)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ),

        // Cable list or empty state
        Expanded(
          child: state.cableList.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: state.cableList.length,
                  itemBuilder: (context, index) {
                    final cable = state.cableList[index];
                    return CableListItem(
                      index: index,
                      cable: cable,
                      onDelete: () => _onCableRemoved(cable.barcode),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cable,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无电缆',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请扫描电缆条码添加',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(LineStockState state, ThemeData theme) {
    // Recursively find the ShelvingInProgress state
    final shelvingState = _findShelvingState(state);

    if (shelvingState == null) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(12), // Reduced padding to save space
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning message if not ready to submit
            if (!shelvingState.canSubmit)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '请添加至少一盘电缆',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!shelvingState.canSubmit)
              const SizedBox(height: 12),

            // Confirm button
            PrimaryButton(
              text: '确认上架 (${shelvingState.cableCount} 盘)',
              icon: Icons.check_circle,
              onPressed: shelvingState.canSubmit ? _confirmShelving : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, ShelvingSuccess state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            const Text('上架成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目标库位: ${state.targetLocation}'),
            const SizedBox(height: 8),
            Text('转移数量: ${state.transferredCount} 盘电缆'),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Go back to query screen
              context.pop();
            },
            child: const Text('返回查询'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Reset and continue
              context.read<LineStockBloc>().add(const ResetShelving());
              setState(() {
                _isLocationSet = false;
                _locationController.clear();
              });
            },
            child: const Text('继续上架'),
          ),
        ],
      ),
    );
  }
}
