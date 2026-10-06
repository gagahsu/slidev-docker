---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: 雲端部署
routeAlias: ch09
style: |
  .slidev-layout p,
  .slidev-layout li,
  .slidev-layout td,
  .slidev-layout th,
  .slidev-layout div {
    font-size: max(16px, 1em);
  }
  table {
    width: 100%;
    margin: 1rem 0;
    border-collapse: collapse;
  }
  th, td {
    padding: 8px !important;
    border: 1px solid #e2e8f0 !important;
  }
  .index-table td {
    text-align: center;
    font-family: monospace;
  }
---

<div class="flex flex-col justify-center items-center h-full" style="background: #ffffff;">
  <p style="color: #5eada0; font-size: 1rem; font-weight: 600; letter-spacing: 0.2em; text-transform: uppercase; margin-bottom: 1.2rem;">Docker 容器化課程</p>
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">雲端部署</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「以免費、免綁卡的平台部署 SSDS」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
【開場白】
本章為課程最後一章：雲端部署。

【回顧】
前八章已將 SSDS 前後端包裝為 Image、以 Compose 整合、處理網路與上傳檔案、推送至 Docker Hub，並在本機模擬 512MB 記憶體限制。

【學習目標】
- 依「免費、免綁卡、可執行 Docker」條件評估雲端平台
- 以方式 A（GitHub + Dockerfile）將 SSDS 部署至 Render
- 以方式 B（Docker Hub Image + GitHub Actions + Deploy Hook）建立自動化部署
- 排除部署時常見的 build、啟動與連線問題
-->

---
layout: default
---

# Outline

- **平台調查**
  - 2026 年 10 月「免費 + 免綁卡 + 可執行 Docker」的平台
- **部署架構與事前準備**
- **方式 A：從 GitHub 讀取 Dockerfile 部署**（Render）
- **方式 B：部署 Docker Hub 上的 Image**（Render）+ GitHub Actions
- **疑難排解、備案平台與實作練習**

<!--
【帶讀大綱】
本章分為五個部分：
1. 平台調查：免費雲端平台近年變動很大，許多過去常被推薦的平台已取消免費方案或要求綁卡，以 2026 年 10 月的資料重新整理。
2. 部署架構：SSDS 在雲端的架構與部署前的準備項目。
3. 方式 A：由 Render 讀取第四章的 Dockerfile 自行建置。
4. 方式 B：由 Render 拉取第八章推送至 Docker Hub 的 Image，並以 GitHub Actions 實現 push 即自動部署。
5. 疑難排解與備案平台，以及九章課程回顧。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 平台調查

<!--
【段落轉換】
第一部分依條件評估雲端平台。
-->

---

# 平台選擇條件

| 條件 | 原因 |
| --- | --- |
| **免費** | 課堂專案與展示用途，不應產生費用 |
| **免綁信用卡** | 部分學生沒有信用卡；綁卡也有超額扣款的風險 |
| **可執行 Docker** | 支援部署 Dockerfile（由 Git 建置）或 Registry 上的 Image，至少一種 |
| **記憶體 ≥ 512MB** | Spring Boot 4 + 多模組專案，256MB 無法執行 |
| **可連線外部 PostgreSQL（IPv4）** | 資料庫位於 Supabase，平台須能連線 pooler 的 6543 port |
| **提供 https 網址** | 瀏覽器與手機可直接開啟，不需自行處理憑證 |

<!--
【重點解說】
- 前三項為基本需求：免費、免綁卡、可執行 Docker。
- 第四項由 SSDS 的特性決定：Spring Boot 4 加上 Hibernate、POI、ICU4J，第八章在本機模擬確認 512MB 為下限，256MB 的方案直接排除。
- 第五項見第六章：資料庫位於 Supabase，平台的對外連線須能到達 pooler；部分平台的試用帳號會限制對外網路。
- 第六項：雲端平台幾乎都會自動提供 https 網址。
-->

---
zoom: 0.76
---

# 2026 年 10 月平台調查結果

| 平台 | 免綁卡 | Image | Dockerfile | 免費資源 | 休眠 | 結論 |
| --- | :---: | :---: | :---: | --- | --- | --- |
| **Render** | ✅ | ✅ | ✅ | 512MB / 0.1 CPU、每月 750 小時 | 閒置 15 分鐘休眠；SSDS 喚醒實測約 10 分鐘 | **主要選擇**（常駐網址） |
| **Railway** | ✅（試用） | ✅ | ✅ | 試用 30 天 $5 額度；之後每月 $1 額度；每服務 0.5GB / 1 vCPU | 可選 | 短期展示備案 |
| Back4App Containers | ✅ | ✅ | ✅ | 256MB / 0.25 CPU | 有限制 | 僅足以執行 `ssds-web` |
| Koyeb | ❌ 2026/2 起須綁卡 | ✅ | ✅ | 512MB | 1 小時 | 排除 |
| Hugging Face Spaces | — | — | ❌ | Docker Space 自 2026 年中起須付費方案 | — | 排除 |
| Fly.io | ❌ | ✅ | ✅ | 僅 7 天試用 | — | 排除 |
| Cloud Run / Azure / AWS | ❌ | ✅ | ✅ | 免費額度充足 | 依請求計費 | 須綁卡，排除 |

<div class="text-xs text-gray-500 mt-2">資料來源：各平台官方文件與定價頁、snapdeploy.dev〈State of Free Hosting〉（2026-09-28 查核）。免費方案變動頻繁，部署前請至官網確認。</div>

<!--
【重點解說】
- Render：免費 web service 不需綁卡，支援由 Git 讀取 Dockerfile，也支援直接部署 Registry 上的 Image。512MB 記憶體、0.1 CPU，每個工作區每月 750 小時。閒置 15 分鐘會休眠，下次連線需等待喚醒。本章以 Render 為主。
- Railway：註冊不需綁卡，提供 30 天、5 美元的試用額度；之後轉為 Free plan，每月 1 美元額度。每個服務 0.5GB 記憶體、1 vCPU，CPU 為 Render 的 10 倍，冷啟動快很多；但每月 1 美元額度不足以讓 Spring Boot 長期常駐，適合短期展示。試用帳號須完成 GitHub 驗證，否則對外網路受限，無法連線 Supabase。
- Back4App Containers：免綁卡，但只有 256MB，Spring Boot 不足，可用於執行 nginx 前端。

排除名單（網路舊教學常推薦）：
- Koyeb：2026 年 2 月起新帳號須綁卡，並有 29 美元預授權。
- Hugging Face Spaces：過去免費帳號即可建立 Docker Space（16GB 記憶體），自 2026 年中起須付費方案，免費帳號僅剩靜態網頁。
- Fly.io：須綁卡，且僅剩 7 天試用。
- Google Cloud Run、Azure、AWS：免費額度充足，但一律須綁信用卡建立帳單帳戶。

【易錯點提醒 ⚠️】
免費方案是變動最快的資訊，本表為 2026 年 9 月底查核，部署前請至官網確認。
-->

---

# 選擇 Render 的原因

