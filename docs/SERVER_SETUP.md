# Windows 服务器配置指南

本文档说明如何在公司内网Windows服务器上配置应用自动更新服务。

## 📋 准备工作

### 1. 下载HFS (HTTP File Server)

1. 访问官网: https://www.rejetto.com/hfs/
2. 下载最新版本 (推荐 HFS 2.3m 或更高版本)
3. 解压到服务器任意目录，例如: `C:\HFS\`

**注意**: HFS是免费开源软件，无需安装，解压即用。

### 2. 确认服务器信息

- 服务器内网IP地址: `____________________` (请填写)
- 端口号: `80` (默认) 或 `8080` (如果80端口被占用)

---

## 🚀 快速配置步骤 (5分钟)

### 步骤1: 启动HFS

1. 双击运行 `hfs.exe`
2. 首次运行会弹出配置向导，选择"简单配置"即可

### 步骤2: 添加更新文件目录

1. 将项目的 `releases` 目录复制到服务器
   - 建议路径: `C:\warehouse-app\releases\`

2. 在HFS界面中:
   - 在左侧空白区域 **右键点击**
   - 选择 **"Add folder"** (添加文件夹)
   - 浏览选择 `C:\warehouse-app\releases\`
   - 点击确定

3. 目录添加后会显示为 `releases`，右键点击目录:
   - 选择 **"Set alias"** (设置别名)
   - 删除原有名称，留空（这样访问路径更简洁）
   - 点击确定

### 步骤3: 配置端口和权限

1. 点击菜单栏 **"Menu"** → **"Options"** (选项)

2. 在弹出窗口中配置:
   ```
   【Network】网络设置
   - Port: 80 (如果被占用，改为8080)
   - Max connections: 50 (最大连接数)

   【Limits】限制设置
   - Max simultaneous downloads: 20 (同时下载数)
   - Speed limit: 无限制 (内网环境无需限制)

   【Security】安全设置
   - Enable password protection: 否 (内网环境可不设密码)
   ```

3. 点击 **"OK"** 保存配置

### 步骤4: 测试访问

1. 在HFS界面查看显示的服务器地址，例如:
   ```
   http://192.168.1.100
   ```

2. 在另一台电脑浏览器中访问:
   ```
   http://192.168.1.100/version.json
   ```

3. 应该能看到JSON配置内容，例如:
   ```json
   {
     "versionCode": 39,
     "versionName": "1.4.5",
     ...
   }
   ```

4. 测试APK下载:
   ```
   http://192.168.1.100/warehouse-app-v1.4.5-build39.apk
   ```

### 步骤5: 设置开机自启 (可选)

1. 创建HFS快捷方式:
   - 右键点击 `hfs.exe` → 发送到 → 桌面快捷方式

2. 将快捷方式移动到启动文件夹:
   - 按 `Win + R`，输入: `shell:startup`
   - 将快捷方式复制到打开的文件夹中

3. 重启服务器测试HFS是否自动启动

---

## 📁 目录结构

服务器上的文件结构应如下:

```
C:\warehouse-app\
└── releases\
    ├── version.json                          # 版本配置文件 (必需)
    ├── warehouse-app-v1.4.5-build39.apk     # 当前版本APK
    ├── warehouse-app-v1.5.0-build40.apk     # 新版本APK
    └── RELEASE_NOTES_v1.5.0.md              # 版本说明 (可选)
```

**重要提示**:
- `version.json` 必须存在且内容正确
- APK文件名必须与 `version.json` 中的 `downloadUrl` 一致
- 建议保留最近2-3个版本的APK以便回退

---

## 🔄 发布新版本流程

### 方式A: 使用自动化脚本 (推荐)

1. 在开发机上运行:
   ```bash
   cd scripts
   deploy_release.bat
   ```

2. 按提示操作，脚本会自动:
   - 构建Release APK
   - 更新version.json
   - 生成规范的文件名

3. 将 `releases` 目录复制到服务器:
   ```
   复制: 开发机 releases\
   粘贴到: 服务器 C:\warehouse-app\releases\
   ```

4. HFS会自动检测到新文件，无需重启

### 方式B: 手动发布

1. 在开发机构建APK:
   ```bash
   flutter build apk --release
   ```

2. 复制APK到releases目录并重命名:
   ```
   从: build\app\outputs\flutter-apk\app-release.apk
   到: releases\warehouse-app-v1.5.0-build40.apk
   ```

3. 运行配置工具更新version.json:
   ```bash
   cd scripts
   update_version.bat
   ```

4. 复制releases目录到服务器

---

## 🔍 故障排查

### 问题1: PDA设备无法访问服务器

**检查清单:**
- [ ] 服务器和PDA在同一内网网段
- [ ] Windows防火墙是否允许HFS端口 (80/8080)
- [ ] HFS是否正常运行
- [ ] 使用PDA浏览器测试: `http://服务器IP/version.json`

