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
    「免費、免綁卡，把 SSDS 放上網路給全世界看」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
大家好，歡迎來到最後一章：雲端部署。

前面八章，我們把 SSDS 的前後端都包成了 image、用 Compose 串起來、處理好網路跟上傳檔案、推到了 Docker Hub、也在本機模擬過 512MB 的記憶體限制。這一章要做的事情很單純：把這兩個 image 放到雲端平台上跑，拿到一個 https 的網址，讓老師、組員、家人用手機打開就能用。

條件有兩個：免費、而且不用綁信用卡。這兩個條件在 2026 年其實篩掉了很多平台，我們先做一次平台調查，再挑一個平台完整走過兩種部署方式。
-->

---
layout: default
---

# Outline

- **平台調查** — 2026 年 10 月還「免費 + 免綁卡 + 能跑 Docker」的有哪些？
- **部署架構與事前準備** — 兩個服務、一組環境變數、一張檢查清單
- **方式 A：從 GitHub 讀 Dockerfile 部署**（Render）
- **方式 B：部署 Docker Hub 上 build 好的 Image**（Render）+ GitHub Actions 自動化
- **疑難排解、備案平台、練習題與課程回顧**

<!--
今天分成五個部分。

第一部分是平台調查：免費雲端平台這兩年變動很大，很多以前大家推薦的平台已經收掉免費方案或開始要求綁卡，我們用 2026 年 10 月的資料重新整理一次。

第二部分講部署架構：SSDS 在雲端長什麼樣子、要準備哪些東西。

第三、四部分是主菜，兩種部署方式都會完整走一遍：方式 A 讓平台從 GitHub 讀我們第四章寫的 Dockerfile 自己 build；方式 B 讓平台直接拉我們第八章推到 Docker Hub 的 image，並且用 GitHub Actions 做到 push 程式碼就自動部署。

最後是疑難排解跟備案平台，還有整個九章的課程回顧。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 平台調查

<!--
先做功課：哪些平台符合我們的條件？
-->

---

# 選平台的條件

| 條件 | 為什麼 |
| --- | --- |
| **免費** | 課堂專案、demo 用，不應該產生費用 |
| **免綁信用卡** | 很多同學沒有信用卡；綁了卡也有誤用超額被扣款的風險 |
| **能跑 Docker** | 部署 Dockerfile（從 Git build）或部署 Registry 上的 image，至少一種 |
| **記憶體 ≥ 512MB** | Spring Boot 4 + 多模組，256MB 跑不起來 |
| **能連外部 PostgreSQL（IPv4）** | 資料庫在 Supabase，平台要能連到 pooler 的 6543 port |
| **給 https 網址** | 瀏覽器、手機直接打開，不用自己處理憑證 |

<!--
先把條件講清楚，後面的比較才有依據。

前三個是大家的需求：免費、免綁卡、能跑 Docker。

第四個是 SSDS 的特性決定的：Spring Boot 4 加上 Hibernate、POI、ICU4J，第八章在本機模擬過，512MB 是底線，256MB 的方案直接排除。

第五個是第六章講過的：資料庫在 Supabase，平台的對外連線要能到 pooler；而且有些平台的試用帳號會限制對外網路。

第六個：雲端平台幾乎都會自動給 https 網址，這個不用擔心。
-->

---
zoom: 0.76
---

# 2026 年 10 月 平台調查結果

| 平台 | 免綁卡 | Image | Dockerfile | 免費資源 | 休眠 | 結論 |
| --- | :---: | :---: | :---: | --- | --- | --- |
| **Render** | ✅ | ✅ | ✅ | 512MB / 0.1 CPU、每月 750 小時 | 閒置 15 分鐘休眠；SSDS 喚醒實測約 10 分鐘 | **主推**（常駐網址） |
| **Railway** | ✅（試用） | ✅ | ✅ | 試用 30 天 $5 額度、每服務 ≤1GB；之後每月 $1 額度 | 可選 | 短期 demo 備案 |
| Back4App Containers | ✅ | ✅ | ✅ | 256MB / 0.25 CPU | 有限制 | 只夠跑 `ssds-web` |
| Koyeb | ❌ 2026/2 起要綁卡 | ✅ | ✅ | 512MB | 1 小時 | 排除 |
| Hugging Face Spaces | — | — | ❌ | Docker Space 2026 年中起需付費方案 | — | 排除 |
| Fly.io | ❌ | ✅ | ✅ | 只有 7 天試用 | — | 排除 |
| Cloud Run / Azure / AWS | ❌ | ✅ | ✅ | 免費額度大方 | 依請求計費 | 要綁卡，排除 |

<div class="text-xs text-gray-500 mt-2">資料來源：各平台官方文件與定價頁、snapdeploy.dev〈State of Free Hosting〉（2026-09-28 查核）。免費方案變動頻繁，部署前請再到官網確認。</div>

<!--
這張表是今天第一個重點。我一列一列講。

Render：免費 web service 不用綁卡，支援從 Git 讀 Dockerfile，也支援直接部署 Registry 上的 image。512MB 記憶體、0.1 CPU，每個工作區每月 750 小時。代價是閒置 15 分鐘會休眠，下次有人連線要等它醒來。我們今天的主線就是它。

Railway：註冊不用卡，有 30 天、5 美金的試用額度，每個服務最多 1GB 記憶體，比 Render 寬裕。但試用結束後只剩每月 1 美金額度，Spring Boot 常駐幾天就用完了，所以適合「下週要 demo」這種短期需求。要注意它的試用帳號要完成 GitHub 驗證，不然對外網路會受限，連不到 Supabase。

Back4App Containers：免綁卡，但只有 256MB，Spring Boot 不夠，跑 nginx 前端倒是綽綽有餘。

接下來是排除名單，這幾個都是網路上舊教學常推薦的：
- Koyeb：今年二月起新帳號要綁卡，還有 29 美金的預授權。
- Hugging Face Spaces：以前免費帳號就能開 Docker Space，而且有 16GB 記憶體，很多人拿來放後端。但今年年中改成 Docker Space 要付費方案，免費帳號只剩靜態網頁。
- Fly.io：要卡，而且只剩 7 天試用。
- 三大雲 Google Cloud Run、Azure、AWS：免費額度其實很大方，但一律要綁信用卡建立帳單帳戶，不符合條件。

⚠️ 最後那行小字請大家注意：免費方案是變動最快的東西，這張表是我 2026 年 9 月底查核的，大家實際部署前花兩分鐘到官網確認一下。
-->

---

# 為什麼主推 Render？

| 優點 | 說明 |
| --- | --- |
| 兩種部署方式都支援 | 「Git 倉庫 + Dockerfile」與「Existing Image（Docker Hub）」，剛好對應第 4 章與第 8 章 |
| 不會過期 | 不是試用額度，每月 750 小時免費時數，休眠中不計時 |
| 自動 https | `https://<服務名稱>.onrender.com` |
| 區域有新加坡 | 離台灣近，也離 Supabase 的 `ap-south-1`（孟買）近 |
| Logs / Events 介面 | 看 build log、啟動 log、記憶體超用通知，等同雲端版的 `docker logs` |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>免費方案的代價：</b> 0.1 CPU 讓 SSDS 冷啟動<b>約 10 分鐘</b>（本機模擬實測）；閒置 15 分鐘就休眠；<b>沒有持久化磁碟</b>（上傳的圖片在重新部署或休眠後會消失）；不能做正式營運。Demo 前先打開網址把服務叫醒。
</div>

