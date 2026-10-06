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
    「以一份設定檔，管理整個多容器應用」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
【開場白】
本章主題是 Docker Compose。前幾章以 docker run 操作單一容器，但實際的應用通常由多個容器組成。

【學習目標】
- 撰寫 compose.yaml，以 services / networks / volumes 描述多容器應用
- 使用 docker compose 指令統一管理所有服務
- 以 healthcheck 與 depends_on 控制 SSDS 前後端的啟動順序
-->

---
layout: default
---

# Outline

- **compose.yaml 語法結構**
- **docker compose 指令**
- **多容器應用範例**
  - web + api，資料庫位於 Supabase
- **實作練習**

<!--
【帶讀大綱】
本章分為三個部分：第一部分介紹 compose.yaml 的寫法；第二部分介紹 docker compose 指令；第三部分將 SSDS 前後端寫成完整的 compose.yaml。

【重點預告】
最後兩題練習：先將單一服務搬入 Compose，再完成前後端整合。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# compose.yaml 語法結構

<!--
【段落轉換】
第一部分介紹 Compose 的核心：compose.yaml 設定檔。後續所有指令都以此檔案為操作對象。
-->

---

# 為什麼需要 Docker Compose？

- SSDS 至少需要兩個容器：`ssds-web`、`ssds-api`，且 web 須將 `/api` 轉送至 api
- 第三、四章以 `docker run` 逐一啟動：需指定 `--env-file`、`-p`、`-e API_URL=...`，並須**等 api 啟動完成**後才能使用網頁
- **Docker Compose** 以一份 YAML 檔定義並管理多容器應用，以 `docker compose` 指令統一啟動與停止

<!--
【問題引導】
回顧第三、四章：每個 docker run 指令都很長，還需指定 host.docker.internal。組員 clone 專案後，必須先建置兩個 Image、依序啟動、記得帶入 .env；Spring Boot 啟動需十數秒，過早開啟網頁會看到 502。

【生活化比喻】
Compose 如同樂團總譜：一份總譜定義每位樂手（容器）使用的樂器（Image）與合奏對象（網路），取代逐一口頭交代。

【核心說明】
使用 Compose 後，上述步驟簡化為一行指令：`docker compose up -d --build`。組員 clone 專案後執行此指令，即可啟動完整環境。
-->

---

# 什麼是 compose.yaml？

| 項目 | 說明 |
| --- | --- |
| 檔案格式 | YAML |
| 建議檔名 | `compose.yaml` |
| 相容檔名 | `docker-compose.yml`（仍可辨識） |
| 核心概念 | 一份檔案描述多個 Service、Network、Volume |
| 執行方式 | `docker compose` 讀取此檔案並建立對應資源 |
| SSDS 位置 | 前後端兩個 repo 的**上一層**：`ai-products-selection/compose.yaml` |

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <b>版本：</b>Docker Compose v2 為 Docker CLI 的內建 plugin，指令為 <code>docker compose</code>（空格）；舊版獨立執行檔 <code>docker-compose</code>（v1）已於 2023 年停止維護。
</div>

<!--
【重點解說】
SSDS 的前後端為兩個獨立的 Git repo，因此 compose.yaml 放在兩者共同的上一層資料夾，以相對路徑指向兩邊的 Dockerfile：

```
ai-products-selection/
├── compose.yaml
├── ai-products-selection-backend/   (Dockerfile、.env)
└── ai-products-selection-frontend/  (Dockerfile、nginx/)
```

若希望將此檔案納入版本控制，可放入後端 repo，並將前端路徑改為 ../ai-products-selection-frontend，概念相同。

【易錯點提醒 ⚠️】
複製舊文章中的 docker-compose 指令常出現 command not found，應改用 docker compose。另外 compose.yaml 頂端的 `version:` 欄位已廢止，不需撰寫，寫了會出現 obsolete 警告。
-->

---

# compose.yaml 的三大區塊

| 區塊 | 用途 | 常見欄位 |
| --- | --- | --- |
| `services` | 定義每個容器的執行內容 | `image`, `build`, `ports`, `environment`, `env_file`, `depends_on`, `healthcheck` |
| `networks` | 定義容器之間的通訊網路 | `driver`, `name` |
| `volumes` | 定義資料持久化的儲存空間 | `driver`, `name` |

`services` 下的每個 key 為一個服務名稱；該名稱同時是容器在內部網路中的主機名稱（hostname）。

<!--
【重點解說】
services 下的 key（後續範例中的 api 與 web）會成為容器互相連線時使用的主機名稱，這是 Compose 網路的核心概念，於第三部分實際使用。
-->

