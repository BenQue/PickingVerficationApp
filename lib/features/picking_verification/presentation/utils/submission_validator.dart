import '../../domain/entities/picking_order.dart';
import '../../domain/entities/material_item.dart';

/// 提交校验结果
class SubmissionValidationResult {
  final bool isValid;
  final List<String> errors;
  final Map<MaterialCategory, int> categoryCompletionStatus;
  final double completionPercentage;

  const SubmissionValidationResult({
    required this.isValid,
    required this.errors,
    required this.categoryCompletionStatus,
    required this.completionPercentage,
  });
}

/// 提交校验工具类
class SubmissionValidator {
  /// 验证订单是否可以提交
  static SubmissionValidationResult validateOrderSubmission(PickingOrder order) {
    final List<String> errors = [];
    final Map<MaterialCategory, int> categoryStatus = {};

    // 检查订单基本信息
    if (order.orderNumber.isEmpty) {
      errors.add('订单号不能为空');
    }

    if (order.materials.isEmpty) {
      errors.add('订单中没有物料项目');
      return SubmissionValidationResult(
        isValid: false,
        errors: errors,
        categoryCompletionStatus: categoryStatus,
        completionPercentage: 0.0,
      );
    }

    // 按类别统计完成情况
    for (final category in MaterialCategory.values) {
      final categoryMaterials = order.materials.where((m) => m.category == category).toList();
      final completedCount = categoryMaterials.where((m) => m.status == MaterialStatus.completed).length;
      
      categoryStatus[category] = completedCount;
      
      if (categoryMaterials.isNotEmpty && completedCount == 0) {
        errors.add('${category.label}类别中没有已完成的物料');
      }
    }

    // 检查所有物料状态
    final totalMaterials = order.materials.length;
    final completedMaterials = order.materials.where((m) => m.status == MaterialStatus.completed).length;
    final errorMaterials = order.materials.where((m) => m.status == MaterialStatus.error).toList();
    final missingMaterials = order.materials.where((m) => m.status == MaterialStatus.missing).toList();
    final pendingMaterials = order.materials.where((m) => m.status == MaterialStatus.pending).toList();
    final inProgressMaterials = order.materials.where((m) => m.status == MaterialStatus.inProgress).toList();

    final completionPercentage = totalMaterials > 0 ? (completedMaterials / totalMaterials) : 0.0;

    // 所有物料必须处于完成状态才能提交
    if (completedMaterials < totalMaterials) {
      if (pendingMaterials.isNotEmpty) {
        errors.add('还有 ${pendingMaterials.length} 个物料待处理');
      }
      if (inProgressMaterials.isNotEmpty) {
        errors.add('还有 ${inProgressMaterials.length} 个物料正在处理中');
      }
      if (errorMaterials.isNotEmpty) {
        errors.add('有 ${errorMaterials.length} 个物料状态异常，需要处理');
      }
      if (missingMaterials.isNotEmpty) {
        errors.add('有 ${missingMaterials.length} 个物料缺失，需要确认');
      }
    }

    // 检查数据完整性
    final materialsWithoutRequiredData = order.materials.where((m) => 
      m.code.isEmpty || m.name.isEmpty || m.requiredQuantity <= 0
    ).toList();

    if (materialsWithoutRequiredData.isNotEmpty) {
      errors.add('有 ${materialsWithoutRequiredData.length} 个物料数据不完整');
    }

    // 检查数量匹配
    final quantityMismatchMaterials = order.materials.where((m) => 
      m.status == MaterialStatus.completed && !m.isFulfilled
    ).toList();

    if (quantityMismatchMaterials.isNotEmpty) {
      errors.add('有 ${quantityMismatchMaterials.length} 个物料数量不匹配');
    }

    return SubmissionValidationResult(
      isValid: errors.isEmpty && completedMaterials == totalMaterials,
      errors: errors,
      categoryCompletionStatus: categoryStatus,
      completionPercentage: completionPercentage,
    );
  }

  /// 检查是否可以启用提交按钮
  static bool canEnableSubmitButton(PickingOrder order) {
    final result = validateOrderSubmission(order);
    return result.isValid;
  }

