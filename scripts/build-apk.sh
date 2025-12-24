#!/bin/bash
# 灵枢笔记 Android APK 一键构建脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${GREEN}"
    echo "================================"
    echo "$1"
    echo "================================"
    echo -e "${NC}"
}

print_step() {
    echo -e "${YELLOW}[步骤]${NC} $1"
}

print_error() {
    echo -e "${RED}[错误]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[成功]${NC} $1"
}

# 检查环境
print_header "灵枢笔记 Android APK 构建"

print_step "检查构建环境..."

# 检查 JAVA_HOME
if [ -z "$JAVA_HOME" ] && [ -z "$ANDROID_HOME" ]; then
    print_error "未检测到构建环境"
    echo ""
    echo "请先运行安装脚本："
    echo "  ./scripts/setup-build-env.sh"
    echo ""
    echo "然后使环境变量生效："
    echo "  source ~/.bashrc"
    exit 1
fi

cd "$PROJECT_DIR"

# 构建前端资源
print_step "构建前端资源..."
if [ -f "scripts/build-frontend.py" ]; then
    python3 scripts/build-frontend.py
else
    print_error "未找到 build-frontend.py 脚本"
    exit 1
fi

# 配置签名（如果需要）
if [ ! -f "signings.gradle" ]; then
    print_step "创建调试签名配置..."
    cat > signings.gradle << 'EOF'
android {
    signingConfigs {
        siyuanConfig {
            storeFile file("app/debug.keystore")
            storePassword "android"
            keyAlias "androiddebugkey"
            keyPassword "android"
        }
    }
}
EOF
    
    # 创建 debug keystore
    keytool -genkey -v -keystore app/debug.keystore -alias androiddebugkey \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -storepass android -keypass android \
        -dname "CN=Android Debug,O=Android,C=US" 2>/dev/null
    
    print_success "调试签名已创建"
fi

# 选择构建类型
echo ""
echo "请选择构建类型："
echo "  1. Debug (调试版本，快速构建)"
echo "  2. Release (发布版本)"
echo ""
read -p "请输入选择 (1/2): " build_choice

case $build_choice in
    1)
        BUILD_TYPE="Debug"
        BUILD_TASK="assembleCnDebug"
        ;;
    2)
        BUILD_TYPE="Release"
        BUILD_TASK="assembleCnRelease"
        ;;
    *)
        print_error "无效选择"
        exit 1
        ;;
esac

# 构建 APK
print_step "构建 $BUILD_TYPE APK..."
./gradlew clean "$BUILD_TASK" --stacktrace

# 查找生成的 APK
APK_DIR="$PROJECT_DIR/app/build/outputs/apk/cn/$(echo "$BUILD_TYPE" | tr '[:upper:]' '[:lower:]')"

if [ -d "$APK_DIR" ]; then
    APK_FILE=$(find "$APK_DIR" -name "*.apk" -type f | head -n 1)
    
    if [ -n "$APK_FILE" ]; then
        print_header "构建完成！"
        echo ""
        print_success "APK 位置: $APK_FILE"
        echo ""
        # 获取文件大小
        APK_SIZE=$(du -h "$APK_FILE" | cut -f1)
        echo "文件大小: $APK_SIZE"
        echo ""
        echo "安装到设备："
        echo "  adb install -r \"$APK_FILE\""
        echo ""
        
        # 创建输出目录
        OUTPUT_DIR="$PROJECT_DIR/build-output"
        mkdir -p "$OUTPUT_DIR"
        cp "$APK_FILE" "$OUTPUT_DIR/"
        print_success "APK 已复制到: $OUTPUT_DIR/"
    else
        print_error "未找到生成的 APK 文件"
        exit 1
    fi
else
    print_error "构建输出目录不存在: $APK_DIR"
    exit 1
fi