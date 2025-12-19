# Release Notes - v1.8.0

**发布日期**: 2025-12-19  
**版本号**: 1.8.0 (Build 80)

## 版本概述

本版本主要修复了合箱校验功能中的缓存污染问题，解决了用户反映的物料分类显示错误和计划数量不一致的bug。

## Bug 修复

### 合箱校验缓存污染问题 (Critical)

**问题描述**: 用户在合箱校验时，电缆物料有时会错误地出现在中心仓库页签，计划数量也不对。重新扫码后数据又恢复正常。

**根本原因**: 
- 仓储层缓存 (`_orderCache`) 在 API 失败时返回旧数据
- 切换订单时未清除旧缓存
- 多重导航路径创建了隔离的仓储实例

**修复内容**:
- 移除 API 失败时返回旧缓存的逻辑，改为直接显示错误提示
- 每次加载订单前清除该订单的旧缓存
- 在仓储接口中添加 `clearCache()` 方法
- 切换订单和重置状态时主动清除缓存
- 统一使用 GoRouter 导航，确保 BLoC 生命周期一致

## 技术改进

- **数据一致性**: 确保每次扫码都从 API 获取最新数据
- **错误处理**: 网络失败时显示明确的错误提示，而非可能过期的缓存数据
- **导航管理**: 统一导航路径，避免多个仓储实例导致的缓存混乱

## 影响的文件

- `lib/features/picking_verification/domain/repositories/simple_picking_repository.dart`
- `lib/features/picking_verification/data/repositories/simple_picking_repository_impl.dart`
- `lib/features/picking_verification/presentation/bloc/simple_picking_bloc.dart`
- `lib/features/picking_verification/presentation/pages/workbench_home_screen.dart`

## 安装说明

1. 下载 `warehouse-app-v1.8.0-build80.apk`
2. 在 PDA 设备上安装（允许未知来源应用）
3. 启动应用，点击右上角员工信息确认版本号为 V1.8.0

## 验证步骤

1. 扫描订单 A，查看物料分类
2. 返回主页
3. 扫描订单 B（与 A 不同分类的物料）
4. 验证物料正确显示在对应页签
5. 确认计划数量与实际一致

---

**文件信息**:
- 文件名: `warehouse-app-v1.8.0-build80.apk`
- 文件大小: 82.4 MB
- 最低支持版本: Build 30
