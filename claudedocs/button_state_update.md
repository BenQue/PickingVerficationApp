# 电缆上架按钮状态优化

## 更新日期
2025-10-29

## 更新内容

### 问题描述
电缆上架功能中的"确认库位"按钮样式与合箱校验不一致，需要实现：
- 无输入/输入不足时：灰色（禁用状态）
- 输入完成后：蓝色（启用状态）

### 解决方案

#### 1. 更新PrimaryButton组件
**文件**: `lib/core/widgets/common_widgets.dart`

**改进点**:
- 引入WorkbenchTheme统一主题
- 根据启用/禁用状态动态改变背景色
- 统一按钮样式（圆角、字体、图标大小）

**颜色状态**:
```dart
// 启用状态（有输入数据）
backgroundColor: WorkbenchTheme.primaryButtonColor  // #1976D2 蓝色

// 禁用状态（无输入或不足）
backgroundColor: Colors.grey.shade400  // 灰色
```

#### 2. 按钮样式规范

```dart
PrimaryButton(
  text: '确认库位',
  icon: Icons.check,
  onPressed: _locationController.text.trim().length >= 4
      ? _setTargetLocation  // 输入≥4个字符时启用
      : null,               // 否则禁用（显示灰色）
)
```

**视觉效果**:
- **禁用状态**（灰色）：
  - 背景：`Colors.grey.shade400`
  - 文字：`Colors.white70` (半透明白色)
  - 无点击响应

- **启用状态**（蓝色）：
  - 背景：`#1976D2` (Material Blue 700)
  - 文字：`Colors.white` (纯白色)
  - 可点击执行操作

#### 3. 统一样式参数

```dart
// 按钮尺寸
height: 56px             // 大触摸目标
width: 100%              // 全宽

// 圆角
borderRadius: 12px       // 与WorkbenchTheme一致

// 文字
fontSize: 18px
fontWeight: bold
color: white

// 图标
size: 24px
color: white

// 间距
padding: vertical 16px

// 阴影
elevation: 2
```

#### 4. 智能状态检测

```dart
final bool isEnabled = !isLoading && onPressed != null;

// 根据条件自动切换颜色
backgroundColor: isEnabled
    ? WorkbenchTheme.primaryButtonColor  // 蓝色
    : Colors.grey.shade400,              // 灰色
```

### 应用场景

#### 电缆上架 - 确认库位
- **初始状态**：输入框为空 → 按钮灰色
- **输入中**：输入1-3个字符 → 按钮保持灰色
- **可提交**：输入≥4个字符 → 按钮变蓝色
- **提交中**：显示加载动画 → 按钮禁用

#### 其他使用PrimaryButton的场景
此改进自动应用到所有使用PrimaryButton的地方：
- ✅ 合箱校验的各种操作按钮
- ✅ 库存查询的确认按钮
- ✅ 电缆上架的确认库位按钮
- ✅ 所有表单提交按钮

### 代码对比

#### 更新前
```dart
class PrimaryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      // 使用默认主题颜色
      child: ...
    );
  }
}
```

#### 更新后
```dart
class PrimaryButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bool isEnabled = !isLoading && onPressed != null;

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled
            ? WorkbenchTheme.primaryButtonColor  // 蓝色
            : Colors.grey.shade400,              // 灰色
        // ... 完整样式定义
      ),
      child: ...
    );
  }
}
```

### 视觉效果流程

```
电缆上架 - 设置目标库位流程：

1. [输入框为空]
   ┌────────────────────┐
   │ 请输入库位编号     │ ← 输入框（空）
   └────────────────────┘
   ┌────────────────────┐
   │  ✓ 确认库位        │ ← 按钮（灰色，禁用）
   └────────────────────┘

2. [输入不足4个字符]
   ┌────────────────────┐
   │ A01               │ ← 输入框（3个字符）
   └────────────────────┘
   ┌────────────────────┐
   │  ✓ 确认库位        │ ← 按钮（灰色，禁用）
   └────────────────────┘

3. [输入≥4个字符]
   ┌────────────────────┐
   │ A01-001           │ ← 输入框（7个字符）
   └────────────────────┘
   ┌────────────────────┐
   │  ✓ 确认库位        │ ← 按钮（蓝色，启用）
   └────────────────────┘
```

### 技术实现细节