| 優點 | 說明 |
| --- | --- |
| 支援兩種部署方式 | 「Git repo + Dockerfile」與「Existing Image（Docker Hub）」，分別對應第 4 章與第 8 章 |
| 不會過期 | 非試用額度，每月 750 小時免費時數，休眠期間不計時 |
| 自動 https | `https://<服務名稱>.onrender.com` |
| 新加坡區域 | 鄰近台灣，也鄰近 Supabase 的 `ap-south-1`（孟買） |
| Logs / Events 介面 | 檢視 build log、啟動 log、記憶體超用通知，相當於雲端版的 `docker logs` |

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <b>免費方案的限制：</b>0.1 CPU 使 SSDS 冷啟動<b>約 10 分鐘</b>（本機模擬實測）；閒置 15 分鐘即休眠；<b>沒有持久化磁碟</b>（上傳的圖片在重新部署或休眠後消失）；不適用於正式營運。展示前請先開啟網址喚醒服務。
</div>

<!--
【重點解說】
選擇 Render 的理由：支援兩種部署方式、不會過期、有新加坡區域、介面清楚。

【重點提醒】
免費方案的限制：
1. 0.1 CPU 非常有限。以 `docker run --cpus 0.1 -m 512m` 在本機模擬 Render 免費規格：SSDS 不限 CPU 時 31 秒啟動，0.1 CPU 時接近 600 秒（10 分鐘）。Render 的實際 CPU 分配可能較本機模擬寬鬆，但應以 10 分鐘預估。
2. 閒置 15 分鐘即休眠，展示前 5 分鐘先開啟網址喚醒服務。
3. 第七章預告過：免費方案沒有持久化磁碟，每次重新部署或休眠後喚醒，容器皆為全新狀態，上傳的商品圖片會消失。現場上傳、現場展示沒有問題；需長期保存時應改用物件儲存。
4. Render 官方文件亦說明免費方案不應用於正式服務。
-->

---
zoom: 0.9
---

# 冷啟動實測：0.1 CPU 的影響

以 `docker run --cpus <N> -m 512m` 在本機模擬，量測 SSDS 從啟動到 `Started SsdsApplication` 的時間：

| CPU | 啟動時間 | 啟動後記憶體 | 備註 |
| --- | --- | --- | --- |
| 不限制 | 31 秒 | — | 一般筆電 |
| 0.5 | 115 秒 | 約 330MB | 第 8 章的模擬設定 |
| **0.1（Render Free）** | **約 600 秒** | 約 300MB | 啟動後每個請求約 1 秒 |
| 0.1 + CDS（進階，見附錄） | 約 394 秒 | 約 285MB | 節省約 35% |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>對策：</b>① 展示前 15 分鐘先開啟後端 health 網址喚醒服務 ② 必須設定 Health Check Path，Render 部署最多等待 15 分鐘 ③ 重要展示改用 Railway 試用（1 vCPU，見備案）④ 需要更快可加入 CDS（附錄）。
</div>

<!--
【核心說明】
Spring Boot 啟動時須載入數萬個類別、建立上百個 bean、初始化 Hibernate，這些都是 CPU 密集的工作。SSDS 模組多，在 0.1 CPU 下即需約 10 分鐘。lazy initialization 幾乎沒有改善；CDS（Class Data Sharing）可節省約三分之一，見附錄。

【重點提醒】
Render 的 0.1 CPU 實際上可能比 docker 的硬性限制寬鬆，部署後請以 log 中的實際數字為準。

【業界實務】
Render 閒置 15 分鐘即休眠，下一位使用者連線時須等待重新啟動，最長約 10 分鐘。因此 Render 適合放置「隨時可開啟查看」的網址；重要展示應提早喚醒，或另以 Railway 試用額度部署一份 CPU 較充足的備用服務。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 部署架構與事前準備

<!--
【段落轉換】
第二部分說明 SSDS 在雲端的架構，以及部署前須準備的項目。
-->

---
zoom: 0.83
---

# SSDS 的雲端架構

```
                       https://ssds-web-xxxx.onrender.com
使用者瀏覽器 ──────────────────────────────▶ Render Web Service：ssds-web（nginx :80）
                                                │  location /api/ → proxy_pass ${API_URL}
                                                ▼  https://ssds-api-xxxx.onrender.com
                                              Render Web Service：ssds-api（Spring Boot :8080）
                                                │  SSDS_DB_HOST=aws-0-ap-south-1.pooler.supabase.com:6543
                                                ▼
                                              Supabase PostgreSQL（不變）
```

| 本機（Compose） | 雲端（Render） |
| --- | --- |
| `API_URL=http://api:8080`（服務名稱，內部網路） | `API_URL=https://ssds-api-xxxx.onrender.com`（公開網址） |
| `env_file: .env` | Render 的 **Environment Variables** 頁面 |
| `ports: "8000:80"` | 平台自動提供 https 網址，以 `PORT` 指定容器監聽的 port |
| `healthcheck:` | Render 的 **Health Check Path** |

<!--
【重點解說】
此架構與第六章的本機架構幾乎相同，差別僅在各段連線的網址。雲端上有兩個 Render Web Service，各自執行一個 Image。使用者連線 ssds-web，由 nginx 將 /api 開頭的請求轉送至 ssds-api。

【核心說明】
最大的差異在 API_URL：本機 Compose 中兩個容器位於同一內部網路，以服務名稱 api 即可連線；Render 免費方案不支援服務間的私有網路，因此 nginx 須經由 ssds-api 的公開網址連線。公開網址為 https，這也是第四章 nginx 設定檔加入 proxy_ssl_server_name on 的原因。

【業界實務】
本機學到的每一個 Docker 概念，在雲端平台上都有對應的設定欄位，只是由 YAML 改為網頁表單。熟悉 Docker 之後，更換任何雲端平台都只是找到對應的欄位。

【易錯點提醒 ⚠️】
瀏覽器不直接呼叫 ssds-api 網址的原因是 CORS。後端 CORS 白名單只有 localhost:4200；透過 nginx 反向代理，瀏覽器只面對 ssds-web 一個網域，不需修改後端程式碼。
-->

---
zoom: 0.82
---

# 部署前檢查清單

| # | 項目 | 對應章節 |
| --- | --- | --- |
| 1 | 後端 repo 根目錄有 `Dockerfile`、`.dockerignore`；`ssds-api/build.gradle` 已加入 actuator | Ch4 |
| 2 | 前端 repo 根目錄有 `Dockerfile`、`.dockerignore`、`nginx/default.conf.template` | Ch4 |
| 3 | 本機 `docker compose up` 可由 `http://localhost:8000` 登入並顯示資料 | Ch5、Ch6 |
| 4 | `.env` **未**進入 Git（`git ls-files | grep .env` 只顯示 `.env.example`） | Ch8 |
| 5 | Dockerfile 已設定 `JAVA_TOOL_OPTIONS`，本機 512MB 限制下可達 healthy | Ch8 |
| 6 | 已準備新的 `SSDS_JWT_SECRET` | Ch8 |
| 7 | 兩個 repo 皆已 push 至 GitHub（方式 A）／兩個 Image 已推送至 Docker Hub 且為 **amd64**（方式 B） | Ch8 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>原則：</b>本機 <code>docker compose up</code> 無法執行的，雲端也一定無法執行；先在本機修正，再部署至雲端。
</div>

<!--
【操作提示】
請逐項確認後再繼續。每一項皆對應前面章節的內容，多數已在練習中完成。

【易錯點提醒 ⚠️】
第 4 項特別重要：方式 A 由 Render 讀取 GitHub repo，若 .env 曾被 commit，Supabase 密碼即已公開在 GitHub 上。

【重點提醒】
雲端除錯比本機困難：log 須至網頁查看，每次重新部署須等待數分鐘。能在本機重現與修正的問題，不應帶到雲端。
-->

---
zoom: 0.78
---

# 後端環境變數