<!--
選 Render 的理由：兩種部署方式都有、不會過期、有新加坡區域、介面清楚。

但下面那個框要誠實講清楚免費方案的代價：

第一，0.1 CPU 真的很少。我在本機用 docker run --cpus 0.1 -m 512m 模擬 Render 免費規格實測：SSDS 不限 CPU 時 31 秒啟動，0.1 CPU 要將近 600 秒，也就是 10 分鐘。Render 實際的 CPU 分配可能比本機模擬寬鬆一點，但請用 10 分鐘來準備。這不是你設定錯，是資源就這麼多。

第二，閒置 15 分鐘就休眠。所以 demo 之前五分鐘，先自己打開網址把服務叫醒。

第三，第七章預告過的：免費方案沒有持久化磁碟，容器每次重新部署、休眠後喚醒都是全新的，上傳的商品圖片會消失。demo 時現場上傳、現場展示沒問題；要長期保存就要改用物件儲存。

第四，Render 自己的文件也寫了：免費方案不要拿來跑正式服務。
-->

---
zoom: 0.9
---

# 冷啟動實測：0.1 CPU 有多慢？

本機用 `docker run --cpus <N> -m 512m` 模擬，SSDS 從啟動到 `Started SsdsApplication`：

| CPU | 啟動時間 | 啟動後記憶體 | 備註 |
| --- | --- | --- | --- |
| 不限制 | 31 秒 | — | 一般筆電 |
| 0.5 | 115 秒 | 約 330MB | 第 8 章的模擬設定 |
| **0.1（Render Free）** | **約 600 秒** | 約 300MB | 啟動後每個請求約 1 秒 |
| 0.1 + CDS（進階，見附錄） | 約 394 秒 | 約 285MB | 省約 35% |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>對策：</b> ① Demo 前 15 分鐘先打開後端 health 網址叫醒它 ② Health Check Path 一定要設，Render 部署最多等 15 分鐘 ③ 重要 demo 改用 Railway 試用（CPU 寬鬆很多，見備案）④ 想更快可加 CDS（附錄）。
</div>

<!--
這頁是我實際量出來的數字，請大家一定要有心理準備。

我在本機用 docker run --cpus 限制 CPU、-m 512m 限制記憶體，模擬不同規格，看 SSDS 要多久才印出 Started SsdsApplication。不限制 CPU 31 秒；0.5 CPU 要 115 秒；0.1 CPU，也就是 Render 免費方案的規格，要將近 600 秒——10 分鐘。

為什麼這麼慢？Spring Boot 啟動時要載入幾萬個類別、建立上百個 bean、初始化 Hibernate，這些全部是吃 CPU 的工作。我們專案模組多，又是 0.1 顆 CPU，就是這麼久。我也試了 lazy initialization，幾乎沒有差別；CDS（Class Data Sharing）可以省大約三分之一，放在附錄給有興趣的同學。

Render 的 0.1 CPU 實際上可能比 docker 的硬性限制寬鬆，部署後請大家看 log 裡自己的實際數字。

這代表什麼？Render 閒置 15 分鐘就休眠，下一個使用者連進來要等它重新啟動——最多 10 分鐘。所以 Render 適合拿來放一個「隨時可以打開看看」的網址；真正重要的 demo，要嘛提早叫醒，要嘛用 Railway 試用額度部署一份 CPU 比較多的備用。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 部署架構與事前準備

<!--
接下來看 SSDS 在雲端長什麼樣子，以及部署前要準備好哪些東西。
-->

---
zoom: 0.83
---

# SSDS 在雲端的架構

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
| `ports: "8000:80"` | 平台自動給 https 網址，用 `PORT` 告訴它容器聽哪個 port |
| `healthcheck:` | Render 的 **Health Check Path** |

<!--
這張圖跟第六章本機的架構幾乎一模一樣，差別只有三個箭頭上的網址。

雲端上有兩個 Render Web Service，各自跑一個 image。使用者連的是 ssds-web 的網址，nginx 把 /api 開頭的請求轉給 ssds-api。

最大的差別在 API_URL：本機 Compose 裡兩個容器在同一個內部網路，用服務名稱 api 就連得到；但 Render 的免費方案不支援服務之間的私有網路，所以 nginx 要透過 ssds-api 的「公開網址」去連。這也是為什麼第四章 nginx 設定檔要加 proxy_ssl_server_name on——公開網址是 https。

下面的對照表很重要：我們在本機學的每一個 Docker 概念，在雲端平台上都有對應的設定欄位，只是從 YAML 變成網頁表單。你會發現，學會 Docker 之後，換任何一個雲端平台都只是在找「那個欄位在哪裡」。

⚠️ 為什麼瀏覽器不直接打 ssds-api 的網址？因為 CORS。第六章講過，後端 CORS 白名單只有 localhost:4200，走 nginx 反向代理，瀏覽器眼中只有 ssds-web 一個網域，不用改任何後端程式碼。
-->

---
zoom: 0.82
---

# 部署前檢查清單

| # | 項目 | 在哪一章做的 |
| --- | --- | --- |
| 1 | 後端 repo 根目錄有 `Dockerfile`、`.dockerignore`；`ssds-api/build.gradle` 加了 actuator | Ch4 |
| 2 | 前端 repo 根目錄有 `Dockerfile`、`.dockerignore`、`nginx/default.conf.template` | Ch4 |
| 3 | 本機 `docker compose up` 能從 `http://localhost:8000` 登入並看到資料 | Ch5、Ch6 |
| 4 | `.env` **沒有**進 Git（`git ls-files | grep .env` 只看得到 `.env.example`） | Ch8 |
| 5 | Dockerfile 有 `JAVA_TOOL_OPTIONS`，本機 512MB 限制下能 healthy | Ch8 |
| 6 | 準備好新的 `SSDS_JWT_SECRET` | Ch8 |
| 7 | 兩個 repo 都 push 到 GitHub（方式 A）／兩個 image 推到 Docker Hub、**amd64**（方式 B） | Ch8 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>黃金法則：</b> 本機 <code>docker compose up</code> 跑不起來的，雲端一定也跑不起來 — 先在本機修好，再上雲端。
</div>

<!--
這張檢查清單請大家逐項打勾再往下做。每一項都對應前面某一章的內容，大部分在練習裡已經做過了。

第 4 項特別重要：方式 A 是讓 Render 讀你的 GitHub repo，如果 .env 曾經被 commit 過，等於你的 Supabase 密碼在 GitHub 上。用 git ls-files 確認一下。

那個黃金法則是今天最想讓大家記住的一句話。雲端平台的除錯比本機難很多——log 要到網頁上看、每次重新部署要等好幾分鐘。能在本機重現、修好的問題，就不要帶到雲端。
-->