  /// 获取提交按钮状态文本
  static String getSubmitButtonText(PickingOrder order) {
    final result = validateOrderSubmission(order);
    
    if (result.isValid) {
      return '提交校验';
    } else {
      return '完成所有物料后提交 (${(result.completionPercentage * 100).toInt()}%)';
    }
  }

  /// 获取详细的验证错误信息
  static List<String> getValidationMessages(PickingOrder order) {
    final result = validateOrderSubmission(order);
    return result.errors;
  }

  /// 检查特定类别的完成状态
  static bool isCategoryCompleted(PickingOrder order, MaterialCategory category) {
    final categoryMaterials = order.materials.where((m) => m.category == category).toList();
    if (categoryMaterials.isEmpty) return true;
    
    return categoryMaterials.every((m) => m.status == MaterialStatus.completed);
  }

  /// 获取类别完成进度
  static double getCategoryCompletionProgress(PickingOrder order, MaterialCategory category) {
    final categoryMaterials = order.materials.where((m) => m.category == category).toList();
    if (categoryMaterials.isEmpty) return 1.0;
    
    final completedCount = categoryMaterials.where((m) => m.status == MaterialStatus.completed).length;
    return completedCount / categoryMaterials.length;
  }

  /// 获取整体完成进度
  static double getOverallCompletionProgress(PickingOrder order) {
    if (order.materials.isEmpty) return 0.0;
    
    final completedCount = order.materials.where((m) => m.status == MaterialStatus.completed).length;
    return completedCount / order.materials.length;
  }

  /// 检查是否有阻塞性问题
  static List<String> getBlockingIssues(PickingOrder order) {
    final List<String> blockingIssues = [];
    
    // 检查异常状态的物料
    final errorMaterials = order.materials.where((m) => m.status == MaterialStatus.error).toList();
    if (errorMaterials.isNotEmpty) {
      blockingIssues.add('有 ${errorMaterials.length} 个物料状态异常');
    }
    
    // 检查缺失的物料
    final missingMaterials = order.materials.where((m) => m.status == MaterialStatus.missing).toList();
    if (missingMaterials.isNotEmpty) {
      blockingIssues.add('有 ${missingMaterials.length} 个物料缺失');
    }
    
    // 检查数量不足的物料
    final shortfallMaterials = order.materials.where((m) => m.shortageQuantity > 0).toList();
    if (shortfallMaterials.isNotEmpty) {
      blockingIssues.add('有 ${shortfallMaterials.length} 个物料数量不足');
    }
    
    return blockingIssues;
  }
}

/// 重复提交防护状态
enum SubmissionState {
  idle('空闲'),
  submitting('提交中'),
  completed('已完成'),
  failed('失败');

  final String label;
  const SubmissionState(this.label);
}

/// 重复提交防护管理器
class SubmissionGuard {
  static SubmissionState _currentState = SubmissionState.idle;
  static DateTime? _lastSubmissionTime;
  static const int _minSubmissionIntervalMs = 2000; // 最小提交间隔2秒

  /// 检查是否可以提交
  static bool canSubmit() {
    if (_currentState == SubmissionState.submitting) {
      return false;
    }
    
    if (_lastSubmissionTime != null) {
      final timeSinceLastSubmission = DateTime.now().millisecondsSinceEpoch - 
          _lastSubmissionTime!.millisecondsSinceEpoch;
      if (timeSinceLastSubmission < _minSubmissionIntervalMs) {
        return false;
      }
    }
    
    return true;
  }

  /// 开始提交
  static void startSubmission() {
    _currentState = SubmissionState.submitting;
    _lastSubmissionTime = DateTime.now();
  }

  /// 完成提交
  static void completeSubmission() {
    _currentState = SubmissionState.completed;
  }

  /// 失败提交
  static void failSubmission() {
    _currentState = SubmissionState.failed;
  }

  /// 重置状态
  static void reset() {
    _currentState = SubmissionState.idle;
  }

  /// 获取当前状态
  static SubmissionState getCurrentState() {
    return _currentState;
  }

  /// 获取状态描述
  static String getStateDescription() {
    return _currentState.label;
  }
}