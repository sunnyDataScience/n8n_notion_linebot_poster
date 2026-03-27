# n8n 節點分類教科書：從零到戰情室

> 本教科書整合「API 與資料交換基礎概念」及「資料格式與網頁結構」兩份補充教材，
> 以 13 堂循序漸進的 Workflow 範例，帶你從按下第一個按鈕到建出主管戰情室。
>
> **每堂課 = 一個可匯入的 JSON 檔案 + 對應的概念解說。**

---

## 目錄

| 課程 | 檔案 | 核心概念 | 難度 |
|------|------|---------|------|
| [L01](#l01--hello-n8n) | L01_hello_n8n.json | Workflow 基礎、Trigger、節點連線 | ★ |
| [L02](#l02--json-資料流) | L02_json_data_flow.json | JSON 結構、Expression、IF 分流 | ★ |
| [L03](#l03--http-request) | L03_http_get_public_api.json | HTTP GET / POST、公開 API、RESTful | ★★ |
| [L04](#l04--三種-trigger) | L04_trigger_types.json | Manual / Schedule / Webhook | ★★ |
| [L05](#l05--if-與-switch) | L05_if_switch_routing.json | 條件判斷、多路由、Switch | ★★ |
| [L06](#l06--資料轉換) | L06_data_transform.json | Set 計算、Python Code 彙總 | ★★★ |
| [L07](#l07--認證與-credential) | L07_credential_and_auth.json | API Key、Bearer Token、401 錯誤 | ★★★ |
| [L08](#l08--整合節點-fan-out) | L08_integrations_fanout.json | 專用節點 vs HTTP、Fan-out 模式 | ★★★ |
| [L09](#l09--資料格式實戰) | L09_data_formats_rss_html.json | RSS / JSON / HTML 三種格式比較 | ★★★ |
| [L10](#l10--ai-agent) | L10_ai_sales_advisor.json | Chat Trigger、LLM Agent、Memory | ★★★★ |
| [L11](#l11--error-handling-與監控) | L11_error_and_monitoring.json | Error Trigger、SLA 監控、警報分流 | ★★★★ |
| [L12](#l12--主管戰情室) | L12_full_pipeline_dashboard.json | Fan-out → Merge、多維度報表 | ★★★★★ |
| [L13](#l13--no-code-報表) | L13_nocode_google_sheets.json | Summarize 節點、Google Sheets 輸出 | ★★★ |

---

## 前置知識：n8n 是什麼角色？

### 膠水層（Glue Layer）

n8n 不是 CRM，不是資料庫，不是聊天工具。**n8n 是把這些東西「黏在一起」的膠水。**

```
                    ┌─── Slack
                    │
CRM ──→ n8n ──→ ───┼─── Google Sheets
                    │
LINE ──→ n8n ──→ ───┼─── Email
                    │
Webhook ──→ n8n ──→ ┴─── Database
```

n8n 做三件事：**接收** → **處理** → **輸出**。

要當好膠水，n8n 必須：

| 能力 | 需要懂的概念 | 對應課程 |
|------|------------|---------|
| 看懂各系統的資料 | JSON、CSV、XML、RSS、HTML | L01、L02、L09 |
| 跟各系統溝通 | API、HTTP、RESTful | L03、L08 |
| 證明自己有權限 | 認證、Token、Credential | L07 |
| 被動等通知 | Webhook | L04 |
| 對方沒開窗口 | 爬蟲（HTML Extract） | L09 |

---

# 第一部分：基礎操作（L01 — L02）

---

## L01 — Hello n8n

**檔案：** `L01_hello_n8n.json`

### 你的第一個 Workflow

```
Manual Trigger → Edit Fields — 加上問候語
```

### 學習目標

1. 認識 n8n 的介面
2. 了解「節點」和「連線」
3. 按下 Execute 看結果

### 核心觀念

**每個 Workflow 都從 Trigger 開始。** 資料像水一樣從左流到右，每個節點都會產出資料給下一個節點。

### 概念解說：JSON — 資料的共同語言

> JSON 就是「系統之間溝通用的格式」，像是大家都看得懂的表格。

你去餐廳點餐，點餐單長這樣：

```
品項：拿鐵
數量：2
備註：少冰
```

如果全世界的餐廳都用同一種格式寫點餐單，廚師不管在哪間店都看得懂。**JSON 就是這個「全世界都看得懂的點餐單格式」。**

#### 實際長什麼樣

```json
{
  "customer": "鴻海精密工業",
  "product": "企業雲端方案 Pro",
  "amount": 640000,
  "stage": "提案中",
  "salesRep": "林志明"
}
```

#### 重點規則（只有四條）

| 規則 | 說明 | 範例 |
|------|------|------|
| 用大括號 `{}` 包起來 | 代表「一筆資料」 | `{ ... }` |
| 用 `"key": value` 表示 | 左邊是欄位名，右邊是值 | `"amount": 640000` |
| 文字要加引號 | 數字不用 | `"stage": "提案中"` vs `"amount": 640000` |
| 用中括號 `[]` 表示多筆 | 代表「一組資料」 | `[{...}, {...}]` |

#### n8n 裡面全部都是 JSON

```
每一筆資料 = 一個 { json: { ... } }
多筆資料 = [ { json: {...} }, { json: {...} } ]
```

在 L01 中，Manual Trigger 透過 pinData 預設了一筆銷售資料（JSON 格式），Edit Fields 節點用 Expression `{{ $json.customer }}` 取出上游的值，組合成問候語。

### 操作步驟

1. 匯入 `L01_hello_n8n.json`
2. 按右上角「Test Workflow」
3. 點擊「Edit Fields — 加上問候語」節點
4. 看右邊面板的「輸出」—— 這就是 JSON！

### pinData（預設的假資料）

```json
{
  "id": 1,
  "salesRep": "林志明",
  "customer": "鴻海精密工業",
  "amount": 640000,
  "stage": "提案中",
  "probability": 30
}
```

> **pinData** 讓你不用真的串 API 就能測試。改 pinData 的值，重新執行，看 Edit Fields 的輸出跟著變。

---

## L02 — JSON 資料流

**檔案：** `L02_json_data_flow.json`

### 看懂節點之間傳了什麼

```
Manual Trigger (3 筆) → Edit Fields — 加工計算 → IF — 高價值商機？
                                                    ├→ 高價值 — 標記
                                                    └→ 一般 — 標記
```

### 學習目標

1. 理解 JSON 的 key-value 結構
2. 學會用 Expression 取值和計算
3. 觀察「多筆資料」如何逐筆流動
4. IF 節點根據計算結果分流

### 概念解說：Expression 語法

Expression 是 n8n 裡面取值和運算的方式，寫在 `{{ }}` 裡面：

| 用途 | 語法 | 範例 |
|------|------|------|
| 取值 | `{{ $json.欄位名 }}` | `{{ $json.salesRep }}` → 林志明 |
| 數學運算 | `{{ $json.a * $json.b }}` | `{{ $json.amount * $json.probability / 100 }}` |
| 判斷 | `{{ $json.x >= n }}` | `{{ $json.amount >= 1000000 }}` → true / false |
| 文字組合 | `{{ $json.a }} — {{ $json.b }}` | 林志明 — 台積電 |

### 概念解說：結構化 vs 非結構化

想像你收到兩種業績報告：

**報告 A（結構化）：**
```
業務：黃淑芬
客戶：統一企業
金額：816,000
階段：合約審核
```

**報告 B（非結構化）：**
```
黃淑芬上週跟統一的案子進到合約審核了，金額大概八十幾萬，
法務那邊已經在看了，應該月底前會簽。
```

兩份報告講的是同一件事。但報告 A，程式一秒就能讀懂。報告 B，程式需要「理解中文」才能處理。

| | 結構化資料 | 非結構化資料 |
|---|---|---|
| 定義 | 有固定格式、固定欄位 | 自由格式，沒有固定規則 |
| 程式能直接讀嗎 | 可以 | 需要額外解析 |
| 格式 | JSON、CSV、XML、RSS | HTML、PDF、圖片、自由文字 |
| 比喻 | Excel 表格 | Word 文件 |

> **n8n 最喜歡結構化資料。** 如果你拿到的是非結構化的，第一步就是想辦法把它變成結構化。

### 範例中的三筆資料

| 客戶 | 金額 | 結果 |
|------|------|------|
| 台積電 | $1,500,000 | → 高價值（≥ 100 萬） |
| 悠遊卡公司 | $180,000 | → 一般 |
| 巨大機械（捷安特） | $1,400,000 | → 高價值 |

### 動手試試

1. 執行後，點每個節點看 Output
2. 觀察 3 筆資料怎麼分成兩路
3. 改 pinData 的 amount 再跑一次

---

# 第二部分：與外部溝通（L03 — L04）

---

## L03 — HTTP Request

**檔案：** `L03_http_get_public_api.json`

### 查台灣公開資料 + POST 到 CRM

```
Manual Trigger → Edit Fields — 銷售資料
                    ├→ GET — 台幣即時匯率
                    ├→ GET — 台積電月成交資訊
                    └→ POST — 送出銷售資料到 CRM (httpbin)
```

### 學習目標

1. **GET** = 「讀取」資料（免認證公開 API）
2. **POST** = 「送出」資料（模擬寫入 CRM）
3. Expression `{{ $json.xxx }}` 取上游資料動態帶入

### 概念解說：API — 系統之間的服務窗口

> API 就是「一個系統開給另一個系統用的服務窗口」。

想像你去銀行辦事：

```
你（客戶）  →  櫃台窗口（API）  →  銀行內部系統

你不需要知道銀行內部怎麼運作。
你只需要知道：
  - 哪個窗口辦什麼事（哪個 API 做什麼功能）
  - 要帶什麼資料（API 需要什麼參數）
  - 會拿到什麼回覆（API 回傳什麼結果）
```

在 n8n 裡面：
- **專用節點**（Slack、Google Sheets、Notion）= 已經幫你包好的 API 窗口
- **HTTP Request 節點** = 萬用窗口，什麼 API 都能打

### 概念解說：HTTP 請求 — 你怎麼跟窗口溝通

你走到餐廳櫃台（API），你可以：

| 你的動作 | HTTP 方法 | 意思 |
|---------|----------|------|
| 「我要看菜單」 | **GET** | 拿資料（只看，不改） |
| 「我要點一份拿鐵」 | **POST** | 新增資料（建立新東西） |
| 「我要改成去冰」 | **PUT / PATCH** | 修改資料 |
| 「我要取消訂單」 | **DELETE** | 刪除資料 |

#### 一個完整的 HTTP 請求

```
1. 方法（Method）：POST
2. 網址（URL）：https://crm.example.com/api/deals
3. 標頭（Headers）：告訴對方「我是誰」「我用什麼格式」← 認證放這裡
4. 內容（Body）：你要傳的資料（JSON 格式）
```

#### 常見狀態碼（記這五個就夠）

| 狀態碼 | 意思 | 比喻 |
|--------|------|------|
| **200** | 成功 | 「好的，辦好了」 |
| **201** | 成功建立 | 「好的，新帳戶開好了」 |
| **401** | 未授權 | 「你是誰？不認識你」 |
| **403** | 禁止存取 | 「認識你，但你沒這個權限」 |
| **404** | 找不到 | 「沒有這個東西」 |

### 概念解說：RESTful — 窗口的設計規範

> RESTful 是「大家約定好的 API 設計方式」，讓你看到網址就知道在做什麼。

| 你要做什麼 | HTTP 方法 | URL |
|-----------|----------|-----|
| 看所有商機 | GET | `/api/deals` |
| 看某一筆商機 | GET | `/api/deals/123` |
| 建立新商機 | POST | `/api/deals` |
| 修改商機 | PUT | `/api/deals/123` |
| 刪除商機 | DELETE | `/api/deals/123` |

看到 URL + Method 就知道在做什麼 —— 這就是 RESTful 的好處。

### 範例中的三條路徑

#### 路徑 1：GET 台幣匯率

```
URL: https://tw.rter.info/capi.php
Method: GET
參數: 無
回傳: JSON（各幣別匯率）
```

這是最簡單的 API 呼叫 —— 不需要認證，不需要參數，直接拿到乾淨的 JSON。

#### 路徑 2：GET 台積電月成交資訊

```
URL: https://www.twse.com.tw/exchangeReport/STOCK_DAY
Method: GET
參數:
  response = json
  date     = {{ $json.queryDate }}    ← 從 Edit Fields 動態取
  stockNo  = {{ $json.stockNo }}      ← 從 Edit Fields 動態取
```

注意 Query Parameters 都是從上游節點用 Expression 動態帶入的。改 Edit Fields 一個地方，GET 就換股票/月份。

#### 路徑 3：POST 銷售資料到 httpbin

```
URL: https://httpbin.org/post
Method: POST
Body:
  dealId   = DEAL-{{ $now.toFormat("yyyyMMddHHmmss") }}
  salesRep = {{ $json.salesRep }}
  customer = {{ $json.customer }}
  amount   = {{ $json.amount }}
  action   = create_deal
```

httpbin 是「回音壁」—— 你送什麼它回什麼。看 Output 的 `form` 欄位，確認上游資料有帶過來。

### 台灣常用公開 API

| API | 來源 | 需認證 |
|-----|------|-------|
| tw.rter.info（匯率） | 即時匯率 | 免 |
| twse.com.tw（股市） | 證交所 | 免 |
| data.gov.tw（政府開放資料） | 各部會 | 免 |
| 中央氣象署（天氣） | 氣象署 | 需 API Key |
| 環境部（空氣品質） | 環境部 | 需 API Key |

> 需要 Key 的 API → 見 L07。

### 動手試試

- `stockNo` → 2317（鴻海）/ 2454（聯發科）/ 0050（元大台灣50）
- `queryDate` → 20250201（2月）/ 20241201（去年12月）
- 重新執行，三路結果同時變化

---

## L04 — 三種 Trigger

**檔案：** `L04_trigger_types.json`

### 「誰」來啟動你的 Workflow？

```
Manual Trigger ──────→ Format Deal Record → Respond to Webhook
Schedule Trigger ────→       ↑
Webhook Trigger ─────→       ↑
```

三個 Trigger 匯聚（Fan-in）到同一個處理節點。

### 學習目標

1. 認識三種觸發方式的差異
2. 理解 Fan-in 模式（多入口 → 一個處理）
3. 體驗 Webhook 的「被動等通知」概念

### 三種觸發方式比較

| Trigger | 何時啟動 | 使用場景 | 比喻 |
|---------|---------|---------|------|
| **Manual** | 你手動按按鈕 | 開發測試 | 自己按門鈴 |
| **Schedule** | 定時（每小時/每天） | 排程報表、定時同步 | 鬧鐘 |
| **Webhook** | 外部系統 POST 進來 | CRM 通知、LINE Bot | 有人打你電話 |

### 概念解說：Webhook — 反過來，系統主動通知你

> Webhook 是「不是你去問，而是對方有事會主動打電話給你」。

**沒有 Webhook（輪詢）：**
```
你每 10 分鐘打電話給快遞：「我的包裹到了嗎？」
快遞：「還沒。」
...重複 100 次...
```

**有 Webhook：**
```
你跟快遞說：「到了打我電話 0912-345-678」
包裹到了 → 快遞主動通知你
```

**Webhook 就是你給對方一個網址（電話號碼），有事他會主動通知你。**

| | API（你去問） | Webhook（他來通知） |
|---|---|---|
| 方向 | 你 → 對方 | 對方 → 你 |
| 時機 | 你決定什麼時候問 | 對方有事才通知 |
| 比喻 | 你打電話去銀行查餘額 | 銀行簡訊通知你有入帳 |
| n8n 節點 | HTTP Request | Webhook Trigger |

### Webhook 的實際運作流程

```
Step 1：n8n 產生 Webhook 網址：https://your-n8n.com/webhook/new-deal
Step 2：你把這個網址貼到 CRM 設定裡
Step 3：某天業務建立新商機 → CRM 自動 POST 資料到你的 n8n
Step 4：n8n 收到資料，自動執行後續流程
```

### 範例中的 Respond to Webhook

當 Webhook Trigger 收到請求，Format Deal Record 整理完資料後，`Respond to Webhook` 節點把結果回傳給呼叫方。設定 `allIncomingItems` 代表直接回傳整個上游 JSON。

### 動手試試

1. 啟動 Workflow（Active = On）
2. 複製 Webhook URL
3. 用瀏覽器、curl 或 Postman POST 到這個 URL
4. 看 n8n 是否自動執行

---

# 第三部分：流程控制與資料轉換（L05 — L06）

---

## L05 — IF 與 Switch

**檔案：** `L05_if_switch_routing.json`

### 條件判斷 — 讓資料走不同的路

```
Fake Sales (3 筆)
    ├→ IF — 金額 ≥ 100 萬？
    │     ├→ true:  需主管審核
    │     └→ false: 業務自行報價
    │
    └→ Switch — 依階段路由
          ├→ 提案中 → 安排客戶拜訪
          ├→ 報價中 → 準備報價單
          └→ 成交   → 啟動交付流程
```

### 學習目標

1. **IF 節點**：二選一（true / false）
2. **Switch 節點**：多選一（多條規則）
3. 理解「分支」的概念

### IF vs Switch

| | IF | Switch |
|---|---|---|
| 分支數 | 2（true / false） | 多條（自訂規則） |
| 適用場景 | 單一條件判斷 | 多個分類值 |
| 比喻 | 紅綠燈 | 多線道匝道 |

### 業務場景

- **IF**：金額 ≥ 100 萬的商機需要主管審核，否則業務可以自行報價
- **Switch**：不同階段（提案中 / 報價中 / 成交）走不同的後續動作

### pinData（3 筆測試資料）

| 客戶 | 金額 | 階段 | IF 路徑 | Switch 路徑 |
|------|------|------|---------|------------|
| 台積電 | $1,500,000 | 提案中 | 需主管審核 | 安排客戶拜訪 |
| 悠遊卡公司 | $180,000 | 成交 | 業務自行報價 | 啟動交付流程 |
| 巨大機械 | $1,400,000 | 報價中 | 需主管審核 | 準備報價單 |

> **注意：** 本範例使用 `n8n-nodes-fake-sales` 社群節點。需先在 n8n 安裝此節點。

---

## L06 — 資料轉換

**檔案：** `L06_data_transform.json`

### Set（加欄位）→ Code Python（彙總）

```
Fake Sales (5 筆) → Set — 計算加權與佣金 → Code (Python) — 彙總報表
     5 筆              5 筆                    1 筆
```

### 學習目標

1. **Set 節點**：用 Expression 新增計算欄位（不寫程式）
2. **Code 節點**：用 Python 做複雜彙總（要寫程式）
3. 觀察 output 數量變化：5 → 5 → 1

### 概念解說：JSON 的深度應用

Set 節點的 Expression 對 JSON 做欄位級運算：

```
加權金額 = amount × probability%
{{ Math.round($json.amount * ($json.probability / 100)) }}

佣金 = 加權金額 × 5%
{{ Math.round($json.amount * ($json.probability / 100) * 0.05) }}
```

每筆資料都會新增 `weightedAmount` 和 `commission` 兩個欄位。

### Code (Python) 節點重點語法

```python
# 取得所有輸入資料
items = _input.all()

# 取值
for i in items:
    rep = i.json['salesRep']
    amount = i.json['amount']

# 回傳格式（一定是 list of dict）
return [{'json': {
    'totalDeals': len(items),
    'totalAmount': total_amount,
    'report': report_text
}}]
```

Code 節點把 5 筆逐筆資料彙總成 1 筆報表 —— 這就是「多進一出」的處理模式。

### 輸出的報表範例

```
== Pipeline 報表 ==
商機：5 筆
總額：$5,300,000
加權：$2,382,000
佣金：$119,100
-- 業務 --
林志明：3 筆
陳建宏：1 筆
張家豪：1 筆
-- 明細 --
鴻海精密工業  $640,000  [提案中]
國泰世華銀行  $980,000  [報價中]
...
```

---

# 第四部分：認證與整合（L07 — L08）

---

## L07 — 認證與 Credential

**檔案：** `L07_credential_and_auth.json`

### 用 OpenWeatherMap API 實作「API Key 認證」

```
Manual Trigger → Edit Fields — 設定 API Key
                    ├→ GET — 即時天氣（正確 Key）
                    ├→ GET — httpbin 回音（看 Header）
                    └→ GET — 故意填錯 Key（看 401）
```

### 學習目標

1. 為什麼 API 需要認證（對比 L03 免認證）
2. API Key 放在哪裡（Query Param vs Header）
3. 填錯 Key 會怎樣（401 Unauthorized）
4. 為什麼正式環境要用 n8n Credential

### 概念解說：認證、憑證、Token — 你憑什麼進來？

```
你去銀行辦事，櫃台第一句話是什麼？
「請出示您的身分證。」

API 也一樣。你的 n8n 要去查天氣、去 CRM 查商機，
這些系統都會問：「你是誰？你有權限嗎？」

如果你沒有通過認證，API 會回你 401 Unauthorized。
```

#### 三個名詞搞清楚

| 名詞 | 比喻 | 說明 |
|------|------|------|
| **認證（Authentication）** | 證明你是本人的「過程」 | 出示身分證、輸入密碼 |
| **憑證（Credential）** | 你用來證明身分的「東西」 | 身分證、護照、門禁卡 |
| **Token** | 一種「通行證」型的憑證 | 像臨時訪客證，有效期限內可以自由進出 |

#### Token 是什麼？

> Token 就是「系統發給你的臨時通行證」，有了它你就不用每次都輸入帳號密碼。

```
沒有 Token：
  玩雲霄飛車 → 排隊、身分驗證、買票
  玩摩天輪 → 排隊、身分驗證、買票
  → 超級麻煩

有 Token（手環）：
  玩雲霄飛車 → 刷手環
  玩摩天輪 → 刷手環
  → 刷一下就好

但手環有規則：
  - 有效期限（明天就不能用）
  - 有權限範圍（普通手環不能玩 VIP 設施）
  - 可以被作廢（違規可停用）
```

#### 三種認證方式比較

| | API Key | Bearer Token | OAuth 2.0 |
|---|---|---|---|
| 比喻 | 大樓門禁密碼 | 飯店房卡 | 請秘書幫你辦事 |
| 安全性 | 低 | 中 | 高 |
| 設定難度 | 最簡單 | 簡單 | 較複雜 |
| 會過期嗎 | 通常不會 | 會 | 會（自動 Refresh） |
| 常見服務 | OpenAI、小型 API | GitHub、自訂 API | Google、Slack、Notion |

### 範例中的三條路徑

#### 路徑 1：正確 Key → 成功取得天氣

```
GET https://api.openweathermap.org/data/2.5/weather
  ?q=Taipei
  &appid=你的Key        ← API Key 放在 Query Param
  &units=metric
  &lang=zh_tw

回傳：
  main.temp = 28.5（溫度）
  weather[0].description = "多雲"
```

#### 路徑 2：httpbin 回音 → 看 Header 裡的 Token

```
GET https://httpbin.org/get
Headers:
  Authorization: Bearer 你的Key
  X-Custom-Source: n8n-workshop-L07

→ 看 Output 的 headers 欄位
→ 確認 Bearer Token 的樣子
```

#### 路徑 3：故意填錯 Key → 體驗 401 錯誤

```
GET https://api.openweathermap.org/data/2.5/weather
  ?appid=故意填錯的Key

回傳：401 Unauthorized
→ 伺服器說「不認識你」
→ 這就是為什麼需要認證
```

注意 `continueOnFail = true` 讓 401 不會中斷整個 Workflow。

### 概念解說：n8n Credential — 把鑰匙存好

> n8n Credential 就是「幫你保管所有鑰匙的鑰匙包」，設定一次，所有 workflow 都能用。

**為什麼不要把 Token 直接寫在節點裡？**

| | 直接寫在節點 | 用 Credential |
|---|---|---|
| 匯出 workflow | Token 跟著匯出（外洩！） | Token 不會帶出 |
| 分享給同事 | Token 外洩 | 安全，對方自己設定 |
| Token 要換 | 每個節點都要改 | 改一個地方就好 |

> **本範例為了教學把 Key 寫在 Edit Fields。正式環境一定要用 Credential！**

### 事前準備（3 分鐘）

1. 到 https://openweathermap.org/ 免費註冊
2. 登入 → My API Keys → 複製 Key
3. 貼到 Edit Fields 的 `owmApiKey` 欄位
4. 新註冊的 Key 約需等 10 分鐘才生效

---

## L08 — 整合節點 Fan-out

**檔案：** `L08_integrations_fanout.json`

### 一筆成交，同時通知三個服務

```
Manual Trigger → Edit Fields — 成交資料
                    ├→ Slack — 通知業務群組        （專用節點）
                    ├→ HTTP POST — 模擬更新 CRM     （萬用 HTTP）
                    └→ HTTP POST — 模擬寄 Email     （萬用 HTTP）
```

### 學習目標

1. **Fan-out 模式**：一進多出（同一筆資料送到多個地方）
2. **專用節點** vs **萬用 HTTP Request** 的差異
3. 理解 Credential 在專用節點的角色

### 專用節點 vs 萬用 HTTP Request

| | 專用節點（Slack） | 萬用 HTTP Request |
|---|---|---|
| 設定方式 | 選 Credential → 選頻道 → 打訊息 | 自己填 URL → 自己組 Body → 自己看 API 文件 |
| 優點 | 簡單、有下拉選單、錯誤訊息友善 | 什麼 API 都能打、不需等官方支援 |
| 缺點 | 需要先設定 OAuth | 要看 API 文件、自己處理認證 |
| 適用場景 | n8n 有提供專用節點的服務 | 找不到專用節點的服務、自建 API |

> n8n 有 **400+** 專用節點。找不到的時候，用 HTTP Request 搞定。

### 實際執行結果

- **Slack 節點**：沒設定 Credential 會報錯 —— 這是正常的，提醒你需要先設定
- **兩個 HTTP POST**：可以直接跑，看 httpbin 的回音確認資料有送出

### 常見服務的 Credential 設定

| 服務 | 認證類型 | 難度 |
|------|---------|------|
| OpenAI | API Key | 簡單 |
| Slack | OAuth 2.0 | 中等 |
| Google Sheets | OAuth 2.0 | 中等 |
| Notion | Integration Token | 簡單 |
| LINE Bot | Channel Access Token | 簡單 |

---

# 第五部分：資料格式與來源（L09）

---

## L09 — 資料格式實戰

**檔案：** `L09_data_formats_rss_html.json`

### 用台灣真實網站比較 RSS vs JSON vs HTML

```
Manual Trigger
    ├→ GET — 科技新報 RSS      （結構化：XML）
    ├→ GET — 台幣匯率 JSON      （結構化：JSON）
    └→ GET — iThome 首頁 HTML   （非結構化：HTML）
```

### 學習目標

1. 三種格式的差異（結構化 vs 非結構化）
2. n8n 怎麼處理不同格式
3. 為什麼 JSON 最好用、HTML 最難處理

### 概念解說：四種結構化格式

#### JSON — 現代 API 的標準語言

```json
{
  "USDTWD": {
    "Exrate": 32.485,
    "UTC": "2026-03-25"
  }
}
```

- 最主流，幾乎所有現代 API 都用
- 可以巢狀（物件裡面放物件）
- 人類可讀、檔案小
- n8n 原生支援，不需要額外轉換

#### CSV — 最老派但最萬用的表格

```csv
id,salesRep,customer,amount,stage
1,林志明,鴻海精密工業,640000,提案中
3,陳建宏,國泰世華銀行,980000,報價中
```

- 超級簡單，就是逗號分隔
- 不能巢狀、沒有資料型別（全部都是文字）
- Excel、Google Sheets 都能開
- n8n 用 **Read Binary File** + **Spreadsheet File** 或 **Convert to File** 處理

#### XML — 比 JSON 更囉嗦的老前輩

```xml
<deal>
  <salesRep>林志明</salesRep>
  <customer>台積電</customer>
  <amount>1500000</amount>
</deal>
```

- 同樣資料比 JSON 大 30~50%（每個欄位要寫兩次標籤）
- 政府、銀行、SOAP API 還在用
- n8n 的 HTTP Request 會自動把 XML 轉成 JSON

#### RSS — 網站的「最新消息自動推播」

> RSS 是一種用 XML 格式寫的「最新文章清單」。

```xml
<rss version="2.0">
  <channel>
    <title>科技新報</title>
    <item>
      <title>台積電宣布新廠計畫</title>
      <link>https://...</link>
      <pubDate>Mon, 24 Mar 2026 08:00:00 +0800</pubDate>
    </item>
  </channel>
</rss>
```

- 結構固定：channel → item（每篇文章）
- n8n 用 **RSS Feed Trigger**（自動偵測新文章）或 **RSS Read**

### 四種格式一張表

| | JSON | CSV | XML | RSS |
|---|---|---|---|---|
| 長相 | `{ "key": "value" }` | `a,b,c` | `<tag>value</tag>` | XML 的子集 |
| 檔案大小 | 小 | 最小 | 大 | 中等 |
| 能巢狀嗎 | 可以 | 不行 | 可以 | 固定結構 |
| 主要用途 | API、設定檔 | 報表匯出 | 舊系統、政府 | 新聞更新 |
| n8n 支援 | 原生 | Convert to File | XML 節點 | RSS Trigger |

### 概念解說：HTML — 不是給程式讀的，是給人看的

同樣是「台積電的商機資料」：

**JSON（結構化）— 程式直接讀：**
```json
{ "customer": "台積電", "amount": 1500000 }
```

**HTML（非結構化）— 資料藏在排版裡：**
```html
<div class="deal-card">
  <h2 class="customer-name">台積電</h2>
  <span class="deal-amount">NT$ 1,500,000</span>
  <button onclick="viewDetail()">查看詳情</button>
</div>
```

HTML 的問題：
1. 資料和排版混在一起（「NT$ 1,500,000」是文字不是數字）
2. 沒有固定格式（每個網站的 class 名稱不同）
3. 有很多「不是資料」的東西（img、button、CSS）

要從 HTML 挖資料 = **爬蟲**：
```
HTTP Request（GET 網頁）→ HTML Extract（CSS Selector）→ Set（清理格式）→ 乾淨 JSON
```

### 概念解說：JavaScript 渲染 — 你看到的不等於原始碼裡有的

```
傳統網頁 = 你訂了一個便當，打開就能吃
  → 資料已經在 HTML 裡面了

現代網頁 = 你訂了一個料理包 + 食譜（JavaScript）
  → 你要自己按照食譜（執行 JS）才能煮出便當
  → 如果你不煮（不執行 JS），打開只有生食材
```

**怎麼判斷？** 在瀏覽器按右鍵 →「檢視原始碼」：
- 看得到你要的資料 → 傳統網頁 → HTTP Request 就能抓
- 只看到 `<div id="app"></div>` → JS 渲染 → 要用其他方法

**遇到 JS 渲染怎麼辦？**

最推薦：用瀏覽器 F12 → Network → XHR，找到 JavaScript 背後呼叫的 API，直接用 HTTP Request 打那個 API → 拿到乾淨的 JSON。

### 範例中的三條路徑觀察

| 路徑 | 來源 | 格式 | 執行後看到什麼 |
|------|------|------|--------------|
| 上 | technews.tw/feed/ | RSS (XML) | 巢狀結構，找 channel.item 陣列 |
| 中 | tw.rter.info/capi.php | JSON | 乾淨 key-value，直接 `$json.USDTWD.Exrate` |
| 下 | www.ithome.com.tw | HTML | 一大坨文字，資料藏在標籤裡 |

### 優先順序

```
能用 JSON API 就用 JSON（最優先）
有 RSS 也不錯（n8n 自動轉 JSON）
HTML 是最後手段（要自己挖，網頁改版就壞）
```

### 怎麼找 RSS

- 網址後面試加 `/feed`、`/rss`、`/atom.xml`
- 或在原始碼裡搜尋 `application/rss+xml`

### 決策流程圖：我該用什麼方式拿資料？

```
我要的資料在哪裡？
│
├── 對方有 API 文件嗎？
│   ├── 有 → 回傳 JSON → ✅ HTTP Request（最簡單）
│   └── 回傳 XML → HTTP Request + XML 節點
│
├── 是 RSS Feed 嗎？ → ✅ RSS Feed Trigger
│
├── 是 CSV / Excel 檔案嗎？ → ✅ Read File + Spreadsheet File
│
└── 只有網頁
    ├── 原始碼有資料 → ✅ HTTP Request + HTML Extract
    └── JavaScript 渲染
        ├── 找到背後 API → ✅ 直接打 API（最推薦）
        └── 找不到 → 第三方爬蟲服務
```

---

# 第六部分：AI 與進階應用（L10 — L11）

---

## L10 — AI Agent

**檔案：** `L10_ai_sales_advisor.json`

### AI 銷售顧問 — 用 LLM 處理自然語言

```
Chat Trigger（使用者輸入）
    ↓
AI Agent（推理引擎）
    ↑         ↑
  OpenAI    Memory
 （大腦）  （記憶）
```

### 學習目標

1. Chat Trigger → AI Agent → LLM 的架構
2. System Prompt 的設計方式
3. Sub-node 概念（LLM + Memory 掛在 Agent 下方）
4. 對話記憶（Memory）讓 AI 記住上下文

### 架構解說

| 節點 | 角色 | 說明 |
|------|------|------|
| Chat Trigger | 入口 | n8n 內建聊天介面，按「Chat」按鈕開啟 |
| AI Agent | 推理引擎 | 負責「思考」，內含 System Prompt 定義產品線和規則 |
| OpenAI Chat Model | 大腦 | 實際的語言模型（gpt-4o-mini），需要 OpenAI Credential |
| Simple Memory | 記憶 | 記住對話上下文，讓 AI 知道「剛才聊了什麼」 |

### System Prompt 設計重點

範例中的 System Prompt 包含：
- **產品線與報價**：完整的價目表（雲端、AI、IoT、資安）
- **回答規則**：推薦 1-3 項、附報價和導入時間、主動詢問預算
- **語言偏好**：用客戶使用的語言回覆

> System Prompt 就是給 AI 的「角色設定書」—— 它決定了 AI 的行為模式。

### 測試問法

- 「客戶是金融業，預算 100 萬以內」
- 「製造業想做工廠數位轉型」
- 「剛才推薦的方案可以再便宜嗎？」（測記憶）

### 需要

- OpenAI API Key（在 Credential 設定）
- 這就是 L07 學到的認證概念的實際應用

---

## L11 — Error Handling 與監控

**檔案：** `L11_error_and_monitoring.json`

### Workflow 出錯怎麼辦？商機逾期怎麼追？

```
上方：Error Monitor
  Error Trigger → Code — 萃取錯誤 → Set — 格式化異常

下方：Deal SLA Monitor
  Fake Sales → Code — 到期天數 → IF — 需要警報？
                                     ├→ 發送警報
                                     └→ 正常記錄
```

### 學習目標

1. **Error Trigger**：自動攔截其他 Workflow 的錯誤
2. 用 Code 節點做 **SLA 監控**（到期天數計算）
3. IF 節點做**警報分流**

### Error Monitor 路徑

Error Trigger 是特殊的 Trigger —— 當你指定的其他 Workflow 發生錯誤時，它會自動啟動。Code 節點萃取錯誤的 workflow name、error message、execution ID，格式化成標準的異常通知。

### Deal SLA Monitor 路徑

Code 節點計算每筆商機的到期天數，並根據結果標記狀態：

| 狀態 | 條件 | 顏色 |
|------|------|------|
| **OVERDUE** | 已逾期（天數 < 0） | 紅 |
| **URGENT** | 14 天內到期 | 黃 |
| **ON_TRACK** | 14 天以上 | 綠 |

IF 節點根據 `alertNeeded`（OVERDUE 或 URGENT）分流到「發送警報」或「正常記錄」。

### 動手試試

改 pinData 的 `expectedCloseDate`：
- 過去日期 → OVERDUE
- 14 天內 → URGENT
- 14 天以上 → ON_TRACK

---

# 第七部分：綜合演練（L12 — L13）

---

## L12 — 主管戰情室

**檔案：** `L12_full_pipeline_dashboard.json`

### 完整 Pipeline Dashboard

```
Manual Trigger → Fake Sales (50 筆) → Enrich — 加權+風險
                                         ├→ A — 風險偵測 (Python)
                                         ├→ B — 業務 KPI (Python)
                                         └→ C — 區域產品 (Python)
                                              ↓
                                         Merge 1 → Merge 2
                                              ↓
                                         Executive Summary (Python)
```

### 學習目標

1. **Fan-out → Merge**：平行計算再合併
2. **多維度報表**：風險、KPI、區域三個維度
3. 所有前面學到的概念綜合運用

### 架構解析

這是本課程最複雜的 Workflow，整合了前面所有概念：

| 階段 | 使用的概念 | 對應前置課程 |
|------|-----------|------------|
| Fake Sales → Enrich | Expression 計算、JSON 加欄位 | L02、L06 |
| Fan-out 三路 | 分支（一進多出） | L08 |
| A/B/C Code 節點 | Python 彙總、分組統計 | L06 |
| Merge 節點 | 多路合併 | 新概念 |
| Executive Summary | 最終報表整合 | L06 |

### Enrich 節點的計算

```javascript
// 加權金額
{{ Math.round($json.amount * $json.probability / 100) }}

// 到期天數
{{ Math.ceil((new Date($json.expectedCloseDate) - new Date()) / (1000*60*60*24)) }}

// 是否逾期
{{ new Date($json.expectedCloseDate) < new Date() && $json.stage !== '成交' }}

// 風險等級
{{ 逾期 ? '高' : (金額>100萬 且 機率<40%) ? '高' : (金額>50萬 且 機率<55%) ? '中' : '低' }}
```

### 三條分析路徑

| 路徑 | Python Code 做什麼 | 輸出 |
|------|-------------------|------|
| A — 風險偵測 | 篩選高風險 + 逾期，取 Top 10 | 風險商機列表 |
| B — 業務 KPI | 依業務分組，統計筆數/金額/加權 | 業務排行榜 |
| C — 區域產品 | 依區域和產品類別分組統計 | 市場分布 |

### Merge 節點

三路結果透過兩次 Merge（combineAll）合併成一筆資料，包含所有維度的報表。

### Executive Summary 輸出

```
== 主管 Pipeline 戰情報告 ==
報告時間：2026-03-27 14:30

高風險：8 筆
已逾期：3 筆

-- 業務排行 --
1. 林志明 — 15筆 加權$3,200,000
2. 黃淑芬 — 10筆 加權$2,800,000
...

-- 區域 --
北區：25筆 $12,000,000
南區：15筆 $8,500,000
...

-- 建議 --
高風險超過5筆，建議召開 deal review
MVP：林志明
```

---

## L13 — No-Code 報表

**檔案：** `L13_nocode_google_sheets.json`

### 不寫 JS，用 Summarize 做樞紐分析

```
Manual Trigger → Fake Sales (50 筆) → Edit Fields — 加權+風險
                                         ├→ Summarize — 業務績效 → Sheets — Rep
                                         ├→ Summarize — 區域     → Sheets — Region
                                         └→ Summarize — 漏斗     → Sheets — Stage
```

### 學習目標

1. **Summarize 節點** = Excel 樞紐分析（完全不寫程式）
2. 直接輸出到 **Google Sheets**
3. 對比 L12：同樣的結果，不同的方法

### L12 vs L13 對比

| | L12（Code 版） | L13（No-Code 版） |
|---|---|---|
| 彙總方式 | Python Code 節點 | Summarize 節點 |
| 靈活度 | 高（任意邏輯） | 中（預設聚合函數） |
| 門檻 | 需要會 Python | 零程式碼 |
| 輸出 | 報表文字 | Google Sheets |
| 適合 | 複雜自訂報表 | 標準統計報表 |

### Summarize 節點設定

以「業務績效」為例：

| 設定項 | 值 | 說明 |
|--------|-----|------|
| Group By | salesRep, department | 依業務和部門分組 |
| Count | id → dealCount | 計算筆數 |
| Sum | amount → totalAmount | 加總金額 |
| Sum | weightedAmount → totalWeightedAmount | 加總加權金額 |
| Average | amount → avgDealSize | 平均金額 |

> Summarize 節點就是把 Excel 的「資料透視表」搬到 n8n 裡 —— 選分組欄位、選聚合函數，就搞定。

### 使用前準備

1. 建立 Google Sheets OAuth Credential（見 L07 認證概念）
2. 替換節點中的 `YOUR_GOOGLE_SHEET_ID`
3. 在 Google Sheets 內建好三個工作表：`Rep_Summary`、`Region_Summary`、`Stage_Funnel`

---

# 附錄

---

## 附錄 A：所有概念的關係圖

```
┌────────────────────────────────────────────────────────────┐
│                     n8n（膠水層）                            │
│          接收 → 處理 → 輸出，幫你黏所有系統                   │
│                                                            │
│  JSON ← 資料格式（大家都用這個格式溝通）                      │
│   ↑                                                        │
│  HTTP 請求 ← 溝通方式（GET / POST / PUT / DELETE）           │
│   ↑                                                        │
│  認證 / Token ← 身分驗證（不然 API 不理你）                   │
│   ↑                                                        │
│  RESTful ← 設計規範（URL 怎麼取、Method 怎麼配）             │
│   ↑                                                        │
│  ┌───────────┬──────────────┐                              │
│  │           │              │                              │
│  API         Webhook        爬蟲                            │
│  (你去問)    (他來通知)      (自己去看)                       │
│                                                            │
│  HTTP Req    Webhook        HTTP Req                       │
│  + 專用節點   Trigger        + HTML Extract                 │
│                                                            │
│  n8n Credential：統一管理所有 Token / API Key / OAuth        │
│  → 設定一次，所有 workflow 共用                               │
│  → 加密儲存，匯出不外洩                                      │
└────────────────────────────────────────────────────────────┘
```

用一句話串起來：

> **n8n** 是膠水層，用 **JSON** 格式，透過 **HTTP 請求** 傳送，
> 遵循 **RESTful** 規範的介面叫做 **API**，
> 用 **Token** 通過 **認證** 才能使用，
> 所有 Token 存在 **Credential** 裡統一管理，
> **Webhook** 是反向的 API（對方主動通知你），
> **爬蟲** 是在沒有 API 時的替代方案。

---

## 附錄 B：概念 → n8n 節點 → 課程對照表

| 概念 | n8n 節點 / 功能 | 什麼時候用 | 對應課程 |
|------|----------------|-----------|---------|
| 膠水層 | n8n 本身 | 串接任何系統 | 全部 |
| JSON | 所有節點 | 每個節點都在傳 JSON | L01、L02 |
| API（呼叫別人） | HTTP Request / 專用節點 | 主動去拿或送資料 | L03、L08 |
| API（被呼叫） | Webhook Trigger | 別人要通知你 | L04 |
| 認證 / Token | Credential 設定 | 串接需要登入的服務 | L07 |
| HTTP GET | HTTP Request (GET) | 查詢、讀取 | L03、L09 |
| HTTP POST | HTTP Request (POST) | 新增、送出 | L03、L08 |
| RESTful | HTTP Request | 打第三方 SaaS API | L03 |
| Webhook | Webhook Trigger | 等待外部事件觸發 | L04 |
| 爬蟲 | HTTP Request + Extract | 對方沒有 API | L09 |
| Credential | Settings → Credentials | 統一管理認證資訊 | L07、L08 |
| 條件判斷 | IF / Switch | 資料分流 | L02、L05、L11 |
| 資料轉換 | Set / Code | 加欄位、彙總 | L06、L12 |
| 樞紐分析 | Summarize | 分組統計 | L13 |
| AI Agent | Agent + LLM + Memory | 自然語言處理 | L10 |
| 錯誤處理 | Error Trigger | 攔截 Workflow 錯誤 | L11 |

---

## 附錄 C：不同資料來源的接法

| 資料來源 | 格式 | n8n 怎麼接 | 難度 |
|---------|------|-----------|------|
| 現代 API（Slack、Notion） | JSON | 專用節點 / HTTP Request | 簡單 |
| 自訂 API | JSON | HTTP Request | 簡單 |
| Google Sheets | CSV | Google Sheets 節點 | 簡單 |
| 檔案上傳 | CSV / Excel | Read File + Spreadsheet File | 中等 |
| 政府開放資料 | CSV / JSON | HTTP Request | 簡單 |
| 銀行 SOAP API | XML | HTTP Request + XML 節點 | 中等 |
| 新聞 / 部落格 | RSS (XML) | RSS Feed Trigger | 簡單 |
| 傳統網頁 | HTML | HTTP Request + HTML Extract | 中等 |
| JavaScript 渲染網頁 | HTML + JS | 找背後 API / 第三方服務 | 困難 |

---

## 附錄 D：常見問題 FAQ

**Q：我不會寫程式，能用 API 嗎？**
A：可以。n8n 的 HTTP Request 節點就是讓你「不寫程式也能打 API」。你只需要填 URL、選 Method、設定 Credential。

**Q：Token 和 API Key 有什麼差別？**
A：API Key 通常固定不變（像大樓密碼）。Token 通常會過期、可被撤銷、有特定權限範圍（像臨時訪客證）。實務上很多人混用，不用太糾結。

**Q：OAuth 好複雜，一定要用嗎？**
A：如果串接的服務要求 OAuth（Google、Slack），就得用。好消息是 n8n 專用節點已經幫你處理了大部分 OAuth 流程。

**Q：遇到 401 錯誤怎麼辦？**
A：九成是認證問題。按順序檢查：
1. Token / API Key 有沒有貼對？（多餘的空白、換行）
2. Token 有沒有過期？
3. Credential 有沒有選對？
4. Token 的權限夠不夠？

**Q：n8n 收到 XML 要怎麼變 JSON？**
A：HTTP Request 節點通常會自動轉。如果沒有，用 **XML** 節點手動轉換。

**Q：CSV 有中文亂碼怎麼辦？**
A：確認檔案編碼是 UTF-8。如果從 Excel 匯出，選「CSV UTF-8」格式。

**Q：怎麼知道一個網站有沒有 RSS？**
A：網址後面試加 `/feed`、`/rss`、`/atom.xml`。或在原始碼搜尋 `application/rss+xml`。

**Q：JSON 一定要手寫嗎？**
A：在 n8n 裡幾乎不用。Set 節點和 Expression 會自動幫你組 JSON。只有用 Code 節點時才需要手寫。

**Q：找到背後 API 但需要登入怎麼辦？**
A：看 Network 裡的 Headers，通常有 `Authorization` 或 `Cookie`。把這些加到 n8n 的 HTTP Request Headers 裡。

**Q：爬蟲合法嗎？**
A：要看對方的使用條款。公開資料通常可以，但不要過度頻繁請求，也不要爬需要登入的私人資料。

**Q：Credential 存在哪裡？安全嗎？**
A：存在 n8n 的資料庫裡，加密儲存。匯出 workflow JSON 時不會包含 Credential 內容。但你的 n8n 伺服器本身要做好安全防護。

---

## 附錄 E：口訣記憶

```
n8n 是膠水，黏起所有系統
JSON 是語言，HTTP 是方法
REST 是規範，API 是窗口
Token 是通行證，Credential 是鑰匙包
Webhook 反著來，爬蟲自己找

JSON 最主流，API 都用它
CSV 老但穩，Excel 最愛它
XML 很囉嗦，政府還在用
RSS 訂新聞，有更新通知你

HTML 給人看，資料要自己挖
JS 渲染的網頁，先找背後 API
找不到再爬，爬之前問合法
```

---

## 附錄 F：學習路線建議

### 零基礎入門（Day 1）

```
L01 Hello n8n → L02 JSON 資料流
→ 搞懂 Workflow、節點、JSON、Expression
```

### 串接外部服務（Day 2）

```
L03 HTTP Request → L04 三種 Trigger → L05 IF/Switch
→ 搞懂 API、HTTP、Webhook、條件判斷
```

### 資料處理與認證（Day 3）

```
L06 資料轉換 → L07 認證 → L08 整合節點
→ 搞懂 Code 節點、認證、Credential、Fan-out
```

### 進階應用（Day 4）

```
L09 資料格式 → L10 AI Agent → L11 Error Handling
→ 搞懂 RSS/HTML、AI 整合、錯誤處理
```

### 綜合演練（Day 5）

```
L12 主管戰情室 → L13 No-Code 報表
→ 把所有概念串在一起，完成完整的 Dashboard
```

---

*本教科書整合自 `06_補充_API與資料交換基礎概念.md` 和 `06b_補充_資料格式與網頁結構.md`，搭配 L01—L13 共 13 個可匯入的 Workflow JSON 範例。*
