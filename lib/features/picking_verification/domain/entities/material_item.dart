import 'package:equatable/equatable.dart';

/// 物料状态枚举
enum MaterialStatus {
  pending('待处理'),
  inProgress('处理中'),
  completed('已完成'),
  error('异常'),
  missing('缺失');

  final String label;
  const MaterialStatus(this.label);
}

/// 物料类别枚举
enum MaterialCategory {
  lineBreak('断线物料'),
  centralWarehouse('中央仓物料'),
  automated('自动化库物料');

  final String label;
  const MaterialCategory(this.label);
}

/// 物料项实体
class MaterialItem extends Equatable {
  /// 物料ID
  final String id;
  
  /// 物料编码
  final String code;
  
  /// 物料名称
  final String name;
  
  /// 物料描述
  final String? description;
  
  /// 所属类别
  final MaterialCategory category;
  
  /// 需求数量
  final int requiredQuantity;
  
  /// 可用数量
  final int availableQuantity;
  
  /// 当前状态
  final MaterialStatus status;
  
  /// 存储位置
  final String location;
  
  /// 单位
  final String unit;
  
  /// 备注信息
  final String? remarks;

  const MaterialItem({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.category,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.status,
    required this.location,
    this.unit = '个',
    this.remarks,
  });

  /// 检查物料是否满足需求
  bool get isFulfilled => availableQuantity >= requiredQuantity;

  /// 获取短缺数量
  int get shortageQuantity {
    final shortage = requiredQuantity - availableQuantity;
    return shortage > 0 ? shortage : 0;
  }

  /// 复制并更新物料项
  MaterialItem copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    MaterialCategory? category,
    int? requiredQuantity,
    int? availableQuantity,
    MaterialStatus? status,
    String? location,
    String? unit,
    String? remarks,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      requiredQuantity: requiredQuantity ?? this.requiredQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      status: status ?? this.status,
      location: location ?? this.location,
      unit: unit ?? this.unit,
      remarks: remarks ?? this.remarks,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        description,
        category,
        requiredQuantity,
        availableQuantity,
        status,
        location,
        unit,
        remarks,
      ];
}