---
zoom: 0.78
---

# 後端要設定的環境變數

| 變數 | 值 | 說明 |
| --- | --- | --- |
| `PORT` | `8080` | 告訴 Render 容器聽哪個 port（預設猜 10000） |
| `SSDS_DB_HOST` / `SSDS_DB_PORT` | `aws-0-ap-south-1.pooler.supabase.com` / `6543` | **pooler**（IPv4），不要用 direct connection |
| `SSDS_DB_NAME` / `SSDS_DB_USER` / `SSDS_DB_PASSWORD` | `postgres` / `ssds_app.<project-ref>` / 密碼 | 跟本機 `.env` 一樣 |
| `SSDS_JWT_SECRET` | 新產生的亂數 | **不要**沿用預設值 |
| `MISTRAL_API_KEY` | 你的 key | 需要 AI 功能才設 |
| 五個排程開關（下方） | `false` | 省記憶體、省 Apify / Mistral 額度、避免多人重複寫入共用 DB |

```plaintext
SSDS_INGEST_INSTAGRAM_ENABLED  SSDS_INGEST_GOOGLE_TRENDS_ENABLED  AI_TREND_SCHEDULE_ENABLED
AI_SOURCING_TIME_GAP_SCHEDULE_ENABLED  AI_CALIBRATION_SCHEDULE_ENABLED
```

<div class="mt-4 p-3 bg-red-50 border-l-4 border-red-400 text-gray-700 text-sm text-left">
⚠️ <b>不要設</b> <code>SSDS_FLYWAY_ENABLED</code> 與 <code>SSDS_MIGRATION_DB_*</code>：共用資料庫的 migration 只由負責的組員在本機套用。<code>SPRING_PROFILES_ACTIVE=prod</code> 與 <code>JAVA_TOOL_OPTIONS</code> 已經寫在 Dockerfile 裡。
</div>

<!--
這是後端要在 Render 設定的環境變數，幾乎就是大家本機 .env 的內容，加上幾個雲端特有的。

PORT=8080：Render 預設認為容器聽 10000 port，我們的 Spring Boot 聽 8080。設 PORT 是告訴 Render「請把流量轉到 8080」，等同本機的 -p 右半邊。

資料庫那四個跟本機一樣，再強調一次一定要用 pooler 的網址：Render 對外連線只有 IPv4，Supabase 的 direct connection 只有 IPv6，第六章練習 2 示範過那個錯誤。

SSDS_JWT_SECRET：第八章產生的那組新亂數。

最後一列是我的建議：關掉排程。原因有三個：
1. 排程會在背景跑熱度採集、AI 分析，吃記憶體也吃 CPU，0.1 CPU 的機器扛不住。
2. 熱度採集會呼叫 Apify、AI 會呼叫 Mistral，都是用量計費，全班每個人都部署一份，額度很快就燒光。
3. 全組共用一個 Supabase，如果每個組員的雲端服務都在跑同一個排程，會重複寫入。
如果組上需要一個「正式跑排程」的環境，就指定一個人負責，其他人都關掉。另外，Apify 的 token 不需要就不要設，沒設的話程式會自動跳過那個資料來源。

紅框：Flyway 相關的千萬不要設。專案的 .env.example 也寫得很清楚，migration 只能由負責的人在本機對共用資料庫套用。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 方式 A：從 GitHub 讀 Dockerfile 部署

<!--
第一種部署方式：讓 Render 連到我們的 GitHub repo，用第四章寫的 Dockerfile 在它的機器上 build。好處是之後 push 到 main，Render 會自動重新 build、重新部署，不用自己 build image。
-->

---

# 方式 A 流程總覽

```
git push ──▶ GitHub repo ──(Render 自動偵測 push)──▶ Render build（照 Dockerfile）──▶ 部署新容器
```

| 步驟 | 動作 |
| --- | --- |
| 1 | 用 GitHub 帳號註冊 Render（免綁卡），授權 Render 讀取兩個 repo |
| 2 | 建立 `ssds-api` Web Service：選後端 repo → Language: **Docker** → Instance Type: **Free** |
| 3 | 設定環境變數、Health Check Path → Deploy，等 build 與啟動完成 |
| 4 | 記下後端網址 `https://ssds-api-xxxx.onrender.com`，打 `/api/v1/actuator/health` 確認 UP |
| 5 | 建立 `ssds-web` Web Service：選前端 repo → `API_URL` 設成第 4 步的網址 |
| 6 | 打開前端網址登入，整條鏈驗收 |

<!--
先看整體流程，等一下一步一步截圖講解。

順序很重要：先部署後端、拿到後端網址，才能設定前端的 API_URL。這跟第六章「nginx 啟動時要能解析 proxy_pass 的主機名稱」是同一個道理——前端依賴後端。
-->

---

# A-1　註冊 Render 並連結 GitHub

1. 打開 `https://render.com` → **Get Started** → 選 **GitHub** 登入
2. 依畫面建立 Workspace（選 **Hobby** 免費方案，不會要求信用卡）
3. Dashboard 右上角 **+ New** → **Web Service**
4. Source Code 選 **Git Provider** → **GitHub** → 在 GitHub 授權頁選 **Only select repositories**，勾選：
   - `ai-products-selection-backend`
   - `ai-products-selection-frontend`

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>組員的 repo？</b> 如果 repo 在小組的 GitHub Organization 底下，需要 Organization 管理員同意 Render 的存取；或者 fork 一份到自己帳號再部署。
</div>

<!--
第一步註冊。用 GitHub 帳號登入最方便，後面連 repo 就不用再授權一次。

建立 Workspace 時選 Hobby，也就是個人免費方案，整個過程不會要求信用卡。如果畫面要求輸入付款資訊，代表你選到付費方案了，往回找免費的選項。

GitHub 授權頁建議選 Only select repositories，只開放這兩個 repo 給 Render，不要把整個帳號的 repo 都開放出去，這是最小權限原則。

⚠️ 如果你們小組的 repo 是放在 GitHub Organization 底下，Render 要讀取需要 Organization 管理員按同意。來不及的話，fork 一份到自己的帳號再部署也可以。
-->

---
zoom: 0.93
---

# A-2　建立 ssds-api（基本設定）

| 欄位 | 填寫 |
| --- | --- |
| Repository | `ai-products-selection-backend` |
| Name | `ssds-api`（會變成網址的一部分；被用走的話 Render 會加亂數） |
| Language | **Docker**（偵測到根目錄的 Dockerfile 會自動選好） |
| Branch | `main` |
| Region | **Singapore (Southeast Asia)** |
| Root Directory | 留空（Dockerfile 在 repo 根目錄） |
| Instance Type | **Free** — 512 MB / 0.1 CPU |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ Language 如果顯示的不是 Docker（例如 Java 或 Node），代表 Render 沒找到 Dockerfile — 檢查檔名是不是 <code>Dockerfile</code>（大寫 D、沒有副檔名）、有沒有 push 到 <code>main</code>。
</div>

<!--
這頁是建立後端服務的基本欄位。

