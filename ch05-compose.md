---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: Docker Compose
routeAlias: ch05
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">Docker Compose</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「一份總譜，指揮所有容器同時上場」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
歡迎大家來到第五章，Docker Compose。前面幾章我們學會了用 docker run 操作單一容器，但真實的應用往往不會只有一個容器，這章就是要解決「同時管理很多容器」這件麻煩事。
-->

---
layout: default
---

# Outline

- **compose.yaml 語法結構**
- **docker compose 指令**
- **多容器應用範例（web + api，資料庫在 Supabase）**
- **練習題**：從簡單到進階
- **總結**

<!--
今天的路線圖：先搞懂 compose.yaml 怎麼寫，再學怎麼用指令操作它，最後把 SSDS 的前後端寫成一份完整的 compose.yaml，中間穿插兩題練習讓大家實際動手。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# compose.yaml 語法結構

<!--
先從設定檔本身開始，這是 Compose 的核心，之後所有指令都是圍繞這份檔案在動作。
-->

---

# 為什麼需要 Docker Compose？

- SSDS 跑起來至少要兩個容器：`ssds-web`、`ssds-api`，web 還要能把 `/api` 轉給 api
- 第三、四章我們用 `docker run` 逐一啟動：`--env-file`、`-p`、`-e API_URL=...`，還得記得**先等 api 啟動完成**再開網頁
- Docker Compose：「**define and manage multi-container apps in one YAML file, streamlining orchestration**」——用一份 YAML 檔案定義並管理多容器應用
- 比喻：Compose 如同「**樂團總譜**」，一次定義每個容器（樂手）用什麼映像檔（樂器）、跟誰同網路（合奏），再用 `docker compose` 指令統一啟動

<!--
這頁是動機頁，重點是讓大家有共鳴：手動 docker run 管理多容器很痛。

請大家回想第三、四章的 docker run，每一行都又臭又長，還有那個 host.docker.internal。而且真實情況更麻煩：組員 clone 專案下來，你要他先 build 兩個 image、照順序 run、記得帶 .env，Spring Boot 啟動要十幾秒，太早開網頁就看到 502。

這章之後，這一切變成一個指令：docker compose up -d --build。組員 clone 完專案打這一行，整套環境就起來了。

生活比喻就是樂團總譜，一份譜勝過口頭一個一個交代。
-->

---

# 什麼是 compose.yaml？

| 項目 | 說明 |
| --- | --- |
| 檔案格式 | YAML（YAML Ain't Markup Language） |
| 建議檔名 | `compose.yaml`（新版推薦寫法） |
| 舊版相容檔名 | `docker-compose.yml`（仍可使用，Compose 會自動辨識） |
| 核心概念 | 一份檔案描述多個 Service、Network、Volume |
| 執行方式 | `docker compose` 讀取此檔案並依定義建立資源 |
| SSDS 放哪裡 | 前後端兩個 repo 的**上一層**：`ai-products-selection/compose.yaml` |

> ⚠️ **版本注意**：Docker Compose 目前是 Docker CLI 的內建 plugin（v2），指令一律是空格分隔的 `docker compose`，不是舊版獨立執行檔的 `docker-compose`（中間有連字號）。

<!--
這頁把命名跟版本差異講清楚。⚠️ 版本注意：docker compose（v2，內建 plugin）vs docker-compose（v1，獨立執行檔，已經停止維護）。易錯點是很多人複製貼上舊文章的指令會噴「command not found」。

compose.yaml 放哪裡？我們前後端是兩個獨立的 Git repo，所以 compose.yaml 放在兩者的共同上一層資料夾，用相對路徑指到兩邊的 Dockerfile：

```
ai-products-selection/
├── compose.yaml
├── ai-products-selection-backend/   (Dockerfile、.env)
└── ai-products-selection-frontend/  (Dockerfile、nginx/)
```

如果組員希望這份檔案也進版控，可以放進後端 repo，路徑改成 ../ai-products-selection-frontend，概念完全一樣。
-->

---

# compose.yaml 的三大區塊

