# 📱 仓库拣货验证 App - 日志查看指南

**版本**: 1.5.3+
**适用场景**: 生产环境问题排查、用户问题诊断
**最后更新**: 2025-11-10

---

## 📋 目录

1. [快速开始](#快速开始)
2. [PDA设备上直接查看](#pda设备上直接查看)
3. [通过USB连接电脑查看](#通过usb连接电脑查看)
4. [使用诊断脚本](#使用诊断脚本)
5. [日志内容说明](#日志内容说明)
6. [常见问题排查](#常见问题排查)
7. [故障排除](#故障排除)

---

## 🚀 快速开始

### 最快速的方法（推荐）

如果您有电脑和USB数据线：

```bash
# 1. 连接PDA到电脑
# 2. 在项目目录运行
cd /Users/benque/Projects/PickingVerficationApp
./scripts/quick_debug.sh

# 3. 在PDA上重现问题
# 4. 查看电脑屏幕的实时日志
```

---

## 📱 PDA设备上直接查看

### 方法一：使用 Logcat Reader 应用（推荐）

#### 安装步骤

1. **在PDA上打开 Google Play 商店**
2. **搜索** "Logcat Reader" 或 "aLogcat"
3. **安装**应用（选择评分高的应用）
4. **首次打开时**，授予读取日志的权限

#### 使用步骤

**A. 基本使用**

```
1. 打开 Logcat Reader 应用
2. 等待日志加载完成
3. 点击右上角"过滤"图标 🔍
4. 输入关键词: "flutter"
5. 日志会自动过滤显示
```

**B. 精确过滤（查找工单问题）**

```
1. 点击"过滤"按钮
2. 选择"包名"过滤
3. 输入: com.example.picking_verification_app
4. 或使用"标签"过滤，输入: flutter
```

**C. 搜索特定错误**

常用搜索关键词：
- `工单详情` - 查看工单查询相关日志
- `订单号` - 查看订单号信息
- `状态码` - 查看HTTP响应状态
- `错误` 或 `异常` - 查看错误信息
- `响应数据` - 查看服务器返回内容

**D. 保存日志**

```
1. 点击右上角"菜单"图标 ⋮
2. 选择"保存日志"或"分享"
3. 选择保存位置（如：下载文件夹）
4. 文件名会自动生成，如: logcat_20251110_120000.txt
5. 可通过邮件或文件管理器发送
```

#### 实时监控示例

**场景**：用户扫描订单时出错

1. **准备**：打开 Logcat Reader，清除旧日志
2. **操作**：
   - 打开拣货验证App
   - 点击"扫描订单"
   - 输入订单号
3. **观察**：Logcat Reader会实时显示日志
4. **查找**：搜索"订单号"或"错误"关键词

---

### 方法二：系统自带Bug报告（无需安装应用）

#### 启用开发者选项

```
设置 → 关于手机 → 版本号（连续点击7次）
```

提示"您现在处于开发者模式"

#### 生成Bug报告

**Android 11+**:
```
设置 → 系统 → 开发者选项 → Bug报告
→ 选择"完整报告"
→ 等待生成（约2-5分钟）
```

**Android 9/10**:
```
设置 → 系统 → 开发者选项 → 获取错误报告
→ 点击"Bug报告"
→ 等待生成
```

#### 查看报告

1. **通知栏**会显示"Bug报告已生成"
2. **点击通知**，选择"分享"
3. **文件位置**: `/sdcard/bugreports/bugreport-*.zip`
4. **内容**: 包含完整系统日志、应用日志、设备信息

---

## 💻 通过USB连接电脑查看

### 前置条件

#### 1. 启用USB调试

```
设置 → 系统 → 开发者选项 → USB调试（打开）
```

#### 2. 连接设备

- 使用USB数据线连接PDA到电脑
- PDA屏幕会弹出"允许USB调试"对话框
- 勾选"始终允许来自这台计算机"
- 点击"确定"

#### 3. 验证连接

**Mac/Linux**:
```bash
cd ~/Library/Android/sdk/platform-tools
./adb devices
```

**Windows**:
```cmd
cd C:\Users\你的用户名\AppData\Local\Android\sdk\platform-tools
adb.exe devices
```

**预期输出**:
```
List of devices attached
1234567890ABCDEF    device
```

---

### 方法一：使用 Android Studio Logcat

#### 打开Logcat

```
1. 启动 Android Studio
2. 菜单: View → Tool Windows → Logcat
3. 选择您的设备（顶部下拉菜单）
4. 等待日志开始流动
```

#### 过滤日志

**A. 按应用包名过滤**
```
在过滤框输入: package:com.example.picking_verification_app
```

**B. 按标签过滤**
```
在过滤框输入: tag:flutter
```

**C. 按关键词过滤**
```
在搜索框输入: 工单详情
或: 订单号
或: 错误
```

**D. 按日志级别过滤**
- Verbose (V) - 全部
- Debug (D) - 调试信息
- Info (I) - 一般信息
- Warn (W) - 警告
- Error (E) - 错误
- Assert (A) - 断言失败

#### 保存日志

```
1. 右键点击日志区域
2. 选择 "Save As..."
3. 选择保存位置和文件名
4. 点击"Save"
```

---

### 方法二：使用 ADB 命令行

#### 基本命令

**实时查看所有日志**:
```bash
adb logcat
```

**只看Flutter应用日志**:
```bash
# Mac/Linux
adb logcat | grep flutter

# Windows
adb logcat | findstr "flutter"
```

**只看错误和工单相关**:
```bash
# Mac/Linux
adb logcat | grep -E "工单|订单|错误|异常"

# Windows
adb logcat | findstr "工单 订单 错误 异常"
```

#### 保存日志到文件

```bash
# 保存最近的日志
adb logcat -d > app_log.txt

# 持续保存（按Ctrl+C停止）
adb logcat > app_log_$(date +%Y%m%d_%H%M%S).txt
```

#### 清除日志缓冲区

```bash
adb logcat -c
```

---

## 🛠️ 使用诊断脚本

### 脚本位置

```
项目目录/scripts/
├── quick_debug.sh       # 实时监控脚本
└── collect_logs.sh      # 日志收集脚本
```

### 脚本一：快速实时监控

#### 功能
- ✅ 自动检测设备连接
- ✅ 只显示关键日志（过滤噪音）
- ✅ 彩色高亮（绿色=成功，红色=错误）
- ✅ 实时显示

#### 使用方法

```bash
# 在项目目录运行
cd /Users/benque/Projects/PickingVerficationApp
./scripts/quick_debug.sh
```

#### 输出示例

```
=== 仓库拣货验证 App 实时日志监控 ===

✓ 设备已连接

监控以下关键日志:
• 工单查询请求
• HTTP 响应状态
• 错误消息
• 服务器返回数据

提示: 按 Ctrl+C 停止监控

--- 开始监控 ---

I/flutter: === 开始获取工单详情 ===        [蓝色]
I/flutter: 订单号: 123456789              [蓝色]
I/flutter: 请求URL: http://...           [蓝色]
I/flutter: 响应状态码: 400                [黄色]
I/flutter: 服务器返回错误消息: 扫码出错... [红色]
```

#### 适用场景
- ✅ 用户报告问题时实时排查
- ✅ 快速确认错误原因
- ✅ 验证修复效果

---

### 脚本二：完整日志收集

#### 功能
- ✅ 自动收集指定时长的日志
- ✅ 生成3个日志文件（完整、过滤、错误）
- ✅ 自动分析常见问题
- ✅ 提供统计报告

#### 使用方法

```bash
# 收集60秒的日志
./scripts/collect_logs.sh 60

# 收集30秒的日志
./scripts/collect_logs.sh 30

# 默认收集60秒
./scripts/collect_logs.sh
```

#### 生成的文件

```
logs/
├── app_log_20251110_120000.txt          # 完整日志
├── app_filtered_20251110_120000.txt     # 仅Flutter日志
└── app_errors_20251110_120000.txt       # 仅错误日志
```

#### 输出报告示例

```
=== 日志收集报告 ===

完整日志: logs/app_log_20251110_120000.txt
  行数: 1523
  大小: 245K

过滤日志 (仅 Flutter): logs/app_filtered_20251110_120000.txt
  行数: 89

错误日志: logs/app_errors_20251110_120000.txt
  行数: 12

=== HTTP 400 错误检测 ===
检测到 2 次 HTTP 400 错误

详细信息:
I/flutter: 状态码: 400
I/flutter: 响应数据: {"isSuccess":false,"message":"扫码出错：未查询到订单信息"}

=== 工单查询请求检测 ===
工单查询次数: 5
```

#### 适用场景
- ✅ 问题难以重现，需要长时间监控
- ✅ 需要完整日志进行详细分析
- ✅ 需要发送日志给技术支持

---

## 📖 日志内容说明

### 版本 1.5.3+ 的关键日志

#### 1. 工单查询开始

```
I/flutter: === 开始获取工单详情 ===
I/flutter: 订单号: ORD123456
I/flutter: 请求URL: http://10.163.130.173:8001/api/WorkOrderPickVerf?orderno=ORD123456
```

**说明**:
- 用户扫描或输入了订单号
- 准备向服务器发送请求

---

#### 2. 成功响应

```
I/flutter: 响应状态码: 200
I/flutter: 响应数据: {"isSuccess":true,"message":"查询成功","data":{...}}
I/flutter: 工单详情获取成功: 查询成功
```

**说明**:
- ✅ 服务器返回成功
- ✅ 订单存在且数据有效
- ✅ 用户会看到订单详情

---

#### 3. 订单不存在错误（修复后）

```
I/flutter: === 网络请求异常 ===
I/flutter: 异常类型: DioExceptionType.response
I/flutter: 状态码: 400
I/flutter: 响应数据: {"isSuccess":false,"message":"扫码出错：未查询到订单信息","data":null}
I/flutter: 服务器返回错误消息: 扫码出错：未查询到订单信息
```

**说明**:
- ⚠️ 服务器返回 HTTP 400
- ⚠️ 订单号不存在或无效
- ✅ **v1.5.3修复**: 用户看到详细错误 "扫码出错：未查询到订单信息"
- ❌ **v1.5.2及之前**: 用户只看到 "获取工单详情失败：HTTP 400"

---

#### 4. 订单状态不符错误

```
I/flutter: 状态码: 400
I/flutter: 响应数据: {"isSuccess":false,"message":"该工单已完成验证","data":null}
I/flutter: 服务器返回错误消息: 该工单已完成验证
```

**说明**:
- ⚠️ 订单存在但状态不符合验证条件
- ✅ 用户看到清晰的错误："该工单已完成验证"

---

#### 5. 网络超时错误

```
I/flutter: === 网络请求异常 ===
I/flutter: 异常类型: DioExceptionType.connectionTimeout
I/flutter: 连接超时,请检查网络连接
```

**说明**:
- ⚠️ 网络连接超时（10秒内无响应）
- 可能原因：网络断开、服务器无响应、网络延迟过高

---

#### 6. 服务器错误

```
I/flutter: 状态码: 500
I/flutter: 服务器内部错误,请稍后重试
```

**说明**:
- ⚠️ 服务器端发生错误
- 需要联系服务器端技术人员排查

---

### 日志级别说明

| 级别 | 标记 | 说明 | 示例 |
|------|------|------|------|
| Verbose | V | 详细信息 | V/flutter: 详细的调试信息 |
| Debug | D | 调试信息 | D/flutter: 调试输出 |
| Info | I | 一般信息 | I/flutter: 工单详情获取成功 |
| Warning | W | 警告 | W/flutter: 警告信息 |
| Error | E | 错误 | E/flutter: 发生错误 |

我们的日志主要使用 **Info (I)** 级别。

---

## 🔍 常见问题排查

### 问题1：用户报告"扫描订单失败"

#### 排查步骤

1. **收集信息**：
   - 订单号是多少？
   - 显示的错误消息是什么？
   - 发生时间？

2. **查看日志**：
   ```bash
   ./scripts/quick_debug.sh
   # 或
   ./scripts/collect_logs.sh 30
   ```

3. **搜索关键词**：
   - 搜索订单号（如：`ORD123456`）
   - 查看前后的日志

4. **分析结果**：

   **A. 看到 "状态码: 400" + "未查询到订单信息"**
   ```
   结论: 订单号不存在
   解决: 确认订单号是否正确
   ```

   **B. 看到 "状态码: 400" + "该工单已完成验证"**
   ```
   结论: 订单已被处理
   解决: 确认是否重复扫描
   ```

   **C. 看到 "连接超时"**
   ```
   结论: 网络问题
   解决: 检查WiFi连接、服务器状态
   ```

   **D. 看到 "状态码: 500"**
   ```
   结论: 服务器错误
   解决: 联系服务器端技术人员
   ```

---

### 问题2：应用运行缓慢

#### 排查步骤

1. **收集长时间日志**：
   ```bash
   ./scripts/collect_logs.sh 120  # 收集2分钟
   ```

2. **查看日志文件**：
   ```bash
   cat logs/app_errors_*.txt | grep -E "超时|timeout"
   ```

3. **检查响应时间**：
   - 查看"请求URL"和"响应状态码"之间的时间差
   - 正常应该在1-2秒内

4. **可能原因**：
   - 网络延迟高
   - 服务器负载高
   - 数据量过大

---

### 问题3：显示的错误消息不清楚（仍显示HTTP 400）

#### 检查版本

1. **确认应用版本**：
   - 打开应用
   - 点击右上角员工信息
   - 查看版本号

2. **如果版本 < v1.5.3**：
   ```
   原因: 使用旧版本，未包含修复
   解决: 更新到 v1.5.3 或更高版本
   ```

3. **如果版本 = v1.5.3+**：
   ```
   原因: 服务器返回的响应格式不正确
   解决: 检查服务器端日志和响应格式
   ```

---

## 🚨 故障排除

### 问题：无法连接设备

#### 症状
```bash
adb devices
# 输出: List of devices attached
# （列表为空）
```

#### 解决方法

**1. 检查USB连接**
- 确保USB数据线插好
- 尝试更换USB端口
- 尝试更换USB数据线

**2. 启用USB调试**
```
设置 → 系统 → 开发者选项 → USB调试（打开）
```

**3. 重启ADB服务**
```bash
adb kill-server
adb start-server
adb devices
```

**4. 重新授权**
- 拔下USB
- 在PDA上：设置 → 开发者选项 → 撤销USB调试授权
- 重新插入USB
- 点击"始终允许"

---

### 问题：脚本无法执行

#### 症状
```bash
./scripts/quick_debug.sh
# bash: ./scripts/quick_debug.sh: Permission denied
```

#### 解决方法
```bash
chmod +x scripts/quick_debug.sh
chmod +x scripts/collect_logs.sh
./scripts/quick_debug.sh
```

---

### 问题：看不到Flutter日志

#### 症状
运行 `adb logcat` 但看不到任何Flutter应用的日志

#### 解决方法

**1. 确认应用正在运行**
```bash
adb shell "ps | grep picking_verification"
```

**2. 清除日志缓冲区并重试**
```bash
adb logcat -c
adb logcat | grep flutter
```

**3. 检查是否是Release构建**
- Release构建会自动移除某些调试日志
- 但 `debugPrint` 仍然会输出

**4. 尝试查看所有日志**
```bash
adb logcat | grep -i "picking_verification\|flutter"
```

---

### 问题：Logcat Reader无法获取日志权限

#### 症状
应用提示"需要授予读取日志权限"但无法授予

#### 解决方法

**方法一：通过ADB授予**
```bash
adb shell pm grant com.pluscubed.logcat android.permission.READ_LOGS
```

**方法二：使用系统设置**
```
设置 → 应用 → Logcat Reader → 权限
→ 手动授予所需权限
```

---

## 📋 快速参考卡

### 命令速查表

| 任务 | 命令 |
|------|------|
| 检查设备连接 | `adb devices` |
| 实时查看日志 | `adb logcat` |
| 只看Flutter日志 | `adb logcat \| grep flutter` |
| 清除日志 | `adb logcat -c` |
| 保存日志 | `adb logcat > log.txt` |
| 使用监控脚本 | `./scripts/quick_debug.sh` |
| 收集日志 | `./scripts/collect_logs.sh 60` |

### 常用搜索关键词

| 场景 | 关键词 |
|------|--------|
| 工单查询 | `工单详情` `订单号` |
| HTTP错误 | `状态码` `响应数据` |
| 网络问题 | `超时` `连接` `网络` |
| 服务器错误 | `服务器` `500` `异常` |
| 错误消息 | `错误` `异常` `失败` |

### 日志文件位置

| 位置 | 说明 |
|------|------|
| `logs/app_log_*.txt` | 完整日志 |
| `logs/app_filtered_*.txt` | Flutter日志 |
| `logs/app_errors_*.txt` | 仅错误 |
| `/sdcard/bugreports/` | 系统Bug报告 |

---

## 📞 技术支持

### 发送日志给技术支持

**1. 使用脚本收集**：
```bash
./scripts/collect_logs.sh 60
```

**2. 打包日志**：
```bash
cd logs
tar -czf logs_issue_$(date +%Y%m%d).tar.gz *_$(date +%Y%m%d)*.txt
```

**3. 发送文件**：
- 通过邮件发送 `logs_issue_YYYYMMDD.tar.gz`
- 或使用公司内部文件传输系统

### 报告问题时请包含

- ✅ 应用版本号（如：v1.5.3）
- ✅ 发生时间
- ✅ 订单号（如适用）
- ✅ 错误消息
- ✅ 日志文件
- ✅ 重现步骤

---

## 🎯 总结

### 推荐的日志查看方法

| 场景 | 推荐方法 | 难度 |
|------|----------|------|
| 现场快速排查 | quick_debug.sh脚本 | ⭐ 简单 |
| 详细问题分析 | collect_logs.sh脚本 | ⭐ 简单 |
| 无电脑可用 | Logcat Reader应用 | ⭐⭐ 中等 |
| 深度分析 | Android Studio | ⭐⭐⭐ 复杂 |

### 关键点

1. ✅ **v1.5.3+ 的改进**：错误消息更清晰
2. ✅ **实时监控**：使用 `quick_debug.sh`
3. ✅ **完整收集**：使用 `collect_logs.sh`
4. ✅ **关键词搜索**：`工单详情` `订单号` `状态码` `错误`

---

**文档版本**: 1.0
**创建日期**: 2025-11-10
**适用版本**: App v1.5.3+

如有问题或建议，请联系技术支持团队。