---

# compose.yaml — 骨架範例

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
【帶讀關鍵行】
- `name: ssds`：專案名稱。Compose 建立的容器、網路、volume 都會加上此前綴，例如容器名稱為 ssds-api-1。未設定時預設使用資料夾名稱 ai-products-selection，名稱冗長且容易衝突。
- 骨架對應三大區塊：兩個 service、一個 network、一個 volume。

【重點提醒】
此骨架尚未完整：api 未帶入 .env、web 尚不知道 api 的位置、volume 只有宣告尚未掛載。第三部分將補齊。

【易錯點提醒 ⚠️】
YAML 對縮排敏感，必須使用空格縮排，不可使用 Tab；層級錯誤會導致整份檔案解析失敗。
-->

---

# YAML 語法基本規則

| 規則 | 說明 | 範例 |
| --- | --- | --- |
| 縮排代表階層 | 使用空格縮排，不可使用 Tab | `services:` 下一層須縮排 |
| `key: value` | 冒號後須有一個空格 | `image: nginx` |
| 清單（list） | 以 `-` 開頭表示陣列元素 | `ports:` 下一行 `- "80:80"` |
| 字串引號 | 可省略，含特殊字元時建議加引號 | `"8080:80"` |
| 註解 | 以 `#` 開頭 | `# 註解` |

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ 冒號後缺少空格、使用 Tab 縮排，是最常見的兩種 YAML 解析錯誤。
</div>

<!--
【重點解說】
專案的 Spring Boot 設定使用 properties 格式，部分學生可能是第一次接觸 YAML，本頁補充基本規則。

【生活化比喻】
YAML 如同分層整理的衣櫃，同一層必須對齊；縮排錯誤就如同物品放錯層，無法被找到。

【操作提示】
發生解析錯誤時，錯誤訊息通常會指出行號，依行號檢查縮排與冒號即可。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# docker compose 指令

<!--
【段落轉換】
第二部分介紹 docker compose 指令。邏輯與先前的 docker 指令相近，差別在於操作對象由單一容器變為 compose.yaml 中的所有服務。
-->

---

# 常用 docker compose 指令

| 指令 | 用途 | 常用參數 |
| --- | --- | --- |
| `docker compose up` | 建立並啟動所有服務 | `-d`（背景執行）、`--build`（重新建置） |
| `docker compose down` | 停止並移除容器與網路 | `-v`（一併刪除 Volume） |
| `docker compose logs` | 查看服務輸出 | `-f`（持續追蹤）、`--tail` |
| `docker compose ps` | 列出服務狀態（含健康狀態） | — |
| `docker compose build` | 重新建置服務的 Image | — |
| `docker compose exec` | 在執行中的服務容器內執行指令 | `<service> <command>` |

`docker compose up` 讀取 compose.yaml，依相依順序建立 network、volume 與所有 service 並啟動。

<!--
【重點解說】
最常用的指令為 up、down、logs。操作時使用的是 compose.yaml 中的「服務名稱」，而非容器全名。
-->

---

# docker compose 指令 — 範例

```bash
# 在 ai-products-selection/ 下：背景啟動所有服務，必要時重新建置 Image
docker compose up -d --build

# 查看服務狀態：STATUS 欄顯示 (healthy) / (health: starting)
docker compose ps

# 持續追蹤所有服務的 log（不同服務以不同顏色區分）
docker compose logs -f

# 只看 api 服務最後 50 行
docker compose logs --tail 50 api

# 在 api 容器中檢查環境變數（使用服務名稱，不需容器全名）
docker compose exec api env | grep SSDS_DB_HOST

# 只重新建置並重啟 api（修改 Java 後最常用）
docker compose up -d --build api

# 停止並移除容器與網路（保留 volume）
docker compose down
```

<!--
【帶讀關鍵行】
- `docker compose up -d --build api`：容器化開發的日常流程。修改 Controller 後執行此指令，Compose 只重新建置並重啟 api，前端不受影響，比 down 再 up 快得多。
- `docker compose exec api ...`：接的是服務名稱 api。Compose 會為容器加上專案前綴（例如 ssds-api-1），使用 docker exec 必須輸入全名，使用 compose exec 只需輸入 api。
- `docker compose ps`：加入 healthcheck 後，STATUS 欄會顯示 healthy 或 starting。

【易錯點提醒 ⚠️】
docker compose down 預設不刪除 volume，以避免誤刪資料；需要完全清除時才加 -v。

