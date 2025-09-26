#!/bin/bash

# 简化版本运行脚本
# 专注于合箱校验功能

echo "🚀 启动简化版合箱校验系统..."
echo ""

# 清理并获取依赖
echo "📦 获取依赖包..."
flutter clean
flutter pub get

echo ""
echo "🔧 检查代码..."
flutter analyze lib/features/picking_verification/

echo ""
echo "📱 运行简化版应用..."
flutter run -t lib/main_simple.dart

# 如果需要构建APK
# echo ""
# echo "📱 构建简化版APK..."
# flutter build apk -t lib/main_simple.dart --release