Name 會變成網址的一部分：ssds-api.onrender.com。這個名字全 Render 只能有一個，全班都叫 ssds-api 的話，後面的人會被自動加上亂數，例如 ssds-api-a1b2.onrender.com。沒關係，以實際拿到的網址為準。

Language 選 Docker：這是方式 A 的關鍵，Render 會用我們的 Dockerfile build，而不是用它自己的 Java buildpack。

Region 選 Singapore，離台灣的使用者近，離 Supabase 的孟買機房也近，資料庫查詢的延遲會小一點。

Instance Type 一定要選 Free，選錯的話是會計費的方案（不過沒綁卡也扣不了款，會直接無法建立）。
-->

---
zoom: 0.97
---

# A-3　建立 ssds-api（環境變數與進階設定）

**Environment Variables**：照「後端要設定的環境變數」那張表一個一個加，或按 **Add from .env** 一次貼上

**Advanced** 展開後：

| 欄位 | 填寫 |
| --- | --- |
| Health Check Path | `/api/v1/actuator/health` |
| Dockerfile Path | `./Dockerfile`（預設） |
| Docker Build Context Directory | `.`（預設） |
| Auto-Deploy | **On Commit**（push 到 main 自動重新部署） |

最後按 **Deploy Web Service**

<div class="mt-4 p-3 bg-red-50 border-l-4 border-red-400 text-gray-700 text-sm text-left">
⚠️ 用 <b>Add from .env</b> 貼上本機 <code>.env</code> 時，記得<b>刪掉</b> <code>SSDS_FLYWAY_ENABLED</code>、<code>SSDS_MIGRATION_DB_*</code> 這些行，再補上 <code>PORT=8080</code>、新的 <code>SSDS_JWT_SECRET</code> 與排程開關。
</div>

<!--
環境變數可以一個一個加，也可以用 Add from .env 一次貼上整份 .env 內容，比較快。但貼上之前看一下內容，把 migration 相關的刪掉，把雲端專用的補上。

這些值存在 Render 上，是加密保存的，不會出現在 GitHub、也不會進 image——跟本機用 --env-file 是同樣的精神：機密值只在執行時給。

Health Check Path 填 /api/v1/actuator/health，跟第五章 compose 的 healthcheck 是同一個網址。Render 會用它判斷新版本是不是真的起來了。⚠️ 漏了 /api/v1 是最常見的錯，Render 會一直判定服務不健康。

Dockerfile Path、Build Context 用預設值就好，因為我們的 Dockerfile 就在 repo 根目錄，跟第四章 `docker build .` 的意思一樣。

Auto-Deploy 開著，以後 push 到 main，Render 就自動重 build、重部署。
-->

---

# A-4　看 build 與啟動 log

部署後進到服務頁面的 **Logs**，會依序看到：

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
按下 Deploy 之後，Logs 頁面就是雲端版的 docker build 加 docker logs。

前半段是 build：Render 先 clone 我們的 repo，然後照 Dockerfile 一層一層 build，這段 log 跟本機 docker build 的輸出幾乎一模一樣，第一次要 5 到 10 分鐘。

後半段是啟動：第一行 Picked up JAVA_TOOL_OPTIONS 代表第八章的記憶體參數生效了；看到 HikariPool Start completed 代表連上 Supabase 了；看到 Tomcat started on port 8080 with context path /api/v1，最後 Started SsdsApplication。

⚠️ 大家注意那個啟動時間：本機 30 秒，這裡可能要 10 分鐘，因為只有 0.1 CPU。Render 部署時會等健康檢查最多 15 分鐘，所以是來得及的——耐心等，不要急著按重新部署，重新部署只會從頭再等一次。

看到 Your service is live 就成功了。
-->

---

# A-5　驗證後端

```bash
# 把 xxxx 換成你實際拿到的網址
curl https://ssds-api-xxxx.onrender.com/api/v1/actuator/health
# {"status":"UP"}
```

也可以直接用瀏覽器開：

- 健康檢查：`https://ssds-api-xxxx.onrender.com/api/v1/actuator/health`
- Swagger UI：`https://ssds-api-xxxx.onrender.com/api/v1/swagger-ui.html`

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 記下這個網址（<b>不含結尾斜線</b>），下一步設定前端的 <code>API_URL</code> 要用。
</div>

<!--
部署成功之後先驗證後端本身，不要急著做前端。這是第六章教的除錯原則：一層一層確認。

health 回 UP 代表 Spring Boot 起來了、而且連得到 Supabase（health 會檢查資料庫連線）。如果回 DOWN，看 Logs 裡的 HikariPool 錯誤訊息。

Swagger UI 能打開，也可以直接在上面試打幾支 API。

把網址記下來，注意不要帶結尾斜線。
-->

---

# A-6　建立 ssds-web

再按一次 **+ New** → **Web Service**，選 `ai-products-selection-frontend`：

| 欄位 | 填寫 |
| --- | --- |
| Name | `ssds-web` |
| Language / Region / Instance Type | **Docker** / **Singapore** / **Free** |
| Environment Variables | `PORT` = `80`<br>`API_URL` = `https://ssds-api-xxxx.onrender.com`（**不加結尾斜線**） |
| Health Check Path | `/` |

部署完成後打開 `https://ssds-web-xxxx.onrender.com` → 登入 → 能看到商品資料就**大功告成** 🎉

<!--
前端服務的設定比後端簡單很多。

PORT=80：nginx 聽 80 port。

API_URL：就是上一步記下來的後端網址。容器啟動時，nginx 官方 image 會用 envsubst 把設定檔裡的 ${API_URL} 換成這個值——第四章寫的那個 .template 檔，在這裡發揮作用了。同一個 image，本機 Compose 設 http://api:8080，雲端設 https 的公開網址，完全不用改程式碼。

前端的 build 也是在 Render 上做的：npm ci、裝 JRE、generate:api、ng build，大概 5 分鐘。

打開前端網址，登入，看到資料，整條鏈就通了：手機瀏覽器 → Render 上的 nginx → Render 上的 Spring Boot → Supabase。

⚠️ 如果兩個服務都在休眠，第一次打開會非常慢：前端先醒、然後第一個 API 請求再叫醒後端。demo 前先開一次後端的 health 網址，再開前端。
-->

---

# A-7　之後怎麼更新？

```bash
# 在後端 repo 改完程式
git add . && git commit -m "feat: 新增選品報表匯出"
git push origin main
# → Render 偵測到 push，自動重新 build + 部署 ssds-api
```

| 想做的事 | 在 Render 上怎麼做 |
| --- | --- |
| 看部署歷史、退回上一版 | 服務頁面 → **Events** → 選舊的部署 → **Rollback** |
| 改環境變數 | **Environment** → 修改 → 儲存後自動重新部署 |
| 手動重新部署 | 右上角 **Manual Deploy** → **Deploy latest commit** |
| 暫停服務 | **Settings** → **Suspend Web Service** |

<!--
方式 A 最大的好處就是更新超簡單：git push 就好，剩下的 Render 自動處理。

Events 頁面可以看到每一次部署是哪個 commit 觸發的，出問題可以直接 Rollback 回上一版——這就是第八章講的「版本可追溯、可以快速回滾」，平台幫我們做好了。

