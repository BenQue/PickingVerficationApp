#!/bin/bash

# 创建带边距的图标
# 将图标缩小到70%,周围留出15%的边距

INPUT="docs/Warehouse.png"
OUTPUT_DIR="assets/icon"
TEMP_DIR="build/icon_temp"

# 创建临时目录
mkdir -p "$TEMP_DIR"
mkdir -p "$OUTPUT_DIR"

echo "Creating icon with padding..."

# 原始尺寸
ORIGINAL_SIZE=1024

# 缩小后的尺寸 (70%)
SCALED_SIZE=716

# 最终尺寸
FINAL_SIZE=1024

# 边距 (每边15%)
PADDING=154

# Step 1: 复制原图到临时目录
cp "$INPUT" "$TEMP_DIR/original.png"

# Step 2: 缩小图标到70%
sips -z $SCALED_SIZE $SCALED_SIZE "$TEMP_DIR/original.png" --out "$TEMP_DIR/scaled.png" > /dev/null

# Step 3: 使用sips添加白色边框
sips -p $FINAL_SIZE $FINAL_SIZE "$TEMP_DIR/scaled.png" --out "$TEMP_DIR/padded.png" --padColor FFFFFF > /dev/null

# Step 4: 复制到最终位置
cp "$TEMP_DIR/padded.png" "$OUTPUT_DIR/app_icon.png"
cp "$TEMP_DIR/padded.png" "$OUTPUT_DIR/app_icon_foreground.png"

# 清理临时文件
rm -rf "$TEMP_DIR"

echo "✓ Icon with padding created successfully!"
echo "  - Output: $OUTPUT_DIR/app_icon.png"
echo "  - Output: $OUTPUT_DIR/app_icon_foreground.png"
echo "  - Icon scaled to 70% with 15% padding on each side"
