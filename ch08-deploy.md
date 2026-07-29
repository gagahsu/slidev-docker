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
大家好，歡迎來到最後一章「部署實戰」。

前面七章我們已經學會怎麼寫 Dockerfile、怎麼用 Compose 組合多個服務、怎麼設定網路和 Volume。這一章要把這些技能兜在一起，聊聊「怎麼把東西送到正式環境（production）」這件事。

為什麼要學這個？因為在自己電腦上 `docker compose up` 能跑，跟能安全地部署到伺服器上讓別人用，中間還隔著三件事：怎麼管理設定與密碼、怎麼幫每個版本的 image 做好標記、怎麼把 image 送到大家都能取用的地方。這三件事就是今天的主軸。

學完這章，大家應該能夠自己寫出一份不會外洩密碼的 .env、幫專案訂出一套 tag 命名規則，並且知道 CI/CD 大概在做什麼、怎麼把 image push 上 registry。
-->

---
layout: default
---

# Outline

- **第一部分：環境變數管理與 .env**
- **第二部分：Image 版本控制與 Tag 策略**
- **第三部分：CI/CD 概念與推送至 Registry**
- **練習題**
- **總結：課程回顧**

<!--
今天分成三大部分。

第一部分講環境變數跟 .env 檔，這是部署前最容易踩雷的地方，很多資安事件都是密碼不小心被 commit 上去造成的。

第二部分講 image 的版本控制，也就是 tag 策略，讓我們知道現在跑的到底是哪一版程式碼。

第三部分講 CI/CD 的基本概念，還有怎麼把做好的 image 推送到 Registry（倉庫）上，讓其他機器可以拉下來用。

最後會有兩題練習，還有整個八章課程的總回顧。大家準備好了嗎，我們開始吧。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第一部分
# 環境變數管理與 .env

<!--
先進入第一部分。大家有沒有遇過這種情況：程式碼裡直接寫死了資料庫密碼、API 金鑰，結果不小心把整包程式 commit 上 GitHub，密碼就這樣公開給全世界看？

這一部分我們就是要解決這個問題，學會用 .env 檔案把「設定」跟「程式碼」分開管理。
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
大家先记住這個類比：.env 就是我們的隨身小包，重要但敏感的東西放這裡，跟主程式（大行李）分開走。

為什麼要分開？因為程式碼通常會進版本控制（Git），但密碼、金鑰這種東西一旦進了 Git 歷史紀錄，就很難徹底清除，就算之後刪掉檔案，舊的 commit 紀錄裡還是找得到。

⚠️ 這裡先預告一個等一下會再三強調的重點：.env 檔絕對不要 commit 進版控，等一下的注意事項會細講怎麼避免。

範例裡放的就是 TaskBoard 前面幾章一直寫死在 compose.yaml 裡的那些值：資料庫密碼、Spring 的 profile、還有 image 版本號。前面幾章為了教學方便直接寫死，這一章我們要把它們全部搬出來。
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
這張表整理了在 compose.yaml 裡設定環境變數的幾種方式。

最直接的是用 environment 屬性，可以用映射（key: value）或列表（- key=value）兩種語法，效果一樣，看團隊習慣選一種。

如果變數很多，建議用 env_file 指到外部檔案，這樣 compose.yaml 本身乾淨清爽，也方便針對不同環境（開發/正式）切換不同的 env 檔。

插值語法 ${DEBUG} 則是讓 compose.yaml 去讀取 .env 檔或當下 shell 環境的值，這個很常用在「同一份 compose.yaml，不同環境跑不同設定」的情境。

⚠️ 易錯點：env_file 是 Docker Compose CLI 才有的插值功能，如果是單純用 `docker run --env-file`，語法規則不完全一樣，大家換工具時要留意。
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
這張是範例頁，帶大家看一次完整做法。對照第五章那份 compose.yaml，差別就是所有敏感值都換成了 ${} 插值。

Compose 會自動去讀同一層目錄的 .env，把 ${MYSQL_PASSWORD} 這種佔位符換成實際的值。所以這份 compose.yaml 現在完全不含密碼，可以放心 commit 進 Git、可以貼在文件裡、可以給任何人看。

