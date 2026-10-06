---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: 映像檔管理
routeAlias: ch02
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">映像檔管理</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「Image 是模板，Container 是執行實例」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
【開場白】
本章主題是「映像檔管理」。上一章介紹了 Container 是隔離的執行環境，本章說明 Container 的來源：Image（映像檔）。

【學習目標】
- 理解 Image 的組成與 Layer 結構
- 使用 pull、push、images、rmi、tag 管理 Image
- 掌握 Docker Hub 的使用方式與 Tag 命名慣例
-->

---
layout: default
---

# Outline

- **Image 概念與 Layer 結構**
- **常用指令**
  - pull / push / images / rmi / tag
- **Docker Hub 與 Tag 命名規則**
- **實作練習**

<!--
【帶讀大綱】
本章分為三個部分：第一部分建立 Image 的基本觀念，說明 Layer 的設計；第二部分實際操作 Image 相關指令；第三部分介紹 Docker Hub 與 Tag 的命名慣例。

【重點預告】
最後兩題練習分別針對基本指令與私有 Registry 的發布流程。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Image 概念與 Layer 結構

<!--
【段落轉換】
第一部分說明 Image 的定義，以及採用分層結構的原因。後續所有指令操作的對象都是 Image，先建立觀念再學指令會更容易理解。
-->

---

# 什麼是 Image？

**Image（映像檔）** 是標準化的封裝，包含執行 Container 所需的檔案、函式庫、執行環境與設定。

- Image 是唯讀的模板，內容不隨執行環境改變
- Container 是依 Image 啟動的執行實例；同一個 Image 可同時啟動多個 Container

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>重點：</b>Image 是「模板」，Container 是「執行中的實例」。
</div>

<!--
【生活化比喻】
連鎖餐廳若沒有標準食譜，各分店的口味就會不一致。Image 如同標準食譜：無論在哪台電腦或伺服器上執行，只要使用同一個 Image，產生的環境即完全相同。

【易錯點提醒 ⚠️】
Image 與 Container 常被混淆：Image 是靜態的模板；Container 是以模板啟動後的動態實例。

【預期結果】
能以一句話說明 Image 與 Container 的差別。
-->

---

# Image 的 Layer 結構

Image 採用分層（Layer）架構，每一層記錄一組檔案系統的變更（新增、刪除或修改檔案）。

以 SSDS 後端 `ssds-api` 為例：

| 層級 | 內容 |
| --- | --- |
| 最底層 | 作業系統基礎環境（Alpine Linux） |
| 中間層 | JRE 21 執行環境（`eclipse-temurin:21-jre-alpine`） |
| 上一層 | Gradle 產出的相依函式庫 |
| 最上層 | 專案打包的 `ssds.jar` |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>重點：</b>Layer 建立後不可修改，只能在既有 Layer 上疊加新 Layer；相同的 Layer 可被多個 Image 共用，不需重複下載。
</div>

<!--
【生活化比喻】
如同建造房屋：地基完成後不會拆除重建，而是往上加蓋樓層。Image 的每一層都是疊加上去的變更，下層不會被修改。

【核心說明】
分層設計的好處：多個 Image 若使用相同的基礎層，只需下載與儲存一次，節省空間並加快下載速度。

【易錯點提醒 ⚠️】
修改 Image 中的檔案並不會改動原本的 Layer，而是建立新的 Layer 疊加在上方，這就是 Image「不可變（immutable）」的意義。

【業界實務】
以 SSDS 為例：開發期間 Controller 可能一天修改十多次，但底層的 Alpine 與 JRE 21 不變。重新建置 Image 時只需重做最上層的 jar，因此容器化專案的重新建置速度很快。

【預期結果】
理解下載 Image 時部分 Layer 顯示 `Already exists` 的原因：本機已有相同的 Layer。
-->

---

# Registry 與 Image 的關係

**Registry** 是儲存與分發 Image 的服務。Docker Hub 是 Docker 預設的公開 Registry。