| 變數 | 值 | 說明 |
| --- | --- | --- |
| `PORT` | `8080` | 指定容器監聽的 port（Render 預設為 10000） |
| `SSDS_DB_HOST` / `SSDS_DB_PORT` | `aws-0-ap-south-1.pooler.supabase.com` / `6543` | **pooler**（IPv4），不使用 direct connection |
| `SSDS_DB_NAME` / `SSDS_DB_USER` / `SSDS_DB_PASSWORD` | `postgres` / `ssds_app.<project-ref>` / 密碼 | 與本機 `.env` 相同 |
| `SSDS_JWT_SECRET` | 新產生的亂數 | **不可**沿用預設值 |
| `MISTRAL_API_KEY` | 個人金鑰 | 需要 AI 功能時才設定 |
| 五個排程開關（下方） | `false` | 節省記憶體與 Apify / Mistral 額度，避免多人重複寫入共用資料庫 |

```plaintext
SSDS_INGEST_INSTAGRAM_ENABLED  SSDS_INGEST_GOOGLE_TRENDS_ENABLED  AI_TREND_SCHEDULE_ENABLED
AI_SOURCING_TIME_GAP_SCHEDULE_ENABLED  AI_CALIBRATION_SCHEDULE_ENABLED
```

<div class="mt-4 p-3 bg-red-50 border-l-4 border-red-400 text-gray-700 text-sm text-left">
⚠️ <b>不可設定</b> <code>SSDS_FLYWAY_ENABLED</code> 與 <code>SSDS_MIGRATION_DB_*</code>：共用資料庫的 migration 只由負責的組員在本機執行。<code>SPRING_PROFILES_ACTIVE=prod</code> 與 <code>JAVA_TOOL_OPTIONS</code> 已寫在 Dockerfile 中。
</div>

<!--
【帶讀關鍵行】
- `PORT=8080`：Render 預設容器監聽 10000，Spring Boot 監聽 8080。設定 PORT 即告知 Render 將流量轉送至 8080，相當於本機 -p 的右半部。
- 資料庫設定與本機相同，必須使用 pooler 網址：Render 對外連線只有 IPv4，Supabase 的 direct connection 只有 IPv6（見第六章練習 2）。
- `SSDS_JWT_SECRET`：使用第八章產生的新亂數。

【重點解說】
建議關閉排程，原因有三：
1. 排程在背景執行熱度採集與 AI 分析，佔用記憶體與 CPU，0.1 CPU 的機器無法負荷。
2. 熱度採集呼叫 Apify、AI 呼叫 Mistral，皆依用量計費，全班各自部署會很快耗盡額度。
3. 全組共用一個 Supabase，每位組員的雲端服務若都執行相同排程，會重複寫入。
組上若需要正式執行排程的環境，應指定一人負責，其餘人員關閉。Apify token 若不需要則不設定，程式會自動略過該資料來源。

【易錯點提醒 ⚠️】
Flyway 相關設定不可設定。專案的 .env.example 已註明 migration 只能由負責人員在本機對共用資料庫執行。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 方式 A：從 GitHub 讀取 Dockerfile 部署

<!--
【段落轉換】
方式 A：由 Render 連線 GitHub repo，以第四章的 Dockerfile 在 Render 的機器上建置。之後 push 至 main，Render 會自動重新建置與部署，不需自行建置 Image。
-->

---

# 方式 A 流程總覽

```
git push ──▶ GitHub repo ──(Render 偵測 push)──▶ Render build（依 Dockerfile）──▶ 部署新容器
```

| 步驟 | 動作 |
| --- | --- |
| 1 | 以 GitHub 帳號註冊 Render（免綁卡），授權 Render 讀取兩個 repo |
| 2 | 建立 `ssds-api` Web Service：選擇後端 repo → Language: **Docker** → Instance Type: **Free** |
| 3 | 設定環境變數與 Health Check Path → Deploy，等待建置與啟動完成 |
| 4 | 記錄後端網址 `https://ssds-api-xxxx.onrender.com`，呼叫 `/api/v1/actuator/health` 確認為 UP |
| 5 | 建立 `ssds-web` Web Service：選擇前端 repo → `API_URL` 設為第 4 步的網址 |
| 6 | 開啟前端網址並登入，驗收完整流程 |

<!--
【重點提醒】
順序很重要：須先部署後端並取得後端網址，才能設定前端的 API_URL。此與第六章「nginx 啟動時須能解析 proxy_pass 主機名稱」的道理相同：前端依賴後端。
-->

---

# A-1　註冊 Render 並連結 GitHub

1. 開啟 `https://render.com` → **Get Started** → 選擇 **GitHub** 登入
2. 依畫面建立 Workspace（選擇 **Hobby** 免費方案，不會要求信用卡）
3. Dashboard 右上角 **+ New** → **Web Service**
4. Source Code 選擇 **Git Provider** → **GitHub** → 於 GitHub 授權頁選擇 **Only select repositories**，勾選：
   - `ai-products-selection-backend`
   - `ai-products-selection-frontend`

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>組織的 repo：</b>repo 位於小組的 GitHub Organization 時，須由 Organization 管理員同意 Render 的存取；或 fork 至個人帳號後再部署。
</div>

<!--
【操作提示】
- 以 GitHub 帳號登入最方便，後續連結 repo 時不需再次授權。
- 建立 Workspace 時選擇 Hobby（個人免費方案），全程不會要求信用卡；若畫面要求付款資訊，表示選到付費方案，請返回選擇免費選項。
- GitHub 授權頁選擇 Only select repositories，只開放這兩個 repo 給 Render，符合最小權限原則。
-->

---
zoom: 0.93
---

# A-2　建立 ssds-api（基本設定）

| 欄位 | 填寫 |
| --- | --- |
| Repository | `ai-products-selection-backend` |
| Name | `ssds-api`（成為網址的一部分；名稱已被使用時 Render 會加上隨機字串） |
| Language | **Docker**（偵測到根目錄的 Dockerfile 時自動選取） |
| Branch | `main` |
| Region | **Singapore (Southeast Asia)** |
| Root Directory | 留空（Dockerfile 位於 repo 根目錄） |
| Instance Type | **Free** — 512 MB / 0.1 CPU |

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ Language 顯示的若不是 Docker（例如 Java 或 Node），表示 Render 未找到 Dockerfile。請確認檔名為 <code>Dockerfile</code>（大寫 D、無副檔名），且已 push 至 <code>main</code>。
</div>

<!--
【帶讀關鍵行】
- Name：成為網址 ssds-api.onrender.com 的一部分，全 Render 唯一。全班皆命名為 ssds-api 時，後建立者會自動加上隨機字串（例如 ssds-api-a1b2.onrender.com），以實際取得的網址為準。
- Language：選擇 Docker 是方式 A 的關鍵，Render 會以專案的 Dockerfile 建置，而非使用其 Java buildpack。
- Region：選擇 Singapore，鄰近台灣使用者，也鄰近 Supabase 的孟買機房，資料庫查詢延遲較低。
- Instance Type：必須選擇 Free。選到付費方案時，未綁卡將無法建立服務。
-->

---
zoom: 0.97
---

# A-3　建立 ssds-api（環境變數與進階設定）

**Environment Variables**：依「後端環境變數」表格逐一新增，或以 **Add from .env** 一次貼上

**Advanced** 展開後：

| 欄位 | 填寫 |
| --- | --- |
| Health Check Path | `/api/v1/actuator/health` |
| Dockerfile Path | `./Dockerfile`（預設） |
| Docker Build Context Directory | `.`（預設） |
| Auto-Deploy | **On Commit**（push 至 main 時自動重新部署） |

