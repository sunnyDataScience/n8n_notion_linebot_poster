#!/usr/bin/env bash
set -e

echo "========================================"
echo "  n8n Docker"
echo "========================================"
echo ""

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
CERT_DIR="$ROOT_DIR/docker/nginx/certs"

# Check if openssl is available, install if not
if ! command -v openssl &>/dev/null; then
    echo "[INFO] OpenSSL not found. Installing..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y openssl
    elif command -v brew &>/dev/null; then
        brew install openssl
    else
        echo "[ERROR] Cannot install OpenSSL automatically. Please install it manually."
        exit 1
    fi
fi

echo "[1/2] Generating SSL certificates..."

mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/C=TW/ST=Taiwan/L=Taipei/O=Dev/CN=localhost"

echo "[OK] SSL certs generated in $CERT_DIR"
echo ""

echo "[2/2] Starting Docker Compose..."

cd "$ROOT_DIR/docker"
docker compose up -d

echo ""
echo "========================================"
echo "  Done! Open https://localhost:8444"
echo "========================================"
