# 灵枢笔记 Android APK 构建指南

## 项目概述

灵枢笔记 (NeuraLink Notes) 是基于思源笔记 (SiYuan) 的 Android 定制版本，集成了 AI、OCR 和向量化等增强功能。

## 已完成的配置

### 1. 品牌定制

| 配置项 | 修改内容 | 文件位置 |
|--------|----------|----------|
| 应用名称（中文） | "灵枢笔记" | [`flavors.gradle`](neu-android/flavors.gradle:26) |
| 应用名称（英文） | "NeuraLink Notes" | [`flavors.gradle`](neu-android/flavors.gradle:32) |
| 应用包名 | `org.neuralink.notes` | [`app/build.gradle`](neu-android/app/build.gradle.gradle:37) |
| APK 文件名 | `neuralink-{version}` | [`app/build.gradle`](neu-android/app/build.gradle.gradle:22) |

### 2. 前端资源集成

- 前端资源已构建并打包为 [`app/src/main/assets/app.zip`](neu-android/app/src/main/assets/app.zip)
- 文件大小：45.3 MB
- 包含：appearance、stage 目录及所有前端静态资源

### 3. 构建脚本

| 脚本 | 用途 |
|------|------|
| [`scripts/build-frontend.py`](neu-android/scripts/build-frontend.py) | Python 前端资源构建脚本 |

## 构建步骤

### 前置要求

1. **Go 内核 (kernel.aar)**
   - 需要从 NeuraLink-Notes 项目构建 Go 内核
   - 使用 gomobile 编译为 Android AAR 库
   - 放置位置：`neu-android/app/libs/kernel.aar`

2. **开发环境**
   - Android SDK 36
   - JDK 8+
   - Python 3+ (用于构建前端资源)

### 构建流程

```bash
# 1. 构建 Go 内核 (在 NeuraLink-Notes/kernel 目录)
cd NeuraLink-Notes/kernel
gomobile bind -o ../neu-android/app/libs/kernel.aar -target=android/arm64 -androidapi 26

# 2. 构建前端资源 (已在 neu-android 目录完成)
python3 scripts/build-frontend.py

# 3. 配置签名 (如需发布版本)
cp signings.templates.gradle signings.gradle
# 编辑 signings.gradle 配置签名信息

# 4. 构建 APK
./gradlew assembleCnRelease

# 5. 输出位置
# neu-android/app/build-release/neuralink-{version}-all/
```

## 多渠道配置

| 渠道 | 命令 | 说明 |
|------|------|------|
| 国内应用商店 | `assembleCnRelease` | 小米/Vivo/OPPO/荣耀 |
| Google Play | `bundleGoogleplayRelease` | AAB 格式 |
| 华为应用商店 | `bundleHuaweiRelease` | AAB 格式 |
| 官方版本 | `assembleOfficialRelease` | 直接分发 |

## 目录结构

```
neu-android/
├── app/
│   ├── src/main/
│   │   ├── assets/
│   │   │   └── app.zip           # 前端资源包
│   │   ├── java/                 # Java 源代码
│   │   └── res/                  # 资源文件
│   ├── libs/                     # Native 库 (需添加 kernel.aar)
│   └── build.gradle              # 应用构建配置
├── scripts/
│   └── build-frontend.py         # 前端资源构建脚本
├── flavors.gradle                # 多渠道配置 (已修改)
├── buildRelease.gradle           # 发布构建配置
└── signings.templates.gradle     # 签名配置模板
```

## 保留的新功能

灵枢笔记保留了 NeuraLink-Notes 项目中的以下增强功能：

### AI 功能
- 私有大模型集成
- RAG (检索增强生成)
- 流式对话界面

### OCR 功能
- 私有 OCR 服务集成
- 图片文字识别
- PDF 扫描识别

### 向量化功能
- 块级向量化
- 语义搜索

### Web 认证
- JWT Token 认证
- 跨应用单点登录
- 访问码认证

## 注意事项

1. **Go 内核必须编译**：没有 kernel.aar 文件无法构建 APK
2. **签名配置**：发布版本需要配置签名证书
3. **前端资源更新**：修改前端代码后需重新运行 `build-frontend.py`
4. **包名冲突**：与官方思源笔记包名不同，可以共存安装

## 版本信息

- 基于：SiYuan Android 3.5.1
- 版本号：292
- 目标 SDK：36
- 最低 SDK：26

## 联系方式

- 官网：https://www.cheman.top
- 邮箱：125607565@qq.com