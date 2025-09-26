import 'package:flutter/material.dart';

/// 提交进度状态
enum SubmissionProgressState {
  preparing('准备提交'),
  validating('验证数据'),
  submitting('提交中'),
  processing('处理中'),
  completed('完成'),
  failed('失败');

  final String label;
  const SubmissionProgressState(this.label);
}

/// 提交进度组件
class SubmissionProgressWidget extends StatefulWidget {
  final SubmissionProgressState state;
  final String? message;
  final double? progress; // 0.0 to 1.0
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const SubmissionProgressWidget({
    super.key,
    required this.state,
    this.message,
    this.progress,
    this.onRetry,
    this.onCancel,
  });

  @override
  State<SubmissionProgressWidget> createState() => _SubmissionProgressWidgetState();
}

class _SubmissionProgressWidgetState extends State<SubmissionProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10.0,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: _getStateColor().withValues(alpha: 0.3),
                  width: 2.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 状态图标和标题
                  _buildHeader(),
                  
                  const SizedBox(height: 24.0),
                  
                  // 进度指示器
                  _buildProgressIndicator(),
                  
                  const SizedBox(height: 16.0),
                  
                  // 状态消息
                  _buildMessage(),
                  
                  const SizedBox(height: 24.0),
                  
                  // 操作按钮
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建头部
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 56.0, // PDA适配大图标
          height: 56.0,
          decoration: BoxDecoration(
            color: _getStateColor().withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(28.0),
          ),
          child: Icon(
            _getStateIcon(),
            size: 32.0, // PDA适配大图标
            color: _getStateColor(),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '校验提交',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 22.0, // PDA适配大字体
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                widget.state.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18.0, // PDA适配大字体
                  color: _getStateColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建进度指示器
  Widget _buildProgressIndicator() {
    switch (widget.state) {
      case SubmissionProgressState.preparing:
      case SubmissionProgressState.validating:
      case SubmissionProgressState.submitting:
      case SubmissionProgressState.processing:
        return Column(
          children: [
            if (widget.progress != null) ...[
              LinearProgressIndicator(
                value: widget.progress,
                backgroundColor: _getStateColor().withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(_getStateColor()),
                minHeight: 8.0, // PDA适配加粗进度条
              ),
              const SizedBox(height: 8.0),
              Text(
                '${((widget.progress ?? 0) * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16.0,
                  color: _getStateColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              SizedBox(
                width: 40.0, // PDA适配大进度指示器
                height: 40.0,
                child: CircularProgressIndicator(
                  strokeWidth: 4.0,
                  valueColor: AlwaysStoppedAnimation<Color>(_getStateColor()),
                ),
              ),
            ],
          ],
        );
      case SubmissionProgressState.completed:
        return Container(
          width: 80.0, // PDA适配大成功图标
          height: 80.0,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 48.0,
            color: Colors.green,
          ),
        );
      case SubmissionProgressState.failed:
        return Container(
          width: 80.0, // PDA适配大错误图标
          height: 80.0,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error,
            size: 48.0,
            color: Colors.red,
          ),
        );
    }
  }

  /// 构建消息
  Widget _buildMessage() {
    final message = widget.message ?? _getDefaultMessage();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _getStateColor().withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 16.0, // PDA适配大字体
          color: Theme.of(context).colorScheme.onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    switch (widget.state) {
      case SubmissionProgressState.failed:
        return Row(
          children: [
            if (widget.onCancel != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52.0), // PDA适配大按钮
                    textStyle: const TextStyle(fontSize: 16.0), // PDA适配大字体
                  ),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 12.0),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: 24.0),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52.0), // PDA适配大按钮
                  backgroundColor: _getStateColor(),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16.0, // PDA适配大字体
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      case SubmissionProgressState.completed:
        return const SizedBox.shrink();
      default:
        if (widget.onCancel != null) {
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52.0), // PDA适配大按钮
                textStyle: const TextStyle(fontSize: 16.0), // PDA适配大字体
              ),
              child: const Text('取消'),
            ),
          );
        }
        return const SizedBox.shrink();
    }
  }

  /// 获取状态颜色
  Color _getStateColor() {
    switch (widget.state) {
      case SubmissionProgressState.preparing:
      case SubmissionProgressState.validating:
        return Colors.blue;
      case SubmissionProgressState.submitting:
      case SubmissionProgressState.processing:
        return Colors.orange;
      case SubmissionProgressState.completed:
        return Colors.green;
      case SubmissionProgressState.failed:
        return Colors.red;
    }
  }

  /// 获取状态图标
  IconData _getStateIcon() {
    switch (widget.state) {
      case SubmissionProgressState.preparing:
        return Icons.inventory_2_outlined;
      case SubmissionProgressState.validating:
        return Icons.fact_check_outlined;
      case SubmissionProgressState.submitting:
        return Icons.cloud_upload_outlined;
      case SubmissionProgressState.processing:
        return Icons.hourglass_empty_outlined;
      case SubmissionProgressState.completed:
        return Icons.check_circle_outline;
      case SubmissionProgressState.failed:
        return Icons.error_outline;
    }
  }

  /// 获取默认消息
  String _getDefaultMessage() {
    switch (widget.state) {
      case SubmissionProgressState.preparing:
        return '正在准备提交数据...';
      case SubmissionProgressState.validating:
        return '正在验证物料状态和数据完整性...';
      case SubmissionProgressState.submitting:
        return '正在提交校验结果到服务器...';
      case SubmissionProgressState.processing:
        return '服务器正在处理您的校验数据...';
      case SubmissionProgressState.completed:
        return '校验数据提交成功！订单状态已更新。';
      case SubmissionProgressState.failed:
        return '提交失败，请检查网络连接并重试。';
    }
  }
}