最後按 **Deploy Web Service**

<div class="mt-4 p-3 bg-red-50 border-l-4 border-red-400 text-gray-700 text-sm text-left">
⚠️ 以 <b>Add from .env</b> 貼上本機 <code>.env</code> 時，須<b>刪除</b> <code>SSDS_FLYWAY_ENABLED</code>、<code>SSDS_MIGRATION_DB_*</code>，並補上 <code>PORT=8080</code>、新的 <code>SSDS_JWT_SECRET</code> 與排程開關。
</div>

<!--
【核心說明】
環境變數加密保存於 Render，不會出現在 GitHub，也不會進入 Image，與本機以 --env-file 注入的原則相同：機密值只在執行時提供。

【帶讀關鍵行】
- Health Check Path：/api/v1/actuator/health，與第五章 Compose 的 healthcheck 相同。Render 以此判斷新版本是否確實啟動完成。
- Dockerfile Path、Build Context：使用預設值，Dockerfile 位於 repo 根目錄，等同第四章的 `docker build .`。
- Auto-Deploy：開啟後，push 至 main 即自動重新建置與部署。

【易錯點提醒 ⚠️】
Health Check Path 遺漏 /api/v1 是最常見的錯誤，Render 會持續判定服務不健康。
-->

---

# A-4　檢視建置與啟動 log

部署後於服務頁面的 **Logs** 依序可見：

```
==> Cloning from https://github.com/<you>/ai-products-selection-backend
==> Building with Dockerfile...
#12 [build 9/11] RUN chmod +x gradlew && ./gradlew --no-daemon :ssds-api:dependencies
#14 [build 11/11] RUN ./gradlew --no-daemon :ssds-api:bootJar -x test
==> Pushing image to registry...
==> Deploying...
Picked up JAVA_TOOL_OPTIONS: -XX:MaxRAMPercentage=60 -XX:+UseSerialGC ...
  .   ____          _            __ _ _
 :: Spring Boot ::                (v4.1.0)
HikariPool-1 - Start completed.
Tomcat started on port 8080 (http) with context path '/api/v1'
Started SsdsApplication in 601.1 seconds
==> Your service is live 🎉
```

<!--
【帶讀關鍵行】
- 前半段為建置：Render clone repo 後依 Dockerfile 逐層建置，輸出與本機 docker build 幾乎相同，首次約需 5 至 10 分鐘。
- `Picked up JAVA_TOOL_OPTIONS`：第八章的記憶體參數已生效。
- `HikariPool-1 - Start completed`：已連線 Supabase。
- `Tomcat started on port 8080 ... context path '/api/v1'` 與 `Started SsdsApplication`：服務啟動完成。

【易錯點提醒 ⚠️】
本機約 30 秒的啟動，在 0.1 CPU 下可能需要 10 分鐘。Render 部署時最多等待健康檢查 15 分鐘，時間足夠；請耐心等待，不要重新部署，否則只會從頭再等待一次。

【預期結果】
出現 Your service is live 即部署成功。
-->

---

# A-5　驗證後端

```bash
# 將 xxxx 替換為實際取得的網址
curl https://ssds-api-xxxx.onrender.com/api/v1/actuator/health
# {"status":"UP"}
```

亦可直接以瀏覽器開啟：

- 健康檢查：`https://ssds-api-xxxx.onrender.com/api/v1/actuator/health`
- Swagger UI：`https://ssds-api-xxxx.onrender.com/api/v1/swagger-ui.html`

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 記錄此網址（<b>不含結尾斜線</b>），下一步設定前端 <code>API_URL</code> 時使用。
</div>

<!--
【重點提醒】
部署成功後先驗證後端本身，再進行前端。此為第六章的除錯原則：逐層確認。

【核心說明】
health 回傳 UP 表示 Spring Boot 已啟動，且可連線 Supabase（health 會檢查資料庫連線）。回傳 DOWN 時，請查看 Logs 中的 HikariPool 錯誤訊息。Swagger UI 可直接測試 API。
-->

---

# A-6　建立 ssds-web

再次按 **+ New** → **Web Service**，選擇 `ai-products-selection-frontend`：

| 欄位 | 填寫 |
| --- | --- |
| Name | `ssds-web` |
| Language / Region / Instance Type | **Docker** / **Singapore** / **Free** |
| Environment Variables | `PORT` = `80`<br>`API_URL` = `https://ssds-api-xxxx.onrender.com`（**不加結尾斜線**） |
| Health Check Path | `/` |

部署完成後開啟 `https://ssds-web-xxxx.onrender.com` → 登入 → 顯示商品資料即**部署完成**。

<!--
【帶讀關鍵行】
- `PORT=80`：nginx 監聽 80。
- `API_URL`：上一步記錄的後端網址。容器啟動時，nginx 官方 Image 以 envsubst 將設定檔中的 ${API_URL} 替換為此值，即第四章 .template 檔的作用。同一個 Image，本機 Compose 設為 http://api:8080，雲端設為 https 公開網址，不需修改程式碼。

【補充】
前端同樣在 Render 上建置：npm ci、安裝 JRE、generate:api、ng build，約 5 分鐘。

【預期結果】
開啟前端網址並登入，顯示資料即表示整條路徑正常：手機瀏覽器 → Render 上的 nginx → Render 上的 Spring Boot → Supabase。

【易錯點提醒 ⚠️】
兩個服務皆在休眠時，首次開啟會非常慢：前端先喚醒，第一個 API 請求再喚醒後端。展示前請先開啟後端的 health 網址，再開啟前端。
-->

---

# A-7　後續更新

```bash
# 在後端 repo 修改程式後
git add . && git commit -m "feat: 新增選品報表匯出"
git push origin main
# → Render 偵測到 push，自動重新建置並部署 ssds-api
```

| 操作 | Render 上的做法 |
| --- | --- |
| 檢視部署歷史、回復上一版 | 服務頁面 → **Events** → 選擇舊的部署 → **Rollback** |
| 修改環境變數 | **Environment** → 修改 → 儲存後自動重新部署 |
| 手動重新部署 | 右上角 **Manual Deploy** → **Deploy latest commit** |
| 暫停服務 | **Settings** → **Suspend Web Service** |

<!--
【重點解說】
方式 A 的最大優點是更新簡便：git push 後由 Render 自動處理。Events 頁面顯示每次部署由哪個 commit 觸發，發生問題時可直接 Rollback，即第八章所述「版本可追溯、可快速回復」。

【易錯點提醒 ⚠️】
每次重新部署容器皆為全新狀態，上傳的圖片會消失，此為免費方案沒有持久化磁碟的限制（第七章）。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 方式 B：部署 Docker Hub 上的 Image

<!--
【段落轉換】
方式 B：自行建置 Image 並推送至 Docker Hub，Render 只負責拉取與執行。

【重點解說】
適用情境：
- repo 為私有，或位於 Organization 下不便授權給 Render
- 希望本機測試過的 Image 與雲端執行的 Image 完全相同
- 希望以 GitHub Actions 自行控制建置流程
-->

---

# 方式 B 流程總覽

```
docker build（或 GitHub Actions）──▶ docker push ──▶ Docker Hub ──▶ Render 拉取 Image ──▶ 部署
```