常見的 Image 來源：

| 類型 | 說明 |
| --- | --- |
| Docker Official Image | 例如 `nginx`、`eclipse-temurin`、`postgres`，由 Docker 與上游社群共同維護 |
| Verified Publisher | 經 Docker 驗證的廠商所發布的 Image |
| 個人 / 組織 Image | 開發者自行推送的 Image |

<!--
【生活化比喻】
Registry 如同食譜分享網站，Docker Hub 是其中規模最大者：可直接使用現成的食譜，也可分享自己的食譜。

【業界實務】
實務上很少從零建立 Image，而是以 Docker Hub 上的官方 Image 作為基礎。官方 Image 會定期更新以修補安全漏洞，較為安全可靠。

【易錯點提醒 ⚠️】
Registry 不只 Docker Hub 一種。企業內部常架設私有 Registry（例如 registry-host:5000），雲端廠商也提供各自的 Registry（如 GitHub Container Registry `ghcr.io`）。後續 push 的範例會使用私有 Registry。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 常用指令：pull / push / images / rmi

<!--
【段落轉換】
第二部分實際操作 Image 相關的常用指令：pull、push、images、rmi、tag。這些是日常開發最頻繁使用的指令。
-->

---

# Image 常用指令總覽

| 指令 | 說明 |
| --- | --- |
| `docker pull` | 從 Registry 下載 Image 至本機 |
| `docker push` | 將本機 Image 上傳至 Registry |
| `docker images` | 列出本機所有 Image（等同 `docker image ls`） |
| `docker rmi` | 刪除本機 Image（等同 `docker image rm`） |
| `docker tag` | 為 Image 新增標籤（常搭配 push 使用） |
| `docker image prune` | 刪除未被標記（dangling）的 Image |

<!--
【重點解說】
指令名稱即表達其動作：pull 下載、push 上傳、images 列出、rmi 為 remove image 的縮寫。

【易錯點提醒 ⚠️】
`docker rmi` 與 `docker rm` 不同：rm 刪除 Container，rmi 刪除 Image。
-->

---

# docker pull — 範例

下載 SSDS 後續章節使用的基礎 Image：

```bash
# 未指定 tag 時預設為 latest（不建議用於專案）
docker pull nginx

# 指定版本：SSDS 專案統一使用以下 Image
docker pull eclipse-temurin:21-jdk-alpine  # build 階段：以 ./gradlew 編譯後端
docker pull eclipse-temurin:21-jre-alpine  # runtime：執行 ssds.jar
docker pull node:22-alpine                 # build 階段：ng build 前端
docker pull nginx:1.30-alpine              # runtime：提供 Angular 靜態檔

# 從私有 Registry 下載
docker pull registry-host:5000/myadmin/ssds-api:1.0.0
```

下載時會逐層顯示進度；本機已存在的 Layer 會顯示 `Already exists`，不會重複下載。

<!--
【帶讀關鍵行】
- `docker pull nginx`：未指定 tag，預設下載 `latest`。
- 下方四行為專案實際做法：明確指定版本，避免上游改版後行為或設定語法不相容。
- 四個 Image 分為兩組：jdk 與 node 用於「編譯」，jre 與 nginx 用於「執行」。第四章的 multi-stage build 即以編譯用 Image 建置程式，最後只將成品放入執行用 Image。

【概念定義】
`eclipse-temurin:21-jre-alpine` 的命名意義：
- temurin：Eclipse Adoptium 維護的 OpenJDK 發行版
- 21：Java 版本，對應 build.gradle 中 toolchain 的 21
- jre：僅包含執行環境，不含編譯器
- alpine：精簡的 Linux 發行版
選用 jre 與 alpine，Image 大小可由四百多 MB 降至約兩百 MB。

【易錯點提醒 ⚠️】
`latest` 並非「最新穩定版」，只是一個標籤名稱，維護者可指向任何版本。專案中應一律指定版本。

