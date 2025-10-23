#!/bin/bash

# Hysteria2 Server One-Click Deployment Script for Debian 11+
# Based on tutorial from https://playlab.eu.org/archives/hysteria2
# Run as root: sudo bash this_script.sh
# This script allows interactive choice between self-signed and ACME certificates.
# For ACME, it prompts for domain and email; assumes domain is resolved to server IP.
# It will prompt for other configurations like password, masquerade URL, and port.

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Check Debian version
DEB_VERSION=$(lsb_release -rs)
if [ 1 -eq "$(echo "${DEB_VERSION} < 11" | bc)" ]; then
  echo "This script requires Debian 11 or higher. Current version: ${DEB_VERSION}"
  exit 1
fi

# Update system and install prerequisites
apt update && apt upgrade -y
apt install -y curl openssl nano lsb-release bc

# Install Hysteria2 using official script
bash <(curl -fsSL https://get.hy2.sh/)

# Enable auto-start
systemctl enable hysteria-server.service

# Prompt for certificate type
read -p "Choose certificate type (acme or self-signed, default: self-signed): " CERT_TYPE
CERT_TYPE=${CERT_TYPE:-self-signed}

# Common prompts
read -p "Enter authentication password (default: 123456): " AUTH_PASSWORD
AUTH_PASSWORD=${AUTH_PASSWORD:-123456}

read -p "Enter masquerade URL (default: https://cn.bing.com/): " MASQ_URL
MASQ_URL=${MASQ_URL:-https://cn.bing.com/}

read -p "Enter listen port (default: 443): " LISTEN_PORT
LISTEN_PORT=${LISTEN_PORT:-443}

# Certificate-specific logic
if [ "$CERT_TYPE" == "acme" ]; then
  read -p "Enter domain (must be resolved to this server's IP): " DOMAIN
  if [ -z "$DOMAIN" ]; then
    echo "Domain is required for ACME."
    exit 1
  fi
  read -p "Enter email for ACME: " EMAIL
  if [ -z "$EMAIL" ]; then
    echo "Email is required for ACME."
    exit 1
  fi

  # ACME config section
  CERT_CONFIG=$(cat << EOF
acme:
  domains:
    - $DOMAIN
  email: $EMAIL
EOF
)


else
  # Default to self-signed
  read -p "Enter CN for self-signed cert (default: bing.com): " CERT_CN
  CERT_CN=${CERT_CN:-bing.com}

  # Generate self-signed certificate
  openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=${CERT_CN}" -days 3650
  chown hysteria /etc/hysteria/server.key
  chown hysteria /etc/hysteria/server.crt

  # TLS config section
  CERT_CONFIG=$(cat << EOF
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
EOF
)
fi

# Create config.yaml
cat > /etc/hysteria/config.yaml << EOF
listen: :${LISTEN_PORT}

${CERT_CONFIG}

auth:
  type: password
  password: ${AUTH_PASSWORD}

resolver:
  type: udp
  tcp:
    addr: 8.8.8.8:53
    timeout: 4s
  udp:
    addr: 8.8.4.4:53
    timeout: 4s
  tls:
    addr: 1.1.1.1:853
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false
  https:
    addr: 1.1.1.1:443
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false

masquerade:
  type: proxy
  proxy:
    url: ${MASQ_URL}
    rewriteHost: true
EOF

# Fix permissions if needed by running as root (as per tutorial)
sed -i '/User=/d' /etc/systemd/system/hysteria-server.service
sed -i '/User=/d' /etc/systemd/system/hysteria-server@.service
systemctl daemon-reload

# Start and restart service
systemctl start hysteria-server.service
systemctl restart hysteria-server.service

# Check status
systemctl status hysteria-server.service



# Performance optimization
sysctl -w net.core.rmem_max=16777216
sysctl -w net.core.wmem_max=16777216

# Make optimizations permanent
echo "net.core.rmem_max=16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max=16777216" >> /etc/sysctl.conf

#Ensure process has enough permission
chown root:root /etc/hysteria/*
chmod 600 /etc/hysteria/server.crt /etc/hysteria/server.key
chmod 644 /etc/hysteria/config.yaml

sysctl -p

echo "Hysteria2 server deployment completed!"
echo "Config file: /etc/hysteria/config.yaml"
echo "Certificate type: ${CERT_TYPE}"
if [ "$CERT_TYPE" == "acme" ]; then
  echo "Hysteria will automatically handle ACME certificate issuance on start."
  echo "Ensure port 80 is accessible for ACME challenges."
fi
echo "Restart service if changes made: systemctl restart hysteria-server.service"