# 動態問卷系統 — 共用規格（Single Source of Truth）

> 本課程（MySQL / Spring Boot / Angular / Docker）所有「動態問卷」相關的範例、練習、解答，
> 一律以本文件為準。修改章節內容時若與本文件衝突，以本文件為準；要改規格就先改本文件。
>
> 需求來源：`slidev-java/動態問券-更新版.pdf`（Java 版，20 頁）、`slidev-java/汶欣的動態問卷.pdf`（畫面參考，30 頁）。
> 各 repo 內的 `SURVEY-SPEC.md` 內容必須保持一致。

## 1. 技術版本

| 項目 | 版本 |
| ---- | ---- |
| Java | 21（Eclipse Temurin） |
| Spring Boot | **4.1.1**（穩定版；不選 SNAPSHOT / RC；4.1.2 正式版出來後只需改版本號） |
| 建置工具 | Gradle - Groovy（Initializr：Project = Gradle - Groovy、Language = Java、Packaging = Jar） |
| Spring 家族 | Spring Framework 7、Spring Security 7、Hibernate 7、Jackson 3（`tools.jackson.*`） |
| MySQL | 8.4 |
| Angular | **21**（`@angular/cli@21`，Node 20.19+ / 22.12+ / 24） |
| Angular Material | 21 |

## 2. 專案固定命名

| 項目 | 值 |
| ---- | -- |
| 後端專案 / Artifact | `dynamic-survey` |
| Group / Package | `com.example` / `com.example.survey` |
| 前端專案 | `survey-web` |
| 資料庫 | `dynamic_survey`（utf8mb4） |
| 後端 Port / 前端 Port | 8080 / 4200 |
| Package 分層 | `controller` `service` `repository` `entity` `dto` `vo` `security` `config` `exception` |
| 統一回應 | `AppResponse<T>`（`code`、`message`、`data`），狀態碼列舉 `RspCode` |

## 3. 資料表（6 張）

```
users 1 ──< survey_responses >── 1 surveys 1 ──< questions 1 ──< options
                  │                                  │
                  └──< response_answers >────────────┘ (question_id)
```

| 表 | 欄位 |
| -- | ---- |
| `users` | `id` PK AI、`name`、`email` UNIQUE、`password`（BCrypt）、`phone`、`role`（`USER` / `ADMIN`）、`created_at` |
| `surveys` | `id` PK AI、`title`（≤50）、`description`（≤300）、`start_date`、`end_date`、`published`（TINYINT，0 = 未發佈、1 = 已發佈）、`created_at` |
| `questions` | `id` PK AI、`survey_id` FK、`title`、`type`（`SINGLE` / `MULTI` / `TEXT`）、`required`（TINYINT）、`order_index` |
| `options` | `id` PK AI、`question_id` FK、`label`、`order_index` |
| `survey_responses` | `id` PK AI、`survey_id` FK、`user_id` FK（可為 NULL）、`name`、`phone`、`email`、`age`（可為 NULL）、`submitted_at`；**UNIQUE(`survey_id`, `email`)** |
| `response_answers` | `id` PK AI、`response_id` FK、`question_id` FK、`answer_text`（**多選以分號 `;` 串接**） |

- 刪除問卷時，底下 `questions`、`options`（`ON DELETE CASCADE`）一併刪除；已有作答的問卷不會進入可刪除狀態（見 §4）。
- 「選項用陣列」：API 與前端的 `QuestionDTO.options` 是 **陣列**（`OptionDTO[]`），資料庫則以 `options` 表儲存。

## 4. 問卷狀態（由 `published` + 日期計算，不存進資料庫）

| 顯示狀態 | 條件（`today` 為今天，起訖日皆含） |
| -------- | -------------------------------- |
| 未發佈 | `published = 0` |
| 尚未開始 | `published = 1` 且 `today < start_date` |
| 進行中 | `published = 1` 且 `start_date <= today <= end_date` |
| 已結束 | `published = 1` 且 `today > end_date` |

| 顯示狀態 | 後台：可編輯 | 後台：可刪除 | 後台：看結果 | 前台：列表連結 | 前台：看統計 |
| -------- | :---: | :---: | :---: | :---: | :---: |
| 未發佈 | ✅ | ✅ | ❌ | 不顯示 | ❌ |
| 尚未開始 | ✅ | ✅ | ❌ | 顯示但取消連結 | ❌ |
| 進行中 | ❌（唯讀） | ❌ | ✅ | 可填寫 | ✅ |
| 已結束 | ❌（唯讀） | ❌ | ✅ | 取消連結 | ✅ |

## 5. 前台需求

1. **列表頁**：標題模糊搜尋 + 開始 / 結束日期區間（兩條件組合）；分頁，預設每頁 10 筆、每頁筆數可自訂；欄位：編號、名稱、狀態、開始時間、結束時間、觀看統計。
2. **作答頁**：固定欄位 姓名、手機、Email 必填，年齡選填；動態題目（單選 / 多選 / 文字，可設必填）；同一 Email 不可重複填寫同一份問卷；按送出**不寫資料庫**，先存進 **HttpSession** 並跳確認頁；必填與格式檢查以提醒視窗告知。
3. **確認頁**：唯讀，從 Session 讀取；單選、多選只顯示被選取的項目；「送出」寫入資料庫並回列表、「修改」回填寫頁且帶回先前資料；兩個按鈕都要詢問使用者是否執行。
4. **統計頁**：所有題目的統計，選擇題用圓餅圖，文字題列出內容。
5. **會員**（保留）：註冊、登入（JWT）、我的填寫紀錄、修改會員資料。登入為選用，未登入也能匿名作答。

