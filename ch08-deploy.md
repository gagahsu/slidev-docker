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
    「機密不落地、版本可追溯、記憶體有邊界」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
大家好，歡迎來到第八章「上線前準備」。

前面七章我們已經把 SSDS 前後端都包成 image、用 Compose 串起來、處理好網路和上傳檔案的持久化。下一章就要部署到雲端了，但在那之前，還有幾件事一定要先在本機做好。

為什麼？因為在自己電腦上 `docker compose up` 能跑，跟能安全地放到雲端讓別人用，中間還隔著幾件事：機密值怎麼管理才不會外洩、怎麼幫每個版本的 image 做好標記、怎麼把 image 送到雲端平台拉得到的地方，以及——免費雲端方案只有 512MB 記憶體，我們的 Spring Boot 撐不撐得住。

學完這章，大家手上會有推到 Docker Hub 的兩個 image，而且已經在本機模擬過免費方案的記憶體限制，第九章就能直接上線。
-->

---
layout: default
---

# Outline

- **環境變數管理與 .env** — 機密值永遠不進 Image、不進 Git
- **Image 版本控制與 Tag 策略**
- **推送至 Docker Hub** — 注意 CPU 架構（amd64）
- **正式環境加固** — 健康檢查、自動重啟、**模擬 512MB 免費方案**
- **練習題 / 總結**

<!--
今天分成四大部分，全部都是「部署到雲端之前」要先在本機準備好的事。

第一部分講環境變數跟 .env 檔，這是部署前最容易踩雷的地方，很多資安事件都是密碼不小心被 commit 上去造成的。

第二部分講 image 的版本控制，也就是 tag 策略，讓我們知道現在跑的到底是哪一版程式碼。

第三部分把 image 推到 Docker Hub，第九章有一種部署方式就是讓雲端平台直接從 Docker Hub 拉 image。

第四部分是正式環境加固，特別是記憶體：免費雲端方案通常只有 512MB，Spring Boot 很容易爆掉，我們先在本機模擬一次。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 環境變數管理與 .env

<!--
先進入第一部分。大家有沒有遇過這種情況：程式碼裡直接寫死了資料庫密碼、API 金鑰，結果不小心把整包程式 commit 上 GitHub，密碼就這樣公開給全世界看？

SSDS 的 .env 裡有 Supabase 密碼、Mistral API key、Apify token，每一個外洩都會直接造成損失——Mistral 跟 Apify 是用量計費的。
-->

---
zoom: 0.9
---

# SSDS 的兩種 .env

| | 後端 `.env` | Compose 層 `.env` |
| --- | --- | --- |
| 位置 | `ai-products-selection-backend/.env` | `ai-products-selection/.env`（跟 compose.yaml 同層） |
| 用途 | 給 **Spring Boot 容器**的環境變數 | 給 **compose.yaml 本身**做 `${}` 文字替換 |
| 怎麼進容器 | `env_file:` / `docker run --env-file` | 只有在 `environment:` 明確引用才會進容器 |
| 內容 | `SSDS_DB_*`、`MISTRAL_API_KEY`、`SSDS_JWT_SECRET`… | `SSDS_VERSION`、`DOCKERHUB_USER` |
| 進版控？ | ❌（專案已有 `.env.example` 當範本） | ❌（另附 `.env.example`） |

```bash
# ai-products-selection/.env（Compose 層）
SSDS_VERSION=1.0.0
DOCKERHUB_USER=myaccount
```

<!--
SSDS 會同時出現兩個 .env，這是大家最容易搞混的地方，先講清楚。

左邊是後端專案原本就有的 .env，裡面是 Spring Boot 要讀的機密值。Spring Boot 自己會讀它（application.properties 的 spring.config.import），容器裡則是靠 env_file 或 --env-file 帶進去。專案已經有一份 .env.example 當範本、而且 .gitignore 已經排除 .env，這是很好的習慣。

右邊是 Compose 的 .env：放在 compose.yaml 同一層，Compose 啟動時會自動讀它，用來替換 compose.yaml 裡的 ${SSDS_VERSION} 這種佔位符。它本身不會變成容器的環境變數。

