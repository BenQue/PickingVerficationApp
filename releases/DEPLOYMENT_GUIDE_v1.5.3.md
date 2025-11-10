# 部署指南 - v1.5.3

## 快速部署步骤

### 1. 准备工作

确保您有以下访问权限：
- 更新服务器 (10.163.130.173) 的 SSH 访问权限
- `/var/www/html/` 目录的写入权限
- 测试设备用于验证更新

### 2. 部署到更新服务器

#### 步骤 2.1: 上传 APK 文件

```bash
# 方式一：使用 SCP
scp releases/warehouse-app-v1.5.3-build43.apk user@10.163.130.173:/var/www/html/

# 方式二：使用 SFTP
sftp user@10.163.130.173
put releases/warehouse-app-v1.5.3-build43.apk /var/www/html/
quit
```

#### 步骤 2.2: 上传版本配置文件

```bash
# 上传 version.json
scp releases/version.json user@10.163.130.173:/var/www/html/
```

#### 步骤 2.3: 验证文件上传成功

```bash
# 检查 version.json
curl http://10.163.130.173:8000/version.json

# 预期输出:
# {
#   "versionCode": 43,
#   "versionName": "1.5.3",
#   "downloadUrl": "http://10.163.130.173:8000/warehouse-app-v1.5.3-build43.apk",
#   ...
# }

# 检查 APK 文件（仅检查头部）
curl -I http://10.163.130.173:8000/warehouse-app-v1.5.3-build43.apk

# 预期输出应包含:
# HTTP/1.1 200 OK
# Content-Length: 82191708
# Content-Type: application/vnd.android.package-archive
```

### 3. 测试自动更新流程

#### 步骤 3.1: 使用旧版本应用测试

1. 在测试设备上安装 v1.5.2 或更早版本
2. 打开应用
3. 应用应自动检测到新版本 v1.5.3
4. 验证更新对话框显示正确的更新日志

#### 步骤 3.2: 测试下载和安装

1. 点击"立即更新"按钮
2. 观察下载进度（应显示 78.4 MB）
3. 下载完成后，系统应提示安装
4. 安装后验证版本号为 V1.5.3

#### 步骤 3.3: 验证功能修复

1. 扫描一个无效的订单号
2. 验证错误消息显示为："扫码出错：未查询到订单信息"
3. 而不是："获取工单详情失败：HTTP 400"

### 4. 生产环境部署

#### 步骤 4.1: 部署时间建议

- **推荐时间**: 非工作高峰期（如中午休息时间或下班后）
- **避免时间**: 工作繁忙时段、月末盘点期间

#### 步骤 4.2: 通知用户

建议通过以下方式通知用户：
- 企业微信/钉钉群组通知
- 现场广播通知
- 班组长逐一告知

**通知模板**:
```
【系统更新通知】
仓库拣货验证App将于今日[时间]更新至v1.5.3版本。

主要改进：
• 修复错误信息显示问题，提供更清晰的错误提示
• 增强系统稳定性

更新方式：
打开应用即可自动检测更新，点击"立即更新"完成升级。
更新不影响现有数据，整个过程约需2-3分钟。

如有问题，请联系技术支持：[联系方式]
```

#### 步骤 4.3: 分批部署策略

**小规模试点（可选）**:
1. 选择 2-3 个测试用户先行更新
2. 观察 30 分钟，确认无异常
3. 再推广到全体用户

**全面部署**:
1. 上传文件到更新服务器
2. 用户打开应用时会自动检测更新
3. 用户可选择立即更新或稍后更新（不强制）

### 5. 部署后验证

#### 步骤 5.1: 监控更新率

使用以下命令查看服务器访问日志：
```bash
# 查看 version.json 的访问次数
ssh user@10.163.130.173 'grep "version.json" /var/log/nginx/access.log | tail -20'

# 查看 APK 的下载次数
ssh user@10.163.130.173 'grep "warehouse-app-v1.5.3-build43.apk" /var/log/nginx/access.log | wc -l'
```

#### 步骤 5.2: 用户反馈收集

关注以下方面：
- ✅ 更新流程是否顺畅
- ✅ 错误消息显示是否清晰
- ✅ 是否有新的问题出现
- ✅ 用户满意度

#### 步骤 5.3: 问题应对

如果发现严重问题：
1. 立即将 `version.json` 中的 `versionCode` 改回 42
2. 这将阻止新用户更新
3. 已更新用户可通过安装 v1.5.2 APK 回退
4. 调查问题原因并修复

### 6. 回滚计划

#### 紧急回滚步骤

如需回滚到 v1.5.2：

```bash
# 1. 恢复 version.json
scp releases/version.json.backup user@10.163.130.173:/var/www/html/version.json

# 2. 或者手动修改 versionCode
ssh user@10.163.130.173
echo '{"versionCode": 42, "versionName": "1.5.2", ...}' > /var/www/html/version.json

# 3. 验证
curl http://10.163.130.173:8000/version.json
```

对于已更新的设备：
```bash
# 安装旧版本 APK
adb install -r releases/warehouse-app-v1.5.2-build42.apk
```

### 7. 文档归档

确保以下文档已归档：
- ✅ [releases/RELEASE_NOTES_v1.5.3.md](RELEASE_NOTES_v1.5.3.md)
- ✅ [releases/INSTALL_SUMMARY_v1.5.3.txt](INSTALL_SUMMARY_v1.5.3.txt)
- ✅ [docs/BUG_FIX_HTTP_400_ERROR.md](../docs/BUG_FIX_HTTP_400_ERROR.md)
- ✅ [docs/QUICK_FIX_SUMMARY.md](../docs/QUICK_FIX_SUMMARY.md)

### 8. 后续跟踪

**第1周**:
- 每日检查更新率和用户反馈
- 记录任何异常情况

**第2-4周**:
- 每周汇总用户体验数据
- 收集改进建议

**第1个月后**:
- 评估修复效果
- 规划下一版本改进

---

## 快速参考

### 关键文件
- APK: `releases/warehouse-app-v1.5.3-build43.apk`
- 配置: `releases/version.json`
- MD5: `5eb2846bed22a99d3862fd6da11e0721`

### 关键URL
- 版本检查: `http://10.163.130.173:8000/version.json`
- APK 下载: `http://10.163.130.173:8000/warehouse-app-v1.5.3-build43.apk`

### 联系方式
- 技术支持: [待填写]
- 紧急联系: [待填写]

---

**部署检查清单**

- [ ] APK 文件已上传到服务器
- [ ] version.json 已上传并验证
- [ ] 文件可通过 HTTP 访问
- [ ] 测试设备验证更新流程
- [ ] 功能修复已验证
- [ ] 用户已通知
- [ ] 回滚方案已准备
- [ ] 文档已归档

---

祝部署顺利！🚀
