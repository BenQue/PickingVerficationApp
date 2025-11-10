# 🚀 版本 1.5.3 部署前检查清单

**发布日期**: 2025-11-10
**负责人**: [填写姓名]
**审核人**: [填写姓名]

---

## ✅ 开发阶段

### 代码修改
- [x] 修复 HTTP 400 错误信息显示问题
- [x] 优化 DioClient 配置 (lib/core/api/dio_client.dart)
- [x] 增强错误处理 (simple_picking_datasource.dart)
- [x] 添加调试日志
- [x] 代码审查通过

### 版本更新
- [x] pubspec.yaml: 1.5.2+42 → 1.5.3+43
- [x] workbench_home_screen.dart: V1.5.2 → V1.5.3
- [x] releases/version.json 更新完成

### 测试验证
- [x] 新增单元测试 (dio_client_http_400_test.dart)
- [x] 所有单元测试通过 (2/2)
- [x] 代码分析无警告 (flutter analyze)
- [x] 功能手动测试 (推荐)

### 构建发布
- [x] Flutter clean 清理缓存
- [x] APK 构建成功 (flutter build apk --release)
- [x] APK 文件大小: 78.4 MB ✅
- [x] APK MD5 生成: 5eb2846bed22a99d3862fd6da11e0721
- [x] APK 复制到 releases/ 目录

---

## 📝 文档完成

### 技术文档
- [x] docs/BUG_FIX_HTTP_400_ERROR.md (技术分析)
- [x] docs/QUICK_FIX_SUMMARY.md (快速总结)
- [x] test/core/api/dio_client_http_400_test.dart (测试用例)

### 发布文档
- [x] releases/RELEASE_NOTES_v1.5.3.md (发布说明)
- [x] releases/INSTALL_SUMMARY_v1.5.3.txt (安装摘要)
- [x] releases/DEPLOYMENT_GUIDE_v1.5.3.md (部署指南)
- [x] releases/RELEASE_SUMMARY_v1.5.3.md (发布摘要)
- [x] releases/commit_message.txt (Git提交消息)

---

## 🔍 部署前验证

### 文件完整性
- [ ] 验证 APK 文件存在
  ```bash
  ls -lh releases/warehouse-app-v1.5.3-build43.apk
  # 应显示: 78M
  ```

- [ ] 验证 MD5 校验和
  ```bash
  md5 -q releases/warehouse-app-v1.5.3-build43.apk
  # 应输出: 5eb2846bed22a99d3862fd6da11e0721
  ```

- [ ] 验证 version.json 内容
  ```bash
  cat releases/version.json
  # 检查 versionCode: 43, versionName: "1.5.3"
  ```

### 本地测试（强烈推荐）
- [ ] 在测试设备上安装新版本
  ```bash
  adb install -r releases/warehouse-app-v1.5.3-build43.apk
  ```

- [ ] 验证版本号显示
  - 打开应用
  - 点击右上角员工信息
  - 确认显示 "V1.5.3" ✅

- [ ] 测试错误场景
  - 扫描无效订单号
  - 确认显示详细错误消息（非"HTTP 400"）✅

- [ ] 测试正常流程
  - 扫描有效订单
  - 完成正常业务流程 ✅

---

## 🌐 服务器准备

### 服务器访问
- [ ] 确认有服务器 SSH 访问权限
  ```bash
  ssh user@10.163.130.173
  ```

- [ ] 确认 /var/www/html/ 目录写入权限
  ```bash
  ssh user@10.163.130.173 'ls -ld /var/www/html/'
  ```

### 备份当前版本
- [ ] 备份当前 version.json
  ```bash
  ssh user@10.163.130.173 'cp /var/www/html/version.json /var/www/html/version.json.backup-$(date +%Y%m%d)'
  ```

- [ ] 备份当前 APK（如果需要快速回滚）
  ```bash
  # 确认旧版本 APK 文件存在
  ssh user@10.163.130.173 'ls -lh /var/www/html/warehouse-app-v1.5.2-build42.apk'
  ```

---

## 📤 部署到服务器

### 上传文件
- [ ] 上传 APK 到服务器
  ```bash
  scp releases/warehouse-app-v1.5.3-build43.apk user@10.163.130.173:/var/www/html/
  ```

- [ ] 上传 version.json 到服务器
  ```bash
  scp releases/version.json user@10.163.130.173:/var/www/html/
  ```

- [ ] 设置文件权限（如果需要）
  ```bash
  ssh user@10.163.130.173 'chmod 644 /var/www/html/warehouse-app-v1.5.3-build43.apk'
  ssh user@10.163.130.173 'chmod 644 /var/www/html/version.json'
  ```

### 验证文件可访问
- [ ] 测试 version.json 可访问
  ```bash
  curl http://10.163.130.173:8000/version.json
  # 应返回 JSON 内容，versionCode: 43
  ```

- [ ] 测试 APK 可下载
  ```bash
  curl -I http://10.163.130.173:8000/warehouse-app-v1.5.3-build43.apk
  # 应返回 HTTP/1.1 200 OK, Content-Length: 82191708
  ```

- [ ] 测试完整下载（可选，但推荐）
  ```bash
  curl -o /tmp/test-v1.5.3.apk http://10.163.130.173:8000/warehouse-app-v1.5.3-build43.apk
  md5 -q /tmp/test-v1.5.3.apk
  # 应输出: 5eb2846bed22a99d3862fd6da11e0721
  ```

