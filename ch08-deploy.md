---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: 上線前準備
routeAlias: ch08
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">上線前準備</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「機密不落地、版本可追溯、記憶體有上限」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
【開場白】
本章主題是「上線前準備」。前七章已將 SSDS 前後端包裝為 Image、以 Compose 整合，並處理網路與上傳檔案的持久化。

【問題引導】
本機能以 docker compose up 執行，與能安全地部署至雲端供他人使用之間，仍有幾項工作：機密值如何管理才不會外洩、如何為每個版本的 Image 標記、如何將 Image 放到雲端平台可取得的位置，以及免費方案僅有 512MB 記憶體，Spring Boot 是否能正常運作。

【學習目標】
- 區分兩種 .env 的用途，確保機密值不進入 Git 與 Image
- 以語意化版號與 commit hash 標記 Image
- 將 Image 推送至 Docker Hub（指定 amd64 架構）
- 以資源限制在本機模擬 512MB 免費方案
-->

---
layout: default
---

# Outline

- **環境變數管理與 .env**
  - 機密值不進 Image、不進 Git
- **Image 版本控制與 Tag 策略**
- **推送至 Docker Hub**
  - CPU 架構（amd64）
- **正式環境加固**
  - 健康檢查、自動重啟、**模擬 512MB 免費方案**
- **實作練習**

<!--
【帶讀大綱】
本章四個部分皆為部署至雲端前須在本機完成的準備：
1. 環境變數與 .env：機密值外洩是最常見的資安事件來源之一。
2. Tag 策略：確認目前執行的是哪個版本的程式碼。
3. 推送至 Docker Hub：第九章其中一種部署方式即由雲端平台直接從 Docker Hub 拉取 Image。
4. 正式環境加固：免費方案通常只有 512MB 記憶體，先在本機模擬。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 環境變數管理與 .env

<!--
【段落轉換】
第一部分說明機密值的管理。程式碼中寫死資料庫密碼或 API 金鑰，再不慎 commit 至 GitHub，是常見的外洩途徑。

【重點提醒】
SSDS 的 .env 包含 Supabase 密碼、Mistral API key、Apify token。Mistral 與 Apify 皆依用量計費，任何一項外洩都會造成直接損失。
-->

---
zoom: 0.9
---

# SSDS 的兩種 .env

| | 後端 `.env` | Compose 層 `.env` |
| --- | --- | --- |
| 位置 | `ai-products-selection-backend/.env` | `ai-products-selection/.env`（與 compose.yaml 同層） |
| 用途 | 提供 **Spring Boot 容器**的環境變數 | 供 **compose.yaml 本身**進行 `${}` 變數替換 |
| 進入容器的方式 | `env_file:` / `docker run --env-file` | 僅在 `environment:` 明確引用時才會進入容器 |
| 內容 | `SSDS_DB_*`、`MISTRAL_API_KEY`、`SSDS_JWT_SECRET`… | `SSDS_VERSION`、`DOCKERHUB_USER` |
| 納入版控 | ❌（專案已有 `.env.example` 作為範本） | ❌（另附 `.env.example`） |

```bash
# ai-products-selection/.env（Compose 層）
SSDS_VERSION=1.0.0
DOCKERHUB_USER=myaccount
```

<!--
【重點解說】
- 後端 .env：專案原有的檔案，存放 Spring Boot 讀取的機密值。Spring Boot 透過 application.properties 的 spring.config.import 讀取；容器中則以 env_file 或 --env-file 注入。專案已提供 .env.example，且 .gitignore 已排除 .env。
- Compose 層 .env：與 compose.yaml 放在同一層，Compose 啟動時自動讀取，用於替換 compose.yaml 中的 ${SSDS_VERSION} 等佔位符，本身不會成為容器的環境變數。

【易錯點提醒 ⚠️】
Compose 層 .env 的路徑以 compose.yaml 所在目錄為準，必須與 compose.yaml 放在同一層。
-->

---

# compose.yaml 中的環境變數寫法

