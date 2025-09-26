
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/task_board/data/models/task_model.dart';
import 'package:picking_verification_app/features/task_board/domain/entities/task.dart';

void main() {
  group('TaskModel', () {
    const tTaskModel = TaskModel(
      id: '1',
      orderNumber: 'ORD001',
      type: TaskType.pickingVerification,
      status: TaskStatus.pending,
      assignedTo: 'user1',
      priority: 2,
      dueDate: null,
      createdAt: null,
      updatedAt: null,
      metadata: {'key': 'value'},
    );

    test('should be a subclass of Task entity', () async {
      // assert
      expect(tTaskModel, isA<Task>());
    });

    group('fromJson', () {
      test('should return a valid TaskModel from JSON', () async {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'id': '1',
          'order_number': 'ORD001',
          'type': 'picking_verification',
          'status': 'pending',
          'assigned_to': 'user1',
          'priority': 2,
          'due_date': null,
          'created_at': null,
          'updated_at': null,
          'metadata': {'key': 'value'},
        };

        // act
        final result = TaskModel.fromJson(jsonMap);

        // assert
        expect(result, equals(tTaskModel));
      });

      test('should handle date parsing correctly', () async {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'id': '1',
          'order_number': 'ORD001',
          'type': 'picking_verification',
          'status': 'pending',
          'assigned_to': 'user1',
          'priority': 2,
          'due_date': '2024-12-31T23:59:59.000Z',
          'created_at': '2024-01-01T00:00:00.000Z',
          'updated_at': '2024-01-02T12:00:00.000Z',
          'metadata': null,
        };

        // act
        final result = TaskModel.fromJson(jsonMap);

        // assert
        expect(result.dueDate, isA<DateTime>());
        expect(result.createdAt, isA<DateTime>());
        expect(result.updatedAt, isA<DateTime>());
        expect(result.dueDate!.year, equals(2024));
        expect(result.dueDate!.month, equals(12));
        expect(result.dueDate!.day, equals(31));
      });

      test('should handle unknown task type by defaulting to pickingVerification', () async {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'id': '1',
          'order_number': 'ORD001',
          'type': 'unknown_type',
          'status': 'pending',
          'assigned_to': null,
          'priority': null,
          'due_date': null,
          'created_at': null,
          'updated_at': null,
          'metadata': null,
        };

        // act
        final result = TaskModel.fromJson(jsonMap);

        // assert
        expect(result.type, equals(TaskType.pickingVerification));
      });

      test('should handle unknown task status by defaulting to pending', () async {
        // arrange
        final Map<String, dynamic> jsonMap = {
          'id': '1',
          'order_number': 'ORD001',
          'type': 'picking_verification',
          'status': 'unknown_status',
          'assigned_to': null,
          'priority': null,
          'due_date': null,
          'created_at': null,
          'updated_at': null,
          'metadata': null,
        };

        // act
        final result = TaskModel.fromJson(jsonMap);

        // assert
        expect(result.status, equals(TaskStatus.pending));
      });
    });

    group('toJson', () {
      test('should return a JSON map containing proper data', () async {
        // act
        final result = tTaskModel.toJson();

        // assert
        final expectedJsonMap = {
          'id': '1',
          'order_number': 'ORD001',
          'type': 'picking_verification',
          'status': 'pending',
          'assigned_to': 'user1',
          'priority': 2,
          'due_date': null,
          'created_at': null,
          'updated_at': null,
          'metadata': {'key': 'value'},
        };
        expect(result, equals(expectedJsonMap));
      });

      test('should serialize dates correctly', () async {
        // arrange
        final taskWithDates = TaskModel(
          id: '1',
          orderNumber: 'ORD001',
          type: TaskType.pickingVerification,
          status: TaskStatus.pending,
          assignedTo: 'user1',
          priority: 2,
          dueDate: DateTime(2024, 12, 31, 23, 59, 59),
          createdAt: DateTime(2024, 1, 1, 0, 0, 0),
          updatedAt: DateTime(2024, 1, 2, 12, 0, 0),
          metadata: null,
        );

        // act
        final result = taskWithDates.toJson();

        // assert
        expect(result['due_date'], isA<String>());
        expect(result['created_at'], isA<String>());
        expect(result['updated_at'], isA<String>());
        expect(result['due_date'], contains('2024-12-31T23:59:59'));
      });
    });

    group('fromEntity', () {
      test('should create TaskModel from Task entity', () async {
        // arrange
        const taskEntity = Task(
          id: '1',
          orderNumber: 'ORD001',
          type: TaskType.platformReceiving,
          status: TaskStatus.inProgress,
          assignedTo: 'user1',
          priority: 3,
        );

        // act
        final result = TaskModel.fromEntity(taskEntity);

        // assert
        expect(result, isA<TaskModel>());
        expect(result.id, equals(taskEntity.id));
        expect(result.orderNumber, equals(taskEntity.orderNumber));
        expect(result.type, equals(taskEntity.type));
        expect(result.status, equals(taskEntity.status));
        expect(result.assignedTo, equals(taskEntity.assignedTo));
        expect(result.priority, equals(taskEntity.priority));
      });
    });
  });
}