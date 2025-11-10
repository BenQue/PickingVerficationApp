#!/bin/bash
# 快速调试脚本 - 实时查看应用关键日志
# 用法: ./scripts/quick_debug.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}=== 仓库拣货验证 App 实时日志监控 ===${NC}"
echo ""

# 检查 ADB
if ! command -v adb &> /dev/null; then
    echo -e "${RED}错误: 未找到 adb 命令${NC}"
    exit 1
fi

# 检查设备连接
DEVICES=$(adb devices | grep -v "List" | grep "device$" | wc -l)
if [ "$DEVICES" -eq 0 ]; then
    echo -e "${RED}错误: 未检测到已连接的设备${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 设备已连接${NC}"
echo ""
echo -e "${YELLOW}监控以下关键日志:${NC}"
echo "• 工单查询请求"
echo "• HTTP 响应状态"
echo "• 错误消息"
echo "• 服务器返回数据"
echo ""
echo -e "${BLUE}提示: 按 Ctrl+C 停止监控${NC}"
echo ""
echo "--- 开始监控 ---"
echo ""

# 清除旧日志
adb logcat -c

# 实时显示关键日志，带颜色高亮
adb logcat | grep --line-buffered -E "flutter.*\
(开始获取工单详情|\
订单号:|\
请求URL:|\
响应状态码:|\
响应数据:|\
网络请求异常|\
异常类型:|\
状态码:|\
服务器返回错误消息:|\
重新抛出服务器错误消息)" | \
while IFS= read -r line; do
    if echo "$line" | grep -q "错误\|异常\|失败"; then
        echo -e "${RED}$line${NC}"
    elif echo "$line" | grep -q "开始获取工单详情\|请求URL"; then
        echo -e "${BLUE}$line${NC}"
    elif echo "$line" | grep -q "响应状态码\|状态码"; then
        if echo "$line" | grep -q "200"; then
            echo -e "${GREEN}$line${NC}"
        else
            echo -e "${YELLOW}$line${NC}"
        fi
    else
        echo "$line"
    fi
done