| 寫法 | 語法 | 說明 |
| --- | --- | --- |
| `environment`（映射語法） | `SPRING_PROFILES_ACTIVE: prod` | 直接寫在 compose.yaml（適用非機密值） |
| `env_file` | `env_file: ./ai-products-selection-backend/.env` | 由外部檔案載入整批變數 |
| 變數替換 | `image: ${DOCKERHUB_USER}/ssds-api:${SSDS_VERSION}` | 由 Compose 層 `.env` 或 shell 取值 |
| 預設值 | `${SSDS_VERSION:-1.0.0}` | 未設定時使用預設值 |
| 必填檢查 | `${DOCKERHUB_USER:?請在 .env 設定}` | 未設定時直接報錯，避免代入空字串 |

<!--
【重點解說】
- 非機密值（例如 profile）可直接寫在 environment；大量機密值以 env_file 指向外部檔案；compose.yaml 中隨環境變化的部分（例如 Image 版本）使用 ${} 替換。
- `:-` 提供預設值；`:?` 在未設定時報錯，避免 Compose 代入空字串。Image 名稱或密碼為空字串時，錯誤訊息通常難以判讀。
-->

---

# .env 寫法 — 範例

將 SSDS 的 compose.yaml 改為「可納入版控、換版本只需修改 .env」的版本：

```yaml
# ai-products-selection/compose.yaml — 不含任何機密
name: ssds
services:
  api:
    image: ${DOCKERHUB_USER:?}/ssds-api:${SSDS_VERSION:-1.0.0}
    build: ./ai-products-selection-backend
    env_file: ./ai-products-selection-backend/.env
    environment:
      SPRING_PROFILES_ACTIVE: prod
    # ports / volumes / healthcheck 沿用第五、七章
  web:
    image: ${DOCKERHUB_USER:?}/ssds-web:${SSDS_VERSION:-1.0.0}
    build: ./ai-products-selection-frontend
    environment:
      API_URL: http://api:8080
    # ports / depends_on 沿用第五章
```

```bash
docker compose config     # 輸出變數展開後的完整設定，確認 ${} 是否正確代入
```

<!--
【帶讀關鍵行】
與第五章相比有兩項差異：
- Image 名稱改為 ${DOCKERHUB_USER}/ssds-api:${SSDS_VERSION}。docker compose build 產生的 Image 即為可推送至 Docker Hub 的完整名稱；升版或回復版本時，只需修改 Compose 層 .env 中的版本號。
- 檔案中沒有任何密碼。機密值皆在後端 .env，以 env_file 注入，因此 compose.yaml 可安心 commit 或分享。

【易錯點提醒 ⚠️】
docker compose config 會展開所有 ${} 並輸出，env_file 的內容（包含密碼）也會一併輸出，不可在共用螢幕或錄影時執行。
-->

---
zoom: 0.92
---

# 使用 .env 的注意事項

<div class="mt-2 p-3 bg-red-50 border-l-4 border-red-400 text-gray-700 text-sm text-left">
⚠️ <b>機密值只能在「執行時」提供：</b>不可寫入 Dockerfile 的 <code>ENV</code> / <code>ARG</code>，也不可 COPY 進 Image。Image 推送至 Docker Hub 後，<code>docker inspect</code>、<code>docker history</code> 與解開 layer 皆可看到內容。
</div>

| 檢查項目 | SSDS 現況 / 做法 |
| --- | --- |
| `.gitignore` 排除 `.env` | 後端已排除 ✅；Compose 層的 `.env` 也須排除 |
| `.dockerignore` 排除 `.env` | 第四章已加入 ✅ |
| 提供 `.env.example` | 後端已有 ✅（只寫欄位與說明，不含實際值） |
| **`SSDS_JWT_SECRET`** | 預設值為 `dev-only-insecure-secret...`，**上線前必須改為自行產生的亂數**（≥ 32 bytes） |
| 外洩時的處置 | 從 Git 刪除並不足夠，**須至 Supabase / Mistral / Apify 撤銷並重新產生金鑰** |

```bash
# 產生 JWT secret（擇一）
openssl rand -base64 48
docker run --rm alpine sh -c "head -c 48 /dev/urandom | base64"
```

