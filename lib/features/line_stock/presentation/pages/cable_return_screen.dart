import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/line_stock_bloc.dart';
import '../bloc/line_stock_event.dart';
import '../bloc/line_stock_state.dart';
import '../widgets/barcode_input_field.dart';

/// Cable return screen for returning cables from line to warehouse
///
/// Workflow:
/// 1. Scan cable barcode to verify current location
/// 2. Scan multiple cables to add to return list
/// 3. Review and confirm return operation
///
/// Features:
/// - Cable barcode scanning/input
/// - Return list management (add/remove)
/// - Batch return confirmation
/// - Success feedback
class CableReturnScreen extends StatefulWidget {
  const CableReturnScreen({super.key});

  @override
  State<CableReturnScreen> createState() => _CableReturnScreenState();
}

class _CableReturnScreenState extends State<CableReturnScreen> {
  @override
  void initState() {
    super.initState();
    // Reset state when entering screen
    context.read<LineStockBloc>().add(const ResetShelving());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('电缆退库'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/workbench'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<LineStockBloc>().add(const ResetShelving());
            },
          ),
        ],
      ),
      body: BlocConsumer<LineStockBloc, LineStockState>(
        listener: (context, state) {
          if (state is ShelvingSuccess) {
            _showSuccessDialog(context, state.displayMessage);
          }
        },
        builder: (context, state) {
          if (state is LineStockError) {
            return _buildErrorState(state);
          }

          if (state is ShelvingInProgress) {
            return _buildShelvingInProgress(state);
          }

          // Initial or loading state
          return _buildInitialState();
        },
      ),
    );
  }

  Widget _buildErrorState(LineStockError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            state.message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (state.canRetry)
            ElevatedButton(
              onPressed: () {
                context.read<LineStockBloc>().add(const ResetShelving());
              },
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.unarchive, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            '初始化中...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildShelvingInProgress(ShelvingInProgress state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instruction section
                _buildInstructionCard(),
                const SizedBox(height: 24),

                // Cable barcode input
                _buildBarcodeInput(),
                const SizedBox(height: 24),

                // Cable list
                if (state.hasCables) ...[
                  _buildCableListSection(state),
                  const SizedBox(height: 24),
                ],

                // Return button
                if (state.hasCables) _buildReturnButton(state),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.unarchive,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '扫描电缆退库',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '请扫描或输入需要退库的电缆条码',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeInput() {
    return BarcodeInputField(
      label: '电缆条码',
      hint: '扫描或输入13位电缆条码后按回车',
      minLength: 13,
      autoSubmitOnChange: false,
      showKeyboard: false, // PDA模式: 禁用自动弹出键盘
      onSubmit: (barcode) {
        if (barcode.isNotEmpty) {
          context.read<LineStockBloc>().add(
                AddCableBarcode(barcode),
              );
        }
      },
    );
  }

  Widget _buildCableListSection(ShelvingInProgress state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '退库列表',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '共 ${state.cableCount} 件',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...state.cableList.map((cable) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.qr_code, color: Colors.blue),
                title: Text(
                  cable.barcode,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(cable.displayInfo),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    context.read<LineStockBloc>().add(
                          RemoveCableBarcode(cable.barcode),
                        );
                  },
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildReturnButton(ShelvingInProgress state) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          _showReturnConfirmation(state);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          '确认退库',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showReturnConfirmation(ShelvingInProgress state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认退库'),
        content: Text('确定要将 ${state.cableCount} 件电缆退回库存吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Use "RETURN" as special location code for return operation
              final barcodes = state.cableList.map((c) => c.barcode).toList();
              context.read<LineStockBloc>().add(
                    ConfirmShelving(
                      locationCode: 'RETURN',
                      barCodes: barcodes,
                    ),
                  );
            },
            child: const Text(
              '确认',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('成功'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<LineStockBloc>().add(const ResetShelving());
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
