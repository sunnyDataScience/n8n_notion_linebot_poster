# Enterprise Multimodal RAG Strategy

# n8n + LINE Bot + Google Drive + Notion

> 從「能用」到「企業級」的完整升級路徑。
> 每個技巧都對應具體的 n8n 節點或 Code node 實作。

---

## 1. Gap Analysis — 現況 vs 目標


| 能力                  | 現況                                                  | 目標                                                | 優先級    |
| ------------------- | --------------------------------------------------- | ------------------------------------------------- | ------ |
| Chunking            | 500-char recursive split, flat                      | NQ1D structured, token-aware 512/64               | **P0** |
| Metadata            | 4 fields (source, media_type, title, doc_id)        | 12+ fields with source_url, hierarchy, tags       | **P0** |
| Embedding Model     | 不一致 (Flow A default, Flow B text-embedding-3-small) | 統一 `text-embedding-3-small` (1536-dim)            | **P0** |
| Citation            | 無                                                   | 回答附帶可點擊的 Google Drive / Notion 連結                 | **P0** |
| Query Expansion     | 無                                                   | HyDE + MultiQuery (3 queries)                     | **P1** |
| Reranking           | 無                                                   | Cohere `rerank-multilingual-v3.0`                 | **P1** |
| Hybrid Search       | Dense only                                          | Dense + keyword metadata filtering → Phase 2 BM25 | **P2** |
| Conversation Memory | 無                                                   | `memoryBufferWindow` keyed by LINE userId         | **P1** |
| Document Parsing    | 直接 binary loader / Vision API                       | **MinerU** OCR + 表格 + 公式辨識 → clean Markdown       | **P0** |
| Deduplication       | 無（重複觸發 = 重複寫入）                                 | content_hash + doc_id filter + delete-before-upsert | **P0** |


---

## 1.5 MinerU Integration — 多模態文件前處理引擎

### Why MinerU

現有系統對 PDF/Word/PPT 的處理方式太粗糙：

- **Text/PDF** → 直接 binary data loader（無法處理掃描件、表格、公式）
- **Image** → Vision API（OK，但無結構化輸出）

MinerU 補足的能力：


| 格式           | 現況                 | MinerU 後                     |
| ------------ | ------------------ | ---------------------------- |
| 原生文字 PDF     | binary loader 抽純文字 | 保留表格結構 + 公式 → clean Markdown |
| 掃描件 PDF      | 完全無法處理             | OCR → Markdown               |
| Word (.docx) | 不支援                | 完整轉換含格式                      |
| PPT (.pptx)  | 不支援                | 逐頁轉換含版面                      |
| 圖片內文字        | Vision API 描述      | OCR 精確抽取 + 版面保留              |


### n8n Template Reference

**Template 4808** — Convert Documents to Markdown with MinerU API and GPT-4o-mini

```
核心節點：
- chatTrigger (接收上傳檔案)
- readWriteFile (存檔到本地)
- mcpClientTool (連接 MinerU MCP server)
- agent (AI Agent 呼叫 MinerU 解析)
- lmChatOpenAi (gpt-4o-mini)
```

### Integration Architecture — MinerU Cloud HTTP API

**API Base URL:** `https://mineru.net/api/v4`
**費用：** Beta 期間完全免費（每日 2,000 頁最高優先級）
**支援格式：** PDF, DOC, DOCX, PPT, PPTX, PNG, JPG, HTML
**輸出格式：** Markdown (default), JSON, DOCX, HTML, LaTeX
**限制：** 單檔最大 200MB / 600 頁

### API Flow — 異步三步驟：提交 → 輪詢 → 取結果

```
Google Drive Trigger → Download File
    ↓
Code — Get Google Drive public URL (webViewLink)
    ↓
HTTP Request — POST https://mineru.net/api/v4/extract/task
    Headers: Authorization: Bearer {MINERU_API_KEY}
    Body: { "url": fileUrl, "model_version": "vlm", "output_format": "markdown" }
    Response: { "data": { "task_id": "abc123" } }
    ↓
Wait — 10 seconds
    ↓
HTTP Request — GET https://mineru.net/api/v4/extract/task/{task_id}
    → if state === "done": proceed
    → if state === "running": loop back to Wait
    ↓
HTTP Request — GET {markdown_url} (download Markdown result)
    ↓
Code — NQ1D Metadata Enrichment (parse headings from Markdown)
    ↓
Pinecone Upsert
```

### n8n Node 實作 — Step by Step

**Step 1: Submit Parsing Task**

```
HTTP Request — MinerU Submit
  Method: POST
  URL: https://mineru.net/api/v4/extract/task
  Headers:
    Authorization: =Bearer {{ $vars.MINERU_API_KEY }}
    Content-Type: application/json
  Body (JSON):
  {
    "url": "={{ $json.webViewLink || $json.downloadUrl }}",
    "model_version": "vlm",
    "output_format": "markdown"
  }
```

**Step 2: Poll Status (Wait loop)**

```
Wait — 10 seconds
    ↓
HTTP Request — MinerU Check Status
  Method: GET
  URL: =https://mineru.net/api/v4/extract/task/{{ $('HTTP Request — MinerU Submit').item.json.data.task_id }}
  Headers:
    Authorization: =Bearer {{ $vars.MINERU_API_KEY }}
    ↓
Code — Check Completion:
  const state = $json.state;
  if (state === 'done') return [{ json: $json }];
  // if still running, connect back to Wait node
  return [];
```