⚠️ Docker Compose 官方文件：「路徑是相對於 compose.yaml 檔案的位置」。所以 Compose 層的 .env 一定要跟 compose.yaml 放一起。
-->

---

# .env 在 compose.yaml 中的用法

| 用法 | 語法 | 說明 |
| --- | --- | --- |
| `environment`（映射語法）| `SPRING_PROFILES_ACTIVE: prod` | 直接寫死在 compose.yaml（非機密值可以） |
| `env_file` | `env_file: ./ai-products-selection-backend/.env` | 指定外部檔案載入整批變數 |
| 插值引用 | `image: ${DOCKERHUB_USER}/ssds-api:${SSDS_VERSION}` | 從 Compose 層 `.env` 或 shell 讀值代入 |
| 預設值 | `${SSDS_VERSION:-1.0.0}` | 沒設定時用預設值 |
| 必填檢查 | `${DOCKERHUB_USER:?請在 .env 設定}` | 沒設定就直接報錯，不默默代入空字串 |

<!--
這張表整理了在 compose.yaml 裡設定環境變數的幾種方式。

非機密的值（例如 profile）直接寫在 environment 沒關係；一大批機密值用 env_file 指到外部檔案；compose.yaml 本身要隨環境變化的地方（例如 image 版本）用 ${} 插值。

最後兩列很實用：:- 給預設值；:? 是「沒設定就報錯」，避免 Compose 找不到變數時默默代入空字串——空字串的 image 名稱或密碼，錯誤訊息會非常難懂。
-->

---

# .env 用法 — 範例

把 SSDS 的 compose.yaml 改成「可以安心進版控、換版本只改 .env」的版本：

```yaml
# ai-products-selection/compose.yaml — 這份裡面沒有任何機密
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
docker compose config     # 印出變數展開後的完整設定，檢查 ${} 有沒有代入成功
```

<!--
這張是範例頁。對照第五章那份 compose.yaml，差別有兩個：

第一，image 名稱改成 ${DOCKERHUB_USER}/ssds-api:${SSDS_VERSION}。這樣 docker compose build 出來的 image 直接就是可以推到 Docker Hub 的完整名稱；要升版或回滾，只要改 Compose 層 .env 裡的一行版本號。

第二，整份檔案沒有任何密碼。機密值都在後端 .env，靠 env_file 帶進去。所以這份 compose.yaml 可以放心 commit、貼在文件裡、給任何人看。

docker compose config 會把所有 ${} 展開之後印出來，變數有沒有讀到、讀到什麼值，一目了然。⚠️ 但 env_file 的內容也會被展開印出來，包含密碼，不要在共用螢幕或錄影時打。
-->

---
zoom: 0.92
---

# 使用 .env 的注意事項

<div class="mt-2 p-3 bg-red-50 border-l-4 border-red-400 text-gray-700 text-sm text-left">
⚠️ <b>機密值只能在「執行時」給：</b> 不要寫進 Dockerfile 的 <code>ENV</code> / <code>ARG</code>，也不要 COPY 進 image — image 會被推到 Docker Hub，<code>docker history</code> 與解開 layer 都看得到。
</div>

| 檢查項目 | SSDS 現況 / 做法 |
| --- | --- |
| `.gitignore` 排除 `.env` | 後端已排除 ✅；Compose 層的 `.env` 也要加 |
| `.dockerignore` 排除 `.env` | 第四章已加 ✅ |
| 提供 `.env.example` | 後端已有 ✅（只寫欄位與說明，不寫真值） |
| **`SSDS_JWT_SECRET`** | 預設值是 `dev-only-insecure-secret...`，**上線一定要設成自己的亂數**（≥ 32 bytes） |
| 外洩了怎麼辦 | 從 Git 刪掉不夠 — **直接到 Supabase / Mistral / Apify 換掉那組金鑰** |

```bash
# 產生一組 JWT secret（任選一種）
openssl rand -base64 48
docker run --rm alpine sh -c "head -c 48 /dev/urandom | base64"
```

<!--
這頁是這個部分最重要的提醒。

第一個紅框：機密值只能在執行時給。有些同學會想「那我在 Dockerfile 寫 ENV SSDS_DB_PASSWORD=xxx，不就不用每次帶 --env-file 了？」千萬不要。image 會推到 Docker Hub，ENV 的值用 docker inspect 就看得到；ARG 的值會留在 docker history 裡。

