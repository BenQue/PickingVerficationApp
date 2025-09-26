import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:picking_verification_app/features/task_board/domain/entities/task.dart';
import 'package:picking_verification_app/features/task_board/domain/repositories/task_repository.dart';
import 'package:picking_verification_app/features/task_board/presentation/bloc/task_board_bloc.dart';
import 'package:picking_verification_app/features/task_board/presentation/bloc/task_board_event.dart';
import 'package:picking_verification_app/features/task_board/presentation/bloc/task_board_state.dart';

import 'task_board_bloc_test.mocks.dart';

@GenerateMocks([TaskRepository])
void main() {
  late TaskBoardBloc bloc;
  late MockTaskRepository mockTaskRepository;

  setUp(() {
    mockTaskRepository = MockTaskRepository();
    bloc = TaskBoardBloc(taskRepository: mockTaskRepository);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be TaskBoardInitial', () {
    expect(bloc.state, equals(const TaskBoardInitial()));
  });

  group('LoadTasksEvent', () {
    final tTasks = [
      const Task(
        id: '1',
        orderNumber: 'ORD001',
        type: TaskType.pickingVerification,
        status: TaskStatus.pending,
      ),
      const Task(
        id: '2',
        orderNumber: 'ORD002',
        type: TaskType.platformReceiving,
        status: TaskStatus.inProgress,
      ),
    ];

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits [TaskBoardLoading, TaskBoardLoaded] when LoadTasksEvent is added and getAssignedTasks succeeds',
      build: () {
        when(mockTaskRepository.getAssignedTasks())
            .thenAnswer((_) async => tTasks);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTasksEvent()),
      expect: () => [
        const TaskBoardLoading(),
        TaskBoardLoaded(allTasks: tTasks),
      ],
      verify: (_) {
        verify(mockTaskRepository.getAssignedTasks());
      },
    );

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits [TaskBoardLoading, TaskBoardEmpty] when LoadTasksEvent is added and no tasks are returned',
      build: () {
        when(mockTaskRepository.getAssignedTasks())
            .thenAnswer((_) async => []);
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTasksEvent()),
      expect: () => [
        const TaskBoardLoading(),
        const TaskBoardEmpty(),
      ],
    );

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits [TaskBoardLoading, TaskBoardError] when LoadTasksEvent is added and getAssignedTasks fails',
      build: () {
        when(mockTaskRepository.getAssignedTasks())
            .thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadTasksEvent()),
      expect: () => [
        const TaskBoardLoading(),
        const TaskBoardError('Network error'),
      ],
    );
  });

  group('RefreshTasksEvent', () {
    final tInitialTasks = [
      const Task(
        id: '1',
        orderNumber: 'ORD001',
        type: TaskType.pickingVerification,
        status: TaskStatus.pending,
      ),
    ];

    final tRefreshedTasks = [
      const Task(
        id: '1',
        orderNumber: 'ORD001',
        type: TaskType.pickingVerification,
        status: TaskStatus.pending,
      ),
      const Task(
        id: '3',
        orderNumber: 'ORD003',
        type: TaskType.lineDelivery,
        status: TaskStatus.pending,
      ),
    ];

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits [TaskBoardRefreshing, TaskBoardLoaded] when RefreshTasksEvent is added from loaded state',
      build: () {
        when(mockTaskRepository.refreshTasks())
            .thenAnswer((_) async => tRefreshedTasks);
        return bloc;
      },
      seed: () => TaskBoardLoaded(allTasks: tInitialTasks),
      act: (bloc) => bloc.add(const RefreshTasksEvent()),
      expect: () => [
        TaskBoardRefreshing(tInitialTasks),
        TaskBoardLoaded(allTasks: tRefreshedTasks),
      ],
      verify: (_) {
        verify(mockTaskRepository.refreshTasks());
      },
    );

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits [TaskBoardLoading, TaskBoardLoaded] when RefreshTasksEvent is added from initial state',
      build: () {
        when(mockTaskRepository.refreshTasks())
            .thenAnswer((_) async => tRefreshedTasks);
        return bloc;
      },
      act: (bloc) => bloc.add(const RefreshTasksEvent()),
      expect: () => [
        const TaskBoardLoading(),
        TaskBoardLoaded(allTasks: tRefreshedTasks),
      ],
    );

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits [TaskBoardRefreshing, TaskBoardError] when RefreshTasksEvent fails',
      build: () {
        when(mockTaskRepository.refreshTasks())
            .thenThrow(Exception('Refresh failed'));
        return bloc;
      },
      seed: () => TaskBoardLoaded(allTasks: tInitialTasks),
      act: (bloc) => bloc.add(const RefreshTasksEvent()),
      expect: () => [
        TaskBoardRefreshing(tInitialTasks),
        const TaskBoardError('Refresh failed'),
      ],
    );
  });

  group('FilterTasksByTypeEvent', () {
    final tTasks = [
      const Task(
        id: '1',
        orderNumber: 'ORD001',
        type: TaskType.pickingVerification,
        status: TaskStatus.pending,
      ),
      const Task(
        id: '2',
        orderNumber: 'ORD002',
        type: TaskType.platformReceiving,
        status: TaskStatus.pending,
      ),
    ];

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits updated state with filter when FilterTasksByTypeEvent is added',
      build: () => bloc,
      seed: () => TaskBoardLoaded(allTasks: tTasks),
      act: (bloc) => bloc.add(const FilterTasksByTypeEvent(TaskType.pickingVerification)),
      expect: () => [
        TaskBoardLoaded(
          allTasks: tTasks,
          selectedFilter: TaskType.pickingVerification,
        ),
      ],
    );

    blocTest<TaskBoardBloc, TaskBoardState>(
      'does not emit when FilterTasksByTypeEvent is added from non-loaded state',
      build: () => bloc,
      act: (bloc) => bloc.add(const FilterTasksByTypeEvent(TaskType.pickingVerification)),
      expect: () => [],
    );
  });

  group('UpdateTaskStatusEvent', () {
    final tTasks = [
      const Task(
        id: '1',
        orderNumber: 'ORD001',
        type: TaskType.pickingVerification,
        status: TaskStatus.pending,
      ),
      const Task(
        id: '2',
        orderNumber: 'ORD002',
        type: TaskType.platformReceiving,
        status: TaskStatus.pending,
      ),
    ];

    const tUpdatedTask = Task(
      id: '1',
      orderNumber: 'ORD001',
      type: TaskType.pickingVerification,
      status: TaskStatus.completed,
    );

    final tExpectedUpdatedTasks = [
      tUpdatedTask,
      const Task(
        id: '2',
        orderNumber: 'ORD002',
        type: TaskType.platformReceiving,
        status: TaskStatus.pending,
      ),
    ];

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits updated state with modified task when UpdateTaskStatusEvent succeeds',
      build: () {
        when(mockTaskRepository.updateTaskStatus('1', TaskStatus.completed))
            .thenAnswer((_) async => tUpdatedTask);
        return bloc;
      },
      seed: () => TaskBoardLoaded(allTasks: tTasks),
      act: (bloc) => bloc.add(const UpdateTaskStatusEvent(
        taskId: '1',
        newStatus: TaskStatus.completed,
      )),
      expect: () => [
        TaskBoardLoaded(allTasks: tExpectedUpdatedTasks),
      ],
      verify: (_) {
        verify(mockTaskRepository.updateTaskStatus('1', TaskStatus.completed));
      },
    );

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits error when UpdateTaskStatusEvent fails',
      build: () {
        when(mockTaskRepository.updateTaskStatus('1', TaskStatus.completed))
            .thenThrow(Exception('Update failed'));
        return bloc;
      },
      seed: () => TaskBoardLoaded(allTasks: tTasks),
      act: (bloc) => bloc.add(const UpdateTaskStatusEvent(
        taskId: '1',
        newStatus: TaskStatus.completed,
      )),
      expect: () => [
        const TaskBoardError('Update failed'),
      ],
    );

    blocTest<TaskBoardBloc, TaskBoardState>(
      'does not emit when UpdateTaskStatusEvent is added from non-loaded state',
      build: () => bloc,
      act: (bloc) => bloc.add(const UpdateTaskStatusEvent(
        taskId: '1',
        newStatus: TaskStatus.completed,
      )),
      expect: () => [],
    );
  });

  group('SelectTaskEvent', () {
    final tTasks = [
      const Task(
        id: '1',
        orderNumber: 'ORD001',
        type: TaskType.pickingVerification,
        status: TaskStatus.pending,
      ),
      const Task(
        id: '2',
        orderNumber: 'ORD002',
        type: TaskType.platformReceiving,
        status: TaskStatus.pending,
      ),
    ];

    const tSelectedTask = Task(
      id: '1',
      orderNumber: 'ORD001',
      type: TaskType.pickingVerification,
      status: TaskStatus.pending,
    );

    blocTest<TaskBoardBloc, TaskBoardState>(
      'emits updated state with selected task when SelectTaskEvent is added',
      build: () => bloc,
      seed: () => TaskBoardLoaded(allTasks: tTasks),
      act: (bloc) => bloc.add(const SelectTaskEvent(tSelectedTask)),
      expect: () => [
        TaskBoardLoaded(
          allTasks: tTasks,
          selectedTask: tSelectedTask,
        ),
      ],
    );

    blocTest<TaskBoardBloc, TaskBoardState>(
      'does not emit when SelectTaskEvent is added from non-loaded state',
      build: () => bloc,
      act: (bloc) => bloc.add(const SelectTaskEvent(tSelectedTask)),
      expect: () => [],
    );
  });
}