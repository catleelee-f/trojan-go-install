#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}   Trojan-Go 卸载脚本${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}[错误] 请使用 root 用户运行此脚本${NC}"
   exit 1
fi

echo -e "${YELLOW}[*] 停止服务...${NC}"
systemctl stop trojan-go 2>/dev/null || true
systemctl disable trojan-go 2>/dev/null || true

echo -e "${YELLOW}[*] 删除服务...${NC}"
rm -f /etc/systemd/system/trojan-go.service
systemctl daemon-reload

echo -e "${YELLOW}[*] 删除程序...${NC}"
rm -f /usr/local/bin/trojan-go

echo -e "${YELLOW}[*] 删除配置...${NC}"
rm -rf /etc/trojan-go

echo -e "${YELLOW}[*] 删除证书...${NC}"
/root/.acme.sh/acme.sh --remove --domain all 2>/dev/null || true
rm -rf /root/.acme.sh

echo -e "${YELLOW}[*] 恢复 SSH 配置...${NC}"
if [[ -f /etc/ssh/sshd_config.bak ]]; then
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    systemctl restart sshd
    echo -e "${GREEN}[*] SSH 配置已恢复${NC}"
fi

echo -e "${YELLOW}[*] 关闭防火墙...${NC}"
ufw disable 2>/dev/null || true

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}   卸载完成！${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${YELLOW}请手动重启 SSH 服务: systemctl restart sshd${NC}"