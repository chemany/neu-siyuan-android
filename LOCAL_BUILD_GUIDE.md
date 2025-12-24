# 灵枢笔记 Android APK - 本地 Linux 服务器构建指南

## 概述

在本地 Linux 服务器上构建 Android APK，无需依赖 GitHub Actions。

## 前置要求

### 硬件要求
- CPU: 4 核心以上推荐
- 内存: 8GB 以上推荐
- 磁盘: 10GB 可用空间

### 软件要求

| 软件 | 版本 | 用途 |
|------|------|------|
| JDK | 17 | Android 构建 |
| Android SDK | 最新 | Android 开发工具 |
| Go | 1.21+ | 构建内核（可选） |
| Python | 3.x | 构建前端资源 |
| git | 任意 | 版本控制 |

## 快速安装脚本

创建 [`scripts/setup-build-env.sh`](scripts/setup-build-env.sh)：

```bash
#!/bin/bash
# 灵枢笔记 Android 构建环境安装脚本

set -e

echo "================================"
echo "灵枢笔记 Android 构建环境安装"
echo "================================"

# 检测系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测系统类型"
    exit 1
fi

echo "检测到系统: $OS"

# 安装 JDK 17
echo "1. 安装 JDK 17..."
if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    sudo apt update
    sudo apt install -y openjdk-17-jdk
    
    # 设置 JAVA_HOME
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]]; then
    sudo yum install -y java-17-openjdk-devel
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
elif [[ "$OS" == "arch" ]]; then
    sudo pacman -S --noconfirm jdk17-openjdk
fi

source ~/.bashrc
java -version

# 安装 Android SDK
echo "2. 安装 Android SDK..."
ANDROID_SDK_ROOT="$HOME/Android/Sdk"
mkdir -p "$ANDROID_SDK_ROOT"

# 下载 commandlinetools
cd /tmp
wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q commandlinetools-linux-11076708_latest.zip
mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools/latest"
mv cmdline-tools/* "$ANDROID_SDK_ROOT/cmdline-tools/latest/"

# 设置环境变量
echo "export ANDROID_HOME=$ANDROID_SDK_ROOT" >> ~/.bashrc
echo "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/platform-tools:$PATH' >> ~/.bashrc
source ~/.bashrc

# 接受许可证
yes | sdkmanager --licenses

# 安装必需的 SDK 包
echo "3. 安装 Android SDK 包..."
sdkmanager "platform-tools"
sdkmanager "platforms;android-36"
sdkmanager "build-tools;34.0.0"
sdkmanager "ndk;26.1.10909125"

# 安装 Python（如果没有）
echo "4. 检查 Python..."
if ! command -v python3 &> /dev/null; then
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt install -y python3 python3-pip
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]]; then
        sudo yum install -y python3 python3-pip
    elif [[ "$OS" == "arch" ]]; then
        sudo pacman -S --noconfirm python python-pip
    fi
fi

python3 --version

echo ""
echo "================================"
echo "安装完成！"
echo "================================"
echo "请运行以下命令使环境变量生效："
echo "  source ~/.bashrc"
echo ""
echo "然后运行构建脚本："
echo "  ./scripts/build-apk.sh"
```

## 一键构建脚本

创建 [`scripts/build-apk.sh`](scripts/build-apk.sh)：

```bash
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
if [ -z "$JAVA_HOME" ]; then
    print_error "JAVA_HOME 未设置，请先运行 setup-build-env.sh"
    exit 1
fi

# 检查 Android SDK
if [ -z "$ANDROID_HOME" ]; then
    print_error "ANDROID_HOME 未设置，请先运行 setup-build-env.sh"
    exit 1
fi

# 检查 kernel.aar
if [ ! -f "$PROJECT_DIR/app/libs/kernel.aar" ]; then
    print_error "缺少 kernel.aar 文件"
    echo ""
    echo "请从以下选项中选择："
    echo "  1. 从 NeuraLink-Notes 构建 Go 内核"
    echo "  2. 从官方思源笔记获取"
    echo ""
    read -p "是否继续使用 Debug 模式构建（需要修改配置）？(y/n): " continue_build
    if [ "$continue_build" != "y" ]; then
        exit 1
    fi
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
        -dname "CN=Android Debug,O=Android,C=US"
    
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
```

