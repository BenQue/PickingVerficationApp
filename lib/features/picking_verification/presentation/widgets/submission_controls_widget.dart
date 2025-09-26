import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/picking_order.dart';
import '../../domain/entities/material_item.dart';
import '../bloc/picking_verification_bloc.dart';
import '../bloc/picking_verification_event.dart';
import '../bloc/picking_verification_state.dart';
import '../utils/submission_validator.dart';
import '../services/navigation_service.dart';

/// 提交控制组件
class SubmissionControlsWidget extends StatefulWidget {
  final PickingOrder order;
  final VoidCallback? onReturnToEdit;

  const SubmissionControlsWidget({
    super.key,
    required this.order,
    this.onReturnToEdit,
  });

  @override
  State<SubmissionControlsWidget> createState() => _SubmissionControlsWidgetState();
}

class _SubmissionControlsWidgetState extends State<SubmissionControlsWidget> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Listen to BLoC state changes for navigation
    context.read<PickingVerificationBloc>().stream.listen((state) {
      if (state is SubmissionSuccess && mounted) {
        // Navigate to completion screen on successful submission
        PickingVerificationNavigationService.navigateToCompletion(
          context,
          completedOrder: state.order,
          operatorId: state.operatorId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final validationResult = SubmissionValidator.validateOrderSubmission(widget.order);
    final canSubmit = validationResult.isValid && 
                     SubmissionGuard.canSubmit() && 
                     !_isSubmitting;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 完成状态指示器
          _buildProgressIndicator(validationResult),
          
          const SizedBox(height: 16.0),
          
          // 验证错误信息
          if (!validationResult.isValid) ...[
            _buildValidationErrorsCard(validationResult.errors),
            const SizedBox(height: 16.0),
          ],

          // 操作按钮区域
          _buildActionButtons(canSubmit, validationResult),
        ],
      ),
    );
  }

  /// 构建进度指示器
  Widget _buildProgressIndicator(SubmissionValidationResult result) {
    final progressValue = result.completionPercentage;
    final isCompleted = result.isValid;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : Colors.orange,
                  size: 24.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    isCompleted ? '所有物料已完成校验' : '物料校验进度',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18.0, // PDA适配大字体
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(progressValue * 100).toInt()}%',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isCompleted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? Colors.green : Colors.orange,
              ),
              minHeight: 8.0, // PDA适配加粗进度条
            ),
            const SizedBox(height: 8.0),
            // 类别完成状态
            _buildCategoryProgress(result.categoryCompletionStatus),
          ],
        ),
      ),
    );
  }

  /// 构建类别进度
  Widget _buildCategoryProgress(Map<MaterialCategory, int> categoryStatus) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: MaterialCategory.values.map((category) {
        final categoryMaterials = widget.order.materials.where((m) => m.category == category).toList();
        final completedCount = categoryStatus[category] ?? 0;
        final totalCount = categoryMaterials.length;
        final isCompleted = completedCount == totalCount && totalCount > 0;
        
        if (totalCount == 0) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isCompleted ? Colors.green : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isCompleted ? Icons.check_circle_outline : Icons.pending_outlined,
                size: 16.0,
                color: isCompleted ? Colors.green : Colors.grey.shade600,
              ),
              const SizedBox(width: 4.0),
              Text(
                '${category.label}: $completedCount/$totalCount',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14.0,
                  color: isCompleted ? Colors.green.shade800 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建验证错误卡片
  Widget _buildValidationErrorsCard(List<String> errors) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_outlined,
                  color: Colors.red.shade700,
                  size: 24.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    '需要处理的问题',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18.0, // PDA适配大字体
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            ...errors.map((error) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.fiber_manual_record,
                    size: 8.0,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 16.0, // PDA适配大字体
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(bool canSubmit, SubmissionValidationResult result) {
    return Row(
      children: [
        // 返回修改按钮
        if (widget.onReturnToEdit != null) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: _isSubmitting ? null : widget.onReturnToEdit,
              icon: const Icon(Icons.edit_outlined, size: 24.0),
              label: const Text('返回修改'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(56.0), // PDA适配大按钮
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                textStyle: const TextStyle(
                  fontSize: 18.0, // PDA适配大字体
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16.0),
        ],
        
        // 提交按钮
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: canSubmit ? _handleSubmission : null,
            icon: _isSubmitting 
                ? SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 24.0),
            label: Text(_getSubmitButtonText(result, _isSubmitting)),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56.0), // PDA适配大按钮
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              backgroundColor: canSubmit 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
              foregroundColor: canSubmit
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
              textStyle: const TextStyle(
                fontSize: 18.0, // PDA适配大字体
                fontWeight: FontWeight.w600,
              ),
              elevation: canSubmit ? 4.0 : 0.0,
            ),
          ),
        ),
      ],
    );
  }

  /// 获取提交按钮文本
  String _getSubmitButtonText(SubmissionValidationResult result, bool isSubmitting) {
    if (isSubmitting) {
      return '提交中...';
    } else if (result.isValid) {
      return '提交校验';
    } else {
      return '完成所有物料后提交 (${(result.completionPercentage * 100).toInt()}%)';
    }
  }

  /// 处理提交
  void _handleSubmission() {
    if (!SubmissionGuard.canSubmit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '请稍等，提交间隔时间太短',
            style: const TextStyle(fontSize: 16.0), // PDA适配大字体
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    SubmissionGuard.startSubmission();
    
    // 发送提交事件到 BLoC
    context.read<PickingVerificationBloc>().add(
      SubmitVerificationEvent(orderId: widget.order.orderId),
    );
  }

  /// 重置提交状态
  void _resetSubmissionState() {
    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }
    SubmissionGuard.reset();
  }

  @override
  void dispose() {
    _resetSubmissionState();
    super.dispose();
  }
}