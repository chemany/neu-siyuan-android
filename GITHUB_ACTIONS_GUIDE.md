# 灵枢笔记 Android APK - GitHub Actions 自动构建指南

## 概述

使用 GitHub Actions 免费构建 Android APK，无需在本地安装任何构建工具。

## 前置准备

### 1. 创建 GitHub 仓库

```bash
# 在 neu-android 目录初始化 git
cd /root/code/neu-android
git init

# 添加所有文件
git add .
git commit -m "初始化灵枢笔记 Android 项目"
```

### 2. 关联 NeuraLink-Notes 仓库

由于 GitHub Actions 需要访问 NeuraLink-Notes 的前端资源，有两种方式：

**方式 A：将两个仓库合并**
- 将 NeuraLink-Notes 作为子模块添加到 neu-android

**方式 B：在 VPS 上预构建前端资源**
```bash
# 在 VPS 上构建 app.zip
python3 scripts/build-frontend.py

# 将 app.zip 提交到仓库
git add app/src/main/assets/app.zip
git commit -m "添加前端资源"
```

### 3. 修改工作流文件

编辑 [`.github/workflows/build-apk.yml`](.github/workflows/build-apk.yml)，修改以下内容：

```yaml
# 第 30-32 行，修改 NeuraLink-Notes 仓库地址
- name: 获取 NeuraLink-Notes 前端资源
  run: |
    git clone --depth 1 https://github.com/YOUR_USERNAME/YOUR_REPO.git ../NeuraLink-Notes
```

如果使用预构建的 app.zip，可以删除这一步。

### 4. 推送到 GitHub

```bash
# 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/neu-android.git

# 推送代码
git push -u origin main
```

## 使用方法

### 方法 1：自动触发（推送代码）

每次推送到 main 分支时，自动构建 Debug APK：

```bash
git push origin main
```

### 方法 2：手动触发

1. 访问 GitHub 仓库页面
2. 点击 "Actions" 标签
3. 选择 "Build 灵枢笔记 Android APK" 工作流
4. 点击 "Run workflow"
5. 选择构建类型（debug/release）

## 下载 APK

### 从 Actions 下载

1. 访问仓库的 "Actions" 页面
2. 点击对应的工作流运行记录
3. 在 "Artifacts" 部分下载 APK 文件

### 从 Releases 下载（仅 Release 版本）

1. 访问仓库的 "Releases" 页面
2. 下载对应版本的 APK

## 工作流配置说明

### 构建类型

| 类型 | 用途 | 签名 |
|------|------|------|
| Debug | 开发测试 | Debug 签名 |
| Release | 正式发布 | 需配置正式签名 |

### 构建渠道

| 渠道 | 命令 | 市场 |
|------|------|------|
| cn | `assembleCnRelease` | 国内应用商店 |
| googleplay | `bundleGoogleplayRelease` | Google Play |
| huawei | `bundleHuaweiRelease` | 华为应用市场 |
| official | `assembleOfficialRelease` | 官方分发 |

## 高级配置

### 配置正式签名

1. 在 GitHub 仓库设置中添加 Secrets：
   - `KEYSTORE_FILE`: Base64 编码的 keystore 文件
   - `KEYSTORE_PASSWORD`: keystore 密码
   - `KEY_ALIAS`: 密钥别名
   - `KEY_PASSWORD`: 密钥密码

2. 修改工作流文件使用正式签名

### 自动发布到 Release

修改工作流文件第 96-104 行，配置自动发布：

```yaml
- name: 创建 Release
  if: success() && github.event.inputs.build_type == 'release'
  uses: softprops/action-gh-release@v1
  with:
    tag_name: v${{ github.run_number }}
    name: 灵枢笔记 v${{ github.run_number }}
    draft: false
    prerelease: false
    files: app/build/outputs/apk/cn/release/*.apk
```

## 常见问题

### Q: 构建失败怎么办？

1. 检查 "Actions" 页面的详细日志
2. 确认 NeuraLink-Notes 仓库地址正确
3. 确认前端资源已正确构建

### Q: 如何修改应用图标？

替换 `app/src/main/res/mipmap-*` 目录下的图标文件。

### Q: 如何保留在 VPS 上运行？

这是推荐的架构：
- **VPS**：运行 NeuraLink-Notes 网络服务（提供 API）
- **GitHub Actions**：构建 Android APK
- **APK**：内置配置指向 VPS 服务器

## 目录结构

```
neu-android/
├── .github/
│   └── workflows/
│       └── build-apk.yml          # GitHub Actions 配置
├── app/
│   ├── src/main/
│   │   ├── assets/
│   │   │   └── app.zip            # 前端资源（可预构建）
│   │   └── res/
│   │       └── mipmap-*/          # 应用图标
│   └── build.gradle               # 构建配置
├── scripts/
│   └── build-frontend.py          # 前端构建脚本
├── flavors.gradle                 # 渠道配置
├── BUILD_GUIDE.md                 # 本地构建指南
└── GITHUB_ACTIONS_GUIDE.md        # 本文档
```

## 优势

| 特性 | GitHub Actions | 本地构建 |
|------|----------------|----------|
| 磁盘占用 | 0 MB | ~5 GB |
| 配置时间 | 5 分钟 | 1-2 小时 |
| 构建速度 | 中等 | 快 |
| 自动化 | 是 | 否 |
| 成本 | 免费 | 无 |