## 使用步骤

### 1. 在本地 Linux 服务器上安装构建环境

```bash
# 上传 neu-android 目录到服务器
scp -r neu-android user@your-server:/home/user/

# SSH 登录服务器
ssh user@your-server

# 进入项目目录
cd neu-android

# 运行安装脚本
chmod +x scripts/setup-build-env.sh
./scripts/setup-build-env.sh

# 使环境变量生效
source ~/.bashrc
```

### 2. 构建 APK

```bash
# 方法 1：使用一键构建脚本
chmod +x scripts/build-apk.sh
./scripts/build-apk.sh

# 方法 2：手动构建
./gradlew assembleCnDebug
```

### 3. 从服务器下载 APK

```bash
# 在本地机器上执行
scp user@your-server:/home/user/neu-android/build-output/*.apk ./
```

## 高级配置

### 配置正式签名

1. 创建 keystore：
```bash
keytool -genkey -v -keystore release.keystore \
  -alias your-key-alias -keyalg RSA -keysize 2048 \
  -validity 10000
```

2. 修改 `signings.gradle`：
```gradle
android {
    signingConfigs {
        siyuanConfig {
            storeFile file("release.keystore")
            storePassword "your-store-password"
            keyAlias "your-key-alias"
            keyPassword "your-key-password"
        }
    }
}
```

### 获取 kernel.aar

**选项 A：从官方构建获取**
```bash
# 下载官方思源笔记 APK
# 解压提取 libsiyuan.so
# 使用 gomobile 重新打包
```

**选项 B：从 NeuraLink-Notes 构建**
```bash
cd NeuraLink-Notes/kernel
gomobile bind -o ../neu-android/app/libs/kernel.aar \
  -target=android/arm64 -androidapi 26
```

## 自动化构建

### 使用 cron 定时构建

```bash
# 编辑 crontab
crontab -e

# 每天凌晨 2 点自动构建
0 2 * * * cd /home/user/neu-android && ./scripts/build-apk.sh >> build.log 2>&1
```

### 使用 webhook 触发构建

安装 webhook 服务：
```bash
# 安装 webhook
pip3 install webhook

# 创建 webhook 配置
cat > webhook.json << EOF
[
  {
    "id": "build-apk",
    "execute-command": "/home/user/neu-android/scripts/build-apk.sh",
    "command-working-directory": "/home/user/neu-android"
  }
]
EOF

# 启动 webhook
webhook -hooks webhook.json -verbose
```

## 故障排除

### 问题 1：Gradle 构建失败

```bash
# 清理缓存
./gradlew clean

# 重新构建
./gradlew assembleCnDebug --stacktrace
```

### 问题 2：SDK 包找不到

```bash
# 手动安装 SDK 包
sdkmanager --list
sdkmanager "platforms;android-36"
```

### 问题 3：内存不足

```bash
# 修改 gradle.properties
echo "org.gradle.jvmargs=-Xmx4096m" >> gradle.properties
```

## 目录结构

```
neu-android/
├── scripts/
│   ├── setup-build-env.sh    # 环境安装脚本
│   ├── build-apk.sh           # 一键构建脚本
│   └── build-frontend.py      # 前端构建脚本
├── app/
│   ├── src/main/
│   │   └── assets/
│   │       └── app.zip        # 前端资源
│   └── libs/
│       └── kernel.aar         # Go 内核（需添加）
├── build-output/              # APK 输出目录
│   └── *.apk
├── LOCAL_BUILD_GUIDE.md       # 本文档
└── GITHUB_ACTIONS_GUIDE.md    # GitHub Actions 指南
```

## 对比：本地构建 vs GitHub Actions

| 特性 | 本地构建 | GitHub Actions |
|------|----------|----------------|
| 速度 | 快 | 中等 |
| 隐私 | 完全私有 | 代码公开（私有仓库需付费） |
| 成本 | 免费 | 免费 |
| 磁盘占用 | ~5GB | 0GB（在 VPS 上） |
| 自动化 | 需自己配置 | 内置支持 |
| 维护 | 需自己维护 | GitHub 维护 |