| 區塊 | 用途 | 常見欄位 |
| --- | --- | --- |
| `services` | 定義每個容器要跑什麼 | `image`, `build`, `ports`, `environment`, `env_file`, `depends_on`, `healthcheck` |
| `networks` | 定義容器之間的通訊網路 | `driver`, `name` |
| `volumes` | 定義資料持久化的儲存空間 | `driver`, `name` |

「**一個 service 就是一個會被跑起來的容器（或一組容器）**」，services 底下每一個 key 就是一個服務名稱，這個名稱同時也會是容器在內部網路裡的主機名稱（hostname），這點在第三部分 web 連 api 時會很重要。

<!--
這頁介紹 compose.yaml 的三大區塊：services、networks、volumes。

重點是 services 底下的 key（接下來範例裡的 api 跟 web）之後會變成容器互相連線的主機名稱，這是 Compose 網路的核心概念，大家先有印象，第三部分會實際用到。
-->

---

# — 範例

```yaml
# ai-products-selection/compose.yaml（骨架）
name: ssds

services:
  api:
    image: ssds-api:1.0.0
    ports:
      - "8080:8080"
  web:
    image: ssds-web:1.0.0
    ports:
      - "8000:80"

networks:
  default:
    driver: bridge

volumes:
  ssds-uploads:
```

<!--
這頁給一個最小的骨架，對照剛剛講的三大區塊：兩個 service、一個 network、一個 volume。

最上面的 `name: ssds` 是專案名稱，Compose 建出來的容器、網路、volume 都會帶這個前綴，例如容器叫 ssds-api-1。沒寫的話預設用資料夾名稱 ai-products-selection，又長又容易跟別人撞名。

這份還很陽春：api 沒有帶 .env、web 也還不知道 api 在哪，volume 也只是宣告還沒掛上去。我們第三部分會把它補完整。

⚠️ 易錯點：YAML 對縮排非常敏感，縮排一定要用空格不能用 tab，層級錯一格整份檔案就解析失敗。
-->

---

# YAML 語法基本規則

| 規則 | 說明 | 範例 |
| --- | --- | --- |
| 縮排代表階層 | 用「空格」縮排，禁止用 Tab | `services:` 底下要縮排 |
| `key: value` | 冒號後面要留一個空格 | `image: nginx` |
| 清單（list） | 用 `-` 開頭表示陣列元素 | `ports: \n  - "80:80"` |
| 字串可省略引號 | 但含特殊字元建議加引號 | `"8080:80"` |
| 註解 | 用 `#` 開頭 | `# 這是註解` |

> ⚠️ 冒號後面沒空格、或用 Tab 縮排，都是新手最常踩的兩個地雷，Compose 會直接報 YAML 解析錯誤。

<!--
這頁純粹補基本功，雖然大家寫 Spring Boot 可能看過 application.yml，但專案用的是 properties，有些同學是第一次接觸 YAML。生活比喻：YAML 就像整理衣櫃分層放，同一層要對齊，亂放（縮排錯）東西就找不到。易錯點 ⚠️ 已經標在頁面上：Tab 縮排跟冒號少空格是最常見兩個錯誤，出錯訊息通常會直接告訴我們是第幾行。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# docker compose 指令

<!--
設定檔寫好了，接下來就是怎麼用指令去操作它，這部分跟我們之前學的 docker 指令邏輯很像，只是操作對象從單一容器變成整份 compose.yaml 裡的所有服務。
-->

---

# 常用 docker compose 指令

| 指令 | 用途 | 常用參數 |
| --- | --- | --- |
| `docker compose up` | 建立並啟動所有服務 | `-d`（背景執行）、`--build` |
| `docker compose down` | 停止並移除容器、網路 | `-v`（連 Volume 一起刪除） |
| `docker compose logs` | 查看服務的輸出紀錄 | `-f`（持續追蹤）、`--tail` |
| `docker compose ps` | 列出目前執行中的服務（含健康狀態） | — |
| `docker compose build` | 重新建構服務的映像檔 | — |
| `docker compose exec` | 進入執行中的容器下指令 | `<service> <command>` |

「**docker compose up 會一次讀完 compose.yaml，照著依賴順序把 network、volume、所有 service 都建立並啟動**」，這就是總譜一次指揮全體上場的概念。

---

# — 範例

