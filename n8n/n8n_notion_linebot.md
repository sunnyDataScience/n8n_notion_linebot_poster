# n8n x Notion x LINE Bot 實戰工作坊：一天打造你的 AI 知識庫助理

## 課程核心理念

> **情境想像：** 你是系學會的新任幹部，前幾屆留下來的東西散落在三個 Google Drive、兩個 LINE 群組、一份沒人維護的共筆，還有學長姐腦袋裡。每次有人問「去年迎新的場地合約在哪？」「社費申請表怎麼填？」你就要花 30 分鐘翻群組訊息。
>
> 如果有一個 LINE Bot，學弟妹傳訊息問它就能秒回答案、還附上原始文件連結呢？**今天你就要把這個東西做出來。**

本工作坊專為大學生設計 — 不管你是社團幹部、專題小組組長、還是想幫自己建一套考試筆記搜尋系統的人。你不需要會寫程式，只需要會「拖拉節點」和「設定欄位」。本課程將帶你用 n8n 這條自動化輸送帶，把 Notion 知識庫、Google Drive 文件、Pinecone 語意搜尋和 LINE Bot 串成一套完整的 AI 問答系統。

**目標：** 學員在一天結束時，能獨立完成一套「文件自動索引 + LINE Bot 智能問答」的工作流，並部署到雲端穩定運行。

**工具鏈：** n8n (工作流引擎) + Notion (結構化知識庫) + Google Drive (原始資料倉庫) + Pinecone (向量搜尋索引) + LINE Messaging API (使用者入口) + Zeabur (雲端部署平台)

**你可以用這套系統做什麼？（大學生實用場景）**

| 場景 | 痛點 | 做出來長怎樣 |
| --- | --- | --- |
| **社團知識傳承** | 每年換屆，資料散落各處，學弟妹什麼都要重問 | LINE Bot 秒回「迎新企劃書在這裡」並附連結 |
| **考試筆記搜尋** | PDF 講義在 Drive、手寫筆記整理在 Notion，找資料要翻兩邊 | 兩邊都自動索引，傳「傅立葉轉換怎麼推導」給 Bot，不管答案在 PDF 還是 Notion 都找得到 |
| **專題/畢業專題管理** | 組員丟檔案到 Drive、會議記錄寫在 Notion，資訊斷裂 | Drive 丟檔案 or Notion 寫筆記都自動摘要、標籤、建索引，問 Bot 就能跨來源搜尋 |
| **打工/實習交接** | 前一個工讀生離職，SOP 不知道放哪 | 新人加 LINE Bot 好友就能查所有 SOP |

**核心口訣：**
1. Drive 和 Notion 是兩個入口，Pinecone 是共同終點
2. 索引兩條路進去 (Upsert)，問答一條路出來 (Query)
3. 能上線的關鍵是：去重、重試、錯誤通知

---

## 課程大綱 (8 小時)

### **第一單元 (09:00 - 10:30): 搞懂資料住哪裡 — 架構思維與工具定位**

