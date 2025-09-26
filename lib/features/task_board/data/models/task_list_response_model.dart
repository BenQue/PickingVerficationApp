import 'task_model.dart';

class TaskListResponseModel {
  const TaskListResponseModel({
    required this.tasks,
    required this.total,
    this.hasMore = false,
    this.nextPageToken,
  });

  final List<TaskModel> tasks;
  final int total;
  final bool hasMore;
  final String? nextPageToken;

  factory TaskListResponseModel.fromJson(Map<String, dynamic> json) {
    final tasksJson = json['tasks'] as List<dynamic>? ?? [];
    final tasks = tasksJson
        .map((taskJson) => TaskModel.fromJson(taskJson as Map<String, dynamic>))
        .toList();

    return TaskListResponseModel(
      tasks: tasks,
      total: json['total'] as int? ?? tasks.length,
      hasMore: json['has_more'] as bool? ?? false,
      nextPageToken: json['next_page_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'total': total,
      'has_more': hasMore,
      'next_page_token': nextPageToken,
    };
  }
}