表格是 SSDS 的檢查清單，大部分專案已經做得很好了。特別要注意 SSDS_JWT_SECRET：application.properties 裡給了一個 dev-only 的預設值。部署到雲端如果沒設，任何看過我們原始碼的人都能用這個預設值偽造登入 token。上線一定要設成自己產生的亂數。

最後一列：如果密碼真的不小心 commit 了，光是從 Git 刪掉、加 .gitignore 是沒用的，舊 commit 裡還找得到。最正確的做法是直接把那組金鑰作廢重發，因為它已經外洩了。

第二個指令示範「容器當工具」：電腦沒有 openssl 的話，用 alpine 容器產生亂數，跟第七章借 pg_dump 是同樣的概念。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Image 版本控制與 Tag 策略

<!--
接下來進入第二部分，聊聊 image 的版本控制。

大家想像一下，工廠出貨的時候，每一批貨都會貼上批號，這樣如果某一批貨出了問題，才能精準地追查是哪一批、什麼時候生產的，也才能只回收那一批，而不是把所有貨都收回來。

Docker image 的 tag 也是同樣的道理，這一部分我們就來聊聊怎麼幫 image 貼「批號」。
-->

---

# 什麼是 Image Tag？

只用預設的 `latest` tag，無法辨識正式環境跑的是哪個版本，也無法回滾（rollback）到「上一個能動的版本」。

「Tag（標籤）」是幫 image 每一個版本貼上可辨識名字的機制，格式為 `NAME[:TAG]`，例如 `ssds-api:1.2.0`。Docker 官方建構最佳實踐提醒：**tag 是「可變的」（mutable）**——同一個 tag 隨時可能被覆蓋成不同內容的 image，這也是版本策略重要的原因。

```bash
docker image tag ssds-api:latest ssds-api:1.2.0
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>批號類比：</b> tag 就像出貨批號，讓我們知道「現在雲端上跑的，究竟是哪一批貨」。
</div>

<!--
這張是概念定義頁。核心就是那句「tag 是可變的」——這句話很重要，代表同一個名字今天指到的內容，跟三個月後可能不一樣，因為有人可能重新推送覆蓋了同一個 tag。

批號的類比再強調一次：出貨如果沒貼批號，出了問題根本沒辦法追查、也沒辦法只回收有問題的那一批。Image 也一樣，沒有清楚的版本標記，出問題想回滾都不知道要滾到哪一版。
-->

---

# latest 的風險

| 情境 | 使用 latest | 使用語意化版號 |
| --- | --- | --- |
| 團隊知道目前跑哪個版本 | 不知道 | 一看 tag 就知道 |
| Rollback 回上一版 | 困難，不知道上一版是什麼 | 直接指定舊 tag 重新部署 |
| 多台機器版本是否一致 | 不保證，可能各拉到不同時間點的 latest | 一致，因為 tag 固定指向同一個內容 |
| Build 結果是否可重現 | 不可靠 | 可靠 |
| CI/CD pipeline 追蹤 | 難以稽核 | 每次 build 都有明確紀錄 |

<!--
這張表整理了如果一直依賴 latest 這個預設 tag，在正式環境會遇到的具體風險。

⚠️ 特別提醒：latest 不是「最新穩定版」的意思，它只是 Docker 沒有指定 tag 時的預設名稱，跟「穩定」、「推薦」完全沒有關係，這是很多新手會誤會的地方。
-->

---

# Tag 命名策略 — 範例

用語意化版號（Semantic Versioning，`主版本.次版本.修訂版本`）搭配 git commit hash：

```bash
# 修好商品圖片排序的 bug，只加修訂版本
docker build -t myaccount/ssds-api:1.0.1 ./ai-products-selection-backend

# 新增「選品報表匯出」功能，加次版本
docker build -t myaccount/ssds-api:1.1.0 ./ai-products-selection-backend

# 同時打上多個 tag：版本號 + git commit hash
docker build -t myaccount/ssds-api:1.1.0 \
  -t myaccount/ssds-api:$(git -C ai-products-selection-backend rev-parse --short HEAD) \
  ./ai-products-selection-backend