⚠️ 提醒一下：每次重新部署，容器都是全新的，上傳的圖片會消失。第七章講過，這是免費方案沒有持久化磁碟的限制。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 方式 B：部署 Docker Hub 上的 Image

<!--
第二種部署方式：我們自己 build image、推到 Docker Hub，Render 只負責拉下來跑。

什麼時候用方式 B？
- repo 是私有的、或在 Organization 底下不方便授權給 Render
- 想要「在本機測過的 image」跟「雲端跑的 image」是同一個，一個 bit 都不差
- 想用 GitHub Actions 自己控制 build 流程
-->

---

# 方式 B 流程總覽

```
docker build（或 GitHub Actions）──▶ docker push ──▶ Docker Hub ──▶ Render 拉 image ──▶ 部署
```

| 步驟 | 動作 |
| --- | --- |
| 1 | 確認 Docker Hub 上已有 `myaccount/ssds-api:1.0.0`、`myaccount/ssds-web:1.0.0`，且是 **linux/amd64** |
| 2 | Render **+ New** → **Web Service** → Source Code 選 **Existing Image** |
| 3 | Image URL 填 `docker.io/myaccount/ssds-api:1.0.0`（私有 repo 要加 Credential） |
| 4 | Name / Region / **Free** / 環境變數 / Health Check Path — 跟方式 A 完全一樣 |
| 5 | 對 `ssds-web` 重複一次，`API_URL` 填後端網址 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 方式 A 與 B 的差別只在「image 從哪裡來」— <b>環境變數、Port、Health Check 的設定完全相同</b>，這就是 image 的可攜性。
</div>

<!--
方式 B 的流程跟方式 A 幾乎一樣，差別只在第 2、3 步：Source Code 選 Existing Image，填 Docker Hub 上的 image 網址。

後面的環境變數、PORT、Health Check Path，跟方式 A 一模一樣。這正是 Docker 的核心價值：image 是一個標準化的包裝，不管它是 Render 自己 build 的、還是我們推上去的，跑起來都一樣。
-->

---

# B-1　確認 Image 的平台架構

```bash
docker image inspect myaccount/ssds-api:1.0.0 --format '{{.Os}}/{{.Architecture}}'
# linux/amd64   ← 一定要是這個
```

如果是 `linux/arm64`（M 系列 Mac 預設），重新 build 再推：

```bash
docker build --platform linux/amd64 -t myaccount/ssds-api:1.0.1 \
  ./ai-products-selection-backend
docker push myaccount/ssds-api:1.0.1
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ 架構錯誤的症狀：Render Logs 出現 <code>exec format error</code>，或是部署一直失敗、沒有任何 Spring Boot 的 log。
</div>

<!--
方式 B 第一件事：確認 image 的 CPU 架構。第八章提過，這裡再確認一次，因為這是方式 B 最常見、也最難懂的失敗原因。

docker image inspect 加 format 可以直接印出 OS 跟架構。Windows 跟 Intel Mac 的同學一定是 amd64；M 系列 Mac 的同學如果 build 時忘了加 --platform，就會是 arm64。

重 build 的時候順便把版本號加一，不要覆蓋同一個 tag——第八章講的，tag 是可變的，覆蓋會讓大家搞不清楚哪個 1.0.0 是哪個。
-->

---
zoom: 0.93
---

# B-2　在 Render 建立 Image 服務

**+ New** → **Web Service** → Source Code 選 **Existing Image**：

| 欄位 | 填寫 |
| --- | --- |
| Image URL | `docker.io/myaccount/ssds-api:1.0.0` |
| Credential | Public repo：不用填<br>Private repo：**Add credential** → Username = Docker Hub 帳號、Token = Docker Hub **Read-only** Access Token |
| Name / Region / Instance Type | `ssds-api` / Singapore / **Free** |
| Environment Variables | 同方式 A（`PORT=8080`、`SSDS_DB_*`、`SSDS_JWT_SECRET`…） |
| Health Check Path | `/api/v1/actuator/health` |

`ssds-web` 同樣做法：Image URL `docker.io/myaccount/ssds-web:1.0.0`，環境變數 `PORT=80`、`API_URL=https://ssds-api-xxxx.onrender.com`

<!--
Existing Image 的設定頁。

Image URL 的格式是 docker.io/帳號/名稱:tag。docker.io 是 Docker Hub 的 registry 位址，平常 docker pull 不寫也會預設是它，但在平台上建議寫完整。

Credential：public repository 不用填。如果你在 Docker Hub 把 repo 設成 private，就要給 Render 一組憑證。建議到 Docker Hub 建一個「唯讀」的 Access Token 給 Render，不要給有寫入權限的、更不要給帳號密碼。最小權限原則。

其他欄位跟方式 A 完全一樣。
-->

---

# B-3　更新版本：手動與 Deploy Hook

Image 服務**不會自動偵測** Docker Hub 有新版，要自己觸發：

| 做法 | 怎麼做 |
| --- | --- |
| 換 tag | **Settings** → Image URL 改成 `...:1.0.1` → 儲存並部署 |
| 同 tag 重拉 | **Manual Deploy** → **Deploy latest reference** |
| Deploy Hook | **Settings** → 複製 **Deploy Hook** 網址，打一個 HTTP 請求就會重新部署 |

```bash
# Deploy Hook：可以用 imgURL 參數指定這次要部署哪個 tag
curl -fsS -X POST -G "$RENDER_DEPLOY_HOOK_API" \
  --data-urlencode "imgURL=docker.io/myaccount/ssds-api:1.0.1"
```

<div class="mt-4 p-3 bg-red-50 border-l-4 border-red-400 text-gray-700 text-sm text-left">
⚠️ Deploy Hook 網址本身就是密碼（裡面有 key），任何人拿到都能觸發部署 — 只放在 GitHub Secrets，不要貼在 README 或群組。
</div>

<!--
方式 B 的更新要自己觸發，因為 Render 不會一直去 Docker Hub 檢查有沒有新版。

三種做法：換 tag 最明確，推薦；同一個 tag 重推之後用 Deploy latest reference 讓 Render 重拉；Deploy Hook 是給自動化用的，下一頁 GitHub Actions 就會用它。

Deploy Hook 可以帶 imgURL 參數，指定這次要部署哪個 tag。--data-urlencode 會把冒號、斜線編碼好；-G 把參數放到網址上，-X POST 用 POST 方法送出。

紅框很重要：Deploy Hook 網址裡面帶了 key，等同一把鑰匙，外洩的話任何人都能讓你的服務重新部署。只能放在 GitHub Secrets 這種加密的地方。
-->

---
zoom: 0.71
---

# B-4　GitHub Actions：push 就自動 build、推送、部署

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
      - uses: actions/checkout@v5
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}
      - uses: docker/build-push-action@v6
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
這份 workflow 就是第八章 CI/CD 概念的實作。我們一段一段看。

on push branches main：push 到 main 就觸發。

checkout：把程式碼抓下來。setup-buildx：啟用 BuildKit 的進階功能（快取）。login-action：用 GitHub Secrets 裡的帳號跟 Access Token 登入 Docker Hub。

