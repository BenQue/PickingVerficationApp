import '../../domain/entities/picking_order.dart';
import '../../domain/entities/material_item.dart';

/// 数据完整性验证结果
class DataIntegrityValidationResult {
  final bool isValid;
  final List<DataIntegrityIssue> issues;
  final Map<String, dynamic> metadata;

  const DataIntegrityValidationResult({
    required this.isValid,
    required this.issues,
    required this.metadata,
  });
}

/// 数据完整性问题
class DataIntegrityIssue {
  final String materialId;
  final String materialCode;
  final DataIntegrityIssueType type;
  final String description;
  final DataIntegrityIssueSeverity severity;

  const DataIntegrityIssue({
    required this.materialId,
    required this.materialCode,
    required this.type,
    required this.description,
    required this.severity,
  });
}

/// 数据完整性问题类型
enum DataIntegrityIssueType {
  missingData('数据缺失'),
  invalidData('数据无效'),
  quantityMismatch('数量不匹配'),
  statusInconsistency('状态不一致'),
  duplicateData('重复数据');

  final String label;
  const DataIntegrityIssueType(this.label);
}

/// 数据完整性问题严重程度
enum DataIntegrityIssueSeverity {
  critical('严重'),
  warning('警告'),
  info('信息');

  final String label;
  const DataIntegrityIssueSeverity(this.label);
}

/// 数据完整性验证器
class DataIntegrityValidator {
  /// 执行全面的数据完整性检查
  static DataIntegrityValidationResult validateOrderDataIntegrity(PickingOrder order) {
    final List<DataIntegrityIssue> issues = [];
    final Map<String, dynamic> metadata = {};

    // 检查订单基本信息
    _validateOrderBasicInfo(order, issues, metadata);
    
    // 检查物料数据完整性
    _validateMaterialsData(order, issues, metadata);
    
    // 检查状态一致性
    _validateStatusConsistency(order, issues, metadata);
    
    // 检查数量逻辑
    _validateQuantityLogic(order, issues, metadata);
    
    // 检查重复数据
    _validateDuplicateData(order, issues, metadata);

    // 分析问题严重程度
    final criticalIssues = issues.where((i) => i.severity == DataIntegrityIssueSeverity.critical).toList();
    final isValid = criticalIssues.isEmpty;

    return DataIntegrityValidationResult(
      isValid: isValid,
      issues: issues,
      metadata: metadata,
    );
  }

  /// 验证订单基本信息
  static void _validateOrderBasicInfo(
    PickingOrder order, 
    List<DataIntegrityIssue> issues, 
    Map<String, dynamic> metadata
  ) {
    // 订单号检查
    if (order.orderNumber.isEmpty) {
      issues.add(DataIntegrityIssue(
        materialId: '',
        materialCode: '',
        type: DataIntegrityIssueType.missingData,
        description: '订单号为空',
        severity: DataIntegrityIssueSeverity.critical,
      ));
    } else if (!RegExp(r'^[A-Z0-9]{6,20}$').hasMatch(order.orderNumber)) {
      issues.add(DataIntegrityIssue(
        materialId: '',
        materialCode: '',
        type: DataIntegrityIssueType.invalidData,
        description: '订单号格式不正确',
        severity: DataIntegrityIssueSeverity.warning,
      ));
    }

    // 生产线信息检查
    if (order.productionLineId?.isEmpty ?? true) {
      issues.add(DataIntegrityIssue(
        materialId: '',
        materialCode: '',
        type: DataIntegrityIssueType.missingData,
        description: '生产线ID缺失',
        severity: DataIntegrityIssueSeverity.warning,
      ));
    }

    metadata['orderBasicInfoChecked'] = true;
    metadata['orderNumber'] = order.orderNumber;
  }

