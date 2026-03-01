# GitHub 新建仓库 + 自动编译 完整步骤

## 第一步：注册/登录 GitHub

打开 https://github.com ，没有账号就注册一个。

---

## 第二步：新建仓库

1. 登录后，点击右上角 **"+"** → **"New repository"**
2. 填写：
   - Repository name: `PayURLHook`
   - 选择 **Public**（免费 Actions 额度更多）
   - **不要勾选** "Add a README file"
   - **不要勾选** ".gitignore"
   - **不要勾选** "License"
3. 点击 **"Create repository"**

---

## 第三步：本地安装 Git（如果没装过）

下载安装：https://git-scm.com/download/win
安装时一路下一步默认即可。

---

## 第四步：推送代码到 GitHub

打开 **命令提示符 (CMD)** 或 **PowerShell**，逐行运行：

```
cd C:\Users\Administrator\Desktop\11122\PayURLHook

git init

git add .

git commit -m "init PayURLHook"

git branch -M main

git remote add origin https://github.com/你的GitHub用户名/PayURLHook.git

git push -u origin main
```

⚠️ 把上面的 `你的GitHub用户名` 换成你真实的 GitHub 用户名！

第一次 push 会弹出 GitHub 登录窗口，登录即可。

---

## 第五步：等待自动编译

1. 打开你的仓库页面：`https://github.com/你的用户名/PayURLHook`
2. 点击顶部 **"Actions"** 标签
3. 你会看到一个正在运行的 workflow（黄色圆圈转圈）
4. 等 2~3 分钟，变成 **绿色 ✓** 就编译成功了

---

## 第六步：下载 .deb 文件

1. 在 Actions 页面，点击那个 **绿色 ✓** 的 workflow run
2. 页面拉到最下面，找到 **Artifacts** 区域
3. 点击 **"PayURLHook-deb"** 下载
4. 解压 zip，里面就是 `.deb` 文件

---

## 第七步：安装到越狱 iPhone

### 方式 A：用 Filza（推荐）
1. 把 .deb 文件传到手机（AirDrop / 微信 / Safari下载）
2. 用 Filza 打开 .deb 文件
3. 点右上角 **"安装"**
4. 安装完成后 **注销 SpringBoard**

### 方式 B：用 SSH
```bash
# 电脑上运行，把 deb 传到手机
scp packages/PayURLHook.deb root@手机IP:/var/mobile/

# SSH 到手机安装
ssh root@手机IP
dpkg -i /var/mobile/PayURLHook.deb
killall -9 SpringBoard
```

---

## 验证是否生效

安装后，打开任意 App（如淘宝、美团等），选择微信支付或支付宝支付。
跳转时 URL 会自动保存到：

```
/var/mobile/Documents/PayURLHook/pay_urls.log
```

用 Filza 导航到这个路径查看日志文件。
