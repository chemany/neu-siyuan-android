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
    sudo apt install -y openjdk-17-jdk unzip wget
    
    # 设置 JAVA_HOME
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]]; then
    sudo yum install -y java-17-openjdk-devel unzip wget
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk' >> ~/.bashrc
    echo 'export PATH=$JAVA_HOME/bin:$PATH' >> ~/.bashrc
elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
    sudo pacman -S --noconfirm jdk17-openjdk unzip wget
fi

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
java -version

# 安装 Android SDK
echo "2. 安装 Android SDK..."
ANDROID_SDK_ROOT="$HOME/Android/Sdk"
mkdir -p "$ANDROID_SDK_ROOT"

# 下载 commandlinetools
cd /tmp
wget -q https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip -q commandlinetools-linux-11076708_latest.zip
mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools/latest"
mv cmdline-tools/* "$ANDROID_SDK_ROOT/cmdline-tools/latest/"
rm commandlinetools-linux-11076708_latest.zip

# 设置环境变量
echo "export ANDROID_HOME=$ANDROID_SDK_ROOT" >> ~/.bashrc
echo "export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH' >> ~/.bashrc
echo 'export PATH=$ANDROID_HOME/platform-tools:$PATH' >> ~/.bashrc

export ANDROID_HOME=$ANDROID_SDK_ROOT
export ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
export PATH=$ANDROID_HOME/platform-tools:$PATH

# 接受许可证
yes | sdkmanager --licenses 2>/dev/null || true

# 安装必需的 SDK 包
echo "3. 安装 Android SDK 包..."
sdkmanager "platform-tools" 2>/dev/null || true
sdkmanager "platforms;android-36" 2>/dev/null || true
sdkmanager "build-tools;34.0.0" 2>/dev/null || true

# 检查 Python
echo "4. 检查 Python..."
if ! command -v python3 &> /dev/null; then
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        sudo apt install -y python3
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]]; then
        sudo yum install -y python3
    elif [[ "$OS" == "arch" ]] || [[ "$OS" == "manjaro" ]]; then
        sudo pacman -S --noconfirm python
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
echo "或者注销后重新登录"