```

更保險的做法：搭配 digest（映像的內容雜湊值）鎖定版本，即使 tag 被覆蓋也不受影響：

```bash
docker image inspect --format '{{index .RepoDigests 0}}' myaccount/ssds-api:1.1.0
# myaccount/ssds-api@sha256:4b1c...e9
```

<!--
這頁帶大家看實際的 tag 命名範例。

語意化版號就是 SemVer：修 bug 只加最後一碼，加新功能加中間一碼，有破壞相容性的改動才加第一碼。我們專案 build.gradle 的 version 目前是 0.0.1-SNAPSHOT，實務上會讓這兩邊對齊，CI 直接讀出來用。

第三段一次 build 打上兩個 tag：版本號給人看、git commit hash 給機器精準追蹤。前後端是兩個 repo，所以用 git -C 指定要讀哪個 repo 的 commit。正式環境出包時，從雲端平台看到跑的是 ssds-api:a3f9c1e，直接 git checkout a3f9c1e 就能看到當時一模一樣的程式碼。

最後是 digest，那串 sha256 是根據 image 內容算出來的指紋。digest 只有在 push 到 registry 之後才會有，第九章部署時平台的部署紀錄裡也會顯示它。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 推送至 Docker Hub

<!--
第三部分，把做好的 image 送到 Registry，讓雲端平台可以直接拉。
-->

---

# 什麼是 Registry？

「Registry（映像倉庫）」是集中存放、管理、分享 Docker image 的地方。Docker Hub 官方說明它是**「世界上最大的容器 registry，用來存儲、管理和共享 Docker 映像」**。

| 概念 | 說明 |
| --- | --- |
| Registry | 存放 image 的伺服器服務，例如 Docker Hub、GitHub Container Registry（ghcr.io） |
| Repository | Registry 裡的一個專案空間，例如 `myaccount/ssds-api` |
| Tag | Repository 底下的具體版本，例如 `myaccount/ssds-api:1.0.0` |
| Public repository | 任何人都能 pull；免費帳號數量不限 |
| Private repository | 需要權限才能存取；免費帳號數量有限，雲端平台拉取時要另外給憑證 |

<!--
先建立這個核心觀念：Registry 就是 image 的「倉庫」，我們把組好的貨放進去，其他機器（同學的電腦、雲端平台）就可以直接從倉庫拉貨，不用重新 build 一次。

Repository 要 public 還是 private？我們的 image 裡沒有機密（.env 都被排除了），但有編譯後的程式碼，jar 是可以被反編譯的。課堂專案用 public 最簡單；如果專案需要保密，就用 private repository，第九章在雲端平台設定時多填一組 Docker Hub 的存取 token 就好。

⚠️ 易錯點：public repository 是任何人都能看、能拉的，推之前一定要確認 image 裡沒有 .env——第四章練習教過的 ls /app 檢查請再做一次。
-->

---
zoom: 0.89
---

# Build → Tag → Push 流程

| 步驟 | 指令 | 說明 |
| --- | --- | --- |
| 1. 登入 | `docker login -u myaccount` | 密碼欄位貼 **Personal Access Token**，不要用帳號密碼 |
| 2. 建置 | `docker build --platform linux/amd64 -t myaccount/ssds-api:1.0.0 .` | 依 Dockerfile 組出 image，**指定 amd64** |
| 3. 標記 | `docker image tag myaccount/ssds-api:1.0.0 myaccount/ssds-api:latest` | 需要的話加其他 tag |
| 4. 推送 | `docker image push --all-tags myaccount/ssds-api` | 上傳到 Docker Hub |
| 5. 驗證 | `docker pull myaccount/ssds-api:1.0.0` | 刪掉本機 image 後重拉，確認拉得到 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>Apple Silicon（M1～M4）的 Mac 一定要加 <code>--platform linux/amd64</code>：</b> 預設會 build 出 arm64 的 image，雲端平台幾乎都是 amd64，啟動時會出現 <code>exec format error</code>。Windows / Intel Mac 本來就是 amd64，加了也無妨。
</div>

<!--
這是這一部分最核心的一張表，把「從自己電腦到讓雲端拉得到」拆成五個步驟。

第一步 docker login：Docker Hub 建議用 Personal Access Token（在 Account settings → Personal access tokens 建立）取代帳號密碼，token 可以單獨撤銷，外洩風險小很多。

第二步的 --platform linux/amd64 是這頁最重要的提醒。Image 是跟 CPU 架構綁定的：M 系列晶片的 Mac 預設 build 出 arm64 的 image，在自己電腦跑得好好的，丟到雲端的 x86 伺服器就是 exec format error。這個錯誤訊息很不直覺，很多人卡一整個下午。Mac 上指定 amd64 會用模擬的方式 build，會慢一點，正常的。

第三步：我們在 build 時就直接用 myaccount/ssds-api 這種含帳號的完整名稱，所以不用再額外 tag 前綴；如果之前 build 的是 ssds-api:1.0.0，就要先 tag 成 myaccount/ssds-api:1.0.0 才能推。

第五步驗證：最好先 docker rmi 刪掉本機的 image 再 pull 一次，確認真的拉得到。

⚠️ 易錯點：tag 名稱一定要包含帳號，例如 myaccount/ssds-api，不能只用 ssds-api，不然會被當成要推去 Docker 官方的命名空間，直接被拒絕。
-->

---

# Build → Tag → Push — 範例

SSDS 發布 1.0.0 版的完整流程（在 `ai-products-selection/` 下）：

```bash
# 1. 登入 Docker Hub（密碼貼 Personal Access Token）
docker login -u myaccount

