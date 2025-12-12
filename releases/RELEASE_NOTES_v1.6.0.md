# 仓库应用 v1.6.0 发布说明

## 版本信息
- **版本号**: 1.6.0
- **构建号**: 60
- **发布日期**: 2025年12月2日
- **文件名**: warehouse-app-v1.6.0-build60.apk
- **文件大小**: 82.2 MB

## 新功能

### 电缆入库 (Cable Receiving)
新增断线电缆收货功能，支持批量扫码入库：

- **扫码查询**: 扫描电缆条码获取待入库信息
- **批量添加**: 支持连续扫描多个电缆条码
- **唯一性校验**: 本地列表自动去重，防止重复添加
- **API验证**: 服务端校验条码有效性，无效条码阻止添加
- **批量提交**: 一键确认所有待入库电缆
- **操作反馈**: 成功/失败提示，错误信息展示

### 功能入口
- 位于工作台 → 断线线边管理 → 电缆入库
- 替换原"电缆退库"按钮位置

## 技术实现

### 新增文件

#### Data Layer (数据层)
| 文件 | 说明 |
|------|------|
| `lib/features/line_stock/data/models/handover_item_model.dart` | API响应数据模型 |
| `lib/features/line_stock/data/models/handover_confirm_request.dart` | 确认入库请求模型 |

#### Domain Layer (领域层)
| 文件 | 说明 |
|------|------|
| `lib/features/line_stock/domain/entities/handover_item.dart` | 入库物料实体 |

#### Presentation Layer (展示层)
| 文件 | 说明 |
|------|------|
| `lib/features/line_stock/presentation/pages/cable_receiving_screen.dart` | 电缆入库主界面 |
| `lib/features/line_stock/presentation/widgets/handover_list_item.dart` | 入库列表项组件 |

### 修改文件

| 文件 | 修改内容 |
|------|----------|
| `pubspec.yaml` | 版本号更新为 1.6.0+60 |
| `lib/core/config/app_router.dart` | 添加 `/line-stock/receiving` 路由 |
| `lib/features/picking_verification/presentation/pages/workbench_home_screen.dart` | 添加电缆入库按钮，更新版本显示 |
| `lib/features/line_stock/presentation/bloc/line_stock_bloc.dart` | 添加 Handover 事件处理器 |
| `lib/features/line_stock/presentation/bloc/line_stock_event.dart` | 添加 Handover 相关事件 |
| `lib/features/line_stock/presentation/bloc/line_stock_state.dart` | 添加 Handover 相关状态 |
| `lib/features/line_stock/domain/repositories/line_stock_repository.dart` | 添加 Handover 接口方法 |
| `lib/features/line_stock/data/repositories/line_stock_repository_impl.dart` | 实现 Handover 接口方法 |
| `lib/features/line_stock/data/datasources/line_stock_remote_datasource.dart` | 添加 API 调用方法 |
| `lib/features/line_stock/core/constants.dart` | 添加 Handover 相关常量 |
| `releases/version.json` | 更新版本信息供自动更新使用 |

### API接口

#### 查询待入库物料
```
GET /api/LineStock/GetHandoverListByBarcode?factoryid=2&barcode={barcode}
```

**响应示例**:
```json
{
  "code": 0,
  "message": "success",
  "data": {
    "barCode": "CABLE001",
    "materialCode": "MAT001",
    "materialDesc": "电缆描述",
    "batchCode": "BATCH001",
    "quantity": 100.0,
    "baseUnit": "M"
  }
}
```

#### 确认入库
```
POST /api/LineStock/HandoverConfirm
Content-Type: application/json

{
  "barCodes": ["CABLE001", "CABLE002", "CABLE003"]
}
```

**响应示例**:
```json
{
  "code": 0,
  "message": "入库成功",
  "data": null
}
```

