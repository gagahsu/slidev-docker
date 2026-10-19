---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: 部署實戰
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">部署實戰</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「從寫在自己電腦上的程式，到讓全世界都能拉下來跑的 image」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
歡迎來到最後一章，部署實戰。

前面七章，我們寫了 Dockerfile，用 Compose 組合三個服務，也設定好網路和 Volume。但在自己電腦上能跑，跟能安全地部署到伺服器給別人用，中間還隔著三件事：密碼和設定怎麼管理、每個版本的 Image 怎麼標記、Image 要怎麼送到大家都拿得到的地方。

學完這一章，我們會有一套密碼不進版控、版本清楚、出問題三十秒就能回到上一版的部署流程。
-->

---
layout: default
---

# Outline

- **環境變數管理與 .env**
- **Image 版本控制與 Tag 策略**
- **CI/CD 概念與推送至 Registry**
- **練習題**
- **總結：課程回顧**

<!--
這一章分成三部分。第一部分是環境變數和 .env 檔，這是部署前最容易出問題的地方。第二部分是 Image 的版本標記策略，讓我們知道現在跑的是哪一版程式。第三部分是 CI/CD 的基本概念，以及怎麼把 Image 推到 Registry，最後再幫正式環境加上健康檢查和資源限制。之後有兩題練習，以及整個八章課程的回顧。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 環境變數管理與 .env

<!--
先進入第一部分。很多資安事件，都是因為密碼直接寫在程式碼裡，又不小心 commit 上 GitHub。這一部分我們要把設定和程式碼分開管理。
-->

---

# 什麼是 .env 檔？

「.env 檔」是一個純文字檔，用來存放環境變數（environment variables），把資料庫密碼、API 金鑰這類會因環境（開發／測試／正式）而不同的設定，跟主程式碼分開管理。

Docker Compose 官方文件說明：**「路徑是相對於 compose.yaml 檔案的位置」**——`.env` 通常放在跟 `compose.yaml` 同一層目錄。

```bash
# .env（放在 compose.yaml 同一層）
MYSQL_ROOT_PASSWORD=rootpw
MYSQL_PASSWORD=apppw
SPRING_PROFILES_ACTIVE=prod
TASKBOARD_VERSION=1.0.0
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>小提醒：</b> .env 用 KEY=VALUE 格式，一行一個變數，沒有引號也沒有分號。
</div>

<!--
「.env 檔是一個純文字檔，用來存放環境變數」，把資料庫密碼這類會因環境而不同的設定，跟程式碼分開管理。

我們可以把它想成出門時的隨身小包。證件、鑰匙這些重要又敏感的東西放在小包裡，跟大行李分開帶。

為什麼要分開？因為程式碼會進 Git。密碼一旦進了 Git 的歷史紀錄，就算之後刪掉檔案，舊的 commit 裡還是找得到。

範例裡放的，就是前面幾章一直寫死在 compose.yaml 裡的值，資料庫密碼、Spring 的 profile，還有 Image 的版本號。之前為了教學方便直接寫死，這一章我們要把它們全部搬出來。

格式很簡單，一行一個 KEY 等於 VALUE。
-->

---

# .env 在 compose.yaml 中的用法

| 用法 | 語法 | 說明 |
| --- | --- | --- |
| `environment`（映射語法）| `DEBUG: "true"` | 直接寫死在 compose.yaml |
| `environment`（列表語法）| `- DEBUG=true` | 同上，另一種寫法 |
| `env_file` | `env_file: "webapp.env"` | 指定外部檔案載入整批變數 |
| 插值引用 | `- DEBUG=${DEBUG}` | 從 .env 或 shell 讀值代入 |
| 命令列臨時覆蓋 | `docker compose run -e DEBUG=1 web` | 執行當下才決定的值 |

<!--
這張表整理了在 compose.yaml 裡設定環境變數的幾種方式，我們挑重點看。

前兩列的 environment，是直接把值寫在 compose.yaml 裡，有兩種寫法，效果一樣。

第三列的 env_file，是指定一個外部檔案，一次載入整批變數。變數很多的時候，這樣 compose.yaml 會比較乾淨。

最重要的是第四列，插值引用。用錢字號加大括號，Compose 會從 .env 或目前的 shell 讀取實際的值代入。同一份 compose.yaml，就能在不同環境跑不同的設定，這一章接下來都會用這個寫法。
-->

---

# .env 用法 — 範例

把 TaskBoard 的 compose.yaml 改成完全不含密碼的版本：

```yaml
# compose.yaml — 這份可以安心進版控
services:
  web:
    image: myaccount/taskboard-web:${TASKBOARD_VERSION}
    ports: ["8080:80"]
  api:
    image: myaccount/taskboard-api:${TASKBOARD_VERSION}
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://db:3306/taskboard
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: ${MYSQL_PASSWORD}
      SPRING_PROFILES_ACTIVE: ${SPRING_PROFILES_ACTIVE}