# 2. 建置兩個服務的 image（直接用含帳號的名稱 + 指定平台）
docker build --platform linux/amd64 -t myaccount/ssds-api:1.0.0 \
  ./ai-products-selection-backend
docker build --platform linux/amd64 -t myaccount/ssds-web:1.0.0 \
  ./ai-products-selection-frontend

# 3. 推送
docker image push myaccount/ssds-api:1.0.0
docker image push myaccount/ssds-web:1.0.0

# 或者：compose.yaml 的 image 欄位已經是 ${DOCKERHUB_USER}/ssds-xxx:${SSDS_VERSION}
DOCKER_DEFAULT_PLATFORM=linux/amd64 docker compose build && docker compose push
```

<!--
帶大家實際走一次完整流程，這就是 SSDS 推上 Docker Hub 的樣子。

兩種做法擇一：前半段是一個一個 build、push；最後一行是利用 Compose：因為我們剛剛把 compose.yaml 的 image 欄位改成含帳號、含版本的完整名稱，docker compose build 會把兩個 image 都 build 好、docker compose push 會把兩個都推上去。DOCKER_DEFAULT_PLATFORM 這個環境變數讓 Compose build 時也用 amd64。PowerShell 的話先打 `$env:DOCKER_DEFAULT_PLATFORM="linux/amd64"` 再執行。

預期結果：push 完成後到 Docker Hub 該帳號頁面，能看到 ssds-api 跟 ssds-web 兩個 repository，各有一個 1.0.0 的 tag。

⚠️ 推送過程中進度條顯示的是「未壓縮」大小，實際傳輸的資料量因為壓縮而更小。第一次推 ssds-api 壓縮後約 170MB，網路慢的話要等一下；之後改版只要推有變動的 layer（通常只有 jar 那一層）。
-->

---

# 簡單 CI/CD 概念

手動 build、tag、push、部署，步驟一多容易漏做或出錯。

「CI/CD」是 Continuous Integration（持續整合）與 Continuous Deployment/Delivery（持續部署/交付）的合稱，核心精神是**「把 build、測試、push、部署交給自動化流程，人只需要專心寫程式」**。

| 階段 | CI/CD 做的事 | SSDS 用什麼（第九章實作） |
| --- | --- | --- |
| 觸發 | 開發者 push 程式碼到 Git | GitHub |
| CI（持續整合）| 自動 build image、跑測試 | GitHub Actions（public repo 免費） |
| 打包 | 自動 tag（版本號 / commit hash）並 push | Docker Hub |
| CD（持續部署）| 通知雲端平台拉新版並重新部署 | 雲端平台的 Deploy Hook |

<!--
這張帶入 CI/CD 的概念，先講痛點：手動流程步驟一多就容易出錯，尤其團隊人數變多、部署頻率變高之後，手動操作幾乎一定會出包。

CI/CD 說穿了就是把我們前面學的 build、tag、push 這一整套流程，寫成腳本、交給自動化工具去跑，開發者只要專心把程式碼 push 上去，後面的事情工具會自動接手。

最右邊那欄是第九章會實際做的：GitHub Actions 在 push 到 main 時自動 build、push 到 Docker Hub，再呼叫雲端平台的 Deploy Hook 觸發重新部署。

補充：我們後端專案的測試有用 Testcontainers，它會在測試時自動起一個真的 PostgreSQL 容器，所以 CI 跑測試的機器也要有 Docker——GitHub Actions 的 ubuntu runner 剛好內建 Docker，這也是 Docker 在 CI/CD 裡很實用的一種應用場景。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 正式環境加固

<!--
最後一部分，把 SSDS 推上雲端前的最後一哩路：自動重啟、健康檢查、記憶體限制。
-->

---

# 健康檢查、自動重啟與資源限制

```yaml
services:
  api:
    image: ${DOCKERHUB_USER:?}/ssds-api:${SSDS_VERSION:-1.0.0}
    restart: unless-stopped                  # 掛掉自動重啟
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
這頁是三件事。

