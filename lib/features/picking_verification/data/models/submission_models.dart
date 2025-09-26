import '../../domain/entities/material_item.dart';

/// 校验提交请求模型
class VerificationSubmissionRequest {
  final String orderId;
  final String submissionId;
  final DateTime submissionTimestamp;
  final String? operatorId;
  final String? deviceId;
  final List<MaterialSubmissionItem> materials;
  final Map<String, dynamic>? metadata;

  const VerificationSubmissionRequest({
    required this.orderId,
    required this.submissionId,
    required this.submissionTimestamp,
    this.operatorId,
    this.deviceId,
    required this.materials,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'submissionId': submissionId,
      'submissionTimestamp': submissionTimestamp.toIso8601String(),
      'operatorId': operatorId,
      'deviceId': deviceId,
      'materials': materials.map((m) => m.toJson()).toList(),
      'metadata': metadata,
      'summary': {
        'totalMaterials': materials.length,
        'completedMaterials': materials.where((m) => m.status == MaterialStatus.completed).length,
        'completionRate': materials.isNotEmpty 
            ? materials.where((m) => m.status == MaterialStatus.completed).length / materials.length
            : 0.0,
      },
    };
  }
}

/// 物料提交项模型
class MaterialSubmissionItem {
  final String id;
  final String code;
  final String name;
  final MaterialCategory category;
  final int requiredQuantity;
  final int availableQuantity;
  final MaterialStatus status;
  final String location;
  final String unit;
  final String? remarks;
  final DateTime? statusUpdatedAt;
  final String? statusUpdatedBy;

  const MaterialSubmissionItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.status,
    required this.location,
    required this.unit,
    this.remarks,
    this.statusUpdatedAt,
    this.statusUpdatedBy,
  });

  factory MaterialSubmissionItem.fromMaterialItem(
    MaterialItem item, {
    DateTime? statusUpdatedAt,
    String? statusUpdatedBy,
  }) {
    return MaterialSubmissionItem(
      id: item.id,
      code: item.code,
      name: item.name,
      category: item.category,
      requiredQuantity: item.requiredQuantity,
      availableQuantity: item.availableQuantity,
      status: item.status,
      location: item.location,
      unit: item.unit,
      remarks: item.remarks,
      statusUpdatedAt: statusUpdatedAt,
      statusUpdatedBy: statusUpdatedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category.name,
      'requiredQuantity': requiredQuantity,
      'availableQuantity': availableQuantity,
      'status': status.name,
      'statusLabel': status.label,
      'location': location,
      'unit': unit,
      'remarks': remarks,
      'statusUpdatedAt': statusUpdatedAt?.toIso8601String(),
      'statusUpdatedBy': statusUpdatedBy,
      'isFulfilled': availableQuantity >= requiredQuantity,
      'shortageQuantity': requiredQuantity > availableQuantity 
          ? requiredQuantity - availableQuantity 
          : 0,
    };
  }
}

/// 校验提交响应模型
class VerificationSubmissionResponse {
  final bool success;
  final String message;
  final String? submissionId;
  final String? orderId;
  final DateTime? processedAt;
  final String? orderStatus;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? errors;

  const VerificationSubmissionResponse({
    required this.success,
    required this.message,
    this.submissionId,
    this.orderId,
    this.processedAt,
    this.orderStatus,
    this.data,
    this.errors,
  });

  factory VerificationSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return VerificationSubmissionResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      submissionId: json['submissionId'] as String?,
      orderId: json['orderId'] as String?,
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'] as String)
          : null,
      orderStatus: json['orderStatus'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'submissionId': submissionId,
      'orderId': orderId,
      'processedAt': processedAt?.toIso8601String(),
      'orderStatus': orderStatus,
      'data': data,
      'errors': errors,
    };
  }
}

/// API错误响应模型
class ApiErrorResponse {
  final int statusCode;
  final String errorCode;
  final String message;
  final String? details;
  final DateTime timestamp;
  final Map<String, dynamic>? validationErrors;

  const ApiErrorResponse({
    required this.statusCode,
    required this.errorCode,
    required this.message,
    this.details,
    required this.timestamp,
    this.validationErrors,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    return ApiErrorResponse(
      statusCode: json['statusCode'] as int? ?? 500,
      errorCode: json['errorCode'] as String? ?? 'UNKNOWN_ERROR',
      message: json['message'] as String? ?? '未知错误',
      details: json['details'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      validationErrors: json['validationErrors'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'errorCode': errorCode,
      'message': message,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'validationErrors': validationErrors,
    };
  }
}

/// 提交重试配置
class SubmissionRetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final List<int> retryableStatusCodes;

  const SubmissionRetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.retryableStatusCodes = const [408, 429, 500, 502, 503, 504],
  });

  Duration getDelayForAttempt(int attempt) {
    if (attempt <= 0) return Duration.zero;
    
    final delay = initialDelay * (backoffMultiplier * attempt);
    return delay > maxDelay ? maxDelay : delay;
  }

  bool shouldRetry(int statusCode, int attemptCount) {
    return attemptCount < maxRetries && retryableStatusCodes.contains(statusCode);
  }
}