⚠️ 請大家注意一個很重要的區別，這是最多人搞混的：.env 裡的變數是給「Compose 檔案本身」做文字替換用的，不會自動變成容器裡的環境變數。api 服務之所以拿得到密碼，是因為我們在 environment 區塊明確寫了 SPRING_DATASOURCE_PASSWORD: ${MYSQL_PASSWORD}。如果只在 .env 裡寫了某個變數，卻沒在 environment 裡引用它，容器裡是看不到那個變數的。

另外看 image 那行：版本號也用了 ${TASKBOARD_VERSION}。這樣要升版或回滾，只要改 .env 裡的一行版本號，再 docker compose up -d 就好，compose.yaml 完全不用動。這是實務上很常見的做法。

預期結果：docker compose up 之後，用 docker compose exec api env | grep SPRING 可以看到密碼確實被注入容器了，但 compose.yaml 裡沒有任何一個明文密碼。
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
這頁是這個部分最重要的提醒，一定要講清楚。

生活比喻延續前面：隨身小包很重要，但如果我們把小包的內容物拍照發到公開社群，那跟沒分開放也沒兩樣。.env 就算跟程式碼分開放在同一個資料夾，只要它進了 Git，效果就跟寫死在程式碼裡一樣糟。

⚠️ 大家一定要在專案一開始就把 .env 加進 .gitignore，養成習慣，不要等到不小心 commit 了才補救。

另外官方也建議，真正機密的東西（像是正式環境的資料庫密碼）不要只靠環境變數，更進階的做法是用 Docker Secrets 這類專門的機密管理機制，環境變數比較適合非機密、或是開發測試用的設定。

實務上團隊常見做法是放一份 .env.example 當範本，這個檔案可以進版控，因為裡面沒有真的密碼，只有告訴大家「這裡需要填 DB_PASSWORD」這種欄位提示。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第二部分
# Image 版本控制與 Tag 策略

<!--
接下來進入第二部分，聊聊 image 的版本控制。

大家想像一下，工廠出貨的時候，每一批貨都會貼上批號，這樣如果某一批貨出了問題，才能精準地追查是哪一批、什麼時候生產的，也才能只回收那一批，而不是把所有貨都收回來。

Docker image 的 tag 也是同樣的道理，這一部分我們就來聊聊怎麼幫 image 貼「批號」。
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
這張是概念定義頁。核心就是那句「tag 是可變的」——這句話很重要，代表同一個名字（例如 nginx:3.21）今天指到的內容，跟三個月後可能不一樣，因為原作者可能重新推送覆蓋了同一個 tag。

批號的類比再強調一次：出貨如果沒貼批號，出了問題根本沒辦法追查、也沒辦法只回收有問題的那一批。Image 也一樣，沒有清楚的版本標記，出問題想回滾都不知道要滾到哪一版。

⚠️ 易錯點：很多初學者以為 tag 是「固定不變」的版本號，其實不是，除非搭配 digest（下一頁會提到），否則 tag 本質上只是一個可以被覆蓋的指標。
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

大家看第一列，latest 完全無法告訴我們現在跑的是哪個版本，因為每次 build 都可能覆蓋掉 latest 指向的內容。

第二列更嚴重，一旦正式環境出包想回滾，如果只靠 latest，我們根本不知道「上一個能動的版本」是什麼，因為它已經被新的 latest 蓋掉了。

⚠️ 特別提醒：latest 不是「最新穩定版」的意思，它只是 Docker 沒有指定 tag 時的預設名稱，跟「穩定」、「推薦」完全沒有關係，這是很多新手會誤會的地方。
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
這頁帶大家看實際的 tag 命名範例。

語意化版號就是 SemVer，格式是主版本.次版本.修訂版本。修 bug 只加最後一碼，加新功能加中間一碼，有破壞相容性的改動才加第一碼。順帶一提，這個版本號實務上會跟 build.gradle 裡的 version 對齊，CI 直接讀出來用。

第二段範例展示一次 build 打上三個 tag：1.3.0 給人看、git commit hash 給機器精準追蹤是哪次 commit、staging 給部署流程判斷要送去哪個環境。三個 tag 指向同一份 image，硬碟只佔一份。