  /// 验证物料数据完整性
  static void _validateMaterialsData(
    PickingOrder order, 
    List<DataIntegrityIssue> issues, 
    Map<String, dynamic> metadata
  ) {
    final materialIds = <String>[];
    final materialCodes = <String>[];

    for (final material in order.materials) {
      // ID检查
      if (material.id.isEmpty) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.missingData,
          description: '物料ID为空',
          severity: DataIntegrityIssueSeverity.critical,
        ));
      } else if (materialIds.contains(material.id)) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.duplicateData,
          description: '物料ID重复: ${material.id}',
          severity: DataIntegrityIssueSeverity.critical,
        ));
      } else {
        materialIds.add(material.id);
      }

      // 编码检查
      if (material.code.isEmpty) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.missingData,
          description: '物料编码为空',
          severity: DataIntegrityIssueSeverity.critical,
        ));
      } else if (materialCodes.contains(material.code)) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.duplicateData,
          description: '物料编码重复: ${material.code}',
          severity: DataIntegrityIssueSeverity.warning,
        ));
      } else {
        materialCodes.add(material.code);
      }

      // 名称检查
      if (material.name.isEmpty) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.missingData,
          description: '物料名称为空',
          severity: DataIntegrityIssueSeverity.warning,
        ));
      }

      // 位置检查
      if (material.location.isEmpty) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.missingData,
          description: '存储位置为空',
          severity: DataIntegrityIssueSeverity.warning,
        ));
      }
    }

    metadata['materialsCount'] = order.materials.length;
    metadata['uniqueIds'] = materialIds.length;
    metadata['uniqueCodes'] = materialCodes.length;
  }

  /// 验证状态一致性
  static void _validateStatusConsistency(
    PickingOrder order, 
    List<DataIntegrityIssue> issues, 
    Map<String, dynamic> metadata
  ) {
    final statusCounts = <MaterialStatus, int>{};

    for (final material in order.materials) {
      statusCounts[material.status] = (statusCounts[material.status] ?? 0) + 1;

      // 检查完成状态的逻辑一致性
      if (material.status == MaterialStatus.completed) {
        if (material.availableQuantity < material.requiredQuantity) {
          issues.add(DataIntegrityIssue(
            materialId: material.id,
            materialCode: material.code,
            type: DataIntegrityIssueType.statusInconsistency,
            description: '标记为完成但数量不足',
            severity: DataIntegrityIssueSeverity.critical,
          ));
        }
      }

      // 检查异常状态的逻辑
      if (material.status == MaterialStatus.error && 
          (material.remarks?.isEmpty ?? true)) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.statusInconsistency,
          description: '异常状态但无备注说明',
          severity: DataIntegrityIssueSeverity.warning,
        ));
      }

      // 检查缺失状态的逻辑
      if (material.status == MaterialStatus.missing && 
          material.availableQuantity > 0) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.statusInconsistency,
          description: '标记为缺失但有可用数量',
          severity: DataIntegrityIssueSeverity.warning,
        ));
      }
    }

    metadata['statusDistribution'] = statusCounts;
  }

  /// 验证数量逻辑
  static void _validateQuantityLogic(
    PickingOrder order, 
    List<DataIntegrityIssue> issues, 
    Map<String, dynamic> metadata
  ) {
    int totalQuantityIssues = 0;

    for (final material in order.materials) {
      // 需求数量检查
      if (material.requiredQuantity <= 0) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.invalidData,
          description: '需求数量必须大于0',
          severity: DataIntegrityIssueSeverity.critical,
        ));
        totalQuantityIssues++;
      }

      // 可用数量检查
      if (material.availableQuantity < 0) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.invalidData,
          description: '可用数量不能为负数',
          severity: DataIntegrityIssueSeverity.critical,
        ));
        totalQuantityIssues++;
      }

      // 数量关系检查
      if (material.availableQuantity > material.requiredQuantity * 2) {
        issues.add(DataIntegrityIssue(
          materialId: material.id,
          materialCode: material.code,
          type: DataIntegrityIssueType.quantityMismatch,
          description: '可用数量异常高于需求数量',
          severity: DataIntegrityIssueSeverity.info,
        ));
      }
    }

    metadata['quantityIssuesCount'] = totalQuantityIssues;
  }

  /// 验证重复数据
  static void _validateDuplicateData(
    PickingOrder order, 
    List<DataIntegrityIssue> issues, 
    Map<String, dynamic> metadata
  ) {
    final Map<String, List<MaterialItem>> codeGroups = {};
    
    // 按编码分组
    for (final material in order.materials) {
      codeGroups.putIfAbsent(material.code, () => []).add(material);
    }

    // 检查同编码物料的一致性
    for (final entry in codeGroups.entries) {
      if (entry.value.length > 1) {
        final firstMaterial = entry.value.first;
        
        for (int i = 1; i < entry.value.length; i++) {
          final material = entry.value[i];
          
          if (material.name != firstMaterial.name) {
            issues.add(DataIntegrityIssue(
              materialId: material.id,
              materialCode: material.code,
              type: DataIntegrityIssueType.duplicateData,
              description: '相同编码的物料名称不一致',
              severity: DataIntegrityIssueSeverity.warning,
            ));
          }
          
          if (material.unit != firstMaterial.unit) {
            issues.add(DataIntegrityIssue(
              materialId: material.id,
              materialCode: material.code,
              type: DataIntegrityIssueType.duplicateData,
              description: '相同编码的物料单位不一致',
              severity: DataIntegrityIssueSeverity.warning,
            ));
          }
        }
      }
    }

    metadata['duplicateCodeGroups'] = codeGroups.length;
  }

  /// 获取验证摘要
  static Map<String, dynamic> getValidationSummary(DataIntegrityValidationResult result) {
    final criticalCount = result.issues.where((i) => i.severity == DataIntegrityIssueSeverity.critical).length;
    final warningCount = result.issues.where((i) => i.severity == DataIntegrityIssueSeverity.warning).length;
    final infoCount = result.issues.where((i) => i.severity == DataIntegrityIssueSeverity.info).length;

    return {
      'isValid': result.isValid,
      'totalIssues': result.issues.length,
      'criticalIssues': criticalCount,
      'warningIssues': warningCount,
      'infoIssues': infoCount,
      'canProceedWithWarnings': criticalCount == 0,
      'metadata': result.metadata,
    };
  }
}