【補充】
開發時亦可使用 `docker compose watch`，在原始碼變更時自動重新建置或同步檔案，需在 compose.yaml 中設定 `develop.watch`。
-->

---

# 使用 docker compose 的注意事項

| 情境 | 說明 |
| --- | --- |
| 指令找不到 | 確認使用 `docker compose`（空格），而非 `docker-compose` |
| 找不到 compose.yaml | 須在 compose.yaml 所在目錄執行，或以 `-f` 指定路徑 |
| 修改 compose.yaml 後未生效 | 重新執行 `docker compose up -d`，Compose 只會重建有變動的服務 |
| 服務啟動後立即結束 | 以 `docker compose logs <service>` 查看錯誤訊息 |
| Port 衝突 | 8080 被 IDE 中的 Spring Boot 佔用時，先關閉該程式或修改 `ports` |

<!--
【業界實務】
SSDS 最常遇到 port 衝突：在 IntelliJ 執行後端時佔用 8080，若未關閉即執行 docker compose up，api 會出現 port is already allocated。

【重點提醒】
一律使用 docker compose（v2），避免沿用網路舊教學中的 docker-compose 指令。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 多容器應用範例（web + api）

<!--
【段落轉換】
第三部分整合前述語法與指令，將 SSDS 前後端寫成完整的 compose.yaml。

【重點提醒】
資料庫位於 Supabase，Compose 中不需要 db 服務，api 以環境變數直接連線即可。這也是現代專案常見的架構。
-->

---

# 服務之間如何連線？

同一份 compose.yaml 中的所有 service 預設加入同一個內部網路，彼此可以**服務名稱**作為主機名稱連線，不需知道對方 IP。

例如後端服務命名為 `api`，前端 nginx 的轉送目標即為 `http://api:8080`，由 Compose 內建 DNS 解析為容器 IP。第四章使用的 `host.docker.internal:8080` 不再需要。

| 概念 | 說明 |
| --- | --- |
| 內部網路 | Compose 預設建立一個 network，所有 service 皆加入 |
| 主機名稱解析 | service 名稱即為容器的 hostname |
| 對外開放 | 只有設定 `ports` 的 service 可從主機存取 |
| 對外連線 | 容器可直接連線網際網路（Supabase、Mistral API），不需額外設定 |

<!--
【生活化比喻】
延續樂團總譜：每位樂手有自己的譜號（服務名稱），總譜上註明合奏對象，樂手依譜號即可找到對方，不需知道對方的座位（IP）。

【核心說明】
容器對外連線為預設允許，因此 api 連線 Supabase、Mistral API 皆不需設定；需要設定的是外部連入，也就是 ports。

【易錯點提醒 ⚠️】
API_URL 不可寫成 http://localhost:8080。在 web 容器中，localhost 指的是 web 容器自身，nginx 會轉送給自己並回傳 502。連線其他容器時必須使用對方的服務名稱。
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
      start_interval: 5s
      retries: 5

  web:                                       # Angular + nginx（ssds-web）
    build: ./ai-products-selection-frontend
    image: ssds-web:1.0.0
    ports: ["8000:80"]
    environment:
      API_URL: http://api:8080               # 以服務名稱連線 api
    depends_on:
      api: { condition: service_healthy }    # 等 api 健康檢查通過後才啟動
```

<!--
【帶讀關鍵行】
api：
- `build`：指向後端資料夾，使用第四章的 Dockerfile 建置。同時設定 `image: ssds-api:1.0.0`，建置產生的 Image 即以此命名，第八章推送至 Docker Hub 時使用。
- `env_file`：即第三章 `--env-file` 的 Compose 寫法，帶入 Supabase 連線與 Mistral key。路徑相對於 compose.yaml。
- `environment`：額外設定或覆蓋變數，此處將 profile 設為 prod。
- `healthcheck`：使用第四章加入的 actuator，每 10 秒以 wget 檢查一次 /api/v1/actuator/health。`start_period: 90s` 為啟動寬限期：SSDS 在一般筆電上約 30 秒啟動完成，較慢的電腦更久，寬限期內的失敗不計入 retries。`start_interval: 5s` 讓寬限期內每 5 秒檢查一次，服務就緒後能更快被判定為 healthy（需 Docker Engine 25 以上）。

web：
- `API_URL: http://api:8080`：對應第四章 nginx 設定檔中的 ${API_URL}；api 為服務名稱，8080 為容器內 port。
- `depends_on` + `condition: service_healthy`：Compose 等 api 的 healthcheck 通過後才啟動 web，避免網頁就緒而後端尚未就緒時出現 502。

