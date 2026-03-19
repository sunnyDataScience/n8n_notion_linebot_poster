# Claude Code × n8n 協作手冊

> **核心觀念：不要拖 UI，要生 JSON。把 n8n 當成「可被 JSON 定義的流程系統」，而不是「拖拉工具」。**

---

## 目錄

1. [協作模型總覽](#1-協作模型總覽)
2. [Workflow Spec 規格模板](#2-workflow-spec-規格模板)
3. [三種協作方案](#3-三種協作方案)
4. [Claude Code 職責與邊界](#4-claude-code-職責與邊界)
5. [n8n CLI / API 操作手冊](#5-n8n-cli--api-操作手冊)
6. [MCP Server 整合](#6-mcp-server-整合)
7. [安全規範](#7-安全規範)
8. [標準作業流程 (SOP)](#8-標準作業流程-sop)
9. [自動化可行性矩陣](#9-自動化可行性矩陣)
10. [常見問題與排除](#10-常見問題與排除)

---

## 1. 協作模型總覽

### 一句話定義

> SA 先把流程規格化 → Claude Code 讀規格 → 產生/修改 n8n workflow JSON → CLI 或 API 匯入/更新 → 人工驗證憑證與 edge cases。

### 分工原則

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│     人類 (SA)    │     │   Claude Code    │     │      n8n        │
│                 │     │                  │     │                 │
│ - 寫流程規格     │────→│ - 讀 Spec        │────→│ - 執行 workflow  │
│ - 定義觸發條件   │     │ - 產生 JSON      │     │ - 管理 runtime   │
│ - 設定憑證      │     │ - 批次修改       │     │ - webhook/cron   │
│ - 驗證結果      │     │ - 產生部署腳本    │     │ - execution log  │
│ - 處理 edge case│     │ - 版本控制       │     │ - integrations   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

### 口訣

1. **不要拖 UI，要生 JSON**
2. **不要猜設定，要先寫 Spec**
3. **不要直上正式，要先跑 Staging**

---

## 2. Workflow Spec 規格模板

每一條 n8n workflow 在交給 Claude Code 之前，必須先填寫以下規格。這是整個協作流程的核心文件。

### 模板

```yaml
# ============================================================
# n8n Workflow Spec
# ============================================================

workflow:
  name: ""                    # workflow 名稱，snake_case
  description: ""             # 一句話描述這條流程做什麼
  version: "1.0.0"            # semver
  owner: ""                   # 負責人
  tags: []                    # 分類標籤，例如 [hr, approval]

# ------------------------------------------------------------
# 觸發條件
# ------------------------------------------------------------
trigger:
  type: ""                    # webhook | cron | notion_trigger | drive_trigger | manual | form | chat
  config:
    # webhook 範例：
    #   method: POST
    #   path: /leave-request
    # cron 範例：
    #   expression: "0 0 * * *"    # 每天午夜
    #   timezone: "Asia/Taipei"
    # notion_trigger 範例：
    #   database_id: "xxx"
    #   event: "page_added"

# ------------------------------------------------------------
# 輸入 Schema
# ------------------------------------------------------------
input_schema:
  format: "json"              # json | form | binary | text
  fields:
    - name: ""
      type: ""                # string | number | boolean | date | array | object | binary
      required: true
      description: ""
      example: ""
  # 範例 payload（完整）：
  example_payload: |
    {}

# ------------------------------------------------------------
# 節點清單與責任
# ------------------------------------------------------------
nodes:
  - id: "node_1"
    type: ""                  # n8n node type，例如 n8n-nodes-base.set
    name: ""                  # 節點顯示名稱
    responsibility: ""        # 這個節點做什麼（一句話）
    input_from: ""            # 接收哪個節點的輸出
    output_to: ""             # 輸出到哪個節點
    config: {}                # 節點特定設定
    notes: ""                 # 補充說明

# ------------------------------------------------------------
# 分支條件
# ------------------------------------------------------------
branch_rules:
  - condition: ""             # 例如 "{{ $json.days > 3 }}"
    true_path: ""             # 條件成立走哪個節點
    false_path: ""            # 條件不成立走哪個節點
    description: ""           # 為什麼需要這個分支

# ------------------------------------------------------------
# 輸出 Schema
# ------------------------------------------------------------
output_schema:
  format: "json"
  fields:
    - name: ""
      type: ""
      description: ""
  side_effects:               # 除了回傳值，還會造成哪些外部影響
    - target: ""              # 例如 "Notion 請假紀錄 DB"
      action: ""              # 例如 "新增一筆記錄"
    - target: ""
      action: ""

# ------------------------------------------------------------
# 錯誤處理
# ------------------------------------------------------------
error_policy:
  retry:
    enabled: true
    max_attempts: 3
    wait_between: 5000        # ms
  on_failure:
    action: ""                # notify | log | fallback | ignore
    notify_channel: ""        # 例如 "LINE group xxx"
    fallback_workflow: ""     # 備援 workflow 名稱
  timeout: 30000              # ms，整條 workflow 的 timeout

# ------------------------------------------------------------
# 憑證依賴
# ------------------------------------------------------------
credentials_required:
  - name: ""                  # credential 名稱
    type: ""                  # 例如 notionApi, googleDriveOAuth2Api
    scope: ""                 # 需要的權限範圍
    notes: ""                 # 設定注意事項

# ------------------------------------------------------------
# 環境變數
# ------------------------------------------------------------
env_vars:
  - name: ""
    description: ""
    required: true
    example: ""

# ------------------------------------------------------------
# 測試案例
# ------------------------------------------------------------
test_cases:
  - name: ""                  # 測試名稱
    description: ""           # 測試什麼情境
    input: {}                 # 測試輸入
    expected_output: {}       # 預期輸出
    expected_side_effects: [] # 預期副作用

# ------------------------------------------------------------
# 部署資訊
# ------------------------------------------------------------
deployment:
  environment: ""             # dev | staging | production
  n8n_instance: ""            # 目標 n8n URL
  method: ""                  # cli | api | manual_import
  depends_on: []              # 依賴的其他 workflow
```

### 範例：請假流程自動化

```yaml
workflow:
  name: "leave_request_approval"
  description: "LINE 送出請假申請，自動寫入 Notion 並通知主管審批"
  version: "1.0.0"
  owner: "HR Team"
  tags: [hr, approval, line]

trigger:
  type: webhook
  config:
    method: POST
    path: /leave-request

input_schema:
  format: json
  fields:
    - name: employee_name
      type: string
      required: true
      description: "員工姓名"
      example: "王小明"
    - name: leave_type
      type: string
      required: true
      description: "假別：annual | sick | personal"
      example: "annual"
    - name: start_date
      type: date
      required: true
      description: "起始日期"
      example: "2026-03-20"
    - name: end_date
      type: date
      required: true
      description: "結束日期"
      example: "2026-03-22"
    - name: days
      type: number
      required: true
      description: "請假天數"
      example: 3
    - name: reason
      type: string
      required: false
      description: "請假事由"
      example: "家庭旅遊"
  example_payload: |
    {
      "employee_name": "王小明",
      "leave_type": "annual",
      "start_date": "2026-03-20",
      "end_date": "2026-03-22",
      "days": 3,
      "reason": "家庭旅遊"
    }

nodes:
  - id: "webhook"
    type: "n8n-nodes-base.webhook"
    name: "接收請假申請"
    responsibility: "接收 LINE 轉發過來的請假 payload"
    input_from: null
    output_to: "set_fields"

  - id: "set_fields"
    type: "n8n-nodes-base.set"
    name: "整理欄位"
    responsibility: "標準化欄位命名，加入 timestamp 和 status=PENDING"
    input_from: "webhook"
    output_to: "write_notion"

  - id: "write_notion"
    type: "n8n-nodes-base.notion"
    name: "寫入 Notion 請假表"
    responsibility: "在 Notion 請假紀錄 DB 新增一筆記錄"
    input_from: "set_fields"
    output_to: "check_days"

  - id: "check_days"
    type: "n8n-nodes-base.if"
    name: "檢查天數"
    responsibility: "判斷請假天數是否 > 3 天"
    input_from: "write_notion"
    output_to: "notify_manager | auto_approve"

  - id: "notify_manager"
    type: "n8n-nodes-base.httpRequest"
    name: "通知主管審批"
    responsibility: "透過 LINE Push API 發送審批通知給主管"
    input_from: "check_days (true)"
    output_to: null

  - id: "auto_approve"
    type: "n8n-nodes-base.notion"
    name: "自動核准"
    responsibility: "3 天以內自動核准，更新 Notion status=APPROVED"
    input_from: "check_days (false)"
    output_to: "notify_employee"

  - id: "notify_employee"
    type: "n8n-nodes-base.httpRequest"
    name: "通知員工結果"
    responsibility: "透過 LINE 回覆申請結果"
    input_from: "auto_approve"
    output_to: null

branch_rules:
  - condition: "{{ $json.days > 3 }}"
    true_path: "notify_manager"
    false_path: "auto_approve"
    description: "超過 3 天需主管審批，3 天以內自動核准"

output_schema:
  format: json
  fields:
    - name: status
      type: string
      description: "APPROVED | PENDING_APPROVAL"
  side_effects:
    - target: "Notion 請假紀錄 DB"
      action: "新增一筆請假記錄"
    - target: "LINE (主管)"
      action: "推播審批通知（僅 > 3 天時）"
    - target: "LINE (員工)"
      action: "回覆申請結果（僅 <= 3 天自動核准時）"

error_policy:
  retry:
    enabled: true
    max_attempts: 3
    wait_between: 5000
  on_failure:
    action: notify
    notify_channel: "LINE HR 群組"
    fallback_workflow: null
  timeout: 30000

credentials_required:
  - name: "notion_hr"
    type: "notionApi"
    scope: "read_write"
    notes: "需要存取請假紀錄 Database"
  - name: "line_channel"
    type: "httpHeaderAuth"
    scope: "messaging_api"
    notes: "LINE Channel Access Token"

env_vars:
  - name: "NOTION_LEAVE_DB_ID"
    description: "Notion 請假紀錄 Database ID"
    required: true
    example: "abc123..."
  - name: "LINE_MANAGER_USER_ID"
    description: "主管的 LINE User ID"
    required: true
    example: "U1234..."

test_cases:
  - name: "短假自動核准"
    description: "請假 2 天應自動核准並通知員工"
    input:
      employee_name: "測試員工"
      leave_type: "annual"
      start_date: "2026-04-01"
      end_date: "2026-04-02"
      days: 2
      reason: "休息"
    expected_output:
      status: "APPROVED"
    expected_side_effects:
      - "Notion 新增一筆 status=APPROVED"
      - "LINE 通知員工已核准"

  - name: "長假需審批"
    description: "請假 5 天應送主管審批"
    input:
      employee_name: "測試員工"
      leave_type: "annual"
      start_date: "2026-04-01"
      end_date: "2026-04-05"
      days: 5
      reason: "出國旅遊"
    expected_output:
      status: "PENDING_APPROVAL"
    expected_side_effects:
      - "Notion 新增一筆 status=PENDING"
      - "LINE 通知主管審批"

deployment:
  environment: "staging"
  n8n_instance: "https://n8n.example.com"
  method: "cli"
  depends_on: []
```

---

## 3. 三種協作方案

### 方案 1：規格驅動生成（最推薦）

**適合：有自架 n8n，想做可維護、可複製、可批次部署的團隊。**

```
SA 寫 Spec (YAML)
    ↓
Claude Code 讀 Spec → 產生 workflow JSON
    ↓
Git commit + PR review
    ↓
n8n CLI import → staging 測試
    ↓
人工驗證 credentials + edge cases
    ↓
CLI activate → production
```

**指令範例：**

```bash
# 產生 workflow JSON 後匯入
n8n import:workflow --input=workflows/leave_request.json

# 啟動
n8n update:workflow --id=123 --active=true

# 執行測試
n8n execute --id=123
```

### 方案 2：AI Builder 打草稿 + Claude Code 重構（過渡型）

**適合：需求還在探索階段，想快速看到 prototype。**

```
n8n AI Workflow Builder 自然語言建立草稿
    ↓
n8n GUI 匯出 JSON
    ↓
Claude Code 重構 JSON（補 error handling、命名、模組化）
    ↓
Git 版本控管
    ↓
CLI/API 部署
```

### 方案 3：MCP Server 整合（Agent 互動型）

**適合：把 n8n 當工具層，AI agent 作為上層 orchestrator。**

```
Claude Code / Claude Desktop
    ↓ MCP protocol
n8n MCP Server
    ↓
搜尋 workflow → 讀 metadata → 觸發執行
```

**設定方式：**

```bash
claude mcp add n8n-mcp-server \
  --url https://your-n8n.example.com/mcp \
  --header "Authorization: Bearer <API_KEY>"
```

> 注意：MCP 偏向「查詢 / 觸發 / 執行」，不是最佳的 workflow authoring 通道。開發主軸仍應放在 Spec + JSON + Git + CLI。

---

## 4. Claude Code 職責與邊界

### Claude Code 該做的

| 任務 | 說明 |
|------|------|
| 讀 Spec 產生 JSON | 核心職責，把 YAML spec 轉成合法 n8n workflow JSON |
| 批次修改 workflow | 例如統一加入 error handling、改命名規範 |
| 產生部署腳本 | shell script 包裝 CLI 指令 |
| 維護 repo 結構 | workflows/、specs/、scripts/ 目錄管理 |
| 產生測試資料 | mock payload、test fixtures |
| 補 error handling | 加入 retry、timeout、fallback 節點 |
| 文件化 | 從 JSON 反向產生 workflow 說明文件 |

### Claude Code 不該做的

| 禁止事項 | 原因 |
|----------|------|
| 模擬 GUI 拖拉 | UI 自動化脆弱，JSON/API 才是工業化做法 |
| 猜憑證設定 | OAuth token、API key 必須人工設定 |
| 直接改 production | 沒有 staging 驗證就上線是自殺 |
| 沒 Spec 自由發揮 | 沒規格的產出無法驗證、無法維護 |
| 處理敏感資訊 | credentials、token 不能經過 AI |

---

## 5. n8n CLI / API 操作手冊

### CLI（僅限自架版）

```bash
# ============================================================
# Workflow 管理
# ============================================================

# 匯入 workflow
n8n import:workflow --input=workflow.json

# 匯出所有 workflow
n8n export:workflow --all --output=workflows/

# 匯出單一 workflow
n8n export:workflow --id=123 --output=workflow_123.json

# 啟用 workflow
n8n update:workflow --id=123 --active=true

# 停用 workflow
n8n update:workflow --id=123 --active=false

# 直接執行 workflow（測試用）
n8n execute --id=123

# ============================================================
# Credential 管理
# ============================================================

# 匯出 credentials（加密）
n8n export:credentials --all --output=credentials/

# 匯出 credentials（明文，僅限遷移用，注意安全！）
n8n export:credentials --all --decrypted --output=credentials/

# 匯入 credentials
n8n import:credentials --input=credentials.json
```

### Public REST API（Cloud / 付費版）

```bash
# ============================================================
# Workflow CRUD
# ============================================================

# 列出所有 workflow
curl -X GET "https://your-n8n.com/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"

# 取得單一 workflow
curl -X GET "https://your-n8n.com/api/v1/workflows/123" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"

# 建立 workflow
curl -X POST "https://your-n8n.com/api/v1/workflows" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflow.json

# 更新 workflow
curl -X PATCH "https://your-n8n.com/api/v1/workflows/123" \
  -H "X-N8N-API-KEY: $N8N_API_KEY" \
  -H "Content-Type: application/json" \
  -d @workflow_update.json

# 啟用 workflow
curl -X PATCH "https://your-n8n.com/api/v1/workflows/123/activate" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"

# ============================================================
# Execution
# ============================================================

# 取得執行紀錄
curl -X GET "https://your-n8n.com/api/v1/executions" \
  -H "X-N8N-API-KEY: $N8N_API_KEY"
```

> 注意：n8n free trial 不提供 API 存取。

---

## 6. MCP Server 整合

### 設定

```bash
# Claude Code 加入 n8n MCP server
claude mcp add n8n-mcp-server \
  --url https://your-n8n.example.com/mcp \
  --header "Authorization: Bearer <API_KEY>"
```

### 能力範圍

| 能力 | 支援 | 說明 |
|------|------|------|
| 搜尋 workflow | O | 列出已暴露的 workflow |
| 讀取 metadata | O | 取得 workflow 名稱、節點、狀態 |
| 觸發執行 | O | 執行已啟用的 workflow |
| 建立 workflow | X | 不是主要用途，用 CLI/API |
| 修改 workflow | X | 不是主要用途，用 CLI/API |
| 管理 credentials | X | 安全考量，不開放 |

### 適用場景

- Claude Code 作為上層 orchestrator，呼叫 n8n 執行已部署的流程
- Demo、BD 展示、內部助理
- 查詢 workflow 執行狀態

### 不適用場景

- Workflow 開發與修改（用 Spec + JSON + CLI）
- Credential 管理（手動操作）
- 批次部署（用 deploy script）

---

## 7. 安全規範

### 絕對禁止

| 規則 | 原因 |
|------|------|
| 不把 credentials 明文傳給 AI | AI 不需要也不該知道你的 token |
| 不對 production 直接覆蓋 workflow | 必須先走 staging |
| 不用 `--decrypted` 匯出後 commit 到 Git | 敏感資訊會進版本歷史 |
| 不把 n8n API key 寫在 workflow JSON 裡 | 用環境變數 |

### Credential 處理流程

```
Claude Code 產生 JSON
    ↓
JSON 裡只有 credential 名稱和 type（不含實際值）
    ↓
人工在 n8n GUI 建立 credential 並綁定
    ↓
或用 CLI import 加密的 credential 檔案（不經過 AI）
```

### Workflow JSON 安全檢查清單

- [ ] JSON 不含任何 API key / token / password
- [ ] JSON 不含任何真實用戶資料
- [ ] credential 欄位只有 `name` 和 `type`，沒有 `data`
- [ ] HTTP Request 節點的 auth header 使用 credential reference，不是硬編碼
- [ ] webhook path 不含可猜測的敏感路徑

---

## 8. 標準作業流程 (SOP)

### SOP-1：新建 Workflow

```
Step 1  SA 填寫 Workflow Spec（見第 2 節模板）
            ↓
Step 2  Review Spec：確認觸發條件、節點、分支、錯誤處理完整
            ↓
Step 3  Claude Code 讀 Spec → 產生 workflow JSON
            ↓
Step 4  JSON 放入 Git repo：workflows/<name>.json
            ↓
Step 5  PR review：檢查 JSON 結構、安全性
            ↓
Step 6  CLI 匯入 staging n8n
            ↓
Step 7  人工設定 credentials
            ↓
Step 8  跑測試案例（Spec 裡定義的）
            ↓
Step 9  通過 → CLI 匯入 production + activate
            ↓
Step 10 監控 execution log 前 24 小時
```

### SOP-2：修改既有 Workflow

```
Step 1  從 n8n CLI 匯出最新 JSON → 放入 Git
            ↓
Step 2  更新 Workflow Spec
            ↓
Step 3  Claude Code 讀更新後的 Spec → 修改 JSON
            ↓
Step 4  Git diff review
            ↓
Step 5  CLI 更新 staging → 測試 → production
```

### SOP-3：批次部署

```bash
#!/bin/bash
set -euo pipefail

WORKFLOWS_DIR="./workflows"
N8N_URL="https://n8n.example.com"

for file in "$WORKFLOWS_DIR"/*.json; do
    echo "Importing: $file"
    n8n import:workflow --input="$file"
done

echo "All workflows imported."
```

---

## 9. 自動化可行性矩陣

### 高自動化（Claude Code 可直接產出）

| 項目 | 說明 |
|------|------|
| 節點選型 | 根據 Spec 選擇正確的 n8n node type |
| 流程拓撲 | 節點連接順序與結構 |
| 分支條件 | IF / Switch 節點的 expression |
| CRUD 流程 | webhook → 處理 → 寫入 DB → 回應 |
| 錯誤通知 | Error Trigger → 通知節點 |
| 命名規範 | 統一節點命名、variable naming |
| Sub-workflow 拆分 | 模組化大型流程 |
| 文件產生 | 從 JSON 產出 workflow 說明文件 |

### 需人工收尾（AI 產出後必須人工檢查）

| 項目 | 原因 |
|------|------|
| OAuth / credential 綁定 | 需要真實 token，AI 不該碰 |
| 節點欄位的細小 schema 差異 | n8n 版本間可能有差異 |
| Expression 與 reference path | `{{ $json.field }}` 路徑需對應實際資料 |
| 多環境變數切換 | dev / staging / prod 的值不同 |
| Binary data 處理 | 檔案上傳/下載的 buffer 處理 |
| Third-party API rate limit | 需要根據實際額度調整 |
| Production rollback | 需要人工判斷影響範圍 |

---

## 10. 常見問題與排除

### Q1：Claude Code 產生的 JSON 匯入後節點位置很亂？

n8n JSON 裡的 `position` 欄位控制節點在畫布上的位置。Claude Code 可以產生合理的 position 值（每個節點 x 間隔 250，y 根據分支調整），但匯入後在 GUI 按一下 auto-layout 即可。

### Q2：匯入後 credential 顯示紅色錯誤？

正常。Claude Code 產生的 JSON 只有 credential 的 `name` 和 `type`，沒有實際的 token。需要在 n8n GUI 手動建立 credential 並重新綁定。

### Q3：n8n 版本升級後 JSON 格式不相容？

n8n 的 workflow JSON schema 偶爾會在大版本升級時改變。建議：
- 在 Spec 裡註明目標 n8n 版本
- 升級前先匯出備份
- 升級後用 CLI 重新匯入測試

### Q4：能不能讓 Claude Code 直接連 n8n 改東西？

技術上透過 MCP 或 API 可以，但不建議在 production 這樣做。正確做法是 Claude Code 改 JSON 檔案 → Git → CLI 部署。保持「程式碼即真理」(Infrastructure as Code) 的原則。

### Q5：Free trial 的 n8n Cloud 能用這套流程嗎？

部分可以。Free trial 不支援 API，但你可以：
- Claude Code 產生 JSON → 手動在 GUI 匯入
- 用 n8n AI Workflow Builder 做草稿 → 匯出 → Claude Code 重構

---

## 專案目錄結構建議

```
project/
├── specs/                      # Workflow 規格檔
│   ├── leave_request.yaml
│   ├── expense_report.yaml
│   └── knowledge_index.yaml
├── workflows/                  # n8n workflow JSON
│   ├── leave_request.json
│   ├── expense_report.json
│   └── knowledge_index.json
├── scripts/                    # 部署與管理腳本
│   ├── deploy.sh
│   ├── export_all.sh
│   └── test_workflow.sh
├── tests/                      # 測試 payload
│   ├── leave_request_short.json
│   └── leave_request_long.json
└── docs/                       # 自動產生的文件
    └── workflow_docs.md
```

---

## 版本紀錄

| 版本 | 日期 | 變更 |
|------|------|------|
| 1.0.0 | 2026-03-19 | 初版建立 |
