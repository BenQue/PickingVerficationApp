import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_board_event.dart';
import 'task_board_state.dart';

class TaskBoardBloc extends Bloc<TaskBoardEvent, TaskBoardState> {
  final TaskRepository _taskRepository;
  List<Task> _allTasks = [];

  TaskBoardBloc({required TaskRepository taskRepository})
      : _taskRepository = taskRepository,
        super(const TaskBoardInitial()) {
    on<LoadTasksEvent>(_onLoadTasks);
    on<RefreshTasksEvent>(_onRefreshTasks);
    on<FilterTasksByTypeEvent>(_onFilterTasksByType);
    on<UpdateTaskStatusEvent>(_onUpdateTaskStatus);
    on<SelectTaskEvent>(_onSelectTask);
  }

  Future<void> _onLoadTasks(
    LoadTasksEvent event,
    Emitter<TaskBoardState> emit,
  ) async {
    emit(const TaskBoardLoading());

    try {
      final tasks = await _taskRepository.getAssignedTasks();
      _allTasks = tasks;

      if (tasks.isEmpty) {
        emit(const TaskBoardEmpty());
      } else {
        emit(TaskBoardLoaded(allTasks: tasks));
      }
    } catch (e) {
      emit(TaskBoardError(_getErrorMessage(e)));
    }
  }

  Future<void> _onRefreshTasks(
    RefreshTasksEvent event,
    Emitter<TaskBoardState> emit,
  ) async {
    if (state is TaskBoardLoaded) {
      emit(TaskBoardRefreshing(_allTasks));
    } else {
      emit(const TaskBoardLoading());
    }

    try {
      final tasks = await _taskRepository.refreshTasks();
      _allTasks = tasks;

      if (tasks.isEmpty) {
        emit(const TaskBoardEmpty());
      } else {
        final currentState = state;
        if (currentState is TaskBoardLoaded) {
          emit(TaskBoardLoaded(
            allTasks: tasks,
            selectedFilter: currentState.selectedFilter,
            selectedTask: currentState.selectedTask,
          ));
        } else {
          emit(TaskBoardLoaded(allTasks: tasks));
        }
      }
    } catch (e) {
      emit(TaskBoardError(_getErrorMessage(e)));
    }
  }

  Future<void> _onFilterTasksByType(
    FilterTasksByTypeEvent event,
    Emitter<TaskBoardState> emit,
  ) async {
    final currentState = state;
    if (currentState is TaskBoardLoaded) {
      emit(currentState.copyWith(selectedFilter: event.type));
    }
  }

  Future<void> _onUpdateTaskStatus(
    UpdateTaskStatusEvent event,
    Emitter<TaskBoardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TaskBoardLoaded) return;

    try {
      final updatedTask = await _taskRepository.updateTaskStatus(
        event.taskId,
        event.newStatus,
      );

      // Update the task in the list
      final updatedTasks = _allTasks.map((task) {
        if (task.id == event.taskId) {
          return updatedTask;
        }
        return task;
      }).toList();

      _allTasks = updatedTasks;

      emit(currentState.copyWith(
        allTasks: updatedTasks,
        selectedTask: currentState.selectedTask?.id == event.taskId
            ? updatedTask
            : currentState.selectedTask,
      ));
    } catch (e) {
      emit(TaskBoardError(_getErrorMessage(e)));
    }
  }

  Future<void> _onSelectTask(
    SelectTaskEvent event,
    Emitter<TaskBoardState> emit,
  ) async {
    final currentState = state;
    if (currentState is TaskBoardLoaded) {
      emit(currentState.copyWith(selectedTask: event.task));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      // Remove "Exception: " prefix if present
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      return message;
    }
    return '发生未知错误，请稍后重试';
  }
}