### 显示字段
| 字段 | API字段名 | 说明 |
|------|-----------|------|
| 条码 | barCode | 电缆条码 |
| 物料号 | materialCode | 物料编号 |
| 物料描述 | materialDesc | 物料描述 |
| 批次 | batchCode | 批次号 |
| 数量 | quantity | 数量 |
| 单位 | baseUnit | 基本单位 |

## BLoC 状态管理

### 新增事件 (Events)
```dart
// 扫描条码添加到入库列表
class ScanHandoverBarcode extends LineStockEvent {
  final String barcode;
}

// 从列表移除物料
class RemoveHandoverItem extends LineStockEvent {
  final String barcode;
}

// 清空入库列表
class ClearHandoverList extends LineStockEvent {}

// 确认入库
class ConfirmHandover extends LineStockEvent {}

// 重置入库状态
class ResetHandover extends LineStockEvent {}
```

### 新增状态 (States)
```dart
// 入库进行中状态
class HandoverInProgress extends LineStockState {
  final List<HandoverItem> itemList;
  final bool isLoading;
  bool get canSubmit => itemList.isNotEmpty && !isLoading;
}

// 入库成功状态
class HandoverSuccess extends LineStockState {
  final String message;
  final int confirmedCount;
}
```

## 用户界面

### 电缆入库界面布局
```
┌─────────────────────────────────────┐
│  ← 电缆入库                          │
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │ 📷 扫描条码输入框              ││
│  └─────────────────────────────────┘│
│                                     │
│  待入库物料 (N件)                   │
│  ┌─────────────────────────────────┐│
│  │ 条码: CABLE001              [X] ││
│  │ 物料号: MAT001                  ││
│  │ 描述: 电缆描述                  ││
│  │ 批次: BATCH001 | 100.0 M        ││
│  └─────────────────────────────────┘│
│  ┌─────────────────────────────────┐│
│  │ 条码: CABLE002              [X] ││
│  │ ...                             ││
│  └─────────────────────────────────┘│
│                                     │
├─────────────────────────────────────┤
│  [清空列表]        [确认入库 (N件)] │
└─────────────────────────────────────┘
```

### 功能卡片颜色
- **电缆入库**: 绿色 (`0xFF4CAF50`) - Material Green 500
- **图标**: `Icons.move_to_inbox`

## 兼容性
- 现有功能完全不受影响
- 所有修改均为追加式，未改动现有代码逻辑
- 测试通过率与之前版本一致

## 安装方法

```bash
# 检查设备连接
adb devices

# 安装应用
adb install -r releases/warehouse-app-v1.6.0-build60.apk

# 验证安装
adb shell dumpsys package com.example.picking_verification_app | grep versionName
```

## 系统要求
- Android 11+ (API 30+)
- ARM64架构
- 150 MB可用存储空间

## 测试清单

### 功能测试
- [ ] 工作台版本显示 V1.6.0
- [ ] 电缆入库按钮可点击进入
- [ ] 扫码查询返回正确物料信息
- [ ] 重复条码提示并阻止添加
- [ ] 无效条码显示错误信息
- [ ] 批量添加多个电缆
- [ ] 删除单个物料
- [ ] 清空列表
- [ ] 确认入库成功提示
- [ ] 返回按钮正常工作

### 边界测试
- [ ] 空列表时确认按钮禁用
- [ ] 网络错误提示
- [ ] 服务器错误提示

## 已知问题
- 无

## 下一版本计划
- 电缆退库功能 (待开发)
- 订单查询功能 (待开发)

## 开发备注

### 架构模式
本功能严格遵循 Clean Architecture 架构：
- **Data Layer**: 处理 API 调用和数据转换
- **Domain Layer**: 定义业务实体和仓库接口
- **Presentation Layer**: 使用 BLoC 管理状态，Flutter Widget 构建 UI

### 代码复用
- 复用现有的 `LineStockBloc` 和 `LineStockRepository`
- 复用错误处理和网络异常机制
- 复用扫码输入组件样式

### 测试设备
- 设备型号: CRUISE2_5G (d740)
- 设备ID: cd0aee1d
