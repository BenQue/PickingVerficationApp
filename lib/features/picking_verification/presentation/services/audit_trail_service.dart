import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/entities/picking_order.dart';
import '../../domain/entities/material_item.dart';

/// 审计记录类型
enum AuditLogType {
  submissionStarted('提交开始'),
  submissionCompleted('提交完成'),
  submissionFailed('提交失败'),
  submissionRetried('重试提交'),
  submissionCancelled('提交取消'),
  dataCleared('数据清除'),
  validationError('验证错误');

  final String label;
  const AuditLogType(this.label);
}

/// 审计记录条目
class AuditLogEntry {
  final String id;
  final AuditLogType type;
  final String orderId;
  final String orderNumber;
  final DateTime timestamp;
  final String? operatorId;
  final String? deviceId;
  final Map<String, dynamic> details;
  final Map<String, dynamic>? materialSummary;

  const AuditLogEntry({
    required this.id,
    required this.type,
    required this.orderId,
    required this.orderNumber,
    required this.timestamp,
    this.operatorId,
    this.deviceId,
    required this.details,
    this.materialSummary,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'typeLabel': type.label,
      'orderId': orderId,
      'orderNumber': orderNumber,
      'timestamp': timestamp.toIso8601String(),
      'operatorId': operatorId,
      'deviceId': deviceId,
      'details': details,
      'materialSummary': materialSummary,
    };
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      id: json['id'] as String,
      type: AuditLogType.values.firstWhere((e) => e.name == json['type']),
      orderId: json['orderId'] as String,
      orderNumber: json['orderNumber'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      operatorId: json['operatorId'] as String?,
      deviceId: json['deviceId'] as String?,
      details: Map<String, dynamic>.from(json['details'] as Map),
      materialSummary: json['materialSummary'] != null
          ? Map<String, dynamic>.from(json['materialSummary'] as Map)
          : null,
    );
  }
}

/// 审计跟踪服务
class AuditTrailService {
  static final AuditTrailService _instance = AuditTrailService._internal();
  factory AuditTrailService() => _instance;
  AuditTrailService._internal();

  final List<AuditLogEntry> _logs = [];
  static const int _maxLogsInMemory = 1000;

  /// 记录提交开始
  Future<void> logSubmissionStarted({
    required String orderId,
    required String orderNumber,
    required PickingOrder order,
    String? operatorId,
    String? submissionId,
    Map<String, dynamic>? metadata,
  }) async {
    final entry = AuditLogEntry(
      id: _generateId(),
      type: AuditLogType.submissionStarted,
      orderId: orderId,
      orderNumber: orderNumber,
      timestamp: DateTime.now(),
      operatorId: operatorId,
      deviceId: await _getDeviceId(),
      details: {
        'submissionId': submissionId,
        'totalMaterials': order.materials.length,
        'completedMaterials': order.materials.where((m) => m.status == MaterialStatus.completed).length,
        'metadata': metadata,
      },
      materialSummary: _generateMaterialSummary(order),
    );

    await _addLogEntry(entry);
  }

  /// 记录提交完成
  Future<void> logSubmissionCompleted({
    required String orderId,
    required String orderNumber,
    required PickingOrder order,
    required String submissionId,
    required Map<String, dynamic> submissionResult,
    String? operatorId,
    Duration? processingTime,
  }) async {
    final entry = AuditLogEntry(
      id: _generateId(),
      type: AuditLogType.submissionCompleted,
      orderId: orderId,
      orderNumber: orderNumber,
      timestamp: DateTime.now(),
      operatorId: operatorId,
      deviceId: await _getDeviceId(),
      details: {
        'submissionId': submissionId,
        'submissionResult': submissionResult,
        'processingTimeMs': processingTime?.inMilliseconds,
        'success': true,
      },
      materialSummary: _generateMaterialSummary(order),
    );

    await _addLogEntry(entry);
  }

  /// 记录提交失败
  Future<void> logSubmissionFailed({
    required String orderId,
    required String orderNumber,
    required PickingOrder order,
    required String errorMessage,
    required String errorType,
    String? submissionId,
    String? operatorId,
    Map<String, dynamic>? errorDetails,
    Duration? processingTime,
  }) async {
    final entry = AuditLogEntry(
      id: _generateId(),
      type: AuditLogType.submissionFailed,
      orderId: orderId,
      orderNumber: orderNumber,
      timestamp: DateTime.now(),
      operatorId: operatorId,
      deviceId: await _getDeviceId(),
      details: {
        'submissionId': submissionId,
        'errorMessage': errorMessage,
        'errorType': errorType,
        'errorDetails': errorDetails,
        'processingTimeMs': processingTime?.inMilliseconds,
        'success': false,
      },
      materialSummary: _generateMaterialSummary(order),
    );

    await _addLogEntry(entry);
  }

  /// 记录提交重试
  Future<void> logSubmissionRetried({
    required String orderId,
    required String orderNumber,
    required PickingOrder order,
    required String originalSubmissionId,
    required String newSubmissionId,
    String? operatorId,
    String? retryReason,
  }) async {
    final entry = AuditLogEntry(
      id: _generateId(),
      type: AuditLogType.submissionRetried,
      orderId: orderId,
      orderNumber: orderNumber,
      timestamp: DateTime.now(),
      operatorId: operatorId,
      deviceId: await _getDeviceId(),
      details: {
        'originalSubmissionId': originalSubmissionId,
        'newSubmissionId': newSubmissionId,
        'retryReason': retryReason,
      },
      materialSummary: _generateMaterialSummary(order),
    );

    await _addLogEntry(entry);
  }