| 步驟 | 動作 |
| --- | --- |
| 1 | 確認 Docker Hub 上已有 `myaccount/ssds-api:1.0.0`、`myaccount/ssds-web:1.0.0`，且為 **linux/amd64** |
| 2 | Render **+ New** → **Web Service** → Source Code 選擇 **Existing Image** |
| 3 | Image URL 填入 `docker.io/myaccount/ssds-api:1.0.0`（私有 repo 須加入 Credential） |
| 4 | Name / Region / **Free** / 環境變數 / Health Check Path — 與方式 A 相同 |
| 5 | 對 `ssds-web` 重複上述步驟，`API_URL` 填入後端網址 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 方式 A 與 B 的差別只在「Image 的來源」；<b>環境變數、Port、Health Check 的設定完全相同</b>，此即 Image 的可攜性。
</div>

<!--
【核心說明】
方式 B 與方式 A 的差別僅在第 2、3 步：Source Code 選擇 Existing Image 並填入 Docker Hub 上的 Image 網址。其餘設定完全相同，這正是 Docker 的核心價值：Image 是標準化的封裝，無論由 Render 建置或由我們推送，執行結果都相同。
-->

---

# B-1　確認 Image 的平台架構

```bash
docker image inspect myaccount/ssds-api:1.0.0 --format '{{.Os}}/{{.Architecture}}'
# linux/amd64   ← 必須為此值
```

若為 `linux/arm64`（M 系列 Mac 預設），重新建置並推送：

```bash
docker build --platform linux/amd64 -t myaccount/ssds-api:1.0.1 \
  ./ai-products-selection-backend
docker push myaccount/ssds-api:1.0.1
```

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ 架構錯誤的症狀：Render Logs 出現 <code>exec format error</code>，或部署持續失敗且沒有任何 Spring Boot log。
</div>

<!--
【重點解說】
CPU 架構不符是方式 B 最常見、也最不易理解的失敗原因。Windows 與 Intel Mac 一定為 amd64；M 系列 Mac 建置時未加 --platform 即為 arm64。

【重點提醒】
重新建置時版本號 +1，不要覆寫同一個 tag。第八章說明過，tag 是可變的，覆寫會造成版本混淆。
-->

---
zoom: 0.93
---

# B-2　在 Render 建立 Image 服務

**+ New** → **Web Service** → Source Code 選擇 **Existing Image**：

| 欄位 | 填寫 |
| --- | --- |
| Image URL | `docker.io/myaccount/ssds-api:1.0.0` |
| Credential | Public repo：不需填寫<br>Private repo：**Add credential** → Username = Docker Hub 帳號、Token = Docker Hub **Read-only** Access Token |
| Name / Region / Instance Type | `ssds-api` / Singapore / **Free** |
| Environment Variables | 同方式 A（`PORT=8080`、`SSDS_DB_*`、`SSDS_JWT_SECRET`…） |
| Health Check Path | `/api/v1/actuator/health` |

`ssds-web` 做法相同：Image URL 為 `docker.io/myaccount/ssds-web:1.0.0`，環境變數 `PORT=80`、`API_URL=https://ssds-api-xxxx.onrender.com`

<!--
【帶讀關鍵行】
- Image URL 格式為 docker.io/帳號/名稱:tag。docker.io 是 Docker Hub 的 registry 位址，docker pull 時可省略，但在平台上建議寫完整。
- Credential：public repository 不需填寫。private repository 須提供憑證；建議於 Docker Hub 建立「唯讀」Access Token 給 Render，不提供具寫入權限的 token，更不提供帳號密碼，符合最小權限原則。
-->

---

# B-3　更新版本：手動與 Deploy Hook

Image 服務**不會自動偵測** Docker Hub 上的新版本，須自行觸發：

| 做法 | 操作 |
| --- | --- |
| 更換 tag | **Settings** → Image URL 改為 `...:1.0.1` → 儲存並部署 |
| 同一 tag 重新拉取 | **Manual Deploy** → **Deploy latest reference** |
| Deploy Hook | **Settings** → 複製 **Deploy Hook** 網址，發送 HTTP 請求即觸發重新部署 |

```bash
# Deploy Hook：以 imgURL 參數指定此次部署的 tag
curl -fsS -X POST -G "$RENDER_DEPLOY_HOOK_API" \
  --data-urlencode "imgURL=docker.io/myaccount/ssds-api:1.0.1"
```

<div class="mt-4 p-3 bg-red-50 border-l-4 border-red-400 text-gray-700 text-sm text-left">
⚠️ Deploy Hook 網址本身即為密碼（包含 key），取得者皆可觸發部署；只能存放於 GitHub Secrets，不可貼在 README 或群組中。
</div>

<!--
【重點解說】
- 更換 tag：最明確，建議使用。
- Deploy latest reference：同一 tag 重新推送後，讓 Render 重新拉取。
- Deploy Hook：供自動化使用，下一頁的 GitHub Actions 即使用此方式。

【帶讀關鍵行】
Deploy Hook 可帶入 imgURL 參數指定部署的 tag。--data-urlencode 將冒號與斜線編碼；-G 將參數置於網址；-X POST 以 POST 方法送出。
-->

---
zoom: 0.71
---

# B-4　GitHub Actions：push 即自動建置、推送與部署

```yaml
# ai-products-selection-backend/.github/workflows/deploy.yml
name: build-push-deploy
on:
  push:
    branches: [main]

jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: docker/setup-buildx-action@v4
      - uses: docker/login-action@v4
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - uses: docker/build-push-action@v7
        with:
          context: .
          platforms: linux/amd64
          push: true
          tags: |
            ${{ secrets.DOCKERHUB_USERNAME }}/ssds-api:latest
            ${{ secrets.DOCKERHUB_USERNAME }}/ssds-api:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
      - name: Trigger Render deploy
        run: >
          curl -fsS -X POST -G "${{ secrets.RENDER_DEPLOY_HOOK }}"
          --data-urlencode "imgURL=docker.io/${{ secrets.DOCKERHUB_USERNAME }}/ssds-api:${{ github.sha }}"
```

<!--
【核心說明】
此 workflow 即第八章 CI/CD 概念的實作。

【帶讀關鍵行】
- `on.push.branches: [main]`：push 至 main 時觸發。
- `checkout`：取得程式碼。`setup-buildx`：啟用 BuildKit 的進階功能（快取）。`login-action`：以 GitHub Secrets 中的帳號與 Access Token 登入 Docker Hub。
- `build-push-action`：即 docker build 加 docker push。
  - `context: .`：對應 docker build 最後的 `.`。
  - `platforms: linux/amd64`：GitHub 的 runner 本身即為 amd64，明確寫出較清楚。
  - `tags`：latest 便於閱讀；github.sha 為此次 commit 的完整 hash，精確對應程式碼版本，即第八章 tag 策略的實作。
  - `cache-from` / `cache-to: type=gha`：將 layer cache 存放於 GitHub Actions 快取。第四章排定的相依套件快取順序在此發揮作用：只修改 Java 時，相依套件層直接命中快取，建置時間大幅縮短。
- 最後一步呼叫 Render 的 Deploy Hook，以 imgURL 指定部署剛推送的 commit hash 版本。

【重點提醒】
- 本頁使用 2026 年 10 月的 action 主版本（checkout v6、setup-buildx v4、login v4、build-push v7），這些版本以 Node 24 執行。舊教學中的 v3 / v4 / v5 / v6 仍可運作，但已有更新版本。
- 前端 repo 放置相同檔案，將 ssds-api 改為 ssds-web、Deploy Hook 改為前端服務的即可。
- GitHub Actions 對 public repo 免費；private repo 每月亦有免費分鐘數，課堂專案足夠使用。
-->