*   **主題：** 資料分層架構與工具角色分工。
*   **目標：** 建立學員對整套系統的全局觀，理解每個工具「為什麼在這裡」。
*   **內容：**
    1.  **觀念破冰：** 你不是在「寫程式」，你是在「搭流水線」。介紹 MVP 思維，能跑比完美重要。
        > **現場提問：** 「你們社團或專題的資料現在放在哪？」（通常答案是：LINE 記事本、Google Drive 某個沒人整理的資料夾、某個學長的個人雲端）。這就是今天要解決的問題。
    2.  **資料分層架構（用社團交接當例子）：**

        | 元件 | 角色定位 | 社團交接的比喻 | 放什麼 |
        | --- | --- | --- | --- |
        | **Google Drive** | 原始資料倉庫（入口 1） | 社辦那個塞滿資料夾的鐵櫃 | PDF、投影片、會議錄音轉文字、合約掃描檔 |
        | **Notion** | 結構化知識庫（入口 2） | 社團共筆、會議記錄、手動整理的筆記 | 文字內容、標籤、分類、狀態、來源連結 |
        | **Pinecone** | 向量索引 | 社辦裡那個什麼都知道的老鳥學長（你問他就能秒找到） | embedding + metadata |
        | **n8n** | 工作流引擎 | 自動幫你整理鐵櫃、更新清單的實習生 | 觸發、處理、寫回、通知 |
        | **Zeabur** | n8n 託管 | 讓這個實習生 24 小時不下班的宿舍 | 部署、網域、環境變數、DB |

    3.  **大學生版比喻：** Drive 是社辦鐵櫃（放 PDF、合約這些「檔案型」資料），Notion 是社團共筆（放會議記錄、SOP 這些「文字型」資料）。兩邊都會自動餵進 Pinecone — 那個什麼都記得的老鳥學長。n8n 就是自動化實習生：不管你把東西丟進鐵櫃還是寫在共筆上，它都會自動幫你整理、貼標籤、更新索引。
    4.  **系統全景圖：** 用 Mermaid 圖展示兩條入口（Drive / Notion）匯入 Pinecone，再由 LINE Bot 統一查詢的架構。
        ```mermaid
        flowchart TB
          subgraph "入口（資料進來）"
            GD[Google Drive<br/>PDF/投影片/合約]
            NT[Notion<br/>共筆/會議記錄/SOP]
          end
          subgraph "處理（AI 加工）"
            LLM[LLM 摘要 + 標籤 + 分 chunk]
            EMB[Embeddings 向量化]
          end
          subgraph "儲存（搜得到）"
            PC[Pinecone 向量資料庫]
          end
          subgraph "出口（問答）"
            LINE[LINE Bot 問答]
          end
          GD -->|Drive Trigger| LLM
          NT -->|Notion Trigger| LLM
          LLM --> EMB --> PC
          LINE -->|similarity search| PC
          PC -->|檢索結果| LINE
        ```
    5.  **Demo 時刻：** 講師現場示範完成品 — 在 LINE 上傳訊息「去年迎新的場地在哪裡租的？」，Bot 3 秒內回覆答案 + Notion 連結。讓學員知道今天結束時自己也能做到這件事。
*   **實作活動：** 每位學員選定自己的主題場景（社團交接 / 課堂筆記 / 專題管理 / 打工 SOP，四選一），準備好兩個入口：
    1.  **Drive 入口：** 在 Google Drive 建立一個資料夾，上傳 2-3 份 PDF/DOCX 檔案（講義、企劃書、合約等「檔案型」資料）。
    2.  **Notion 入口：** 在 Notion 建立知識庫 DB，手動寫入 1-2 筆文字內容（會議記錄、SOP 等「文字型」資料），設定必要欄位（title, source, tags, summary, status, last_indexed_at）。
    3.  **Notion 索引紀錄頁：** 另外建一個 DB，用來記錄所有被索引過的文件狀態（不管來源是 Drive 還是 Notion）。

### **第二單元 (10:40 - 12:00): n8n 節點工具箱 — 從零搭出你的第一條流水線**