build-push-action 做的就是 docker build 加 docker push：
- context: . 就是 docker build 最後那個點。
- platforms: linux/amd64：GitHub 的機器本來就是 amd64，寫出來比較明確。
- tags 打兩個：latest 方便人看，github.sha 是這次 commit 的完整 hash，精準對應程式碼版本——第八章 tag 策略的實作。
- cache-from / cache-to type=gha：把 layer cache 存在 GitHub Actions 的快取裡。第四章辛苦排好的依賴快取順序在這裡發揮作用：只改 Java 的話，下載依賴那層直接命中快取，build 時間大幅縮短。

最後一步呼叫 Render 的 Deploy Hook，用 imgURL 指定部署剛剛推上去的那個 commit hash 版本。

前端 repo 放一份一樣的檔案，把 ssds-api 換成 ssds-web、Deploy Hook 換成前端服務的就好。

GitHub Actions 對 public repo 免費；private repo 每月也有免費分鐘數，課堂專案夠用。
-->

---

# B-5　設定 GitHub Secrets

GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**：

| Secret 名稱 | 值 | 從哪裡拿 |
| --- | --- | --- |
| `DOCKERHUB_USERNAME` | `myaccount` | Docker Hub 帳號 |
| `DOCKERHUB_TOKEN` | `dckr_pat_...` | Docker Hub → Account settings → **Personal access tokens**（Read & Write） |
| `RENDER_DEPLOY_HOOK` | `https://api.render.com/deploy/srv-...?key=...` | Render 服務 → **Settings** → **Deploy Hook** |

設定完 push 一個 commit → repo 的 **Actions** 分頁看執行過程 → 綠勾勾後到 Render **Events** 確認有新的部署

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 Secrets 存進去之後<b>再也看不到值</b>，workflow log 裡也會被自動遮成 <code>***</code> — 這就是「機密值只在執行時給」在 CI 上的做法。
</div>

<!--
workflow 裡的 secrets.XXX 要先在 GitHub 設定好。三個值：

DOCKERHUB_USERNAME：Docker Hub 帳號。
DOCKERHUB_TOKEN：Docker Hub 的 Personal Access Token，這次需要寫入權限，因為要 push。不要用帳號密碼。
RENDER_DEPLOY_HOOK：Render 服務設定頁的 Deploy Hook 網址。

設定好之後 push 一個 commit，到 Actions 分頁看它跑。第一次 build 沒有快取會比較久，大概 5 到 10 分鐘；之後只改 Java 的話會快很多。綠勾勾之後，Render 的 Events 頁面會出現一筆新的部署，Image 欄位是剛剛的 commit hash。

這樣就完成了完整的 CI/CD：寫程式 → push → 自動 build → 自動推 Docker Hub → 自動部署到雲端。
-->

---
zoom: 0.96
---

# 方式 A vs 方式 B

| 比較 | 方式 A：Git + Dockerfile | 方式 B：Existing Image |
| --- | --- | --- |
| 誰 build | Render | 自己 / GitHub Actions |
| 自動更新 | push 就自動 | 要 Deploy Hook 或手動 |
| 設定難度 | ⭐ 最簡單 | ⭐⭐ 多了 Docker Hub、Secrets |
| 本機與雲端一致性 | 同一份 Dockerfile，但 build 環境不同 | **同一個 image，一個 bit 都不差** |
| CPU 架構問題 | 不會遇到（Render 自己 build） | 要注意 amd64 |
| 私有 repo / Org repo | 要授權 Render 讀取 | 不用給 Render 讀程式碼 |
| 換平台 | 換平台要重新設定 Git 連結 | 任何能跑 image 的平台都能直接用 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>建議：</b> 第一次部署用<b>方式 A</b> 最快上線；熟悉之後改用<b>方式 B + GitHub Actions</b>，這也是業界最常見的做法。
</div>

<!--
兩種方式比較一下。

方式 A 最簡單，適合第一次上線，也適合只想快速 demo 的情況。

方式 B 多了幾個步驟，但有兩個很大的優點：第一，雲端跑的跟本機測的是同一個 image，第八章在本機 512MB 限制下測過的東西，到雲端行為完全一樣；第二，image 在 Docker Hub 上，換到任何平台（Railway、公司的 Kubernetes、三大雲）都能直接用，這就是容器化的可攜性。

業界最常見的就是方式 B 的模式：CI 負責 build、registry 負責存放、平台只負責跑。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 疑難排解與備案平台

<!--
部署一定會遇到問題。這一部分整理最常見的錯誤，以及 Render 不能用時的備案。
-->

---
zoom: 0.87
---

# 部署疑難排解（一）：Build 與啟動

| 症狀（Render Logs） | 原因 | 解法 |
| --- | --- | --- |
| `Could not resolve "../../api"` | 前端沒跑 `generate:api` | Dockerfile build 階段：`apk add openjdk21-jre-headless` + `npm run generate:api`（Ch4） |
| `./gradlew: Permission denied` / `bad interpreter: ^M` | 執行權限 / CRLF 換行 | `RUN chmod +x gradlew`；`.gitattributes` 設 `/gradlew text eol=lf` |
| `exec format error` | 推了 arm64 image | `--platform linux/amd64` 重 build（方式 B） |
| `password authentication failed for user "ssds_app"`（帳號沒有 `.<ref>`） | `SSDS_DB_*` 沒設，用了預設值 | Render → Environment 補齊 |
| `No open ports detected` / 一直 Deploying | `PORT` 沒設或設錯 | api 設 `PORT=8080`、web 設 `PORT=80` |
| `Ran out of memory (used over 512MB)` / 一直重啟 | JVM 吃太多 | `JAVA_TOOL_OPTIONS` 的 `MaxRAMPercentage` 調到 50；關掉排程 |
| Health check 一直失敗 | 路徑錯 | `/api/v1/actuator/health`（含 context-path） |

<!--
第一張表是 build 跟啟動階段的錯誤。大部分在前面章節都遇過了，這裡整理成一張表方便查。

特別提醒最後兩列：
- 記憶體超用：Render 會在 Events 頁面直接顯示 Ran out of memory。處理方式就是第八章教的：調低 MaxRAMPercentage、關掉不需要的排程。
- Health check：漏了 /api/v1 是最常見的錯。
-->

---
zoom: 0.81
---

# 部署疑難排解（二）：連線

| 症狀 | 原因 | 解法 |
| --- | --- | --- |
| api log：`Network is unreachable` / `UnknownHostException: db.xxx.supabase.co` | 用了 Supabase direct connection（IPv6） | `SSDS_DB_HOST` 改用 **pooler**（Ch6） |
| api log：`password authentication failed` | 帳號格式或密碼錯 | 帳號是 `ssds_app.<project-ref>`；密碼不要加引號 |
| 前端 **502 Bad Gateway** | nginx 連不到後端 | `API_URL` 拼錯、用了 `http://` 而非 `https://` |
| 前端 API 全部 **404** | `API_URL` 多了結尾 `/` | 拿掉結尾斜線（Ch6 proxy_pass 規則） |
| 前端 **504 Gateway Timeout** | 後端還在冷啟動（0.1 CPU 約 10 分鐘） | 稍後再重新整理；demo 前 15 分鐘先叫醒後端 |
| 重新整理子頁面 404 | 少了 SPA fallback | nginx `try_files $uri $uri/ /index.html`（Ch4） |
| 上傳的圖片隔天不見 | 免費方案沒有持久化磁碟 | 預期行為（Ch7）；長期需改用物件儲存 |

