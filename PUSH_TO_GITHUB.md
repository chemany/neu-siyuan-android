# 推送到 GitHub 指南

## 当前状态

- Git 仓库已初始化
- 分支已重命名为 `main`
- 代码已提交

## 下一步操作

### 1. 在 GitHub 上创建仓库

1. 访问 https://github.com/new
2. 仓库名称填写：`neu-siyuan-android`
3. 设置为 Public 或 Private
4. **不要**勾选 "Add a README file"
5. 点击 "Create repository"

### 2. 获取您的实际 GitHub 用户名

替换下面命令中的 `YOUR_USERNAME` 为您的实际用户名：

```bash
cd /root/code/neu-android
git remote set-url origin https://github.com/chemany/neu-siyuan-android.git
```

### 3. 推送到 GitHub

```bash
cd /root/code/neu-android
git push -u origin main
```

## 验证

推送成功后，访问：
```
https://github.com/chemany/neu-siyuan-android
```

您应该能看到所有项目文件。

## 在本地 Linux 服务器上克隆

```bash
git clone https://github.com/chemanyE/neu-siyuan-android.git
cd neu-siyuan-android
./scripts/setup-build-env.sh
source ~/.bashrc
./scripts/build-apk.sh