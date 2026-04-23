#!/bin/bash

set -e

# ==================== 颜色定义 ====================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ==================== 版本信息 ====================
VERSION="1.1.0"

# ==================== 欢迎界面 ====================
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Trojan-Go 一键安装脚本 v${VERSION}${NC}"
echo -e "${BLUE}   适用于 Debian 11+ / Ubuntu 20.04+${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# ==================== 帮助信息 ====================
show_help() {
    echo "用法: bash install.sh [选项]"
    echo ""
    echo "选项:"
    echo "  -d, --domain DOMAIN       设置域名 (可留空交互式输入)"
    echo "  -t, --token TOKEN         Cloudflare API Token (可留空交互式输入)"
    echo "  -p, --password PASSWORD   Trojan 密码 (留空自动生成)"
    echo "  -s, --ssh-port PORT       SSH 端口 (默认: 22)"
    echo "  -h, --help                显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  bash install.sh                                    # 交互式输入"
    echo "  bash install.sh -d vpn.example.com -t YOUR_CF_TOKEN # 命令行参数"
    echo ""
}

# ==================== 参数解析 ====================
DOMAIN=""
CF_TOKEN=""
TROJAN_PASS=""
SSH_PORT="22"

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -t|--token)
            CF_TOKEN="$2"
            shift 2
            ;;
        -p|--password)
            TROJAN_PASS="$2"
            shift 2
            ;;
        -s|--ssh-port)
            SSH_PORT="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# ==================== 检查 root ====================
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[错误] 请使用 root 用户运行此脚本${NC}"
   exit 1
fi

# ==================== 交互式输入 ====================
if [[ -z "$DOMAIN" ]]; then
    echo -e "${YELLOW}[?] 请输入你的域名 (例: vpn.example.com):${NC}"
    read -p "域名: " DOMAIN
fi

if [[ -z "$CF_TOKEN" ]]; then
    echo -e "${YELLOW}[?] 请输入 Cloudflare API Token:${NC}"
    read -p "Token: " CF_TOKEN
fi

# ==================== 再次检查 ====================
if [[ -z "$DOMAIN" ]]; then
    echo -e "${RED}[错误] 域名不能为空${NC}"
    exit 1
fi

if [[ -z "$CF_TOKEN" ]]; then
    echo -e "${RED}[错误] Cloudflare API Token 不能为空${NC}"
    exit 1
fi

# ==================== 生成随机密码 ====================
if [[ -z "$TROJAN_PASS" ]]; then
    TROJAN_PASS=$(cat /proc/sys/kernel/random/uuid)
    echo -e "${GREEN}[*] 已自动生成密码: $TROJAN_PASS${NC}"
fi

# ==================== 系统更新 ====================
echo -e "${GREEN}[1/9] 更新系统...${NC}"
apt update && apt upgrade -y

# ==================== 安装依赖 ====================
echo -e "${GREEN}[2/9] 安装依赖 (nginx, curl, wget, ufw, fail2ban)...${NC}"
apt install -y curl wget vim sudo ufw fail2ban unzip dnsutils nginx

# ==================== SSH 安全加固 ====================
echo -e "${GREEN}[3/9] 配置 SSH 安全...${NC}"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

sed -i "s/#Port 22/Port ${SSH_PORT}/" /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

echo -e "${YELLOW}[*] SSH 已禁用密码登录和 root 登录${NC}"
echo -e "${YELLOW}[*] SSH 端口已改为: ${SSH_PORT}${NC}"

# ==================== 防火墙配置 ====================
echo -e "${GREEN}[4/9] 配置防火墙...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow ${SSH_PORT}/tcp
ufw allow 443/tcp
ufw --force enable

# ==================== 配置 Nginx (Trojan-Go HTTP 回退) ====================
echo -e "${GREEN}[5/9] 配置 Nginx...${NC}"
cat > /etc/nginx/sites-available/default << EOF
server {
    listen 80 default_server;
    server_name ${DOMAIN};
    location / {
        root /var/www/html;
    }
}
EOF
nginx -t && systemctl restart nginx

# ==================== 安装 Trojan-Go ====================
echo -e "${GREEN}[6/9] 下载安装 Trojan-Go...${NC}"
cd /tmp
TROJAN_VER="v0.10.6"
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        ARCH_STR="amd64"
        ;;
    aarch64)
        ARCH_STR="arm64"
        ;;
    armv7l)
        ARCH_STR="armv7"
        ;;
    *)
        ARCH_STR="amd64"
        ;;
esac

TROJAN_URL="https://github.com/p4gefau1t/trojan-go/releases/download/${TROJAN_VER}/trojan-go-linux-${ARCH_STR}.zip"

