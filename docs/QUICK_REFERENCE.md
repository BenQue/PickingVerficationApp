# 自动更新功能快速参考

---

## 🔧 首次配置

### 1. 服务器端（5分钟）
```bash
1. 下载HFS: https://www.rejetto.com/hfs/
2. 运行hfs.exe
3. 右键 → Add folder → 选择 releases/
4. 测试: http://192.168.1.100/version.json
```

### 2. 应用端（1分钟）
```dart
// lib/core/config/app_config.dart
static const String updateServerUrl = 'http://192.168.1.100'; // 改为实际IP
```

---

## 📦 发布新版本

### 自动化方式（推荐）
```bash
cd scripts
deploy_release.bat

# 然后复制 releases/ 到服务器
```

### 手动方式
```bash
# 1. 更新版本号
编辑 pubspec.yaml: version: 1.5.0+40

# 2. 构建APK
flutter build apk --release

# 3. 生成配置
cd scripts
update_version.bat

# 4. 上传到服务器
复制 releases/ 到服务器
```

---

## 📂 关键文件

| 文件 | 说明 | 位置 |
|------|------|------|
| `version.json` | 版本配置 | `releases/version.json` |
| `app_config.dart` | 服务器URL | `lib/core/config/app_config.dart` |
| `update_version.bat` | 配置工具 | `scripts/update_version.bat` |
| `deploy_release.bat` | 发布工具 | `scripts/deploy_release.bat` |

---

## 🔍 常用命令

```bash
# 检查应用版本
adb shell dumpsys package com.example.picking_verification_app | grep versionName

# 安装APK
adb install -r build/app/outputs/flutter-apk/app-release.apk

# 查看更新日志
adb logcat | grep -i "update"

# 测试服务器访问
curl http://192.168.1.100/version.json
```

---

## ⚡ 快速排查

| 问题 | 检查 | 解决 |
|------|------|------|
| 不检查更新 | `AppConfig.enableAutoUpdate` | 设为 `true` |
| 无法连接服务器 | 服务器IP、HFS运行状态 | 检查IP配置和HFS |
| 下载失败 | WiFi信号、防火墙 | 增强信号、开放端口 |
| 未弹安装 | 权限设置 | 授予"安装未知应用"权限 |

---

## 📞 获取帮助

- **服务器配置**: [docs/SERVER_SETUP.md](./SERVER_SETUP.md)
- **完整指南**: [docs/AUTO_UPDATE_GUIDE.md](./AUTO_UPDATE_GUIDE.md)
- **系统总览**: [docs/AUTO_UPDATE_README.md](./AUTO_UPDATE_README.md)

---

## version.json 模板

```json
{
  "versionCode": 40,
  "versionName": "1.5.0",
  "downloadUrl": "http://192.168.1.100/warehouse-app-v1.5.0-build40.apk",
  "updateLog": "• 更新内容1\n• 更新内容2",
  "forceUpdate": false,
  "minSupportedVersion": 30,
  "fileSize": 52428800,
  "releaseDate": "2025-01-04"
}
```

---

**版本**: 1.0 | **更新**: 2025-01-04