---

# B-5　設定 GitHub Secrets

GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**：

| Secret 名稱 | 值 | 取得位置 |
| --- | --- | --- |
| `DOCKERHUB_USERNAME` | `myaccount` | Docker Hub 帳號 |
| `DOCKERHUB_TOKEN` | `dckr_pat_...` | Docker Hub → Account settings → **Personal access tokens**（Read & Write） |
| `RENDER_DEPLOY_HOOK` | `https://api.render.com/deploy/srv-...?key=...` | Render 服務 → **Settings** → **Deploy Hook** |

設定完成後 push 一個 commit → 於 repo 的 **Actions** 分頁檢視執行過程 → 成功後至 Render **Events** 確認有新的部署

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 Secrets 儲存後<b>無法再檢視其值</b>，workflow log 中也會自動遮蔽為 <code>***</code>，此即「機密值只在執行時提供」在 CI 上的實作。
</div>

<!--
【帶讀關鍵行】
- DOCKERHUB_USERNAME：Docker Hub 帳號。
- DOCKERHUB_TOKEN：Docker Hub 的 Personal Access Token，須具寫入權限以進行 push；不使用帳號密碼。
- RENDER_DEPLOY_HOOK：Render 服務設定頁的 Deploy Hook 網址。

【預期結果】
首次建置沒有快取，約需 5 至 10 分鐘；之後只修改 Java 會快很多。成功後 Render 的 Events 頁面出現新部署，Image 欄位為該次 commit hash。至此完成完整的 CI/CD：撰寫程式 → push → 自動建置 → 自動推送至 Docker Hub → 自動部署至雲端。
-->

---
zoom: 0.96
---

# 方式 A vs 方式 B

| 比較 | 方式 A：Git + Dockerfile | 方式 B：Existing Image |
| --- | --- | --- |
| 建置者 | Render | 自己 / GitHub Actions |
| 自動更新 | push 即自動 | 須 Deploy Hook 或手動 |
| 設定難度 | ⭐ 最簡單 | ⭐⭐ 多了 Docker Hub、Secrets |
| 本機與雲端一致性 | 同一份 Dockerfile，但建置環境不同 | **同一個 Image，完全一致** |
| CPU 架構問題 | 不會發生（Render 自行建置） | 須確認 amd64 |
| 私有 / Org repo | 須授權 Render 讀取 | 不需讓 Render 讀取程式碼 |
| 更換平台 | 須重新設定 Git 連結 | 任何能執行 Image 的平台皆可直接使用 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>建議：</b>首次部署使用<b>方式 A</b>，最快上線；熟悉後改用<b>方式 B + GitHub Actions</b>，此為業界最常見的做法。
</div>

<!--
【重點解說】
- 方式 A 最簡單，適合首次上線或快速展示。
- 方式 B 步驟較多，但有兩項優點：雲端執行的與本機測試的是同一個 Image，第八章在 512MB 限制下測試的結果，在雲端完全相同；Image 位於 Docker Hub，可直接用於任何平台（Railway、企業的 Kubernetes、三大雲），即容器化的可攜性。

【業界實務】
業界最常見的模式即方式 B：CI 負責建置、Registry 負責存放、平台只負責執行。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 疑難排解與備案平台

<!--
【段落轉換】
本部分整理部署時最常見的錯誤，以及 Render 無法使用時的備案。
-->

---
zoom: 0.87
---

# 部署疑難排解（一）：建置與啟動

| 症狀（Render Logs） | 原因 | 解法 |
| --- | --- | --- |
| `Could not resolve "../../api"` | 前端未執行 `generate:api` | Dockerfile 建置階段：`apk add openjdk21-jre-headless` + `npm run generate:api`（Ch4） |
| `./gradlew: Permission denied` / `bad interpreter: ^M` | 執行權限 / CRLF 換行 | `RUN chmod +x gradlew`；`.gitattributes` 設定 `/gradlew text eol=lf` |
| `exec format error` | 推送了 arm64 Image | 以 `--platform linux/amd64` 重新建置（方式 B） |
| `password authentication failed for user "ssds_app"`（帳號未含 `.<ref>`） | 未設定 `SSDS_DB_*`，使用了預設值 | Render → Environment 補齊 |
| `No open ports detected` / 持續 Deploying | 未設定或設錯 `PORT` | api 設 `PORT=8080`、web 設 `PORT=80` |
| `Ran out of memory (used over 512MB)` / 持續重啟 | JVM 記憶體使用過多 | `JAVA_TOOL_OPTIONS` 的 `MaxRAMPercentage` 調為 50；關閉排程 |
| Health check 持續失敗 | 路徑錯誤 | `/api/v1/actuator/health`（含 context-path） |

<!--
【重點解說】
多數錯誤已在前面章節遇過，此處整理成表格方便查詢。

【重點提醒】
- 記憶體超用：Render 會在 Events 頁面直接顯示 Ran out of memory，處理方式即第八章的調低 MaxRAMPercentage 並關閉不需要的排程。
- Health check：遺漏 /api/v1 為最常見的錯誤。
-->

---
zoom: 0.81
---

# 部署疑難排解（二）：連線

| 症狀 | 原因 | 解法 |
| --- | --- | --- |
| api log：`Network is unreachable` / `UnknownHostException: db.xxx.supabase.co` | 使用了 Supabase direct connection（IPv6） | `SSDS_DB_HOST` 改用 **pooler**（Ch6） |
| api log：`password authentication failed` | 帳號格式或密碼錯誤 | 帳號為 `ssds_app.<project-ref>`；密碼不加引號 |
| 前端 **502 Bad Gateway** | nginx 無法連線後端 | `API_URL` 拼錯，或使用了 `http://` 而非 `https://` |
| 前端 API 全部 **404** | `API_URL` 多了結尾 `/` | 移除結尾斜線（Ch6 proxy_pass 規則） |
| 前端 **504 Gateway Timeout** | 後端仍在冷啟動（0.1 CPU 約 10 分鐘） | 稍後重新整理；展示前 15 分鐘先喚醒後端 |
| 重新整理子頁面出現 404 | 缺少 SPA fallback | nginx `try_files $uri $uri/ /index.html`（Ch4） |
| 上傳的圖片隔天消失 | 免費方案沒有持久化磁碟 | 預期行為（Ch7）；長期保存須改用物件儲存 |

<!--
【重點解說】
此表與第六章練習 2 的除錯表幾乎相同，只是場景移至雲端。

【核心說明】
- 除錯順序：由外而內。瀏覽器 DevTools 查看狀態碼 → ssds-web 的 Logs 檢查 nginx → ssds-api 的 Logs 檢查 Spring Boot。
- 502 與 504 的差別：502 表示 nginx 無法連線後端（網址錯誤）；504 表示已連線但等待逾時（後端冷啟動中）。
- 最後一列並非錯誤，而是免費方案的限制（第七章）。
-->

---
zoom: 0.94
---

# 備案：Railway（短期展示）

Render 無法使用，或需要較多 CPU 進行短期展示時：

