# 功能改进计划

本文档记录了已识别但尚未实施的功能改进项。

## 1. 提交超时/错误后的重试功能

**优先级**: P1 - 重要改进
**状态**: 待实施
**记录日期**: 2025-11-04
**影响范围**: 合箱校验提交流程

### 问题描述

当前实现中，提交校验到服务器时如果发生超时或网络错误：

**现状**:
- ✅ 防重复提交保护正常工作（四层保护机制）
- ✅ 提交成功后正常导航到完成页面
- ❌ 超时/错误后按钮永久禁用
- ❌ 用户无法重试，必须退出页面重新扫描订单
- ❌ 没有错误提示给用户

**技术细节**:
```dart
// submission_controls_widget.dart 第33-42行
// 当前只监听成功状态
context.read<PickingVerificationBloc>().stream.listen((state) {
  if (state is SubmissionSuccess && mounted) {
    // 导航到完成页面
  }
  // ❌ 缺少对 SubmissionError 的处理
});
```

**超时配置**:
- 全局超时：10秒（连接/发送/接收）
- 提交请求超时：发送30秒，接收60秒
- 自动重试：最多3次，指数退避延迟

### 用户体验影响

**场景1**: 用户在信号较弱的区域提交
- 等待60秒后超时
- 按钮变灰，无任何提示
- 用户不知道发生了什么
- 必须退出重新扫描（浪费时间）

**场景2**: 服务器暂时性故障
- 提交失败
- 用户无法立即重试
- 需要重新执行整个流程

### 建议的解决方案

#### 方案A: 最小改动（快速修复）

**修改文件**: `lib/features/picking_verification/presentation/widgets/submission_controls_widget.dart`

**代码变更**:
```dart
@override
void initState() {
  super.initState();

  // 监听BLoC状态变化
  context.read<PickingVerificationBloc>().stream.listen((state) {
    if (state is SubmissionSuccess && mounted) {
      // 成功：导航到完成页面
      PickingVerificationNavigationService.navigateToCompletion(
        context,
        completedOrder: state.order,
        operatorId: state.operatorId,
      );
    } else if (state is SubmissionError && mounted) {
      // ❗ 新增：错误处理
      _resetSubmissionState();  // 重置状态允许重试

      // 显示错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            state.errorMessage,
            style: const TextStyle(fontSize: 16.0),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          action: state.canRetry
              ? SnackBarAction(
                  label: '重试',
                  textColor: Colors.white,
                  onPressed: () {
                    // 触发重试事件
                    context.read<PickingVerificationBloc>().add(
                      RetrySubmissionEvent(
                        orderId: widget.order.orderId,
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    }
  });
}

// _resetSubmissionState 方法已存在（第383-390行），无需修改
```

**工作量估算**: 1-2小时
- 代码修改：20行
- 测试：网络超时场景、错误重试流程
- 回归测试：正常提交流程

#### 方案B: 完整改进（推荐）

在方案A基础上，添加更好的用户体验：

**1. 错误对话框代替SnackBar**
```dart
void _showErrorDialog(SubmissionError state) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 28),
          const SizedBox(width: 12),
          const Text('提交失败'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.errorMessage,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            '错误类型: ${state.errorType.label}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (state.errorType == SubmissionErrorType.timeoutError) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '提示：请检查网络信号后重试',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(fontSize: 16),
          ),
        ),
        if (state.canRetry)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PickingVerificationBloc>().add(
                RetrySubmissionEvent(
                  orderId: state.order.orderId,
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text(
              '重试',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 44),
            ),
          ),
      ],
    ),
  );
}
```

**2. 提交进度对话框**
显示提交的各个步骤，让用户了解进度：
```dart
void _showSubmissionProgressDialog(SubmissionInProgress state) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            state.currentStep ?? '处理中...',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: state.progress,
          ),
        ],
      ),
    ),
  );
}
```

**工作量估算**: 4-6小时
- 代码修改：100行
- UI设计：错误对话框样式
- 测试：各种错误类型、进度显示
- 回归测试：完整提交流程

#### 方案C: 完整解决方案（最优）

在方案B基础上，改进SubmissionGuard自动恢复：

```dart
// submission_validator.dart
class SubmissionGuard {
  // ... 现有代码 ...

  static void failSubmission() {
    _currentState = SubmissionState.failed;
    // ❗ 添加：失败后延迟自动重置
    Future.delayed(
      Duration(milliseconds: _minSubmissionIntervalMs),
      () {
        if (_currentState == SubmissionState.failed) {
          reset();
        }
      },
    );
  }

  static void completeSubmission() {
    _currentState = SubmissionState.completed;
    // ❗ 添加：成功后快速重置
    Future.delayed(
      const Duration(milliseconds: 100),
      () {
        if (_currentState == SubmissionState.completed) {
          reset();
        }
      },
    );
  }
}
```

**工作量估算**: 6-8小时
- 包含方案B的所有内容
- 额外修改：SubmissionGuard自动恢复机制
- 额外测试：状态自动恢复逻辑

### 实施建议

**短期（1-2周内）**: 实施方案A
- 快速修复用户痛点
- 风险低，改动小
- 可快速上线

**中期（1个月内）**: 实施方案B
- 提供更好的用户体验
- 完善错误提示和引导
- 需要更多测试时间

**长期（2-3个月内）**: 实施方案C
- 完整的错误恢复机制
- 最佳用户体验
- 需要充分的测试周期

### 测试要点

**功能测试**:
1. 模拟网络超时（60秒）
2. 模拟服务器错误（500）
3. 模拟网络中断
4. 验证重试功能
5. 验证错误提示显示

**回归测试**:
1. 正常提交流程不受影响
2. 防重复提交保护仍然有效
3. 提交成功后正常导航

**边界测试**:
1. 快速连续点击重试按钮
2. 重试过程中切换应用
3. 多次重试后的行为

### 相关文件

**需要修改的文件**:
- `lib/features/picking_verification/presentation/widgets/submission_controls_widget.dart`
- （可选）`lib/features/picking_verification/presentation/utils/submission_validator.dart`

**相关BLoC状态**:
- `SubmissionError` - 错误状态，包含 `canRetry` 标志
- `SubmissionInProgress` - 进度状态，包含 `currentStep` 和 `progress`

**相关事件**:
- `RetrySubmissionEvent` - 已实现，可直接使用

### 风险评估

**低风险**:
- ✅ 不影响现有防重复提交功能
- ✅ 只添加错误处理，不修改核心流程
- ✅ 后端已支持重试（RetrySubmissionEvent已存在）

**中等风险**:
- ⚠️ 需要测试各种错误场景
- ⚠️ 可能影响用户操作流程

**高风险**:
- ❌ 无

### 备注

- 当前的"BUG"（超时后按钮禁用）虽然防止了重复提交，但用户体验很差
- 建议优先实施方案A作为快速修复
- 后续可以逐步升级到方案B或C

---

## 2. 其他待改进项

### 2.1 SubmissionGuard 全局单例问题
- 当前使用静态单例，可能在多任务场景下产生干扰
- 建议改为基于订单ID的独立实例

### 2.2 提交进度可视化
- 当前只有简单的Loading状态
- 可以显示具体的提交步骤和进度百分比

### 2.3 离线提交队列
- 当网络不可用时，保存提交请求到本地队列
- 网络恢复后自动重试

---

**最后更新**: 2025-11-04
**维护者**: Development Team
