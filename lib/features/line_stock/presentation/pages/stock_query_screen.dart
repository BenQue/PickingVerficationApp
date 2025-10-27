import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../bloc/line_stock_bloc.dart';
import '../bloc/line_stock_event.dart';
import '../bloc/line_stock_state.dart';
import '../widgets/barcode_input_field.dart';
import '../widgets/stock_info_card.dart';

/// Stock query screen for looking up line stock information by barcode
///
/// Features:
/// - Barcode input with auto-focus for scanner
/// - Real-time stock information display
/// - Navigation to shelving screen
/// - Error handling with user feedback
class StockQueryScreen extends StatefulWidget {
  const StockQueryScreen({super.key});

  @override
  State<StockQueryScreen> createState() => _StockQueryScreenState();
}

class _StockQueryScreenState extends State<StockQueryScreen> {
  @override
  void initState() {
    super.initState();
    // Reset to initial state when screen loads
    context.read<LineStockBloc>().add(const ResetLineStock());
  }

  void _onBarcodeScanned(String barcode) {
    // Query stock by barcode
    context.read<LineStockBloc>().add(
          QueryStockByBarcode(barcode: barcode),
        );
  }

  void _navigateToShelving() {
    // Navigate to cable shelving screen
    context.push('/line-stock/shelving');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('库存查询'),
        centerTitle: true,
      ),
      body: BlocConsumer<LineStockBloc, LineStockState>(
        listener: (context, state) {
          // Handle error states with snackbar
          if (state is LineStockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
                duration: const Duration(seconds: 3),
                action: state.canRetry
                    ? SnackBarAction(
                        label: '重试',
                        textColor: Colors.white,
                        onPressed: () {
                          // Optionally retry the last operation
                        },
                      )
                    : null,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                // Barcode input section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title and icon
                      Row(
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '扫描电缆条码',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '使用扫码枪扫描或手动输入',
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

                      // Barcode input field
                      BarcodeInputField(
                        label: '电缆条码',
                        hint: '扫码枪扫描或手动输入条码',
                        onSubmit: _onBarcodeScanned,
                        enabled: state is! LineStockLoading,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Content area based on state
                Expanded(
                  child: _buildContent(context, state, theme),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LineStockState state,
    ThemeData theme,
  ) {
    if (state is LineStockLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              state.message ?? '正在查询库存信息...',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    if (state is StockQuerySuccess) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Stock information card
            StockInfoCard(stock: state.stock),

            const SizedBox(height: 24),

            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Navigate to shelving button
                  PrimaryButton(
                    text: '开始上架',
                    icon: Icons.arrow_forward,
                    onPressed: _navigateToShelving,
                  ),
                  const SizedBox(height: 12),

                  // Clear result button
                  SecondaryButton(
                    text: '清除结果',
                    icon: Icons.clear,
                    onPressed: () {
                      context.read<LineStockBloc>().add(
                            const ClearQueryResult(),
                          );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      );
    }

    if (state is LineStockError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '查询失败',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.message,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (state.canRetry)
                PrimaryButton(
                  text: '重新扫描',
                  icon: Icons.refresh,
                  onPressed: () {
                    context.read<LineStockBloc>().add(
                          const ResetLineStock(),
                        );
                  },
                ),
            ],
          ),
        ),
      );
    }

    // Initial state - show instructions
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 120,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              '请扫描电缆条码',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '使用扫码枪扫描电缆条码\n系统将显示库存信息',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
