# 補充教材：API 與資料交換基礎概念

> 這份文件用「點餐」和「業務銷售」的比喻，幫你搞懂 n8n 膠水層、API、認證與 Token、Webhook、HTTP、RESTful、JSON、網路爬蟲這些概念。
> 每個概念都會對應到 n8n 裡的實際操作。

---

## 目錄

1. [n8n 是什麼角色？— 膠水層](#1-n8n-是什麼角色--膠水層)
2. [JSON — 資料的共同語言](#2-json--資料的共同語言)
3. [API — 系統之間的服務窗口](#3-api--系統之間的服務窗口)
4. [認證、憑證、Token — 你憑什麼進來？](#4-認證憑證token--你憑什麼進來)
5. [n8n Credential — 把鑰匙存好，不用每次掏](#5-n8n-credential--把鑰匙存好不用每次掏)
6. [HTTP 請求 — 你怎麼跟窗口溝通](#6-http-請求--你怎麼跟窗口溝通)
7. [RESTful — 窗口的設計規範](#7-restful--窗口的設計規範)
8. [Webhook — 反過來，系統主動通知你](#8-webhook--反過來系統主動通知你)
9. [網路爬蟲 — 沒有窗口時，自己去看](#9-網路爬蟲--沒有窗口時自己去看)
10. [所有概念的關係圖](#10-所有概念的關係圖)
11. [n8n 實戰對照表](#11-n8n-實戰對照表)

---

## 1. n8n 是什麼角色？— 膠水層

### 一句話解釋

> n8n 不是 CRM，不是資料庫，不是聊天工具。n8n 是把這些東西「黏在一起」的膠水。

### 生活比喻

你公司裡有很多系統：

```
CRM（管客戶）   Google Sheets（管報表）   Slack（聊天通知）
LINE Bot（接客戶訊息）   Email（寄信）   資料庫（存資料）
```

這些系統各做各的，互相不認識。
要讓它們協作，你有兩個選擇：

```
選擇 A：每兩個系統之間寫一段程式串接
  → CRM ↔ Slack 要寫一段
  → CRM ↔ Google Sheets 要寫一段
  → LINE ↔ CRM 又要寫一段
  → 6 個系統 = 15 條連線，維護噩夢

選擇 B：所有系統都接到 n8n，由 n8n 負責轉接
  → CRM → n8n → Slack
  → LINE → n8n → CRM → n8n → Google Sheets
  → 6 個系統 = 6 條連線，集中管理
```

**n8n 就是選擇 B。它是中間的「膠水層」（Glue Layer）。**

### 膠水層的核心能力

```
                    ┌─── Slack
                    │
CRM ──→ n8n ──→ ───┼─── Google Sheets
                    │
LINE ──→ n8n ──→ ───┼─── Email
                    │
Webhook ──→ n8n ──→ ┴─── Database

n8n 做的三件事：
  1. 接收（從各個來源拿到資料）
  2. 處理（轉換、篩選、計算、判斷）
  3. 輸出（把結果送到各個目的地）
```

### 為什麼叫「膠水」？

```
膠水的特性：
  - 不是主角，但沒有它東西黏不起來
  - 什麼都能黏（不限品牌、不限系統）
  - 黏好之後，你不會再注意到它的存在

n8n 的特性：
  - 不存資料，但幫你搬資料
  - 什麼 API 都能接（400+ 專用節點 + 萬用 HTTP Request）
  - 設定好之後自動跑，你不用管它
```

### 這跟後面的概念有什麼關係？

```
要當好膠水，n8n 必須：
  ✅ 看懂各系統的資料 → 需要懂 JSON、CSV、XML（資料格式）
  ✅ 跟各系統溝通 → 需要懂 API、HTTP、RESTful（溝通方式）
  ✅ 證明自己有權限 → 需要懂認證、Token、Credential（身分驗證）
  ✅ 被動等通知 → 需要懂 Webhook（反向觸發）
  ✅ 對方沒開窗口 → 需要懂爬蟲（自己去拿）
```

**所以這份文件的每一個概念，都是 n8n 當膠水時需要的技能。**

---

## 2. JSON — 資料的共同語言

### 一句話解釋

> JSON 就是「系統之間溝通用的格式」，像是大家都看得懂的表格。

### 生活比喻

你去餐廳點餐，點餐單長這樣：

```
品項：拿鐵
數量：2
備註：少冰
```

如果全世界的餐廳都用同一種格式寫點餐單，廚師不管在哪間店都看得懂。
**JSON 就是這個「全世界都看得懂的點餐單格式」。**

### 實際長什麼樣

```json
{
  "customer": "統一企業",
  "product": "全通路行銷平台",
  "amount": 816000,
  "stage": "合約審核",
  "salesRep": "黃淑芬"
}
```

### 重點規則（只有四條）

| 規則 | 說明 | 範例 |
|------|------|------|
| 用大括號 `{}` 包起來 | 代表「一筆資料」 | `{ ... }` |
| 用 `"key": value` 表示 | 左邊是欄位名，右邊是值 | `"amount": 816000` |
| 文字要加引號 | 數字不用 | `"stage": "合約審核"` vs `"amount": 816000` |
| 用中括號 `[]` 表示多筆 | 代表「一組資料」 | `[{...}, {...}, {...}]` |

### 在 n8n 裡的對應

n8n 裡面每個節點傳遞的資料，**全部都是 JSON**。
你在節點輸出看到的那些欄位，就是 JSON 的 key-value。

```
每一筆資料 = 一個 { json: { ... } }
多筆資料 = [ { json: {...} }, { json: {...} } ]
```

---

## 3. API — 系統之間的服務窗口

### 一句話解釋

> API 就是「一個系統開給另一個系統用的服務窗口」。

### 生活比喻

想像你去銀行辦事：

```
你（客戶）  →  櫃台窗口（API）  →  銀行內部系統

你不需要知道銀行內部怎麼運作。
你只需要知道：
  - 哪個窗口辦什麼事（哪個 API 做什麼功能）
  - 要帶什麼資料（API 需要什麼參數）
  - 會拿到什麼回覆（API 回傳什麼結果）
```

### 業務銷售的例子

```
你的 n8n workflow
    ↓ 呼叫 CRM 的 API
CRM 系統（Salesforce / HubSpot）
    ↓ 回傳
「客戶：台積電，金額：150萬，階段：提案中」
```

你不需要登入 CRM 網站，不需要手動查資料。
**透過 API，程式幫你自動去問，自動拿到結果。**

### API 不是什麼

| 常見誤解 | 正確理解 |
|---------|---------|
| API 是一種程式語言 | API 是一個「介面」，不是語言 |
| API 只有工程師才能用 | n8n 的 HTTP Request 節點讓你不寫程式也能用 API |
| 每個 API 都一樣 | 每個系統的 API 都有自己的「規格書」（API 文件） |

### 在 n8n 裡的對應

- **專用節點**（Slack、Google Sheets、Notion）= 已經幫你包好的 API 窗口
- **HTTP Request 節點** = 萬用窗口，什麼 API 都能打

**但不管用哪種窗口，你都需要先「證明你是誰」。這就是下一節要講的。**

---

## 4. 認證、憑證、Token — 你憑什麼進來？

### 為什麼需要認證？

```
你去銀行辦事，櫃台第一句話是什麼？

「請出示您的身分證。」

API 也一樣。
你的 n8n 要去 Slack 發訊息、去 Google Sheets 寫資料、去 CRM 查商機，
這些系統都會問同一個問題：

「你是誰？你有權限嗎？」
```

**如果你沒有通過認證，API 會回你 `401 Unauthorized`（你是誰？不認識你。）**

### 三個名詞搞清楚

| 名詞 | 比喻 | 說明 |
|------|------|------|
| **認證（Authentication）** | 「證明你是本人」的過程 | 你出示身分證、輸入密碼、刷臉 |
| **憑證（Credential）** | 你用來「證明身分的東西」 | 身分證、護照、門禁卡、密碼 |
| **Token** | 一種「通行證」型的憑證 | 像是臨時訪客證，有效期限內可以自由進出 |

### 用銀行比喻串起來

```
場景：你要從 ATM 領錢

  1. 你插入金融卡 → 提供「憑證」
  2. 你輸入密碼 → 進行「認證」
  3. ATM 確認你是本人 → 認證通過
  4. ATM 讓你領錢 → 你有「權限」了

如果你的卡過期了、密碼錯了 → 認證失敗 → ATM 拒絕你
```

### Token 是什麼？— 重點中的重點

#### 一句話解釋

> Token 就是「系統發給你的臨時通行證」，有了它你就不用每次都輸入帳號密碼。

#### 用遊樂園比喻

```
沒有 Token 的世界：
  你每玩一個設施，都要重新排隊買票、出示身分證。
  玩雲霄飛車 → 排隊、身分驗證、買票
  玩摩天輪 → 排隊、身分驗證、買票
  玩碰碰車 → 排隊、身分驗證、買票
  → 超級麻煩

有 Token 的世界：
  你在入口買了一張「手環」（Token）。
  玩雲霄飛車 → 刷手環
  玩摩天輪 → 刷手環
  玩碰碰車 → 刷手環
  → 不用每次驗證，刷一下就好

但手環有規則：
  - 有效期限（今天有效，明天就不能用）
  - 有權限範圍（普通手環不能玩 VIP 設施）
  - 可以被作廢（如果你違規，工作人員可以停用你的手環）
```

**Token 就是這個手環。**

#### Token 的實際樣子

```
一個 Token 通常長這樣（一串看不懂的文字）：

  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkw...

或是比較短的：

  xoxb-your-slack-bot-token-here（Slack Bot Token）
  sk-abcdefghijklmnop1234567890（OpenAI API Key）
  ghp_abcdefghijklmnop1234567890（GitHub Personal Access Token）
```

你不需要知道它怎麼產生的，你只需要知道：**把它放到對的地方，API 就認得你。**

### 常見的認證方式（由簡單到複雜）

#### 方式 1：API Key

```
最簡單的方式。對方給你一組金鑰，你每次請求都帶上。

比喻：大樓的門禁密碼
  → 知道密碼就能進
  → 簡單，但不夠安全（密碼外洩就完了）

實際用法：
  Headers:
    X-API-Key: your-api-key-here

  或放在 URL：
    https://api.example.com/deals?api_key=your-api-key-here

常見場景：
  - OpenAI API（sk-...）
  - 很多小型 SaaS 服務
```

#### 方式 2：Bearer Token

```
對方給你一個 Token，放在 Headers 的 Authorization 欄位。

比喻：飯店的房卡
  → 櫃台（登入）給你房卡（Token）
  → 刷房卡就能進房間、用泳池、去健身房
  → 退房後房卡失效

實際用法：
  Headers:
    Authorization: Bearer eyJhbGciOiJIUzI1NiIs...

常見場景：
  - GitHub API（Personal Access Token）
  - 大部分 RESTful API
  - JWT（JSON Web Token）
```

#### 方式 3：OAuth 2.0

```
最安全但也最複雜。不是直接給密碼，而是「授權」對方存取你的資料。

比喻：你請秘書幫你去銀行辦事
  1. 你（用戶）跟銀行（Google）說：「我授權這位秘書（n8n）幫我辦事」
  2. 銀行跟秘書確認：「他真的授權你了？」
  3. 秘書回答：「是，這是授權書（Authorization Code）」
  4. 銀行發給秘書一張臨時工作證（Access Token）
  5. 秘書用工作證幫你辦事
  6. 工作證到期了 → 用 Refresh Token 換新的

你全程不需要把密碼給秘書。
秘書只拿到「有限權限的臨時通行證」。

常見場景：
  - Google（Gmail、Sheets、Drive）
  - Slack
  - Notion
  - 任何有「用 Google 登入」「用 Facebook 登入」的服務
```

### OAuth 2.0 的完整流程圖

```
你（使用者）         n8n（應用程式）        Google（服務提供者）
    │                    │                      │
    │  1. 「我要連 Google」│                      │
    │ ──────────────────→ │                      │
    │                    │  2. 跳轉到 Google 登入頁  │
    │                    │ ────────────────────→ │
    │  3. Google 問你：                           │
    │    「要允許 n8n 存取你的 Sheets 嗎？」        │
    │ ←──────────────────────────────────────── │
    │                                            │
    │  4. 你按「允許」                              │
    │ ────────────────────────────────────────→ │
    │                    │                      │
    │                    │  5. Google 給 n8n 一個  │
    │                    │     Authorization Code │
    │                    │ ←──────────────────── │
    │                    │                      │
    │                    │  6. n8n 用 Code 換      │
    │                    │     Access Token       │
    │                    │ ────────────────────→ │
    │                    │                      │
    │                    │  7. Google 發 Token     │
    │                    │ ←──────────────────── │
    │                    │                      │
    │                    │  8. n8n 用 Token        │
    │                    │     讀寫你的 Sheets     │
    │                    │ ────────────────────→ │
```

### 三種認證方式比較

| | API Key | Bearer Token | OAuth 2.0 |
|---|---|---|---|
| 比喻 | 大樓門禁密碼 | 飯店房卡 | 請秘書幫你辦事 |
| 安全性 | 低 | 中 | 高 |
| 設定難度 | 最簡單 | 簡單 | 較複雜（要跳轉授權） |
| 會過期嗎 | 通常不會 | 會（要 Refresh） | 會（自動 Refresh） |
| 常見服務 | OpenAI、小型 API | GitHub、自訂 API | Google、Slack、Notion |
| n8n 設定 | Header Authentication | Header Authentication | 專用節點的 OAuth 設定 |

### Token 的安全注意事項

```
⚠️ Token = 你的鑰匙。弄丟了別人就能進你家。

絕對不要做的事：
  ❌ 把 Token 貼在公開的 GitHub repo 裡
  ❌ 把 Token 用 LINE / Slack 傳給別人
  ❌ 把 Token 寫死在程式碼裡（用環境變數或 n8n Credential）
  ❌ 截圖時露出 Token

如果 Token 外洩了：
  1. 立刻去對方平台「撤銷」（Revoke）這個 Token
  2. 重新產生一個新的
  3. 更新 n8n 裡的 Credential
```

---

## 5. n8n Credential — 把鑰匙存好，不用每次掏

### 一句話解釋

> n8n Credential 就是「幫你保管所有鑰匙的鑰匙包」，設定一次，所有 workflow 都能用。

### 生活比喻

```
沒有 Credential 的做法：
  你每次出門都要記得帶：
    - 公司門禁卡
    - 停車場遙控器
    - 家裡鑰匙
    - 健身房會員卡
  每次要用，從口袋翻半天。
  換了一張新門禁卡，每個口袋都要更新。

有 Credential 的做法（n8n）：
  你把所有卡和鑰匙放進一個「鑰匙包」。
  每次出門帶這一包就好。
  換了新卡，只要更新鑰匙包裡那一張，所有場景自動生效。
```

### 在 n8n 裡怎麼運作

```
Step 1：建立 Credential（一次性設定）
  n8n 設定 → Credentials → 新增
  → 選類型（例如：Google Sheets OAuth2）
  → 填入 Token / API Key / 帳號密碼
  → 儲存

Step 2：在節點裡選擇 Credential
  Google Sheets 節點 → Credential 下拉選單
  → 選「My Google Account」
  → 完成！

Step 3：所有用到 Google Sheets 的節點，都選同一個 Credential
  → 未來換了 Token，只要在 Credential 裡更新一次
  → 所有 workflow 自動生效
```

### Credential 存了什麼？

| 認證方式 | Credential 裡存的東西 |
|---------|---------------------|
| API Key | API Key 字串 |
| Bearer Token | Token 字串 |
| OAuth 2.0 | Client ID、Client Secret、Access Token、Refresh Token |
| 帳號密碼 | Username、Password |
| SSH | Private Key |

### 為什麼不要把 Token 直接寫在節點裡？

```
錯誤做法（直接寫在 HTTP Request 節點）：
  Headers → Authorization: Bearer sk-abc123456789

  問題：
    ❌ 匯出 workflow JSON 時，Token 會跟著匯出
    ❌ 分享 workflow 給同事，Token 就外洩了
    ❌ Token 過期要換，每個節點都要改

正確做法（用 Credential）：
  HTTP Request 節點 → Authentication → 選 Credential

  好處：
    ✅ Token 加密儲存在 n8n 裡，匯出時不會帶出
    ✅ 分享 workflow 安全，對方需要自己設定 Credential
    ✅ Token 要換，改一個地方就好
```

### 實際操作：串接 Google Sheets 的完整流程

```
1. 去 Google Cloud Console 建立 OAuth 2.0 憑證
   → 拿到 Client ID 和 Client Secret

2. 在 n8n Credentials 頁面
   → 新增 → 選「Google Sheets OAuth2 API」
   → 貼上 Client ID 和 Client Secret
   → 按「Connect」→ 跳轉到 Google 登入頁
   → 登入你的 Google 帳號 → 按「允許」
   → n8n 自動拿到 Access Token + Refresh Token
   → 儲存

3. 在 Google Sheets 節點裡
   → Credential 選「剛才建立的那個」
   → 選你要操作的 Sheet
   → 完成！

以後 Token 過期了，n8n 會自動用 Refresh Token 去換新的。
你什麼都不用做。
```

### 常見服務的 Credential 設定方式

| 服務 | 認證類型 | 你需要準備什麼 | 難度 |
|------|---------|--------------|------|
| OpenAI | API Key | 從 OpenAI 後台複製 API Key | 簡單 |
| Slack | OAuth 2.0 | 建立 Slack App，設定 OAuth | 中等 |
| Google Sheets | OAuth 2.0 | Google Cloud Console 建立憑證 | 中等 |
| Notion | API Key (Integration Token) | 建立 Notion Integration | 簡單 |
| LINE Bot | Channel Access Token | 從 LINE Developers 複製 | 簡單 |
| GitHub | Personal Access Token | 從 GitHub Settings 產生 | 簡單 |
| 自訂 API | 看對方要求 | Header / Query / Basic Auth | 看情況 |

---

## 6. HTTP 請求 — 你怎麼跟窗口溝通

### 一句話解釋

> HTTP 請求就是「你走到窗口，跟它說你要做什麼事」的那個動作。

### 生活比喻

你走到餐廳櫃台（API），你可以：

| 你的動作 | HTTP 方法 | 意思 |
|---------|----------|------|
| 「我要看菜單」 | **GET** | 拿資料（只看，不改） |
| 「我要點一份拿鐵」 | **POST** | 新增資料（建立新東西） |
| 「我要改成去冰」 | **PUT / PATCH** | 修改資料 |
| 「我要取消訂單」 | **DELETE** | 刪除資料 |

### 一個完整的 HTTP 請求長什麼樣

```
1. 方法（Method）：POST
2. 網址（URL）：https://crm.example.com/api/deals
3. 標頭（Headers）：告訴對方「我是誰」「我用什麼格式」← 認證資訊放這裡！
4. 內容（Body）：你要傳的資料（JSON 格式）
```

用業務銷售的例子：

```
POST https://crm.example.com/api/deals
Headers:
  Authorization: Bearer abc123（你的通行證 Token）
  Content-Type: application/json（我傳的是 JSON 格式）
Body:
  {
    "customer": "台積電",
    "amount": 1500000,
    "stage": "提案中"
  }
```

### 回應（Response）

對方收到之後，會回你：

```
狀態碼：201 Created（成功建立）
Body：
  {
    "id": "DEAL-001",
    "message": "商機已建立"
  }
```

### 常見狀態碼（記這五個就夠）

| 狀態碼 | 意思 | 比喻 | 跟認證的關係 |
|--------|------|------|------------|
| **200** | 成功 | 「好的，辦好了」 | Token 正確 |
| **201** | 成功建立 | 「好的，新帳戶開好了」 | Token 正確 |
| **401** | 未授權 | 「你是誰？請出示證件」 | **Token 錯誤或過期** |
| **403** | 禁止存取 | 「認識你，但你沒這個權限」 | **Token 的權限不夠** |
| **404** | 找不到 | 「沒有這個東西」 | 跟認證無關 |
| **500** | 伺服器錯誤 | 「我們內部出問題了」 | 跟認證無關 |

> **遇到 401/403 是最常見的串接問題。** 十次有八次是 Token 貼錯、過期、或權限不足。

### 在 n8n 裡的對應

**HTTP Request 節點** 就是在幫你做這件事：

```
你設定：
  Method = POST
  URL = https://...
  Authentication = 選 Credential（不用手動填 Token）
  Body = { "customer": "台積電", ... }

n8n 幫你送出去，自動帶上 Token，然後把回應傳給下一個節點。
```

---

## 7. RESTful — 窗口的設計規範

### 一句話解釋

> RESTful 是「大家約定好的 API 設計方式」，讓你看到網址就知道在做什麼。

### 生活比喻

想像一條街上有很多銀行，每家銀行的窗口編號方式都不一樣，很混亂。
後來大家約定：「1 號窗口辦開戶、2 號窗口辦轉帳、3 號窗口辦查詢」。
**RESTful 就是這個「大家都遵守的窗口編號規則」。**

### RESTful 的規則

用「商機管理」的例子：

| 你要做什麼 | HTTP 方法 | URL | 說明 |
|-----------|----------|-----|------|
| 看所有商機 | GET | `/api/deals` | 列出全部 |
| 看某一筆商機 | GET | `/api/deals/123` | 看 ID=123 那筆 |
| 建立新商機 | POST | `/api/deals` | 新增一筆 |
| 修改商機 | PUT | `/api/deals/123` | 改 ID=123 那筆 |
| 刪除商機 | DELETE | `/api/deals/123` | 刪 ID=123 那筆 |

### 看到 URL 就能猜到在幹嘛

```
GET    /api/customers          → 列出所有客戶
GET    /api/customers/5        → 查看第 5 號客戶
POST   /api/customers          → 新增客戶
GET    /api/customers/5/deals  → 查看第 5 號客戶的所有商機
```

**這就是 RESTful 的好處：看 URL + Method 就知道在做什麼。**

### 不是所有 API 都是 RESTful

| 類型 | 說明 | 常見場景 |
|------|------|---------|
| RESTful API | 最常見，URL 代表資源 | 大部分 SaaS（Notion、Slack、HubSpot） |
| GraphQL | 一個網址，用 query 語法問 | GitHub、Shopify |
| SOAP | 很舊的格式，用 XML | 政府系統、銀行內部 |

### 在 n8n 裡的對應

當你用 HTTP Request 節點打外部 API 時，你就是在用 RESTful：

```
Method: GET
URL: https://crm.example.com/api/deals?stage=提案中
Authentication: 選你的 CRM Credential

→ 拿到所有「提案中」的商機
```

---

## 8. Webhook — 反過來，系統主動通知你

### 一句話解釋

> Webhook 是「不是你去問，而是對方有事會主動打電話給你」。

### 生活比喻

**沒有 Webhook 的世界（輪詢）：**
```
你每 10 分鐘打電話給快遞：「我的包裹到了嗎？」
快遞：「還沒。」
你 10 分鐘後再打：「到了嗎？」
快遞：「還沒。」
...重複 100 次...
快遞：「到了。」
```

**有 Webhook 的世界：**
```
你跟快遞說：「到了打我電話 0912-345-678」
快遞包裹到了 → 主動打給你：「到了！」
```

**Webhook 就是你給對方一個網址（電話號碼），有事他會主動通知你。**

### API vs Webhook 的核心差異

| | API（你去問） | Webhook（他來通知） |
|---|---|---|
| 方向 | 你 → 對方 | 對方 → 你 |
| 時機 | 你決定什麼時候問 | 對方有事才通知 |
| 比喻 | 你打電話去銀行查餘額 | 銀行簡訊通知你有入帳 |
| n8n 節點 | HTTP Request | Webhook Trigger |
| 需要認證嗎 | 你要證明自己（帶 Token） | 對方要證明自己（驗簽名） |

### 實際運作流程

```
Step 1：你在 n8n 建立一個 Webhook 節點
        → n8n 產生一個網址：https://your-n8n.com/webhook/new-deal

Step 2：你把這個網址貼到 CRM 設定裡
        → 告訴 CRM：「有新商機時，POST 到這個網址」

Step 3：某天業務建立了一筆新商機
        → CRM 自動 POST 資料到你的 n8n

Step 4：n8n 收到資料，自動執行後續流程
        → 通知 Slack、更新 Google Sheets、寄 Email...
```

### Webhook 的認證問題

```
API 是你去問別人 → 你要帶 Token 證明自己
Webhook 是別人來找你 → 你要驗證「來的人是不是真的是 CRM」

常見的驗證方式：
  1. Secret Token：CRM 在 Header 裡帶一個密碼，你檢查密碼對不對
  2. 簽名驗證：CRM 用密鑰對資料簽名，你用同一個密鑰驗證
  3. IP 白名單：只允許特定 IP 送資料進來
```

### 在 n8n 裡的對應

```
Webhook Trigger 節點：
  Method: POST
  Path: /new-deal
  Authentication: Header Auth / 或不設（看安全需求）

  → 當有人 POST 到 https://your-n8n.com/webhook/new-deal
  → 這個 workflow 就會自動啟動
```

**Demo 1 的 Webhook Trigger 就是這個概念。**

---

## 9. 網路爬蟲 — 沒有窗口時，自己去看

### 一句話解釋

> 網路爬蟲就是「對方沒有開 API 窗口，你只好自己去他的網站上把資料抄下來」。

### 生活比喻

```
有 API 的情況：
  你走到服務窗口，問：「台積電的股價多少？」
  窗口回答：「$890」
  → 乾淨、快速、有規則

沒有 API 的情況（爬蟲）：
  你走到佈告欄前面，自己用眼睛找到台積電那一行
  然後用筆抄下來：「$890」
  → 可以做，但比較麻煩，而且佈告欄改版你就抄不到了
```

### API vs 爬蟲

| | API | 爬蟲 |
|---|---|---|
| 對方有提供 | 有官方窗口 | 沒有，自己去看 |
| 資料格式 | 乾淨的 JSON | 混在 HTML 裡，要自己挖 |
| 需要認證嗎 | 通常需要（Token） | 通常不用（公開網頁） |
| 穩定性 | 高（有版本控制） | 低（網頁改版就壞） |
| 合法性 | 通常允許 | 要看對方的使用條款 |
| 速度 | 快 | 慢（要載入整個網頁） |

### 爬蟲的基本流程

```
Step 1：發送 HTTP GET 到目標網頁
        → 拿到一大堆 HTML 原始碼

Step 2：從 HTML 裡面找到你要的資料
        → 用 CSS Selector 或 XPath 定位

Step 3：整理成結構化資料
        → 變成你能用的 JSON 格式
```

### 在 n8n 裡的對應

n8n 有兩種方式做爬蟲：

**方式 1：HTTP Request + HTML Extract**
```
HTTP Request 節點（GET 網頁）
    ↓
HTML Extract 節點（用 CSS Selector 挖資料）
    ↓
整理好的 JSON 資料
```

**方式 2：用內建的瀏覽器自動化**
```
有些網站需要 JavaScript 執行才能看到內容
→ 這時候用 n8n 的 Browser 相關節點
→ 像真人一樣打開瀏覽器、等頁面載入、再抓資料
```

### 什麼時候該用 API，什麼時候用爬蟲？

```
決策流程：

  對方有 API 嗎？
    ├→ 有 → 用 API（優先！）
    └→ 沒有 → 對方允許爬嗎？
                ├→ 允許 → 用爬蟲
                └→ 不允許 → 找其他資料來源
```

---

## 10. 所有概念的關係圖

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│                     n8n（膠水層）                            │
│          接收 → 處理 → 輸出，幫你黏所有系統                   │
│                                                            │
│   ┌────────────────────────────────────────────────────┐   │
│   │                                                    │   │
│   │  JSON ← 資料格式（大家都用這個格式溝通）               │   │
│   │   ↑                                               │   │
│   │   │                                               │   │
│   │  HTTP 請求 ← 溝通方式（GET / POST / PUT / DELETE）  │   │
│   │   ↑                                               │   │
│   │   │                                               │   │
│   │  認證 / Token ← 身分驗證（不然 API 不理你）          │   │
│   │   ↑                                               │   │
│   │   │                                               │   │
│   │  RESTful ← 設計規範（URL 怎麼取、Method 怎麼配）     │   │
│   │   ↑                                               │   │
│   │   │                                               │   │
│   │  ┌───────────┬──────────────┐                     │   │
│   │  │           │              │                     │   │
│   │  API         Webhook        爬蟲                   │   │
│   │  (你去問)    (他來通知)      (自己去看)              │   │
│   │                                                    │   │
│   │  n8n 節點     n8n 節點       n8n 節點               │   │
│   │  HTTP Req    Webhook        HTTP Req              │   │
│   │  + 專用節點   Trigger        + HTML Extract         │   │
│   │                                                    │   │
│   │  認證方式     認證方式       認證方式                 │   │
│   │  Credential  Secret/簽名    通常不需要               │   │
│   │                                                    │   │
│   └────────────────────────────────────────────────────┘   │
│                                                            │
│   n8n Credential：統一管理所有 Token / API Key / OAuth       │
│   → 設定一次，所有 workflow 共用                              │
│   → 加密儲存，匯出不外洩                                     │
│                                                            │
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

## 11. n8n 實戰對照表

### 概念 → n8n 節點 → 使用場景

| 概念 | n8n 節點 / 功能 | 什麼時候用 | Demo 範例 |
|------|----------------|-----------|----------|
| 膠水層 | n8n 本身 | 串接任何系統 | 所有 Demo |
| JSON | 所有節點 | 每個節點都在傳 JSON | 全部 Demo |
| API (呼叫別人) | HTTP Request / 專用節點 | 主動去拿資料或執行動作 | Demo 4：打 CRM API |
| API (被呼叫) | Webhook Trigger | 別人要通知你的時候 | Demo 1：Webhook Trigger |
| 認證 / Token | Credential 設定 | 串接任何需要登入的服務 | 所有專用節點 |
| HTTP GET | HTTP Request (GET) | 查詢、讀取資料 | 查詢 CRM 商機列表 |
| HTTP POST | HTTP Request (POST) | 新增、送出資料 | Demo 4：更新 CRM |
| RESTful | HTTP Request | 打第三方 SaaS API | Demo 4：httpbin.org |
| Webhook | Webhook Trigger | 等待外部事件觸發 | Demo 1：接收 CRM 通知 |
| 爬蟲 | HTTP Request + Extract | 對方沒有 API | 抓競品網站價格 |
| Credential | n8n Settings → Credentials | 統一管理認證資訊 | 每個專用節點 |

### 一個完整的業務場景，所有概念全用到

```
場景：「CRM 有新商機時，自動查詢客戶資料，通知業務主管」

1. [膠水層]   n8n 負責串接所有系統
2. [Webhook]  CRM 建立新商機 → POST 到你的 n8n
3. [JSON]     收到的資料是 JSON 格式：{ customer: "台積電", amount: 1500000 }
4. [API]      用 HTTP Request 去查客戶資料庫的 API
5. [Token]    帶上 Bearer Token 通過認證
6. [Credential] Token 存在 n8n Credential 裡，不用每次手動填
7. [HTTP]     GET https://crm.example.com/api/customers/台積電
8. [RESTful]  URL 設計遵循 RESTful 規範（/api/customers/名稱）
9. [爬蟲]     如果客戶沒在 CRM 裡，用爬蟲去公開網站查基本資料

最後 → 整理好的資料 → 通知 Slack（用 Slack Credential）→ 寫入 Google Sheets（用 Google Credential）
```

---

## 口訣記憶

```
n8n 是膠水，黏起所有系統
JSON 是語言，HTTP 是方法
REST 是規範，API 是窗口
Token 是通行證，Credential 是鑰匙包
Webhook 反著來，爬蟲自己找

→ 在 n8n 裡，Credential 設定一次，到處都能用
→ 專用節點幫你包好認證和格式
→ HTTP Request 是萬用工具，什麼 API 都能打
→ 遇到 401 先檢查 Token，八成是認證問題
```

---

## 常見問題 FAQ

**Q：我不會寫程式，能用 API 嗎？**
A：可以。n8n 的 HTTP Request 節點就是讓你「不寫程式也能打 API」。你只需要填 URL、選 Method、設定 Credential。

**Q：Token 和 API Key 有什麼差別？**
A：API Key 通常是固定不變的（像大樓密碼）。Token 通常會過期、可以被撤銷、有特定權限範圍（像臨時訪客證）。實務上很多人混用這兩個詞，不用太糾結。

**Q：OAuth 好複雜，一定要用嗎？**
A：如果你串接的服務要求 OAuth（Google、Slack），那就得用。好消息是 n8n 的專用節點已經幫你處理了大部分 OAuth 流程，你只要按「Connect」、登入、授權就好。

**Q：Credential 存在哪裡？安全嗎？**
A：存在 n8n 的資料庫裡，加密儲存。匯出 workflow JSON 時不會包含 Credential 內容。但你的 n8n 伺服器本身要做好安全防護（設密碼、HTTPS）。

**Q：Webhook 和 API 可以同時用嗎？**
A：當然。很多系統兩個都支援。例如：
- 你用 **Webhook** 接收「新商機建立」的通知
- 收到通知後用 **API**（帶 Token）去查詢更多客戶細節

**Q：爬蟲合法嗎？**
A：要看對方的使用條款（Terms of Service）。公開資料通常可以，但不要過度頻繁請求（會被封鎖），也不要爬需要登入的私人資料。

**Q：為什麼 n8n 裡面有些節點叫 Slack、有些叫 HTTP Request？**
A：Slack 節點 = 已經幫你包好 API + 認證的客戶端（選 Credential 就搞定）。HTTP Request = 萬用工具，什麼 API 都能打，但要自己看 API 文件、自己設定認證。

**Q：JSON 一定要手寫嗎？**
A：在 n8n 裡幾乎不用手寫。Set 節點和 Expression 會自動幫你組 JSON。只有用 Code 節點時才需要手寫。

**Q：遇到 401 錯誤怎麼辦？**
A：九成是認證問題。按這個順序檢查：
1. Token / API Key 有沒有貼對？（多餘的空白、換行）
2. Token 有沒有過期？
3. Credential 有沒有選對？
4. Token 的權限夠不夠？（例如只有 read 權限但你要 write）
