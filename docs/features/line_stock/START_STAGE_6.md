# 🚀 开始 Stage 6 - 快速指南

**目标**: 集成测试 + 性能验证 + 文档完善 = 生产就绪

---

## ✅ 前置确认

在开始前，请确认：

```bash
# 1. 所有测试通过
flutter test test/features/line_stock/
# 预期: 241 tests passed ✅

# 2. 代码可编译
flutter build apk --debug
# 预期: Build succeeded ✅

# 3. 静态分析
flutter analyze lib/features/line_stock/
# 预期: 0 errors (9 deprecation warnings 可接受) ✅
```

如果以上都通过，说明Stage 5完成，可以开始Stage 6！

---

## 📋 Stage 6 任务优先级

### 🔴 Priority 1: 集成测试 (必须完成)

创建4个集成测试文件：

```bash
test/features/line_stock/integration/
├── stock_query_flow_test.dart        # 查询流程
├── cable_shelving_flow_test.dart     # 上架流程
├── error_recovery_test.dart          # 错误恢复
└── edge_cases_test.dart              # 边界场景
```

**详细指导**: 参见 [STAGE_6_HANDOFF.md](./STAGE_6_HANDOFF.md#1-集成测试-02天---优先级最高)

### 🟡 Priority 2: 代码质量 (应该完成)

```bash
# 1. 修复所有静态分析警告
flutter analyze lib/features/line_stock/ --fix

# 2. 格式化代码
dart format lib/features/line_stock/

# 3. 创建代码审查清单
# 文件: docs/features/line_stock/CODE_REVIEW_CHECKLIST.md
```

### 🟢 Priority 3: 文档完善 (应该完成)

创建3个文档：

```bash
docs/features/line_stock/
├── USER_MANUAL.md              # 用户操作手册
├── TROUBLESHOOTING.md          # 故障排查指南
└── screenshots/                # 功能截图
    ├── query_initial.png
    ├── query_result.png
    ├── shelving_location.png
    ├── shelving_cables.png
    ├── shelving_success.png
    └── error_dialog.png
```

### 🔵 Priority 4: 性能测试 (可选完成)

手动测试记录：
- 列表滚动性能 (50+项)
- 内存占用 (<100MB)
- API响应时间

---

## 🎯 今日目标

**如果只有2-3小时**:
- ✅ 完成2个核心集成测试 (查询 + 上架)
- ✅ 修复静态分析警告
- ✅ 创建用户操作手册

**如果有4小时完整时间**:
- ✅ 完成全部4个集成测试
- ✅ 代码质量提升
- ✅ 完成3个文档
- ✅ 截取6张功能截图

---

## 📖 快速参考

### 集成测试模板

```dart
// test/features/line_stock/integration/xxx_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('Complete Stock Query Flow', () {
    testWidgets('should complete query flow successfully', (tester) async {
      // Arrange: Setup mocked dependencies
      final mockDioClient = MockDioClient();

      // Act & Assert: Test complete user journey
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider(
            create: (_) => LineStockBloc(/* with mocked dependencies */),
            child: StockQueryScreen(),
          ),
        ),
      );

      // 1. Enter barcode
      await tester.enterText(find.byType(TextField), 'TEST123');
      await tester.pump();

      // 2. Submit and verify loading
      await tester.tap(find.text('查询'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 3. Verify result display
      await tester.pumpAndSettle();
      expect(find.text('物料编码'), findsOneWidget);

      // 4. Navigate to shelving
      await tester.tap(find.text('立即上架'));
      await tester.pumpAndSettle();
      expect(find.byType(CableShelvingScreen), findsOneWidget);
    });
  });
}
```

### 文档模板

```markdown
# Line Stock 用户操作手册

## 1. 功能概述

Line Stock (线边库存) 功能用于...

## 2. 库存查询

### 2.1 扫描条码
1. 打开查询页面
2. 将PDA对准条码
3. 系统自动识别并查询

![查询页面](screenshots/query_initial.png)

### 2.2 查看库存信息
...

## 3. 电缆上架

### 3.1 设置库位
...

## 4. 常见问题

### Q1: 扫码无反应怎么办？
A: 检查以下几点...
```

---

## 📞 需要帮助？

**参考文档**:
- [Stage 6 详细交接文档](./STAGE_6_HANDOFF.md) - 完整任务说明
- [Stage 5 完成报告](./STAGE_5_COMPLETE.md) - 当前状态
- [功能规格说明](./line-stock-specs.md) - 功能需求

**测试命令**:
```bash
# 运行所有测试
flutter test test/features/line_stock/

# 运行集成测试
flutter test test/features/line_stock/integration/

# 运行单个测试文件
flutter test test/features/line_stock/integration/stock_query_flow_test.dart
```

**开发环境**:
```bash
# 启动应用
flutter run

# 热重载
r

# 热重启
R

# 查看日志
flutter logs
```

---

## ✅ 完成标准

Stage 6 完成的标志：

- [ ] 至少4个集成测试全部通过
- [ ] 静态分析 0 errors, 0 warnings
- [ ] 用户操作手册完成
- [ ] 所有241个测试保持通过
- [ ] 功能截图完整

达到以上标准，即可认为 Line Stock 功能开发完成，达到生产就绪状态！

---

**祝开发顺利！有任何问题随时查看详细文档。** 🎉