那個 commit hash 的 tag 特別有價值。正式環境出包的時候，你從監控看到跑的是 taskboard-api:a3f9c1e，直接 git checkout a3f9c1e 就能看到當時一模一樣的程式碼，不用猜。

最後 Docker 官方文件特別提到更保險的做法是搭配 digest，也就是那串 sha256 開頭的雜湊值，這是根據 image 內容算出來的指紋，就算之後同一個 tag 被別人覆蓋成不同內容，我們鎖定 digest 的話還是能保證拿到原本那個版本。

⚠️ 易錯點：digest 那串很長，通常不會手動記，而是在 CI/CD 流程裡自動產生、自動寫入設定檔。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第三部分
# CI/CD 概念與推送至 Registry

<!--
最後一部分，我們來聊聊怎麼把 image 送出去，還有簡單認識一下 CI/CD 是什麼。

想像我們前面辛苦組好的貨（image），總得要有個倉庫可以寄放、也要有一套穩定的流程，確保每次出貨的品管都一致，這就是這一部分要講的東西。
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
先建立這個核心觀念：Registry 就是 image 的「倉庫」，我們把組好的貨放進去，其他機器（不管是同事的電腦還是正式環境的伺服器）就可以直接從倉庫拉貨，不用重新組一次。

Docker Hub 是最知名、也是最大的公開 Registry，但企業內部也常常會架設自己的私有 Registry。

表格裡把幾個容易搞混的名詞釐清一下：Registry 是整個倉庫服務，Repository 是倉庫裡的一個專案分類，Tag 才是掛在 Repository 底下的具體版本。三層關係大家可以想成「倉庫 > 貨架 > 貨物批號」。

⚠️ 易錯點：public repository 是任何人都能看、能拉的，不要把還沒公開的專案或含有機密資訊的 image 誤推到 public repository。
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
這是這一部分最核心的一張表，把「從自己電腦到讓別人拉得到」拆成五個步驟。

第一步 docker login 是先跟 Registry 證明「我是這個帳號」，登入憑證由 docker login 統一管理，之後 push 才有權限。

第二步 build 大家很熟了，就是照 Dockerfile 把 image 組出來。

第三步很多新手會漏掉：推送前必須把 image 標記成「registry 位址/帳號/名稱:tag」的完整格式，因為 Docker 預設推去 Docker Hub，如果沒加前綴或前綴不是我們自己的帳號，push 會失敗或推錯地方。

第四步才是真正的上傳動作，第五步則是驗證，最好找另一台機器（或先刪掉本機的 image）重新 pull 一次，確認別人真的拉得到、也拉得對。

⚠️ 易錯點：第三步的 tag 名稱一定要包含帳號或組織名稱，例如 myaccount/taskboard-api，不能只用 taskboard-api，不然會被當成要推去官方保留的命名空間，通常會被拒絕。

順帶提醒，TaskBoard 有兩個 image 要推：taskboard-api 跟 taskboard-web。db 不用推，因為它直接用官方的 mysql:8.4。這也是一個實務原則——能用官方 image 就別自己包。
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
帶大家實際走一次完整流程，這就是 TaskBoard 真正上線的樣子。

注意第 3 步同時打了 1.2.0 跟 latest：語意化版號給精準追蹤用，latest 方便沒指定版本時的預設拉取。但正式環境的 compose.yaml 一定要明確寫版本號，不要依賴 latest。

第 5 步是這頁最實用的一段，也是把前面所有東西串起來的地方。部署伺服器上不需要有原始碼、不需要裝 JDK、不需要裝 Node，只要有 Docker、一份 compose.yaml 跟一份 .env。要升版就改 .env 裡的 TASKBOARD_VERSION，然後 compose pull 把新 image 拉下來、compose up -d 讓 Compose 自動把有變動的服務重建重啟。

回滾更簡單：.env 改回 1.1.0，同樣兩行指令，三十秒回到上一版。這就是我們前面堅持要有版本 tag 的回報。

預期結果：push 完成後到 Docker Hub 該帳號頁面，能看到 taskboard-api 跟 taskboard-web 兩個 repository。

