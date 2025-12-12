# 改进：服务器错误消息显示

## 问题描述

**问题：** 当服务器返回HTTP 400错误时，用户看到的是Dio客户端的原始异常信息，而不是服务器返回的具体业务错误消息。

**用户看到的错误（改进前）：**
```
操作失败
提交验证失败: DioException [bad response]
This exception was thrown because the response has a status code of 400 and
RequestOptions.validateStatus was configured to throw for this status code.
The status code of 400 has the following meaning: "Client error - the request
contains bad syntax or cannot be fulfilled"
```

**问题：**
- ❌ 技术性太强，普通用户无法理解
- ❌ 没有显示服务器返回的具体错误原因
- ❌ 无法帮助用户了解如何解决问题

## 解决方案

### 改进1: 优化错误消息提取逻辑

在 `simple_picking_datasource.dart` 中增强了服务器错误消息的提取：

**改进前：**
```dart
String errorMessage = '提交验证失败';
if (e.response?.data != null) {
  if (e.response!.data is Map) {
    final data = e.response!.data as Map<String, dynamic>;
    if (data.containsKey('message')) {
      errorMessage = data['message'] as String;
    }
  }
}
throw Exception('HTTP 400错误: $errorMessage\n\n请检查配置: ...');
```

**改进后：**
```dart
String errorMessage = '提交验证失败';
if (e.response?.data != null) {
  try {
    if (e.response!.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      // 按优先级尝试多个可能的错误字段
      if (data.containsKey('message') && data['message'] != null) {
        errorMessage = data['message'] as String;
      } else if (data.containsKey('Message') && data['Message'] != null) {
        errorMessage = data['Message'] as String;
      } else if (data.containsKey('error') && data['error'] != null) {
        errorMessage = data['error'] as String;
      } else if (data.containsKey('Error') && data['Error'] != null) {
        errorMessage = data['Error'] as String;
      } else if (data.containsKey('msg') && data['msg'] != null) {
        errorMessage = data['msg'] as String;
      } else {
        errorMessage = '服务器返回错误: ${data.toString()}';
      }
    } else if (e.response!.data is String) {
      final dataStr = e.response!.data as String;
      if (dataStr.isNotEmpty) {
        errorMessage = dataStr;
      }
    }
  } catch (parseError) {
    errorMessage = '服务器返回了无法解析的错误信息';
  }
} else {
  errorMessage = '服务器未返回错误详情';
}

// 直接抛出服务器消息，简洁明了
throw Exception(errorMessage);
```

**改进点：**
- ✅ 支持多种错误字段命名：`message`, `Message`, `error`, `Error`, `msg`
- ✅ 增加空值检查，防止null错误
- ✅ 字符串响应的处理
- ✅ 异常处理防止解析失败
- ✅ 移除冗余的配置信息（已在日志中显示）
- ✅ 消息更简洁，直接显示服务器错误

### 改进2: 优化BLoC层的错误显示

在 `simple_picking_bloc.dart` 中改进了错误消息的格式化：

**改进前：**
```dart
} catch (e) {
  emit(SimplePickingError(
    message: '提交验证失败: ${e.toString()}',  // 显示完整的异常对象
    lastWorkOrder: workOrder,
  ));
}
```

**改进后：**
```dart
} catch (e) {
  // 提取友好的错误消息
  String errorMessage = '提交验证失败';

  if (e is Exception) {
    // Exception类型，提取消息
    final exceptionStr = e.toString();
    if (exceptionStr.startsWith('Exception: ')) {
      // 移除 'Exception: ' 前缀
      errorMessage = exceptionStr.substring(11);
    } else {
      errorMessage = exceptionStr;
    }
  } else {
    errorMessage = e.toString();
  }

  emit(SimplePickingError(
    message: errorMessage,  // 只显示错误消息，不显示类型前缀
    lastWorkOrder: workOrder,
  ));
}
```

**改进点：**
- ✅ 移除 `Exception: ` 前缀
- ✅ 只显示用户需要的错误消息
- ✅ 保持消息简洁友好

### 改进3: 其他HTTP错误的处理

同样改进了其他HTTP状态码（401, 403, 404, 500等）的错误消息提取：

```dart
// 处理其他HTTP错误 (401, 403, 404, 500等)
if (e.response != null) {
  String serverMessage = '未知错误';

  // 尝试从响应中提取服务器错误消息
  if (e.response!.data != null) {
    try {
      if (e.response!.data is Map) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data.containsKey('message') && data['message'] != null) {
          serverMessage = data['message'] as String;
        } else if (data.containsKey('Message') && data['Message'] != null) {
          serverMessage = data['Message'] as String;
        } else if (data.containsKey('error') && data['error'] != null) {
          serverMessage = data['error'] as String;
        }
      } else if (e.response!.data is String) {
        serverMessage = e.response!.data as String;
      }
    } catch (_) {
      serverMessage = e.message ?? '未知错误';
    }
  }

  throw Exception('提交失败 (HTTP ${e.response!.statusCode}): $serverMessage');
}
```

