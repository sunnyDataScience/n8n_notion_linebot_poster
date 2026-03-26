# n8n Container 安裝 SOP

## 架構概述

```
User Browser --HTTPS:8443--> Nginx (reverse proxy) --HTTP:5678--> n8n
```

- **n8n**: 工作流自動化平台
- **Nginx**: HTTPS 反向代理（自簽憑證）
- 對外埠號：`8443`（HTTPS）、`8088`（HTTP 自動跳轉 HTTPS）

---

## 前置需求

- Docker & Docker Compose 已安裝
- 使用者有 `docker` 群組權限（或使用 `sudo`）
- 防火牆已開放 port `8443`
- （可選）n8n Enterprise License Key（向 [n8n 官網](https://n8n.io) 購買或申請試用）

---

## 安裝步驟

### Step 1: 複製專案目錄

```bash
# 將整個 n8n 目錄複製到你的工作路徑
cp -r /path/to/n8n ~/docker-service/n8n
cd ~/docker-service/n8n
```

### Step 2: 產生自簽 SSL 憑證

```bash
mkdir -p nginx/certs

openssl req -x509 -nodes -days 365 \
  -newkey rsa:2048 \
  -keyout nginx/certs/privkey.pem \
  -out nginx/certs/fullchain.pem \
  -subj "/C=TW/ST=Taiwan/L=Taipei/O=MyOrg/CN=$(hostname -I | awk '{print $1}')"
```

> 如果已有正式憑證，直接將 `fullchain.pem` 和 `privkey.pem` 放入 `nginx/certs/` 即可。

### Step 3: 設定 License Key（可選）

`docker-compose.yml` 中的 `N8N_LICENSE_KEY` 為 **Enterprise 授權金鑰**，用來啟用企業版功能（LDAP、SAML SSO 等）。

- **有 Enterprise License**：將 key 填入 `N8N_LICENSE_KEY=<your-key>`
- **沒有 Enterprise License**：移除或註解該行，以 Community 版啟動即可，基本工作流功能皆可正常使用

```yaml
environment:
  # - N8N_LICENSE_KEY=<your-key>   # 有 Enterprise 授權才需要
  - N8N_EDITOR_BASE_URL=https://<你的IP>:8443
  - WEBHOOK_URL=https://<你的IP>:8443/
```

> **注意**：License Key 是從 n8n 官網取得的，與 n8n 容器內的帳號註冊無關。

### Step 4: 修改設定中的 IP 位址

取得本機 IP：

```bash
hostname -I | awk '{print $1}'
```

修改 `docker-compose.yml` 中的 IP（將 `10.137.80.58` 替換為你的 IP）：

```bash
# 假設你的 IP 是 10.x.x.x
MY_IP=$(hostname -I | awk '{print $1}')

sed -i "s/10.137.80.58/$MY_IP/g" docker-compose.yml
sed -i "s/10.137.80.58/$MY_IP/g" nginx.conf
```

### Step 5: 啟動服務

```bash
docker compose up -d
```

確認服務狀態：

```bash
docker compose ps
```

預期輸出應看到 `n8n` 和 `nginx` 兩個 container 狀態為 `Up`。

### Step 6: 驗證存取

在瀏覽器開啟：

```
https://<你的IP>:8443
```

> 因為是自簽憑證，瀏覽器會顯示安全性警告，點擊「進階」→「繼續前往」即可。

### Step 7: 建立 n8n 帳號

首次進入會要求設定 **Owner 帳號**：

1. 輸入 Email、名稱、密碼
2. 點擊「Next」完成初始設定
3. 登入後即可開始建立工作流

---

## 目錄結構

```
n8n/
├── docker-compose.yml    # Docker 服務定義
├── nginx.conf            # Nginx 反向代理設定
├── nginx/
│   └── certs/
│       ├── fullchain.pem # SSL 憑證
│       └── privkey.pem   # SSL 私鑰
└── SOP.md                # 本文件
```

---

## 常用維運指令

| 動作 | 指令 |
|------|------|
| 啟動服務 | `docker compose up -d` |
| 停止服務 | `docker compose down` |
| 查看日誌 | `docker compose logs -f n8n` |
| 重啟服務 | `docker compose restart` |
| 更新 n8n 版本 | `docker compose pull && docker compose up -d` |
| 備份資料 | `docker run --rm -v n8n_n8n_storage:/data -v $(pwd):/backup alpine tar czf /backup/n8n_backup.tar.gz -C /data .` |
| 還原資料 | `docker run --rm -v n8n_n8n_storage:/data -v $(pwd):/backup alpine tar xzf /backup/n8n_backup.tar.gz -C /data` |

---

## 故障排除

| 問題 | 排查方式 |
|------|----------|
| 無法連線 8443 | 確認防火牆：`sudo ufw status` 或 `sudo iptables -L -n` |
| 憑證錯誤 | 確認 `nginx/certs/` 下的檔案存在且路徑正確 |
| n8n 容器重啟 | 查看日誌：`docker compose logs n8n` |
| 502 Bad Gateway | n8n 容器可能尚未就緒，等待數秒後重試 |