⚠️ 推送過程中進度條顯示的是「未壓縮」大小，實際傳輸的資料量因為壓縮而更小，所以不用太在意進度條顯示的數字比預期的檔案大。
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
這張帶入 CI/CD 的概念，先講痛點：手動流程步驟一多就容易出錯，尤其團隊人數變多、部署頻率變高之後，手動操作幾乎一定會出包。

CI/CD 說穿了就是把我們前面學的 build、tag、push 這一整套流程，寫成腳本、交給自動化工具去跑，開發者只要專心把程式碼 push 上去，後面的事情工具會自動接手。

表格描述的是最基本的流程骨架：開發者 push 程式碼 → CI 工具自動 build 並跑測試 → 測試過了自動打 tag → CD 工具自動推送並部署。像 GitHub Actions、GitLab CI 這些工具都是在做這件事。

⚠️ 這裡先講觀念，不深入特定工具的設定語法，重點是理解「自動化取代手動重複步驟」這個核心精神，等大家有需要時再去查特定 CI/CD 工具的文件。

補充一提，testcontainers.com 這類工具也常被整合進 CI 流程裡，用來在自動化測試階段直接啟動真實的資料庫、訊息佇列等容器做整合測試，這也是 Docker 在 CI/CD 裡很實用的一種應用場景。對 Spring Boot 專案來說特別好用——整合測試不用再靠 H2 假裝自己是 MySQL，直接開一個真的 MySQL 8.4 容器來跑。
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
這頁是把 TaskBoard 推上正式環境前的最後一哩路，三件事。

第一是 restart: unless-stopped。容器如果因為 OOM 或程式例外掛掉，Docker 會自動重啟；主機重開機它也會自己起來。不加這行，半夜服務掛了就是掛到早上。unless-stopped 的意思是「除非你手動 stop，否則我一直重啟」，比 always 好，因為你手動停掉的服務不會被硬拉起來。

第二是 healthcheck，這裡用 Spring Boot Actuator 的 /actuator/health。這比單純看「容器有沒有在跑」精準太多——Java 行程還活著，但資料庫連線池爆了、應用其實已經沒有服務能力，這種情況只有健康檢查抓得到。注意 start_period 那行，Spring Boot 啟動要二三十秒，沒有寬限期的話它會在啟動途中就被判定不健康。

第三是資源限制，這是很多人忽略但很重要的一項。JVM 預設會看「整台主機」有多少記憶體來決定堆積大小，主機有 32GB 它就敢用 8GB。萬一 API 有記憶體洩漏，它會一路吃到把整台機器連同資料庫一起拖垮。設了 memory: 1g 之後，容器最多用 1GB，超過就只有這個容器被 OOM kill 掉，其他服務不受影響——爆炸有邊界。

那個 JAVA_TOOL_OPTIONS 的 MaxRAMPercentage 是 Java 專屬的配套。新版 JVM 已經看得懂容器的記憶體上限，這行是明確告訴它「堆積最多用容器上限的 75%」，剩下的留給 metaspace、執行緒堆疊這些非堆積記憶體。⚠️ 沒設這個的話，JVM 堆積可能貼著容器上限成長，然後在 GC 之前就先被 Docker 殺掉，log 裡什麼線索都沒有，只留下一個 Exit Code 137，很難查。
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
第一題重點在複習前兩部分的核心觀念：設定與程式碼分開、密碼不進版控、版本要有明確標記。

第 5 步的驗證很重要，因為改成 ${} 之後最常見的失敗是「Compose 找不到變數，就默默代入空字串」，結果密碼變成空的，資料庫連不上。用 exec env 檢查一次最保險。

給同學一點時間動手，等一下看提示。
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
提示給得很具體了，大家對照自己的答案看看。

我特別想推薦 docker compose config 這個指令，很多人不知道。它會把 ${} 全部展開之後印出來，變數有沒有讀到、讀到什麼值，一目了然。⚠️ 但也因為它會印出明文密碼，不要在共用螢幕或會被錄影的場合亂打。

⚠️ 另一個要提醒的坑：.gitignore 加了 .env 之後，如果 .env 之前已經不小心 commit 過，光加 .gitignore 是沒用的，舊 commit 裡還找得到。這種情況要處理 Git 歷史，而且最正確的做法是——直接把那組密碼換掉，因為它已經外洩了。
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
第二題是整個課程的收尾題，把 build、tag、push、部署串成一條線，這些步驟正是 CI/CD 自動化背後實際執行的指令。

