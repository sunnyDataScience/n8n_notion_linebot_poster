# 實作卡 A — AI 科技新聞篩選器

> 預估時間：15–20 分鐘 | 難度：中等
> 涵蓋概念：Manual Trigger、HTTP Request、Code、IF、Set

---

## 情境

你是新創公司的 PM，老闆每天早上要你整理「跟 AI 有關的科技新聞」。
與其每天手動瀏覽，不如讓 n8n 自動篩選！

**目標：** 從科技新報 RSS 抓新聞 → 篩選含「AI」的文章 → 輸出乾淨清單

---

## 素材與設定

| 項目 | 值 |
|------|-----|
| RSS 來源 | `https://technews.tw/feed/` |
| 格式 | RSS (XML)，免認證 |
| 篩選關鍵字 | `AI`（不分大小寫） |
| 最終輸出欄位 | `title`、`link`、`categories` |

---

## 流程圖

```
Manual Trigger
      │
      ▼
HTTP Request（GET RSS）
      │
      ▼
Code（解析 XML → 結構化資料）
      │
      ▼
IF（標題或分類含 AI？）
  ├─ true  ──▶ Set（只保留 3 欄位）
  └─ false ──▶（不處理）
```

---

## Step 1：建立 Manual Trigger

1. 在 n8n 畫布按 **+** 新增節點
2. 搜尋 `Manual Trigger`，加入畫布
3. 不需要任何設定

---

## Step 2：加入 HTTP Request 節點

1. 從 Manual Trigger 拉線，新增 `HTTP Request`
2. 設定如下：

| 欄位 | 值 |
|------|-----|
| Method | `GET`（預設） |
| URL | `https://technews.tw/feed/` |

3. 其他設定保持預設
4. 按 **Test step** 測試 → 應該看到一大段 XML 文字在 `data` 欄位

---

## Step 3：加入 Code 節點（解析 XML）

1. 從 HTTP Request 拉線，新增 `Code`
2. Language 選 **JavaScript**
3. 貼上以下程式碼：

```javascript
// Parse RSS XML — extract each <item> into structured data
const xml = $input.first().json.data;
const items = [];
const itemRegex = /<item>([\s\S]*?)<\/item>/g;
let match;

while ((match = itemRegex.exec(xml)) !== null) {
  const block = match[1];

  // Extract title (remove CDATA wrapper)
  const title = (block.match(/<title>(.*?)<\/title>/) || ['', ''])[1]
    .replace(/<!\[CDATA\[|\]\]>/g, '');

  // Extract link
  const link = (block.match(/<link>(.*?)<\/link>/) || ['', ''])[1];

  // Extract publish date
  const pubDate = (block.match(/<pubDate>(.*?)<\/pubDate>/) || ['', ''])[1];

  // Extract all <category> tags
  const cats = [];
  const catRegex = /<category><!\[CDATA\[(.*?)\]\]><\/category>/g;
  let catMatch;
  while ((catMatch = catRegex.exec(block)) !== null) {
    cats.push(catMatch[1]);
  }

  items.push({
    title,
    link,
    pubDate,
    categories: cats.join(', ')
  });
}

return items.map(item => ({ json: item }));
```

4. 按 **Test step** → 應該看到 30–40 筆結構化資料，每筆有 `title`、`link`、`pubDate`、`categories`

**理解重點：** 這段程式碼做的事 = ETL 的 **E**xtract + **T**ransform
- 原始資料：一大坨 XML 字串
- 處理後：多筆乾淨的 JSON 物件

---

## Step 4：加入 IF 節點（篩選 AI）

1. 從 Code 拉線，新增 `IF`
2. 設定條件：

**條件一：**

| 欄位 | 值 |
|------|-----|
| Value 1 (左邊) | `{{ $json.title }}` |
| Operation | `contains` |
| Value 2 (右邊) | `AI` |

3. 按左下角 **+ Add condition**，新增第二個條件：

**條件二：**

| 欄位 | 值 |
|------|-----|
| Value 1 (左邊) | `{{ $json.categories }}` |
| Operation | `contains` |
| Value 2 (右邊) | `AI` |

4. 上方的 **Combine** 選 **ANY**（= OR，任一條件成立就通過）
5. 按 **Test step** → 資料會分成 true / false 兩組

---

## Step 5：加入 Set 節點（整理輸出）

1. 從 IF 的 **true** 輸出拉線，新增 `Set`
2. 切換到 **Manual Mapping** 模式
3. 新增 3 個欄位：

| 欄位名 | 類型 | 值 |
|--------|------|-----|
| `title` | String | `{{ $json.title }}` |
| `link` | String | `{{ $json.link }}` |
| `categories` | String | `{{ $json.categories }}` |

4. 關鍵設定：**Include Other Fields** 設為 `false`（只保留這 3 欄位）
5. 按 **Test step** → 應該只看到乾淨的 3 欄位輸出

---

## 驗收 Checklist

按 **Execute Workflow** 跑完整流程後檢查：

- [ ] IF 的 **true** 分支有輸出（至少 3–5 篇 AI 相關新聞）
- [ ] 最終 Set 輸出**只有** `title`、`link`、`categories` 三個欄位
- [ ] IF 的 **false** 分支的文章標題都**不含** AI

---

## 延伸挑戰

完成太快？試試這些：

1. **自動排程：** 把 Manual Trigger 換成 `Schedule Trigger`，設定每天 09:00 執行
2. **加入時間戳：** 在 Set 多加一欄 `fetched_at`，值填 `{{ $now.format("YYYY-MM-DD HH:mm") }}`
3. **換關鍵字：** 把 AI 換成「半導體」或「資安」，看篩選結果有什麼變化
4. **雙重篩選：** 在 IF 和 Set 之間再加一個 IF，進一步過濾「24 小時內」的文章

---

## 常見卡關 Q&A

**Q：HTTP Request 回來是空的？**
A：確認 URL 有沒有打錯。正確的是 `https://technews.tw/feed/`（結尾有斜線）

**Q：Code 節點執行後 0 筆？**
A：確認程式碼有完整貼上。常見問題是 regex 的反斜線 `\` 被吃掉

**Q：IF 的 true 分支 0 筆？**
A：確認 Combine 選的是 **ANY**（OR），不是 ALL（AND）。另外確認 `contains` 的值是 `AI`（大寫）

**Q：Set 輸出還有很多多餘欄位？**
A：確認 **Include Other Fields** 設為 `false`
