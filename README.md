# Trojan-Go 一键安装脚本

安全、稳定、易用的 Trojan-Go 代理搭建脚本，支持 TLS 加密和 Cloudflare CDN 隐藏真实 IP。

## 功能特性

- TLS 1.3 加密流量，难以被识别和阻断
- Cloudflare CDN 隐藏真实 VPS IP，防止被墙
- BBR 拥塞控制，优化弱网环境（高延迟/丢包）
- Nginx HTTP 回退服务器，提升稳定性
- SSH 密钥登录 + 禁用密码，提高安全性
- UFW 防火墙，最小权限原则
- UUID 格式强密码
- 订阅端点鉴权，防止密码泄露
- 一键安装，开机自启

## 系统要求

- Debian 11+ / Ubuntu 20.04+
- 512MB+ 内存
- 域名（已添加到 Cloudflare）
- Cloudflare API Token

## 快速开始

### 方式一：直接下载执行（推荐）

```bash
bash <(curl -sL https://raw.githubusercontent.com/catleelee-f/trojan-go-install/main/install.sh)
```

### 方式二：下载到本地执行

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/catleelee-f/trojan-go-install/main/install.sh
chmod +x install.sh

# 执行安装（交互式输入域名和Token）
sudo ./install.sh
```

## 安装参数

| 参数 | 缩写 | 说明 | 必需 |
|------|------|------|------|
| --domain | -d | 你的域名 | 可交互输入 |
| --token | -t | Cloudflare API Token | 可交互输入 |
| --ssh-port | -s | SSH 端口（默认: 22） | 否 |
| --help | -h | 显示帮助 | 否 |

注意：Trojan 密码会自动生成 UUID，无需手动指定。

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

安装完成后，脚本会输出订阅链接和 Trojan URI。

### 订阅方式（推荐）

安装后会输出订阅链接，格式如：
```
http://你的域名/sub/随机密钥
```

**使用订阅时需要在请求头中设置：**
```
X-Sub-Key: 随机密钥
```

不同的客户端设置方式不同：
- **Quantumult X**: 订阅设置 → 高级 → 添加请求头
- **Shadowrocket**: 订阅设置中支持自定义 Header
- **Stash**: 支持在订阅配置中添加请求头

### Trojan URI 方式

直接复制脚本输出的 URI 导入客户端：
```
trojan://密码@域名:443?sni=域名#备注
```

### 通用客户端配置

```json
{
  "run_type": "client",
  "local_addr": "127.0.0.1",
  "local_port": 1080,
  "remote_addr": "你的域名",
  "remote_port": 443,
  "password": ["你的密码"],
  "ssl": {
    "sni": "你的域名",
    "verify": true
  }
}
```

### 客户端下载

- **Windows**: [Trojan-Go Release](https://github.com/p4gefau1t/trojan-go/releases)
- **Android**: Play Store 搜索 "Trojan-Go"
- **macOS**: [Trojan-QT5](https://github.com/TheWanderingCoel/Trojan-QT5) 或 [ClashX](https://github.com/yichengchen/clashX)
- **iOS**: Shadowrocket / Stash / Quantumult X

## VPS 安装路径

| 文件/配置 | 路径 |
|-----------|------|
| Trojan-Go 程序 | `/usr/local/bin/trojan-go` |
| Trojan-Go 配置 | `/etc/trojan-go/config.json` |
| SSL 证书 | `/etc/trojan-go/cert.pem` |
| SSL 私钥 | `/etc/trojan-go/private.key` |
| Systemd 服务 | `/etc/systemd/system/trojan-go.service` |
| acme.sh | `/root/.acme.sh/` |
| Nginx 站点配置 | `/etc/nginx/sites-available/default` |
| 订阅端点 | `/var/www/html/` |
| 系统日志 | `journalctl -u trojan-go -f` |

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

## 安全特性

本脚本在安全方面做了以下防护：

| 安全措施 | 说明 |
|----------|------|
| `read -r` | 防止命令注入 |
| `mktemp` | 防止临时文件 symlink 攻击 |
| CF Token 文件存储 | Token 不进入环境变量 |
| URL-safe Base64 | 订阅内容安全编码 |
| Nginx 字符串转义 | 防止配置注入 |
| 域名严格验证 | 防止恶意域名 |
| SSH 禁用密码/root | 防止暴力破解 |
| 订阅端点鉴权 | 路径+请求头双重验证 |
| 订阅限速 | 防止资源耗尽攻击 |

## 常见问题

### Q: 安装后无法连接？

1. 检查 Cloudflare 是否开启了 Proxy 模式（橙色云）
2. 检查防火墙是否开放 443 端口: `ufw status`
3. 查看服务状态: `systemctl status trojan-go`
4. 查看日志: `journalctl -u trojan-go -f`

### Q: 443 端口被占用？

脚本会自动检测并尝试停止占用 443 端口的进程。如需手动处理：
```bash
# 查看占用进程
ss -tlnp | grep :443

# 停止进程后重启
systemctl restart trojan-go
```

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

## Cloudflare CDN 说明

开启 CDN 可以：
- 隐藏真实 VPS IP，防止被墙
- 优化跨境路由，降低抖动
- 防止 DDoS 攻击

开启方法：Cloudflare Dashboard → DNS → 点击 DNS 记录旁边的云朵变成橙色。

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
5. **订阅密钥**: 切勿泄露给他人

## 卸载

```bash
# 下载卸载脚本
curl -O https://raw.githubusercontent.com/catleelee-f/trojan-go-install/main/uninstall.sh
chmod +x uninstall.sh
sudo ./uninstall.sh
```

## License

MIT License