  /// 记录提交取消
  Future<void> logSubmissionCancelled({
    required String orderId,
    required String orderNumber,
    required PickingOrder order,
    String? submissionId,
    String? operatorId,
    String? cancelReason,
  }) async {
    final entry = AuditLogEntry(
      id: _generateId(),
      type: AuditLogType.submissionCancelled,
      orderId: orderId,
      orderNumber: orderNumber,
      timestamp: DateTime.now(),
      operatorId: operatorId,
      deviceId: await _getDeviceId(),
      details: {
        'submissionId': submissionId,
        'cancelReason': cancelReason,
      },
      materialSummary: _generateMaterialSummary(order),
    );

    await _addLogEntry(entry);
  }

  /// 记录数据清除
  Future<void> logDataCleared({
    required String orderId,
    required String orderNumber,
    required int itemsCleared,
    String? operatorId,
    String? clearReason,
  }) async {
    final entry = AuditLogEntry(
      id: _generateId(),
      type: AuditLogType.dataCleared,
      orderId: orderId,
      orderNumber: orderNumber,
      timestamp: DateTime.now(),
      operatorId: operatorId,
      deviceId: await _getDeviceId(),
      details: {
        'itemsCleared': itemsCleared,
        'clearReason': clearReason,
      },
    );

    await _addLogEntry(entry);
  }

  /// 记录验证错误
  Future<void> logValidationError({
    required String orderId,
    required String orderNumber,
    required PickingOrder order,
    required List<String> validationErrors,
    String? operatorId,
    Map<String, dynamic>? validationDetails,
  }) async {
    final entry = AuditLogEntry(
      id: _generateId(),
      type: AuditLogType.validationError,
      orderId: orderId,
      orderNumber: orderNumber,
      timestamp: DateTime.now(),
      operatorId: operatorId,
      deviceId: await _getDeviceId(),
      details: {
        'validationErrors': validationErrors,
        'validationDetails': validationDetails,
        'errorCount': validationErrors.length,
      },
      materialSummary: _generateMaterialSummary(order),
    );

    await _addLogEntry(entry);
  }

  /// 获取指定订单的审计日志
  List<AuditLogEntry> getOrderLogs(String orderId) {
    return _logs.where((log) => log.orderId == orderId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 获取所有审计日志
  List<AuditLogEntry> getAllLogs() {
    return List.from(_logs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 获取最近的审计日志
  List<AuditLogEntry> getRecentLogs([int limit = 50]) {
    final sortedLogs = getAllLogs();
    return sortedLogs.take(limit).toList();
  }

  /// 清除旧日志
  Future<void> clearOldLogs({Duration? olderThan}) async {
    final cutoffTime = olderThan != null 
        ? DateTime.now().subtract(olderThan)
        : DateTime.now().subtract(const Duration(days: 30)); // 默认30天

    _logs.removeWhere((log) => log.timestamp.isBefore(cutoffTime));
  }

  /// 导出审计日志为JSON
  String exportLogsAsJson({String? orderId}) {
    final logsToExport = orderId != null 
        ? getOrderLogs(orderId)
        : getAllLogs();
    
    final jsonList = logsToExport.map((log) => log.toJson()).toList();
    return jsonEncode({
      'exportedAt': DateTime.now().toIso8601String(),
      'totalLogs': jsonList.length,
      'logs': jsonList,
    });
  }

  /// 添加日志条目
  Future<void> _addLogEntry(AuditLogEntry entry) async {
    _logs.add(entry);
    
    // 保持内存中日志数量限制
    if (_logs.length > _maxLogsInMemory) {
      _logs.removeRange(0, _logs.length - _maxLogsInMemory);
    }

    // 在调试模式下打印日志
    if (kDebugMode) {
      print('AuditTrail: [${entry.type.label}] ${entry.orderNumber} - ${entry.details}');
    }

    // TODO: 在实际应用中，这里应该持久化到本地存储或发送到远程服务器
    await _persistLogEntry(entry);
  }

  /// 持久化日志条目（占位符实现）
  Future<void> _persistLogEntry(AuditLogEntry entry) async {
    // TODO: 实现实际的持久化逻辑
    // 例如：SharedPreferences、SQLite、或发送到远程日志服务
  }

  /// 生成唯一ID
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return '${timestamp}_$random';
  }

  /// 获取设备ID
  Future<String> _getDeviceId() async {
    // TODO: 实现实际的设备ID获取逻辑
    // 例如：使用device_info_plus包获取设备信息
    return 'device_${DateTime.now().millisecondsSinceEpoch % 100000}';
  }

  /// 生成物料摘要
  Map<String, dynamic> _generateMaterialSummary(PickingOrder order) {
    final summary = <String, dynamic>{};
    
    // 总体统计
    summary['totalMaterials'] = order.materials.length;
    
    // 按状态统计
    for (final status in MaterialStatus.values) {
      final count = order.materials.where((m) => m.status == status).length;
      summary['${status.name}Count'] = count;
    }
    
    // 按类别统计
    for (final category in MaterialCategory.values) {
      final categoryMaterials = order.materials.where((m) => m.category == category).toList();
      if (categoryMaterials.isNotEmpty) {
        summary['${category.name}Total'] = categoryMaterials.length;
        summary['${category.name}Completed'] = categoryMaterials
            .where((m) => m.status == MaterialStatus.completed)
            .length;
      }
    }
    
    // 计算完成率
    final completedCount = order.materials.where((m) => m.status == MaterialStatus.completed).length;
    summary['completionRate'] = order.materials.isNotEmpty 
        ? (completedCount / order.materials.length)
        : 0.0;
    
    return summary;
  }
}