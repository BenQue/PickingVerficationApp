import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:picking_verification_app/features/task_board/data/datasources/task_remote_datasource.dart';
import 'package:picking_verification_app/features/task_board/data/models/task_list_response_model.dart';
import 'package:picking_verification_app/features/task_board/data/models/task_model.dart';
import 'package:picking_verification_app/features/task_board/data/repositories/task_repository_impl.dart';
import 'package:picking_verification_app/features/task_board/domain/entities/task.dart';

import 'task_repository_impl_test.mocks.dart';

@GenerateMocks([TaskRemoteDataSource])
void main() {
  late TaskRepositoryImpl repository;
  late MockTaskRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockTaskRemoteDataSource();
    repository = TaskRepositoryImpl(remoteDataSource: mockRemoteDataSource);
  });

  group('getAssignedTasks', () {
    final tTaskModels = [
      const TaskModel(
        id: '1',
        orderNumber: 'ORD001',
        type: TaskType.pickingVerification,
        status: TaskStatus.pending,
      ),
      const TaskModel(
        id: '2',
        orderNumber: 'ORD002',
        type: TaskType.platformReceiving,
        status: TaskStatus.inProgress,
      ),
    ];

    final tTaskListResponse = TaskListResponseModel(
      tasks: tTaskModels,
      total: 2,
    );

    test('should return list of tasks when call to remote data source is successful', () async {
      // arrange
      when(mockRemoteDataSource.getAssignedTasks())
          .thenAnswer((_) async => tTaskListResponse);

      // act
      final result = await repository.getAssignedTasks();

      // assert
      verify(mockRemoteDataSource.getAssignedTasks());
      expect(result, isA<List<Task>>());
      expect(result.length, equals(2));
      expect(result[0].id, equals('1'));
      expect(result[1].id, equals('2'));
    });

    test('should throw exception when call to remote data source fails', () async {
      // arrange
      when(mockRemoteDataSource.getAssignedTasks())
          .thenThrow(Exception('Network error'));

      // act
      final call = repository.getAssignedTasks();

      // assert
      expect(call, throwsException);
      verify(mockRemoteDataSource.getAssignedTasks());
    });
  });

  group('refreshTasks', () {
    final tTaskModels = [
      const TaskModel(
        id: '3',
        orderNumber: 'ORD003',
        type: TaskType.lineDelivery,
        status: TaskStatus.completed,
      ),
    ];

    final tTaskListResponse = TaskListResponseModel(
      tasks: tTaskModels,
      total: 1,
    );

    test('should return refreshed list of tasks when call to remote data source is successful', () async {
      // arrange
      when(mockRemoteDataSource.refreshTasks())
          .thenAnswer((_) async => tTaskListResponse);

      // act
      final result = await repository.refreshTasks();

      // assert
      verify(mockRemoteDataSource.refreshTasks());
      expect(result, isA<List<Task>>());
      expect(result.length, equals(1));
      expect(result[0].id, equals('3'));
    });

    test('should throw exception when call to remote data source fails', () async {
      // arrange
      when(mockRemoteDataSource.refreshTasks())
          .thenThrow(Exception('Network error'));

      // act
      final call = repository.refreshTasks();

      // assert
      expect(call, throwsException);
      verify(mockRemoteDataSource.refreshTasks());
    });
  });

  group('getTasksByType', () {
    final tTaskModels = [
      const TaskModel(
        id: '4',
        orderNumber: 'ORD004',
        type: TaskType.pickingVerification,
        status: TaskStatus.pending,
      ),
    ];

    final tTaskListResponse = TaskListResponseModel(
      tasks: tTaskModels,
      total: 1,
    );

    test('should return filtered tasks by type when call to remote data source is successful', () async {
      // arrange
      when(mockRemoteDataSource.getTasksByType('picking_verification'))
          .thenAnswer((_) async => tTaskListResponse);

      // act
      final result = await repository.getTasksByType(TaskType.pickingVerification);

      // assert
      verify(mockRemoteDataSource.getTasksByType('picking_verification'));
      expect(result, isA<List<Task>>());
      expect(result.length, equals(1));
      expect(result[0].type, equals(TaskType.pickingVerification));
    });

    test('should throw exception when call to remote data source fails', () async {
      // arrange
      when(mockRemoteDataSource.getTasksByType('picking_verification'))
          .thenThrow(Exception('Network error'));

      // act
      final call = repository.getTasksByType(TaskType.pickingVerification);

      // assert
      expect(call, throwsException);
      verify(mockRemoteDataSource.getTasksByType('picking_verification'));
    });
  });

  group('updateTaskStatus', () {
    const tUpdatedTaskModel = TaskModel(
      id: '1',
      orderNumber: 'ORD001',
      type: TaskType.pickingVerification,
      status: TaskStatus.completed,
    );

    test('should return updated task when call to remote data source is successful', () async {
      // arrange
      when(mockRemoteDataSource.updateTaskStatus('1', 'completed'))
          .thenAnswer((_) async => tUpdatedTaskModel);

      // act
      final result = await repository.updateTaskStatus('1', TaskStatus.completed);

      // assert
      verify(mockRemoteDataSource.updateTaskStatus('1', 'completed'));
      expect(result, isA<Task>());
      expect(result.id, equals('1'));
      expect(result.status, equals(TaskStatus.completed));
    });

    test('should throw exception when call to remote data source fails', () async {
      // arrange
      when(mockRemoteDataSource.updateTaskStatus('1', 'completed'))
          .thenThrow(Exception('Update failed'));

      // act
      final call = repository.updateTaskStatus('1', TaskStatus.completed);

      // assert
      expect(call, throwsException);
      verify(mockRemoteDataSource.updateTaskStatus('1', 'completed'));
    });
  });
}