<!--
【核心說明】
不可為了省去 --env-file 而在 Dockerfile 寫入 `ENV SSDS_DB_PASSWORD=xxx`。Image 會推送至 Docker Hub，ENV 的值以 docker inspect 即可看到；ARG 的值會留在 docker history 中。BuildKit 的建置檢查（build checks）也會對 ENV / ARG 中疑似機密的名稱發出 SecretsUsedInArgOrEnv 警告。

【重點提醒】
application.properties 中的 SSDS_JWT_SECRET 有 dev-only 預設值。部署至雲端若未設定，任何看過原始碼的人皆可用此預設值偽造登入 token，上線前必須改為自行產生的亂數。

【易錯點提醒 ⚠️】
密碼若已 commit，僅從 Git 刪除或加入 .gitignore 無效，舊 commit 中仍可取得。正確做法是直接撤銷該金鑰並重新產生。

【補充】
第二個指令同樣是以容器作為工具：本機沒有 openssl 時，改用 alpine 容器產生亂數，與第七章借用 pg_dump 的概念相同。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Image 版本控制與 Tag 策略

<!--
【段落轉換】
第二部分說明 Image 的版本控制。

【生活化比喻】
工廠出貨時每一批貨都貼有批號，某批出現問題時才能精確追查並只回收該批。Image 的 tag 即為批號。
-->

---

# 什麼是 Image Tag？

只使用預設的 `latest`，無法得知正式環境執行的是哪個版本，也無法回復至「上一個可正常運作的版本」。

**Tag** 是為 Image 的每個版本加上可辨識名稱的機制，格式為 `NAME[:TAG]`，例如 `ssds-api:1.2.0`。Tag 是**可變的（mutable）**：同一個 tag 隨時可能被覆寫為不同內容的 Image，因此需要明確的版本策略。

```bash
docker image tag ssds-api:latest ssds-api:1.2.0
```

<!--
【核心說明】
tag 可變代表同一個名稱今天指向的內容，與三個月後可能不同，因為有人可能重新推送並覆寫同一個 tag。

【生活化比喻】
出貨若未標示批號，發生問題時無法追查，也無法只回收有問題的批次。Image 缺乏明確的版本標記，發生問題時也無從得知應回復至哪一版。
-->

---

# latest 的風險

| 情境 | 使用 latest | 使用語意化版號 |
| --- | --- | --- |
| 得知目前執行的版本 | 無法得知 | 由 tag 即可得知 |
| 回復至上一版 | 困難，不知道上一版為何 | 直接指定舊 tag 重新部署 |
| 多台機器版本一致 | 不保證，可能拉到不同時間點的 latest | 一致 |
| 建置結果可重現 | 不可靠 | 可靠 |
| CI/CD 追蹤 | 難以稽核 | 每次建置皆有明確紀錄 |

<!--
【易錯點提醒 ⚠️】
latest 不代表「最新穩定版」，只是未指定 tag 時的預設名稱，與「穩定」或「推薦」無關。
-->

---

# Tag 命名策略 — 範例

以語意化版號（Semantic Versioning，`主版本.次版本.修訂版本`）搭配 git commit hash：

```bash
# 修正商品圖片排序錯誤：修訂版本 +1
docker build -t myaccount/ssds-api:1.0.1 ./ai-products-selection-backend

# 新增「選品報表匯出」功能：次版本 +1
docker build -t myaccount/ssds-api:1.1.0 ./ai-products-selection-backend

# 同時加上兩個 tag：版本號 + git commit hash
docker build -t myaccount/ssds-api:1.1.0 \
  -t myaccount/ssds-api:$(git -C ai-products-selection-backend rev-parse --short HEAD) \
  ./ai-products-selection-backend
```

以 digest（Image 內容的雜湊值）鎖定版本，即使 tag 被覆寫也不受影響：

```bash
docker image inspect --format '{{index .RepoDigests 0}}' myaccount/ssds-api:1.1.0
# myaccount/ssds-api@sha256:4b1c...e9
```

