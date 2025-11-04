# 应用自动更新功能使用指南

本文档说明如何使用仓库应用的自动更新功能，包括首次部署、日常使用和故障排查。

---

## 📋 目录

1. [功能概述](#功能概述)
2. [首次部署](#首次部署)
3. [发布新版本](#发布新版本)
4. [用户体验](#用户体验)
5. [配置说明](#配置说明)
6. [故障排查](#故障排查)
7. [常见问题](#常见问题)

---

## 功能概述

### 核心功能

- ✅ **自动检查更新**: 应用启动时自动检查服务器版本
- ✅ **版本比较**: 智能比较版本号，只在有新版本时提示
- ✅ **在线下载**: 通过WiFi从内网服务器下载APK
- ✅ **进度显示**: 实时显示下载进度和百分比
- ✅ **安全安装**: 下载完成后自动调用系统安装器
- ✅ **强制更新**: 支持配置强制更新（用户无法跳过）
- ✅ **手动检查**: 用户可在应用信息中手动检查更新

### 技术架构

```
┌──────────────┐     HTTP     ┌──────────────┐
│ Windows服务器 │ ◄────────── │   PDA设备    │
│     HFS      │              │  Flutter App │
│              │              │              │
│ version.json │ ────────────►│ 版本检查逻辑  │
│ *.apk files  │ ────────────►│ 下载&安装    │
└──────────────┘              └──────────────┘
```

---

## 首次部署

### 第1步: 配置服务器

详见 [docs/SERVER_SETUP.md](./SERVER_SETUP.md)

**快速摘要:**
1. 在Windows服务器安装HFS
2. 添加`releases`目录到HFS
3. 确保防火墙允许HFS端口(80或8080)
4. 测试访问: `http://服务器IP/version.json`

### 第2步: 配置Flutter应用

修改 `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  /// 更新服务器URL - 替换为您的服务器IP
  static const String updateServerUrl = 'http://192.168.1.100'; // 改为实际IP

  /// 是否启用自动更新
  static const bool enableAutoUpdate = true;

  /// 启动时是否检查更新
  static const bool checkUpdateOnStartup = true;
}
```

### 第3步: 构建并部署应用

```bash
# 1. 清理构建
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 构建Release APK
flutter build apk --release

# 4. 安装到PDA设备
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 第4步: 验证功能

1. 打开应用
2. 点击右上角用户头像
3. 点击"检查更新"按钮
4. 应该显示"当前已是最新版本"或更新对话框

---

## 发布新版本

### 方式A: 使用自动化脚本（推荐）

```bash
# 在项目根目录运行
cd scripts
deploy_release.bat
```

脚本会自动:
1. ✅ 清理旧构建
2. ✅ 获取依赖
3. ✅ 构建Release APK
4. ✅ 复制到releases目录并重命名
5. ✅ 更新version.json配置

然后将`releases`目录复制到服务器即可。

### 方式B: 手动发布

#### 步骤1: 更新版本号

修改 `pubspec.yaml`:
```yaml
version: 1.5.0+40  # 版本名+构建号
```

修改UI显示版本（可选）:
```dart
// lib/features/picking_verification/presentation/pages/workbench_home_screen.dart
const Text('V1.5.0', ...)  // 更新显示版本
```

#### 步骤2: 构建APK

```bash
flutter clean
flutter build apk --release
```

#### 步骤3: 生成配置文件

```bash
cd scripts
update_version.bat
```

按提示输入:
- 版本号: `40`
- 版本名称: `1.5.0`
- 服务器IP: `192.168.1.100`
- 更新说明: 逐条输入，空行结束
- 是否强制更新: `N` (或 `Y`)

#### 步骤4: 部署到服务器

将 `releases/` 目录内容复制到服务器:
```
releases/
├── version.json                    # 最新版本配置
├── warehouse-app-v1.5.0-build40.apk  # 新版本APK
└── warehouse-app-v1.4.5-build39.apk  # 保留旧版本
```

---

## 用户体验

### 自动更新流程

```
1. 用户打开应用
   ↓
2. 后台静默检查更新（2-3秒）
   ↓
3. 发现新版本
   ↓
4. 显示更新对话框
   ┌───────────────────────────┐
   │ 🔄 发现新版本              │
   │                           │
   │ 最新版本: 1.5.0           │
   │                           │
   │ 更新内容:                  │
   │ • 修复扫码问题             │
   │ • 优化性能                 │
   │                           │
   │ 文件大小: 52.4 MB         │
   │                           │
   │ [稍后]    [立即更新]      │
   └───────────────────────────┘
   ↓
5. 用户点击"立即更新"
   ↓
6. 显示下载进度
   ┌───────────────────────────┐
   │ 🔄 正在下载更新...         │
   │                           │
   │       ⭕ 65%              │
   │                           │
   │ 34.1 MB / 52.4 MB        │
   │                           │
   │ 正在下载更新，请稍候...     │
   │                           │
   │        [取消]             │
   └───────────────────────────┘
   ↓
7. 下载完成，自动弹出安装界面
   ↓
8. 用户确认安装
   ↓
9. 安装完成，重启应用
```

### 手动检查更新

```
1. 点击右上角"操作员001"头像
2. 在应用信息对话框中点击"检查更新"
3. 显示检查结果:
   - 有新版本 → 显示更新对话框
   - 无新版本 → 显示"当前已是最新版本"提示
   - 检查失败 → 静默失败（不打扰用户）
```

---

## 配置说明

### version.json 配置详解

```json
{
  "versionCode": 40,              // 版本号（整数，必须递增）
  "versionName": "1.5.0",         // 版本名称（显示用）
  "downloadUrl": "http://192.168.1.100/warehouse-app-v1.5.0-build40.apk",
  "updateLog": "• 修复扫码异常\n• 优化网络性能\n• 更新UI显示",
  "forceUpdate": false,           // true=强制更新，false=可选更新
  "minSupportedVersion": 30,      // 最低支持版本（低于此版本强制更新）
  "fileSize": 52428800,           // APK文件大小（字节）
  "releaseDate": "2025-01-04",    // 发布日期（可选）
  "md5": "a1b2c3..."              // MD5校验（可选，暂未实现）
}
```

### 应用配置选项

`lib/core/config/app_config.dart`:

```dart
/// 更新服务器URL
static const String updateServerUrl = 'http://192.168.1.100';

/// 是否启用自动更新（总开关）
static const bool enableAutoUpdate = true;

/// 启动时是否检查更新
static const bool checkUpdateOnStartup = true;

/// 是否在WiFi下自动下载（暂未实现）
static const bool autoDownloadOnWifi = false;

/// 更新检查间隔（小时，暂未实现）
static const int updateCheckIntervalHours = 24;
```

---

## 故障排查

### 问题1: 启动时不检查更新

**可能原因:**
- `AppConfig.enableAutoUpdate = false`
- `AppConfig.checkUpdateOnStartup = false`
- 网络连接问题

**解决方案:**
```dart
// 1. 检查配置
lib/core/config/app_config.dart

// 2. 手动触发检查
点击用户头像 → 检查更新
```

### 问题2: 提示"无法连接到更新服务器"

**可能原因:**
- 服务器IP配置错误
- HFS未运行
- 防火墙阻止访问
- PDA与服务器不在同一网段

**诊断步骤:**
```bash
# 1. 确认服务器IP
在服务器上运行: ipconfig
记录IP地址: 192.168.1.XXX

# 2. 检查HFS是否运行
在服务器浏览器访问: http://localhost

# 3. PDA端测试
在PDA浏览器访问: http://服务器IP/version.json
应该能看到JSON内容

# 4. 检查防火墙
Windows防火墙 → 允许应用 → HFS
```

### 问题3: 下载很慢或失败

**可能原因:**
- WiFi信号弱
- 服务器网络负载高
- APK文件过大

**优化建议:**
```
1. 检查WiFi信号强度（至少3格）
2. 减小APK大小:
   flutter build apk --release --split-per-abi
3. 增加HFS并发连接数:
   HFS → Options → Max connections: 100
```

### 问题4: 下载完成但未弹出安装

**可能原因:**
- 缺少`REQUEST_INSTALL_PACKAGES`权限
- Android版本兼容性问题

**解决方案:**
```xml
<!-- 检查 AndroidManifest.xml -->
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

首次安装时，系统会提示授权"安装未知应用"，必须允许。

### 问题5: 显示"检查更新失败"

**调试步骤:**
```bash
# 1. 查看应用日志
adb logcat | grep -i "update"

# 2. 检查version.json格式
在浏览器访问: http://服务器IP/version.json
确保JSON格式正确，无语法错误

# 3. 测试Dio请求
在应用中手动检查更新，观察错误信息
```

---

## 常见问题

### Q1: 如何实现强制更新？

**A:** 修改 `version.json`:
```json
{
  "forceUpdate": true,  // 改为true
  ...
}
```

强制更新时:
- 用户无法点击"稍后"按钮
- 对话框无法关闭（点击外部无效）
- 必须更新才能继续使用

### Q2: 如何回退到旧版本？

**A:**
```bash
# 方式1: 修改version.json指向旧版本
{
  "versionCode": 39,  // 降低版本号
  "versionName": "1.4.5",
  "downloadUrl": "http://192.168.1.100/warehouse-app-v1.4.5-build39.apk",
  ...
}

# 方式2: 直接安装旧APK
adb install -r releases/warehouse-app-v1.4.5-build39.apk
```

**注意:** 降级可能导致数据兼容性问题。

### Q3: 能否跳过某些版本？

**A:** 是的，版本比较只看`versionCode`:
```
当前版本: 35
服务器版本: 40
结果: 提示更新到40（自动跳过36-39）
```

### Q4: 如何禁用自动更新？

**A:** 修改 `lib/core/config/app_config.dart`:
```dart
static const bool enableAutoUpdate = false;  // 完全禁用
// 或
static const bool checkUpdateOnStartup = false;  // 仅禁用启动检查
```

重新构建应用生效。

### Q5: 更新后数据会丢失吗？

**A:** 不会。应用更新是覆盖安装，保留以下数据:
- ✅ 用户登录状态（Secure Storage）
- ✅ 应用配置
- ✅ 本地缓存

**前提:** APK签名一致（使用同一密钥签名）。

### Q6: 可以支持HTTPS吗？

**A:** 可以，但需要额外配置:
```
1. 为HFS配置SSL证书
2. 修改 AppConfig.updateServerUrl 为 https://
3. 如使用自签名证书，需在应用中信任该证书
```

内网环境HTTP已足够安全。

### Q7: 如何监控更新使用情况？

**A:** HFS提供访问日志:
```
HFS → Menu → Log → Show log

可以看到:
- 下载IP地址
- 下载时间
- 文件名
- 下载是否完成
```

### Q8: 支持差分更新吗？

**A:** 当前版本不支持。每次更新下载完整APK（约50-100MB）。

内网100Mbps WiFi环境下，下载时间约8-10秒，可接受。

---

## 版本发布清单

发布新版本前请确认:

- [ ] 更新 `pubspec.yaml` 版本号
- [ ] 更新UI显示版本号（可选）
- [ ] 运行测试确保无错误
- [ ] 构建Release APK
- [ ] 运行 `update_version.bat` 生成配置
- [ ] 检查 `version.json` 内容正确
- [ ] APK文件名符合规范
- [ ] 复制到服务器releases目录
- [ ] 测试从PDA访问version.json
- [ ] 在测试设备验证更新流程
- [ ] 通知用户有新版本可用

---

## 技术支持

遇到问题请检查:
1. 本文档"故障排查"部分
2. [docs/SERVER_SETUP.md](./SERVER_SETUP.md) 服务器配置
3. 应用日志: `adb logcat`
4. HFS访问日志

---

**版本:** 1.0
**更新日期:** 2025-01-04
**适用应用版本:** 1.4.5+