## 效果对比

### 场景1: 重复提交工单

**服务器返回：**
```json
{
  "isSuccess": false,
  "message": "该工单已经完成验证，不能重复提交",
  "data": null
}
```

**改进前用户看到：**
```
提交验证失败: DioException [bad response]
This exception was thrown because the response has a status code of 400...
```

**改进后用户看到：**
```
该工单已经完成验证，不能重复提交
```

---

### 场景2: 工单状态不允许提交

**服务器返回：**
```json
{
  "isSuccess": false,
  "message": "工单状态为'已取消'，无法进行验证",
  "data": null
}
```

**改进前用户看到：**
```
提交验证失败: DioException [bad response]...
```

**改进后用户看到：**
```
工单状态为'已取消'，无法进行验证
```

---

### 场景3: 物料数量不匹配

**服务器返回：**
```json
{
  "isSuccess": false,
  "message": "物料MAT001的完成数量与需求数量不符",
  "data": null
}
```

**改进前用户看到：**
```
提交验证失败: DioException [bad response]...
```

**改进后用户看到：**
```
物料MAT001的完成数量与需求数量不符
```

---

### 场景4: 服务器内部错误 (HTTP 500)

**服务器返回：**
```json
{
  "message": "数据库连接失败",
  "error": "Internal Server Error"
}
```

**改进前用户看到：**
```
提交验证失败: 提交失败 (HTTP 500): 未知错误
```

**改进后用户看到：**
```
提交失败 (HTTP 500): 数据库连接失败
```

## 支持的服务器响应格式

现在支持多种常见的服务器错误响应格式：

### 格式1: 标准JSON响应
```json
{
  "isSuccess": false,
  "message": "具体的错误消息",
  "data": null
}
```
→ 提取 `message` 字段

### 格式2: 首字母大写
```json
{
  "IsSuccess": false,
  "Message": "具体的错误消息",
  "Data": null
}
```
→ 提取 `Message` 字段

### 格式3: error字段
```json
{
  "error": "具体的错误消息"
}
```
→ 提取 `error` 字段

### 格式4: 简短msg字段
```json
{
  "success": false,
  "msg": "具体的错误消息"
}
```
→ 提取 `msg` 字段

### 格式5: 纯字符串
```
具体的错误消息文本
```
→ 直接使用整个响应

## 调试支持

启用 `AppConfig.enableApiDebugLogging = true` 时，日志会显示：

```
=== 工单提交异常 ===
异常类型: DioExceptionType.badResponse
状态码: 400
错误消息: DioException [bad response]: ...
响应数据: {"isSuccess":false,"message":"该工单已经完成验证","data":null}

🔍 HTTP 400 错误诊断信息:
1. 检查员工ID是否有效: operator
2. 检查工作中心代码是否有效: WC001
3. 检查工单状态是否允许提交
4. 请联系服务器管理员确认有效的配置值

最终错误消息: 该工单已经完成验证
```

**用户看到的界面消息：**
```
该工单已经完成验证
```

**开发者在日志中看到：**
- 完整的响应数据
- 诊断信息
- 配置值
- 最终提取的错误消息

## 修改的文件

1. **lib/features/picking_verification/data/datasources/simple_picking_datasource.dart**
   - 增强HTTP 400错误消息提取
   - 增强其他HTTP错误消息提取
   - 增加更多错误字段支持
   - 增加异常处理

2. **lib/features/picking_verification/presentation/bloc/simple_picking_bloc.dart**
   - 改进错误消息格式化
   - 移除"Exception: "前缀
   - 简化用户界面显示

## 使用建议

### 对于开发者

1. **启用调试日志** 查看完整的服务器响应：
   ```dart
   // app_config.dart
   static const bool enableApiDebugLogging = true;
   ```

2. **查看日志** 了解服务器返回的完整信息：
   ```bash
   adb logcat -s flutter | grep -E "工单提交异常|最终错误消息"
   ```

3. **生产环境** 记得关闭调试日志：
   ```dart
   static const bool enableApiDebugLogging = false;
   ```

### 对于用户

- 用户现在可以看到清晰的中文错误消息
- 错误消息直接说明问题所在
- 不再显示技术性的异常堆栈信息

## 未来改进

1. **错误代码映射** - 为常见错误定义错误代码和本地化消息
2. **重试建议** - 根据错误类型提供操作建议
3. **错误上报** - 收集错误统计，帮助改进系统
4. **离线队列** - 网络错误时支持离线队列

## 版本信息

**版本：** v1.5.4
**改进日期：** 2025-11-19
**改进类型：** 用户体验优化
**影响范围：** 所有API错误处理