<!--
【重點解說】
- SemVer：修正錯誤時修訂版本 +1，新增功能時次版本 +1，有破壞相容性的修改時主版本 +1。專案 build.gradle 的 version 目前為 0.0.1-SNAPSHOT，實務上會讓兩者一致，由 CI 直接讀取。
- 第三段一次建置加上兩個 tag：版本號供人閱讀，commit hash 供精確追蹤。前後端為兩個 repo，因此以 git -C 指定讀取哪個 repo 的 commit。正式環境發生問題時，由雲端平台得知執行的是 ssds-api:a3f9c1e，執行 git checkout a3f9c1e 即可取得當時的程式碼。
- digest 是依 Image 內容計算的雜湊值，推送至 registry 後才會產生；第九章雲端平台的部署紀錄中也會顯示。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 推送至 Docker Hub

<!--
【段落轉換】
第三部分將建置完成的 Image 推送至 Registry，供雲端平台直接拉取。
-->

---

# 什麼是 Registry？

**Registry（映像倉庫）** 是集中存放、管理與分享 Image 的服務。

| 概念 | 說明 |
| --- | --- |
| Registry | 存放 Image 的服務，例如 Docker Hub、GitHub Container Registry（ghcr.io） |
| Repository | Registry 中的專案空間，例如 `myaccount/ssds-api` |
| Tag | Repository 下的特定版本，例如 `myaccount/ssds-api:1.0.0` |
| Public repository | 任何人皆可 pull；免費帳號數量不限 |
| Private repository | 需要權限才能存取；免費帳號數量有限，雲端平台拉取時須另外提供憑證 |

<!--
【核心說明】
Registry 是 Image 的倉庫：將建置完成的 Image 放入後，其他機器（組員電腦、雲端平台）即可直接拉取，不需重新建置。

【重點解說】
Image 中不含機密（.env 已排除），但包含編譯後的程式碼，jar 可被反編譯。課堂專案使用 public repository 最簡便；需要保密時使用 private repository，第九章於雲端平台設定時另外提供 Docker Hub 存取 token 即可。

【易錯點提醒 ⚠️】
public repository 任何人皆可檢視與拉取，推送前務必確認 Image 中沒有 .env，請再次執行第四章練習中的 ls /app 檢查。
-->

---
zoom: 0.89
---

# Build → Tag → Push 流程

| 步驟 | 指令 | 說明 |
| --- | --- | --- |
| 1. 登入 | `docker login -u myaccount` | 密碼欄位貼上 **Personal Access Token**，不使用帳號密碼 |
| 2. 建置 | `docker build --platform linux/amd64 -t myaccount/ssds-api:1.0.0 .` | 依 Dockerfile 建置，**指定 amd64** |
| 3. 標記 | `docker image tag myaccount/ssds-api:1.0.0 myaccount/ssds-api:latest` | 視需要加上其他 tag |
| 4. 推送 | `docker image push --all-tags myaccount/ssds-api` | 上傳至 Docker Hub |
| 5. 驗證 | `docker pull myaccount/ssds-api:1.0.0` | 刪除本機 Image 後重新拉取，確認可取得 |

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <b>Apple Silicon（M 系列）Mac 必須加上 <code>--platform linux/amd64</code>：</b>預設會建置 arm64 Image，而雲端平台幾乎皆為 amd64，啟動時出現 <code>exec format error</code>。Windows 與 Intel Mac 本身即為 amd64，加上亦無妨。
</div>

<!--
【帶讀關鍵行】
- 第 1 步：Docker Hub 建議以 Personal Access Token（於 Account settings → Personal access tokens 建立）取代帳號密碼；token 可單獨撤銷，外洩風險較低。
- 第 2 步：Image 與 CPU 架構綁定。M 系列 Mac 預設建置 arm64 Image，在本機可正常執行，但部署至 x86 雲端伺服器時出現 exec format error，錯誤訊息不易判讀。Mac 指定 amd64 時以模擬方式建置，速度較慢屬正常現象。
- 第 3 步：建置時已使用含帳號的完整名稱（myaccount/ssds-api），不需額外加上前綴；若先前建置的名稱為 ssds-api:1.0.0，須先 tag 為 myaccount/ssds-api:1.0.0 才能推送。
- 第 5 步：先以 docker rmi 刪除本機 Image 再 pull，確認確實可取得。