<!--
第二張表是連線問題，跟第六章練習 2 的除錯表幾乎一樣，只是場景搬到雲端。

除錯順序還是那句話：從外往內。瀏覽器 DevTools 看狀態碼 → ssds-web 的 Logs 看 nginx → ssds-api 的 Logs 看 Spring Boot。

502 跟 504 的差別：502 是 nginx 根本連不到後端（網址錯），504 是連到了但等太久（後端在冷啟動）。

最後一列不是 bug，是免費方案的限制，第七章講過。
-->

---
zoom: 0.94
---

# 備案：Railway（短期 demo）

當 Render 不能用、或需要更多記憶體（1GB）做短期 demo 時：

| 步驟 | 動作 |
| --- | --- |
| 1 | `https://railway.com` 用 GitHub 登入，**完成 GitHub 帳號驗證**（否則是 Limited Trial，對外網路受限、連不到 Supabase） |
| 2 | **New Project** → **Deploy from GitHub repo**（偵測 Dockerfile，等同方式 A）或 **Docker Image**（等同方式 B） |
| 3 | 服務 → **Variables**：貼上同一組環境變數（`PORT=8080`、`SSDS_DB_*`…） |
| 4 | **Settings** → **Networking** → **Generate Domain**，Port 填 `8080` |
| 5 | 前端同樣做法，`API_URL` 填後端的 Railway 網址 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ 試用為 <b>30 天或 5 美金額度</b>（先到者為準），之後每月只有 1 美金額度，Spring Boot 常駐很快用完 — 適合「下週 demo」，不適合長期放著。
</div>

<!--
備案平台 Railway。流程跟 Render 幾乎一樣，因為所有平台做的事都一樣：拿到 image（或 Dockerfile）、設定環境變數、告訴它 port、給一個網址。

第一步的 GitHub 驗證一定要做：Railway 沒驗證的試用帳號，對外網路是受限的，Spring Boot 會連不到 Supabase。

Railway 的優點是記憶體比較多、沒有強制休眠，demo 體驗比 Render 好；缺點是試用額度用完就沒了。所以建議：平常放 Render，重要 demo 前一週在 Railway 部署一份備用。

順帶一提，Back4App Containers 也免綁卡，但只有 256MB，可以拿來放 ssds-web（nginx 很省），後端還是放 Render。
-->

---
zoom: 0.72
---

# 附錄（進階）：用 CDS 加快冷啟動

把後端 Dockerfile 的**第二階段**換成這段（第一階段不變），啟動實測 0.1 CPU：600 → 394 秒；不限 CPU：31 → 18 秒

```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app \
 && mkdir -p /app/uploads && chown -R app:app /app
COPY --from=build --chown=app:app /src/ssds-api/build/libs/ssds.jar /tmp/ssds.jar
USER app
RUN java -Djarmode=tools -jar /tmp/ssds.jar extract --destination /app/extracted
# training run：只建立 Spring context 就結束；DB 指向 127.0.0.1，build 時不會去連 Supabase
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
這是給想再快一點的同學的進階做法，課堂上不一定要做。

CDS（Class Data Sharing）的原理：Spring Boot 啟動慢，很大一部分是在載入、解析、驗證幾萬個類別。CDS 讓我們在 docker build 的時候先「試跑」一次應用程式，把用到的類別整理成一個快取檔 app.jsa；之後真正啟動時直接讀這個快取，省掉大量 CPU 工作。

步驟三個：
1. java -Djarmode=tools extract：Spring Boot 官方的工具，把 fat jar 解開成適合 CDS 的結構。
2. training run：-Dspring.context.exit=onRefresh 讓 Spring 建好 context 就結束，-XX:ArchiveClassesAtExit 在結束時寫出快取檔。
3. ENTRYPOINT 加上 -XX:SharedArchiveFile 使用快取。

⚠️ training run 的重點：build 的時候沒有、也不應該有資料庫密碼（第八章：機密值不進 image）。所以我們用環境變數把 DB 指到 127.0.0.1、告訴 Hibernate 不要去讀資料庫的 metadata，這樣 build 過程完全不會碰到 Supabase。如果把 host 留著 Supabase 的網址，build 時會拿假密碼去連，連續的錯誤密碼有可能讓 Supabase 暫時封鎖你的 IP。

這份我實際 build 過、啟動過、也確認連得上 Supabase 讀到資料。代價是 build 多一分鐘左右、image 稍微大一點。
-->

---
layout: default
---

# 練習 1：方式 A — 讓 SSDS 上線
### 任務說明

1. 完成「部署前檢查清單」的 7 個項目，並把兩個 repo push 到 GitHub
2. 註冊 Render（GitHub 登入，Hobby 免費方案），授權兩個 repo
3. 建立 `ssds-api`：Docker、Singapore、Free、環境變數（含 `PORT=8080`、排程關閉）、Health Check Path
4. 確認 `https://<你的後端>/api/v1/actuator/health` 回 `{"status":"UP"}`
5. 建立 `ssds-web`：`PORT=80`、`API_URL=<你的後端網址>`
6. 用**手機**打開前端網址，登入並瀏覽商品頁
7. 改一行前端文字 → `git push` → 觀察 Render 自動重新部署，完成後重新整理確認

<!--
第一題就是今天的主線：把 SSDS 用方式 A 部署上去。

第 1 步請不要跳過，檢查清單每一項都打勾。

第 6 步用手機開，是要大家真正感受到「這個網址全世界都連得到」。

第 7 步體驗自動部署：只是 git push，雲端上的網站就更新了。

⚠️ 時間提醒：第一次 build 加冷啟動，兩個服務加起來可能要 20 到 30 分鐘，這段時間可以先看練習 2 的內容。
-->

---
layout: default
---

# 練習 1：解題提示
### 提示說明

