# PayURLHook 编译指南 (Windows)

## 第一步：安装 WSL

以管理员身份打开 PowerShell，运行：

```powershell
wsl --install -d Ubuntu
```

安装完成后重启电脑，打开 Ubuntu 终端，设置用户名和密码。

---

## 第二步：在 WSL 中安装依赖

打开 Ubuntu 终端，逐行运行：

```bash
sudo apt update
sudo apt install -y git make perl curl fakeroot libz-dev
```

---

## 第三步：安装 Theos

```bash
# 设置环境变量
echo 'export THEOS=~/theos' >> ~/.bashrc
echo 'export PATH=$THEOS/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 克隆 Theos
git clone --recursive https://github.com/theos/theos.git $THEOS

# 下载 iOS SDK (14.5)
curl -LO https://github.com/theos/sdks/archive/master.zip
unzip master.zip
mv sdks-master/*.sdk $THEOS/sdks/
rm -rf sdks-master master.zip

# 安装 iOS 工具链
$THEOS/bin/update-theos
```

---

## 第四步：编译项目

```bash
# 进入项目目录 (Windows路径自动挂载在 /mnt/ 下)
cd /mnt/c/Users/Administrator/Desktop/11122/PayURLHook

# 编译
make

# 打包 deb
make package
```

编译成功后，`.deb` 文件在 `packages/` 目录下。

---

## 第五步：安装到手机

### 方式1：通过 SSH

```bash
# 设置设备IP
export THEOS_DEVICE_IP=192.168.x.x

# 一键编译+安装
make package install
```

### 方式2：手动安装

1. 把 `packages/` 下的 `.deb` 文件传到手机
2. 用 Filza 打开 .deb 文件安装
3. 注销 SpringBoard

---

## 日志查看

安装后，在任意 App 中选择微信/支付宝支付，跳转URL会保存到：

```
/var/mobile/Documents/PayURLHook/pay_urls.log
```

用 Filza 或 SSH 查看：
```bash
cat /var/mobile/Documents/PayURLHook/pay_urls.log
```
