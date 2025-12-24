#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
灵枢笔记 (NeuraLink Notes) - 前端资源构建脚本
此脚本用于构建 NeuraLink-Notes 前端资源并打包为 app.zip
"""

import os
import sys
import shutil
import zipfile
from pathlib import Path

# 项目根目录
SCRIPT_DIR = Path(__file__).parent.parent
PROJECT_ROOT = SCRIPT_DIR.parent
NEURALINK_DIR = PROJECT_ROOT / "NeuraLink-Notes"
ANDROID_DIR = PROJECT_ROOT / "neu-android"
ASSETS_DIR = ANDROID_DIR / "app" / "src" / "main" / "assets"
TEMP_BUILD_DIR = Path("/tmp/neuralink-android-build")


def print_header(text):
    """打印标题"""
    print("\n" + "=" * 40)
    print(text)
    print("=" * 40 + "\n")


def print_step(num, text):
    """打印步骤"""
    print(f"{num}. {text}")


def format_size(size_bytes):
    """格式化文件大小"""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.1f} TB"


def create_zip(source_dir, output_zip):
    """创建 zip 文件，保留目录结构"""
    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                file_path = Path(root) / file
                arcname = file_path.relative_to(source_dir)
                zipf.write(file_path, arcname)
                print(f"   - 添加: {arcname}")


def main():
    print_header("灵枢笔记 Android 前端资源构建")
    
    # 检查 NeuraLink-Notes 目录是否存在
    if not NEURALINK_DIR.exists():
        print(f"错误: NeuraLink-Notes 目录不存在: {NEURALINK_DIR}")
        sys.exit(1)
    
    # 创建临时构建目录
    print_step(1, "创建临时构建目录...")
    if TEMP_BUILD_DIR.exists():
        shutil.rmtree(TEMP_BUILD_DIR)
    TEMP_BUILD_DIR.mkdir(parents=True, exist_ok=True)
    
    # 复制前端资源文件
    print_step(2, "复制前端资源文件...")
    
    resources = [
        ("appearance", "appearance/"),
        ("guide", "guide/"),
        ("stage", "stage/"),
        ("changelogs", "changelogs/"),
    ]
    
    for name, path in resources:
        source = NEURALINK_DIR / path
        if source.exists() and source.is_dir():
            dest = TEMP_BUILD_DIR / name
            shutil.copytree(source, dest)
            print(f"   - 已复制 {path}")
        else:
            print(f"   - 跳过 {path} (目录不存在)")
    
    # 确保 assets 目录存在
    ASSETS_DIR.mkdir(parents=True, exist_ok=True)
    
    # 构建 app.zip
    print_step(3, "构建 app.zip...")
    output_zip = ASSETS_DIR / "app.zip"
    
    # 删除旧的 zip 文件
    if output_zip.exists():
        output_zip.unlink()
    
    create_zip(TEMP_BUILD_DIR, output_zip)
    
    # 清理临时目录
    print_step(4, "清理临时目录...")
    shutil.rmtree(TEMP_BUILD_DIR)
    
    # 验证文件是否创建成功
    if output_zip.exists():
        file_size = format_size(output_zip.stat().st_size)
        print_header("构建完成!")
        print(f"文件位置: {output_zip}")
        print(f"文件大小: {file_size}")
        print("\n下一步:")
        print("1. 构建 Go 内核 (如果需要)")
        print("2. 将 kernel.aar 放置到 neu-android/app/libs/")
        print("3. 运行 ./gradlew assembleCnRelease 构建 APK")
    else:
        print("错误: app.zip 构建失败")
        sys.exit(1)


if __name__ == "__main__":
    main()