| 步驟 | 動作 |
| --- | --- |
| 1 | 至 `https://railway.com` 以 GitHub 登入，**完成 GitHub 帳號驗證**（否則為 Limited Trial，對外網路受限、無法連線 Supabase） |
| 2 | **New Project** → **Deploy from GitHub repo**（偵測 Dockerfile，等同方式 A）或 **Docker Image**（等同方式 B） |
| 3 | 服務 → **Variables**：貼上相同的環境變數（`PORT=8080`、`SSDS_DB_*`…） |
| 4 | **Settings** → **Networking** → **Generate Domain**，Port 填入 `8080` |
| 5 | 前端做法相同，`API_URL` 填入後端的 Railway 網址 |

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ 試用為 <b>30 天或 5 美元額度</b>（先到者為準），之後轉為 Free plan，每月僅 1 美元額度；每個服務 0.5GB / 1 vCPU。Spring Boot 常駐很快會用完額度，適合短期展示，不適合長期放置。
</div>

<!--
【重點解說】
Railway 的流程與 Render 幾乎相同，因為所有平台做的事都一樣：取得 Image（或 Dockerfile）、設定環境變數、指定 port、提供網址。

【易錯點提醒 ⚠️】
第一步的 GitHub 驗證必須完成：未驗證的試用帳號對外網路受限，Spring Boot 無法連線 Supabase。

【業界實務】
Railway 的 CPU 較多（1 vCPU）、沒有強制休眠，展示體驗優於 Render；但記憶體同為 0.5GB，且試用額度用完即無法常駐。建議平時使用 Render，重要展示前一週於 Railway 部署一份備用。

【補充】
Back4App Containers 亦免綁卡，但只有 256MB，可用於放置 ssds-web（nginx 資源需求低），後端仍放 Render。
-->

---
zoom: 0.72
---

# 附錄（進階）：以 CDS 加快冷啟動

將後端 Dockerfile 的**第二階段**替換為以下內容（第一階段不變），實測 0.1 CPU：600 → 394 秒；不限 CPU：31 → 18 秒

```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app \
 && mkdir -p /app/uploads && chown -R app:app /app
COPY --from=build --chown=app:app /src/ssds-api/build/libs/ssds.jar /tmp/ssds.jar
USER app
RUN java -Djarmode=tools -jar /tmp/ssds.jar extract --destination /app/extracted
# training run：只建立 Spring context 即結束；DB 指向 127.0.0.1，建置時不會連線 Supabase
RUN SSDS_DB_HOST=127.0.0.1 SSDS_DB_PASSWORD=dummy \
    SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect \
    SPRING_JPA_PROPERTIES_HIBERNATE_BOOT_ALLOW_JDBC_METADATA_ACCESS=false \
    java -XX:ArchiveClassesAtExit=/app/app.jsa -Dspring.context.exit=onRefresh \
         -jar /app/extracted/ssds.jar
ENV SPRING_PROFILES_ACTIVE=prod \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -Xss512k -XX:TieredStopAtLevel=1"
EXPOSE 8080
ENTRYPOINT ["java", "-XX:SharedArchiveFile=/app/app.jsa", "-jar", "/app/extracted/ssds.jar"]
```

<!--
【核心說明】
Spring Boot 啟動慢的主因之一是載入、解析與驗證數萬個類別。CDS（Class Data Sharing）在 docker build 時先試執行應用程式，將使用到的類別整理為快取檔 app.jsa；實際啟動時直接讀取快取，省去大量 CPU 工作。

【帶讀關鍵行】
1. `java -Djarmode=tools ... extract`：Spring Boot 官方工具，將 fat jar 解開為適合 CDS 的結構。
2. training run：`-Dspring.context.exit=onRefresh` 使 Spring 建立 context 後即結束，`-XX:ArchiveClassesAtExit` 於結束時寫出快取檔。
3. ENTRYPOINT 加上 `-XX:SharedArchiveFile` 使用快取。

【易錯點提醒 ⚠️】
建置時沒有、也不應該有資料庫密碼（第八章：機密值不進 Image）。因此以環境變數將 DB 指向 127.0.0.1，並設定 Hibernate 不讀取資料庫 metadata，使建置過程完全不連線 Supabase。若保留 Supabase 網址，建置時會以假密碼連線，連續錯誤可能導致 Supabase 暫時封鎖 IP。

【補充】
- 此設定已實際建置、啟動並確認可連線 Supabase 讀取資料。代價是建置時間增加約一分鐘，Image 略大。
- 若專案升級至 Java 25（LTS），可改用 JEP 483/514 的 AOT cache（`-XX:AOTCacheOutput` / `-XX:AOTCache`），效果優於傳統 CDS。
-->

---
layout: default
---

# 練習 1：方式 A — SSDS 上線
### 任務說明

1. 完成「部署前檢查清單」的 7 個項目，並將兩個 repo push 至 GitHub
2. 註冊 Render（GitHub 登入，Hobby 免費方案），授權兩個 repo
3. 建立 `ssds-api`：Docker、Singapore、Free、環境變數（含 `PORT=8080`、排程關閉）、Health Check Path
4. 確認 `https://<後端網址>/api/v1/actuator/health` 回傳 `{"status":"UP"}`
5. 建立 `ssds-web`：`PORT=80`、`API_URL=<後端網址>`
6. 以**手機**開啟前端網址，登入並瀏覽商品頁
7. 修改一行前端文字 → `git push` → 觀察 Render 自動重新部署，完成後重新整理確認

<!--
【任務鋪陳】
本題為本章主線：以方式 A 部署 SSDS。

【出題動機】
- 第 1 步請勿略過，檢查清單逐項確認。
- 第 6 步以手機開啟，體會此網址可由任何地方連線。
- 第 7 步體驗自動部署：僅執行 git push，雲端網站即更新。

【重點提醒】
首次建置加上冷啟動，兩個服務合計可能需 20 至 30 分鐘，等待期間可先閱讀練習 2。
-->

---
layout: default
zoom: 0.88
---

# 練習 1：參考答案

```bash
# 1. 檢查清單第 4 項：.env 未進入 Git（只應出現 .env.example）
git -C ai-products-selection-backend ls-files | grep -i env

# 3. Render ssds-api 環境變數
PORT=8080
SSDS_DB_HOST=aws-0-ap-south-1.pooler.supabase.com
SSDS_DB_PORT=6543
SSDS_DB_NAME=postgres
SSDS_DB_USER=ssds_app.<project-ref>
SSDS_DB_PASSWORD=<密碼>
SSDS_JWT_SECRET=<第八章產生的亂數>
SSDS_INGEST_INSTAGRAM_ENABLED=false
SSDS_INGEST_GOOGLE_TRENDS_ENABLED=false
AI_TREND_SCHEDULE_ENABLED=false
AI_SOURCING_TIME_GAP_SCHEDULE_ENABLED=false
AI_CALIBRATION_SCHEDULE_ENABLED=false
# Health Check Path：/api/v1/actuator/health

# 4. 驗證後端
curl https://ssds-api-xxxx.onrender.com/api/v1/actuator/health    # {"status":"UP"}

# 5. Render ssds-web：PORT=80、API_URL=https://ssds-api-xxxx.onrender.com、Health Check Path：/
# 驗證前端反向代理：經由前端網域呼叫後端
curl -I https://ssds-web-xxxx.onrender.com/api/v1/actuator/health  # HTTP/2 200
```

<!--
【帶讀解法】
最後一行最重要：以前端網域呼叫 /api/v1/actuator/health，等同模擬瀏覽器的行為，請求先到 ssds-web 的 nginx，再轉送至 ssds-api。此行回傳 200，表示 nginx 反向代理 → 後端 → Supabase 全線連通，前端畫面即可取得資料。回傳 502 / 404 時，對照「疑難排解（二）」。

【預期結果】
- 第 6 步：手機可開啟前端網址並登入。
- 第 7 步：push 後 Render 的 Events 出現新的部署，完成後重新整理即顯示修改後的文字。
-->

