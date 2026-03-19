# n8n Workshop Workflow 範例庫

> 對應「n8n 自動化工作流實戰工作坊」各單元教學範例，可直接匯入 n8n 使用。

---

## 目錄結構

```
workflows/
├── README.md                          ← 你在這裡
├── unit_02_basics/                    ← 第二單元：n8n 基礎
│   └── 01_notion_trigger_hello_world.json
├── unit_03_flow_a_indexing/           ← 第三單元：Flow A 索引管線
│   ├── 01_flow_a1_drive_indexing.json
│   ├── 02_flow_a2_notion_indexing.json
│   └── 03_flow_a_full_dual_input.json
├── unit_03_flow_b_linebot/            ← 第三單元：Flow B LINE Bot
│   └── 01_flow_b_line_bot_qa.json
├── unit_04_flow_c_watchdog/           ← 第四單元：Flow C 守門員
│   ├── 01_flow_c_error_monitor.json
│   └── 02_flow_c_cron_reindex.json
└── unit_05_demos/                     ← 第五單元：商業化 Demo
    ├── 01_leave_request_approval.json
    └── 02_expense_report_summary.json
```

---

## Workflow 清單

### 第二單元：用 — n8n 基礎

| # | 檔案 | 名稱 | 教學目的 |
|---|------|------|---------|
| 1 | `unit_02_basics/01_notion_trigger_hello_world.json` | 第一條工作流 — Notion Trigger Hello World | 體驗 Trigger → Set → 輸出，感受「Notion 打字，n8n 自動動」 |

### 第三單元：做 — Flow A 索引管線

| # | 檔案 | 名稱 | 教學目的 |
|---|------|------|---------|
| 2 | `unit_03_flow_a_indexing/01_flow_a1_drive_indexing.json` | Flow A-1 — Drive 索引路徑 | Drive Trigger → Download → Extract Text → 正規化欄位 |
| 3 | `unit_03_flow_a_indexing/02_flow_a2_notion_indexing.json` | Flow A-2 — Notion 索引路徑 | Notion Trigger → Get Page → 正規化欄位 |
| 4 | `unit_03_flow_a_indexing/03_flow_a_full_dual_input.json` | Flow A 完整版 — 雙入口索引管線 | 兩條路匯合 → LLM 摘要 → Embeddings → Pinecone Upsert → 索引紀錄 |

### 第三單元：做 — Flow B LINE Bot

| # | 檔案 | 名稱 | 教學目的 |
|---|------|------|---------|
| 5 | `unit_03_flow_b_linebot/01_flow_b_line_bot_qa.json` | Flow B — LINE Bot 問答服務 | Webhook → 向量搜尋 → LLM 生成回答 → LINE Reply |

### 第四單元：部署 — Flow C 守門員

| # | 檔案 | 名稱 | 教學目的 |
|---|------|------|---------|
| 6 | `unit_04_flow_c_watchdog/01_flow_c_error_monitor.json` | Flow C-1 — 錯誤監控與通知 | Error Trigger → 寫 Notion Log → LINE 通知管理員 |
| 7 | `unit_04_flow_c_watchdog/02_flow_c_cron_reindex.json` | Flow C-2 — 定時補索引 | 每晚 Cron → 查漏掉的文件 → 重跑 Flow A → 更新狀態 |

### 第五單元：商業化 — Demo 範例

| # | 檔案 | 名稱 | 教學目的 |
|---|------|------|---------|
| 8 | `unit_05_demos/01_leave_request_approval.json` | 請假流程自動化 | LINE 請假 → Notion → IF 天數判斷 → 主管審批/自動核准 |
| 9 | `unit_05_demos/02_expense_report_summary.json` | 財會表單串接 | Notion 費用表單 → Google Sheets → 月底 Cron 匯總 → LINE 月報 |

---

## 匯入方式

### 方法 1：n8n GUI 匯入

1. 開啟 n8n 畫布
2. 點擊右上角 `...` → `Import from File`
3. 選擇對應的 `.json` 檔案
4. 設定 Credentials（見下方佔位符清單）

### 方法 2：Docker CLI 匯入（適用自架版）

```bash
# 複製 JSON 進容器
docker cp workflows/unit_02_basics/01_notion_trigger_hello_world.json n8n:/tmp/workflow.json

# 匯入
docker exec n8n n8n import:workflow --input=/tmp/workflow.json

# 批次匯入所有 workflow
for f in workflows/**/*.json; do
  docker cp "$f" n8n:/tmp/workflow.json
  docker exec n8n n8n import:workflow --input=/tmp/workflow.json
  echo "Imported: $f"
done
```

### 方法 3：n8n REST API（付費版）

```bash
curl -X POST "https://your-n8n.com/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflows/unit_02_basics/01_notion_trigger_hello_world.json
```

---

## 佔位符清單

匯入後需替換以下佔位符：

### Credentials（在 n8n GUI 中建立並綁定）

| 佔位符名稱 | 類型 | 使用的 Workflow |
|-----------|------|----------------|
| `notion_api` | Notion API | #1, #3, #4, #6, #7, #8, #9 |
| `google_drive_oauth2` | Google Drive OAuth2 | #2, #4 |
| `openai_api` | OpenAI API | #4, #5 |
| `pinecone_api` | Pinecone API | #4, #5 |
| `google_sheets_oauth2` | Google Sheets OAuth2 | #9 |

### 環境變數 / ID

| 佔位符 | 說明 | 使用的 Workflow |
|-------|------|----------------|
| `YOUR_NOTION_KB_DATABASE_ID` | Notion 知識庫 Database ID | #1, #3, #4 |
| `YOUR_GOOGLE_DRIVE_FOLDER_ID` | Google Drive 監控資料夾 ID | #2, #4 |
| `YOUR_PINECONE_INDEX` | Pinecone Index 名稱 | #4, #5 |
| `YOUR_NOTION_INDEX_LOG_DB_ID` | Notion 索引紀錄 Database ID | #4, #7 |
| `YOUR_NOTION_ERROR_LOG_DB_ID` | Notion 錯誤紀錄 Database ID | #6 |
| `YOUR_NOTION_LEAVE_DB_ID` | Notion 請假紀錄 Database ID | #8 |
| `YOUR_NOTION_EXPENSE_DB_ID` | Notion 費用紀錄 Database ID | #9 |
| `YOUR_GOOGLE_SHEET_ID` | Google Sheets 帳本 ID | #9 |
| `LINE_CHANNEL_ACCESS_TOKEN` | LINE Channel Access Token | #5, #6, #8, #9 |
| `ADMIN_LINE_USER_ID` | 管理員 LINE User ID | #6 |
| `MANAGER_LINE_USER_ID` | 主管 LINE User ID | #8 |
| `FINANCE_MANAGER_LINE_USER_ID` | 財務負責人 LINE User ID | #9 |
| `FLOW_A_WORKFLOW_ID` | Flow A 的 Workflow ID（匯入後取得） | #7 |

---

## 建議學習順序

```
#1 Hello World（暖身）
    ↓
#2 Drive 路徑 → #3 Notion 路徑 → #4 完整 Flow A（漸進組合）
    ↓
#5 Flow B LINE Bot（串接問答）
    ↓
#6 錯誤監控 → #7 定時補索引（守門員上線）
    ↓
#8 請假 Demo → #9 財會 Demo（場景延伸）
```