*   **主題：** 認識 n8n 的核心節點，動手搭出 Hello World 工作流。
*   **目標：** 掌握 n8n 的六大類節點，並完成一個「Notion 新增頁面 → 自動 LINE 通知」的簡易工作流。
*   **內容：**
    1.  **n8n 介面導覽：** 畫布、節點面板、執行紀錄、Credentials 設定。
        > **類比：** n8n 的畫布就像你在玩 Scratch 或 Canva — 不是寫程式碼，是拖方塊、連線、填欄位。
    2.  **六大節點分類速覽（用點餐 App 當比喻）：**
        *   **A. 觸發 Trigger：** 客人按下「送出訂單」的那個按鈕 — Notion Trigger、Google Drive Trigger、Webhook、Cron。
        *   **B. 流程控制 Control：** 「內用還外帶？」的分流邏輯 — IF/Switch、Split In Batches、Error Trigger。
        *   **C. 資料處理 Data：** 把訂單格式化、印出明細 — Set/Edit Fields、Merge、Code。
        *   **D. 外部服務 Integrations：** 通知廚房、叫外送員 — Notion Node、Google Drive Node、Pinecone Node、HTTP Request。
        *   **E. AI/RAG 節點：** 根據客人口味推薦餐點的 AI 店員 — LLM、Embeddings、Retriever/Chain。
        *   **F. 可觀測性 Observability：** 出餐紀錄 + 客訴通知系統 — 寫 Log DB、通知節點。
    3.  **Credentials 設定實戰：** 手把手設定 Notion API、Google Drive API 的授權連線。
        > **踩坑提醒：** 這一步最容易卡關，但只要設定一次就好。就像你第一次把 IG 帳號綁到排程發文工具一樣，授權一次之後就不用再管了。
*   **實作活動：** 搭建第一條工作流 — 在 Notion 知識庫新增一筆「模擬社團文件」 → Notion Trigger 偵測到 → Set 節點整理欄位 → 輸出確認訊息。學員親手拖拉節點、設定欄位、按下執行，體驗「我在 Notion 打字，n8n 那邊就自動動了」的感覺。

---
**午休 (12:00 - 13:00)**
---

### **第三單元 (13:00 - 15:00): Flow A 索引更新 — 讓知識庫自動長出來**

*   **主題：** 搭建雙入口的知識庫索引流水線：Drive 和 Notion 各自觸發，共同匯入 Pinecone。
*   **目標：** 學會搭建兩條獨立的索引路徑（Flow A-1 Drive 路徑 + Flow A-2 Notion 路徑），讓不同來源的資料都能自動進入向量資料庫。
    > **場景帶入：** 想像你是系學會公關，資料散在兩個地方 — Drive 裡有前三屆留下來的 47 份 PDF（活動企劃、場地合約、廠商報價單），Notion 共筆裡有這學期的會議記錄和 SOP。你不可能一份一份讀完再整理。今天要做的就是：**不管資料從哪邊進來，AI 都自動幫你讀完、寫摘要、貼標籤、建索引。** 以後任何人問「去年和哪家音響公司合作的？」，系統 3 秒找到答案。