```bash
# 在 ai-products-selection/ 底下：背景啟動所有服務，需要時重新建置映像檔
docker compose up -d --build

# 看服務狀態：STATUS 欄會顯示 (healthy) / (health: starting)
docker compose ps

# 即時追蹤所有服務的日誌（兩個服務的 log 會交錯顯示，各有顏色）
docker compose logs -f

# 只看 api 服務最後 50 行日誌
docker compose logs --tail 50 api

# 進 api 容器看環境變數（不用管容器全名叫什麼）
docker compose exec api env | grep SSDS_DB_HOST

# 只重新建置並重啟 api（改完 Java 之後最常打的一行）
docker compose up -d --build api

# 停止並移除容器、網路（保留 volume）
docker compose down
```

<!--
這兩頁一組，先表格再範例。重點指令是 up / down / logs。

請大家特別記住 `docker compose up -d --build api` 這一行，這是容器化開發的日常節奏：改完 Controller、存檔、打這一行，Compose 只會重 build 跟重啟 api 這個服務，前端完全不動。比起 down 再 up 整套快非常多。

`docker compose exec api ...` 注意它接的是「服務名稱 api」，不是容器全名。Compose 會自動幫容器加上專案名稱前綴（例如 ssds-api-1），用 docker exec 就得打全名，用 compose exec 打 api 就好。

`docker compose ps` 的 STATUS 欄位，等一下加了 healthcheck 之後會多顯示 healthy 或 starting，很好用。

易錯點 ⚠️：docker compose down 預設不會刪除 volume，這是刻意設計避免誤刪資料；真的要清空重來才加 -v。
-->

---

# 使用 docker compose 的注意事項

| 情境 | 說明 |
| --- | --- |
| 指令找不到 | 確認用的是 `docker compose`（有空格），不是舊版 `docker-compose` |
| 找不到 compose.yaml | 要在 compose.yaml 所在的資料夾執行，或用 `-f` 指定路徑 |
| 修改 compose.yaml 後沒生效 | 重新執行 `docker compose up -d`，Compose 會只重建有變動的服務 |
| 服務啟動但立刻結束 | 用 `docker compose logs <service>` 查看錯誤訊息 |
| Port 衝突 | 8080 被 IDE 的 Spring Boot 佔用時，先關掉 IDE 的或改 `ports` |

> ⚠️ **版本注意**：`docker compose`（v2, plugin）已內建在新版 Docker Desktop / Docker Engine 裡，不需要額外安裝；舊版獨立執行檔 `docker-compose`（v1）已經停止維護。

<!--
這頁整理常見的踩雷情境，讓大家遇到問題時知道第一步該查什麼。

我們專案特別容易遇到的是 port 衝突：大家平常在 IntelliJ 跑後端就是佔 8080，忘了關就 docker compose up，api 會報 port is already allocated。

⚠️ 版本注意再次強調：一律用 docker compose（v2），避免大家去抄網路上舊教學的 docker-compose 指令而卡住。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 多容器應用範例（web + api）

<!--
現在把前面學的語法跟指令串起來，把 SSDS 的前後端寫成一份完整的 compose.yaml。

資料庫呢？我們的資料庫在 Supabase 雲端，所以 Compose 裡「不需要」db 服務，api 透過環境變數直接連出去就好。這也是現代專案很常見的架構。
-->

---

# 服務間如何互相連線？

「**同一個 compose.yaml 裡的所有 service，預設會被放進同一個內部網路，彼此可以用『服務名稱』當作主機名稱互相溝通**」，不需要知道對方的 IP，也不需要額外設定。

例如後端 service 命名為 `api`，前端 nginx 的轉發目標就直接寫 `http://api:8080`，Compose 內建 DNS 會自動解析成正確的容器 IP。第四章那個 `host.docker.internal:8080` 到這裡終於可以退場了。

| 概念 | 說明 |
| --- | --- |
| 內部網路 | Compose 預設自動建立一個 network，所有 service 都加入 |
| 主機名稱解析 | service 名稱 = 容器的 hostname，可直接用來連線 |
| 對外開放 | 只有設定 `ports` 的 service 才能被主機外部存取 |
| 對外連線 | 容器可以直接連網際網路（Supabase、Mistral API），不需要額外設定 |

