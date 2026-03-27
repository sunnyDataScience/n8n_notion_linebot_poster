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

echo "[0/3] Starting Docker..."

# Check if Docker is running
if ! docker info &>/dev/null; then
    echo "[INFO] Docker is not running. Starting Docker..."
    if [[ "$(uname)" == "Darwin" ]]; then
        open -a Docker
    elif command -v systemctl &>/dev/null; then
        sudo systemctl start docker
    else
        echo "[ERROR] Cannot start Docker automatically. Please start it manually."
        exit 1
    fi
    echo "[INFO] Waiting for Docker to start..."
    while ! docker info &>/dev/null; do
        sleep 3
    done
fi

echo "[OK] Docker is running."
echo ""

echo "[1/3] Generating SSL certificates..."

mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERT_DIR/privkey.pem" \
    -out "$CERT_DIR/fullchain.pem" \
    -subj "/C=TW/ST=Taiwan/L=Taipei/O=Dev/CN=localhost"

echo "[OK] SSL certs generated in $CERT_DIR"
echo ""

echo "[2/3] Loading n8n Docker image..."

if [ -f "$ROOT_DIR/n8n.tar" ]; then
    docker load -i "$ROOT_DIR/n8n.tar"
    echo "[OK] n8n image loaded."
else
    echo "[SKIP] n8n.tar not found, skipping docker load."
fi
echo ""

echo "[3/3] Starting Docker Compose..."

cd "$ROOT_DIR/docker"
docker compose up -d

echo ""
echo "========================================"
echo "  Done! Open https://localhost:8444"
echo "========================================"