```

<!--
這一頁把 TaskBoard 的 compose.yaml 改成完全不含密碼的版本。因為比較長，拆成兩頁，這頁先看 web 和 api。

對照第五章那份，差別就是所有敏感的值，都換成了插值。

先看 image 那行，版本號也用了 TASKBOARD_VERSION。要升版或回到舊版，只要改 .env 裡的一行，再執行一次 `docker compose up -d`，compose.yaml 完全不用動。

api 的資料庫密碼，則是從 MYSQL_PASSWORD 這個變數讀進來。
-->

---

# .env 用法 — 範例（續）

```yaml
services:
  # ...（接上頁 web、api）
  db:
    image: mysql:8.4
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: taskboard
      MYSQL_USER: appuser
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes: [db-data:/var/lib/mysql]

volumes:
  db-data:
```

<!--
接著看 db。root 密碼和應用帳號的密碼，也都換成了插值。

Compose 會自動讀取同一層目錄的 .env，把這些佔位符換成實際的值。所以這份 compose.yaml 完全不含密碼，可以放心 commit 進 Git，給任何人看。

這裡有一個最多人搞混的地方。.env 裡的變數，是用來替換 Compose 檔案本身的文字，不會自動變成容器裡的環境變數。api 拿得到密碼，是因為我們在 environment 裡明確寫了 SPRING_DATASOURCE_PASSWORD 引用它。只寫在 .env、沒有在 environment 引用的變數，容器裡是看不到的。

啟動之後，用 `docker compose exec api env` 搭配 grep，就能確認密碼確實被注入了容器。
-->

---

# 使用 .env 的注意事項

Docker Compose 官方最佳實踐明確提到：**「Be cautious about including sensitive data in environment variables. Consider using Secrets for managing sensitive information.」**（謹慎處理環境變數中的敏感資料，考慮改用 Secrets 管理）

```bash
# .gitignore
.env
*.env.local
taskboard-api/src/main/resources/application-local.yml
```

```bash
# .env.example — 這份要進版控，只寫欄位不寫真值
MYSQL_ROOT_PASSWORD=
MYSQL_PASSWORD=
SPRING_PROFILES_ACTIVE=prod
TASKBOARD_VERSION=1.0.0
```

<div class="mt-4 p-3 bg-red-50 border-l-4 border-red-400 text-gray-700 text-sm text-left">
⚠️ <b>絕對不要把 .env commit 進 Git！</b> 一旦密碼進了版控歷史，就算之後刪除檔案，舊 commit 裡還是找得到，等於永久外洩。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>建議做法：</b> 專案裡放一份 `.env.example`（只寫欄位名稱，不寫真實值），讓團隊成員知道要設定哪些變數，真正的 `.env` 由每個人自己建立、絕不進版控。
</div>

<!--
這一頁是第一部分最重要的提醒。

延續隨身小包的比喻，如果我們把小包裡的東西拍照發到公開社群，那跟沒分開放也沒兩樣。.env 也是一樣，只要它進了 Git，效果就跟寫死在程式碼裡一樣糟。

所以專案一開始，就要把 .env 加進 .gitignore，養成習慣，不要等到不小心 commit 了才補救。

那新同事怎麼知道要設定哪些變數？團隊常見的做法是放一份 `.env.example`，只寫欄位名稱，不寫真正的值，這份可以進版控。

另外官方也建議，正式環境真正機密的資料，不要只靠環境變數，可以進一步改用 Docker Secrets 這類專門的機密管理機制。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Image 版本控制與 Tag 策略

<!--
接下來進入第二部分，Image 的版本控制。就像工廠出貨，每一批貨都要貼上批號，出了問題才能精準追查和回收。
-->

---

# 什麼是 Image Tag？

只用預設的 `latest` tag，無法辨識正式環境跑的是哪個版本，也無法回滾（rollback）到「上一個能動的版本」。

「Tag（標籤）」是幫 image 每一個版本貼上可辨識名字的機制，格式為 `NAME[:TAG]`，例如 `my-app:1.2.0`。Docker 官方建構最佳實踐提醒：**tag 是「可變的」（mutable）**——同一個 tag 隨時可能被覆蓋成不同內容的 image，這也是版本策略重要的原因。

```bash
docker image tag taskboard-api:latest taskboard-api:1.2.0
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>批號類比：</b> tag 就像出貨批號，讓我們知道「現在正式環境跑的，究竟是哪一批貨」。
</div>

