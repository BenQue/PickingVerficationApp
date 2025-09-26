import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/task.dart';
import '../bloc/task_board_bloc.dart';
import '../bloc/task_board_event.dart';
import '../bloc/task_board_state.dart';
import '../widgets/task_group_section.dart';
import '../widgets/task_item_widget.dart';

class TaskBoardScreen extends StatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  State<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends State<TaskBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load tasks when screen initializes
    context.read<TaskBoardBloc>().add(const LoadTasksEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '我的任务',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: [
            _buildTab('全部', null),
            _buildTab(TaskType.pickingVerification.displayName, TaskType.pickingVerification),
            _buildTab(TaskType.platformReceiving.displayName, TaskType.platformReceiving),
            _buildTab(TaskType.lineDelivery.displayName, TaskType.lineDelivery),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            onPressed: () {
              context.read<TaskBoardBloc>().add(const RefreshTasksEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<TaskBoardBloc, TaskBoardState>(
        builder: (context, state) {
          if (state is TaskBoardLoading) {
            return _buildLoadingState();
          }

          if (state is TaskBoardRefreshing) {
            // Show current data with refresh indicator
            return Stack(
              children: [
                _buildTaskContent(state.currentTasks),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(),
                ),
              ],
            );
          }

          if (state is TaskBoardError) {
            return _buildErrorState(state.message);
          }

          if (state is TaskBoardEmpty) {
            return _buildEmptyState();
          }

          if (state is TaskBoardLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                // All tasks tab
                _buildAllTasksView(state.tasksByType),
                // Picking verification tab
                _buildSingleTypeView(
                  TaskType.pickingVerification,
                  state.tasksByType[TaskType.pickingVerification] ?? [],
                ),
                // Platform receiving tab
                _buildSingleTypeView(
                  TaskType.platformReceiving,
                  state.tasksByType[TaskType.platformReceiving] ?? [],
                ),
                // Line delivery tab
                _buildSingleTypeView(
                  TaskType.lineDelivery,
                  state.tasksByType[TaskType.lineDelivery] ?? [],
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTab(String label, TaskType? type) {
    return Tab(
      child: BlocBuilder<TaskBoardBloc, TaskBoardState>(
        builder: (context, state) {
          if (state is TaskBoardLoaded) {
            final count = type == null
                ? state.allTasks.length
                : state.taskCounts[type] ?? 0;
            
            return Row(
              children: [
                Text(label),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          }
          return Text(label);
        },
      ),
    );
  }

  Widget _buildTaskContent(List<Task> tasks) {
    final tasksByType = <TaskType, List<Task>>{};
    for (final type in TaskType.values) {
      tasksByType[type] = tasks.where((task) => task.type == type).toList();
    }
    return _buildAllTasksView(tasksByType);
  }

  Widget _buildAllTasksView(Map<TaskType, List<Task>> tasksByType) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TaskBoardBloc>().add(const RefreshTasksEvent());
      },
      child: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 80),
        children: TaskType.values.map((type) {
          return TaskGroupSection(
            taskType: type,
            tasks: tasksByType[type] ?? [],
            onTaskTap: _onTaskTap,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleTypeView(TaskType type, List<Task> tasks) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<TaskBoardBloc>().add(const RefreshTasksEvent());
      },
      child: tasks.isEmpty
          ? _buildEmptyStateForType(type)
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 80),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskItemWidget(
                  task: tasks[index],
                  onTap: () => _onTaskTap(tasks[index]),
                );
              },
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 24),
          Text(
            '正在加载任务...',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              '加载失败',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TaskBoardBloc>().add(const LoadTasksEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            const Text(
              '暂无任务',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当有新任务分配给您时，它们会显示在这里',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<TaskBoardBloc>().add(const RefreshTasksEvent());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateForType(TaskType type) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无${type.displayName}任务',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '新任务将会自动显示在这里',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTaskTap(Task task) {
    // Prepare for navigation to verification flow
    context.read<TaskBoardBloc>().add(SelectTaskEvent(task));
    
    // Navigate to order verification screen first
    // The verification screen will then route to the appropriate work interface
    context.push('/verification/${task.id}/${task.orderNumber}');
  }
}