第一是 restart: unless-stopped。容器如果因為 OOM 或程式例外掛掉，Docker 會自動重啟；主機重開機它也會自己起來。unless-stopped 的意思是「除非你手動 stop，否則我一直重啟」。

第二是 healthcheck，用第四章加的 actuator。start_period 拉到 180 秒：實測限制 0.5 CPU 時 SSDS 啟動要 115 秒左右（不限制約 30 秒），寬限期太短的話第一次 up 會報 dependency failed to start。

第三是資源限制，這是重點。第九章的免費雲端方案只有 512MB 記憶體、很少的 CPU。與其部署上去才發現爆掉、然後在雲端看 log 猜原因，不如先在本機用 deploy.resources.limits 模擬一樣的條件。

JAVA_TOOL_OPTIONS 是 JVM 的記憶體調校，每一個參數都有原因：
- MaxRAMPercentage=60：堆積最多用容器上限的 60%，大約 300MB。剩下的 200MB 要留給 metaspace（我們專案類別很多：Spring、Hibernate、POI、ICU4J）、執行緒堆疊、程式碼快取。設到 75% 以上，總用量很容易超過 512MB 被系統殺掉。
- UseSerialGC：單執行緒的垃圾回收器，額外記憶體開銷最小，適合小記憶體、少 CPU 的環境。
- Xss512k：每條執行緒的堆疊從預設 1MB 降到 512KB，Tomcat 有幾十條執行緒，省下來很可觀。
- TieredStopAtLevel=1：只用 C1 編譯器，啟動更快、程式碼快取更小，代價是長時間執行的峰值效能差一點——對 demo 來說完全划算。

⚠️ 沒設這些的話，最常見的症狀是容器莫名其妙重啟，docker inspect 看到 OOMKilled: true、Exit Code 137，log 裡什麼線索都沒有。

這組參數可以直接寫進 Dockerfile 的 ENV 當預設值，下一頁會看到。
-->

---
zoom: 0.95
---

# 把 JVM 設定放進 Dockerfile

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
# 驗證：看 JVM 實際算出來的最大堆積
docker run --rm -m 512m --entrypoint java myaccount/ssds-api:1.0.0 \
  -XX:+PrintFlagsFinal -version | grep -i maxheapsize
