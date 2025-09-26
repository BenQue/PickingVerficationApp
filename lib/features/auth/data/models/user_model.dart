import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends Equatable {
  final String id;
  final String employeeId;
  final String name;
  final String email;
  final String role;
  final String department;
  final List<String> permissions;

  const UserModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.permissions,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      employeeId: json['employeeId'] as String,
      name: json['fullName'] as String? ?? json['name'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      department: json['department'] as String? ?? '',
      permissions: List<String>.from(json['permissions'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'fullName': name,
      'email': email,
      'role': role,
      'department': department,
      'permissions': permissions,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      employeeId: employeeId,
      name: name,
      permissions: permissions,
    );
  }

  @override
  List<Object?> get props => [id, employeeId, name, email, role, department, permissions];
}