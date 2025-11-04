# 应用自动更新系统

仓库应用的自动更新功能已成功集成，本文档提供快速入门指南。

---

## 🎯 功能特性

- ✅ **自动检查**: 应用启动时自动检查服务器版本
- ✅ **在线更新**: WiFi环境下从内网服务器下载更新
- ✅ **进度显示**: 实时显示下载百分比和文件大小
- ✅ **安全安装**: 下载完成自动调用系统安装器
- ✅ **强制更新**: 支持配置强制更新模式
- ✅ **手动检查**: 用户可在设置中手动检查更新

---

## 📚 文档导航

### 1. [服务器配置指南](./SERVER_SETUP.md)
如何在Windows服务器上配置HFS文件服务器
- **适用于**: IT管理员、运维人员
- **耗时**: 约10分钟
- **内容**: HFS安装、目录配置、防火墙设置、故障排查

### 2. [完整使用指南](./AUTO_UPDATE_GUIDE.md)
日常使用、版本发布、用户体验、故障排查
- **适用于**: 开发人员、测试人员、运维人员
- **内容**:
  - 首次部署步骤
  - 版本发布流程（自动化脚本）
  - 用户体验说明
  - 常见问题解答
  - 故障排查指南

---

## 🚀 快速开始

### 对于 IT 管理员

**1. 配置服务器（5分钟）**
```bash
# 详见 docs/SERVER_SETUP.md

1. 下载 HFS: https://www.rejetto.com/hfs/
2. 运行 hfs.exe
3. 添加 releases 目录
4. 测试访问: http://服务器IP/version.json
```

**2. 配置应用服务器地址**
```dart
// lib/core/config/app_config.dart
static const String updateServerUrl = 'http://192.168.1.100'; // 改为实际IP
```

**3. 重新构建并分发应用**
```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 对于开发人员

**发布新版本（一键完成）**
```bash
# 1. 更新版本号
编辑 pubspec.yaml: version: 1.5.0+40

# 2. 运行自动化脚本
cd scripts
deploy_release.bat

# 3. 上传到服务器
将 releases/ 目录复制到Windows服务器
```

脚本自动完成:
- ✅ 清理构建
- ✅ 构建Release APK
- ✅ 生成version.json配置
- ✅ 重命名文件为标准格式

### 对于用户

**检查更新**
```
1. 打开仓库应用
2. 点击右上角用户头像
3. 点击"检查更新"按钮
4. 如有新版本，点击"立即更新"
5. 等待下载完成（约10秒）
6. 确认安装
```

---

## 📁 项目结构

```
lib/
├── core/
│   └── config/
│       └── app_config.dart                 # 服务器URL配置
└── features/
    └── app_update/
        ├── data/
        │   ├── models/
        │   │   └── update_info_model.dart  # 版本信息模型
        │   └── repositories/
        │       └── update_repository_impl.dart  # 更新仓库实现
        ├── domain/
        │   ├── entities/
        │   │   └── update_info.dart        # 版本信息实体
        │   └── repositories/
        │       └── update_repository.dart  # 更新仓库接口
        └── presentation/
            ├── bloc/
            │   ├── update_bloc.dart        # 更新状态管理
            │   ├── update_event.dart       # 更新事件
            │   └── update_state.dart       # 更新状态
            └── widgets/
                └── update_dialog.dart      # 更新对话框

scripts/
├── update_version.bat          # 配置工具：生成version.json
└── deploy_release.bat          # 一键发布工具

releases/
├── version.json                # 版本配置文件
├── warehouse-app-v1.5.0-build40.apk  # 最新版本
└── warehouse-app-v1.4.5-build39.apk  # 历史版本

docs/
├── SERVER_SETUP.md             # 服务器配置详细指南
├── AUTO_UPDATE_GUIDE.md        # 完整使用指南
└── AUTO_UPDATE_README.md       # 本文档（快速入门）
```

---

## 🔧 技术实现

### 架构模式
- **Clean Architecture**: 分层架构，解耦业务逻辑
- **BLoC Pattern**: 状态管理使用flutter_bloc
- **Repository Pattern**: 抽象数据访问层

### 核心依赖
```yaml
dependencies:
  r_upgrade: ^0.4.0           # APK下载和安装
  package_info_plus: ^5.0.0   # 获取应用版本信息
  dio: ^5.0.0                 # HTTP请求（已有）
  path_provider: ^2.1.0       # 文件路径管理