<!--
這頁是這一部分最重要的觀念：service 名稱就是 DNS 名稱。生活比喻延續樂團總譜，每個樂手（容器）都有自己的譜號（服務名稱），總譜上寫「小提琴呼應鋼琴」，樂手之間看譜號就知道要跟誰合奏，不用另外查對方站在哪裡（IP）。

最後一列補充：容器「往外連」是預設就可以的，所以 api 連 Supabase、連 Mistral API 都不用特別設定；需要設定的是「外面連進來」，也就是 ports。

易錯點 ⚠️：很多新手會把 API_URL 寫成 http://localhost:8080，這是錯的，因為在 web 容器裡，localhost 是 web 容器自己，nginx 會轉給自己然後回 502。要連別的容器一定要寫對方的 service 名稱。
-->

---
zoom: 0.79
---

# 完整範例：SSDS 前後端

```yaml
# ai-products-selection/compose.yaml
name: ssds

services:
  api:                                       # Spring Boot（ssds-api）
    build: ./ai-products-selection-backend
    image: ssds-api:1.0.0
    ports: ["8080:8080"]
    env_file: ./ai-products-selection-backend/.env   # SSDS_DB_*、MISTRAL_API_KEY…
    environment:
      SPRING_PROFILES_ACTIVE: prod
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/api/v1/actuator/health"]
      interval: 10s
      timeout: 5s
      start_period: 90s
      retries: 5

  web:                                       # Angular + nginx（ssds-web）
    build: ./ai-products-selection-frontend
    image: ssds-web:1.0.0
    ports: ["8000:80"]
    environment:
      API_URL: http://api:8080               # 用服務名稱連 api
    depends_on:
      api: { condition: service_healthy }    # 等 api 真的健康再啟動
```

<!--
這份就是 SSDS 的 compose.yaml，大家之後本機整合測試都會用它。我們一個服務一個服務看。

api：
- `build` 指向後端資料夾，Compose 會用裡面第四章寫好的 Dockerfile 現場建置。同時寫了 `image: ssds-api:1.0.0`，意思是 build 出來的 image 就叫這個名字，第八章推到 Docker Hub 時會用到。
- `env_file` 就是第三章 `--env-file` 的 Compose 版，把後端 .env 裡的 Supabase 連線、Mistral key 都帶進去。注意這個路徑是相對於 compose.yaml 的。
- `environment` 可以額外加或覆蓋變數，這裡把 profile 設成 prod。
- `healthcheck` 用第四章加的 actuator：每 10 秒用 wget 問一次 /api/v1/actuator/health。`start_period: 90s` 是寬限期——實測 SSDS 在一般筆電上啟動約 30 秒，慢的電腦會更久，這段時間失敗不算數，避免剛開機就被判定不健康。

web：
- `API_URL: http://api:8080`：這就是第四章 nginx 設定檔裡的 ${API_URL}。api 是上面那個服務名稱，8080 是容器內的 port。
- `depends_on` 加 `condition: service_healthy`：Compose 會等到 api 的 healthcheck 通過，才啟動 web。解決了「網頁先好、後端還沒好，使用者看到 502」的問題。

⚠️ 為什麼 healthcheck 用 wget 不用 curl？因為 eclipse-temurin alpine 版沒有 curl，只有 busybox 內建的 wget。寫 curl 的話健康檢查會永遠失敗，容器一直是 unhealthy。

預期結果：docker compose ps 會看到 api 從 health: starting 變成 healthy，接著 web 才啟動；打開 localhost:8000 就是完整的 SSDS。
-->

---

# 使用多容器範例的注意事項

| 情境 | 說明 |
| --- | --- |
| `depends_on` 的限制 | 單純列服務名稱只保證「容器啟動」，不保證 Spring Boot 已就緒；要搭配 `condition: service_healthy` |
| api 一直 unhealthy | 先 `docker compose logs api`：多半是 `.env` 沒帶到、Supabase 密碼錯，或 health 路徑少了 `/api/v1` |
| web 回 502 Bad Gateway | nginx 連不到 api：檢查 `API_URL` 是不是寫成 `localhost`、api 是否還在啟動 |
| `env_file` 路徑 | 相對於 **compose.yaml 所在目錄**，不是相對於 build 目錄 |
| 改了 Java 沒生效 | `docker compose up -d` 不會自動重 build，要加 `--build` |

