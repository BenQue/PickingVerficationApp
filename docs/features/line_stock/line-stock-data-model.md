# 线边库存管理功能 - 数据模型设计

**文档版本**: 1.0
**创建日期**: 2025-10-27
**架构模式**: Clean Architecture
**状态管理**: BLoC Pattern

---

## 目录

1. [架构概览](#1-架构概览)
2. [数据层模型](#2-数据层模型)
3. [领域层实体](#3-领域层实体)
4. [表现层状态](#4-表现层状态)
5. [数据转换映射](#5-数据转换映射)
6. [代码实现示例](#6-代码实现示例)

---

## 1. 架构概览

### 1.1 分层架构

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│  (BLoC, UI, Widgets)                │
│                                     │
│  - LineStockBloc                    │
│  - LineStockEvent                   │
│  - LineStockState                   │
│  - UI Screens & Widgets             │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│        Domain Layer                 │
│  (Entities, Repository Interfaces)  │
│                                     │
│  - LineStock (Entity)               │
│  - CableItem (Value Object)         │
│  - LineStockRepository (Interface)  │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│         Data Layer                  │
│  (Models, DataSources, Repos)       │
│                                     │
│  - LineStockModel                   │
│  - TransferRequestModel             │
│  - LineStockRemoteDataSource        │
│  - LineStockRepositoryImpl          │
└─────────────────────────────────────┘
               │
               ↓
         [API Server]
```

### 1.2 数据流向

**查询流程**:
```
UI (扫码) → Event → BLoC → Repository → DataSource → API
                      ↓
                   State → UI (显示结果)
```

**转移流程**:
```
UI (提交) → Event → BLoC → Repository → DataSource → API
                      ↓
                   State → UI (显示结果)
```

---

## 2. 数据层模型

### 2.1 API响应通用模型

所有API响应遵循统一格式：

```dart
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
}
```

**JSON示例**:
```json
{
  "isSuccess": true,
  "message": "操作成功",
  "data": { /* 具体数据 */ }
}
```

---

### 2.2 LineStockModel - 库存信息模型

**用途**: 表示从API返回的库存信息

```dart
class LineStockModel {
  final int? stockId;
  final String? materialCode;
  final String? materialDesc;
  final double? quantity;
  final String? baseUnit;
  final String? batchCode;
  final String? locationCode;
  final String? barcode;

  const LineStockModel({
    this.stockId,
    this.materialCode,
    this.materialDesc,
    this.quantity,
    this.baseUnit,
    this.batchCode,
    this.locationCode,
    this.barcode,
  });

  factory LineStockModel.fromJson(Map<String, dynamic> json) {
    return LineStockModel(
      stockId: json['stockId'] as int?,
      materialCode: json['materialCode'] as String?,
      materialDesc: json['materialDesc'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      baseUnit: json['baseUnit'] as String?,
      batchCode: json['batchCode'] as String?,
      locationCode: json['locationCode'] as String?,
      barcode: json['barcode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockId': stockId,
      'materialCode': materialCode,
      'materialDesc': materialDesc,
      'quantity': quantity,
      'baseUnit': baseUnit,
      'batchCode': batchCode,
      'locationCode': locationCode,
      'barcode': barcode,
    };
  }

  // 转换为领域实体
  LineStock toEntity() {
    return LineStock(
      stockId: stockId,
      materialCode: materialCode ?? '',
      materialDesc: materialDesc ?? '',
      quantity: quantity ?? 0.0,
      baseUnit: baseUnit ?? 'PCS',
      batchCode: batchCode ?? '',
      locationCode: locationCode ?? '',
      barcode: barcode ?? '',
    );
  }
}
```

**API响应示例**:
```json
{
  "isSuccess": true,
  "message": "查询成功",
  "data": {
    "stockId": 123,
    "materialCode": "C12345",
    "materialDesc": "断线电缆 XX型",
    "quantity": 150.0,
    "baseUnit": "PCS",
    "batchCode": "BATCH-001",
    "locationCode": "A-01-02",
    "barcode": "BC123456789"
  }
}
```

**字段说明**:

| 字段 | 类型 | 可空 | 说明 |
|-----|------|------|------|
| stockId | int | 是 | 库存记录ID |
| materialCode | String | 是 | 物料编码 |
| materialDesc | String | 是 | 物料描述 |
| quantity | double | 是 | 库存数量 |
| baseUnit | String | 是 | 基本单位 |
| batchCode | String | 是 | 批次号 |
| locationCode | String | 是 | 库位编码 |
| barcode | String | 是 | 条码 |

---

### 2.3 TransferRequestModel - 转移请求模型

**用途**: 表示库存转移的请求参数

```dart
class TransferRequestModel {
  final String locationCode;
  final List<String> barCodes;

  const TransferRequestModel({
    required this.locationCode,
    required this.barCodes,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationCode': locationCode,
      'barCodes': barCodes,
    };
  }

  factory TransferRequestModel.fromJson(Map<String, dynamic> json) {
    return TransferRequestModel(
      locationCode: json['locationCode'] as String,
      barCodes: List<String>.from(json['barCodes'] as List),
    );
  }
}
```

**请求示例**:
```json
{
  "locationCode": "B-02-05",
  "barCodes": [
    "BC123456789",
    "BC123456790",
    "BC123456791"
  ]
}
```

**响应示例**:
```json
{
  "isSuccess": true,
  "message": "转移成功",
  "data": true
}
```

---

### 2.4 Failure - 错误模型

**用途**: 统一的错误处理

```dart
abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
```

---

## 3. 领域层实体

### 3.1 LineStock - 库存实体

**用途**: 核心业务对象，表示线边库存

```dart
import 'package:equatable/equatable.dart';

class LineStock extends Equatable {
  final int? stockId;
  final String materialCode;
  final String materialDesc;
  final double quantity;
  final String baseUnit;
  final String batchCode;
  final String locationCode;
  final String barcode;

  const LineStock({
    this.stockId,
    required this.materialCode,
    required this.materialDesc,
    required this.quantity,
    required this.baseUnit,
    required this.batchCode,
    required this.locationCode,
    required this.barcode,
  });

  @override
  List<Object?> get props => [
    stockId,
    materialCode,
    materialDesc,
    quantity,
    baseUnit,
    batchCode,
    locationCode,
    barcode,
  ];

  // 业务逻辑方法
  bool get hasStock => quantity > 0;

  String get displayInfo => '$materialDesc ($materialCode)';

  String get quantityInfo => '$quantity $baseUnit';

  // 复制方法（用于状态更新）
  LineStock copyWith({
    int? stockId,
    String? materialCode,
    String? materialDesc,
    double? quantity,
    String? baseUnit,
    String? batchCode,
    String? locationCode,
    String? barcode,
  }) {
    return LineStock(
      stockId: stockId ?? this.stockId,
      materialCode: materialCode ?? this.materialCode,
      materialDesc: materialDesc ?? this.materialDesc,
      quantity: quantity ?? this.quantity,
      baseUnit: baseUnit ?? this.baseUnit,
      batchCode: batchCode ?? this.batchCode,
      locationCode: locationCode ?? this.locationCode,
      barcode: barcode ?? this.barcode,
    );
  }
}
```

**使用示例**:
```dart
final stock = LineStock(
  stockId: 123,
  materialCode: 'C12345',
  materialDesc: '断线电缆 XX型',
  quantity: 150.0,
  baseUnit: 'PCS',
  batchCode: 'BATCH-001',
  locationCode: 'A-01-02',
  barcode: 'BC123456789',
);

// 业务逻辑
if (stock.hasStock) {
  print('库存充足：${stock.quantityInfo}');
}

print('物料信息：${stock.displayInfo}');
```

---

### 3.2 CableItem - 电缆项值对象

**用途**: 表示已扫描的电缆条码项（用于上架列表）

```dart
import 'package:equatable/equatable.dart';

class CableItem extends Equatable {
  final String barcode;
  final String materialCode;
  final String materialDesc;
  final String currentLocation;

  const CableItem({
    required this.barcode,
    required this.materialCode,
    required this.materialDesc,
    required this.currentLocation,
  });

  @override
  List<Object?> get props => [
    barcode,
    materialCode,
    materialDesc,
    currentLocation,
  ];

  // 从LineStock创建
  factory CableItem.fromLineStock(LineStock stock) {
    return CableItem(
      barcode: stock.barcode,
      materialCode: stock.materialCode,
      materialDesc: stock.materialDesc,
      currentLocation: stock.locationCode,
    );
  }

  String get displayInfo => '$materialCode - $materialDesc';

  CableItem copyWith({
    String? barcode,
    String? materialCode,
    String? materialDesc,
    String? currentLocation,
  }) {
    return CableItem(
      barcode: barcode ?? this.barcode,
      materialCode: materialCode ?? this.materialCode,
      materialDesc: materialDesc ?? this.materialDesc,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}
```

---

### 3.3 TransferResult - 转移结果实体

**用途**: 表示库存转移操作的结果

```dart
import 'package:equatable/equatable.dart';

class TransferResult extends Equatable {
  final bool isSuccess;
  final String message;
  final String targetLocation;
  final int transferredCount;
  final DateTime timestamp;

  const TransferResult({
    required this.isSuccess,
    required this.message,
    required this.targetLocation,
    required this.transferredCount,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
    isSuccess,
    message,
    targetLocation,
    transferredCount,
    timestamp,
  ];

  String get successMessage =>
      '成功上架 $transferredCount 个电缆到 $targetLocation';
}
```

---

## 4. 表现层状态

### 4.1 LineStockEvent - 事件定义

```dart
import 'package:equatable/equatable.dart';

abstract class LineStockEvent extends Equatable {
  const LineStockEvent();

  @override
  List<Object?> get props => [];
}

// ============ 查询相关事件 ============

/// 通过条码查询库存
class QueryStockByBarcode extends LineStockEvent {
  final String barcode;
  final int? factoryId;

  const QueryStockByBarcode({
    required this.barcode,
    this.factoryId,
  });

  @override
  List<Object?> get props => [barcode, factoryId];
}

/// 清空查询结果
class ClearQueryResult extends LineStockEvent {
  const ClearQueryResult();
}

// ============ 上架相关事件 ============

/// 设置目标库位
class SetTargetLocation extends LineStockEvent {
  final String locationCode;

  const SetTargetLocation(this.locationCode);

  @override
  List<Object?> get props => [locationCode];
}

/// 修改目标库位
class ModifyTargetLocation extends LineStockEvent {
  const ModifyTargetLocation();
}

/// 添加电缆条码
class AddCableBarcode extends LineStockEvent {
  final String barcode;

  const AddCableBarcode(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// 删除电缆条码
class RemoveCableBarcode extends LineStockEvent {
  final String barcode;

  const RemoveCableBarcode(this.barcode);

  @override
  List<Object?> get props => [barcode];
}

/// 清空电缆列表
class ClearCableList extends LineStockEvent {
  const ClearCableList();
}

/// 确认上架（提交转移）
class ConfirmShelving extends LineStockEvent {
  final String locationCode;
  final List<String> barCodes;

  const ConfirmShelving({
    required this.locationCode,
    required this.barCodes,
  });

  @override
  List<Object?> get props => [locationCode, barCodes];
}

/// 重置上架状态
class ResetShelving extends LineStockEvent {
  const ResetShelving();
}

// ============ 通用事件 ============

/// 重置所有状态
class ResetLineStock extends LineStockEvent {
  const ResetLineStock();
}
```

**事件说明**:

| 事件 | 触发时机 | 参数 |
|-----|---------|------|
| QueryStockByBarcode | 用户扫描条码查询 | barcode, factoryId? |
| ClearQueryResult | 用户清空查询结果 | - |
| SetTargetLocation | 用户设置目标库位 | locationCode |
| ModifyTargetLocation | 用户修改目标库位 | - |
| AddCableBarcode | 用户扫描电缆条码 | barcode |
| RemoveCableBarcode | 用户删除某个条码 | barcode |
| ClearCableList | 用户清空电缆列表 | - |
| ConfirmShelving | 用户确认上架 | locationCode, barCodes |
| ResetShelving | 上架完成或取消 | - |
| ResetLineStock | 重置所有状态 | - |

---

### 4.2 LineStockState - 状态定义

```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/line_stock_entity.dart';
import '../../domain/entities/cable_item.dart';

abstract class LineStockState extends Equatable {
  const LineStockState();

  @override
  List<Object?> get props => [];
}

// ============ 初始状态 ============

class LineStockInitial extends LineStockState {
  const LineStockInitial();
}

// ============ 加载状态 ============

class LineStockLoading extends LineStockState {
  final String? message;

  const LineStockLoading({this.message});

  @override
  List<Object?> get props => [message];
}

// ============ 查询相关状态 ============

/// 查询成功
class StockQuerySuccess extends LineStockState {
  final LineStock stock;

  const StockQuerySuccess(this.stock);

  @override
  List<Object?> get props => [stock];
}

// ============ 上架相关状态 ============

/// 上架进行中（包含所有中间状态）
class ShelvingInProgress extends LineStockState {
  final String? targetLocation;
  final List<CableItem> cableList;
  final bool canSubmit;

  const ShelvingInProgress({
    this.targetLocation,
    required this.cableList,
    required this.canSubmit,
  });

  @override
  List<Object?> get props => [targetLocation, cableList, canSubmit];

  bool get hasTargetLocation => targetLocation != null && targetLocation!.isNotEmpty;
  bool get hasCables => cableList.isNotEmpty;
  int get cableCount => cableList.length;

  // 辅助方法
  ShelvingInProgress copyWith({
    String? targetLocation,
    List<CableItem>? cableList,
    bool? canSubmit,
  }) {
    return ShelvingInProgress(
      targetLocation: targetLocation ?? this.targetLocation,
      cableList: cableList ?? this.cableList,
      canSubmit: canSubmit ?? this.canSubmit,
    );
  }
}

/// 上架成功
class ShelvingSuccess extends LineStockState {
  final String message;
  final String targetLocation;
  final int transferredCount;

  const ShelvingSuccess({
    required this.message,
    required this.targetLocation,
    required this.transferredCount,
  });

  @override
  List<Object?> get props => [message, targetLocation, transferredCount];

  String get displayMessage => '成功上架 $transferredCount 个电缆到 $targetLocation';
}

// ============ 错误状态 ============

class LineStockError extends LineStockState {
  final String message;
  final bool canRetry;
  final LineStockState? previousState;  // 用于恢复之前的状态

  const LineStockError({
    required this.message,
    this.canRetry = true,
    this.previousState,
  });

  @override
  List<Object?> get props => [message, canRetry, previousState];
}
```

**状态转换图**:

```
[Initial]
    ↓ QueryStockByBarcode
[Loading]
    ↓ success
[StockQuerySuccess] ←→ [Initial]
    ↓ error
[LineStockError] → [Initial]

[Initial]
    ↓ SetTargetLocation
[ShelvingInProgress(location=X, cables=[], canSubmit=false)]
    ↓ AddCableBarcode (验证成功)
[ShelvingInProgress(location=X, cables=[1], canSubmit=true)]
    ↓ AddCableBarcode (继续添加)
[ShelvingInProgress(location=X, cables=[1,2,3], canSubmit=true)]
    ↓ ConfirmShelving
[Loading]
    ↓ success
[ShelvingSuccess] → [Initial]
    ↓ error
[LineStockError] → [ShelvingInProgress]
```

---

## 5. 数据转换映射

### 5.1 Model ↔ Entity 转换

```dart
// Model → Entity
LineStockModel model = // ... from API
LineStock entity = model.toEntity();

// Entity → Model (如果需要)
LineStock entity = // ...
LineStockModel model = LineStockModel(
  stockId: entity.stockId,
  materialCode: entity.materialCode,
  // ... 其他字段
);
```

### 5.2 LineStock → CableItem 转换

```dart
LineStock stock = // ... 查询结果
CableItem cableItem = CableItem.fromLineStock(stock);
```

### 5.3 API Response → Domain

```dart
// 查询库存
ApiResponse<LineStockModel> apiResponse = // ... from API
if (apiResponse.isSuccess && apiResponse.data != null) {
  LineStock entity = apiResponse.data!.toEntity();
  emit(StockQuerySuccess(entity));
} else {
  emit(LineStockError(message: apiResponse.message));
}

// 转移库存
ApiResponse<bool> transferResponse = // ... from API
if (transferResponse.isSuccess && transferResponse.data == true) {
  emit(ShelvingSuccess(
    message: transferResponse.message,
    targetLocation: locationCode,
    transferredCount: barCodes.length,
  ));
} else {
  emit(LineStockError(message: transferResponse.message));
}
```

---

## 6. 代码实现示例

### 6.1 Repository 接口

```dart
import 'package:dartz/dartz.dart';
import '../entities/line_stock_entity.dart';
import '../../../core/error/failures.dart';

abstract class LineStockRepository {
  /// 通过条码查询库存
  Future<Either<Failure, LineStock>> queryByBarcode({
    required String barcode,
    int? factoryId,
  });

  /// 库存转移
  Future<Either<Failure, bool>> transferStock({
    required String locationCode,
    required List<String> barCodes,
  });
}
```

### 6.2 Repository 实现

```dart
import 'package:dartz/dartz.dart';
import '../../domain/repositories/line_stock_repository.dart';
import '../../domain/entities/line_stock_entity.dart';
import '../../../core/error/failures.dart';
import '../datasources/line_stock_remote_datasource.dart';

class LineStockRepositoryImpl implements LineStockRepository {
  final LineStockRemoteDataSource remoteDataSource;

  LineStockRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, LineStock>> queryByBarcode({
    required String barcode,
    int? factoryId,
  }) async {
    try {
      final model = await remoteDataSource.queryByBarcode(
        barcode: barcode,
        factoryId: factoryId,
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('未知错误：$e'));
    }
  }

  @override
  Future<Either<Failure, bool>> transferStock({
    required String locationCode,
    required List<String> barCodes,
  }) async {
    try {
      final result = await remoteDataSource.transferStock(
        locationCode: locationCode,
        barCodes: barCodes,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('未知错误：$e'));
    }
  }
}
```

### 6.3 DataSource 实现

```dart
import 'package:dio/dio.dart';
import '../models/line_stock_model.dart';
import '../models/transfer_request_model.dart';
import '../../../core/error/exceptions.dart';

abstract class LineStockRemoteDataSource {
  Future<LineStockModel> queryByBarcode({
    required String barcode,
    int? factoryId,
  });

  Future<bool> transferStock({
    required String locationCode,
    required List<String> barCodes,
  });
}

class LineStockRemoteDataSourceImpl implements LineStockRemoteDataSource {
  final Dio dio;

  LineStockRemoteDataSourceImpl({required this.dio});

  @override
  Future<LineStockModel> queryByBarcode({
    required String barcode,
    int? factoryId,
  }) async {
    try {
      final response = await dio.get(
        '/api/LineStock/byBarcode',
        queryParameters: {
          'barcode': barcode,
          if (factoryId != null) 'factoryid': factoryId,
        },
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => LineStockModel.fromJson(data as Map<String, dynamic>),
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('网络连接超时');
      } else if (e.type == DioExceptionType.badResponse) {
        throw ServerException(e.response?.data['message'] ?? '服务器错误');
      } else {
        throw NetworkException('网络连接失败');
      }
    }
  }

  @override
  Future<bool> transferStock({
    required String locationCode,
    required List<String> barCodes,
  }) async {
    try {
      final request = TransferRequestModel(
        locationCode: locationCode,
        barCodes: barCodes,
      );

      final response = await dio.post(
        '/api/LineStock/transfer',
        data: request.toJson(),
      );

      final apiResponse = ApiResponse.fromJson(
        response.data,
        (data) => data as bool,
      );

      if (apiResponse.isSuccess) {
        return apiResponse.data ?? false;
      } else {
        throw ServerException(apiResponse.message);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('网络连接超时');
      } else if (e.type == DioExceptionType.badResponse) {
        throw ServerException(e.response?.data['message'] ?? '服务器错误');
      } else {
        throw NetworkException('网络连接失败');
      }
    }
  }
}
```

### 6.4 BLoC 核心逻辑示例

```dart
Future<void> _onAddCableBarcode(
  AddCableBarcode event,
  Emitter<LineStockState> emit,
) async {
  final currentState = state;

  // 只能在上架进行中状态添加
  if (currentState is! ShelvingInProgress) {
    emit(const LineStockError(
      message: '请先设置目标库位',
      canRetry: false,
    ));
    return;
  }

  // 检查条码是否已存在
  if (currentState.cableList.any((c) => c.barcode == event.barcode)) {
    emit(LineStockError(
      message: '条码已存在：${event.barcode}',
      canRetry: true,
      previousState: currentState,
    ));
    // 恢复之前状态
    await Future.delayed(const Duration(seconds: 2));
    emit(currentState);
    return;
  }

  emit(const LineStockLoading(message: '验证条码...'));

  // 查询条码验证
  final result = await repository.queryByBarcode(barcode: event.barcode);

  result.fold(
    (failure) {
      emit(LineStockError(
        message: '条码无效或查询失败：${event.barcode}\n${failure.message}',
        canRetry: true,
        previousState: currentState,
      ));
      // 恢复之前状态
      Future.delayed(const Duration(seconds: 2), () {
        if (state is LineStockError) {
          emit(currentState);
        }
      });
    },
    (stock) {
      // 添加到列表
      final newCable = CableItem.fromLineStock(stock);
      final updatedList = [...currentState.cableList, newCable];

      emit(ShelvingInProgress(
        targetLocation: currentState.targetLocation,
        cableList: updatedList,
        canSubmit: currentState.hasTargetLocation && updatedList.isNotEmpty,
      ));
    },
  );
}
```

---

## 7. 数据验证规则

### 7.1 输入验证

| 字段 | 验证规则 | 错误消息 |
|-----|---------|---------|
| 条码 | 非空，长度 > 0 | "条码不能为空" |
| 库位编码 | 非空，格式匹配 | "库位格式不正确" |
| 条码列表 | 至少包含1个条码 | "请至少扫描一个电缆条码" |

### 7.2 业务规则验证

| 规则 | 验证逻辑 | 处理方式 |
|-----|---------|---------|
| 条码唯一性 | 列表中不能有重复条码 | 提示重复并拒绝添加 |
| 条码有效性 | 条码必须在系统中存在 | 查询API验证 |
| 库位有效性 | 库位必须存在 | 后端验证返回错误 |

---

## 8. 附录

### 8.1 完整类型定义

```dart
// Exception 定义
class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}
```

### 8.2 相关文档

- [功能规格说明](./line-stock-specs.md)
- [任务分解计划](./line-stock-tasks.md)
- [API开发文档](../../API/API开发文档.md)

### 8.3 修订历史

| 版本 | 日期 | 修订内容 | 修订人 |
|-----|------|---------|--------|
| 1.0 | 2025-10-27 | 初始版本 | Claude Code |

---

**文档结束**
