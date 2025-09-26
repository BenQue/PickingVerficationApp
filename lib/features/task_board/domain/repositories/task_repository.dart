import '../entities/task.dart';

abstract class TaskRepository {
  /// Get assigned tasks for the current user
  Future<List<Task>> getAssignedTasks();
  
  /// Refresh task list
  Future<List<Task>> refreshTasks();
  
  /// Get tasks filtered by type
  Future<List<Task>> getTasksByType(TaskType type);
  
  /// Update task status
  Future<Task> updateTaskStatus(String taskId, TaskStatus status);
}