【易錯點提醒 ⚠️】
tag 名稱必須包含帳號（myaccount/ssds-api），只寫 ssds-api 會被視為推送至 Docker 官方命名空間而遭拒絕。
-->

---

# Build → Tag → Push — 範例

SSDS 發布 1.0.0 版（於 `ai-products-selection/` 下執行）：

```bash
# 1. 登入 Docker Hub（密碼貼上 Personal Access Token）
docker login -u myaccount

# 2. 建置兩個服務的 Image（使用含帳號的名稱並指定平台）
docker build --platform linux/amd64 -t myaccount/ssds-api:1.0.0 \
  ./ai-products-selection-backend
docker build --platform linux/amd64 -t myaccount/ssds-web:1.0.0 \
  ./ai-products-selection-frontend

# 3. 推送
docker image push myaccount/ssds-api:1.0.0
docker image push myaccount/ssds-web:1.0.0

# 或：compose.yaml 的 image 欄位已為 ${DOCKERHUB_USER}/ssds-xxx:${SSDS_VERSION}
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build && docker compose push
```

<!--
【帶讀關鍵行】
兩種做法擇一：前半段逐一建置與推送；最後一行利用 Compose：compose.yaml 的 image 欄位已改為含帳號與版本的完整名稱，docker compose build 一次建置兩個 Image，docker compose push 一次推送兩個。DOCKER_DEFAULT_PLATFORM 環境變數使 Compose 建置時也使用 amd64。PowerShell 須先執行 `$env:DOCKER_DEFAULT_PLATFORM="linux/amd64"`。

【補充】
推送過程顯示的是未壓縮大小，實際傳輸量因壓縮而較小。首次推送 ssds-api 壓縮後約 170MB；之後改版只需推送有變動的 layer（通常只有 jar 那一層）。

【預期結果】
推送完成後，Docker Hub 帳號頁面出現 ssds-api 與 ssds-web 兩個 repository，各有 1.0.0 tag。
-->

---

# CI/CD 概念

手動執行 build、tag、push 與部署，步驟一多即容易遺漏或出錯。

**CI/CD** 為 Continuous Integration（持續整合）與 Continuous Deployment / Delivery（持續部署 / 交付）的合稱，核心概念是**將建置、測試、推送與部署交由自動化流程執行**。

| 階段 | 工作內容 | SSDS 使用的工具（第九章實作） |
| --- | --- | --- |
| 觸發 | 開發者 push 程式碼至 Git | GitHub |
| CI（持續整合） | 自動建置 Image、執行測試 | GitHub Actions（public repo 免費） |
| 打包 | 自動加上 tag（版本號 / commit hash）並推送 | Docker Hub |
| CD（持續部署） | 通知雲端平台拉取新版並重新部署 | 雲端平台的 Deploy Hook |

<!--
【核心說明】
CI/CD 即將前述 build、tag、push 流程寫成腳本，交由自動化工具執行；開發者只需將程式碼 push 至 Git，後續工作由工具自動完成。

【課程預覽】
第九章實作：GitHub Actions 在 push 至 main 時自動建置並推送至 Docker Hub，再呼叫雲端平台的 Deploy Hook 觸發重新部署。

【業界實務】
後端測試使用 Testcontainers，會在測試時啟動真實的 PostgreSQL 容器，因此執行測試的 CI 機器也需要 Docker。GitHub Actions 的 ubuntu runner 已內建 Docker，這也是 Docker 在 CI/CD 中的常見應用。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 正式環境加固

<!--
【段落轉換】
第四部分為部署前的最後準備：自動重啟、健康檢查與記憶體限制。
-->

---

# 健康檢查、自動重啟與資源限制

```yaml
services:
  api:
    image: ${DOCKERHUB_USER:?}/ssds-api:${SSDS_VERSION:-1.0.0}
    restart: unless-stopped                  # 異常結束時自動重啟
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:8080/api/v1/actuator/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 180s                     # 實測 0.5 CPU 下啟動約 115 秒
    deploy:
      resources:
        limits: { cpus: "0.5", memory: 512m }   # 模擬免費雲端方案
    environment:
      JAVA_TOOL_OPTIONS: >-
        -XX:MaxRAMPercentage=60 -XX:+UseSerialGC -Xss512k -XX:TieredStopAtLevel=1
```