【預期結果】
執行 `docker images` 可看到上述 Image 皆已下載至本機。
-->

---

# docker images / docker rmi — 範例

```bash
# 列出本機所有 Image（Docker Engine 29 起的預設格式）
docker images

# IMAGE                          ID             DISK USAGE   CONTENT SIZE   EXTRA
# eclipse-temurin:21-jre-alpine  71e0d3f8a1b2      195MB         58MB
# node:22-alpine                 c1d2e3f4a5b6      160MB         40MB
# ssds-api:1.0.0                 8f3c1a92be04      480MB        170MB    U
# ssds-api:latest                8f3c1a92be04      480MB        170MB    U
# ssds-web:1.0.0                 2d47e5b310cc       95MB         26MB

# 以 Image ID 刪除
docker rmi 2d47e5b310cc

# 以 repository:tag 刪除
docker rmi ssds-web:1.0.0
```

<!--
【帶讀關鍵行】
- Docker Engine 29 起，`docker images` 的預設輸出改為 IMAGE（repository:tag 合併為一欄）、ID、DISK USAGE（解壓後佔用的磁碟空間）、CONTENT SIZE（壓縮後的內容大小，約等於 push 時的傳輸量）、EXTRA（`U` 表示有容器正在使用）。如需舊版的分欄格式，可使用 `docker images --format "table {{.Repository}}	{{.Tag}}	{{.ID}}	{{.Size}}"`。
- `ssds-api:1.0.0` 與 `ssds-api:latest` 的 ID 相同，代表兩者為同一份 Image，只是有兩個標籤，磁碟上只佔一份空間。

【重點解說】
大小比較：ssds-web 不到 100MB，因為 Angular 打包後僅約 2MB 靜態檔加上精簡版 nginx；ssds-api 將近 500MB，其中 ssds.jar 接近 100MB（包含 Spring Boot、Apache POI、ICU4J 等套件），其餘為 JRE 與 Alpine。第四章介紹 multi-stage build 時會再比較。

【易錯點提醒 ⚠️】
Image 若仍有 Container 使用（無論執行中或已停止），docker rmi 會失敗。須先刪除相關 Container，或加上 -f 強制刪除。

【預期結果】
刪除後再次執行 docker images，該 Image 不再出現於清單中。
-->

---

# docker push — 語法與選項

`docker image push [OPTIONS] NAME[:TAG]`：將本機 Image 上傳至 Registry。

| 選項 | 說明 |
| --- | --- |
| `-a`, `--all-tags` | 推送該 repository 的所有標籤 |
| `--platform` | 推送指定平台的版本，例如 `linux/amd64` |
| `-q`, `--quiet` | 精簡輸出，不顯示詳細進度 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>重點：</b>push 前須先以 <code>docker login</code> 登入，且 Image 名稱須包含目標 Registry 位址與命名空間。
</div>

<!--
【概念定義】
push 為 pull 的反向操作：將本機建置的 Image 上傳至 Registry，其他人或伺服器即可直接 pull 使用，不需重新建置。

【易錯點提醒 ⚠️】
- 未登入時 push 會被拒絕，錯誤訊息通常包含 unauthorized。
- Docker 預設會同時推送多個 Layer，因此進度列會有多條同時更新。
-->

---

# docker push — 範例

將本機的 `ssds-api` 推送至公司內部 Registry：

```bash
# Step 1：登入 Registry
docker login registry-host:5000

# Step 2：為本機 Image 加上目標位置的 tag
docker image tag ssds-api:1.0.0 registry-host:5000/myadmin/ssds-api:1.0.0

# Step 3：推送
docker push registry-host:5000/myadmin/ssds-api:1.0.0

# 推送該 repository 的所有標籤
docker push -a registry-host:5000/myadmin/ssds-api
```

