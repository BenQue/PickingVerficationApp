# 自动更新调试指南

## 🐛 问题修复记录

### 问题 1: 下载完成后显示"下载失败"

**原因分析：**
1. ~~存储路径权限问题~~
2. **FileProvider authority 名称不匹配** ✓

**修复方案：**
- 修改 MainActivity.kt 中的 FileProvider authority
  - 错误：`.fileprovider` (小写)
  - 正确：`.fileProvider` (大写 P)
- 改用外部存储目录 `getExternalStorageDirectory()`
- 添加详细的调试日志

**修复版本：** v1.5.1-build41 (2025-11-04 更新)

## 📱 实时查看更新日志

### 方法 1: 使用 ADB Logcat（推荐）

```bash
# 清除旧日志并实时查看更新相关日志
adb logcat -c && adb logcat | grep -E "(APK|下载|更新|install)"
```

### 方法 2: 查看完整 Flutter 日志

```bash
# 查看所有 Flutter 日志
adb logcat | grep flutter
```

### 方法 3: 过滤特定关键词

```bash
# 只看更新相关的关键信息
adb logcat | grep -E "(开始下载|下载进度|APK文件已下载|调用安装|安装界面已打开)"
```

## 🔍 调试输出说明

成功的更新流程应该看到以下日志：

```
1. APK 保存路径: /storage/emulated/0/Android/data/.../warehouse_app_update.apk
2. 开始下载: http://10.163.130.173:8000/warehouse-app-v1.5.1-build41.apk
3. 下载进度: 10.5%
4. 下载进度: 25.3%
5. 下载进度: 50.7%
6. 下载进度: 75.2%
7. 下载进度: 100.0%
8. APK文件已下载，大小: 81788928 bytes
9. 调用安装: /storage/emulated/0/Android/data/.../warehouse_app_update.apk
10. 安装界面已打开
```

## ⚠️ 常见错误信息

### 错误 1: "无法获取存储目录"
```
错误信息: 无法获取存储目录
原因: 存储权限未授予
解决: 检查应用是否有存储权限
```

### 错误 2: "APK文件下载失败：文件不存在"
```
错误信息: APK文件下载失败：文件不存在
原因: 下载过程中断或失败
解决: 检查网络连接，查看详细日志
```

### 错误 3: "APK文件下载失败：文件大小为0"
```
错误信息: APK文件下载失败：文件大小为0
原因: 服务器返回空文件
解决: 检查服务器上的 APK 文件是否正常
```

### 错误 4: "打开APK文件失败"
```
错误信息: 打开APK文件失败
原因: FileProvider 配置问题或权限不足
解决: 检查 FileProvider authority 是否匹配
```

### 错误 5: "下载超时，请检查网络连接"
```
错误信息: 下载超时，请检查网络连接
原因: 网络速度慢或不稳定
解决: 检查 WiFi 信号，重试下载
```

## 🧪 测试步骤

### 完整测试流程

1. **准备测试环境**
   ```bash
   # 确保设备已连接
   adb devices

   # 清除日志
   adb logcat -c
   ```

2. **启动日志监控**
   ```bash
   # 在新终端窗口中运行
   adb logcat | grep -E "(APK|下载|更新|install)" > update_test.log
   ```

3. **执行更新测试**
   - 在 PDA 上打开应用
   - 等待自动更新提示
   - 点击"立即更新"
   - 观察控制台输出

4. **检查日志文件**
   ```bash
   # 查看完整日志
   cat update_test.log
   ```

### 快速测试命令

```bash
# 一键测试（连接设备后运行）
adb logcat -c && echo "开始监控更新日志..." && adb logcat | grep -E "(APK|下载|更新|install|Error|Exception)"
```

## 📊 性能指标

### 预期性能

| 指标 | WiFi (100Mbps) | WiFi (50Mbps) | WiFi (20Mbps) |
|------|----------------|---------------|---------------|
| 下载时间 | 6-8 秒 | 12-15 秒 | 30-35 秒 |
| 安装耗时 | < 10 秒 | < 10 秒 | < 10 秒 |
| 总耗时 | < 20 秒 | < 30 秒 | < 50 秒 |

### 监控命令

```bash
# 监控下载速度
adb logcat | grep "下载进度" | while read line; do
    echo "$(date '+%H:%M:%S') - $line"
done
```

## 🔧 高级调试

### 查看具体错误堆栈

```bash
# 查看 Flutter 异常详情
adb logcat -v time | grep -A 20 "Exception"
```

### 检查文件系统

```bash
# 查看 APK 文件是否成功下载
adb shell ls -lh /storage/emulated/0/Android/data/com.example.picking_verification_app/files/
```

### 手动测试 APK 安装

```bash
# 从设备提取 APK 并手动安装
adb pull /storage/emulated/0/Android/data/com.example.picking_verification_app/files/warehouse_app_update.apk
adb install -r warehouse_app_update.apk
```

## 📝 问题报告模板

如果遇到问题，请收集以下信息：

```
问题描述：
__________

复现步骤：
1.
2.
3.

设备信息：
- 型号：
- Android 版本：
- 应用版本：

网络环境：
- WiFi 信号强度：
- 网络速度：

日志输出：
```
[粘贴 adb logcat 相关输出]
```

错误截图：
[如果有的话]
```

## ✅ 成功标志

更新成功后应该看到：

1. ✅ 控制台输出："APK文件已下载，大小: 81788928 bytes"
2. ✅ 控制台输出："安装界面已打开"
3. ✅ Android 安装界面自动弹出
4. ✅ 显示应用名称和版本号 1.5.1
5. ✅ 可以成功点击"安装"
6. ✅ 安装完成后版本号更新为 V1.5.1

---

**提示：** 保持 adb logcat 窗口打开，可以实时看到更新过程的所有细节！