---

## 🧪 部署后测试

### 自动更新测试
- [ ] 在测试设备上保留旧版本 (v1.5.2)
- [ ] 打开应用，等待自动检测更新
- [ ] 验证更新对话框显示正确
  - 版本号: 1.5.3
  - 更新日志正确显示
  - 文件大小约 78.4 MB

- [ ] 点击"立即更新"，测试下载
  - 下载进度正常显示
  - 下载完成后提示安装

- [ ] 完成安装后验证
  - 应用可正常启动
  - 版本号显示 V1.5.3
  - 功能正常工作

### 功能验证
- [ ] 测试修复的功能
  - 扫描无效订单
  - 确认错误消息清晰（"扫码出错：未查询到订单信息"）
  - 而非"获取工单详情失败：HTTP 400"

- [ ] 测试正常业务流程
  - 登录功能正常
  - 扫描有效订单成功
  - 物料验证正常
  - 提交流程正常

- [ ] 测试其他核心功能
  - 平台接收
  - 线边配送
  - 任务看板

---

## 📢 用户通知

### 通知准备
- [ ] 准备通知内容
  ```
  【系统更新通知】
  仓库拣货验证App今日更新至v1.5.3版本

  主要改进：
  • 修复错误信息显示，提供更清晰的错误提示
  • 增强系统稳定性

  更新方式：打开应用自动检测更新
  更新不影响数据，约需2-3分钟

  如有问题请联系：[技术支持联系方式]
  ```

- [ ] 确定通知渠道
  - [ ] 企业微信/钉钉群组
  - [ ] 现场广播
  - [ ] 班组长通知

- [ ] 选择合适的通知时间
  - 推荐：非高峰期（中午或下班后）
  - 避免：工作繁忙时段

### 发送通知
- [ ] 通知已发送给所有用户
- [ ] 记录通知发送时间: ___________

---

## 📊 监控和跟踪

### 初期监控（前24小时）
- [ ] 每2小时检查一次更新率
  ```bash
  ssh user@10.163.130.173 'grep "warehouse-app-v1.5.3" /var/log/nginx/access.log | wc -l'
  ```

- [ ] 收集用户反馈
  - 更新是否顺畅
  - 错误消息是否清晰
  - 是否有新问题

- [ ] 监控异常日志
  - 检查服务器错误日志
  - 关注应用崩溃报告

### 持续跟踪
- [ ] 第1天: 更新率统计 _____%
- [ ] 第3天: 更新率统计 _____%
- [ ] 第7天: 更新率统计 _____%
- [ ] 第30天: 更新率统计 _____%

---

## 🔄 回滚准备

### 回滚条件（出现以下任一情况时考虑回滚）
- [ ] 发现严重功能bug
- [ ] 应用频繁崩溃
- [ ] 用户无法正常使用核心功能
- [ ] 数据丢失或损坏

### 回滚步骤（如需要）
```bash
# 1. 立即停止新版本推送
ssh user@10.163.130.173
cd /var/www/html/
cp version.json.backup-[日期] version.json

# 2. 验证回滚
curl http://10.163.130.173:8000/version.json
# 确认 versionCode 已改回 42

# 3. 通知用户
# 发送回滚通知，提供旧版本APK链接
```

---

## ✍️ Git 版本控制

### Git 提交
- [ ] 查看修改状态
  ```bash
  git status
  ```

- [ ] 添加修改文件
  ```bash
  git add lib/core/api/dio_client.dart
  git add lib/features/picking_verification/data/datasources/simple_picking_datasource.dart
  git add pubspec.yaml
  git add lib/features/picking_verification/presentation/pages/workbench_home_screen.dart
  git add releases/
  git add docs/
  git add test/core/api/dio_client_http_400_test.dart
  ```

- [ ] 创建提交
  ```bash
  git commit -F releases/commit_message.txt
  ```

- [ ] 创建版本标签
  ```bash
  git tag -a v1.5.3 -m "Release version 1.5.3 - Fix HTTP 400 error message display"
  ```

- [ ] 推送到远程（如需要）
  ```bash
  git push origin main
  git push origin v1.5.3
  ```

---

## 📋 最终确认

### 部署完成确认
- [ ] APK 已成功上传到服务器
- [ ] version.json 已更新并可访问
- [ ] 测试设备验证更新流程成功
- [ ] 功能测试全部通过
- [ ] 用户已收到更新通知
- [ ] 监控机制已启动
- [ ] 回滚方案已准备
- [ ] Git 提交和标签已创建
- [ ] 文档已归档

### 签名确认
```
部署执行人: ________________  日期: ___________
测试验证人: ________________  日期: ___________
审核批准人: ________________  日期: ___________
```

---

## 📞 紧急联系

如遇紧急问题，请联系：
- 技术负责人: [姓名] - [电话]
- 后备联系人: [姓名] - [电话]
- 紧急热线: [电话]

---

## 📌 重要提醒

1. ⚠️ 确保在非高峰期部署
2. ⚠️ 保持通讯畅通，随时准备处理问题
3. ⚠️ 前24小时密切监控用户反馈
4. ⚠️ 出现严重问题立即回滚，不要犹豫
5. ⚠️ 记录所有问题和处理过程，用于后续改进

---

✅ **检查清单完成，准备部署！**

祝部署顺利！🚀