*   **內容：**
    1.  **Flow A 雙入口全景流程圖：**
        ```mermaid
        flowchart TB
          subgraph "Flow A-1：Drive 路徑"
            GD[Google Drive Trigger<br/>新增/更新檔案] --> G1[Download 檔案]
            G1 --> X1[Extract text<br/>PDF/DOCX/PPTX 轉文字]
            X1 --> S1[Set: normalize fields<br/>title, source=drive, source_url]
          end
          subgraph "Flow A-2：Notion 路徑"
            NT[Notion Trigger<br/>page added/updated] --> N1[Get Page Content]
            N1 --> S2[Set: normalize fields<br/>title, source=notion, source_url]
          end
          subgraph "共用處理管線"
            L1[LLM: summary + tags + chunks]
            E1[Embeddings: chunk vectors]
            P1[Pinecone: Upsert<br/>帶 metadata]
            LOG[Notion: 寫入/更新索引紀錄<br/>status=INDEXED]
          end
          S1 --> L1
          S2 --> L1
          L1 --> E1 --> P1 --> LOG
        ```
    2.  **Flow A-1 Drive 路徑 — 逐節點拆解：**
        > **適用場景：** 學長姐丟了一堆 PDF 到 Drive，或是你掃描了一疊紙本合約上傳。
        *   Google Drive Trigger：監控指定資料夾，偵測新增/更新檔案（注意：它是 polling，可能一次回多筆 items，要搭配 Split In Batches）。
        *   Google Drive Download：下載檔案內容。
        *   Extract Text：根據檔案類型（PDF/DOCX/PPTX）抽取純文字。
        *   Set 節點：統一欄位格式（title, source=drive, source_url=Drive 連結）。
    3.  **Flow A-2 Notion 路徑 — 逐節點拆解：**
        > **適用場景：** 你在 Notion 共筆寫了一篇會議記錄，或是更新了社團 SOP。
        *   Notion Trigger：監控知識庫 DB，偵測 page 新增/更新。
        *   Get Page Content：抓取頁面的完整文字內容和 properties。
        *   Set 節點：統一欄位格式（title, source=notion, source_url=Notion 連結）。
    4.  **共用處理管線（兩條路匯合後）：**
        *   LLM 節點：用 Prompt 生成 summary、tags、chunks（不管來源是 Drive 還是 Notion，到這步格式已經統一）。
        *   Embeddings + Pinecone Upsert：每個 chunk 帶 metadata（doc_id, title, tags, source=drive/notion, source_url, chunk_index, updated_at）。
        *   Notion 索引紀錄：寫入/更新一筆紀錄，標記 status=INDEXED、last_indexed_at。
    3.  **去重策略：** 如何避免重複索引（用 doc_id + updated_at 判斷）。
        > **生活類比：** 你在 Notion 改了一份文件的標題，n8n 又跑了一次。如果沒有去重，Pinecone 裡就會有兩份一模一樣的東西，搜尋時就會重複出現。就像你的 LINE 相簿裡同一張照片存了三次一樣煩。
    6.  **AI Vibe Coding 教學法：** 給學生一個固定 Prompt 範本，讓 AI 產出「節點清單 + 欄位 mapping」，學生照著拉節點就能動。

        ```text
        你是 n8n workflow architect。
        目標：建立雙入口知識庫索引系統。
        路徑 1：Google Drive Trigger → 下載檔案 → 抽取文字 → normalize fields
        路徑 2：Notion Trigger → 抓取頁面內容 → normalize fields
        共用管線：LLM 生成 summary + tags + chunks → embeddings → upsert 到 Pinecone（metadata 帶 source=drive/notion）→ 寫入 Notion 索引紀錄

        請輸出：
        1) 兩條路徑各自的 n8n 節點序列（每個節點名稱、用途）
        2) 共用管線的節點序列
        3) 每個節點的輸入/輸出欄位（用 JSON key 表示）
        4) 去重策略（如何避免重複索引，Drive 和 Notion 各自的 doc_id 怎麼生成）
        5) 錯誤處理（哪些步驟要 retry、失敗寫哪裡）
        ```
*   **實作活動：** 學員搭建完整的雙入口 Flow A。
    1.  **測試 Drive 路徑：** 把第一單元上傳的 PDF 檔案丟進 Drive 監控資料夾，看 n8n 自動抓到 → 抽取文字 → 摘要 → 向量化 → 寫入 Pinecone。
    2.  **測試 Notion 路徑：** 在 Notion 知識庫新增一筆會議記錄，看 n8n 自動抓到 → 摘要 → 向量化 → 寫入 Pinecone。
    3.  **驗證兩條路都通：** 到 Notion 索引紀錄頁面，確認兩筆資料都變成 `INDEXED`。
    > **成就感時刻：** 你從兩個不同的地方丟資料進去，Pinecone 那邊都收到了。以後不管是學長丟了一份 PDF 到 Drive，還是你自己在 Notion 寫了一篇筆記，系統都會自動處理。

### **第四單元 (15:10 - 17:00): Flow B + C — LINE Bot 問答與守門員上線**

*   **主題：** 串接 LINE Bot 做智能問答，並建立錯誤監控機制，讓系統穩定運行。
*   **目標：** 完成 LINE Bot 問答工作流，部署到 Zeabur，並建立守門員流程。
    > **場景帶入：** 社團迎新周，30 個大一新生加入 LINE 群組，每個人都在問：「社費怎麼繳？」「練習時間是什麼時候？」「上次表演的影片在哪？」幹部被洗版到崩潰。現在你把 Bot 拉進群組，新生直接問 Bot 就好，Bot 從你剛剛建好的知識庫裡找答案回覆，還附上原始文件連結。幹部終於可以去睡覺了。