【易錯點提醒 ⚠️】
healthcheck 使用 wget 而非 curl，因為 eclipse-temurin 的 alpine 版不含 curl，只有 busybox 內建的 wget。若寫成 curl，健康檢查會持續失敗，容器始終為 unhealthy。

【預期結果】
docker compose ps 顯示 api 由 health: starting 轉為 healthy，之後 web 才啟動；開啟 localhost:8000 即為完整的 SSDS。
-->

---

# 多容器範例的注意事項

| 情境 | 說明 |
| --- | --- |
| `depends_on` 的限制 | 只列服務名稱時僅保證容器已啟動，不保證 Spring Boot 已就緒；須搭配 `condition: service_healthy` |
| api 持續 unhealthy | 以 `docker compose logs api` 檢查：多為 `.env` 未帶入、Supabase 密碼錯誤，或 health 路徑缺少 `/api/v1` |
| web 回傳 502 Bad Gateway | nginx 無法連線 api：檢查 `API_URL` 是否誤寫為 `localhost`，或 api 仍在啟動中 |
| `env_file` 路徑 | 相對於 **compose.yaml 所在目錄**，而非 build 目錄 |
| 修改 Java 後未生效 | `docker compose up -d` 不會自動重新建置，須加上 `--build` |

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <code>env_file</code> 只將值注入容器，<code>.env</code> 本身不會進入 Image，也不在 compose.yaml 中。機密值管理於第八章完整說明。
</div>

<!--
【易錯點提醒 ⚠️】
- depends_on 只寫服務名稱時，只確認容器是否已啟動，不確認 Spring Boot 是否就緒。java 行程啟動後容器即為 running，但 Tomcat 要十數秒後才開始監聽 8080。
- api 持續 unhealthy 多為三種原因：env_file 路徑錯誤導致缺少密碼、Supabase 密碼錯誤、healthcheck 網址缺少 context-path。以 docker compose logs api 即可判斷。
- docker compose up -d 發現 Image 已存在時不會重新建置，修改 Java 後直接執行 up，執行的仍是舊版程式，必須加上 --build。
-->

---

# 練習 1：將 ssds-api 搬入 Compose
### 任務說明

**難度：基礎**

將第四章建置的 `ssds-api:1.0.0` 由 `docker run` 改為 Compose 管理。於 `ai-products-selection/` 下撰寫 `compose.yaml`：

1. 一個名為 `api` 的服務，使用 `ssds-api:1.0.0` Image（**不使用 build**）
2. 主機 `8080` 對應容器 `8080`
3. 以 `env_file` 帶入後端的 `.env`，另設定 `SPRING_PROFILES_ACTIVE=dev`
4. 以 `docker compose up -d` 啟動，並以 `docker compose logs -f api` 等待 `Started SsdsApplication`
5. 以 `docker compose exec api wget -qO- http://localhost:8080/api/v1/actuator/health` 確認回傳 `{"status":"UP"}`
6. 比較此 YAML 與第四章的 `docker run` 指令

<!--
【任務鋪陳】
本題練習 services 的常用欄位、ports 映射與 env_file 寫法。

【出題動機】
- 第 3 步刻意設定 dev profile，讓 log 中顯示 Hibernate 輸出的 SQL，同時確認 environment 可覆蓋 Image 中 ENV 的預設值（第四章 Dockerfile 預設為 prod）。
- 第 6 步為本題重點：-p 對應 ports、--env-file 對應 env_file、-e 對應 environment。Compose 並非新概念，而是將相同參數寫入檔案，可納入版本控制，組員 clone 後即可使用。
-->

---

# 練習 1：參考答案