```

<!--
把 JVM 參數寫進 Dockerfile 的 ENV 當預設值，好處是不管在本機 docker run、Compose、還是第九章的雲端平台，都自動帶上這組參數，不用每個地方各設一次。需要調整的時候，在平台上設同名環境變數就能覆蓋。

驗證指令：-m 512m 限制記憶體，--entrypoint java 讓容器改跑 java -XX:+PrintFlagsFinal -version，印出 JVM 所有參數的最終值，grep MaxHeapSize 應該看到大約 300MB 左右的數字（單位是 byte）。啟動時 log 第一行也會出現 Picked up JAVA_TOOL_OPTIONS，代表 JVM 有讀到。

⚠️ 改完 Dockerfile 記得重 build、重推，版本號 +1。
-->

---
layout: default
---

# 練習 1：上線前的機密檢查
### 任務說明

1. 在 `ai-products-selection/` 建立 Compose 層的 `.env`（`SSDS_VERSION`、`DOCKERHUB_USER`）與 `.env.example`，並確認 `.env` 不會被 Git 追蹤
2. 改寫 `compose.yaml`：image 改用 `${DOCKERHUB_USER}/ssds-xxx:${SSDS_VERSION}`，用 `docker compose config` 確認展開正確
3. 產生一組新的 `SSDS_JWT_SECRET` 寫進後端 `.env`
4. 驗證 image 裡沒有機密：
   - `docker run --rm --entrypoint ls myaccount/ssds-api:1.0.0 -la /app` 看不到 `.env`
   - `docker history --no-trunc myaccount/ssds-api:1.0.0` 裡找不到任何密碼
5. **想一想**：如果組員把 `MISTRAL_API_KEY` 寫在 Dockerfile 的 `ENV` 而且已經推上 public repo，應該做哪些事？

<!--
第一題重點在複習第一部分的核心觀念：設定與程式碼分開、密碼不進版控、也不進 image。

第 4 步的兩個驗證都很重要：ls 看檔案、history 看每一層是怎麼來的。

第 5 題答案：第一件事是到 Mistral 後台把那把 key 作廢、重發一把新的——這是唯一真正有效的補救；接著改 Dockerfile、重 build、重推，並刪掉 Docker Hub 上有問題的 tag。順序很重要：先作廢金鑰，因為 image 可能已經被別人拉走了。
-->

---
layout: default
---

# 練習 1：解題提示

```bash
# ai-products-selection/.env（不進版控）
SSDS_VERSION=1.0.0
DOCKERHUB_USER=myaccount
```

```bash
# .env.example（可進版控）
SSDS_VERSION=1.0.0
DOCKERHUB_USER=
```

```bash
docker compose config | grep image:               # 確認 image 名稱展開正確
docker run --rm alpine sh -c "head -c 48 /dev/urandom | base64"   # 產生 JWT secret
docker run --rm --entrypoint ls myaccount/ssds-api:1.0.0 -la /app
docker history --no-trunc myaccount/ssds-api:1.0.0 | grep -i -E "password|api_key|token"
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <code>ai-products-selection/</code> 本身不是 Git repo 的話，Compose 層 <code>.env</code> 不會被追蹤；如果你把 compose.yaml 放進後端 repo，就要確認那個 repo 的 <code>.gitignore</code> 有排除它。
</div>

<!--
提示給得很具體了，大家對照自己的答案看看。

⚠️ 一個要提醒的坑：.gitignore 加了 .env 之後，如果 .env 之前已經不小心 commit 過，光加 .gitignore 是沒用的。用 git log --all -- .env 可以檢查歷史裡有沒有出現過。

預期結果：ls /app 只有 app.jar 跟 uploads；history 裡 grep 不到任何東西。
-->

---
layout: default
---

# 練習 2：發布到 Docker Hub 並模擬免費方案
### 任務說明

1. 更新後端 Dockerfile，加入 `JAVA_TOOL_OPTIONS`，重新 build `ssds-api` 與 `ssds-web`（`--platform linux/amd64`）
2. 打上 `1.0.0` 與 git commit hash 兩種 tag，推送到 Docker Hub
3. 模擬部署機：`docker compose down`、刪掉本機兩個 image，再 `docker compose pull && docker compose up -d`
4. 在 compose.yaml 幫 api 加上 `memory: 512m` 限制，觀察：
   - `docker compose ps` 多久變成 healthy？
   - `docker stats` 看 api 實際用了多少記憶體？
   - 登入前端操作幾分鐘，api 有沒有重啟（`docker inspect` 看 `RestartCount` 與 `OOMKilled`）？
5. **想一想**：雲端發現 1.0.1 有嚴重 bug，要回到 1.0.0，你要改哪裡、打哪兩個指令？

<!--
第二題把 build、tag、push、部署串成一條線，也是第九章的彩排。

第 3 步請大家真的把本機 image 刪掉再拉，因為這才是「部署伺服器」的真實狀態——那台機器上沒有原始碼、沒有 JDK、沒有 Node，只有 Docker 跟設定檔。