<!--
【帶讀關鍵行】
本機的 `ssds-api:1.0.0` 不能直接推送，必須先以 `docker image tag` 加上包含目標 Registry 位址的名稱，Docker 才能判斷推送目的地。名稱未包含 Registry 位址時，預設推送至 Docker Hub。

【業界實務】
這些指令通常寫在 CI 腳本中：Gradle 建置 jar、docker build 建立 Image、加上版本 tag、push 至 Registry，伺服器端再 pull 並重新啟動。第八、九章會完整實作此流程。

【易錯點提醒 ⚠️】
`docker image tag` 不是「改名」，而是「新增標籤」。原本的 `ssds-api:1.0.0` 仍然存在，兩個名稱指向同一個 Image ID。

【預期結果】
推送成功後，可於 Registry 的網頁介面看到對應的 repository 與 tag。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Docker Hub 與 Tag 命名規則

<!--
【段落轉換】
第三部分介紹 Docker Hub 平台，以及 Tag 的命名慣例。缺乏命名規範時，團隊協作容易混淆版本。
-->

---

# 什麼是 Docker Hub？

**Docker Hub** 是 Docker 官方的 Image Registry 服務，提供 Image 的儲存、管理與分享。

| 功能 | 說明 |
| --- | --- |
| Repository（儲存庫） | 存放同一專案不同版本的 Image；公開儲存庫不限數量，免費帳號另可建立 1 個私人儲存庫 |
| 官方 / 驗證 Image | 提供品質經驗證的 Image，可直接作為基礎 |
| 拉取次數限制 | 匿名：每 IP 每 6 小時 100 次；免費帳號：每 6 小時 200 次 |
| 搜尋 | 於網站或以 `docker search` 搜尋 Image |

<!--
【生活化比喻】
Docker Hub 可視為「Image 版的 GitHub」：GitHub 存放程式碼，Docker Hub 存放打包好的 Image，同樣區分公開與私人儲存庫。

【業界實務】
企業內部專案通常使用私人 Repository 避免商業邏輯外流；開源工具則多放在公開 Repository。Docker Hub 的自動建置（Automated Builds）僅限付費方案，實務上多改用 GitHub Actions 建置後推送（第九章實作）。

【重點提醒】
課堂上多人共用同一個對外 IP 時，匿名的拉取額度容易用完，出現 `toomanyrequests` 錯誤；執行 `docker login` 登入後額度即提高。

【易錯點提醒 ⚠️】
任何人都能上傳 Image 至 Docker Hub，並非每個 Image 都安全可信。應優先選用標示為「Docker Official Image」或「Verified Publisher」的來源。
-->

---

# Tag（標籤）命名規則

**Tag** 是附加在 Image 名稱後的識別字串，格式為 `repository:tag`，用於區分同一 Image 的不同版本。

| 命名方式 | 範例 | 用途 |
| --- | --- | --- |
| 語意化版本 | `ssds-api:1.4.2` | 明確標示版本號，正式環境首選 |
| 主版本簡寫 | `ssds-api:1.4`、`ssds-api:1` | 允許在次版本範圍內自動更新 |
| latest | `ssds-api:latest` | 預設標籤，正式環境不應依賴 |
| 環境標籤 | `ssds-api:staging`、`ssds-api:prod` | 依部署環境區分 |
| Commit / 建置編號 | `ssds-api:git-a1b2c3d` | 精確對應某次程式碼版本，便於追蹤 |

<!--
【生活化比喻】
若便當只標示「今日便當」而不寫日期，就無法得知是哪一天製作的。Tag 命名越明確，追查問題或回復版本越容易。

【業界實務】
成熟的團隊會為同一次建置同時加上多個 tag，例如 `1.4.2` 與 `git-a1b2c3d`：前者便於閱讀，後者可精確對應程式碼的 commit。

【易錯點提醒 ⚠️】
正式環境不可只依賴 `latest`。latest 會持續被覆寫，今天與明天部署的 latest 內容可能完全不同，造成「本機測試正常、正式環境出錯」的情況。
-->

---

