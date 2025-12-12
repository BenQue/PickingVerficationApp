import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../domain/entities/line_stock_entity.dart';
import '../bloc/line_stock_bloc.dart';
import '../bloc/line_stock_event.dart';
import '../bloc/line_stock_state.dart';
import '../widgets/barcode_input_field.dart';
import '../widgets/stock_info_card.dart';

/// Query mode for stock lookup
enum StockQueryMode {
  barcode, // Query by barcode (single result)
  material, // Query by material code (batch results)
}

/// Stock query screen for looking up line stock information
///
/// Features:
/// - Toggle between barcode and material code query modes
/// - Barcode input with auto-focus for scanner
/// - Material code input for batch lookup
/// - Real-time stock information display
/// - Navigation to shelving screen
/// - Error handling with user feedback
class StockQueryScreen extends StatefulWidget {
  const StockQueryScreen({super.key});

  @override
  State<StockQueryScreen> createState() => _StockQueryScreenState();
}

class _StockQueryScreenState extends State<StockQueryScreen> {
  StockQueryMode _queryMode = StockQueryMode.barcode;

  @override
  void initState() {
    super.initState();
    // Reset to initial state when screen loads
    context.read<LineStockBloc>().add(const ResetLineStock());
  }

  void _onBarcodeScanned(String barcode) {
    // Query stock by barcode (validation is handled by BarcodeInputField)
    context.read<LineStockBloc>().add(
          QueryStockByBarcode(barcode: barcode),
        );
  }

  void _onMaterialCodeSubmit(String materialCode) {
    // Query stock by material code
    context.read<LineStockBloc>().add(
          QueryStockByMaterialCode(materialCode: materialCode),
        );
  }

  void _navigateToShelving() {
    // Get current stock from state
    final currentState = context.read<LineStockBloc>().state;
    if (currentState is StockQuerySuccess) {
      // Trigger event to start shelving with this cable
      context.read<LineStockBloc>().add(
            StartShelvingWithCable(currentState.stock.barcode),
          );

      // Navigate to shelving screen
      context.push('/line-stock/shelving');
    }
  }

  void _switchQueryMode(StockQueryMode mode) {
    if (_queryMode != mode) {
      setState(() {
        _queryMode = mode;
      });
      // Clear previous query result when switching modes
      context.read<LineStockBloc>().add(const ClearQueryResult());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('库存查询'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/workbench'),
        ),
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
                // Query mode toggle
                _buildQueryModeToggle(theme),

                const Divider(height: 1),

                // Input section based on query mode
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: _queryMode == StockQueryMode.barcode
                      ? BarcodeInputField(
                          key: const ValueKey('barcode_input'),
                          label: '电缆条码',
                          hint: '扫码枪扫描或手动输入9位条码后按回车',
                          onSubmit: _onBarcodeScanned,
                          enabled: state is! LineStockLoading,
                          minLength: 9,
                          autoSubmitOnChange: false,
                          showKeyboard: false, // PDA mode: disable keyboard by default
                        )
                      : BarcodeInputField(
                          key: const ValueKey('material_input'),
                          label: '物料号码',
                          hint: '输入物料号按回车查询',
                          onSubmit: _onMaterialCodeSubmit,
                          enabled: state is! LineStockLoading,
                          minLength: 1,
                          autoSubmitOnChange: false,
                          showKeyboard: false, // PDA mode: same as barcode query
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

  Widget _buildQueryModeToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SegmentedButton<StockQueryMode>(
        segments: const [
          ButtonSegment<StockQueryMode>(
            value: StockQueryMode.barcode,
            label: Text('按条码查询'),
            icon: Icon(Icons.qr_code),
          ),
          ButtonSegment<StockQueryMode>(
            value: StockQueryMode.material,
            label: Text('按物料查询'),
            icon: Icon(Icons.inventory_2),
          ),
        ],
        selected: {_queryMode},
        onSelectionChanged: (Set<StockQueryMode> selected) {
          _switchQueryMode(selected.first);
        },
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          textStyle: WidgetStateProperty.all(
            theme.textTheme.titleMedium,
          ),
        ),
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
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // Stock information card
            StockInfoCard(stock: state.stock),

            const SizedBox(height: 16),

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
          ],
        ),
      );
    }

    if (state is MaterialQuerySuccess) {
      return _buildMaterialQueryResult(context, state, theme);
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _queryMode == StockQueryMode.barcode
                  ? Icons.qr_code_2
                  : Icons.inventory_2,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              _queryMode == StockQueryMode.barcode ? '请扫描电缆条码' : '请输入物料号码',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _queryMode == StockQueryMode.barcode
                  ? '使用扫码枪扫描电缆条码\n系统将显示库存信息'
                  : '输入物料号码后按回车\n系统将显示所有批次库存',
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

  Widget _buildMaterialQueryResult(
    BuildContext context,
    MaterialQuerySuccess state,
    ThemeData theme,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        // Compact summary header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Material info row
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 20,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    state.materialCode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  // Batch count and total stock in one row
                  Text(
                    '${state.batchCount}批次 | 库存: ${state.totalLastQuantity.toStringAsFixed(1)}${state.baseUnit}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Material description
              Text(
                state.materialDesc,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Batch list title
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            '批次详情',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Batch items
        ...state.stockList.map((stock) => _buildBatchItem(context, stock, theme)),

        const SizedBox(height: 8),

        // Clear button
        SecondaryButton(
          text: '清除结果',
          icon: Icons.clear,
          onPressed: () {
            context.read<LineStockBloc>().add(const ClearQueryResult());
          },
        ),
      ],
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchItem(
    BuildContext context,
    LineStock stock,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Batch code and location code
            Row(
              children: [
                Icon(
                  Icons.label,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '批次: ${stock.batchCode}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stock.locationCode,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Barcode and location description in one row
            Row(
              children: [
                Icon(
                  Icons.qr_code,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  stock.barcode,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    stock.locationDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 12),

            // Quantity info - compact layout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuantityInfo(
                  theme,
                  '入库数量',
                  stock.quantity,
                  stock.baseUnit,
                  Colors.blue,
                ),
                _buildQuantityInfo(
                  theme,
                  '库存数量',
                  stock.lastQuantity,
                  stock.baseUnit,
                  Colors.green,
                ),
                _buildQuantityInfo(
                  theme,
                  '已用数量',
                  stock.quantity - stock.lastQuantity,
                  stock.baseUnit,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityInfo(
    ThemeData theme,
    String label,
    double value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value.toStringAsFixed(1),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$label ($unit)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
