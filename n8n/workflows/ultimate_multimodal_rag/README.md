# Ultimate Multimodal RAG + LINE Bot — 終極整合版

> 一套系統吃下文字、圖片、語音、影片四種媒體，全部自動索引，LINE Bot 問什麼都能答。

---

## 系統架構總覽

```
                    ┌─────────────────────────────────────────────┐
                    │              資 料 入 口                      │
                    │                                             │
                    │  Google Drive          Notion               │
                    │  (PDF/DOCX/IMG/        (頁面/附件/            │
                    │   MP3/MP4/...)          影音連結)              │
                    └──────┬────────────────────┬─────────────────┘
                           │                    │
                    ┌──────▼────────────────────▼─────────────────┐
                    │          Flow A — 多模態索引管線                │
                    │                                             │
                    │  ┌─────────────────────────────────┐        │
                    │  │  Switch (MIME Type 分流)          │        │
                    │  │                                  │        │
                    │  │  text/pdf/docx → Extract Text    │        │
                    │  │  image/*      → OpenAI Vision    │        │
                    │  │  audio/*      → Whisper 語音轉文字  │        │
                    │  │  video/*      → FFmpeg 抽音軌      │        │
                    │  │               → Whisper 轉文字     │        │
                    │  │               → Vision 抽關鍵幀     │        │
                    │  └────────────────┬──────────────────┘        │
                    │                   ↓                          │
                    │  Merge → LLM 摘要 → Embeddings → Pinecone    │
                    │                                → Notion Log  │
                    └─────────────────────────────────────────────┘
                                        │
                                        ↓
                    ┌─────────────────────────────────────────────┐
                    │              Pinecone 向量索引                │
                    │  (metadata: doc_id, title, source,          │
                    │   media_type, summary, tags, chunk_index)   │
                    └─────────────────────┬───────────────────────┘
                                          │
                    ┌─────────────────────▼───────────────────────┐
                    │          Flow B — 多模態 LINE Bot              │
                    │                                             │
                    │  LINE Webhook 接收訊息                        │
                    │  ┌──────────────────────────────────┐       │
                    │  │  Switch (message.type 分流)        │       │
                    │  │                                   │       │
                    │  │  text  → 直接當 query              │       │
                    │  │  image → LINE Content API 下載     │       │
                    │  │        → OpenAI Vision 描述        │       │
                    │  │        → 描述文字當 query            │       │
                    │  │  audio → LINE Content API 下載     │       │
                    │  │        → Whisper 轉文字            │       │
                    │  │        → 轉錄文字當 query            │       │
                    │  │  video → LINE Content API 下載     │       │
                    │  │        → Whisper 轉文字            │       │
                    │  │        → 轉錄文字當 query            │       │
                    │  └───────────────┬──────────────────┘       │
                    │                  ↓                          │
                    │  Merge → Embeddings → Pinecone Query        │
                    │       → LLM 生成回答 → LINE Reply            │
                    └─────────────────────────────────────────────┘
                                        │
                    ┌───────────────────▼──────────────────────────┐
                    │          Flow C — 強化版守門員                  │
                    │                                              │
                    │  C-1: Error Trigger → Notion Log → LINE 通知  │
                    │  C-2: 每晚 Cron → 查漏 → 重跑 Flow A           │
                    │  C-3: 每週 Cron → 抽樣驗證 → 品質報告             │
                    │  C-4: 每日 Cron → 媒體處理失敗重試                │
                    └──────────────────────────────────────────────┘
```

---

## 檔案清單

| # | 檔案 | 說明 |
|---|------|------|
| 1 | `flow_a_multimodal_indexing.json` | 多模態索引管線（Drive + Notion 雙入口，支援文字/圖片/語音/影片） |
| 2 | `flow_b_multimodal_linebot.json` | 多模態 LINE Bot（接收文字/圖片/語音/影片訊息，全部能搜能答） |
| 3 | `flow_c_enhanced_watchdog.json` | 強化版守門員（錯誤監控 + 定時補索引 + 品質抽驗 + 媒體重試） |

---

## 多模態處理策略

### 各媒體類型的處理邏輯

| 媒體類型 | MIME Type | 索引時處理方式 | 產出內容 | LINE Bot 接收時處理方式 |
|---------|-----------|-------------|---------|---------------------|
| **文字文件** | `application/pdf`, `application/vnd.*`, `text/*` | Extract from File → 純文字 | 原文內容 | 直接當 query |
| **圖片** | `image/png`, `image/jpeg`, `image/webp` | OpenAI Vision API (`gpt-4o`) → 圖片描述 + OCR | 視覺描述 + 文字辨識 | Vision 描述 → 當 query |
| **語音** | `audio/mpeg`, `audio/wav`, `audio/m4a`, `audio/ogg` | OpenAI Whisper API → 語音轉文字 | 逐字稿 | Whisper 轉文字 → 當 query |
| **影片** | `video/mp4`, `video/quicktime`, `video/webm` | Whisper 轉音軌文字 + Vision 抽關鍵幀描述 | 逐字稿 + 畫面描述 | Whisper 轉文字 → 當 query |

### 影片處理細節

影片是最複雜的媒體類型，需要兩條子管線：

```
影片檔案
    ├── 音軌提取 → Whisper API → 逐字稿（主要內容）
    └── 關鍵幀提取 → Vision API → 畫面描述（補充內容）
            ↓
    合併：逐字稿 + 畫面描述 = 完整影片內容
```

