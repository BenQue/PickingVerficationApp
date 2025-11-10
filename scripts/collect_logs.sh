#!/bin/bash
# 移动端日志收集脚本
# 用法: ./scripts/collect_logs.sh [duration_in_seconds]

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 配置
APP_PACKAGE="com.example.picking_verification_app"
LOG_DIR="logs"
DURATION=${1:-60}  # 默认记录 60 秒

echo -e "${GREEN}=== 仓库拣货验证 App 日志收集工具 ===${NC}"
echo ""

# 检查 ADB
if ! command -v adb &> /dev/null; then
    echo -e "${RED}错误: 未找到 adb 命令${NC}"
    echo "请确保 Android SDK 已安装并配置环境变量"
    exit 1
fi

# 检查设备连接
echo -e "${YELLOW}检查设备连接...${NC}"
DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)
if [ "$DEVICES" -eq 0 ]; then
    echo -e "${RED}错误: 未检测到已连接的设备${NC}"
    echo "请确保:"
    echo "1. 设备已通过 USB 连接"
    echo "2. 设备已启用 USB 调试"
    echo "3. 已授权此计算机进行调试"
    exit 1
fi
echo -e "${GREEN}✓ 已检测到设备${NC}"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 生成日志文件名
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="$LOG_DIR/app_log_$TIMESTAMP.txt"
FILTERED_LOG="$LOG_DIR/app_filtered_$TIMESTAMP.txt"
ERROR_LOG="$LOG_DIR/app_errors_$TIMESTAMP.txt"

echo ""
echo -e "${YELLOW}日志收集配置:${NC}"
echo "应用包名: $APP_PACKAGE"
echo "记录时长: ${DURATION} 秒"
echo "日志目录: $LOG_DIR"
echo ""

# 清除旧日志
echo -e "${YELLOW}清除设备日志缓冲区...${NC}"
adb logcat -c

# 检查应用是否运行
APP_RUNNING=$(adb shell "ps | grep $APP_PACKAGE" | wc -l)
if [ "$APP_RUNNING" -eq 0 ]; then
    echo -e "${YELLOW}警告: 应用未运行。请启动应用后再收集日志。${NC}"
    read -p "按 Enter 继续收集日志，或按 Ctrl+C 取消..."
fi

echo -e "${GREEN}开始收集日志...${NC}"
echo "操作提示:"
echo "1. 现在可以在设备上重现问题"
echo "2. 例如: 扫描无效订单号、测试网络错误等"
echo "3. 日志将记录 ${DURATION} 秒"
echo ""

# 开始收集日志（后台运行）
timeout ${DURATION}s adb logcat > "$LOG_FILE" 2>&1 &
LOGCAT_PID=$!

# 显示进度
for ((i=1; i<=DURATION; i++)); do
    echo -ne "\r${YELLOW}收集中... ${i}/${DURATION} 秒${NC}"
    sleep 1
done
echo ""

# 等待 logcat 完成
wait $LOGCAT_PID 2>/dev/null || true

echo -e "${GREEN}✓ 日志收集完成${NC}"
echo ""

# 处理和过滤日志
echo -e "${YELLOW}分析日志...${NC}"

# 提取 Flutter 相关日志
grep -i "flutter" "$LOG_FILE" > "$FILTERED_LOG" 2>/dev/null || echo "未找到 Flutter 日志" > "$FILTERED_LOG"

# 提取错误和关键信息
grep -E "(错误|异常|失败|Exception|Error|工单详情|订单号|响应数据|状态码)" "$LOG_FILE" > "$ERROR_LOG" 2>/dev/null || echo "未找到错误日志" > "$ERROR_LOG"

echo ""
echo -e "${GREEN}=== 日志收集报告 ===${NC}"
echo ""
echo "完整日志: $LOG_FILE"
echo "  行数: $(wc -l < "$LOG_FILE")"
echo "  大小: $(du -h "$LOG_FILE" | cut -f1)"
echo ""
echo "过滤日志 (仅 Flutter): $FILTERED_LOG"
echo "  行数: $(wc -l < "$FILTERED_LOG")"
echo ""
echo "错误日志: $ERROR_LOG"
echo "  行数: $(wc -l < "$ERROR_LOG")"
echo ""

# 显示最近的关键日志
echo -e "${YELLOW}=== 最近的关键日志 (最后 10 条) ===${NC}"
tail -10 "$ERROR_LOG"
echo ""

# 搜索特定的错误模式
echo -e "${YELLOW}=== HTTP 400 错误检测 ===${NC}"
HTTP_400_COUNT=$(grep -c "HTTP 400\|状态码: 400" "$LOG_FILE" 2>/dev/null || echo "0")
if [ "$HTTP_400_COUNT" -gt 0 ]; then
    echo -e "${RED}检测到 $HTTP_400_COUNT 次 HTTP 400 错误${NC}"
    echo "详细信息:"
    grep -A 5 "状态码: 400" "$LOG_FILE" | head -20
else
    echo -e "${GREEN}✓ 未检测到 HTTP 400 错误${NC}"
fi
echo ""

# 搜索网络请求
echo -e "${YELLOW}=== 工单查询请求检测 ===${NC}"
REQUEST_COUNT=$(grep -c "开始获取工单详情\|请求URL" "$LOG_FILE" 2>/dev/null || echo "0")
echo "工单查询次数: $REQUEST_COUNT"
if [ "$REQUEST_COUNT" -gt 0 ]; then
    echo "最近的查询:"
    grep -A 2 "开始获取工单详情" "$LOG_FILE" | tail -6
fi
echo ""

# 提供查看建议
echo -e "${GREEN}=== 后续操作建议 ===${NC}"
echo ""
echo "1. 查看完整日志:"
echo "   cat $LOG_FILE"
echo ""
echo "2. 搜索特定错误:"
echo "   grep '订单号' $LOG_FILE"
echo "   grep '错误消息' $LOG_FILE"
echo ""
echo "3. 实时查看新日志:"
echo "   adb logcat | grep -i flutter"
echo ""
echo "4. 上传日志以供分析:"
echo "   # 将日志文件打包发送给技术支持"
echo "   tar -czf logs_$TIMESTAMP.tar.gz $LOG_DIR/*_$TIMESTAMP.txt"
echo ""

echo -e "${GREEN}日志收集完成！${NC}"