第 5 步請大家真的把本機 image 刪掉再拉，因為這才是「部署伺服器」的真實狀態——那台機器上沒有原始碼、沒有 JDK、沒有 Node，只有 Docker 跟兩個設定檔。能跑起來，就證明我們八章學的容器化真的完成了。

第 6 題是我最想留給大家的一個觀念。答案是：改 .env 裡的 TASKBOARD_VERSION=0.9.0，然後 docker compose pull && docker compose up -d。就這樣，三十秒。這個能力——出事能快速回到上一個好版本——就是我們前面堅持要打版本 tag、堅持不用 latest 的全部理由。
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
對答案時間。重點是理解「為什麼是這個順序」：不登入就 push 會被拒絕；不 tag 成含帳號的格式，push 目標會不對。

⚠️ 第 5 步的驗證非常重要，很多人推送完就以為結束了，但沒有實際拉取驗證過，不知道部署機是不是真的拉得到、拉到的是不是預期的版本。養成「推送後一定驗證」的習慣。

最後回顧一下我們這八章對 TaskBoard 做了什麼：第一章用 docker run 起了一個 MySQL，第八章我們有一套版本化、密碼不落地、可以三十秒回滾的完整部署流程。同一個專案，從「在我電腦上可以跑」變成「在任何裝了 Docker 的機器上都能跑」。這就是容器化。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — 課程回顧

<table class="summary-table">
<tr><th>章節</th><th>核心一句話</th></tr>
<tr><td>Ch1 Docker 簡介</td><td>Container 比 VM 更輕量，共用作業系統核心</td></tr>
<tr><td>Ch2 映像檔管理</td><td>Image 是唯讀模板，Container 是執行實例</td></tr>
<tr><td>Ch3 容器操作</td><td>run / exec / logs 是每天都會用到的基本功</td></tr>
<tr><td>Ch4 Dockerfile</td><td>用一份可重複執行的腳本，取代手動組 image</td></tr>
<tr><td>Ch5 Docker Compose</td><td>用 YAML 一次定義、啟動多個服務</td></tr>
<tr><td>Ch6 網路設定</td><td>自訂 bridge network 取代已淘汰的 --link</td></tr>
<tr><td>Ch7 Volume 資料持久化</td><td>資料要活得比 container 久，就交給 Volume</td></tr>
<tr><td>Ch8 部署實戰</td><td>.env 管密碼、tag 管版本、Registry 負責分享</td></tr>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> 密碼別進版控、image 別只靠 <code>latest</code>、推送前一定要驗證，做到這三件事就避開了新手最常踩的坑。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🎉 <b>恭喜完成全部 8 章：</b> 接下來找一個自己的小專案，實際走一次 Dockerfile、Compose、tag、push 完整流程，動手做過一次才會變成真正的技能。
</div>

<!--
八章課程走到這裡，我們一起回顧一下整個學習路徑。

從最開始理解 Container 跟 VM 的差異，到學會操作 image 跟 container，再到用 Dockerfile 把「怎麼組 image」寫成腳本、用 Compose 把多個服務兜在一起，接著補上網路和資料持久化這兩塊基礎建設知識，最後這一章則是把「怎麼安全、有版本紀錄地把東西送出去」補齊。

這八個章節其實是一條完整的路徑：從「認識容器」到「能夠獨立把一個專案部署出去」。走到這裡，大家已經具備完整部署一個 Docker 化專案所需要的核心知識了。

⚠️ 最後提醒一次貫穿整個部署章節最重要的一句話：密碼別進版控、image 別只靠 latest、推送前一定要驗證。這三件事做到，就已經避開了新手最常踩的坑。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對環境變數管理、Image Tag 策略，或是 CI/CD 與推送到 Registry 的流程，有沒有什麼疑問？都歡迎提出來討論。

恭喜大家完成八章課程，接下來記得回來翻翻各章節的投影片，或直接查閱 Docker 官方文件，祝大家部署順利！
-->