> ⚠️ `env_file` 只把值帶進容器，`.env` 本身沒有進 image，也沒有進 compose.yaml 的版控 — 機密值的管理第八章會再完整整理。

<!--
這頁補強實務眉角。

⚠️ 易錯點一：depends_on 如果只寫服務名稱，它只管「容器有沒有啟動」，不管「Spring Boot 有沒有準備好」。java 行程一啟動容器就算 running 了，但 Tomcat 要十幾秒後才開始聽 8080。

⚠️ 易錯點二：api 一直 unhealthy，九成是三個原因之一：env_file 路徑寫錯所以沒有密碼、Supabase 密碼本身錯、healthcheck 的網址漏了 context-path。用 docker compose logs api 一看就知道是哪一個。

⚠️ 易錯點三特別提醒 Java 同學：`docker compose up -d` 看到 image 已經存在就不會重 build，所以你改了 Java 檔重新 up，跑的還是舊版程式。改了程式碼一定要加 --build。
-->

---

# 練習題一：任務說明

**難度：基礎**

先把第四章 build 好的 `ssds-api:1.0.0` 從 `docker run` 搬進 Compose。在 `ai-products-selection/` 下寫一份 `compose.yaml`：

1. 一個叫 `api` 的服務，使用 `ssds-api:1.0.0` 映像檔（**不用 build**）
2. 主機 `8080` 對應到容器 `8080`
3. 用 `env_file` 帶入後端的 `.env`，並另外設定 `SPRING_PROFILES_ACTIVE=dev`
4. `docker compose up -d` 啟動後，用 `docker compose logs -f api` 等到 `Started SsdsApplication`
5. 用 `docker compose exec api wget -qO- http://localhost:8080/api/v1/actuator/health` 確認回 `{"status":"UP"}`
6. 對照一下：這份 YAML 跟第四章那行 `docker run`，內容其實一模一樣

<!--
第一題基礎，練習 services 底下常用欄位、ports 映射、env_file 的寫法。

第 3 步故意設成 dev profile，讓大家在 log 裡看到 Hibernate 印出的 SQL，順便確認 environment 可以覆蓋 image 裡 ENV 的預設值（第四章 Dockerfile 預設是 prod）。

第 6 步是這題真正的用意：讓大家自己把 docker run 跟這份 YAML 逐項對照——-p 變成 ports、--env-file 變成 env_file、-e 變成 environment。Compose 不是新東西，只是把同樣的參數換個地方寫，而且寫在檔案裡可以進版控、組員 clone 下來就能用。
-->

---

# 練習題一：解題提示

```yaml
name: ssds
services:
  api:
    image: ssds-api:1.0.0
    ports:
      - "8080:8080"
    env_file: ./ai-products-selection-backend/.env
    environment:
      SPRING_PROFILES_ACTIVE: dev
```

啟動與驗證：

```bash
docker compose up -d
docker compose ps
docker compose logs api | grep "Started SsdsApplication"
docker compose exec api wget -qO- http://localhost:8080/api/v1/actuator/health
```

<!--
提示頁給完整解答，重點提醒 ports 的寫法是「主機 port : 容器 port」，順序不能顛倒。

⚠️ 易錯點一：env_file 的路徑是相對於 compose.yaml，我們的 compose.yaml 在上一層，所以要寫 ./ai-products-selection-backend/.env。⚠️ 易錯點二：ports 的值一定要加引號寫成字串，因為 YAML 會把某些沒引號的 `xx:yy` 當成六十進位數字解析，這是 YAML 的經典陷阱。

預期結果：compose ps 顯示 api 是 running，health 回 UP。如果回 DOWN，通常是連不到 Supabase，看 log 裡的 HikariPool 錯誤訊息。
-->

---

# 練習題二：任務說明

**難度：進階**

把 SSDS 前後端寫成一份完整的 `compose.yaml`：

