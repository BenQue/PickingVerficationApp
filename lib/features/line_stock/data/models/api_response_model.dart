/// Generic API Response Model
/// Wraps all API responses with standard format
class ApiResponse<T> {
  final bool isSuccess;
  final String message;
  final T? data;

  const ApiResponse({
    required this.isSuccess,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse(
      isSuccess: json['isSuccess'] as bool,
      message: json['message'] as String,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson(Object Function(T) toJsonT) {
    return {
      'isSuccess': isSuccess,
      'message': message,
      'data': data != null ? toJsonT(data as T) : null,
    };
  }
}