```yaml
# ai-products-selection/compose.yaml
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

```bash
docker compose up -d
docker compose ps                                     # api 為 running
docker compose logs api | grep "Started SsdsApplication"
docker compose exec api wget -qO- http://localhost:8080/api/v1/actuator/health
# {"status":"UP"}
```

| `docker run` | compose.yaml |
| --- | --- |
| `--name ssds-api` | `services.api`（容器名稱 `ssds-api-1`） |
| `-p 8080:8080` | `ports: ["8080:8080"]` |
| `--env-file .env` | `env_file: ./ai-products-selection-backend/.env` |
| `-e SPRING_PROFILES_ACTIVE=dev` | `environment: { SPRING_PROFILES_ACTIVE: dev }` |

<!--
【帶讀解法】
ports 的格式為「主機 port : 容器 port」，順序不可顛倒。

【易錯點提醒 ⚠️】
- env_file 路徑相對於 compose.yaml。compose.yaml 位於上一層，因此須寫 ./ai-products-selection-backend/.env。
- ports 的值建議加引號寫成字串。在 YAML 1.1 規則下，部分未加引號的 `xx:yy` 會被解析為六十進位數字。

【預期結果】
compose ps 顯示 api 為 running，health 回傳 UP。若回傳 DOWN，通常是無法連線 Supabase，請查看 log 中的 HikariPool 錯誤訊息。
-->

---

# 練習 2：SSDS 前後端整合
### 任務說明

**難度：進階**

將 SSDS 前後端寫成完整的 `compose.yaml`：

1. `api` 服務：以 `build: ./ai-products-selection-backend` 建置，Image 命名為 `ssds-api:1.0.0`，對外開放 `8080:8080`，帶入 `.env`
2. `web` 服務：以 `build: ./ai-products-selection-frontend` 建置，Image 命名為 `ssds-web:1.0.0`，對外開放 `8000:80`
3. web 以**服務名稱**將 `/api` 轉送至後端（不可出現 `localhost` 或 `host.docker.internal`）
4. 為 `api` 加入 healthcheck，並讓 `web` 於 `api` 健康後才啟動
5. 驗證：開啟 `http://localhost:8000` 登入，畫面能載入商品資料
6. 修改任一 Controller 的回應文字，**只重新建置 api**，確認 web 容器未被重啟（查看 `docker compose ps` 的 CREATED 欄）

<!--
【任務鋪陳】
本題整合本章所有重點：build、多服務、服務名稱連線、healthcheck、env_file。

【出題動機】
- 第 3 點禁止 localhost，因為這是最常見的錯誤：在 web 容器中，localhost 指的是 nginx 本身。
- 第 5 點為端到端驗收：瀏覽器 → web 的 nginx → 反向代理至 api → api 連線 Supabase 查詢 → 回傳。能顯示資料即代表整條路徑皆正常。
- 第 6 點練習日常開發流程：docker compose up -d --build api。
-->

---
zoom: 0.88
---

# 練習 2：參考答案

```yaml
# ai-products-selection/compose.yaml
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
docker compose up -d --build        # 首次建置兩個 Image，需較長時間
docker compose ps                   # api (healthy) → web 啟動
docker compose up -d --build api    # 第 6 題：只重新建置 api
docker compose ps                   # api 的 CREATED 為數秒前，web 仍為數分鐘前
```

<!--
【帶讀解法】
三個重點：API_URL 的主機使用服務名稱 api、port 使用容器內的 8080；healthcheck 路徑包含 /api/v1；depends_on 使用 service_healthy。

【易錯點提醒 ⚠️】
healthcheck 寫錯時 api 永遠為 unhealthy，web 永遠不會啟動，docker compose up 會出現 dependency failed to start。此時先以 docker compose exec api wget 手動呼叫健康檢查網址，確認路徑是否正確。

【問題引導】
上傳一張商品圖片後執行 docker compose down 再 up，圖片是否仍存在？答案於第七章說明。
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
<tr><th>主題</th><th>重點</th></tr>
</thead>
<tbody>
<tr><td>compose.yaml</td><td>以一份 YAML 定義 services / networks / volumes，放在前後端 repo 的上一層</td></tr>
<tr><td>版本</td><td>使用 <code>docker compose</code>（v2 plugin），不使用 <code>docker-compose</code>；不需寫 <code>version:</code></td></tr>
<tr><td>核心指令</td><td><code>up -d --build</code>、<code>down</code>、<code>logs -f</code>、<code>ps</code>、<code>exec</code></td></tr>
<tr><td>服務連線</td><td>同一網路以服務名稱連線：<code>API_URL=http://api:8080</code></td></tr>
<tr><td>機密值</td><td>以 <code>env_file</code> 帶入 <code>.env</code>，不寫死在 YAML 中</td></tr>
<tr><td>啟動順序</td><td>Actuator healthcheck + <code>depends_on: condition: service_healthy</code></td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b>網路設定 — web → api 的反向代理，以及容器如何連線至 Supabase。
</div>

<!--
【回顧】
Compose 解決多容器協作的問題。本章介紹 YAML 語法、compose.yaml 的三大區塊與核心指令，並將 SSDS 寫成一份完整的 compose.yaml。

【課程預覽】
下一章說明網路設定的細節：服務名稱如何被解析、nginx 反向代理的作用，以及容器如何連線至外部的 Supabase。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
【互動引導】
開放提問：compose.yaml 語法、up / down / logs 指令，或 healthcheck、depends_on 的寫法，有任何疑問皆可提出。
-->
