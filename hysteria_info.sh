#!/bin/bash

# Hysteria2 Server Status and Info Script
# Run as root if config permissions require it: sudo bash this_script.sh
# Checks if server is running, extracts config info, and generates proxy URL.

# Check if hysteria-server is running
STATUS=$(systemctl is-active hysteria-server.service 2>/dev/null)
if [ "$STATUS" != "active" ]; then
  echo "Hysteria server is not running."
  exit 1
fi

echo "Hysteria server is running."

# Config file path
CONFIG="/etc/hysteria/config.yaml"

if [ ! -f "$CONFIG" ]; then
  echo "Config file not found at $CONFIG."
  exit 1
fi

# Extract port (listen: :443 -> 443)
PORT=$(grep '^listen:' "$CONFIG" | awk -F: '{print $3}' | tr -d ' ')

# Extract password
PASSWORD=$(grep '^  password:' "$CONFIG" | awk '{print $2}' | tr -d ' ')

# Extract masquerade URL if present
MASQ_URL=$(grep '^    url:' "$CONFIG" | awk '{print $2}' | tr -d ' ')

# Determine cert type and SNI
if grep -q '^acme:' "$CONFIG"; then
  CERT_TYPE="ACME"
  DOMAIN=$(grep '^    - ' "$CONFIG" | awk '{print $2}' | tr -d ' ')
  SNI="$DOMAIN"
  INSECURE=0
  HOST="$DOMAIN"
else
  CERT_TYPE="Self-signed"
  CERT_PATH=$(grep '^  cert:' "$CONFIG" | awk '{print $2}' | tr -d ' ')
  if [ -f "$CERT_PATH" ]; then
    SNI=$(openssl x509 -in "$CERT_PATH" -noout -subject | sed 's/.*CN = //' | tr -d ' ')
  else
    SNI="unknown"
  fi
  INSECURE=1
  # Get public IP (prefer IPv6 if available)
  IPV6=$(curl -s -6 ifconfig.co 2>/dev/null)
  if [ -n "$IPV6" ]; then
    HOST="[$IPV6]"
  else
    IPV4=$(curl -s -4 ifconfig.co 2>/dev/null)
    HOST="$IPV4"
  fi
fi

# Print basic information
echo "Basic Proxy Information:"
echo "-------------------------"
echo "Certificate Type: $CERT_TYPE"
echo "Listen Port: $PORT"
echo "Authentication Password: $PASSWORD"
echo "SNI: $SNI"
echo "Masquerade URL: ${MASQ_URL:-Not set}"
echo "Host: $HOST"
echo "Insecure: $INSECURE"

# Generate proxy URL
PROXY_URL="hysteria2://${PASSWORD}@${HOST}:${PORT}?sni=${SNI}&insecure=${INSECURE}#Hysteria2"

echo "Generated Proxy URL:"
echo "$PROXY_URL"