**解决方案:**
```cmd
# 临时关闭防火墙测试 (仅用于测试!)
netsh advfirewall set allprofiles state off

# 或添加防火墙规则 (推荐)
netsh advfirewall firewall add rule name="HFS" dir=in action=allow protocol=TCP localport=80
```

### 问题2: version.json下载成功但内容不正确

**原因**: 可能是编码问题或缓存

**解决方案:**
1. 确保version.json使用UTF-8编码保存
2. 在HFS中右键目录 → Refresh (刷新)
3. 清除PDA设备浏览器缓存

### 问题3: APK下载速度慢

**检查清单:**
- [ ] WiFi信号强度
- [ ] 服务器网络负载
- [ ] HFS连接数限制设置

**优化方案:**
- 增加HFS最大连接数: Options → Limits → Max connections: 100
- 检查服务器网卡是否千兆
- 使用有线连接测试网络速度

### 问题4: 80端口被占用

**检测端口占用:**
```cmd
netstat -ano | findstr :80
```

**解决方案:**
1. 更改HFS端口为8080:
   - Menu → Options → Port: 8080

2. 同时更新 `version.json` 中的 `downloadUrl`:
   ```json
   "downloadUrl": "http://192.168.1.100:8080/warehouse-app-vX.X.X-buildXX.apk"
   ```

3. 重启HFS

---

## 🔐 安全建议

虽然是内网环境,仍建议考虑以下安全措施:

### 1. IP访问限制 (可选)

在HFS中设置仅允许特定IP段访问:
```
Menu → IP address → Ban list
添加规则: !192.168.1.*  (仅允许192.168.1.x网段)
```

### 2. 文件完整性校验 (推荐)

为APK生成MD5校验值:
```bash
certutil -hashfile warehouse-app-v1.5.0-build40.apk MD5
```

将MD5值添加到version.json:
```json
{
  "md5": "a1b2c3d4e5f6..."
}
```

### 3. HTTPS加密 (高安全需求)

如果需要HTTPS:
1. 为HFS配置SSL证书
2. 更新downloadUrl为https://
3. 需要有效的SSL证书(可使用自签名证书)

---

## 📊 监控和维护

### 查看访问日志

HFS会记录所有访问:
- Menu → Log → Show log
- 可以看到下载记录、访问IP等信息

### 磁盘空间管理

建议定期清理旧版本APK:
- 保留最近3个版本
- 删除超过30天的旧版本
- 每个APK约50-100MB

### 定期备份

建议备份以下内容:
- `releases\` 目录 (所有APK和配置)
- HFS配置文件 (hfs.ini)

---

## 📞 技术支持

如遇到问题,请检查:
1. 本文档的"故障排查"部分
2. HFS官方文档: https://www.rejetto.com/wiki/
3. 联系IT管理员协助配置防火墙和网络

---

## ✅ 配置完成检查清单

部署前请确认:

- [ ] HFS已安装并运行
- [ ] releases目录已添加到HFS
- [ ] version.json文件存在且内容正确
- [ ] 至少有一个APK文件在releases目录
- [ ] 能从其他设备访问 `http://服务器IP/version.json`
- [ ] 能从其他设备下载APK文件
- [ ] 防火墙已配置允许HFS端口
- [ ] (可选) 已设置HFS开机自启
- [ ] 已记录服务器IP地址并告知开发团队

配置完成后,请将服务器IP地址更新到:
- `lib/core/config/app_config.dart` (Flutter应用配置)
- 通知所有相关人员

**恭喜! 服务器配置完成,可以开始配置Flutter客户端了。**