```

### 关键流程

**1. 版本检查**
```dart
// UpdateRepositoryImpl
Future<Either<Failure, UpdateInfo?>> checkForUpdate() async {
  // 1. 请求服务器 version.json
  final response = await dio.get('$updateServerUrl/version.json');

  // 2. 解析服务器版本
  final serverVersion = UpdateInfoModel.fromJson(response.data);

  // 3. 获取当前版本
  final packageInfo = await PackageInfo.fromPlatform();
  final currentVersion = int.parse(packageInfo.buildNumber);

  // 4. 比较版本号
  if (serverVersion.versionCode > currentVersion) {
    return Right(serverVersion);  // 有新版本
  }
  return const Right(null);  // 无更新
}
```

**2. 下载安装**
```dart
// UpdateRepositoryImpl
Future<Either<Failure, bool>> downloadAndInstall(String downloadUrl) async {
  _downloadId = await RUpgrade.upgrade(
    downloadUrl,
    fileName: 'warehouse_app_update.apk',
    isAutoRequestInstall: true,  // 下载完自动安装
    notificationVisibility: VISIBILITY_VISIBLE,
  );

  return const Right(true);
}
```

**3. 状态管理**
```dart
// UpdateBloc
on<CheckUpdateRequested>((event, emit) async {
  emit(UpdateChecking());

  final result = await updateRepository.checkForUpdate();

  result.fold(
    (failure) => emit(UpdateFailure(failure.message)),
    (updateInfo) => updateInfo != null
        ? emit(UpdateAvailable(updateInfo))
        : emit(UpdateNotAvailable()),
  );
});
```

---

## ⚙️ 配置选项

### 服务器配置

`releases/version.json`:
```json
{
  "versionCode": 40,                    // 版本号（必须递增）
  "versionName": "1.5.0",               // 显示版本
  "downloadUrl": "http://...",          // APK下载地址
  "updateLog": "• 更新说明",            // 更新日志
  "forceUpdate": false,                 // 是否强制更新
  "minSupportedVersion": 30,            // 最低支持版本
  "fileSize": 52428800                  // 文件大小
}
```

### 应用配置

`lib/core/config/app_config.dart`:
```dart
static const String updateServerUrl = 'http://192.168.1.100';
static const bool enableAutoUpdate = true;
static const bool checkUpdateOnStartup = true;
```

---

## ✅ 测试清单

部署前请验证:

### 服务器端
- [ ] HFS正常运行
- [ ] `version.json`可访问: `http://服务器IP/version.json`
- [ ] APK文件可下载: `http://服务器IP/xxx.apk`
- [ ] 防火墙已配置允许HFS端口

### 应用端
- [ ] `AppConfig.updateServerUrl`已配置正确IP
- [ ] 启动时能检查到更新（或显示已是最新）
- [ ] 手动检查更新功能正常
- [ ] 下载进度显示正常
- [ ] 下载完成自动弹出安装
- [ ] 安装后版本号正确

### 测试场景
- [ ] 场景1: 当前最新版本 → 显示"当前已是最新版本"
- [ ] 场景2: 有新版本（可选更新）→ 显示对话框，可稍后
- [ ] 场景3: 有新版本（强制更新）→ 显示对话框，无法关闭
- [ ] 场景4: 服务器不可达 → 静默失败，不打扰用户
- [ ] 场景5: 下载中断 → 可取消，可重试

---

## 🆘 获取帮助

### 常见问题
详见 [docs/AUTO_UPDATE_GUIDE.md](./AUTO_UPDATE_GUIDE.md) 的"常见问题"章节

### 故障排查
详见 [docs/AUTO_UPDATE_GUIDE.md](./AUTO_UPDATE_GUIDE.md) 的"故障排查"章节

### 调试命令
```bash
# 查看应用日志
adb logcat | grep -i "update"

# 查看应用版本
adb shell dumpsys package com.example.picking_verification_app | grep versionName

# 测试网络连接
在PDA浏览器访问: http://服务器IP/version.json

# 重新安装应用
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 📈 未来改进

可选的增强功能:

- [ ] 差分更新（减小下载量）
- [ ] 后台静默下载（WiFi环境）
- [ ] 定时检查更新（每24小时）
- [ ] 版本更新统计（下载次数、成功率）
- [ ] 更新失败重试机制
- [ ] MD5校验（防篡改）
- [ ] HTTPS支持（高安全需求）

---

## 📄 许可证

本功能是仓库应用的一部分，遵循项目整体许可证。

---

## 👥 贡献者

- **开发**: Claude Code (AI助手)
- **需求**: 仓库应用团队
- **测试**: 待补充

---

**最后更新**: 2025-01-04
**文档版本**: 1.0
**适用应用版本**: 1.4.5+

需要帮助？请先查阅 [完整使用指南](./AUTO_UPDATE_GUIDE.md)