第 4 步是第九章的事前演練。如果在本機 512MB 都撐不住，部署到雲端一定也撐不住，先在這裡調好參數。

第 5 題答案：改 Compose 層 .env 的 SSDS_VERSION=1.0.0，然後 docker compose pull && docker compose up -d。第九章的雲端平台也是同樣的概念，只是改的是平台上的 image tag。
-->

---
layout: default
zoom: 0.95
---

# 練習 2：解題提示

```bash
# 1-2. 建置、打 tag、推送
docker login -u myaccount
SHA=$(git -C ai-products-selection-backend rev-parse --short HEAD)
docker build --platform linux/amd64 \
  -t myaccount/ssds-api:1.0.0 -t myaccount/ssds-api:$SHA \
  ./ai-products-selection-backend
docker build --platform linux/amd64 -t myaccount/ssds-web:1.0.0 \
  ./ai-products-selection-frontend
docker image push --all-tags myaccount/ssds-api
docker image push --all-tags myaccount/ssds-web

# 3. 模擬部署機：清乾淨再拉
docker compose down
docker rmi myaccount/ssds-api:1.0.0 myaccount/ssds-web:1.0.0
docker compose pull && docker compose up -d

# 4. 觀察記憶體與重啟
docker stats --no-stream
docker inspect -f '{{.RestartCount}} {{.State.OOMKilled}}' ssds-api-1
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>如果 OOMKilled = true：</b> 先把 <code>MaxRAMPercentage</code> 調到 50；再不行，用環境變數關掉用不到的排程（例如 <code>SSDS_INGEST_INSTAGRAM_ENABLED=false</code>），減少背景工作吃的記憶體。
</div>

<!--
對答案時間。PowerShell 的同學，SHA 那行改成 `$SHA = git -C ai-products-selection-backend rev-parse --short HEAD`，後面的 $SHA 照用。

⚠️ 第 3 步的驗證非常重要，很多人推送完就以為結束了，但沒有實際拉取驗證過，不知道部署機是不是真的拉得到。

第 4 步大家會看到：限制 512MB、0.5 CPU 之後，Spring Boot 啟動時間會從約 30 秒變成約 115 秒（實測）。雲端免費方案的 CPU 更少，啟動會更慢，這是正常的，第九章會再提醒。

docker stats 實測 api 啟動後約 330MB（512MB 上限內）。如果貼著 512MB，就要調參數。
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
<tr><th>主題</th><th>重點回顧</th></tr>
</thead>
<tbody>
<tr><td>兩種 .env</td><td>後端 <code>.env</code> → 容器環境變數；Compose 層 <code>.env</code> → compose.yaml 的 <code>${}</code></td></tr>
<tr><td>機密值</td><td>只在執行時給；不進 Git、不進 image；<code>SSDS_JWT_SECRET</code> 上線必換</td></tr>
<tr><td>Tag 策略</td><td>語意化版號 + commit hash，不依賴 <code>latest</code></td></tr>
<tr><td>Docker Hub</td><td>用 Access Token 登入；<b><code>--platform linux/amd64</code></b></td></tr>
<tr><td>加固</td><td>restart、Actuator healthcheck、512MB 限制 + <code>JAVA_TOOL_OPTIONS</code></td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章（最後一章）：</b> 雲端部署 — 把 <code>ssds-api</code>、<code>ssds-web</code> 部署到<b>免費、免綁信用卡</b>的平台，讓全世界都連得到。
</div>

<!--
這一章我們把「上線前」該準備的事情都做完了：機密值管理、版本 tag、推到 Docker Hub、記憶體調校。

現在大家手上有：
- Docker Hub 上的兩個 image：myaccount/ssds-api:1.0.0、myaccount/ssds-web:1.0.0
- GitHub 上的兩個 repo，各自有 Dockerfile

這兩樣東西剛好對應第九章的兩種部署方式：讓雲端平台從 Docker Hub 拉現成的 image，或是讓雲端平台從 GitHub 讀 Dockerfile 自己 build。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對環境變數管理、Image Tag 策略、推送到 Docker Hub，或是 JVM 記憶體調校，有沒有什麼疑問？都歡迎提出來討論。
-->
