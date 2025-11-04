# ✅ 配置完成确认

## 已完成的配置

### 1. Flutter依赖安装 ✅

```bash
✅ r_upgrade: ^0.4.2 (已安装)
✅ package_info_plus: ^8.3.1 (已安装，升级版本以解决依赖冲突)
✅ path_provider: ^2.1.5 (已安装)
```

**依赖状态**: 所有依赖已成功安装，无冲突

### 2. 服务器配置 ✅

**服务器信息**:
- **IP地址**: `10.163.130.173`
- **端口**: `8000` (因80端口被占用)
- **完整URL**: `http://10.163.130.173:8000`

**已配置文件**:
- ✅ `lib/core/config/app_config.dart` - 更新服务器URL已设置
- ✅ `releases/version.json` - 下载URL已更新为服务器地址

---

## 下一步操作

### 步骤1: 配置Windows服务器HFS（重要！）

由于使用8000端口，需要在HFS配置中指定端口：

1. **下载并运行HFS**
   - 下载: https://www.rejetto.com/hfs/
   - 运行 `hfs.exe`

2. **配置端口为8000**
   ```
   Menu → Options → Port: 8000
   ```

3. **添加releases目录**
   ```
   右键空白区域 → Add folder → 选择项目的 releases/ 目录
   右键 releases → Set alias → 留空（删除默认名称）
   ```

4. **配置防火墙**
   ```cmd
   # 在Windows服务器上运行
   netsh advfirewall firewall add rule name="HFS8000" dir=in action=allow protocol=TCP localport=8000
   ```

5. **测试访问**
   ```
   在PDA浏览器访问: http://10.163.130.173:8000/version.json
   应该能看到JSON内容
   ```

### 步骤2: 构建应用

```bash
# 清理构建
flutter clean

# 构建Release APK
flutter build apk --release

# APK位置
build/app/outputs/flutter-apk/app-release.apk
```

### 步骤3: 安装到PDA测试

```bash
# 连接PDA设备
adb devices

# 安装应用
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### 步骤4: 测试更新功能

1. 打开应用
2. 点击右上角"操作员001"头像
3. 点击"检查更新"按钮
4. 应该显示以下之一：
   - "当前已是最新版本"（如果服务器未配置）
   - "无法连接到更新服务器"（如果服务器未启动）
   - 更新对话框（如果服务器配置正确且有新版本）

---

## 服务器配置检查清单

在服务器上完成以下配置：

- [ ] HFS已下载并运行
- [ ] HFS端口设置为8000
- [ ] releases目录已添加到HFS
- [ ] 防火墙已开放8000端口
- [ ] 能从其他设备访问 `http://10.163.130.173:8000`
- [ ] 能访问 `http://10.163.130.173:8000/version.json`
- [ ] version.json返回正确的JSON内容

---

## 配置文件位置

| 配置项 | 文件路径 | 当前值 |
|--------|---------|--------|
| 服务器URL | `lib/core/config/app_config.dart` | `http://10.163.130.173:8000` |
| 版本配置 | `releases/version.json` | 下载URL已更新 |
| 应用版本 | `pubspec.yaml` | `1.4.5+39` |

---

## 快速测试命令

### 测试服务器连接（在PDA或开发机）
```bash
# 使用curl测试
curl http://10.163.130.173:8000/version.json

# 预期输出：
# {
#   "versionCode": 39,
#   "versionName": "1.4.5",
#   "downloadUrl": "http://10.163.130.173:8000/warehouse-app-v1.4.5-build39.apk",
#   ...
# }
```

### 测试APK下载（在PDA或开发机）
```bash
# 测试APK是否可下载
curl -I http://10.163.130.173:8000/warehouse-app-v1.4.5-build39.apk

# 预期输出：
# HTTP/1.1 200 OK
# Content-Length: xxx
# Content-Type: application/vnd.android.package-archive
```

---

## 故障排查

### 问题1: 无法连接到更新服务器

**检查项**:
1. HFS是否在服务器上运行？
2. HFS端口是否设置为8000？
3. 防火墙是否开放8000端口？
4. PDA和服务器是否在同一内网？

**解决方案**:
```cmd
# 在服务器上检查HFS是否运行
tasklist | find "hfs"

# 检查8000端口是否被占用
netstat -ano | findstr :8000

# 临时关闭防火墙测试（仅用于测试！）
netsh advfirewall set allprofiles state off
```

### 问题2: version.json访问404

**检查项**:
1. releases目录是否已添加到HFS？
2. version.json文件是否在releases目录中？
3. HFS别名设置是否正确（应该为空）？

**解决方案**:
在HFS中右键releases → Set alias → 确保留空

### 问题3: 依赖安装失败

**解决方案**:
```bash
# 清理并重试
flutter clean
rm -rf pubspec.lock
flutter pub get

# 如果仍然失败，使用国内镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get
```

---

## 重要提醒

### HFS端口配置
⚠️ **由于80端口被占用，所有URL都必须包含端口号`:8000`**

正确URL格式:
- ✅ `http://10.163.130.173:8000/version.json`
- ✅ `http://10.163.130.173:8000/warehouse-app-vX.X.X-buildXX.apk`

错误URL格式:
- ❌ `http://10.163.130.173/version.json` (缺少端口号)

### 发布新版本时
使用自动化脚本时，记得输入正确的服务器地址和端口：
```
服务器IP: 10.163.130.173:8000
```

---

## 参考文档

- [服务器详细配置](./SERVER_SETUP.md)
- [完整使用指南](./AUTO_UPDATE_GUIDE.md)
- [快速参考](./QUICK_REFERENCE.md)

---

**配置完成时间**: 2025-01-04
**服务器地址**: 10.163.130.173:8000
**应用版本**: 1.4.5+39
**状态**: ✅ Flutter端配置完成，待服务器端配置
