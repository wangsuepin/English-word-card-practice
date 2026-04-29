# Flashcard App Design Document

本文件是這個專案的設計基準。之後新增功能、修改互動、調整資料格式或重構程式前，應先更新本文件，確認設計意圖後再改 code。

## 1. Product Goal

這是一個本機執行的 Vue/Vite 字卡練習工具。使用者匯入 CSV 後，可以逐張練習單字、翻面查看解釋與例句、播放英文語音，並用 Again / Hard / Good / Easy 做簡易複習排序。

目前定位是「輕量、即開即用、以單次練習流程為主」的前端工具，不依賴後端服務。

## 2. Tech Stack

- Framework: Vue 3, Composition API
- Build tool: Vite
- Styling: Tailwind CSS
- Runtime: Browser only
- Data source: 使用者手動匯入 CSV
- Speech: Browser `window.speechSynthesis`
- Image: 依單字從 `https://loremflickr.com` 載入圖片

## 3. Current File Structure

- `src/App.vue`
  - 主要 UI、狀態、CSV 解析、字卡流程、鍵盤事件、語音播放都在此檔。
- `src/main.js`
  - 建立 Vue app 並掛載到 `#app`。
- `src/style.css`
  - Tailwind 載入、全域版面基礎樣式、modal 動畫、scrollbar helper。
- `package.json`
  - Vite/Vue/Tailwind 相關依賴與 scripts。
- `setup-local-node.*`, `run-dev.*`
  - 本機環境輔助腳本，用專案內 Node/npm 啟動開發環境。

## 4. Core User Flow

1. 使用者打開 app。
2. app 顯示空狀態，提示匯入 CSV。
3. 使用者匯入 CSV。
4. app 解析 CSV，建立字卡列表 `allCards` 與待練習佇列 `queue`。
5. app 顯示第一張字卡正面。
6. 使用者可點卡片或按 Space 翻面。
7. 翻面後顯示圖片、解釋、例句與四個評分按鈕。
8. 使用者按 Again / Hard / Good / Easy。
9. app 依評分調整 `queue`，並更新統計。
10. `queue` 清空後顯示完成畫面與統計，可重新開始。

## 5. Data Model

### Card

```ts
type Card = {
  word: string
  parsed: ParsedDetails
}
```

### ParsedDetails

```ts
type ParsedDetails = {
  lines: ParsedLine[]
  exampleEnglish: string
}
```

### ParsedLine

```ts
type ParsedLine = {
  type: 'basic' | 'tag' | 'example'
  text: string
  enText?: string
}
```

### App State

```ts
allCards: Card[]
queue: Card[]
isFlipped: boolean
stats: {
  again: number
  hard: number
  good: number
  easy: number
}
showInfo: boolean
```

## 6. CSV Format

目前 CSV 採用簡單格式：

```csv
word,details
```

解析規則：

- 每一行代表一張卡片。
- 第一個 comma 前為 `word`。
- 第一個 comma 後全部視為 `details`。
- 目前不是完整 RFC CSV parser，因此含有 quoted comma、換行欄位、多欄位 escape 的資料可能解析不正確。

### Design Constraint

若未來要支援正式 CSV 格式，應先在本文件更新「CSV Format」與「Parsing Strategy」，再導入成熟 CSV parser，不應只用字串切割補丁硬撐。

## 7. Practice Scheduling

目前使用簡易佇列規則，不是真正長期 SRS：

- `again`: 目前卡片插回靠前位置，讓使用者很快再次看到。
- `hard`: 目前卡片插回佇列中段。
- `good`: 目前卡片放到佇列尾端。
- `easy`: 目前卡片不再放回佇列，視為本輪完成。

### Design Constraint

如果要加入長期記憶排程、日期、間隔、熟悉度、localStorage 或後端同步，必須先設計新的資料模型與 migration 策略。

## 8. UI States

目前主要畫面狀態：