<!--
如果只用預設的 latest，我們無法知道正式環境跑的是哪個版本，出問題時也不知道要回到哪一版。

「Tag 是幫 image 每一個版本貼上可辨識名字的機制」，就像貨物的批號，讓我們知道現在正式環境跑的，到底是哪一批貨。

這裡要特別注意官方的提醒，tag 是可變的。同一個 tag，隨時可能被重新推送、覆蓋成不同內容的 Image。今天拉到的 `nginx:1.27`，跟三個月後拉到的，內容可能不一樣。

所以 tag 本質上只是一個可以被移動的指標，不是固定不變的版本。要真正鎖死內容，要搭配等一下會提到的 digest。
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
這張表整理了一直依賴 latest，在正式環境會遇到的風險。

看第一列，用 latest 的話，團隊根本不知道現在跑的是哪個版本，因為每次 build 都可能覆蓋它。

第二列更嚴重。正式環境出問題想回到上一版，如果只有 latest，我們不知道上一個能動的版本是什麼，因為它已經被新的蓋掉了。

第三列也很常見。好幾台機器在不同時間拉 latest，可能各自拿到不同的內容。

再強調一次，latest 不是「最新穩定版」的意思。它只是沒有指定 tag 時的預設名稱，跟穩定、推薦完全沒有關係。
-->

---

# Tag 命名策略 — 範例

用語意化版號（Semantic Versioning，`主版本.次版本.修訂版本`）搭配環境標記：

```bash
# 修好任務刪除的 bug，只加修訂版本
docker build -t taskboard-api:1.2.1 ./taskboard-api

# 新增「任務標籤」功能，加次版本
docker build -t taskboard-api:1.3.0 ./taskboard-api

# 同時打上多個 tag：版本號 + git commit hash + 環境
docker build -t taskboard-api:1.3.0 \
  -t taskboard-api:$(git rev-parse --short HEAD) \
  -t taskboard-api:staging ./taskboard-api
```

更保險的做法：搭配 digest（映像的內容雜湊值）鎖定版本，即使 tag 被覆蓋也不受影響：

```dockerfile
FROM eclipse-temurin:21-jre-alpine@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c
```

<!--
這一頁看實際的命名方式。

語意化版號的格式是主版本、次版本、修訂版本。修 bug 只加最後一碼，例如 1.2.1。加新功能加中間一碼，例如 1.3.0。有不相容的改動，才加第一碼。這個版本號實務上會跟 build.gradle 裡的 version 對齊。

第三段一次打上三個 tag。1.3.0 給人看，git commit hash 給機器精準追蹤，staging 讓部署流程判斷要送到哪個環境。三個 tag 指向同一份 Image。

commit hash 特別有價值。正式環境出問題時，看到跑的是哪個 hash，直接 checkout 那個 commit，就能看到當時一模一樣的程式碼。

最後是更保險的 digest，也就是 sha256 開頭的那串雜湊值，它是依照 Image 內容算出來的指紋。就算 tag 被覆蓋，鎖定 digest 還是能拿到原本的版本。這串很長，通常由 CI 流程自動產生。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# CI/CD 概念與推送至 Registry

<!--
最後一部分，我們來看怎麼把 Image 送出去，以及 CI/CD 是怎麼把整個流程自動化的。
-->

---

# 什麼是 Registry？

每次到新機器跑程式都重新複製原始碼、重新 build，速度慢，環境差異也容易造成「這邊能跑，那邊跑不動」的問題。

「Registry（映像倉庫）」是集中存放、管理、分享 Docker image 的地方，用來解決這個問題。Docker Hub 官方說明它是**「世界上最大的容器 registry，用來存儲、管理和共享 Docker 映像」**。

