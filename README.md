# Trojan-Go 一键安装脚本

安全、稳定、易用的 Trojan-Go 代理搭建脚本，支持 TLS 加密和 Cloudflare CDN 隐藏真实 IP。

## 功能特性

- TLS 1.3 加密流量，难以被识别和阻断
- Cloudflare CDN 隐藏真实 VPS IP，防止被墙
- BBR 拥塞控制，优化弱网环境（高延迟/丢包）
- SSH 密钥登录 + 禁用密码，提高安全性
- UFW 防火墙，最小权限原则
- UUID 格式强密码
- 一键安装，开机自启

## 系统要求

- Debian 11+ / Ubuntu 20.04+
- 512MB+ 内存
- 域名（已添加到 Cloudflare）
- Cloudflare API Token

## 快速开始

### 方式一：直接下载执行（推荐）

```bash
bash <(curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/trojan-go-install/main/install.sh) \
  -d vpn.example.com \
  -t YOUR_CF_TOKEN
```

### 方式二：下载到本地执行

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/trojan-go-install/main/install.sh
chmod +x install.sh

# 执行安装
sudo ./install.sh -d vpn.example.com -t YOUR_CF_TOKEN
```

## 安装参数

| 参数 | 缩写 | 说明 | 必需 |
|------|------|------|------|
| --domain | -d | 你的域名 | 是 |
| --token | -t | Cloudflare API Token | 是 |
| --password | -p | Trojan 密码（留空自动生成） | 否 |
| --ssh-port | -s | SSH 端口（默认: 22） | 否 |
| --help | -h | 显示帮助 | 否 |

## 准备工作

### 1. 添加域名到 Cloudflare

1. 登录 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 添加你的域名，按提示修改 DNS 服务器
3. 等待 DNS 生效

### 2. 创建 Cloudflare API Token

1. 进入 [API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. 点击 "Create Token"
3. 选择 "Edit zone DNS" 模板
4. 设置对应域名权限
5. 创建后复制 Token

### 3. 配置 DNS 记录

1. 在 Cloudflare 添加 A 记录指向 VPS IP
2. **安装期间：关闭 Proxy (仅 DNS)**
3. **安装完成后：开启 Proxy**

## 客户端配置

安装完成后，脚本会输出客户端配置 JSON，示例：

```json
{
  "run_type": "client",
  "local_addr": "127.0.0.1",
  "local_port": 1080,
  "remote_addr": "vpn.example.com",
  "remote_port": 443,
  "password": ["your-password-here"],
  "ssl": {
    "sni": "vpn.example.com",
    "verify": true
  }
}
```

### 客户端下载

- **Windows**: [Trojan-Go Release](https://github.com/p4gefau1t/trojan-go/releases)
- **Android**: Play Store 搜索 "Trojan-Go"
- **macOS**: [Trojan-QT5](https://github.com/TheWanderingCoel/Trojan-QT5) 或 [ClashX](https://github.com/yichengchen/clashX)
- **iOS**: Shadowrocket / Stash

## 常用命令

```bash
# 查看状态
systemctl status trojan-go

# 查看日志
journalctl -u trojan-go -f

# 重启服务
systemctl restart trojan-go

# 停止服务
systemctl stop trojan-go

# 卸载
bash uninstall.sh
```

## 常见问题

### Q: 安装后无法连接？

1. 检查 Cloudflare 是否开启了 Proxy 模式
2. 检查防火墙是否开放 443 端口: `ufw status`
3. 查看服务状态: `systemctl status trojan-go`
4. 查看日志: `journalctl -u trojan-go -f`

### Q: SSH 连接不上？

1. 检查 SSH 端口是否正确（脚本会修改为指定端口）
2. 确保已配置 SSH 密钥登录
3. 通过 VNC 或面板登录检查 SSH 配置

### Q: 如何更换密码？

```bash
# 编辑配置
vim /etc/trojan-go/config.json

# 重启服务
systemctl restart trojan-go
```

## 优化延迟/丢包

脚本已默认启用 BBR 优化。如需进一步优化：

1. **使用 Cloudflare WARP**: 在 VPS 上安装 warp 客户端
2. **选择优质线路**: 优先选择 CN2/BGP 线路 VPS
3. **多节点中转**: 国内外各建节点

## 安全建议

1. **SSH 密钥**: 务必配置 SSH 密钥登录
2. **修改默认端口**: 安装时指定非标准 SSH 端口
3. **定期更新**: 保持系统和 Trojan-Go 最新
4. **启用 Fail2Ban**: 自动封禁暴力破解 IP

## 卸载

```bash
# 下载卸载脚本
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/trojan-go-install/main/uninstall.sh
chmod +x uninstall.sh
sudo ./uninstall.sh
```

## License

MIT License