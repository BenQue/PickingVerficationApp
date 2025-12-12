# 仓库管理应用 v1.5.5 发布说明

**发布日期:** 2025-11-19
**版本号:** 1.5.5
**构建号:** 45
**APK文件:** warehouse-app-v1.5.5-build45.apk
**文件大小:** 78MB

---

## 📋 版本概述

v1.5.5 是一个重要的用户体验改进版本，主要解决HTTP 400错误显示不友好的问题，并优化了错误处理机制。

---

## ✨ 新功能

### 1. 集中配置管理系统

- ✅ 新增 `AppConfig` 配置类，统一管理应用配置
- ✅ 支持配置验证和摘要输出
- ✅ 便于根据部署环境调整配置

**配置项包括：**
- 默认员工ID (`defaultEmployeeId`)
- 默认工作中心代码 (`defaultWorkCenter`)
- API调试日志开关 (`enableApiDebugLogging`)
- API超时时间 (`apiTimeoutMs`)

### 2. 增强的错误诊断功能

- ✅ 详细的API请求日志（可配置开关）
- ✅ 完整的API响应日志
- ✅ HTTP 400错误的专门诊断信息
- ✅ 配置值验证和检查提示

---

## 🐛 重要修复

### 1. HTTP 400错误消息显示优化 (关键改进)

**问题：** 用户看到技术性的DioException信息，无法理解具体错误原因

**改进前：**
```
操作失败
提交验证失败: DioException [bad response]
This exception was thrown because the response has a status code of 400...
```

**改进后：**
```
该工单已经完成验证，不能重复提交
```

**改进内容：**
- ✅ 智能提取服务器返回的错误消息
- ✅ 支持多种错误字段格式 (`message`, `Message`, `error`, `Error`, `msg`)
- ✅ 移除技术性的异常类型前缀
- ✅ 直接显示用户友好的中文错误信息
- ✅ 处理JSON和字符串两种响应格式

### 2. 错误处理增强

**改进的HTTP错误处理：**
- ✅ HTTP 400 - 智能提取服务器业务错误消息
- ✅ HTTP 401, 403, 404, 500 - 提取并显示服务器错误详情
- ✅ 网络超时 - 显示友好的超时提示
- ✅ 连接失败 - 提供网络检查建议

**错误消息提取优先级：**
1. `message` 字段
2. `Message` 字段（首字母大写）
3. `error` 字段
4. `Error` 字段
5. `msg` 字段
6. 整个响应内容

### 3. BLoC层错误格式化

- ✅ 移除 `Exception: ` 前缀
- ✅ 只显示实际错误消息
- ✅ 保持用户界面简洁

---

## 🔧 技术改进

### 1. 代码重构

**移除硬编码值：**
```dart
// 改进前
const SubmitVerification(
  updateBy: 'operator',  // 硬编码
  workCenter: 'WC001',   // 硬编码
)

// 改进后
const SubmitVerification(
  updateBy: AppConfig.defaultEmployeeId,
  workCenter: AppConfig.defaultWorkCenter,
)
```

### 2. 日志增强

**调试模式下的详细日志：**
```
=== 开始提交工单验证 ===
工单ID: 12345
工序: 0001
状态: verfSuccess
工作中心: WC001
操作人: operator
请求URL: http://10.163.130.173:8001/api/WorkOrderPickVerf
请求体: {"workOrderId":12345,...}

=== 工单提交异常 ===
状态码: 400
响应数据: {"isSuccess":false,"message":"该工单已经完成验证","data":null}

🔍 HTTP 400 错误诊断信息:
1. 检查员工ID是否有效: operator
2. 检查工作中心代码是否有效: WC001
3. 检查工单状态是否允许提交
4. 请联系服务器管理员确认有效的配置值

最终错误消息: 该工单已经完成验证
```

### 3. 配置管理

**新增配置验证方法：**
```dart
// 验证配置
final errors = AppConfig.validateUserConfig();

// 查看配置摘要
print(AppConfig.getConfigSummary());
```

---

## 📖 文档更新

### 新增文档

1. **TROUBLESHOOTING_HTTP_400.md** - HTTP 400错误完整排查指南
   - 问题描述和根本原因
   - 详细的诊断步骤
   - 多种解决方案
   - 常见配置值参考
   - API请求格式说明
   - 服务器端验证规则

2. **FIX_HTTP_400_CONFIG_SOLUTION.md** - HTTP 400配置管理解决方案
   - 问题分析
   - 实施的解决方案
   - 使用指南
   - 诊断模式说明
   - 验证清单

3. **IMPROVEMENT_ERROR_MESSAGES.md** - 错误消息显示改进说明
   - 改进前后对比
   - 实现细节
   - 效果演示
   - 支持的响应格式

---

## 🎯 修改的文件

### 核心文件

1. **lib/core/config/app_config.dart** (新增)
   - 集中配置管理
   - 配置验证方法
   - 配置摘要输出

2. **lib/features/picking_verification/presentation/pages/simple_picking_screen.dart**
   - 导入AppConfig
   - 使用配置值替换硬编码

