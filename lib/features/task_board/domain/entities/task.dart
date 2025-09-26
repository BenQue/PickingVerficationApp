import 'package:equatable/equatable.dart';

enum TaskType {
  pickingVerification('picking_verification', '合箱校验'),
  platformReceiving('platform_receiving', '平台收料'),
  lineDelivery('line_delivery', '产线送料');

  const TaskType(this.value, this.displayName);

  final String value;
  final String displayName;

  static TaskType fromString(String value) {
    return TaskType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TaskType.pickingVerification,
    );
  }
}

enum TaskStatus {
  pending('pending', '待处理'),
  inProgress('in_progress', '进行中'),
  completed('completed', '已完成'),
  cancelled('cancelled', '已取消');

  const TaskStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

class Task extends Equatable {
  const Task({
    required this.id,
    required this.orderNumber,
    required this.type,
    required this.status,
    this.assignedTo,
    this.priority,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  final String id;
  final String orderNumber;
  final TaskType type;
  final TaskStatus status;
  final String? assignedTo;
  final int? priority;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        type,
        status,
        assignedTo,
        priority,
        dueDate,
        createdAt,
        updatedAt,
        metadata,
      ];

  Task copyWith({
    String? id,
    String? orderNumber,
    TaskType? type,
    TaskStatus? status,
    String? assignedTo,
    int? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Task(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      type: type ?? this.type,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}