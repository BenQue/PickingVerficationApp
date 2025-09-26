import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:picking_verification_app/features/task_board/domain/entities/task.dart';
import 'package:picking_verification_app/features/task_board/presentation/bloc/task_board_bloc.dart';
import 'package:picking_verification_app/features/task_board/presentation/bloc/task_board_event.dart';
import 'package:picking_verification_app/features/task_board/presentation/bloc/task_board_state.dart';
import 'package:picking_verification_app/features/task_board/presentation/pages/task_board_screen.dart';

import 'task_board_screen_test.mocks.dart';

@GenerateMocks([TaskBoardBloc])
void main() {
  late MockTaskBoardBloc mockTaskBoardBloc;

  setUp(() {
    mockTaskBoardBloc = MockTaskBoardBloc();
  });

  tearDown(() {
    mockTaskBoardBloc.close();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: BlocProvider<TaskBoardBloc>(
        create: (context) => mockTaskBoardBloc,
        child: const TaskBoardScreen(),
      ),
    );
  }

  group('TaskBoardScreen', () {
    testWidgets('should display loading indicator when state is TaskBoardLoading', (tester) async {
      // arrange
      when(mockTaskBoardBloc.state).thenReturn(const TaskBoardLoading());
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('正在加载任务...'), findsOneWidget);
    });

    testWidgets('should display error message when state is TaskBoardError', (tester) async {
      // arrange
      const tErrorMessage = 'Network error occurred';
      when(mockTaskBoardBloc.state).thenReturn(const TaskBoardError(tErrorMessage));
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text(tErrorMessage), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });

    testWidgets('should display empty state when state is TaskBoardEmpty', (tester) async {
      // arrange
      when(mockTaskBoardBloc.state).thenReturn(const TaskBoardEmpty());
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('暂无任务'), findsOneWidget);
      expect(find.text('当有新任务分配给您时，它们会显示在这里'), findsOneWidget);
      expect(find.text('刷新'), findsOneWidget);
    });

    testWidgets('should display task list when state is TaskBoardLoaded', (tester) async {
      // arrange
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
      
      when(mockTaskBoardBloc.state).thenReturn(TaskBoardLoaded(allTasks: tTasks));
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.text('全部'), findsOneWidget);
      // Check that task type texts exist (may appear multiple times in tabs and content)
      expect(find.textContaining('合箱校验'), findsWidgets);
      expect(find.textContaining('平台收料'), findsWidgets);  
      expect(find.textContaining('产线送料'), findsWidgets);
    });

    testWidgets('should trigger LoadTasksEvent on initialization', (tester) async {
      // arrange
      when(mockTaskBoardBloc.state).thenReturn(const TaskBoardInitial());
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      verify(mockTaskBoardBloc.add(const LoadTasksEvent())).called(1);
    });

    testWidgets('should trigger RefreshTasksEvent when refresh button is tapped', (tester) async {
      // arrange
      when(mockTaskBoardBloc.state).thenReturn(const TaskBoardLoaded(allTasks: []));
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.byIcon(Icons.refresh));

      // assert
      verify(mockTaskBoardBloc.add(const RefreshTasksEvent())).called(1);
    });

    testWidgets('should trigger LoadTasksEvent when retry button is tapped in error state', (tester) async {
      // arrange
      when(mockTaskBoardBloc.state).thenReturn(const TaskBoardError('Network error'));
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('重试'));

      // assert
      verify(mockTaskBoardBloc.add(const LoadTasksEvent())).called(2); // Called once on init + once on retry
    });

    testWidgets('should trigger RefreshTasksEvent when refresh button is tapped in empty state', (tester) async {
      // arrange
      when(mockTaskBoardBloc.state).thenReturn(const TaskBoardEmpty());
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.tap(find.text('刷新'));

      // assert
      verify(mockTaskBoardBloc.add(const RefreshTasksEvent())).called(1);
    });

    testWidgets('should display task counts in tabs when tasks are loaded', (tester) async {
      // arrange
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
          type: TaskType.pickingVerification,
          status: TaskStatus.pending,
        ),
        const Task(
          id: '3',
          orderNumber: 'ORD003',
          type: TaskType.platformReceiving,
          status: TaskStatus.pending,
        ),
      ];
      
      when(mockTaskBoardBloc.state).thenReturn(TaskBoardLoaded(allTasks: tTasks));
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      // Should show total count of 3 in "全部" tab
      expect(find.text('3'), findsWidgets);
      // Should show count of 2 in "合箱校验" tab
      expect(find.text('2'), findsWidgets);
      // Should show count of 1 in "平台收料" tab
      expect(find.text('1'), findsWidgets);
    });

    testWidgets('should show refresh indicator when state is TaskBoardRefreshing', (tester) async {
      // arrange
      final tCurrentTasks = [
        const Task(
          id: '1',
          orderNumber: 'ORD001',
          type: TaskType.pickingVerification,
          status: TaskStatus.pending,
        ),
      ];
      
      when(mockTaskBoardBloc.state).thenReturn(TaskBoardRefreshing(tCurrentTasks));
      when(mockTaskBoardBloc.stream).thenAnswer((_) => const Stream.empty());

      // act
      await tester.pumpWidget(createWidgetUnderTest());

      // assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      // Should still show existing tasks during refresh - but not in TabBarView format, in ListView format
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}