<!--
【帶讀關鍵行】
- `restart: unless-stopped`：容器因 OOM 或例外結束時，Docker 自動重啟；主機重新開機後也會自動啟動。除非手動 stop，否則持續重啟。
- `healthcheck`：使用第四章加入的 actuator。限制 0.5 CPU 時 SSDS 啟動約 115 秒（不限制時約 30 秒），寬限期過短會使首次 up 出現 dependency failed to start，因此 start_period 設為 180 秒。
- `deploy.resources.limits`：第九章免費方案只有 512MB 記憶體與少量 CPU。與其部署後才發現記憶體不足，再從雲端 log 推測原因，不如先在本機模擬相同條件。

【核心說明】
JAVA_TOOL_OPTIONS 各參數的作用：
- `MaxRAMPercentage=60`：堆積上限為容器記憶體的 60%（約 300MB）。其餘約 200MB 留給 metaspace（專案包含 Spring、Hibernate、POI、ICU4J 等大量類別）、執行緒堆疊與程式碼快取。設定 75% 以上時，總用量容易超過 512MB 而被系統終止。
- `UseSerialGC`：單執行緒垃圾回收器，額外記憶體開銷最小，適合小記憶體、少 CPU 的環境。
- `Xss512k`：每條執行緒的堆疊由預設 1MB 降為 512KB；Tomcat 有數十條執行緒，節省量可觀。
- `TieredStopAtLevel=1`：只使用 C1 編譯器，啟動較快、程式碼快取較小，代價是長時間執行的峰值效能略低，對展示用途而言值得。

【易錯點提醒 ⚠️】
未設定上述參數時，常見症狀為容器無預警重啟，docker inspect 顯示 OOMKilled: true、Exit Code 137，log 中沒有任何線索。
-->

---
zoom: 0.95
---

# 將 JVM 設定寫入 Dockerfile

```dockerfile
# ai-products-selection-backend/Dockerfile 第二階段（更新版）
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app \
 && mkdir -p /app/uploads && chown -R app:app /app
COPY --from=build /src/ssds-api/build/libs/ssds.jar app.jar
USER app
ENV SPRING_PROFILES_ACTIVE=prod \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=60 -XX:+UseSerialGC -Xss512k -XX:TieredStopAtLevel=1"
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```bash
# 驗證：查看 JVM 實際計算的最大堆積
docker run --rm -m 512m --entrypoint java myaccount/ssds-api:1.0.0 \
  -XX:+PrintFlagsFinal -version | grep -i maxheapsize
```

<!--
【核心說明】
將 JVM 參數寫入 Dockerfile 的 ENV 作為預設值，無論在本機 docker run、Compose 或第九章的雲端平台，皆自動套用，不需在各處重複設定。需要調整時，於平台設定同名環境變數即可覆蓋。

【帶讀關鍵行】
驗證指令：-m 512m 限制記憶體，--entrypoint java 改為執行 `java -XX:+PrintFlagsFinal -version`，輸出 JVM 所有參數的最終值；grep MaxHeapSize 應顯示約 300MB（單位為 byte）。啟動時 log 第一行出現 Picked up JAVA_TOOL_OPTIONS，表示 JVM 已讀取設定。

【重點提醒】
修改 Dockerfile 後須重新建置並推送，版本號 +1。
-->

---
layout: default
---

# 練習 1：上線前的機密檢查
### 任務說明

1. 在 `ai-products-selection/` 建立 Compose 層的 `.env`（`SSDS_VERSION`、`DOCKERHUB_USER`）與 `.env.example`，並確認 `.env` 不會被 Git 追蹤
2. 改寫 `compose.yaml`：Image 改為 `${DOCKERHUB_USER}/ssds-xxx:${SSDS_VERSION}`，以 `docker compose config` 確認展開正確
3. 產生新的 `SSDS_JWT_SECRET` 並寫入後端 `.env`
4. 驗證 Image 中沒有機密：
   - `docker run --rm --entrypoint ls myaccount/ssds-api:1.0.0 -la /app` 中沒有 `.env`
   - `docker history --no-trunc myaccount/ssds-api:1.0.0` 中沒有任何密碼
5. **思考題**：若組員將 `MISTRAL_API_KEY` 寫在 Dockerfile 的 `ENV`，且已推送至 public repo，應如何處理？

<!--
【任務鋪陳】
本題複習第一部分的核心觀念：設定與程式碼分離、密碼不進版控也不進 Image。

【出題動機】
第 4 步的兩項驗證皆重要：ls 檢查檔案、history 檢查每一層的建置指令。
-->

---
layout: default
zoom: 0.9
---

# 練習 1：參考答案

```bash
# 1. ai-products-selection/.env（不納入版控）
SSDS_VERSION=1.0.0
DOCKERHUB_USER=myaccount