# Tag 命名 — 實際範例

SSDS 後端發布新版本的流程：

```bash
# 在 ai-products-selection-backend/ 下建置 Image（Dockerfile 於第四章撰寫）
docker build -t ssds-api:latest .

# 加上不同精細度的版本 tag
docker image tag ssds-api:latest ssds-api:1.4.2
docker image tag ssds-api:latest ssds-api:1.4

# 推送至 Docker Hub（帳號為 myaccount）
docker image tag ssds-api:latest myaccount/ssds-api:1.4.2
docker image tag ssds-api:latest myaccount/ssds-api:1.4
docker push -a myaccount/ssds-api
```

<!--
【帶讀關鍵行】
同一次建置加上 `latest`、`1.4`、`1.4.2` 三種精細度的 tag：測試環境可固定使用 `1.4`，自動取得修補版本；正式環境則鎖定 `1.4.2`，版本完全固定。

【業界實務】
版本號 `1.4.2` 通常來自 build.gradle 中的 `version = '1.4.2'`，由 CI 腳本讀取後作為 tag，使程式碼版本與 Image 版本一致。

【易錯點提醒 ⚠️】
推送至 Docker Hub 時，Image 名稱前須加上帳號或組織名稱（如 `myaccount/ssds-api`）；否則會被視為推送至官方命名空間 `library/`，遭到拒絕。

【預期結果】
推送完成後，Docker Hub 上該帳號的 Repository 頁面顯示 `1.4.2` 與 `1.4` 兩個 tag。
-->

---
layout: default
---

# 練習 1：準備 SSDS 的基礎 Image
### 任務說明

準備 SSDS 後續章節所需的基礎 Image：

1. 從 Docker Hub 下載 `eclipse-temurin:21-jre-alpine`（用於執行 `ssds.jar`）
2. 以 `docker images` 確認本機已有此 Image，記錄其 ID 與大小
3. 為此 Image 新增標籤 `ssds-runtime:v1`
4. 刪除原本的 `eclipse-temurin:21-jre-alpine` 標籤（保留 `ssds-runtime:v1`）
5. 再次執行 `docker images`，確認 `ssds-runtime:v1` 仍存在，且 ID 與第 2 步相同

<!--
【任務鋪陳】
本題練習 pull、images、tag、rmi 四個指令，同時下載第四章將使用的 runtime Image。

【問題引導】
刪除 `eclipse-temurin:21-jre-alpine` 後，`ssds-runtime:v1` 是否會一併消失？請從 Image ID 與 tag 的關係思考，並於第 5 步驗證。
-->

---
layout: default
---

# 練習 1：參考答案