**Step 3: Download Markdown Result**

```
HTTP Request — Download Markdown
  Method: GET
  URL: ={{ $json.data.markdown_url }}
  // Returns raw Markdown text
```

### 若 Google Drive 檔案不是 public URL

Google Drive 下載的是 binary，不是 URL。需要先上傳取得 signed URL：

```
HTTP Request — MinerU Get Upload URL
  Method: POST
  URL: https://mineru.net/api/v4/file-urls/batch
  Headers: Authorization: Bearer {MINERU_API_KEY}
  Body: {
    "enable_formula": true,
    "language": "zh",
    "files": ["document.pdf"]
  }
  → Response: presigned_url for upload
    ↓
HTTP Request — Upload Binary
  Method: PUT
  URL: ={{ presigned_url }}
  Body: binary data from Google Drive download
    ↓
HTTP Request — MinerU Submit Batch
  Method: POST
  URL: https://mineru.net/api/v4/extract/task/batch
  Body: { "batch_id": "..." }
```

### Lightweight API (免費、免 Token、10MB 限制)

適合快速測試或小檔案，不需要 API Key：

```
HTTP Request — MinerU Lightweight
  Method: POST
  URL: https://mineru.net/api/v1/agent/parse/file
  Content-Type: multipart/form-data
  Body: file binary (max 10MB, 20 pages)
  // No Authorization header needed
```

### Setup — 只需要 API Key，無需安裝任何軟體

```
1. 前往 https://mineru.net 註冊帳號
2. 進入 API Management → https://mineru.net/apiManage/docs
3. 申請 API Token → 取得 MINERU_API_KEY
4. 在 n8n Settings → Variables 新增: MINERU_API_KEY
```

### Enhanced MIME Routing with MinerU

現有的 4 路 Code node routing 需要擴充：

```javascript
// Code — Route by MIME type (Enhanced)
const items = $input.all();
const mime = items[0]?.json?.mimeType || items[0]?.binary?.data?.mimeType || '';

// MinerU-eligible formats (high-quality parsing)
if (mime === 'application/pdf' ||
    mime === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' ||  // .docx
    mime === 'application/vnd.openxmlformats-officedocument.presentationml.presentation' || // .pptx
    mime === 'application/msword' ||  // .doc
    mime === 'application/vnd.ms-powerpoint') {  // .ppt
  return [{ json: { ...items[0].json, route: 'mineru' } }];
}

// Plain text (no MinerU needed)
if (mime.startsWith('text/')) {
  return [{ json: { ...items[0].json, route: 'text' } }];
}

// Image → Vision API (or MinerU for OCR)
if (mime.startsWith('image/')) {
  return [{ json: { ...items[0].json, route: 'image' } }];
}

// Audio → Whisper
if (mime.startsWith('audio/')) {
  return [{ json: { ...items[0].json, route: 'audio' } }];
}

// Video → Whisper
if (mime.startsWith('video/')) {
  return [{ json: { ...items[0].json, route: 'video' } }];
}

return []; // unknown format, skip
```

### NQ1D Enrichment from MinerU Markdown

MinerU 輸出的 Markdown 天然保留了文件結構，非常適合 NQ1D：

```javascript
// Code — NQ1D from MinerU Markdown
const markdown = $json.markdown || $json.content || '';

// Extract heading hierarchy from Markdown
const headingStack = [];
const sections = [];
let currentSection = { hierarchy: '', content: '' };

for (const line of markdown.split('\n')) {
  const match = line.match(/^(#{1,6})\s+(.+)/);
  if (match) {
    // Save previous section
    if (currentSection.content.trim()) {
      sections.push({ ...currentSection });
    }
    // Update heading stack
    const level = match[1].length;
    const text = match[2].trim();
    headingStack.length = level - 1; // truncate to parent level
    headingStack[level - 1] = text;
    currentSection = {
      hierarchy: headingStack.filter(Boolean).join(' > '),
      content: ''
    };
  } else {
    currentSection.content += line + '\n';
  }
}
// Don't forget last section
if (currentSection.content.trim()) {
  sections.push({ ...currentSection });
}

// Extract tables (MinerU preserves them as Markdown tables)
const tableCount = (markdown.match(/\|.*\|/g) || []).length;
const hasFormulas = /\$.*\$/.test(markdown) || /\\\\[.*\\\\]/.test(markdown);

return [{
  json: {
    ...$json,
    section_hierarchy: sections.map(s => s.hierarchy).join('; '),
    total_sections: sections.length,
    has_tables: tableCount > 0,
    has_formulas: hasFormulas,
    parsed_by: 'mineru'
  }
}];
```

---