| 概念 | 說明 |
| --- | --- |
| Registry | 存放 image 的伺服器服務，例如 Docker Hub |
| Repository | Registry 裡的一個專案空間，例如 `myaccount/taskboard-api` |
| Tag | Repository 底下的具體版本，例如 `myaccount/taskboard-api:1.2.0` |
| Public repository | 任何人都能 pull，數量不限 |
| Private repository | 需要權限才能存取，適合內部專案 |

<!--
如果每到一台新機器，都要重新複製原始碼、重新 build，不但慢，環境差異也很容易造成「這邊能跑，那邊不能跑」。

「Registry 是集中存放、管理、分享 Docker image 的地方。」我們把做好的 Image 放進去，同事的電腦或正式伺服器，就能直接拉下來用。

表格裡三個名詞容易搞混，可以想成倉庫、貨架和批號。Registry 是整個倉庫服務，像 Docker Hub。Repository 是倉庫裡的一個貨架，例如 `myaccount/taskboard-api`。Tag 則是貨架上具體的那一批貨，也就是版本。

要注意，public repository 任何人都能拉。還沒公開的專案，或含有機密資訊的 Image，不要推到公開的地方。
-->

---

# Build → Tag → Push 流程

| 步驟 | 指令 | 說明 |
| --- | --- | --- |
| 1. 登入 | `docker login [REGISTRY_URL]` | 驗證帳號權限，Docker Hub 可省略網址 |
| 2. 建置 | `docker build -t taskboard-api:1.2.0 ./taskboard-api` | 依 Dockerfile 組出 image |
| 3. 標記 | `docker image tag taskboard-api:1.2.0 myaccount/taskboard-api:1.2.0` | 加上 registry/使用者前綴 |
| 4. 推送 | `docker image push myaccount/taskboard-api:1.2.0` | 上傳到 Registry |
| 5. 驗證 | `docker pull myaccount/taskboard-api:1.2.0` | 從部署伺服器測試拉取 |

<!--
這張表把「從自己的電腦，到讓別人拉得到」拆成五個步驟。

第一步登入，向 Registry 證明我們的身分。第二步 build，照 Dockerfile 組出 Image。

第三步很多新手會漏掉。推送之前，要把 Image 標記成包含帳號的完整名稱。只用 `taskboard-api` 的話，會被當成要推到官方的命名空間，直接被拒絕。

第四步才是真正上傳。第五步是驗證，最好換一台機器，或先刪掉本機的 Image，重新拉一次，確認別人真的拉得到、拉得對。

順帶一提，TaskBoard 只需要推 api 和 web 兩個 Image。資料庫直接用官方的 `mysql:8.4`，這也是一個實務原則，能用官方 Image 就不要自己包。
-->

---

# Build → Tag → Push — 範例

TaskBoard 發布 1.2.0 版的完整流程：

```bash
# 1. 登入 Docker Hub
docker login

# 2. 建置兩個服務的 image
docker build -t taskboard-api:1.2.0 ./taskboard-api
docker build -t taskboard-web:1.2.0 ./taskboard-web

# 3. 標記成含帳號的完整名稱
docker image tag taskboard-api:1.2.0 myaccount/taskboard-api:1.2.0
docker image tag taskboard-api:1.2.0 myaccount/taskboard-api:latest
docker image tag taskboard-web:1.2.0 myaccount/taskboard-web:1.2.0

# 4. 推送
docker image push --all-tags myaccount/taskboard-api
docker image push myaccount/taskboard-web:1.2.0

# 5. 在部署伺服器上：改 .env 的版本號後拉新版重啟
#    TASKBOARD_VERSION=1.2.0
docker compose pull && docker compose up -d
```

<!--
這一頁把五個步驟實際走一次，這就是 TaskBoard 上線的樣子。

第三步同時打了 1.2.0 和 latest。版本號用來精準追蹤，latest 方便沒指定版本時拉取。但正式環境的 compose.yaml，一定要明確寫版本號。

第四步的 `--all-tags`，會一次推送這個 repository 的所有標籤。

第五步是把前面所有東西串起來的地方。部署伺服器上不需要原始碼、不需要 JDK、也不需要 Node，只要有 Docker、一份 compose.yaml 和一份 .env。要升版，就改 .env 的版本號，再執行 pull 和 up 兩個指令，Compose 會自動重建有變動的服務。