```bash
# 1. 下載
docker pull eclipse-temurin:21-jre-alpine

# 2. 確認並記錄 ID（例如 71e0d3f8a1b2）與 DISK USAGE（約 195MB）
docker images eclipse-temurin

# 3. 新增標籤
docker image tag eclipse-temurin:21-jre-alpine ssds-runtime:v1

# 4. 移除原標籤：輸出 Untagged: eclipse-temurin:21-jre-alpine
docker rmi eclipse-temurin:21-jre-alpine

# 5. ssds-runtime:v1 仍存在，ID 與第 2 步相同
docker images ssds-runtime
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>說明：</b>tag 只是指向 Image ID 的標籤。刪除其中一個標籤時僅輸出 <code>Untagged</code>，底層 Image 不會刪除；只有在最後一個標籤也被移除時，Image 才會從磁碟刪除（輸出 <code>Deleted</code>）。
</div>

<!--
【帶讀解法】
第 4 步的輸出只有 `Untagged`，沒有 `Deleted`，即證明底層 Image 仍然存在。

【易錯點提醒 ⚠️】
若刪除的是最後一個指向該 Image 的標籤，Image 才會真正從磁碟刪除。

【預期結果】
最後一次 docker images 只顯示 `ssds-runtime:v1`，不再顯示 `eclipse-temurin:21-jre-alpine`，兩者的 ID 相同。
-->

---
layout: default
---

# 練習 2：發布 ssds-api 至私有 Registry
### 任務說明

SSDS 後端完成一批錯誤修正，要發布 `2.0.0` 版至公司內部私有 Registry（位址 `registry-host:5000`，命名空間 `myadmin`）：

1. 本機已有建置完成的 Image `ssds-api:latest`
2. 為其加上 `2.0.0` 與 `2.0` 兩種版本標籤，並包含正確的 Registry 位址前綴
3. 登入該 Registry
4. 推送 `2.0.0` 版本
5. **思考題**：測試環境的部署腳本應使用哪一個 tag？正式環境呢？

<!--
【任務鋪陳】
本題結合 Tag 命名規則與 push 指令，情境與實際發布流程一致。

【問題引導】
若希望同事直接取得「最新的 2.0 系列版本」而不需記住完整版本號，tag 應如何設計？

【重點提醒】
本題重點不只是寫出指令，而是依語意化版本的精神設計 tag。
-->

---
layout: default
---

# 練習 2：參考答案

```bash
# 2. 加上兩種版本標籤與 Registry 前綴
docker image tag ssds-api:latest registry-host:5000/myadmin/ssds-api:2.0.0
docker image tag ssds-api:latest registry-host:5000/myadmin/ssds-api:2.0

# 3. 登入私有 Registry
docker login registry-host:5000

# 4. 推送指定版本
docker push registry-host:5000/myadmin/ssds-api:2.0.0

# （選用）一次推送 2.0.0 與 2.0
docker push -a registry-host:5000/myadmin/ssds-api
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>第 5 題答案：</b>測試環境使用 <code>2.0</code>，發布 2.0.1 修補版後重新部署即自動取得；正式環境鎖定 <code>2.0.0</code>，除非明確修改版本號，否則不會變動。
</div>

<!--
【帶讀解法】
Image 名稱須完整包含 `registry-host:5000/myadmin/` 前綴，Docker 以此判斷推送的 Registry 與命名空間；遺漏前綴會推送至錯誤位置或失敗。

【補充】
`-a` 選項可一次推送該 repository 的所有標籤。

【預期結果】
推送完成後，於 Registry 的網頁介面可看到 `ssds-api` repository 下的 `2.0.0` tag。
-->

---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — 映像檔管理

<table class="summary-table">
<thead>
<tr><th>重點</th><th>說明</th></tr>
</thead>
<tbody>
<tr><td>Image vs Container</td><td>Image 是標準化的封裝模板，Container 是依 Image 啟動的執行實例</td></tr>
<tr><td>Layer 架構</td><td>Layer 建立後不可修改，相同 Layer 可在不同 Image 間共用</td></tr>
<tr><td>核心指令</td><td><code>pull</code> 下載、<code>push</code> 上傳、<code>images</code> 列出、<code>rmi</code> 刪除、<code>tag</code> 加標籤</td></tr>
<tr><td>Registry</td><td>Docker Hub 為預設的公開 Registry；企業可架設私有 Registry</td></tr>
<tr><td>Tag 命名</td><td>採用語意化版本（例如 <code>1.4.2</code>），正式環境避免依賴 <code>latest</code></td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>重點：</b>Image 建置後不可變；發布新版本應加上新的 Tag，而非覆寫 <code>latest</code>。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b>容器操作 — <code>run</code>、<code>exec</code>、<code>logs</code> 等日常指令。
</div>

<!--
【回顧】
本章說明了 Image 的分層設計，操作 pull、push、images、rmi、tag 等指令，並介紹 Docker Hub 的功能與 Tag 命名慣例。

【課程預覽】
下一章介紹容器操作，包含建立、進入、查看 log 與刪除容器。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
【互動引導】
開放提問：Image 的分層結構、pull / push / images / rmi 指令，或 Tag 命名慣例，有任何疑問皆可提出。
-->
