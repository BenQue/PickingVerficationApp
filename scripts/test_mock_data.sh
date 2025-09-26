#!/bin/bash

# 模拟数据测试脚本
echo "🧪 开始模拟数据测试..."
echo ""

# 检查Flutter环境
echo "🔧 检查Flutter环境..."
flutter --version | head -1

echo ""
echo "📋 测试工单号说明:"
echo "  • TEST001 或 123456789  - 完整测试工单"
echo "  • EMPTY                 - 空工单测试"  
echo "  • PARTIAL              - 部分完成工单"
echo "  • LARGE                - 大批量工单"
echo "  • ERROR                - 错误处理测试"
echo "  • 其他                  - 随机生成数据"

echo ""
echo "🚀 启动简化版应用..."
echo "预期流程："
echo "1. 应用启动 → WMS工作台"
echo "2. 点击'合箱校验' → 工单输入界面" 
echo "3. 输入测试工单号 → 查看物料详情"
echo "4. 更新物料数量 → 提交验证"
echo ""

# 清理并启动
flutter clean > /dev/null 2>&1
flutter pub get > /dev/null 2>&1

echo "📱 正在启动应用..."
echo "请在应用中测试以下流程：" 
echo ""
echo "✅ 基础测试步骤："
echo "1. 检查工作台界面是否正常显示"
echo "2. 点击'合箱校验'按钮进入功能"
echo "3. 输入工单号 'TEST001' 进行测试"
echo "4. 验证三类物料分类显示正确"
echo "5. 更新物料完成数量并观察进度变化"
echo "6. 全部完成后点击'提交验证'"
echo "7. 确认显示成功界面后返回"
echo ""

flutter run -t lib/main_simple.dart --verbose