1. `api` 服務：用 `build: ./ai-products-selection-backend` 建置，image 命名為 `ssds-api:1.0.0`，對外開 `8080:8080`，帶入 `.env`
2. `web` 服務：用 `build: ./ai-products-selection-frontend` 建置，image 命名為 `ssds-web:1.0.0`，對外開 `8000:80`
3. web 透過**服務名稱**把 `/api` 轉給後端（不准出現 `localhost` 或 `host.docker.internal`）
4. 幫 `api` 加上 healthcheck，並讓 `web` 等到 `api` 健康之後才啟動
5. 驗證：打開 `http://localhost:8000` 登入，畫面能載入商品資料
6. 修改任一支 Controller 的回應文字，**只重建 api**，確認 web 容器沒有被重啟（看 `docker compose ps` 的 CREATED 欄）

<!--
第二題整合本章所有重點：build、多服務、服務名稱連線、healthcheck、env_file。

第 3 點我特別禁止 localhost，因為這是最多人犯的錯：在 web 容器裡，localhost 是 nginx 自己。

第 5 點是端到端驗收，瀏覽器 → web 的 nginx → 反向代理到 api → api 連 Supabase 查資料 → 一路回來。能看到資料，代表整條鏈都通了。

第 6 點練習日常開發節奏：docker compose up -d --build api。
-->

---
zoom: 0.91
---

# 練習題二：解題提示

```yaml
name: ssds
services:
  api:
    build: ./ai-products-selection-backend
    image: ssds-api:1.0.0
    ports: ["8080:8080"]
    env_file: ./ai-products-selection-backend/.env
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/api/v1/actuator/health"]
      interval: 10s
      timeout: 5s
      start_period: 90s
      retries: 5
  web:
    build: ./ai-products-selection-frontend
    image: ssds-web:1.0.0
    ports: ["8000:80"]
    environment:
      API_URL: http://api:8080
    depends_on:
      api: { condition: service_healthy }
```

```bash
docker compose up -d --build      # 第一次要 build 兩個 image，會比較久
docker compose up -d --build api  # 第 6 題：只重建 api
```

<!--
提示頁對照第三部分的完整範例，重點複習三件事：API_URL 的 host 寫服務名稱 api、port 用容器內的 8080；healthcheck 路徑要有 /api/v1；depends_on 用 service_healthy。

⚠️ 易錯點：如果 healthcheck 寫錯，api 永遠是 unhealthy，web 就永遠不會啟動，docker compose up 會報 dependency failed to start。這時候先用 docker compose exec api wget 手動打一次健康檢查網址，確認路徑對不對。

預期結果：第 6 步之後 docker compose ps 會看到 api 的 CREATED 是幾秒前，web 還是幾分鐘前。

最後留一個問題給大家想：現在上傳一張商品圖片，然後 docker compose down 再 up，圖片還在嗎？第七章揭曉。
-->

---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — Docker Compose

<table class="summary-table">
<thead>
<tr><th>主題</th><th>重點回顧</th></tr>
</thead>
<tbody>
<tr><td>compose.yaml</td><td>一份 YAML 檔案定義 services / networks / volumes，放在前後端 repo 的上一層</td></tr>
<tr><td>版本</td><td>一律用 <code>docker compose</code>（v2 plugin），不用舊版 <code>docker-compose</code></td></tr>
<tr><td>核心指令</td><td><code>up -d --build</code>、<code>down</code>、<code>logs -f</code>、<code>ps</code>、<code>exec</code></td></tr>
<tr><td>服務連線</td><td>同網路下用「服務名稱」互相連線：<code>API_URL=http://api:8080</code></td></tr>
<tr><td>機密值</td><td><code>env_file</code> 帶入 <code>.env</code>，不寫死在 yaml</td></tr>
<tr><td>啟動順序</td><td>Actuator healthcheck + <code>depends_on: condition: service_healthy</code></td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入網路設定，拆解 web → api 的反向代理，以及容器怎麼連到外面的 Supabase。
</div>

<!--
總結這一章：Compose 解決的核心痛點是「多容器協作」，我們學了 YAML 語法、compose.yaml 三大區塊、核心指令，也把 SSDS 整套寫成一份 compose.yaml。

下一章會接著談網路設定的細節：為什麼 api 這個名字解析得到、nginx 反向代理到底在做什麼、容器怎麼連到外面的 Supabase。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對 compose.yaml 的語法結構、up/down/logs 這些指令，或是 healthcheck、depends_on 的寫法，有沒有什麼疑問？都歡迎提出來討論。
-->
