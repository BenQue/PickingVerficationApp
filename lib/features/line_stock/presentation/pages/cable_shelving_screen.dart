import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../bloc/line_stock_bloc.dart';
import '../bloc/line_stock_event.dart';
import '../bloc/line_stock_state.dart';
import '../widgets/barcode_input_field.dart';
import '../widgets/cable_list_item.dart';
import '../widgets/shelving_summary.dart';

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
  bool _isLocationSet = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
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
    setState(() {
      _isLocationSet = false;
    });
    context.read<LineStockBloc>().add(const ModifyTargetLocation());
    _locationController.clear();
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
          content: Text('确定要将 ${state.cableCount} 条电缆转移到 ${state.targetLocation} 吗？'),
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
          // Handle error states
          if (state is LineStockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
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

          return SafeArea(
            child: Column(
              children: [
                // Step 1: Target Location Input
                if (!_isLocationSet)
                  _buildLocationInput(theme)
                else
                  _buildLocationDisplay(state, theme),

                const Divider(height: 1),

                // Step 2: Cable List
                if (_isLocationSet) ...[
                  Expanded(
                    child: _buildCableListSection(state, theme),
                  ),

                  // Bottom action bar
                  _buildBottomActions(state, theme),
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
      padding: const EdgeInsets.all(24),
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
                child: Center(
                  child: Text(
                    '1',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          const SizedBox(height: 24),
          TextField(
            controller: _locationController,
            autofocus: true,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: '目标库位',
              labelStyle: const TextStyle(fontSize: 18),
              hintText: '扫描或输入库位代码',
              hintStyle: const TextStyle(fontSize: 16),
              prefixIcon: const Icon(Icons.location_on, size: 32),
              suffixIcon: _locationController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 28),
                      onPressed: () {
                        _locationController.clear();
                        setState(() {});
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
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _setTargetLocation(),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: '确认库位',
            icon: Icons.check,
            onPressed: _locationController.text.trim().isEmpty
                ? null
                : _setTargetLocation,
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

    if (state.cableList.isEmpty) {
      return SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Step 2 header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '添加电缆',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '扫描电缆条码添加到列表',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Barcode input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: BarcodeInputField(
                label: '电缆条码',
                hint: '扫描电缆条码',
                onSubmit: _onCableScanned,
              ),
            ),
            const SizedBox(height: 40),
            // Empty state
            Icon(
              Icons.cable,
              size: 80,
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
              '请扫描电缆条码添加到列表',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Barcode input (always visible when location is set)
        Padding(
          padding: const EdgeInsets.all(16),
          child: BarcodeInputField(
            label: '扫描添加电缆',
            hint: '扫描电缆条码',
            onSubmit: _onCableScanned,
          ),
        ),

        // Cable list header with count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '已添加电缆 (${state.cableCount})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (state.cableCount > 0)
                TextButton.icon(
                  onPressed: _clearAllCables,
                  icon: Icon(Icons.clear_all, size: 20, color: theme.colorScheme.error),
                  label: Text('清空', style: TextStyle(color: theme.colorScheme.error)),
                ),
            ],
          ),
        ),

        // Cable list
        Expanded(
          child: ListView.builder(
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

  Widget _buildBottomActions(LineStockState state, ThemeData theme) {
    if (state is! ShelvingInProgress) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
            // Summary
            ShelvingSummary(
              targetLocation: state.targetLocation,
              cableCount: state.cableCount,
            ),
            const SizedBox(height: 16),

            // Confirm button
            PrimaryButton(
              text: '确认上架 (${state.cableCount} 条)',
              icon: Icons.check_circle,
              onPressed: state.canSubmit ? _confirmShelving : null,
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
            Text('转移数量: ${state.transferredCount} 条电缆'),
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
