import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

abstract class TaskBoardEvent extends Equatable {
  const TaskBoardEvent();

  @override
  List<Object?> get props => [];
}

/// Load assigned tasks for the current user
class LoadTasksEvent extends TaskBoardEvent {
  const LoadTasksEvent();
}

/// Refresh task list
class RefreshTasksEvent extends TaskBoardEvent {
  const RefreshTasksEvent();
}

/// Filter tasks by type
class FilterTasksByTypeEvent extends TaskBoardEvent {
  const FilterTasksByTypeEvent(this.type);

  final TaskType? type; // null means show all types

  @override
  List<Object?> get props => [type];
}

/// Update task status
class UpdateTaskStatusEvent extends TaskBoardEvent {
  const UpdateTaskStatusEvent({
    required this.taskId,
    required this.newStatus,
  });

  final String taskId;
  final TaskStatus newStatus;

  @override
  List<Object> get props => [taskId, newStatus];
}

/// Select/deselect a task
class SelectTaskEvent extends TaskBoardEvent {
  const SelectTaskEvent(this.task);

  final Task task;

  @override
  List<Object> get props => [task];
}