## 2. 4-Layer Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 1 — INGESTION                                        │
│                                                             │
│  Google Drive Trigger ──┐                                   │
│  Notion Trigger ────────┤──→ MIME Routing (Code nodes)      │
│  LINE Upload ───────────┘    text/pdf | image | audio | video│
│                                                             │
│  Media Processing:                                          │
│    pdf/docx/pptx → **MinerU** (OCR + table + formula → MD) │
│    plain text    → passthrough                              │
│    image         → OpenAI Vision API (OCR + description)    │
│    audio         → Whisper API (transcription)              │
│    video         → Whisper (audio track) + Vision (keyframes)│
└───────────────────────────┬─────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 2 — INDEXING (NQ1D)                                  │
│                                                             │
│  ★ Code — Dedup Check (query Pinecone by doc_id)            │
│    → if exists + same modifiedTime → SKIP (avoid duplicate) │
│    → if exists + different modifiedTime → DELETE old → proceed│
│    → if not exists → proceed                                │
│                                                             │
│  Code — NQ1D Metadata Enrichment                            │
│    → parse headings, generate section_hierarchy             │
│    → construct source_url from file/page IDs                │
│    → extract keywords via LLM (for hybrid search)           │
│                                                             │
│  Code — Token-Aware Chunking (512 tokens, 64 overlap)       │
│    → assign chunk_index, total_chunks per chunk             │
│    → attach content_preview (first 200 chars)               │
│                                                             │
│  HTTP Request — OpenAI Embeddings (text-embedding-3-small)  │
│  HTTP Request — Pinecone Upsert (with full NQ1D metadata)   │
└───────────────────────────┬─────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 3 — RETRIEVAL                                        │
│                                                             │
│  ┌─ HyDE Pre-processing (Code + HTTP Request) ────────┐    │
│  │  Generate hypothetical answer → embed it instead    │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                │
│  ┌─ MultiQuery Expansion ─────────────────────────────┐    │
│  │  retrieverMultiQuery (3 diverse queries, gpt-4o-mini)│    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                │
│  ┌─ Cohere Reranking ─────────────────────────────────┐    │
│  │  retrieverContextualCompression + rerankerCohere    │    │
│  │  rerank-multilingual-v3.0, topN=5                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                │
│  ┌─ Citation Extraction (Code node) ──────────────────┐    │
│  │  Extract source_url, title from metadata            │    │
│  │  Format: [Source: title](url)                       │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────────────┬─────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Layer 4 — GENERATION                                       │
│                                                             │
│  AI Agent (gpt-4o)                                          │
│    + System prompt with citation instructions               │
│    + Conversation memory (memoryBufferWindow)               │
│                            ↓                                │
│  Code — Format for LINE (< 1800 chars + source links)       │
│    Phase 1: Plain text with auto-linked URLs                │
│    Phase 2: LINE Flex Messages with clickable buttons       │
│                            ↓                                │
│  LINE Reply API                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. NQ1D Metadata Schema

**NQ1D = Normalized, Queryable, 1-Document** — 每個 chunk 都是自描述的、可獨立查詢的、可追溯到原始文件的。

### Schema Definition

```javascript
{
  // Document Identity
  doc_id:            "drive_1A2B3C4D5E",       // "drive_{fileId}" | "notion_{pageId}"
  chunk_id:          "drive_1A2B3C4D5E_c003",  // "{doc_id}_c{index}"
  title:             "2025 Q1 Budget Report",

  // Source & Traceability
  source:            "drive",                   // "drive" | "notion" | "line_upload"
  source_url:        "https://drive.google.com/file/d/1A2B3C4D5E/view",
  media_type:        "text",                    // "text" | "image" | "audio" | "video"

  // Chunk Position
  chunk_index:       3,                         // 0-based
  total_chunks:      12,
  section_hierarchy: "Financial Reports > Q1 > Budget Summary",
  content_preview:   "The total budget allocated for Q1 was...",

  // Discovery & Filtering
  tags:              "budget,finance,Q1,2025",  // comma-separated (Pinecone compatibility)
  language:          "zh-TW",
  keywords:          "預算,收支,季度報告",        // LLM-extracted, for hybrid search

  // Timestamps & Dedup
  indexed_at:        "2026-03-26T08:00:00Z",
  source_modified_at: "2026-03-25T14:30:00Z",
  content_hash:      "sha256_a1b2c3d4..."      // SHA-256 of raw content, for change detection
}
```

### n8n Implementation — Code Node