# 1. ai-products-selection/.env.example（可納入版控）
SSDS_VERSION=1.0.0
DOCKERHUB_USER=
```

```bash
# 2. 確認 Image 名稱展開正確
docker compose config | grep image:
#   image: myaccount/ssds-api:1.0.0
#   image: myaccount/ssds-web:1.0.0

# 3. 產生 JWT secret，寫入後端 .env 的 SSDS_JWT_SECRET=
docker run --rm alpine sh -c "head -c 48 /dev/urandom | base64"

# 4. 驗證：只有 app.jar 與 uploads；history 中查無結果
docker run --rm --entrypoint ls myaccount/ssds-api:1.0.0 -la /app
docker history --no-trunc myaccount/ssds-api:1.0.0 | grep -i -E "password|api_key|token"
```

<div class="mt-2 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>第 5 題答案：</b>① 立即至 Mistral 後台<b>撤銷該金鑰並重新產生</b>（Image 可能已被他人拉取，此為唯一有效的補救）；② 將 Dockerfile 的 <code>ENV</code> 移除，改由執行時注入；③ 重新建置並推送新版本；④ 刪除 Docker Hub 上含有金鑰的 tag。
</div>

<!--
【帶讀解法】
- `ai-products-selection/` 本身若不是 Git repo，Compose 層 .env 不會被追蹤；若將 compose.yaml 放入後端 repo，須確認該 repo 的 .gitignore 已排除此檔。
- 第 5 題的順序很重要：先撤銷金鑰，因為 Image 可能已被他人拉取，其餘步驟都無法收回已外洩的值。

【易錯點提醒 ⚠️】
.env 若曾經被 commit，之後才加入 .gitignore 並無效果。可執行 `git log --all -- .env` 檢查歷史紀錄中是否出現過。
-->

---
layout: default
---

# 練習 2：發布至 Docker Hub 並模擬免費方案
### 任務說明

1. 更新後端 Dockerfile，加入 `JAVA_TOOL_OPTIONS`，重新建置 `ssds-api` 與 `ssds-web`（`--platform linux/amd64`）
2. 加上 `1.0.0` 與 git commit hash 兩種 tag，推送至 Docker Hub
3. 模擬部署機：`docker compose down`、刪除本機兩個 Image，再執行 `docker compose pull && docker compose up -d`
4. 於 compose.yaml 為 api 加上 `memory: 512m` 限制，觀察：
   - `docker compose ps` 經過多久變為 healthy？
   - `docker stats` 顯示 api 實際使用多少記憶體？
   - 登入前端操作數分鐘，api 是否重啟（以 `docker inspect` 查看 `RestartCount` 與 `OOMKilled`）？
5. **思考題**：雲端上的 1.0.1 有嚴重錯誤，需回復至 1.0.0，應修改哪裡、執行哪兩個指令？

<!--
【任務鋪陳】
本題將 build、tag、push 與部署串成完整流程，為第九章的預演。

【出題動機】
- 第 3 步必須實際刪除本機 Image 再拉取，以模擬部署伺服器的真實狀態：該機器上沒有原始碼、JDK 或 Node，只有 Docker 與設定檔。
- 第 4 步為第九章的事前演練。本機 512MB 無法正常運作，部署至雲端也必定無法運作，應先在此調整參數。
-->

---
layout: default
zoom: 0.88
---

# 練習 2：參考答案

```bash
# 1-2. 建置、加上 tag、推送（PowerShell：$SHA = git -C ai-products-selection-backend rev-parse --short HEAD）
docker login -u myaccount
SHA=$(git -C ai-products-selection-backend rev-parse --short HEAD)
docker build --platform linux/amd64 \
  -t myaccount/ssds-api:1.0.0 -t myaccount/ssds-api:$SHA ./ai-products-selection-backend
