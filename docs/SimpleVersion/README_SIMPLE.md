# 合箱校验系统 - 简化版本

专注于核心功能的简化版本，使用新的SimpleAPI结构。

## 🎯 核心功能

- ✅ **工单扫描**: 支持QR码扫描和手动输入工单号
- ✅ **三类物料管理**: 断线物料、中央仓库物料、自动化仓库物料
- ✅ **实时进度跟踪**: 显示完成数量vs需求数量
- ✅ **简化验证流程**: 专注于拣货验证核心业务
- ✅ **新API集成**: 使用 `/api/WorkOrderPickVerf` 端点

## 🏗️ 技术架构

### API 集成
- **GET**: `/api/WorkOrderPickVerf?orderno=123456789`
- **PUT**: `/api/WorkOrderPickVerf` (状态更新)
- **基础URL**: `http://10.163.130.173:8001`

### 数据映射
- `cabelItems` → 断线物料 (Line Break Materials)
- `centerStockItems` → 中央仓库物料 (Central Warehouse Materials)
- `autoStockItems` → 自动化仓库物料 (Automated Warehouse Materials)

### 技术栈
- **Framework**: Flutter 3.x
- **状态管理**: BLoC Pattern
- **网络请求**: Dio HTTP Client
- **扫描功能**: mobile_scanner
- **架构模式**: Clean Architecture (简化版)

## 🚀 快速开始

### 1. 运行简化版本
```bash
# 使用简化版启动脚本
chmod +x scripts/run_simple.sh
./scripts/run_simple.sh

# 或者直接运行
flutter run -t lib/main_simple.dart
```

### 2. 构建生产版本
```bash
# 构建APK
flutter build apk -t lib/main_simple.dart --release

# 输出位置: build/app/outputs/flutter-apk/app-release.apk
```

## 📁 项目结构 (简化版)

```
lib/
├── main_simple.dart                    # 简化版应用入口
└── features/picking_verification/
    ├── data/
    │   ├── datasources/
    │   │   └── simple_picking_datasource.dart     # 新API数据源
    │   ├── models/
    │   │   └── simple_api_models.dart             # SimpleAPI模型
    │   └── repositories/
    │       └── simple_picking_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   └── simple_picking_entities.dart       # 简化实体
    │   └── repositories/
    │       └── simple_picking_repository.dart
    └── presentation/
        ├── bloc/
        │   └── simple_picking_bloc.dart           # 简化BLoC
        ├── pages/
        │   └── simple_picking_screen.dart         # 主屏幕
        └── widgets/
            └── simple_material_item_widget.dart  # 物料组件
```

## 🔧 配置说明

### API 配置
在 `simple_picking_datasource.dart` 中修改：
```dart
static const String baseUrl = 'http://10.163.130.173:8001';
```

### 模拟数据
开发测试时，如果API不可用，会自动使用模拟数据。

## 📱 使用流程

1. **启动应用** → 显示工单输入界面
2. **扫描/输入工单号** → 获取工单详情
3. **查看物料分类** → 三个标签页显示不同类别
4. **更新完成数量** → 点击物料项更新数量
5. **实时进度跟踪** → 查看完成进度
6. **提交验证** → 所有物料完成后提交

## 🎨 UI 特性

### 工业PDA适配
- **大字体**: 适合工业环境阅读
- **高对比度**: 清晰的视觉反馈
- **大触控区域**: 易于操作
- **竖屏布局**: 专为PDA设计

### 用户体验
- **实时反馈**: 每个操作都有即时反馈
- **进度可视化**: 进度条和百分比显示
- **错误处理**: 友好的中文错误提示
- **离线模式**: 网络问题时使用模拟数据

## 🧪 测试

### 测试工单号
开发测试时可以使用以下工单号：
- `123456789` - 包含所有三类物料的完整工单
- `TEST001` - 简单测试工单

### 手动测试流程
1. 输入测试工单号
2. 验证三个物料类别显示正确
3. 测试物料数量更新功能
4. 验证提交流程

## 🔍 故障排除

### 常见问题
1. **网络连接失败** → 检查API地址和端口
2. **工单不存在** → 验证工单号格式
3. **扫描功能异常** → 检查相机权限
4. **数据不同步** → 重启应用或清除缓存

### 日志查看
```bash
# 查看详细日志
flutter logs
```

## 📈 性能优化

- 使用BLoC状态管理，避免不必要的重建
- 本地缓存工单数据，减少API调用
- 延迟加载大量物料数据
- 优化扫描器性能

## 🔒 安全考虑

- HTTPS通信（生产环境）
- 工单数据会话级缓存
- 相机权限合规处理
- 敏感信息不持久化

## 📞 支持

如有问题，请联系开发团队或查看：
- API文档: `docs/API/SimpleAPI.md`
- 完整文档: `docs/stories/3.2.story.md`