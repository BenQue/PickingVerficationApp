import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../bloc/line_stock_bloc.dart';
import '../bloc/line_stock_event.dart';
import '../bloc/line_stock_state.dart';
import '../widgets/barcode_input_field.dart';
import '../widgets/handover_list_item.dart';

/// Cable receiving screen for confirming cable handover/receiving
///
/// Workflow:
/// 1. Scan cable barcodes to query and add to receiving list
/// 2. Review list (can remove items)
/// 3. Confirm to submit receiving
/// 4. Return to workbench on success
class CableReceivingScreen extends StatefulWidget {
  const CableReceivingScreen({super.key});

  @override
  State<CableReceivingScreen> createState() => _CableReceivingScreenState();
}

class _CableReceivingScreenState extends State<CableReceivingScreen> {
  final _barcodeController = TextEditingController();
  int _previousItemCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with empty handover list
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LineStockBloc>().add(const ResetHandover());
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  /// Recursively find the HandoverInProgress state from error chain
  HandoverInProgress? _findHandoverState(LineStockState state) {
    if (state is HandoverInProgress) {
      return state;
    }
    if (state is LineStockError && state.previousState != null) {
      return _findHandoverState(state.previousState!);
    }
    return null;
  }

  void _onBarcodeScanned(String barcode) {
    context.read<LineStockBloc>().add(ScanHandoverBarcode(barcode));
  }

  void _onItemRemoved(String barcode) {
    context.read<LineStockBloc>().add(RemoveHandoverItem(barcode));
  }

  void _clearAllItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有待入库物料吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              this.context.read<LineStockBloc>().add(const ClearHandoverList());
              Navigator.of(context).pop();
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _confirmReceiving() {
    final state = context.read<LineStockBloc>().state;
    final handoverState = _findHandoverState(state);

    if (handoverState != null && handoverState.canSubmit) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('确认入库'),
          content: Text('确定要将 ${handoverState.itemCount} 个物料确认入库吗?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                this.context.read<LineStockBloc>().add(const ConfirmHandover());
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
        title: const Text('电缆入库'),
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
                  content: const Text('确定要重置所有数据吗?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        this.context.read<LineStockBloc>().add(const ResetHandover());
                        Navigator.of(context).pop();
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
          // Handle error states
          if (state is LineStockError) {
            HapticFeedback.mediumImpact();

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

            // Clear input on error
            _barcodeController.clear();
          }

          // Handle successful item addition
          if (state is HandoverInProgress) {
            if (state.itemCount > _previousItemCount) {
              // Successfully added an item
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _barcodeController.clear();
              _previousItemCount = state.itemCount;
            } else if (state.itemCount < _previousItemCount) {
              // Item was removed
              _previousItemCount = state.itemCount;
            }
          }

          // Handle success state
          if (state is HandoverSuccess) {
            _showSuccessDialog(context, state);
          }
        },
        builder: (context, state) {
          // Find HandoverInProgress state (could be in error chain)
          final handoverState = _findHandoverState(state);

          // Show loading if in HandoverInProgress with isLoading=true
          if (handoverState != null && handoverState.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 16),
                  Text(
                    '正在处理...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Column(
              children: [
                // Title section
                _buildTitleSection(theme),

                const Divider(height: 1),

                // Item list section
                Expanded(
                  child: _buildItemListSection(handoverState, theme),
                ),

                // Bottom action bar
                _buildBottomActions(handoverState, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(ThemeData theme) {
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
            Icons.move_to_inbox,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '断线电缆收货',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '扫描电缆条码，添加到待入库列表',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemListSection(HandoverInProgress? state, ThemeData theme) {
    return Column(
      children: [
        // Barcode input
        Container(
          color: theme.colorScheme.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: BarcodeInputField(
            label: '扫描电缆条码',
            hint: '扫码枪扫描或手动输入条码',
            controller: _barcodeController,
            onSubmit: _onBarcodeScanned,
            minLength: 9,
            autoSubmitOnChange: false,
            showKeyboard: false,
            enableInteractiveSelection: false,
            readOnly: false,
            showCursor: true,
          ),
        ),

        const Divider(height: 1),

        // List header with count
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                '待入库物料',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (state?.itemCount ?? 0) > 0
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state?.itemCount ?? 0} 个',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: (state?.itemCount ?? 0) > 0
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              if ((state?.itemCount ?? 0) > 0)
                TextButton.icon(
                  onPressed: _clearAllItems,
                  icon: Icon(Icons.clear_all, size: 20, color: theme.colorScheme.error),
                  label: Text('清空', style: TextStyle(color: theme.colorScheme.error)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
          ),
        ),

        // Item list or empty state
        Expanded(
          child: state == null || state.itemList.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: state.itemList.length,
                  itemBuilder: (context, index) {
                    final item = state.itemList[index];
                    return HandoverListItem(
                      index: index,
                      item: item,
                      onRemove: () => _onItemRemoved(item.barCode),
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
            Icons.inventory_2_outlined,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无待入库物料',
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

  Widget _buildBottomActions(HandoverInProgress? state, ThemeData theme) {
    final canSubmit = state?.canSubmit ?? false;
    final itemCount = state?.itemCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
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
            if (!canSubmit)
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
                        '请添加至少一个待入库物料',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (!canSubmit) const SizedBox(height: 12),

            // Confirm button
            PrimaryButton(
              text: '确认入库 ($itemCount 个)',
              icon: Icons.check_circle,
              onPressed: canSubmit ? _confirmReceiving : null,
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, HandoverSuccess state) {
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
            const Text('入库成功'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('入库数量: ${state.confirmedCount} 个物料'),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Go back to workbench
              context.go('/workbench');
            },
            child: const Text('返回工作台'),
          ),
        ],
      ),
    );
  }
}
