import '../../domain/entities/material_item.dart';

/// 物料项数据模型
class MaterialItemModel {
  final String id;
  final String code;
  final String name;
  final String? description;
  final String category;
  final int requiredQuantity;
  final int availableQuantity;
  final String status;
  final String location;
  final String unit;
  final String? remarks;

  const MaterialItemModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.category,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.status,
    required this.location,
    required this.unit,
    this.remarks,
  });

  /// 从 JSON 创建模型
  factory MaterialItemModel.fromJson(Map<String, dynamic> json) {
    return MaterialItemModel(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      requiredQuantity: json['required_quantity'] as int,
      availableQuantity: json['available_quantity'] as int,
      status: json['status'] as String,
      location: json['location'] as String,
      unit: json['unit'] as String,
      remarks: json['remarks'] as String?,
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'category': category,
      'required_quantity': requiredQuantity,
      'available_quantity': availableQuantity,
      'status': status,
      'location': location,
      'unit': unit,
      'remarks': remarks,
    };
  }

  /// 转换为实体
  MaterialItem toEntity() {
    return MaterialItem(
      id: id,
      code: code,
      name: name,
      description: description,
      category: _mapCategory(category),
      requiredQuantity: requiredQuantity,
      availableQuantity: availableQuantity,
      status: _mapStatus(status),
      location: location,
      unit: unit,
      remarks: remarks,
    );
  }

  /// 从实体创建模型
  factory MaterialItemModel.fromEntity(MaterialItem entity) {
    return MaterialItemModel(
      id: entity.id,
      code: entity.code,
      name: entity.name,
      description: entity.description,
      category: _categoryToString(entity.category),
      requiredQuantity: entity.requiredQuantity,
      availableQuantity: entity.availableQuantity,
      status: _statusToString(entity.status),
      location: entity.location,
      unit: entity.unit,
      remarks: entity.remarks,
    );
  }

  /// 映射字符串到物料类别
  static MaterialCategory _mapCategory(String category) {
    switch (category.toLowerCase()) {
      case 'line_break':
      case 'linebreak':
      case '断线物料':
        return MaterialCategory.lineBreak;
      case 'central_warehouse':
      case 'centralwarehouse':
      case '中央仓物料':
        return MaterialCategory.centralWarehouse;
      case 'automated':
      case 'automation':
      case '自动化库物料':
        return MaterialCategory.automated;
      default:
        return MaterialCategory.centralWarehouse; // 默认类别
    }
  }

  /// 映射字符串到物料状态
  static MaterialStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case '待处理':
        return MaterialStatus.pending;
      case 'in_progress':
      case 'inprogress':
      case '处理中':
        return MaterialStatus.inProgress;
      case 'completed':
      case 'complete':
      case '已完成':
        return MaterialStatus.completed;
      case 'error':
      case '异常':
        return MaterialStatus.error;
      case 'missing':
      case '缺失':
        return MaterialStatus.missing;
      default:
        return MaterialStatus.pending;
    }
  }

  /// 物料类别转字符串
  static String _categoryToString(MaterialCategory category) {
    switch (category) {
      case MaterialCategory.lineBreak:
        return 'line_break';
      case MaterialCategory.centralWarehouse:
        return 'central_warehouse';
      case MaterialCategory.automated:
        return 'automated';
    }
  }

  /// 物料状态转字符串
  static String _statusToString(MaterialStatus status) {
    switch (status) {
      case MaterialStatus.pending:
        return 'pending';
      case MaterialStatus.inProgress:
        return 'in_progress';
      case MaterialStatus.completed:
        return 'completed';
      case MaterialStatus.error:
        return 'error';
      case MaterialStatus.missing:
        return 'missing';
    }
  }
}