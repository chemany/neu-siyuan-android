#!/bin/bash
# 灵枢笔记 (NeuraLink Notes) - 前端资源构建脚本
# 此脚本用于构建 NeuraLink-Notes 前端资源并打包为 app.zip

set -e

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NEURALINK_DIR="$PROJECT_ROOT/NeuraLink-Notes"
ANDROID_DIR="$PROJECT_ROOT/neu-android"
ASSETS_DIR="$ANDROID_DIR/app/src/main/assets"
TEMP_BUILD_DIR="/tmp/neuralink-android-build"

echo "================================"
echo "灵枢笔记 Android 前端资源构建"
echo "================================"
echo ""

# 检查 NeuraLink-Notes 目录是否存在
if [ ! -d "$NEURALINK_DIR" ]; then
    echo "错误: NeuraLink-Notes 目录不存在: $NEURALINK_DIR"
    exit 1
fi

# 创建临时构建目录
echo "1. 创建临时构建目录..."
rm -rf "$TEMP_BUILD_DIR"
mkdir -p "$TEMP_BUILD_DIR"

# 复制前端资源文件
echo "2. 复制前端资源文件..."

# 复制 appearance 目录（包含前端静态资源）
if [ -d "$NEURALINK_DIR/appearance" ]; then
    cp -r "$NEURALINK_DIR/appearance" "$TEMP_BUILD_DIR/"
    echo "   - 已复制 appearance/"
fi

# 复制 guide 目录（引导页）
if [ -d "$NEURALINK_DIR/guide" ]; then
    cp -r "$NEURALINK_DIR/guide" "$TEMP_BUILD_DIR/"
    echo "   - 已复制 guide/"
fi

# 复制 stage 目录（阶段性资源）
if [ -d "$NEURALINK_DIR/stage" ]; then
    cp -r "$NEURALINK_DIR/stage" "$TEMP_BUILD_DIR/"
    echo "   - 已复制 stage/"
fi

# 复制 changelogs 目录（变更日志）
if [ -d "$NEURALINK_DIR/changelogs" ]; then
    cp -r "$NEURALINK_DIR/changelogs" "$TEMP_BUILD_DIR/"
    echo "   - 已复制 changelogs/"
fi

# 构建 app.zip
echo "3. 构建 app.zip..."
cd "$TEMP_BUILD_DIR"
zip -qr "$ASSETS_DIR/app.zip" ./*

# 清理临时目录
echo "4. 清理临时目录..."
rm -rf "$TEMP_BUILD_DIR"

# 验证文件是否创建成功
if [ -f "$ASSETS_DIR/app.zip" ]; then
    FILE_SIZE=$(du -h "$ASSETS_DIR/app.zip" | cut -f1)
    echo ""
    echo "================================"
    echo "构建完成!"
    echo "文件位置: $ASSETS_DIR/app.zip"
    echo "文件大小: $FILE_SIZE"
    echo "================================"
else
    echo "错误: app.zip 构建失败"
    exit 1
fi