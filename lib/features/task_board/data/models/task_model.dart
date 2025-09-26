import '../../domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.orderNumber,
    required super.type,
    required super.status,
    super.assignedTo,
    super.priority,
    super.dueDate,
    super.createdAt,
    super.updatedAt,
    super.metadata,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      type: TaskType.fromString(json['type'] as String),
      status: TaskStatus.fromString(json['status'] as String),
      assignedTo: json['assigned_to'] as String?,
      priority: json['priority'] as int?,
      dueDate: json['due_date'] != null 
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'type': type.value,
      'status': status.value,
      'assigned_to': assignedTo,
      'priority': priority,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory TaskModel.fromEntity(Task task) {
    return TaskModel(
      id: task.id,
      orderNumber: task.orderNumber,
      type: task.type,
      status: task.status,
      assignedTo: task.assignedTo,
      priority: task.priority,
      dueDate: task.dueDate,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      metadata: task.metadata,
    );
  }
}