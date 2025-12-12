# HTTP 400 错误排查指南

## 问题描述

在使用移动端进行合箱验证（容器校验）时，提交时出现 "操作失败" 错误，显示 `DioException [bad response]`，HTTP状态码为400。

错误提示示例：
```
提交验证失败: DioException [bad response]
This exception was thrown because the response has a status code of 400 and
RequestOptions.validateStatus was configured to throw for this status code.
```

## 根本原因

HTTP 400 错误表示 "客户端错误 - 请求包含错误的语法或无法完成"。在本应用中，最常见的原因是：

1. **无效的员工ID** - 服务器数据库中不存在该员工ID
2. **无效的工作中心代码** - 服务器数据库中不存在该工作中心代码
3. **工单状态不允许提交** - 工单已经完成或被锁定
4. **请求参数格式错误** - 参数类型或格式不符合API要求

## 诊断步骤

### 步骤1: 查看应用日志

使用 `adb logcat` 命令查看详细的错误日志：

```bash
# 连接设备
adb devices

# 查看Flutter应用日志
adb logcat -s flutter

# 或者过滤特定关键词
adb logcat | grep -E "工单提交异常|HTTP 400"
```

### 步骤2: 检查配置值

查看 `lib/core/config/app_config.dart` 文件中的配置：

```dart
static const String defaultEmployeeId = 'operator';  // 当前配置的员工ID
static const String defaultWorkCenter = 'WC001';     // 当前配置的工作中心代码
```

### 步骤3: 查看详细的诊断信息

在日志中查找以下诊断信息（当 `enableApiDebugLogging = true` 时）：

```
=== 开始提交工单验证 ===
工单ID: 12345
工序: 0001
状态: verfSuccess
工作中心: WC001        ← 检查这个值
操作人: operator        ← 检查这个值
请求URL: http://10.163.130.173:8001/api/WorkOrderPickVerf
请求方法: PUT
请求体: {...}

=== 工单提交异常 ===
异常类型: DioExceptionType.badResponse
状态码: 400
错误消息: [服务器返回的错误消息]

🔍 HTTP 400 错误诊断信息:
1. 检查员工ID是否有效: operator
2. 检查工作中心代码是否有效: WC001
3. 检查工单状态是否允许提交
4. 请联系服务器管理员确认有效的配置值
```

## 解决方案

### 解决方案1: 更新配置文件中的员工ID和工作中心代码

1. 联系服务器管理员获取有效的员工ID和工作中心代码
2. 修改 `lib/core/config/app_config.dart`：

```dart
/// 默认员工ID - 从服务器管理员获取有效值
static const String defaultEmployeeId = 'YOUR_VALID_EMPLOYEE_ID';

/// 默认工作中心代码 - 从服务器管理员获取有效值
static const String defaultWorkCenter = 'YOUR_VALID_WORK_CENTER';
```

3. 重新编译并安装应用：

```bash
flutter clean
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 解决方案2: 检查工单状态

如果员工ID和工作中心代码正确，但仍然出现400错误，可能是工单状态问题：

1. 确认工单尚未完成
2. 确认所有物料的验证状态为 "已完成"
3. 检查工单是否被其他用户锁定
4. 查看服务器日志确认具体的验证失败原因

### 解决方案3: 启用调试模式查看详细信息

修改 `lib/core/config/app_config.dart` 启用调试日志：

```dart
static const bool enableApiDebugLogging = true;
```

重新编译并运行应用，然后查看 `adb logcat` 输出的详细请求和响应信息。

## 常见配置值参考

以下是一些常见的有效配置值示例（实际值需要从服务器管理员确认）：

### 员工ID示例
```
'operator'    - 通用操作员账号
'admin'       - 管理员账号
'EMP001'      - 员工工号格式1
'USER123'     - 员工工号格式2
'ZH001'       - 中文姓名拼音+工号
```

### 工作中心代码示例
```
'WC001'         - 工作中心1
'WC-A-01'       - 按区域划分的工作中心
'ASSEMBLY'      - 装配车间
'WAREHOUSE'     - 仓库
'PROD_LINE_1'   - 生产线1
```

## API请求格式

合箱验证提交的API请求格式如下：

**请求方法:** PUT
**请求URL:** `http://10.163.130.173:8001/api/WorkOrderPickVerf`

**请求体:**
```json
{
  "workOrderId": 12345,
  "operation": "0001",
  "status": "verfSuccess",
  "workCenter": "WC001",
  "updateOn": "2025-11-19T12:30:45.123Z",
  "updateBy": "operator"
}
```

**成功响应 (HTTP 200):**
```json
{
  "isSuccess": true,
  "message": "验证成功",
  "data": true
}
```

**失败响应 (HTTP 400):**
```json
{
  "isSuccess": false,
  "message": "员工ID不存在",  // 或其他错误信息
  "data": null
}
```

## 服务器端验证规则

服务器可能会执行以下验证：

1. **员工ID验证**
   - 检查员工ID是否在员工表中存在
   - 检查员工是否有权限操作该工单
   - 检查员工是否在职（状态为活动）

2. **工作中心验证**
   - 检查工作中心代码是否在工作中心表中存在
   - 检查工作中心是否属于当前员工的管辖范围
   - 检查工作中心状态是否可用

3. **工单状态验证**
   - 检查工单是否存在
   - 检查工单是否已经完成
   - 检查工单是否被锁定
   - 检查所有物料是否都已完成验证

4. **权限验证**
   - 检查员工是否有提交权限
   - 检查工单是否分配给该员工
   - 检查操作时间是否在允许范围内

## 配置验证

应用启动时会自动验证配置，可以在代码中手动调用：

```dart
final errors = AppConfig.validateUserConfig();
if (errors.isNotEmpty) {
  for (final error in errors) {
    print('配置错误: $error');
  }
}
```

也可以查看配置摘要：

```dart
print(AppConfig.getConfigSummary());
```

输出示例：
```
========== 应用配置摘要 ==========
API服务器: http://192.168.1.100:8080/api
更新服务器: http://10.163.130.173:8000
员工ID: operator
工作中心: WC001
API调试日志: 启用
API超时: 30000ms
自动更新: 启用
================================
```

## 预防措施

1. **部署前确认配置**
   - 在部署到生产环境前，必须从服务器管理员确认有效的配置值
   - 使用测试账号先进行验证

2. **定期检查日志**
   - 定期查看应用日志，及时发现配置问题
   - 收集用户反馈的错误信息

3. **配置文档化**
   - 为每个部署环境维护配置文档
   - 记录每个配置值的来源和验证方式

4. **错误监控**
   - 实施错误监控机制
   - 收集HTTP 400错误的详细信息
   - 定期分析错误模式

## 相关文件

- `lib/core/config/app_config.dart` - 应用配置文件
- `lib/features/picking_verification/presentation/pages/simple_picking_screen.dart` - 提交逻辑
- `lib/features/picking_verification/data/datasources/simple_picking_datasource.dart` - API调用和错误处理
- `lib/features/picking_verification/data/models/simple_api_models.dart` - API请求模型
- `docs/BUG_FIX_HTTP_400_ERROR.md` - HTTP 400错误修复文档

## 联系支持

如果以上步骤无法解决问题：

1. 收集完整的日志输出（包括请求和响应）
2. 记录当前的配置值
3. 联系服务器管理员确认服务器端的验证规则
4. 如有需要，联系应用开发团队进行深入诊断

## 版本历史

- **v1.5.3** - 改进HTTP 400错误信息显示，添加详细的诊断日志
- **v1.5.4** - 添加AppConfig配置管理，移除硬编码值，增强错误处理