回到上一版也一樣簡單，把版本號改回去，同樣兩行指令，三十秒就完成。這就是堅持打版本 tag 的回報。
-->

---

# 簡單 CI/CD 概念

手動 build、tag、push、部署，步驟一多容易漏做或出錯。

「CI/CD」是 Continuous Integration（持續整合）與 Continuous Deployment/Delivery（持續部署/交付）的合稱，核心精神是**「把 build、測試、push、部署交給自動化流程，人只需要專心寫程式」**。

| 階段 | CI/CD 做的事 |
| --- | --- |
| 觸發 | 開發者 push 程式碼到 Git |
| CI（持續整合）| 自動 build image、跑測試 |
| 打包 | 自動 tag（例如用 commit hash 或版本號）|
| CD（持續部署）| 自動 push 到 Registry，再部署到伺服器 |

<!--
手動 build、tag、push、部署，步驟一多，就很容易漏做或出錯。團隊人數變多、部署變頻繁之後，更是幾乎一定會出問題。

「CI/CD 的核心精神，是把 build、測試、push、部署交給自動化流程，人只需要專心寫程式。」

看這張表，流程是這樣的。開發者把程式碼 push 到 Git，CI 自動 build Image 並執行測試。測試通過後自動打上 tag，CD 再自動推到 Registry，部署到伺服器。GitHub Actions、GitLab CI 這些工具，做的就是這件事。

這裡我們先建立觀念，不深入特定工具的語法。說穿了，CI/CD 跑的就是我們剛才手動打的那些指令。

【講師】可補充 Testcontainers：Spring Boot 整合測試可以直接開一個真正的 MySQL 8.4 容器，不用再用 H2 假裝成 MySQL。
-->

---

# 正式環境加固：健康檢查與資源限制

```yaml
services:
  api:
    image: myaccount/taskboard-api:${TASKBOARD_VERSION}
    restart: unless-stopped              # 掛掉自動重啟，主機重開也會自己起來
    healthcheck:                         # 用 Actuator 判斷「活著」
      test: ["CMD", "wget", "-qO-", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 40s                  # 給 Spring Boot 啟動的寬限時間
    deploy:
      resources:
        limits:   { cpus: "1.0", memory: 1g }    # 上限：不准吃垮主機
        reservations: { memory: 512m }           # 保留：至少要有這麼多
    environment:
      JAVA_TOOL_OPTIONS: "-XX:MaxRAMPercentage=75"   # JVM 依容器記憶體上限調整堆積
```

<!--
推上正式環境之前，還有最後一哩路，這份設定做了三件事。

第一是 restart。容器因為錯誤停掉，Docker 會自動重啟，主機重開機也會自己起來。unless-stopped 的意思是除非我們手動 stop，否則一直重啟。

第二是 healthcheck，用 Spring Boot Actuator 的 health 端點判斷服務是否正常。Java 程式還在跑，但資料庫連線池已經滿了，這種情況只有健康檢查抓得到。注意 start_period，Spring Boot 啟動要二三十秒，沒有寬限期，它會在啟動途中就被判定為不健康。

第三是資源限制。JVM 預設會依照整台主機的記憶體決定能用多少。萬一 API 有記憶體洩漏，可能把整台機器連同資料庫一起拖垮。設了 1g 的上限，超過時只有這個容器被停掉，其他服務不受影響。

最後一行是 Java 專屬的配套，讓 JVM 堆積最多只用容器上限的 75%。沒設的話，可能還沒觸發垃圾回收，就先被 Docker 強制停掉，只留下 Exit Code 137，很難追查。
-->

---
layout: default
---

# 練習 1：把 TaskBoard 的密碼從版控裡趕出去
### 任務說明

拿出第五章那份 `compose.yaml`，裡面 `rootpw`、`apppw` 都是明文寫死的。請完成：

1. 建立 `.env`，把 `MYSQL_ROOT_PASSWORD`、`MYSQL_PASSWORD`、`TASKBOARD_VERSION` 移進去
2. 改寫 `compose.yaml`，全部改用 `${}` 插值，確保檔案裡**看不到任何一個明文密碼**
3. 把 `.env` 加進 `.gitignore`，並建立可進版控的 `.env.example`
4. 幫 `taskboard-api` 與 `taskboard-web` 補上語意化版號 tag `1.0.0`
5. 驗證：`docker compose up -d` 之後，用 `docker compose exec api env | grep SPRING` 確認密碼真的有被注入容器

