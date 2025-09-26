import 'package:equatable/equatable.dart';
import 'user_model.dart';

class AuthResponseModel extends Equatable {
  final UserModel user;
  final String message;
  final bool success;
  final String accessToken;
  final String refreshToken;

  const AuthResponseModel({
    required this.user,
    required this.message,
    required this.success,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      message: json['message'] as String? ?? 'Login successful',
      success: json['success'] as bool,
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'message': message,
      'success': success,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  @override
  List<Object?> get props => [user, message, success, accessToken, refreshToken];
}