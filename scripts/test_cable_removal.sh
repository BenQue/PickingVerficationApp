#!/bin/bash

# 电缆下架功能测试脚本
# 用于快速启动应用并测试电缆下架功能

echo "=========================================="
echo "电缆下架功能 - 测试启动脚本"
echo "=========================================="
echo ""

# 检查是否有连接的设备
echo "检查连接的设备..."
flutter devices

echo ""
echo "请选择运行设备:"
echo "1. 自动检测并启动"
echo "2. 在Android模拟器上运行"
echo "3. 在iOS模拟器上运行"
echo "4. 在连接的物理设备上运行"
echo ""
read -p "请输入选项 (1-4): " choice

case $choice in
  1)
    echo ""
    echo "启动应用..."
    flutter run
    ;;
  2)
    echo ""
    echo "在Android模拟器上启动..."
    flutter run -d emulator
    ;;
  3)
    echo ""
    echo "在iOS模拟器上启动..."
    flutter run -d simulator
    ;;
  4)
    echo ""
    echo "在连接的设备上启动..."
    flutter run -d device
    ;;
  *)
    echo "无效的选项,使用默认启动..."
    flutter run
    ;;
esac

echo ""
echo "=========================================="
echo "测试步骤提示:"
echo "=========================================="
echo "1. 应用启动后,查看工作台主页面"
echo "2. 找到'断线线边管理'功能组"
echo "3. 点击'电缆下架'卡片(橙色,下载图标)"
echo "4. 验证目标库位固定为 2200-100"
echo "5. 扫描电缆条码进行测试"
echo ""
echo "详细测试步骤请查看:"
echo "claudedocs/cable_removal_manual_test.md"
echo "=========================================="