echo -e "${YELLOW}[*] 下载: $TROJAN_URL${NC}"
wget -q --show-progress "$TROJAN_URL" -O trojan-go.zip
unzip -o trojan-go.zip
mv trojan-go /usr/local/bin/trojan-go
chmod +x /usr/local/bin/trojan-go
mkdir -p /etc/trojan-go

# ==================== 安装 acme.sh 并注册邮箱 ====================
echo -e "${GREEN}[7/9] 安装 acme.sh...${NC}"
curl -s https://get.acme.sh | sh

# 注册邮箱 (ZeroSSL 需要)
echo -e "${GREEN}[*] 注册 acme.sh 账号...${NC}"
/root/.acme.sh/acme.sh --register-account -m "admin@${DOMAIN}"

# ==================== 申请 SSL 证书 ====================
echo -e "${GREEN}[8/9] 申请 SSL 证书 for $DOMAIN ...${NC}"
export CF_Token="$CF_TOKEN"
/root/.acme.sh/acme.sh --issue --dns dns_cf -d "$DOMAIN" --force

# ==================== 安装证书 ====================
echo -e "${GREEN}[*] 安装证书...${NC}"
/root/.acme.sh/acme.sh --install-cert -d "$DOMAIN" \
    --key-file /etc/trojan-go/private.key \
    --fullchain-file /etc/trojan-go/cert.pem

# ==================== 配置 Trojan-Go ====================
echo -e "${GREEN}[9/9] 配置 Trojan-Go...${NC}"
cat > /etc/trojan-go/config.json << EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": ["$TROJAN_PASS"],
    "ssl": {
        "cert": "/etc/trojan-go/cert.pem",
        "key": "/etc/trojan-go/private.key",
        "sni": "$DOMAIN"
    }
}
EOF

# ==================== 启用 BBR ====================
echo -e "${GREEN}[*] 启用 BBR 优化...${NC}"
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# ==================== 创建 Systemd 服务 ====================
echo -e "${GREEN}[*] 创建系统服务...${NC}"
cat > /etc/systemd/system/trojan-go.service << EOF
[Unit]
Description=Trojan-Go
After=network.target

[Service]
ExecStart=/usr/local/bin/trojan-go -config /etc/trojan-go/config.json
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable trojan-go

# ==================== 检查 443 端口是否被占用 ====================
if ss -tlnp | grep -q ':443'; then
    echo -e "${YELLOW}[警告] 443 端口已被占用，尝试停止占用进程...${NC}"
    SS_OUTPUT=$(ss -tlnp | grep ':443')
    PID=$(echo "$SS_OUTPUT" | grep -oP 'pid=\K[0-9]+' | head -1)
    if [[ -n "$PID" ]]; then
        PROC_NAME=$(ps -p "$PID" -o comm= 2>/dev/null || echo "unknown")
        echo -e "${YELLOW}[*] 占用 443 的进程: $PROC_NAME (PID: $PID)${NC}"
        kill "$PID" 2>/dev/null || true
        sleep 1
    fi
fi

systemctl start trojan-go

# ==================== 检查服务状态 ====================
sleep 2
if systemctl is-active --quiet trojan-go; then
    STATUS="${GREEN}运行中${NC}"
else
    STATUS="${RED}启动失败${NC}"
    echo -e "${YELLOW}[*] 查看日志排查: journalctl -u trojan-go -n 20${NC}"
fi

# ==================== 安装完成 ====================
echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   安装完成！${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}【配置信息】${NC}"
echo -e "  域名:   ${GREEN}$DOMAIN${NC}"
echo -e "  密码:   ${GREEN}$TROJAN_PASS${NC}"
echo -e "  端口:   ${GREEN}443${NC}"
echo -e "  状态:   $STATUS"
echo ""
echo -e "${YELLOW}【Trojan URI (导入客户端)】${NC}"
echo -e "${GREEN}trojan://$TROJAN_PASS@$DOMAIN:443?sni=$DOMAIN#$DOMAIN${NC}"
echo ""
echo -e "${YELLOW}【Quantumult X 配置】${NC}"
echo -e "trojan://$TROJAN_PASS@$DOMAIN:443?sni=$DOMAIN#$DOMAIN"
echo ""
echo -e "${RED}【请手动完成以下步骤】${NC}"
echo -e "${RED}1. 在 Cloudflare 开启 Proxy 模式 (DNS -> 橙色云)${NC}"
echo -e "${RED}2. SSH 端口已改为 ${SSH_PORT}，确保你有密钥登录${NC}"
echo ""
echo -e "${GREEN}查看状态: systemctl status trojan-go${NC}"
echo -e "${GREEN}查看日志: journalctl -u trojan-go -f${NC}"
echo -e "${GREEN}重启服务: systemctl restart trojan-go${NC}"