3. **lib/features/picking_verification/data/datasources/simple_picking_datasource.dart**
   - 增强HTTP 400错误处理
   - 增强其他HTTP错误处理
   - 添加详细日志输出
   - 智能错误消息提取

4. **lib/features/picking_verification/presentation/bloc/simple_picking_bloc.dart**
   - 改进错误消息格式化
   - 移除Exception前缀

5. **lib/features/picking_verification/presentation/pages/workbench_home_screen.dart**
   - 更新版本号显示: V1.5.4 → V1.5.5

6. **pubspec.yaml**
   - 更新版本号: 1.5.4+44 → 1.5.5+45

---

## 🔍 使用场景示例

### 场景1: 工单重复提交

**服务器返回：**
```json
{
  "isSuccess": false,
  "message": "该工单已经完成验证，不能重复提交",
  "data": null
}
```

**用户看到：**
```
该工单已经完成验证，不能重复提交
```

### 场景2: 工单状态不允许

**服务器返回：**
```json
{
  "isSuccess": false,
  "message": "工单状态为'已取消'，无法进行验证",
  "data": null
}
```

**用户看到：**
```
工单状态为'已取消'，无法进行验证
```

### 场景3: 物料数量不匹配

**服务器返回：**
```json
{
  "isSuccess": false,
  "message": "物料MAT001的完成数量与需求数量不符",
  "data": null
}
```

**用户看到：**
```
物料MAT001的完成数量与需求数量不符
```

---

## ⚙️ 配置说明

### 调试模式

**启用调试日志** (用于问题诊断)：
```dart
// lib/core/config/app_config.dart
static const bool enableApiDebugLogging = true;
```

**查看日志：**
```bash
adb logcat -s flutter
```

### 生产环境

**关闭调试日志** (生产部署)：
```dart
static const bool enableApiDebugLogging = false;
```

---

## 📦 安装说明

### 方法1: 直接安装

```bash
# 检查设备连接
adb devices

# 安装APK
adb install -r releases/warehouse-app-v1.5.5-build45.apk

# 验证安装
adb shell dumpsys package com.example.picking_verification_app | grep versionName
```

### 方法2: 手动安装

1. 将 `warehouse-app-v1.5.5-build45.apk` 复制到设备
2. 在设备上打开文件管理器
3. 找到APK文件并点击安装
4. 允许从此来源安装应用
5. 完成安装

---

## ✅ 验证清单

安装后请验证：

- [ ] 应用启动正常
- [ ] 版本号显示为 **V1.5.5**（点击右上角员工信息按钮查看）
- [ ] 扫描订单功能正常
- [ ] 物料验证功能正常
- [ ] 提交验证功能正常
- [ ] 错误消息显示清晰易懂
- [ ] 如遇HTTP 400错误，能看到服务器返回的具体错误消息

---

## 🐛 已知问题

无

---

## ⚠️ 重要提示

### 关于配置

当前版本使用固定配置值：
- 员工ID: `operator`
- 工作中心: `WC001`

如果服务器返回HTTP 400错误，请：
1. 查看应用日志中的错误消息
2. 联系服务器管理员确认有效的配置值
3. 如需修改配置，需要重新编译应用

### 关于调试

- 默认启用API调试日志，方便问题诊断
- 生产环境部署时建议关闭调试日志
- 可通过 `adb logcat` 查看详细日志

---

## 📞 技术支持

如遇到问题：

1. **查看日志**：`adb logcat -s flutter`
2. **查看文档**：
   - `docs/TROUBLESHOOTING_HTTP_400.md` - 错误排查
   - `docs/FIX_HTTP_400_CONFIG_SOLUTION.md` - 配置方案
   - `docs/IMPROVEMENT_ERROR_MESSAGES.md` - 改进说明
3. **联系开发团队**

---

## 🔄 升级路径

### 从 v1.5.4 升级

直接安装v1.5.5即可，无需卸载旧版本。应用会自动升级。

### 从更早版本升级

建议先升级到v1.5.4，再升级到v1.5.5。

---

## 📊 版本对比

| 功能 | v1.5.4 | v1.5.5 |
|------|--------|--------|
| HTTP 400错误显示 | DioException原始信息 | 服务器业务错误消息 |
| 配置管理 | 硬编码值 | 集中配置类 |
| 错误诊断 | 基础日志 | 详细诊断信息 |
| 调试支持 | 部分日志 | 完整请求/响应日志 |
| 文档 | 基础说明 | 完整排查指南 |

---

## 🎉 总结

v1.5.5版本通过优化错误消息显示和增强配置管理，大幅提升了用户体验。当用户遇到错误时，现在能够：

✅ 看到清晰的中文错误消息
✅ 理解错误的具体原因
✅ 通过日志快速定位问题
✅ 便捷地调整配置参数

这是一个重要的用户体验改进版本，强烈建议所有用户升级。

---

**编译信息:**
- Flutter SDK: 3.8.1
- Dart SDK: 3.8.1
- 编译日期: 2025-11-19
- 编译模式: Release
- 最小SDK版本: Android 5.0 (API 21)
- 目标SDK版本: Android 14 (API 34)