docker build --platform linux/amd64 -t myaccount/ssds-web:1.0.0 ./ai-products-selection-frontend
docker image push --all-tags myaccount/ssds-api
docker image push --all-tags myaccount/ssds-web

# 3. 模擬部署機：清除後重新拉取
docker compose down
docker rmi myaccount/ssds-api:1.0.0 myaccount/ssds-api:$SHA myaccount/ssds-web:1.0.0
docker compose pull && docker compose up -d

# 4. 觀察：約 2 分鐘後 healthy；記憶體約 330MB；RestartCount 0、OOMKilled false
docker compose ps
docker stats --no-stream
docker inspect -f '{{.RestartCount}} {{.State.OOMKilled}}' ssds-api-1

# 5. 回復版本：Compose 層 .env 改為 SSDS_VERSION=1.0.0 後
docker compose pull && docker compose up -d
```

<div class="mt-2 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <b>OOMKilled 為 true 時：</b>先將 <code>MaxRAMPercentage</code> 調降為 50；仍不足時，以環境變數停用不需要的排程（例如 <code>SSDS_INGEST_INSTAGRAM_ENABLED=false</code>），減少背景工作的記憶體使用。
</div>

<!--
【帶讀解法】
- 第 3 步：推送後必須實際拉取驗證，才能確認部署機確實取得 Image。
- 第 4 步：限制 512MB、0.5 CPU 後，Spring Boot 啟動時間由約 30 秒增加為約 115 秒（實測）。雲端免費方案的 CPU 更少，啟動會更慢，屬正常現象。docker stats 實測 api 啟動後約 330MB；若接近 512MB，須調整參數。
- 第 5 步：第九章的雲端平台概念相同，只是改為修改平台上的 Image tag。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — 上線前準備

<table class="summary-table">
<thead>
<tr><th>主題</th><th>重點</th></tr>
</thead>
<tbody>
<tr><td>兩種 .env</td><td>後端 <code>.env</code> → 容器環境變數；Compose 層 <code>.env</code> → compose.yaml 的 <code>${}</code></td></tr>
<tr><td>機密值</td><td>只在執行時提供；不進 Git、不進 Image；<code>SSDS_JWT_SECRET</code> 上線前必須更換</td></tr>
<tr><td>Tag 策略</td><td>語意化版號 + commit hash，不依賴 <code>latest</code></td></tr>
<tr><td>Docker Hub</td><td>以 Access Token 登入；<b><code>--platform linux/amd64</code></b></td></tr>
<tr><td>加固</td><td>restart、Actuator healthcheck、512MB 限制 + <code>JAVA_TOOL_OPTIONS</code></td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章（最後一章）：</b>雲端部署 — 將 <code>ssds-api</code>、<code>ssds-web</code> 部署至<b>免費、免綁信用卡</b>的平台。
</div>

<!--
【回顧】
本章完成上線前的準備：機密值管理、版本 tag、推送至 Docker Hub、記憶體調校。目前已具備：
- Docker Hub 上的兩個 Image：myaccount/ssds-api:1.0.0、myaccount/ssds-web:1.0.0
- GitHub 上的兩個 repo，各自包含 Dockerfile

【課程預覽】
這兩項正好對應第九章的兩種部署方式：由雲端平台從 Docker Hub 拉取現成的 Image，或由雲端平台讀取 GitHub 上的 Dockerfile 自行建置。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
【互動引導】
開放提問：環境變數管理、Image Tag 策略、推送至 Docker Hub 或 JVM 記憶體調校，有任何疑問皆可提出。
-->