- Empty State: 尚未匯入 CSV。
- Practice Front: 顯示單字與播放按鈕。
- Practice Back: 顯示圖片、解析內容、例句播放、評分按鈕。
- Complete State: 練習完成，顯示統計與重新開始。
- Info Modal: 顯示鍵盤操作說明。

### Responsive Rules

- 主內容最大寬度為 `max-w-3xl`。
- 全域 `#app` 負責置中與頁面 padding。
- 手機寬度下 header 允許換行。
- 長單字不可造成橫向捲動。
- 卡片背面內容過長時，內容區可在卡片內捲動，評分按鈕固定在底部。

## 9. Keyboard Controls

- `Enter`: 播放目前單字或例句語音。
- `Space`: 翻面。
- `ArrowUp`: 翻面後評為 Again。
- `ArrowLeft`: 翻面後評為 Hard。
- `ArrowRight`: 翻面後評為 Good。
- `ArrowDown`: 翻面後評為 Easy。
- `Escape`: 關閉 Info Modal。

鍵盤事件由 `window.addEventListener('keydown', handleKeyDown)` 管理，元件卸載時必須移除 listener。

## 10. Speech Behavior

語音播放使用瀏覽器內建 `speechSynthesis`：

- 播放前會先 `cancel()`，避免多段語音重疊。
- 單字與例句使用 `en-US`。
- app 不保證所有瀏覽器都有相同聲音、速度或可用語音。

若未來要加入語速、聲音選擇或離線語音，應先新增「Speech Settings」設計段落。

## 11. External Image Behavior

卡片背面圖片目前由單字組成 URL：

```text
https://loremflickr.com/400/240/{word}
```

並預載後續 3 張卡片圖片。

### Known Tradeoff

圖片結果不可控，且需要網路。若未來要提高品質，應先決定：

- 是否允許使用外部圖片 API。
- 是否需要快取。
- 是否要讓 CSV 自帶圖片 URL。
- 圖片載入失敗時的 fallback UI。

## 12. Current Limitations

- `src/App.vue` 承擔過多責任，後續功能變多時應拆分元件與 composables。
- CSV parser 很簡單，不支援完整 CSV 規格。
- 沒有 localStorage，重新整理後資料會消失。
- 沒有正式測試。
- 沒有錯誤提示，例如 CSV 格式錯誤、圖片載入失敗、語音不可用。
- 圖片來源不可控。
- 目前沒有真正跨日期 SRS。

## 13. Recommended Future Architecture

功能變多時，建議逐步拆成：

- `components/AppHeader.vue`
- `components/Flashcard.vue`
- `components/ProgressBar.vue`
- `components/StatsBar.vue`
- `components/InfoModal.vue`
- `components/CompleteState.vue`
- `composables/useSpeech.js`
- `composables/useKeyboardShortcuts.js`
- `utils/parseCards.js`
- `utils/scheduler.js`

拆分原則：

- 先有需求再拆，不為了形式拆。
- 資料解析與排程邏輯優先從 UI 中抽出。
- UI 元件保持 props / emits 清楚，不直接碰全域狀態。

## 14. Change Workflow

任何新功能或較大改動，請依以下順序：

1. 更新本文件相關章節。
2. 在「Proposed Changes」新增本次設計意圖。
3. 確認資料模型、UI 狀態、互動與限制。
4. 實作 code。
5. 執行驗證。
6. 在「Change Log」記錄完成項目。

小型純樣式修正可以直接改 code，但若會影響使用者流程、資料格式、排程、狀態或元件責任，仍應先改本文件。

## 15. Proposed Changes

此區用來記錄尚未實作、準備討論或準備開發的設計。

### Template

```md
### YYYY-MM-DD - Change Title

Goal:

Design:

Data impact:

UI impact:

Risks:

Verification:
```

## 16. Change Log

### 2026-04-29 - Initial Design Document

- 建立專案設計文件。
- 記錄現有 Vue/Vite 架構、資料模型、CSV 流程、字卡排程、鍵盤操作、語音與圖片行為。
- 建立後續改動前先更新設計文件的流程。