#### 状态检测逻辑
```dart
// 电缆上架页面中的使用
PrimaryButton(
  text: '确认库位',
  icon: Icons.check,
  onPressed: _locationController.text.trim().length >= 4
      ? _setTargetLocation  // 条件满足：启用
      : null,               // 条件不满足：禁用
)
```

#### 颜色计算
```dart
// PrimaryButton组件内部
final bool isEnabled = !isLoading && onPressed != null;

backgroundColor: isEnabled
    ? WorkbenchTheme.primaryButtonColor  // onPressed != null → 蓝色
    : Colors.grey.shade400,              // onPressed == null → 灰色
```

### 一致性保证

#### 与WorkbenchTheme对齐
- ✅ 使用统一的主题色 `WorkbenchTheme.primaryButtonColor`
- ✅ 使用统一的圆角 `WorkbenchTheme.buttonBorderRadius`
- ✅ 使用统一的文字样式（18px，粗体）
- ✅ 使用统一的图标大小（24px）

#### 与合箱校验按钮一致
- ✅ 相同的蓝色 (#1976D2)
- ✅ 相同的圆角 (12px)
- ✅ 相同的高度 (56px)
- ✅ 相同的禁用状态颜色（灰色）

### 部署信息

**构建时间**: 14.8秒
**APK大小**: 81.7MB
**部署状态**: ✅ 成功安装到设备
**应用状态**: ✅ 正常运行

### 测试验证

#### 测试场景
1. **初始状态**
   - 打开电缆上架功能
   - 进入"设置目标库位"
   - 验证：按钮应为灰色

2. **输入过程**
   - 输入1个字符 → 按钮保持灰色
   - 输入2个字符 → 按钮保持灰色
   - 输入3个字符 → 按钮保持灰色
   - 输入4个字符 → 按钮变为蓝色 ✅

3. **删除过程**
   - 从4个字符删除到3个 → 按钮变回灰色
   - 验证状态切换响应及时

4. **提交流程**
   - 输入有效库位 → 按钮蓝色
   - 点击确认 → 显示加载动画
   - 完成后 → 按钮恢复正常

### 用户体验改进

#### 视觉反馈
- ✅ **清晰的状态指示**：灰色=不可用，蓝色=可用
- ✅ **即时响应**：输入时按钮状态立即更新
- ✅ **统一体验**：所有功能按钮风格一致

#### 操作引导
- ✅ 用户一眼看出按钮是否可用
- ✅ 减少无效点击（灰色时无法点击）
- ✅ 提供明确的操作准备度反馈

### 影响范围

#### 直接影响
- ✅ 电缆上架 - 确认库位按钮
- ✅ 所有使用PrimaryButton的页面

#### 间接影响
- ✅ 提升整体应用的视觉一致性
- ✅ 建立统一的按钮状态规范
- ✅ 为后续功能开发提供标准模板

### 后续建议

#### 短期
- ✅ 在实际使用中验证状态切换响应速度
- ✅ 确认在不同输入场景下的表现
- ✅ 收集用户对颜色区分度的反馈

#### 中期
- 考虑添加按钮按下时的视觉反馈（涟漪效果）
- 优化加载状态的动画效果
- 统一所有次要按钮的样式

#### 长期
- 建立完整的按钮状态设计规范
- 添加无障碍功能支持
- 考虑支持自定义主题色

---

**更新状态**: ✅ 完成
**测试状态**: ✅ 已部署到设备
**用户验收**: 待确认

## 技术要点总结

### 关键改进
1. **动态颜色**：根据启用状态自动切换灰色/蓝色
2. **统一主题**：使用WorkbenchTheme确保一致性
3. **智能判断**：自动检测onPressed是否为null
4. **全局应用**：所有PrimaryButton自动获得新样式

### 核心代码
```dart
final bool isEnabled = !isLoading && onPressed != null;

style: ElevatedButton.styleFrom(
  backgroundColor: isEnabled
      ? WorkbenchTheme.primaryButtonColor  // 蓝色
      : Colors.grey.shade400,              // 灰色
  foregroundColor: Colors.white,
  disabledBackgroundColor: Colors.grey.shade400,
  disabledForegroundColor: Colors.white70,
  // ... 其他样式参数
),
```

### 使用方式
```dart
// 只需设置onPressed为null即可自动显示灰色
PrimaryButton(
  text: '确认',
  icon: Icons.check,
  onPressed: condition ? callback : null,  // ← 关键
)
```
