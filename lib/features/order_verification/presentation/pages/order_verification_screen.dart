import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/order_verification_bloc.dart';
import '../bloc/order_verification_event.dart';
import '../bloc/order_verification_state.dart';
import '../widgets/verification_result_widget.dart';
import 'qr_scanner_screen.dart';
import 'manual_input_screen.dart';

class OrderVerificationScreen extends StatelessWidget {
  final String taskId;
  final String expectedOrderId;

  const OrderVerificationScreen({
    super.key,
    required this.taskId,
    required this.expectedOrderId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrderVerificationBloc, OrderVerificationState>(
      listener: (context, state) {
        if (state is VerificationSuccess) {
          // Navigate to work interface after successful verification
          _navigateToWorkInterface(context, state.taskId, state.result.orderId);
        } else if (state is VerificationCancelled) {
          // Go back to task list
          context.go('/home');
        }
      },
      builder: (context, state) {
        return _buildScreen(context, state);
      },
    );
  }

  Widget _buildScreen(BuildContext context, OrderVerificationState state) {
    if (state is VerificationReady) {
      return _buildReadyScreen(context, state);
    } else if (state is VerificationLoading) {
      return _buildLoadingScreen(context, state);
    } else if (state is VerificationFailure) {
      return _buildFailureScreen(context, state);
    } else if (state is VerificationSuccess) {
      return _buildSuccessScreen(context, state);
    } else {
      return _buildInitialScreen(context);
    }
  }

  Widget _buildInitialScreen(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildReadyScreen(BuildContext context, VerificationReady state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订单验证'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _cancelVerification(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            
            // Instructions card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '请验证订单号',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '扫描订单二维码或手动输入订单号进行验证',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '期望订单号:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.expectedOrderId,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Scan button
            ElevatedButton.icon(
              onPressed: () => _showQRScanner(context, state),
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Text('扫描二维码'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Manual input button
            TextButton.icon(
              onPressed: () => _showManualInput(context, state),
              icon: const Icon(Icons.keyboard, size: 24),
              label: const Text('手动输入订单号'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            
            const Spacer(),
            
            // Cancel button
            TextButton(
              onPressed: () => _cancelVerification(context),
              child: const Text('取消'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen(BuildContext context, VerificationLoading state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('验证中...'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 24),
            Text(
              '正在验证订单号...',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureScreen(BuildContext context, VerificationFailure state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('验证失败'),
        backgroundColor: Colors.red.shade100,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _cancelVerification(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VerificationResultWidget(
              isSuccess: false,
              message: state.errorMessage,
              scannedOrderId: state.scannedOrderId,
              expectedOrderId: state.expectedOrderId,
            ),
            
            const SizedBox(height: 32),
            
            // Retry buttons
            ElevatedButton.icon(
              onPressed: () => _retryVerification(context),
              icon: const Icon(Icons.refresh),
              label: const Text('重新验证'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: () => _cancelVerification(context),
              child: const Text('返回任务列表'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(BuildContext context, VerificationSuccess state) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('验证成功'),
        backgroundColor: Colors.green.shade100,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VerificationResultWidget(
              isSuccess: true,
              message: '订单验证成功！',
              scannedOrderId: state.result.orderId,
              expectedOrderId: state.result.orderId,
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: () => _navigateToWorkInterface(
                context, 
                state.taskId, 
                state.result.orderId,
              ),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('进入作业界面'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRScanner(BuildContext context, VerificationReady state) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          expectedOrderId: state.expectedOrderId,
          taskId: state.taskId,
          onScanned: (scannedData) {
            Navigator.of(context).pop();
            context.read<OrderVerificationBloc>().add(
              ScanQRCodeEvent(scannedOrderId: scannedData),
            );
          },
          onManualInput: () {
            Navigator.of(context).pop();
            _showManualInput(context, state);
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
        fullscreenDialog: true,
      ),
    );
  }

  void _showManualInput(BuildContext context, VerificationReady state) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManualInputScreen(
          expectedOrderId: state.expectedOrderId,
          taskId: state.taskId,
          onSubmitted: (inputOrderId) {
            Navigator.of(context).pop();
            context.read<OrderVerificationBloc>().add(
              VerifyManualInputEvent(inputOrderId: inputOrderId),
            );
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _retryVerification(BuildContext context) {
    context.read<OrderVerificationBloc>().add(ResetVerificationEvent());
  }

  void _cancelVerification(BuildContext context) {
    context.read<OrderVerificationBloc>().add(CancelVerificationEvent());
  }

  void _navigateToWorkInterface(BuildContext context, String taskId, String orderId) {
    // For now, route based on task ID logic or default to picking verification
    // In future, we could fetch task details from repository if needed
    // For this story, we'll route to picking verification as specified
    context.go('/picking-verification/$orderId');
  }
}