<!--
接下來是練習一，把 TaskBoard 的密碼從版控裡趕出去。

拿出第五章那份 compose.yaml，把密碼和版本號移到 .env，compose.yaml 全部改用插值。再把 .env 加進 .gitignore，並建立 `.env.example`。最後用 exec 驗證密碼真的有被注入容器。

請大家先想一個問題：如果 Compose 找不到某個變數，會發生什麼事？它會報錯，還是默默代入其他值？

我們先暫停一下，自己動手試試看。

【講師】給大家十分鐘左右，提醒第五步的驗證一定要做。
-->

---
layout: default
---

# 練習 1：解題提示

```bash
# .env（不進版控）
MYSQL_ROOT_PASSWORD=rootpw
MYSQL_PASSWORD=apppw
TASKBOARD_VERSION=1.0.0
```

```yaml
# compose.yaml 片段
  db:
    image: mysql:8.4
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
```

```bash
echo ".env" >> .gitignore
docker image tag taskboard-api:latest taskboard-api:1.0.0
docker compose config          # 展開後檢查變數有沒有正確代入
docker compose exec api env | grep SPRING
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <code>docker compose config</code> 會印出「變數展開後」的完整設定，是檢查 <code>${}</code> 有沒有代入成功最快的方法。
</div>

<!--
我們來看解題的關鍵。

回答剛才的問題。Compose 找不到變數時，不會中斷，而是默默代入空字串。結果密碼變成空的，資料庫就連不上。所以第五步的驗證很重要。

這裡特別推薦 `docker compose config` 這個指令。它會把所有插值展開後印出來，變數有沒有讀到、讀到什麼值，一目了然。不過也因為它會印出明文密碼，不要在共用螢幕或錄影的場合使用。

另一個要注意的坑是，如果 .env 之前已經 commit 過，光是加進 .gitignore 沒有用，舊的 commit 裡還找得到。最正確的做法是直接把那組密碼換掉，因為它已經外洩了。
-->

---
layout: default
---

# 練習 2：完整發布 TaskBoard 到 Registry
### 任務說明

把 TaskBoard 1.0.0 版發布出去，並模擬部署伺服器拉取。

1. 登入 Docker Hub
2. 建置 `taskboard-api` 與 `taskboard-web` 的 1.0.0 版 image
3. 標記成含帳號的完整名稱（版本號 + `latest` + git commit hash 三種 tag）
4. 推送到 Registry
5. 模擬部署伺服器：刪掉本機 image 後重新 `pull`，用只有 `compose.yaml` + `.env` 的方式啟動整套
6. **想一想**：正式環境發現 1.0.0 有嚴重 bug，要在三十秒內回到 0.9.0，你要改哪裡、打哪兩個指令？

<!--
練習二是整個課程的收尾題，把 TaskBoard 1.0.0 版完整發布出去。

任務是登入、建構兩個 Image、打上版本號、latest 和 commit hash 三種 tag，推送到 Registry。第五步請大家真的把本機的 Image 刪掉，再重新拉取，只用 compose.yaml 和 .env 啟動整套。因為這才是部署伺服器的真實狀態，沒有原始碼，只有 Docker 和兩個設定檔。

第六題請大家想一想：正式環境發現 1.0.0 有嚴重的 bug，要在三十秒內回到 0.9.0，要改哪裡？打哪兩個指令？

我們先暫停一下，自己動手試試看。

【講師】給大家十五分鐘左右，沒有 Docker Hub 帳號的同學可以先註冊。
-->

---
layout: default
---

# 練習 2：解題提示

```bash
# 1-2. 登入並建置
docker login
docker build -t taskboard-api:1.0.0 ./taskboard-api
docker build -t taskboard-web:1.0.0 ./taskboard-web

# 3. 三種 tag
GIT_SHA=$(git rev-parse --short HEAD)
docker image tag taskboard-api:1.0.0 myaccount/taskboard-api:1.0.0
docker image tag taskboard-api:1.0.0 myaccount/taskboard-api:latest
docker image tag taskboard-api:1.0.0 myaccount/taskboard-api:$GIT_SHA

