import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String employeeId;
  final String name;
  final List<String> permissions;

  const UserEntity({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.permissions,
  });

  @override
  List<Object?> get props => [id, employeeId, name, permissions];
}