---
layout: default
---

# 練習 2：方式 B — 自動化部署
### 任務說明

1. 確認 `myaccount/ssds-api`、`myaccount/ssds-web` 在 Docker Hub 上為 `linux/amd64`
2. 在 Render 以 **Existing Image** 建立 `ssds-api-img`（環境變數同練習 1），驗證 health 為 UP
3. 在 Docker Hub 建立 Read & Write 的 Access Token；在 Render 複製 `ssds-api-img` 的 Deploy Hook
4. 在後端 repo 加入 `.github/workflows/deploy.yml`，設定三個 GitHub Secrets
5. 修改任一 Controller → push → 觀察：
   - GitHub **Actions** 執行成功（第二次建置應明顯比第一次快，原因為何？）
   - Docker Hub 出現以 commit hash 命名的新 tag
   - Render **Events** 出現新的部署，Image 為該 commit hash
6. **思考題**：新版本有錯誤時，如何以最快的方式回復至上一版？

<!--
【任務鋪陳】
本題完整走過業界標準的 CI/CD 流程。

【重點提醒】
第 2 步服務名稱使用 ssds-api-img，與練習 1 區分以便比較。兩個服務同時常駐會消耗兩倍的免費時數，完成練習後可將其中一個 Suspend。
-->

---
layout: default
zoom: 0.9
---

# 練習 2：參考答案

```bash
# 1. 確認架構：輸出 linux/amd64
docker image inspect myaccount/ssds-api:1.0.0 --format '{{.Os}}/{{.Architecture}}'

# 3. 先手動測試 Deploy Hook，確認有效後再交給 GitHub Actions
curl -fsS -X POST -G "<Deploy Hook 網址>" \
  --data-urlencode "imgURL=docker.io/myaccount/ssds-api:1.0.0"

# 4. GitHub Secrets：DOCKERHUB_USERNAME、DOCKERHUB_TOKEN、RENDER_DEPLOY_HOOK
#    workflow 內容同 B-4，檔案位置 .github/workflows/deploy.yml

# 6. 回復至上一版（擇一）
#    a. Render → Events → 選擇上一次部署 → Rollback
#    b. 以上一版的 commit hash 呼叫 Deploy Hook
curl -fsS -X POST -G "<Deploy Hook 網址>" \
  --data-urlencode "imgURL=docker.io/myaccount/ssds-api:<上一版的 commit sha>"
```

<div class="mt-2 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>第 5 題「為何第二次較快」：</b><code>cache-from</code> / <code>cache-to: type=gha</code> 將 layer cache 存放於 GitHub；第四章「先複製 build.gradle、再複製原始碼」的排序，使相依套件層直接命中快取，只重新編譯 Java。
</div>

<div class="mt-2 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <b>Actions 失敗常見原因：</b>Secret 名稱拼錯（區分大小寫）、Docker Hub Token 只有 Read 權限無法推送、workflow 檔案未放在 <code>.github/workflows/</code>。
</div>

<!--
【帶讀解法】
- 先手動測試 Deploy Hook，確認網址與參數正確，再交給 GitHub Actions。此為除錯的良好習慣：先將自動化拆解為手動步驟驗證，再組合起來。
- 第 6 題：每個版本都有唯一的 tag，回復版本只需「指回」上一個 tag。

【操作提示】
Actions 失敗時，點入該次執行，檢查哪一步失敗，log 中會有明確的錯誤訊息。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.2rem 0; }
.summary-table th { text-align: left; padding: 8px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 8px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — 雲端部署

<table class="summary-table">
<thead>
<tr><th>重點</th><th>說明</th></tr>
</thead>
<tbody>
<tr><td>平台選擇</td><td>2026/10 免費、免綁卡且可執行 Spring Boot：<b>Render</b>（主要）、Railway（短期備案）</td></tr>
<tr><td>方式 A</td><td>GitHub + Dockerfile，由 Render 建置，push 即自動部署</td></tr>
<tr><td>方式 B</td><td>Docker Hub Image（amd64）+ GitHub Actions + Deploy Hook</td></tr>
<tr><td>共同設定</td><td><code>PORT</code>、環境變數（pooler、JWT secret、關閉排程）、Health Check Path</td></tr>
<tr><td>前後端串接</td><td>web 的 <code>API_URL</code> = 後端公開 https 網址（不加結尾斜線），同網域免 CORS</td></tr>
<tr><td>免費方案限制</td><td>0.1 CPU 冷啟動慢、閒置休眠、無持久化磁碟；展示前先喚醒</td></tr>
</tbody>
</table>

<!--
【回顧】
「共同設定」為本章重點：無論方式 A 或 B、Render 或 Railway，須設定的項目都相同：port、環境變數、健康檢查，分別對應本機 Docker 的 -p、--env-file、healthcheck。熟悉 Docker 之後，更換平台只是找到對應的欄位。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.2rem 0; }
.summary-table th { text-align: left; padding: 6px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 6px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 課程回顧 — 從 `docker run` 到雲端網址

<table class="summary-table">
<thead>
<tr><th>章節</th><th>在 SSDS 上完成的工作</th></tr>
</thead>
<tbody>
<tr><td>Ch1 Docker 簡介</td><td>理解 Container 與 VM 的差異，啟動第一個 nginx</td></tr>
<tr><td>Ch2 映像檔管理</td><td>下載基礎 Image，理解 tag 與 layer</td></tr>
<tr><td>Ch3 容器操作</td><td>以官方 JRE Image 執行 <code>ssds.jar</code>，以 exec / logs 除錯</td></tr>
<tr><td>Ch4 Dockerfile</td><td>撰寫 <code>ssds-api</code>、<code>ssds-web</code> 的 multi-stage Dockerfile</td></tr>
<tr><td>Ch5 Docker Compose</td><td>以 <code>docker compose up</code> 同時啟動前後端並設定 healthcheck</td></tr>
<tr><td>Ch6 網路設定</td><td>nginx 反向代理 <code>/api</code>，以 pooler 連線 Supabase</td></tr>
<tr><td>Ch7 Volume</td><td>商品圖片持久化、備份與還原</td></tr>
<tr><td>Ch8 上線前準備</td><td>機密管理、tag 策略、推送 Docker Hub、512MB 調校</td></tr>
<tr><td>Ch9 雲端部署</td><td><b>以免費、免綁卡平台上線，push 即自動部署</b></td></tr>
</tbody>
</table>

<div class="mt-2 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🎉 <b>完成全部 9 章。</b>專案現已具備可公開存取的網址，可寫入履歷與專題報告。
</div>

<!--
【回顧】
第一章啟動了空白的 nginx；第三章以官方 JRE Image 執行自己的 jar；第四章完成兩份正式 Dockerfile；第五至七章以 Compose、網路、Volume 在本機組成完整系統；第八章完成上線前準備；本章讓 SSDS 擁有可公開存取的網址，且 push 程式碼即自動更新。

同一個專案，由「只能在我的電腦上執行」，變成「可在任何安裝 Docker 的機器與雲端平台上執行」，這就是容器化。

【重點提醒】
三項原則：密碼不進版控、Image 不只依賴 latest、部署前先在本機執行過。做到這三點，即可避開最常見的問題。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
【互動引導】
開放提問：平台選擇、兩種部署方式、GitHub Actions，或部署時遇到的錯誤，有任何疑問皆可提出。

【操作提示】
部署遇到問題時，提供 Render Logs 的錯誤訊息，對照疑難排解表格找出原因。
-->
