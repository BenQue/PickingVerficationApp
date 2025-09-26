import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;

  TaskRepositoryImpl({required TaskRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<Task>> getAssignedTasks() async {
    try {
      final response = await _remoteDataSource.getAssignedTasks();
      return response.tasks.map((taskModel) => taskModel as Task).toList();
    } catch (e) {
      // Re-throw with additional context if needed
      rethrow;
    }
  }

  @override
  Future<List<Task>> refreshTasks() async {
    try {
      final response = await _remoteDataSource.refreshTasks();
      return response.tasks.map((taskModel) => taskModel as Task).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Task>> getTasksByType(TaskType type) async {
    try {
      final response = await _remoteDataSource.getTasksByType(type.value);
      return response.tasks.map((taskModel) => taskModel as Task).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Task> updateTaskStatus(String taskId, TaskStatus status) async {
    try {
      final taskModel = await _remoteDataSource.updateTaskStatus(taskId, status.value);
      return taskModel;
    } catch (e) {
      rethrow;
    }
  }
}