## 6. 後台需求（限 `ADMIN`）

1. **登入**：Email + 密碼（8~12 字元）；欄位格式卡控。
2. **列表頁**：搜尋（標題模糊、開始 / 結束日期只允許輸入日期，搜尋起訖包含在區間內的問卷）；分頁預設 10 筆；欄位含勾選刪除、編號、名稱（連結）、狀態、開始、結束、結果。
   - 名稱連結：未發佈 / 尚未開始 → 可修改頁；進行中 / 已結束 → 唯讀頁。
   - 刪除：只有「未發佈」與「尚未開始」的列可勾選；可**批次**刪除，呼叫後端 API。
3. **新增 / 編輯（三步驟頁籤）**：
   1. **基本資料**：標題、說明必填；**開始日期預設 今天 + 2、結束日期預設 今天 + 7**，可自行設定；日期防呆：開始日期必須 **晚於今天**（不能是今天或更早）、結束日期必須在開始日期之後；編輯模式要帶入原資料；按「下一步」前檢查必填。
   2. **題目**：題目名稱、類型（單選 / 多選 / 文字）、是否必填、選項（陣列）；「加入」把題目暫存到 **Session**（不是資料庫）；「編輯」把值帶回輸入框且「加入」鈕變「編輯」；「刪除」只刪除畫面上的資料，不呼叫後端 API；「送出」跳到確認頁。
   3. **確認頁**：檢視問卷與題目；「僅儲存」寫入 DB 但不發佈（`published = 0`）；「儲存並發佈」寫入 DB 並發佈（`published = 1`）。
4. **問卷回饋**：列出所有作答（依填寫編號**倒序**）；「前往」進入細節頁（問卷題目 + 該使用者答案，唯讀）。
5. **統計**：所有題目的統計，選擇題圓餅圖、文字題列表。

## 7. REST API

統一前綴 `/api`。除註冊、登入、前台查詢與作答外，其餘需 JWT；`/api/admin/**` 需 `ADMIN`。

| 方法 | 路徑 | 說明 |
| ---- | ---- | ---- |
| POST | `/api/auth/register` | 註冊 |
| POST | `/api/auth/login` | 登入，回傳 access / refresh token |
| POST | `/api/auth/refresh` | 換發 access token |
| GET / PUT | `/api/users/me` | 查詢 / 修改會員資料 |
| GET | `/api/surveys` | 前台列表：`title`、`startDate`、`endDate`、`page`（從 0）、`size`（預設 10） |
| GET | `/api/surveys/{id}` | 問卷含題目 |
| GET | `/api/surveys/{id}/statistics` | 統計 |
| POST | `/api/surveys/{id}/draft` | 作答暫存到 Session |
| GET | `/api/surveys/{id}/draft` | 讀取 Session 暫存 |
| POST | `/api/surveys/{id}/submit` | 確認送出，寫入 DB |
| GET | `/api/users/me/responses` | 我的填寫紀錄 |
| GET | `/api/admin/surveys` | 後台列表（同前台參數；含全部狀態） |
| POST | `/api/admin/surveys` | 新增問卷（`published` 決定是否發佈） |
| PUT | `/api/admin/surveys/{id}` | 修改問卷（僅未發佈 / 尚未開始） |
| DELETE | `/api/admin/surveys` | 批次刪除，Body 為 `id` 陣列（僅未發佈 / 尚未開始） |
| POST / GET | `/api/admin/survey-draft` | 後台編輯 Session 暫存（題目） |
| GET | `/api/admin/surveys/{id}/responses` | 回饋列表（`submittedAt`、`id` 倒序，分頁） |
| GET | `/api/admin/responses/{id}` | 單筆作答明細 |
| GET | `/api/admin/surveys/{id}/statistics` | 統計 |

分頁回應統一為 `{ content: [...], page, size, totalElements, totalPages }`。

## 8. 各章切入點對照

| Repo / 章 | 問卷情境 |
| --------- | -------- |
| MySQL ch03–ch10 | 六張表的關聯、DDL、查詢、JOIN、Index、View、子查詢 |
| Spring Boot ch03 | 建立 `dynamic-survey` 專案 |
| Spring Boot ch26–28 | Survey / Question / Option 的 JPA、`Pageable` 分頁搜尋 |
| Spring Boot ch37 | Survey CRUD（含狀態計算） |
| Spring Boot ch38–41 | 文件、驗證、Session 暫存作答、測試 |
| Spring Boot ch44–45 | 會員註冊登入、`ADMIN` 權限、JWT |
| Spring Boot ch47 | 整合驗收 |
| Angular ch23–24、29、33、35、38、42–43、50–52 | 路由導覽、元件傳值、串接 API、列表分頁、日期防呆、搜尋、統計圖、對話框、作答表單與驗證 |
| Angular ch57–58 | 攔截器（Token、withCredentials、401 重試）、路由守衛（登入、管理員） |
| Angular ch59 | 前台 + 後台整合（綜合練習） |
| Docker ch01–08 | 以 `dynamic-survey` / `survey-web` / MySQL 三個容器貫穿 |