```bash
# 檢查清單第 4 項：.env 沒進 Git
git -C ai-products-selection-backend ls-files | grep -i env     # 只該看到 .env.example

# 驗證後端（把網址換成你的）
curl https://ssds-api-xxxx.onrender.com/api/v1/actuator/health

# 驗證前端反向代理：從前端網址打後端 API
curl -I https://ssds-web-xxxx.onrender.com/api/v1/actuator/health
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 最後一行很重要：用<b>前端的網域</b>打 <code>/api/v1/actuator/health</code> 回 200，代表 nginx 反向代理 → 後端 → Supabase 整條通了。回 502 / 404 就對照疑難排解（二）。
</div>

<!--
提示的重點是最後一行：用前端的網址打後端的 health。這等於模擬瀏覽器的行為——請求先到 ssds-web 的 nginx，nginx 轉給 ssds-api。這行通了，前端畫面就一定能拿到資料。

遇到問題就照疑難排解的兩張表查：先看狀態碼，再看兩個服務的 Logs。
-->

---
layout: default
---

# 練習 2：方式 B — 自動化部署
### 任務說明

1. 確認 `myaccount/ssds-api`、`myaccount/ssds-web` 在 Docker Hub 上是 `linux/amd64`
2. 在 Render 用 **Existing Image** 建立 `ssds-api-img`（環境變數同練習 1），驗證 health 為 UP
3. 在 Docker Hub 建立 Read & Write 的 Access Token；在 Render 複製 `ssds-api-img` 的 Deploy Hook
4. 在後端 repo 加入 `.github/workflows/deploy.yml`，設定三個 GitHub Secrets
5. 修改任一支 Controller → push → 觀察：
   - GitHub **Actions** 執行成功（第二次 build 應該比第一次快很多，為什麼？）
   - Docker Hub 出現以 commit hash 命名的新 tag
   - Render **Events** 出現新部署，Image 是該 commit hash
6. **想一想**：如果新版有 bug，怎麼用最快的方式回到上一版？

<!--
第二題完整走一次業界標準的 CI/CD 流程。

第 2 步服務名稱用 ssds-api-img，跟練習 1 的分開，方便比較。⚠️ 注意兩個服務同時常駐會吃掉兩倍的免費時數，做完練習可以把其中一個 Suspend。

第 5 步「第二次 build 比較快」的原因：cache-from / cache-to type=gha 把 layer cache 存在 GitHub，第四章排好的「先複製 build.gradle、再複製原始碼」讓依賴那一層直接命中快取。

第 6 題答案：Render Events 頁面直接 Rollback；或者用 Deploy Hook 帶上一版的 commit hash 當 imgURL。因為每個版本都有獨一無二的 tag，回滾只是「指回去」而已。
-->

---
layout: default
---

# 練習 2：解題提示
### 提示說明

```bash
# 1. 確認架構
docker image inspect myaccount/ssds-api:1.0.0 --format '{{.Os}}/{{.Architecture}}'

# 3. 手動測試 Deploy Hook（先確認 hook 有效，再交給 GitHub Actions）
curl -fsS -X POST -G "<你的 Deploy Hook 網址>" \
  --data-urlencode "imgURL=docker.io/myaccount/ssds-api:1.0.0"

# 6. 用上一版的 commit hash 回滾
curl -fsS -X POST -G "<你的 Deploy Hook 網址>" \
  --data-urlencode "imgURL=docker.io/myaccount/ssds-api:<上一版的 commit sha>"
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>Actions 失敗常見原因：</b> Secret 名稱拼錯（大小寫有差）、Docker Hub Token 只有 Read 權限推不上去、workflow 檔放錯位置（一定要在 <code>.github/workflows/</code>）。
</div>

<!--
提示頁三個指令：確認架構、手動測 Deploy Hook、用 Deploy Hook 回滾。

建議先手動測一次 Deploy Hook，確定網址跟參數都對了，再交給 GitHub Actions。這是除錯的好習慣：先把自動化拆成手動步驟驗證，再組合起來。

Actions 失敗的話，點進那次執行，看是哪一步紅了，log 會寫得很清楚。
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
<tr><td>平台選擇</td><td>2026/10 免費免綁卡能跑 Spring Boot：<b>Render</b>（主力）、Railway（短期備案）</td></tr>
<tr><td>方式 A</td><td>GitHub + Dockerfile，Render 自己 build，push 自動部署</td></tr>
<tr><td>方式 B</td><td>Docker Hub image（amd64）+ GitHub Actions + Deploy Hook</td></tr>
<tr><td>共同設定</td><td><code>PORT</code>、環境變數（pooler、JWT secret、排程關閉）、Health Check Path</td></tr>
<tr><td>前後端串接</td><td>web 的 <code>API_URL</code> = 後端公開 https 網址（不加結尾斜線），同網域免 CORS</td></tr>
<tr><td>免費方案限制</td><td>0.1 CPU 冷啟動慢、閒置休眠、無持久化磁碟 — demo 前先叫醒</td></tr>
</tbody>
</table>

<!--
這一章的重點整理在表格裡。

我想特別強調「共同設定」那一列：不管方式 A 還是 B、不管 Render 還是 Railway，要設定的東西都一樣——port、環境變數、健康檢查。這三件事在本機 Docker 對應的是 -p、--env-file、healthcheck。學會了 Docker，換哪個平台都只是在找欄位。
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
<tr><th>章節</th><th>在 SSDS 上完成了什麼</th></tr>
</thead>
<tbody>
<tr><td>Ch1 Docker 簡介</td><td>理解 Container vs VM，跑起第一個 nginx</td></tr>
<tr><td>Ch2 映像檔管理</td><td>pull 基礎 image、理解 tag 與 layer</td></tr>
<tr><td>Ch3 容器操作</td><td>用官方 JRE image 跑起 <code>ssds.jar</code>，exec / logs 除錯</td></tr>
<tr><td>Ch4 Dockerfile</td><td>寫出 <code>ssds-api</code>、<code>ssds-web</code> 的 multi-stage Dockerfile</td></tr>
<tr><td>Ch5 Docker Compose</td><td>一行 <code>docker compose up</code> 拉起前後端 + healthcheck</td></tr>
<tr><td>Ch6 網路設定</td><td>nginx 反向代理 <code>/api</code>、用 pooler 連 Supabase</td></tr>
<tr><td>Ch7 Volume</td><td>商品圖片持久化、備份還原</td></tr>
<tr><td>Ch8 上線前準備</td><td>機密管理、tag 策略、推 Docker Hub、512MB 調校</td></tr>
<tr><td>Ch9 雲端部署</td><td><b>免費免綁卡上線，push 就自動部署</b></td></tr>
</tbody>
</table>

<div class="mt-2 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🎉 <b>恭喜完成全部 9 章！</b> 你的專案現在有一個全世界都連得到的網址。把它寫進履歷和專題報告吧。
</div>

<!--
九章課程走到這裡，我們一起回顧一下。

第一章我們跑起了一個什麼都沒有的 nginx；第三章用官方的 JRE image 跑起自己的 jar；第四章寫出了兩份正式的 Dockerfile；第五到七章用 Compose、網路、Volume 把整套系統在本機組起來；第八章做好上線前的準備；今天，SSDS 有了一個全世界都連得到的網址，而且 push 程式碼就會自動更新。

同一個專案，從「在我電腦上可以跑」，變成「在任何裝了 Docker 的機器、任何雲端平台上都能跑」。這就是容器化。

⚠️ 最後提醒三件事：密碼別進版控、image 別只靠 latest、部署前先在本機跑過。做到這三件事，就避開了新手最常踩的坑。

恭喜大家，把網址分享給你的家人朋友吧！
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對平台選擇、兩種部署方式、GitHub Actions，或是部署時遇到的錯誤，有沒有什麼疑問？都歡迎提出來討論。

如果部署卡住，把 Render Logs 的錯誤訊息貼出來，我們一起對照疑難排解的表格找原因。
-->
