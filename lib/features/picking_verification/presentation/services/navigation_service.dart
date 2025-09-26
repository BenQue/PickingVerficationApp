import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/picking_order.dart';

/// 导航服务 - 处理拣货校验相关的导航逻辑
class PickingVerificationNavigationService {
  /// 导航到校验完成页面
  static Future<void> navigateToCompletion(
    BuildContext context, {
    required PickingOrder completedOrder,
    String? operatorId,
  }) async {
    try {
      // 将订单数据序列化为 JSON
      final orderData = _serializeOrderForNavigation(completedOrder);
      final encodedOrderData = Uri.encodeComponent(jsonEncode(orderData));
      
      // 构建查询参数
      final queryParams = <String, String>{
        'orderData': encodedOrderData,
      };
      
      if (operatorId != null) {
        queryParams['operatorId'] = operatorId;
      }
      
      // 构建完整的路径
      final path = '/verification-completion/${completedOrder.orderNumber}';
      final uri = Uri(path: path, queryParameters: queryParams);
      
      // 导航到完成页面，替换当前页面
      if (context.mounted) {
        context.go(uri.toString());
      }
    } catch (e) {
      debugPrint('Error navigating to completion screen: $e');
      // fallback navigation
      _navigateToFallbackCompletion(context, completedOrder);
    }
  }

  /// 返回到任务列表
  static void navigateToTaskList(BuildContext context) {
    context.go('/tasks');
  }

  /// 开始新的拣货校验任务
  static void navigateToNewPickingVerification(BuildContext context) {
    context.go('/picking-verification');
  }

  /// 返回到主页
  static void navigateToHome(BuildContext context) {
    context.go('/home');
  }

  /// 返回到物料列表进行修改
  static void navigateBackToMaterialList(
    BuildContext context, {
    required String orderNumber,
  }) {
    context.go('/picking-verification/$orderNumber');
  }

  /// 显示确认对话框
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
    String confirmText = '确认',
    String cancelText = '取消',
    bool isDestructive = false,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20.0, // PDA适配大字体
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            content,
            style: const TextStyle(
              fontSize: 16.0, // PDA适配大字体
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                cancelText,
                style: const TextStyle(fontSize: 16.0), // PDA适配大字体
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive ? Colors.red : null,
                minimumSize: const Size(80, 44), // PDA适配大按钮
              ),
              child: Text(
                confirmText,
                style: const TextStyle(
                  fontSize: 16.0, // PDA适配大字体
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 显示提交进度对话框
  static Future<void> showSubmissionProgressDialog(
    BuildContext context, {
    required String title,
    String? message,
    bool isDismissible = false,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: isDismissible,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: isDismissible,
          child: AlertDialog(
            title: Row(
              children: [
                const SizedBox(
                  width: 24.0,
                  height: 24.0,
                  child: CircularProgressIndicator(strokeWidth: 3.0),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18.0, // PDA适配大字体
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: message != null
                ? Text(
                    message,
                    style: const TextStyle(fontSize: 16.0), // PDA适配大字体
                  )
                : null,
          ),
        );
      },
    );
  }

  /// 关闭进度对话框
  static void closeProgressDialog(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// 显示错误对话框
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    List<String>? details,
    VoidCallback? onRetry,
    String? retryText,
  }) async {
    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 28.0, // PDA适配大图标
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20.0, // PDA适配大字体
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 16.0), // PDA适配大字体
              ),
              if (details != null && details.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                const Text(
                  '详细信息:',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8.0),
                ...details.map((detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '• $detail',
                    style: const TextStyle(fontSize: 14.0),
                  ),
                )),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                '关闭',
                style: TextStyle(fontSize: 16.0), // PDA适配大字体
              ),
            ),
            if (onRetry != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  onRetry();
                },
                child: Text(
                  retryText ?? '重试',
                  style: const TextStyle(
                    fontSize: 16.0, // PDA适配大字体
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 序列化订单数据用于导航
  static Map<String, dynamic> _serializeOrderForNavigation(PickingOrder order) {
    return {
      'id': order.orderId,
      'orderNumber': order.orderNumber,
      'productionLine': order.productionLineId,
      'status': order.status,
      'materials': order.materials.map((m) => {
        'id': m.id,
        'code': m.code,
        'name': m.name,
        'category': m.category.name,
        'requiredQuantity': m.requiredQuantity,
        'availableQuantity': m.availableQuantity,
        'status': m.status.name,
        'location': m.location,
        'unit': m.unit,
        'remarks': m.remarks,
      }).toList(),
    };
  }

  /// 备用导航方案
  static void _navigateToFallbackCompletion(
    BuildContext context,
    PickingOrder completedOrder,
  ) {
    // 简化的导航，不传递复杂数据
    context.go('/verification-completion/${completedOrder.orderNumber}');
  }

  /// 处理返回按钮逻辑
  static Future<bool> handleBackNavigation(
    BuildContext context, {
    bool hasUnsavedChanges = false,
    String? customMessage,
  }) async {
    if (!hasUnsavedChanges) {
      return true; // 允许直接返回
    }

    final confirmed = await showConfirmationDialog(
      context,
      title: '确认退出',
      content: customMessage ?? '当前有未保存的更改，确定要退出吗？',
      confirmText: '退出',
      cancelText: '继续编辑',
      isDestructive: true,
    );

    return confirmed ?? false;
  }

  /// 清理和重置导航栈
  static void clearNavigationStack(BuildContext context) {
    // 清理到首页，确保没有历史记录堆积
    context.go('/home');
  }
}