- 音軌提取：透過 n8n Code 節點呼叫 FFmpeg（需容器內安裝）
- 關鍵幀提取：Code 節點以固定間隔（每 30 秒）擷取一幀
- 若 FFmpeg 不可用，退化為只用 Whisper API 直接處理（OpenAI 支援影片音軌）

---

## Credential 需求

| Credential | 類型 | 用途 |
|------------|------|------|
| `notion_api` | Notion API | 讀寫知識庫、索引紀錄、錯誤日誌 |
| `google_drive_oauth2` | Google Drive OAuth2 | 監控資料夾、下載檔案 |
| `openai_api` | OpenAI API | GPT-4o (Chat + Vision)、Whisper、Embeddings |
| `pinecone_api` | Pinecone API | 向量 Upsert + Query |
| — | LINE Channel Access Token | LINE Reply/Push API（透過 HTTP Header） |

---

## 佔位符速查

| 佔位符 | 說明 |
|-------|------|
| `YOUR_NOTION_KB_DATABASE_ID` | Notion 知識庫 Database ID |
| `YOUR_NOTION_INDEX_LOG_DB_ID` | Notion 索引紀錄 Database ID |
| `YOUR_NOTION_ERROR_LOG_DB_ID` | Notion 錯誤紀錄 Database ID |
| `YOUR_GOOGLE_DRIVE_FOLDER_ID` | Google Drive 監控資料夾 ID |
| `YOUR_PINECONE_INDEX` | Pinecone Index 名稱 |
| `YOUR_PINECONE_NAMESPACE` | Pinecone Namespace（建議用 `multimodal-rag`） |
| `LINE_CHANNEL_ACCESS_TOKEN` | LINE Channel Access Token |
| `ADMIN_LINE_USER_ID` | 管理員 LINE User ID |
| `FLOW_A_WORKFLOW_ID` | Flow A 的 Workflow ID（匯入後取得） |

---

## 部署步驟

### 1. 前置需求

- n8n 自架版（Docker），建議使用 `naskio/n8n-python` image（已含 Python）
- 容器內需安裝 FFmpeg（影片音軌提取用）：
  ```bash
  docker exec n8n apk add ffmpeg
  ```
- OpenAI API key（需支援 GPT-4o + Whisper）
- Pinecone index（dimension: 1536, metric: cosine）

### 2. 匯入順序

```bash
# 1. 先匯入 Flow A（其他 Flow 依賴它）
docker cp flow_a_multimodal_indexing.json n8n:/tmp/flow_a.json
docker exec n8n n8n import:workflow --input=/tmp/flow_a.json

# 2. 記下 Flow A 的 workflow ID，填入 Flow C
docker exec n8n n8n list:workflow

# 3. 匯入 Flow B
docker cp flow_b_multimodal_linebot.json n8n:/tmp/flow_b.json
docker exec n8n n8n import:workflow --input=/tmp/flow_b.json

# 4. 匯入 Flow C（需先替換 FLOW_A_WORKFLOW_ID）
docker cp flow_c_enhanced_watchdog.json n8n:/tmp/flow_c.json
docker exec n8n n8n import:workflow --input=/tmp/flow_c.json
```

### 3. 設定 Credentials

在 n8n GUI 中建立並綁定所有 credentials（見上方清單）。

### 4. 啟用

```bash
docker exec n8n n8n update:workflow --id=<FLOW_A_ID> --active=true
docker exec n8n n8n update:workflow --id=<FLOW_B_ID> --active=true
docker exec n8n n8n update:workflow --id=<FLOW_C_ID> --active=true
```

### 5. 驗證

- 丟一份 PDF 到 Drive → 確認 Pinecone 收到向量
- 丟一張圖片到 Drive → 確認 Vision 描述被索引
- 丟一段語音到 Drive → 確認 Whisper 轉錄被索引
- LINE 傳文字訊息 → 確認 Bot 回答
- LINE 傳語音訊息 → 確認 Bot 理解並回答
- LINE 傳圖片 → 確認 Bot 描述圖片並搜尋相關知識

---

## Pinecone Metadata Schema

```json
{
  "doc_id": "drive_abc123 | notion_page_xyz",
  "title": "2024 年度報告.pdf",
  "source": "drive | notion",
  "media_type": "text | image | audio | video",
  "chunk_index": 0,
  "total_chunks": 3,
  "summary": "本文件為 2024 年度營運報告...",
  "tags": ["年報", "財務", "2024"],
  "original_url": "https://drive.google.com/... | https://notion.so/...",
  "indexed_at": "2026-03-19T12:00:00Z",
  "media_metadata": {
    "duration_seconds": 180,
    "language": "zh-TW",
    "resolution": "1920x1080"
  }
}
```

---

## 限制與已知問題

| 限制 | 說明 | 解法 |
|------|------|------|
| Whisper API 檔案上限 25MB | 大型影片/音檔會失敗 | Code 節點先切割音檔（FFmpeg `-ss -t`） |
| Vision API 圖片上限 20MB | 超大圖會失敗 | Code 節點先壓縮（ImageMagick） |
| LINE 內容 API 有效期限 | 媒體內容 URL 會過期 | 收到後立即下載並處理 |
| 影片處理耗時長 | 一部 10 分鐘影片可能需 2-3 分鐘處理 | Flow C 設定較長 timeout，異步處理 |
| Pinecone free tier 限制 | 100K vectors, 1 index | 控制 chunk 數量，定期清理過期向量 |
