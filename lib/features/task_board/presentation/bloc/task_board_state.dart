import 'package:equatable/equatable.dart';
import '../../domain/entities/task.dart';

abstract class TaskBoardState extends Equatable {
  const TaskBoardState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TaskBoardInitial extends TaskBoardState {
  const TaskBoardInitial();
}

/// Loading state
class TaskBoardLoading extends TaskBoardState {
  const TaskBoardLoading();
}

/// Refreshing state (when refreshing existing data)
class TaskBoardRefreshing extends TaskBoardState {
  const TaskBoardRefreshing(this.currentTasks);

  final List<Task> currentTasks;

  @override
  List<Object> get props => [currentTasks];
}

/// Successfully loaded tasks
class TaskBoardLoaded extends TaskBoardState {
  const TaskBoardLoaded({
    required this.allTasks,
    this.selectedFilter,
    this.selectedTask,
  });

  final List<Task> allTasks;
  final TaskType? selectedFilter;
  final Task? selectedTask;

  /// Get tasks grouped by type
  Map<TaskType, List<Task>> get tasksByType {
    final Map<TaskType, List<Task>> grouped = {};
    
    for (final type in TaskType.values) {
      grouped[type] = allTasks.where((task) => task.type == type).toList();
    }
    
    return grouped;
  }

  /// Get filtered tasks based on selected filter
  List<Task> get filteredTasks {
    if (selectedFilter == null) {
      return allTasks;
    }
    return allTasks.where((task) => task.type == selectedFilter).toList();
  }

  /// Get count for each task type
  Map<TaskType, int> get taskCounts {
    final Map<TaskType, int> counts = {};
    
    for (final type in TaskType.values) {
      counts[type] = allTasks.where((task) => task.type == type).length;
    }
    
    return counts;
  }

  @override
  List<Object?> get props => [allTasks, selectedFilter, selectedTask];

  TaskBoardLoaded copyWith({
    List<Task>? allTasks,
    TaskType? selectedFilter,
    Task? selectedTask,
  }) {
    return TaskBoardLoaded(
      allTasks: allTasks ?? this.allTasks,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      selectedTask: selectedTask ?? this.selectedTask,
    );
  }
}

/// Error state
class TaskBoardError extends TaskBoardState {
  const TaskBoardError(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

/// Empty state (no tasks)
class TaskBoardEmpty extends TaskBoardState {
  const TaskBoardEmpty();
}