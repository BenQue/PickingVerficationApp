import 'package:equatable/equatable.dart';

class AuthRequestModel extends Equatable {
  final String employeeId;
  final String password;

  const AuthRequestModel({
    required this.employeeId,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeId': employeeId,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [employeeId, password];
}