# 4. 推送
docker image push --all-tags myaccount/taskboard-api
docker image push --all-tags myaccount/taskboard-web

# 5. 模擬部署機：清乾淨再拉
docker compose down
docker rmi myaccount/taskboard-api:1.0.0 myaccount/taskboard-web:1.0.0
docker compose pull && docker compose up -d
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>第 6 題答案：</b> 改 <code>.env</code> 的 <code>TASKBOARD_VERSION=0.9.0</code>，然後
<code>docker compose pull && docker compose up -d</code> — 這就是版本 tag 存在的全部意義。
</div>

<!--
我們來看解答。順序很重要，不登入就推送會被拒絕，沒有標記成含帳號的名稱，就推不到正確的地方。

第五步的驗證非常重要。很多人推送完就以為結束了，但沒有實際拉取過，就不知道部署機是不是真的拿得到、拿到的是不是預期的版本。

回答第六題。把 .env 的 TASKBOARD_VERSION 改成 0.9.0，然後執行 pull 和 up 兩個指令，三十秒就回到上一版。出事時能快速回到上一個好的版本，就是我們堅持打版本 tag、不依賴 latest 的全部理由。

回頭看，第一章我們只用 docker run 起了一個 MySQL。到了第八章，TaskBoard 已經有一套版本化、密碼不進版控、可以快速回滾的完整部署流程。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 9px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — 課程回顧

<table class="summary-table">
<thead>
<tr><th>章節</th><th>核心一句話</th></tr>
</thead>
<tbody>
<tr><td>Ch1 Docker 簡介</td><td>Container 比 VM 更輕量，共用作業系統核心</td></tr>
<tr><td>Ch2 映像檔管理</td><td>Image 是唯讀模板，Container 是執行實例</td></tr>
<tr><td>Ch3 容器操作</td><td>run / exec / logs 是每天都會用到的基本功</td></tr>
<tr><td>Ch4 Dockerfile</td><td>用一份可重複執行的腳本，取代手動組 image</td></tr>
<tr><td>Ch5 Docker Compose</td><td>用 YAML 一次定義、啟動多個服務</td></tr>
<tr><td>Ch6 網路設定</td><td>自訂 bridge network 取代已淘汰的 --link</td></tr>
<tr><td>Ch7 Volume 資料持久化</td><td>資料要活得比 container 久，就交給 Volume</td></tr>
<tr><td>Ch8 部署實戰</td><td>.env 管密碼、tag 管版本、Registry 負責分享</td></tr>
</tbody>
</table>

<!--
最後，我們把八章串起來回顧一次。

第一章，我們知道 Container 比 VM 更輕量。第二章，Image 是模板，Container 是實例。第三章學會 run、exec、logs 這些基本功。第四章用 Dockerfile 把組 Image 的過程寫成腳本。第五章用 Compose 一次啟動多個服務。第六章用自訂網路讓容器用名字溝通。第七章用 Volume 讓資料活得比容器久。這一章，則用 .env、版本 tag 和 Registry，把 TaskBoard 正式送出去。

這八章其實是一條完整的路徑，從認識容器，到能獨立把一個專案部署上線。
-->

---
layout: default
---

# 本章總結 — 最後叮嚀

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> 密碼別進版控、image 別只靠 <code>latest</code>、推送前一定要驗證，做到這三件事就避開了新手最常踩的坑。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🎉 <b>恭喜完成全部 8 章：</b> 接下來找一個自己的小專案，實際走一次 Dockerfile、Compose、tag、push 完整流程，動手做過一次才會變成真正的技能。
</div>

<!--
最後留給大家三句話。密碼別進版控，Image 別只靠 latest，推送之後一定要驗證。做到這三件事，就已經避開了新手最常踩的坑。

接下來，建議大家找一個自己的小專案，實際走一次 Dockerfile、Compose、tag、push 的完整流程。動手做過一次，才會真正變成自己的技能。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
這門 Docker 課程到這裡就全部結束了。我們從「在我電腦上可以跑」出發，一路把 TaskBoard 變成在任何裝了 Docker 的機器上都能跑的專案。

謝謝大家這八章的參與，祝大家在之後的專案裡，都能用上這些容器化的技能。

【講師】開放 Q&A，可以引導大家回想 .env 和 environment 的差別、回滾流程，或整門課的任何問題。
-->