```javascript
// Code — NQ1D Metadata Enrichment (placed in Flow A after text extraction)
const items = $input.all();
const results = [];

for (const item of items) {
  const content = item.json.content || '';
  const fileId = item.json.doc_id || item.json.id || '';
  const source = item.json.source || 'drive';
  const title = item.json.title || item.json.name || '';

  // Construct source_url
  let source_url = '';
  if (source === 'drive') {
    source_url = `https://drive.google.com/file/d/${fileId}/view`;
  } else if (source === 'notion') {
    source_url = `https://notion.so/${fileId.replace(/-/g, '')}`;
  }

  // Parse section hierarchy from markdown headings
  const headings = [];
  const lines = content.split('\n');
  for (const line of lines) {
    const match = line.match(/^(#{1,3})\s+(.+)/);
    if (match) {
      headings.push({ level: match[1].length, text: match[2].trim() });
    }
  }
  const hierarchy = headings.map(h => h.text).join(' > ') || title;

  results.push({
    json: {
      ...item.json,
      doc_id: `${source}_${fileId}`,
      source_url,
      section_hierarchy: hierarchy,
      content_preview: content.substring(0, 200),
      indexed_at: $now.toISO(),
      language: 'zh-TW'  // or detect dynamically
    }
  });
}

return results;
```

### Source URL Construction Rules


| Source       | Pattern                                              | Example                                       |
| ------------ | ---------------------------------------------------- | --------------------------------------------- |
| Google Drive | `https://drive.google.com/file/d/{fileId}/view`      | `https://drive.google.com/file/d/1A2B3C/view` |
| Notion       | `https://notion.so/{pageId_no_dashes}`               | `https://notion.so/abc123def456`              |
| LINE Upload  | `https://drive.google.com/file/d/{savedFileId}/view` | (saved to Drive first)                        |


---

## 3.5 Deduplication — 避免重複寫入 Embedding

### 問題

Google Drive Trigger 和 Notion Trigger 會在檔案更新時重複觸發。若不做 dedup：
- 同一份文件的 chunks 會在 Pinecone 中出現多次
- 搜尋結果重複，浪費 token 和向量儲存空間
- Reranking 效果被稀釋（同文件佔據多個 topK 位置）

### 策略：三層判斷

```
文件進入 Flow A
    ↓
Step 1: 計算 content_hash (SHA-256)
    ↓
Step 2: Query Pinecone by doc_id filter (metadata filter, topK=1)
    ↓
┌─ Case A: 不存在 → 新文件，直接 index
├─ Case B: 存在 + content_hash 相同 → 內容沒變，SKIP（不重複寫入）
└─ Case C: 存在 + content_hash 不同 → 內容已更新，DELETE old → re-index
```

### n8n Implementation — 4 個節點

#### Node 1: Code — Compute Content Hash

```javascript
// Code — Compute Hash (placed after text extraction, before NQ1D)
const crypto = require('crypto');
const items = $input.all();

return items.map(item => {
  const content = item.json.content || '';
  const hash = crypto.createHash('sha256').update(content).digest('hex').substring(0, 16);
  const fileId = item.json.id || item.json.doc_id || '';
  const source = item.json.source || 'drive';
  const docId = `${source}_${fileId}`;

  return {
    json: {
      ...item.json,
      doc_id: docId,
      content_hash: hash
    }
  };
});
```

#### Node 2: HTTP Request — Pinecone Query by doc_id

```
HTTP Request — Pinecone Check Existing
  Method: POST
  URL: https://{PINECONE_HOST}/query
  Headers:
    Api-Key: {{ $vars.PINECONE_API_KEY }}
    Content-Type: application/json
  Body:
  {
    "vector": [0, 0, 0, ...],          // dummy zero vector (1536 dims)
    "topK": 1,
    "includeMetadata": true,
    "filter": {
      "doc_id": { "$eq": "={{ $json.doc_id }}" }
    }
  }
```

**Why zero vector?** 我們不需要語意搜尋，只需要 metadata filter。用零向量 + filter 是 Pinecone 支援的 metadata-only query 模式。

#### Node 3: Code — Dedup Decision

```javascript
// Code — Dedup Decision
const matches = $json.matches || [];
const currentHash = $('Code — Compute Hash').item.json.content_hash;
const docId = $('Code — Compute Hash').item.json.doc_id;

if (matches.length === 0) {
  // Case A: New document — proceed to index
  return [{
    json: {
      ...$('Code — Compute Hash').item.json,
      dedup_action: 'INDEX',
      old_vector_ids: []
    }
  }];
}

const existingHash = matches[0].metadata?.content_hash || '';

if (existingHash === currentHash) {
  // Case B: Same content — skip
  return [{
    json: {
      doc_id: docId,
      dedup_action: 'SKIP',
      reason: 'content_hash unchanged'
    }
  }];
}

// Case C: Content changed — need to delete old vectors first
// Collect ALL old vector IDs for this doc_id (not just the one match)
return [{
  json: {
    ...$('Code — Compute Hash').item.json,
    dedup_action: 'UPDATE',
    old_doc_id: docId
  }
}];
```

#### Node 4: Code — Route by Dedup Action

```javascript
// Code — Route Dedup
const action = $json.dedup_action;

if (action === 'SKIP') {
  // Return empty — stops this branch, document not re-indexed
  return [];
}

// INDEX or UPDATE — proceed to NQ1D enrichment
return [$input.first()];
```

#### Node 5 (UPDATE only): HTTP Request — Pinecone Delete Old Vectors

```
HTTP Request — Pinecone Delete by doc_id
  Method: POST
  URL: https://{PINECONE_HOST}/vectors/delete
  Headers:
    Api-Key: {{ $vars.PINECONE_API_KEY }}
    Content-Type: application/json
  Body:
  {
    "filter": {
      "doc_id": { "$eq": "={{ $json.old_doc_id }}" }
    }
  }
```

### Complete Dedup Flow in Flow A

```
Download File / Extract Content
    ↓
Code — Compute Content Hash
    ↓
HTTP Request — Pinecone Check Existing (query by doc_id filter)
    ↓
Code — Dedup Decision
    ↓
Code — Route (SKIP → stop | INDEX/UPDATE → continue)
    ↓
[UPDATE only] HTTP Request — Pinecone Delete Old Vectors
    ↓
Code — NQ1D Metadata Enrichment
    ↓
Code — Token-Aware Chunking
    ↓
HTTP Request — OpenAI Embeddings
    ↓
HTTP Request — Pinecone Upsert
```

### Pinecone Vector ID Convention

為了讓 delete-by-filter 更可靠，vector ID 使用 `{doc_id}_c{chunk_index}` 格式：

```javascript
// In the Pinecone Upsert Code node
const vectorId = `${docId}_c${String(chunkIndex).padStart(4, '0')}`;
// Example: "drive_1A2B3C4D5E_c0003"
```

這樣 `filter: { doc_id: { $eq: "drive_1A2B3C4D5E" } }` 可以精確刪除該文件的所有 chunks。

### Flow C Watchdog — 定期清理孤兒向量

在 Flow C 的 Nightly 排程中加一個清理步驟：

```javascript
// Code — Orphan Detection (in Flow C nightly)
// Query Pinecone for all unique doc_ids
// Cross-check with Google Drive / Notion
// If source file deleted → delete orphan vectors

// Implementation:
// 1. HTTP Request — Pinecone list vectors (paginated)
// 2. Code — Extract unique doc_ids from metadata
// 3. HTTP Request — Google Drive check file exists (batch)
// 4. Code — Find orphans (doc_id exists in Pinecone but file deleted)
// 5. HTTP Request — Pinecone delete by orphan doc_ids
```

### Gap Analysis Update

| 能力 | 現況 | 目標 | 優先級 |
|------|------|------|--------|
| Deduplication | 無（重複觸發 = 重複寫入） | content_hash + doc_id filter + delete-before-upsert | **P0** |

---

## 4. Advanced Retrieval Strategy

### 4.1 HyDE (Hypothetical Document Embeddings)

**What:** Instead of embedding the raw user query, first use an LLM to generate a hypothetical paragraph that would answer the question, then embed THAT paragraph. This produces an embedding closer to the actual answer vectors in the database.

**Why:** Raw queries like "預算多少" are short and ambiguous. A hypothetical answer like "2025 年 Q1 的總預算為 150 萬元，其中人事費用佔 60%..." is semantically much closer to the actual stored chunks.

**n8n Implementation:**

```
User Query: "去年迎新的場地在哪裡？"
                    ↓
Code — HyDE Prompt Builder
  prompt: "Given the question: {query}, write a detailed hypothetical
           paragraph that would perfectly answer this question.
           Write in Traditional Chinese."
                    ↓
HTTP Request — OpenAI Chat Completions (gpt-4o-mini, temperature=0.7)
                    ↓
Code — Extract Hypothetical Answer
  hypothetical: "去年社團迎新活動在台北市信義區的某某活動中心舉辦，
                 場地租金為每小時 2000 元，可容納 80 人..."
                    ↓
Set — Replace queryText with hypothetical answer
                    ↓
AI Agent (embeds the hypothetical answer, not the original query)
```

**Code Node — HyDE Prompt Builder:**

```javascript
const query = $json.queryText;
return [{
  json: {
    originalQuery: query,
    hydePrompt: `Given the question: "${query}"\n\nWrite a detailed hypothetical paragraph (in Traditional Chinese) that would perfectly answer this question. Include specific details, names, numbers, and context that a real answer document would contain. Output ONLY the paragraph, no preamble.`
  }
}];
```

### 4.2 MultiQuery Expansion

**What:** Auto-generate 3 diverse reformulations of the query, retrieve for each, then merge results.

**n8n Node:** `retrieverMultiQuery` (native LangChain node)

**Configuration:**

```
queryCount: 3
ai_languageModel: OpenAI Chat Model (gpt-4o-mini)  // fast & cheap
ai_retriever: retrieverVectorStore → Pinecone
```

**Example expansion:**

```
Original: "社費收支報告"
Query 1:  "社團經費收入支出明細表"
Query 2:  "財務報告社費總額統計"
Query 3:  "收支結算預算對比"
```

### 4.3 Cohere Reranking

**What:** After retrieving top-K results from vector search, use a cross-encoder model to re-score and reorder them by relevance.

**n8n Nodes:**

- `retrieverContextualCompression` — wrapper that applies reranking
- `rerankerCohere` — Cohere rerank model

**Configuration:**

```
model: rerank-multilingual-v3.0   // supports zh-TW
topN: 5                           // return top 5 after reranking
```

**Credential needed:** Cohere API key (`cohereApi`)

### 4.4 Complete Retrieval Chain Wiring

```
AI Agent
  ├── ai_languageModel: OpenAI Chat Model (gpt-4o)
  │     model: "gpt-4o"
  │
  ├── ai_memory: Window Buffer Memory
  │     sessionIdType: "customKey"
  │     sessionKey: "={{ $json.userId }}"  // LINE user ID
  │     contextWindowLength: 10
  │
  └── ai_tool: Pinecone Vector Store (retrieve-as-tool)
        mode: "retrieve-as-tool"
        toolDescription: "Search the multimodal knowledge base..."
        topK: 20  // retrieve more, let reranker filter
        │
        └── ai_retriever: Contextual Compression Retriever
              │
              ├── ai_retriever: MultiQuery Retriever
              │     queryCount: 3
              │     │
              │     ├── ai_languageModel: OpenAI Chat Model
              │     │     model: "gpt-4o-mini"  // fast for query generation
              │     │
              │     └── ai_retriever: Vector Store Retriever
              │           │
              │           └── Pinecone Vector Store (retrieve mode)
              │                 │
              │                 └── ai_embedding: Embeddings OpenAI
              │                       model: "text-embedding-3-small"
              │
              └── ai_reranker: Cohere Reranker
                    model: "rerank-multilingual-v3.0"
                    topN: 5
```

### 4.5 Hybrid Search — Keyword Metadata Filtering

**Phase 1 approach:** At index time, extract keywords and store as metadata. At query time, use Pinecone metadata filters to pre-filter before vector similarity.

**Index-time keyword extraction (Code node in Flow A):**

```javascript
// After NQ1D enrichment, before Pinecone upsert
// Use the content to extract keywords via simple TF approach
const content = $json.content || '';
const words = content.match(/[\u4e00-\u9fff]{2,4}/g) || []; // CJK 2-4 char terms
const freq = {};
words.forEach(w => freq[w] = (freq[w] || 0) + 1);
const keywords = Object.entries(freq)
  .sort((a, b) => b[1] - a[1])
  .slice(0, 10)
  .map(([w]) => w)
  .join(',');

return [{ json: { ...item.json, keywords } }];
```

**Query-time filtering:** The AI Agent's system prompt can instruct it to use metadata filters when querying Pinecone, or a Code node can pre-extract keywords from the query and pass them as filter parameters.

---

## 5. Citation & Source Linking

### 5.1 AI Agent System Prompt (Citation-Aware)

```
You are a multimodal knowledge base assistant for a club/organization.

RULES:
1. Answer ONLY based on retrieved context. Never fabricate information.
2. Use Traditional Chinese.
3. After each factual claim, cite the source: [來源: {title}]({source_url})
4. At the end, list all referenced sources with clickable URLs.
5. Keep total response under 1800 characters (LINE limit).
6. If no relevant context found, say so honestly.

CITATION FORMAT:
根據預算報告 [來源: 2025Q1預算](https://drive.google.com/file/d/xxx/view)，
本季度總預算為 150 萬元。

SOURCES:
1. 2025Q1預算 - https://drive.google.com/file/d/xxx/view
2. 社團章程 - https://notion.so/abc123
```

### 5.2 Phase 1 — Plain Text with Auto-linked URLs

LINE automatically detects URLs in text messages and makes them clickable. No special formatting needed.

```
回答文字內容...

參考來源：
1. 2025Q1預算報告
   https://drive.google.com/file/d/1A2B3C/view
2. 社團迎新企劃書
   https://notion.so/abc123def456
```

### 5.3 Phase 2 — LINE Flex Messages

For richer formatting with clickable buttons:

```javascript
// Code — Build Flex Message
const answer = $json.output;
const sources = $json.sources || []; // extracted from AI Agent response

const bubbles = [{
  type: "bubble",
  body: {
    type: "box",
    layout: "vertical",
    contents: [{
      type: "text",
      text: answer.substring(0, 1600),
      wrap: true,
      size: "sm"
    }]
  },
  footer: {
    type: "box",
    layout: "vertical",
    contents: sources.slice(0, 3).map(s => ({
      type: "button",
      action: {
        type: "uri",
        label: s.title.substring(0, 20),
        uri: s.source_url
      },
      style: "link",
      height: "sm"
    }))
  }
}];

return [{
  json: {
    type: "flex",
    altText: answer.substring(0, 60),
    contents: { type: "carousel", contents: bubbles }
  }
}];
```

---

## 6. n8n Template Reference Map

### Core Architecture Templates


| Component              | Template ID | Name                                                | Views  | Key Takeaway                                                         |
| ---------------------- | ----------- | --------------------------------------------------- | ------ | -------------------------------------------------------------------- |
| **MinerU doc parsing** | **4808**    | Convert Docs to Markdown + MinerU API + GPT-4o-mini | 448    | MinerU Cloud API, PDF/Word/PPT → Markdown, OCR + 表格 + 公式辨識 |
| Drive → Vector DB      | **2982**    | AI RAG Chatbot + Google Drive + Gemini + Qdrant     | 65,428 | Token Splitter config, metadata extraction, batch loop               |
| Drive sync backbone    | **5140**    | Build & Update RAG + Google Drive + Qdrant + Gemini | 1,967  | Incremental update/delete, change detection pattern                  |
| PDF OCR → RAG          | **4400**    | PDF RAG + Mistral OCR + Qdrant + Gemini             | 20,271 | OCR pipeline, scanned PDF handling                                   |


### Retrieval & Citation Templates


| Component            | Template ID | Name                                            | Views | Key Takeaway                                   |
| -------------------- | ----------- | ----------------------------------------------- | ----- | ---------------------------------------------- |
| Citation formatting  | **2693**    | OpenAI Citation for File Retrieval RAG          | 3,456 | Source attribution pattern, file ID resolution |
| Document Q&A         | **5807**    | Document Q&A + OpenAI + Pinecone + Google Drive | —     | Webhook → Pinecone → answer pattern            |
| Chatbot with sources | **2165**    | Chat with PDF docs using AI (quoting sources)   | —     | Citation with page numbers                     |


### LINE Bot Templates


| Component       | Template ID | Name                                            | Views | Key Takeaway                             |
| --------------- | ----------- | ----------------------------------------------- | ----- | ---------------------------------------- |
| LINE API shell  | **2733**    | Line Message API: push & reply                  | 8,382 | Reply token pattern, push message format |
| LINE + files    | **3191**    | LINE files → Google Drive + Sheets logging      | —     | Content download, file type detection    |
| LINE + AI agent | **2874**    | LINE BOT + Google Sheets file lookup + AI agent | —     | Agent → LINE reply integration           |
| LINE + memory   | **3600**    | Line chatbot + Google Sheets memory + Gemini    | —     | Conversation history persistence         |


### Multimodal Processing Templates


| Component            | Template ID | Name                                              | Views  | Key Takeaway                |
| -------------------- | ----------- | ------------------------------------------------- | ------ | --------------------------- |
| Image/PDF processing | **3078**    | 5 ways to process images & PDFs with Gemini       | —      | Multimodal input patterns   |
| OCR extraction       | **3102**    | Parse/Extract from Documents/Images + Mistral OCR | 30,378 | Multi-page PDF, image OCR   |
| Doc → Markdown       | **4808**    | Convert documents to Markdown + MinerU API        | —      | Word/PPT/PDF → unified text |
| Doc conversion       | **7887**    | Convert PDF/DOC/images to Markdown + Datalab      | —      | Multi-format input handling |


---

## 7. Implementation Roadmap

### Phase 1 — Foundation (P0)

**Goal:** NQ1D metadata + citation + embedding consistency

**Flow A Changes:**

1. **Register MinerU Cloud API** at https://mineru.net, set `MINERU_API_KEY` in n8n Variables
2. Add MinerU HTTP Request nodes (submit → poll → download Markdown) for PDF/DOCX/PPTX path
3. Update MIME routing: pdf/docx/pptx → MinerU Cloud API path (new), text → passthrough, image/audio/video → existing paths
3. **Add dedup pipeline** before indexing: content_hash → Pinecone query by doc_id → skip/delete-old/index decision
4. Add `Code — NQ1D Metadata Enrichment` after each media processing branch (MinerU Markdown output preserves headings → richer hierarchy)
5. Add `source_url` construction for every document
6. Switch to token-aware chunking (Code node, 512 tokens / 64 overlap)
7. Use HTTP Request for Pinecone upsert (full metadata control, vector ID = `{doc_id}_c{index}`)
8. Standardize embedding model to `text-embedding-3-small`

**Flow B Changes:**

1. Update AI Agent system prompt with citation instructions
2. Add `Code — Citation Formatter` after AI Agent, before LINE reply
3. Standardize embedding model to `text-embedding-3-small`

**New Credential:** `MINERU_API_KEY` (n8n Variables, 免費申請 https://mineru.net)

**Risk:** Must re-index all existing documents after metadata schema change.

**Verification:**

- Upload PDF to Google Drive → check Pinecone metadata has all 12+ NQ1D fields (including `content_hash`)
- Upload image → verify `source_url` is correct Drive link
- **Re-upload same PDF (unchanged) → verify SKIP (no new vectors written)**
- **Edit PDF and re-upload → verify old vectors deleted + new vectors written**
- Query via LINE → verify response includes clickable source URLs
- Check all embeddings are 1536-dimensional
- Check vector IDs follow `{doc_id}_c{index}` convention

---

### Phase 2 — Advanced Retrieval (P1)

**Goal:** HyDE + MultiQuery + Reranking + Conversation Memory

**Flow B Changes:**

1. Add `Code — HyDE Prompt Builder` + `HTTP Request — OpenAI` before AI Agent
2. Replace simple Pinecone retrieve-as-tool with chained retrieval:
  - `retrieverMultiQuery` (3 queries, gpt-4o-mini)
  - `retrieverContextualCompression` + `rerankerCohere`
3. Add `memoryBufferWindow` to AI Agent (keyed by LINE userId)
4. Increase initial topK from 5 to 20 (reranker reduces to 5)

**New Credential:** `cohereApi` (Cohere API key)

**Risk:** Latency increases with HyDE + MultiQuery + Reranking chain. Must stay under 25 seconds (LINE reply timeout = 30s).

**Mitigation:**

- Use `gpt-4o-mini` for HyDE and query expansion (fast)
- Use `gpt-4o` only for final generation
- Monitor execution times in n8n

**Verification:**

- Ask vague question → check execution log shows 3 generated sub-queries
- Compare retrieval quality before/after reranking (manual spot check)
- Ask follow-up question → verify conversation memory retains context
- Measure end-to-end latency < 25 seconds

---

### Phase 3 — Polish (P2)

**Goal:** Hybrid search + Flex Messages + Quality checks + Dedup

**Flow A Changes:**

1. Add keyword extraction in NQ1D enrichment (LLM-based, 10 keywords per chunk)
2. Add orphan vector cleanup in Flow C nightly (cross-check Pinecone doc_ids vs Google Drive/Notion)

**Flow B Changes:**

1. Upgrade LINE reply from plain text to Flex Messages with clickable source buttons
2. Add metadata filter support in retrieval (keyword-based pre-filtering)

**Flow C Changes:**

1. Replace placeholder quality check with actual Pinecone queries:
  - Code node generates test queries
  - HTTP Request embeds each query via OpenAI
  - HTTP Request queries Pinecone with embedding
  - Code node extracts scores and compiles report

**New Credential:** None

**Verification:**

- Delete a Google Drive file → verify nightly cleanup removes orphan vectors from Pinecone
- Test Flex Message rendering on LINE mobile (iOS + Android)
- Weekly quality check generates real scores from Pinecone
- Keyword-filtered query returns more relevant results than unfiltered

---

## 8. Workflow Architecture (Final State)

```
┌─────────────────────────────────────────────────────────┐
│                    4 Workflows                           │
│                                                         │
│  Flow A — Enterprise Multimodal Indexing Pipeline        │
│    Nodes: ~25                                           │
│    Triggers: Google Drive, Notion                       │
│    Key additions: NQ1D enrichment, token chunking,      │
│                   keyword extraction, dedup check        │
│                                                         │
│  Flow B — Enterprise Multimodal LINE Bot                │
│    Nodes: ~30                                           │
│    Triggers: LINE Webhook                               │
│    Key additions: HyDE, MultiQuery, Cohere reranker,    │
│                   citation formatter, Flex Message,      │
│                   conversation memory                    │
│                                                         │
│  Flow C — Enhanced Watchdog                             │
│    Nodes: ~20                                           │
│    Triggers: Error, 3x Schedule                         │
│    Key additions: Real Pinecone quality checks           │
│                                                         │
│  (Optional) Flow D — LINE File Upload Handler           │
│    Nodes: ~10                                           │
│    Trigger: LINE Webhook (file/image message)           │
│    Purpose: Save LINE uploads to Drive, trigger Flow A   │
│    Reference: Template 3191                              │
└─────────────────────────────────────────────────────────┘
```

---

## 9. n8n JSON Constraints (Hard Rules)

Based on extensive import debugging, these patterns are mandatory:


| Rule                                                                | Reason                                                                        |
| ------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Use **Code nodes** for routing                                      | Switch node `rules.rules` vs `rules.values` schema breaks across versions     |
| Use **HTTP Request** for Notion writes                              | Native Notion node `propertiesUi` key format (`|title`, `|select`) is fragile |
| All `__rl` use `**mode: "id"`**                                     | `mode: "list"` requires cached options, fails with placeholder values         |
| Schedule Triggers use `**triggerAtHour/triggerAtMinute**`           | `cronExpression` field not available in all versions                          |
| Set node assignments **without `id` field**                         | Simpler, more portable                                                        |
| **No `cachedResultName`** in resource locators                      | Coupled to specific n8n instance state                                        |
| **Community LINE nodes** require `@aotoki/n8n-nodes-line-messaging` | Not built-in, must be installed                                               |


---

## 10. Glossary


| Term                 | Definition                                                 |
| -------------------- | ---------------------------------------------------------- |
| **NQ1D**             | Normalized, Queryable, 1-Document — 每個 chunk 自描述、可追溯到原始文件  |
| **HyDE**             | Hypothetical Document Embeddings — 先生成假設性答案再做 embedding 檢索 |
| **MultiQuery**       | 將一個查詢自動展開為多個不同表述，擴大召回範圍                                    |
| **Reranking**        | 對初步檢索結果用 cross-encoder 重新評分排序，提升精確度                        |
| **Hybrid Search**    | Dense (向量相似度) + Sparse (關鍵字/BM25) 混合檢索策略                   |
| **Flex Message**     | LINE 的富文本訊息格式，支援按鈕、連結、卡片式排版                                |
| **retrieve-as-tool** | n8n 中 Vector Store 作為 AI Agent 工具使用的模式                     |
| **Citation**         | 回答中標注資訊來源，附帶可追溯的文件連結                                       |


---

## 11. Appendix — Key n8n Node Types

### Vector Store & Retrieval


| Node                   | Type                                                      | Purpose                            |
| ---------------------- | --------------------------------------------------------- | ---------------------------------- |
| Pinecone Vector Store  | `@n8n/n8n-nodes-langchain.vectorStorePinecone`            | Insert & retrieve vectors          |
| Vector Store Retriever | `@n8n/n8n-nodes-langchain.retrieverVectorStore`           | Standard similarity retrieval      |
| MultiQuery Retriever   | `@n8n/n8n-nodes-langchain.retrieverMultiQuery`            | Auto query expansion               |
| Contextual Compression | `@n8n/n8n-nodes-langchain.retrieverContextualCompression` | Post-retrieval filtering/reranking |
| Cohere Reranker        | `@n8n/n8n-nodes-langchain.rerankerCohere`                 | Cross-encoder reranking            |


### Document Processing


| Node                    | Type                                                                  | Purpose                                                      |
| ----------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------ |
| **MinerU Cloud API**    | `n8n-nodes-base.httpRequest` (3 nodes: submit/poll/download)          | **PDF/Word/PPT → Markdown via https://mineru.net/api/v4** |
| Default Data Loader     | `@n8n/n8n-nodes-langchain.documentDefaultDataLoader`                  | Load text/binary into document chain                         |
| Recursive Text Splitter | `@n8n/n8n-nodes-langchain.textSplitterRecursiveCharacterTextSplitter` | Character-based chunking                                     |
| Token Text Splitter     | `@n8n/n8n-nodes-langchain.textSplitterTokenSplitter`                  | Token-aware chunking (recommended)                           |
| OpenAI Embeddings       | `@n8n/n8n-nodes-langchain.embeddingsOpenAi`                           | Generate embedding vectors                                   |


### AI Agent & Memory


| Node                 | Type                                          | Purpose                              |
| -------------------- | --------------------------------------------- | ------------------------------------ |
| AI Agent             | `@n8n/n8n-nodes-langchain.agent`              | Orchestrate tools + generate answers |
| OpenAI Chat Model    | `@n8n/n8n-nodes-langchain.lmChatOpenAi`       | LLM for generation                   |
| Window Buffer Memory | `@n8n/n8n-nodes-langchain.memoryBufferWindow` | Sliding window conversation history  |


