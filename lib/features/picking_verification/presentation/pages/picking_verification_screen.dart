import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/picking_verification_bloc.dart';
import '../bloc/picking_verification_event.dart';
import '../bloc/picking_verification_state.dart';
import '../widgets/order_info_card_widget.dart';
import '../widgets/mode_activation_widget.dart';
import '../widgets/verification_status_widget.dart';
import '../widgets/order_scanning_widget.dart';
import '../widgets/manual_input_widget.dart';
import '../widgets/material_list_widget.dart';

/// 拣货校验屏幕
class PickingVerificationScreen extends StatefulWidget {
  final String? orderNumber;

  const PickingVerificationScreen({super.key, this.orderNumber});

  @override
  State<PickingVerificationScreen> createState() => _PickingVerificationScreenState();
}

class _PickingVerificationScreenState extends State<PickingVerificationScreen> {
  @override
  void initState() {
    super.initState();
    // 如果有订单号，自动激活拣货校验模式
    if (widget.orderNumber != null && widget.orderNumber!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PickingVerificationBloc>().add(
          ActivatePickingVerificationEvent(
            orderNumber: widget.orderNumber!,
          ),
        );
      });
    } else {
      // 无预设订单，直接进入扫描模式
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<PickingVerificationBloc>().add(
          StartScanning(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '合箱校验',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackNavigation(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: BlocListener<PickingVerificationBloc, PickingVerificationState>(
        listener: _handleStateChanges,
        child: BlocBuilder<PickingVerificationBloc, PickingVerificationState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildBody(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PickingVerificationState state) {
    // Handle scanning and manual input modes
    if (state is ScanningMode) {
      return const OrderScanningWidget();
    }
    
    if (state is ManualInputMode) {
      return const ManualInputWidget();
    }
    
    if (state is OrderLookupLoading) {
      return _buildLoadingCard('正在查询订单 ${state.orderNumber}...');
    }
    
    if (state is OrderDetailsLoaded) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OrderInfoCardWidget(
              order: state.order,
              isActivated: state.isModeActivated,
              onRefresh: () => _refreshOrder(context, state.order.orderNumber),
            ),
            const SizedBox(height: 16),
            // Display material list if order has materials
            if (state.order.materials.isNotEmpty) ...[
              // Determine orientation for responsive design
              MaterialListWidget(
                order: state.order,
                isPortrait: MediaQuery.of(context).orientation == Orientation.portrait,
              ),
              const SizedBox(height: 16),
            ],
            VerificationStatusWidget(
              order: state.order,
              isModeActivated: state.isModeActivated,
            ),
            const SizedBox(height: 32),
            _buildBottomActions(context, state),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state is PickingVerificationLoading) ...[
            _buildLoadingCard(state.message),
          ] else if (state is PickingVerificationError) ...[
            _buildErrorCard(state),
            const SizedBox(height: 16),
            _buildRetryActions(context, state),
          ] else if (state is PickingVerificationModeActivated) ...[
            _buildModeActivatedCard(state),
          ] else if (state is PickingOrderLoaded) ...[
            OrderInfoCardWidget(
              order: state.order,
              isActivated: state.isModeActivated,
              onRefresh: () => _refreshOrder(context, state.order.orderNumber),
            ),
            const SizedBox(height: 16),
            VerificationStatusWidget(
              order: state.order,
              isModeActivated: state.isModeActivated,
            ),
          ] else if (state is OrderVerificationCompleted) ...[
            _buildCompletionCard(state),
          ] else if (widget.orderNumber != null) ...[
            ModeActivationWidget(
              orderNumber: widget.orderNumber!,
              isActivated: false,
              isLoading: false,
              onActivate: () => _activateMode(context, widget.orderNumber!),
            ),
          ] else ...[
            _buildInitialCard(),
          ],
          
          const SizedBox(height: 32),
          _buildBottomActions(context, state),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(String? message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              message ?? '正在加载...',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(PickingVerificationError state) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 16),
            const Text(
              '操作失败',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.errorMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryActions(BuildContext context, PickingVerificationError state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _retryOperation(context, state),
            icon: const Icon(Icons.refresh),
            label: const Text('重试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.read<PickingVerificationBloc>().add(ResetPickingVerificationEvent()),
          icon: const Icon(Icons.restart_alt),
          label: const Text('重新开始'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildModeActivatedCard(PickingVerificationModeActivated state) {
    return ModeActivationWidget(
      orderNumber: state.orderNumber,
      isActivated: true,
      isLoading: false,
      onContinue: () => context.read<PickingVerificationBloc>().add(
        LoadPickingOrderEvent(orderNumber: state.orderNumber),
      ),
    );
  }

  Widget _buildCompletionCard(OrderVerificationCompleted state) {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 16),
            const Text(
              '校验完成',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '订单 ${state.completedOrder.orderNumber} 已完成校验',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 16),
            const Text(
              '拣货校验',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '请选择订单查询方式',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Scanning button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<PickingVerificationBloc>().add(StartScanning());
                },
                icon: const Icon(Icons.qr_code_scanner, size: 28),
                label: const Text('扫描二维码', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Manual input button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<PickingVerificationBloc>().add(SwitchToManualInput());
                },
                icon: const Icon(Icons.keyboard, size: 28),
                label: const Text('手动输入', style: TextStyle(fontSize: 20)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, PickingVerificationState state) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _handleBackNavigation(context),
            icon: const Icon(Icons.list),
            label: const Text('返回任务列表'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _showFeatureRequest(context),
          icon: const Icon(Icons.lightbulb_outline),
          label: const Text('功能建议反馈'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _handleStateChanges(BuildContext context, PickingVerificationState state) {
    if (state is PickingVerificationNavigateBack) {
      context.go('/tasks');
    }
  }

  void _handleBackNavigation(BuildContext context) {
    context.read<PickingVerificationBloc>().add(NavigateBackToTasksEvent());
  }

  void _activateMode(BuildContext context, String orderNumber) {
    context.read<PickingVerificationBloc>().add(
      ActivatePickingVerificationEvent(orderNumber: orderNumber),
    );
  }

  void _refreshOrder(BuildContext context, String orderNumber) {
    context.read<PickingVerificationBloc>().add(
      LoadPickingOrderEvent(orderNumber: orderNumber),
    );
  }

  void _retryOperation(BuildContext context, PickingVerificationError state) {
    if (state.orderNumber != null) {
      switch (state.errorType) {
        case PickingVerificationErrorType.activationFailed:
          context.read<PickingVerificationBloc>().add(
            ActivatePickingVerificationEvent(
              orderNumber: state.orderNumber!,
              taskId: state.taskId,
            ),
          );
          break;
        case PickingVerificationErrorType.orderNotFound:
        case PickingVerificationErrorType.networkError:
        default:
          context.read<PickingVerificationBloc>().add(
            LoadPickingOrderEvent(orderNumber: state.orderNumber!),
          );
          break;
      }
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('合箱校验说明'),
        content: const Text(
          '合箱校验是确保拣货准确性的重要环节。\n\n'
          '主要包括：\n'
          '• 激活校验模式\n'
          '• 加载订单详情\n'
          '• 核对商品数量\n'
          '• 检查商品规格\n'
          '• 确认包装完整性\n'
          '• 逐项验证无误后完成校验',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  void _showFeatureRequest(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('功能建议'),
        content: const Text(
          '如果您对合箱校验功能有任何建议或需求，\n'
          '请联系系统管理员或技术支持团队。\n\n'
          '当前版本已支持：\n'
          '• 拣货校验模式激活\n'
          '• 订单信息加载和显示\n'
          '• 校验状态跟踪\n'
          '• 错误处理和重试',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}