*   **內容：**
    1.  **Flow B：LINE Bot 問答流程圖：**
        ```mermaid
        flowchart LR
          U[LINE User] --> W[Webhook: receive message]
          W --> P0[Parse intent + entities]
          P0 --> R1[Pinecone: similarity search]
          R1 --> R2[Optional: Notion lookup]
          R2 --> L2[LLM: answer with citations]
          L2 --> H[HTTP Request: reply to LINE]
        ```
    2.  **逐節點拆解：**
        *   Webhook 節點：接收 LINE 訊息（收 webhook 用 Webhook、回覆/推播用 HTTP Request）。
        *   Pinecone 檢索：similarity search（topK）。
        *   LLM 回答生成：附上來源連結（至少 Notion 連結）。
        *   HTTP Request：呼叫 LINE Reply API 回覆使用者。
    3.  **LINE API 工程現實提醒：** 速率限制、配額、重試/節流策略。
    4.  **Flow C：守門員流程（短但救命）：**
        > **類比：** 你架了一台自動販賣機，但你總不能放著不管吧？萬一卡幣了、缺貨了、有人投訴了呢？Flow C 就是那個「自動販賣機的監控系統」。
        *   Error Trigger → 寫 Notion Log DB → LINE/Slack 通知（壞了馬上通知你）。
        *   Cron 每晚：找 `status=NEW` 或 `last_indexed_at` 過期 → 重新走 Flow A（漏掉的自動補上）。
        *   Cron 每週：抽樣驗證（用熱門問句測試，檢索結果是否還合理）。
    5.  **Zeabur 部署 n8n — 必踩的坑：**
        *   `N8N_LISTEN_ADDRESS=0.0.0.0`（避免 IPv6 `::` 監聽導致 502）。
        *   `N8N_PORT=5678`（維持預設）。
        *   `N8N_PROTOCOL / N8N_HOST / WEBHOOK_URL`（讓 webhook URL 生成正確網域，LINE callback 必須正確）。
*   **實作活動：**
    1.  學員搭建 Flow B，用自己的手機打開 LINE，傳一個跟自己知識庫相關的問題（例如「社費怎麼繳？」「第三章的重點是什麼？」），親眼看 Bot 秒回答案。
    2.  搭建 Flow C 的 Error Trigger，故意觸發一個錯誤，確認 LINE 通知有送達到自己手機。
    3.  將 n8n 部署到 Zeabur，設定環境變數，確認關掉電腦之後 Bot 還是活著的。
    4.  **成果分享：** 學員互加彼此的 LINE Bot 好友，互相測試 — 用對方的知識庫問問題，看誰的 Bot 回答得最好。

### **總結 (17:00 - 17:30): 你的 AI 自動化之路**

*   **回顧與問答：** 總結從資料分層到三條流水線的全過程。
*   **你今天帶走了什麼：**
    *   一個活著的 LINE Bot（可以馬上分享給朋友、社團夥伴）
    *   一套自動化知識庫系統（丟檔案進去就自動索引）
    *   一個可以寫進履歷的 Side Project（「獨立建置 AI 知識庫問答系統」）
*   **下一步 — 真實的延伸場景：**
    *   **考試周強化版：** 把整學期的講義、共筆全部丟進去，期末考前用 LINE Bot 複習
    *   **社團升級版：** 擴充知識庫來源，把 LINE 群組的重要訊息也自動收錄
    *   **實習求職版：** 把這套系統改成「公司 SOP 問答 Bot」，面試時拿出來當作品集
    *   **技術進階：** 如何優化 RAG 品質（chunk 策略、reranking）、加入多輪對話記憶、接更多資料來源（Slack、Email、網頁爬蟲）
