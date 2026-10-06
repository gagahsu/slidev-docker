---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: 容器操作
routeAlias: ch03
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">容器操作</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「從啟動到移除，掌握容器的完整生命週期」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
【開場白】
本章主題是「容器操作」。前兩章已介紹 Image 與 Docker 的基本架構，本章開始實際操作容器，完整走過「建立、執行、停止、刪除」的生命週期。

【學習目標】
學完本章，我們能獨立啟動容器、進入容器檢查環境、查看容器輸出的 log，並正確清除不再使用的容器。

【學習建議】
本章指令較多，不需要死背；重點是理解每個指令作用在生命週期的哪個階段。
-->

---
layout: default
---

# Outline

- **容器基本操作**
  - run / ps / stop / start / rm
- **前景與背景執行**
  - `-it` 與 `-d`、`docker exec`
- **容器生命週期**
  - 狀態轉換、`docker logs`
- **實作練習**

<!--
【帶讀大綱】
本章分為三個部分：第一部分介紹管理容器的五個基本指令；第二部分說明前景執行與背景執行的差異，以及如何進入執行中的容器；第三部分將前述指令串成完整的生命週期，並介紹以 logs 除錯的方法。

【重點預告】
最後安排兩題實作練習，以 SSDS 後端為對象，把本章指令實際操作一遍。所有指令建議在終端機實際執行，僅閱讀投影片不易記住。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 容器基本操作

<!--
【段落轉換】
第一部分從五個基本指令開始：run、ps、stop、start、rm。

【易錯點提醒 ⚠️】
stop 與 rm 是最常被混淆的兩個指令：stop 只是停止容器，容器本體與其中的資料仍然存在；rm 才是刪除容器。
-->

---

# 什麼是 docker run？

`docker run` 從指定的 Image 建立一個新的 Container 並啟動它；若本機沒有該 Image，會先自動從 Registry 下載。

```bash
docker run hello-world
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>注意：</b>每次執行 <code>docker run</code> 都會建立新的容器；即使 Image 相同，產生的容器也是不同的個體。啟動既有容器應使用 <code>docker start</code>。
</div>

<!--
【概念定義】
docker run 實際上包含兩個動作：依 Image 建立容器（create），再啟動它（start）。

【生活化比喻】
Image 像一份食譜，docker run 則是依照同一份食譜開一間新的分店；開幾次就有幾間店。

【範例目的】
hello-world 是 Docker 官方用來驗證安裝是否成功的最小 Image，執行後印出歡迎訊息，容器隨即結束。

【易錯點提醒 ⚠️】
docker run 每次都是「新建」，不是「開啟」。重新啟動已停止的容器應使用 docker start。

【預期結果】
終端機印出 "Hello from Docker!" 歡迎訊息。
-->

---

# docker run 的語法結構

| 指令 / 選項 | 說明 |
| --- | --- |
| `docker run [OPTIONS] IMAGE [COMMAND]` | 基本語法結構 |
| `-d`, `--detach` | 背景執行（detached mode），僅輸出 Container ID |
| `-it` | 互動模式，配置終端機（下一部分說明）|
| `--name` | 指定容器名稱 |
| `--rm` | 容器結束後自動刪除 |
| `-p 主機port:容器port` | 將容器內的 port 映射到主機 |
| `-e KEY=VALUE` | 設定環境變數 |

<!--
【重點解說】
此表整理 docker run 最常用的選項：-d 控制是否背景執行、-it 控制是否互動、--name 指定名稱、--rm 讓容器結束後自動清除、-p 設定 port 映射、-e 設定環境變數。

【易錯點提醒 ⚠️】
-p 的順序固定為「主機 port : 容器 port」，方向寫反會導致服務無法連線。
-->

---

# docker run — 範例

第四章才會撰寫 Dockerfile，本頁先以**官方 JRE Image** 執行本機 build 的 `ssds.jar`：

```bash
# 0. 在 ai-products-selection-backend/ 下打包（產出 ssds-api/build/libs/ssds.jar）
./gradlew :ssds-api:bootJar -x test

# 1. 後端：以唯讀方式掛載 jar 所在目錄，機密值以 --env-file 從 .env 帶入
docker run -d --name ssds-api -p 8080:8080 \
  --env-file .env \
  -v "${PWD}/ssds-api/build/libs:/jar:ro" -w /app \
  eclipse-temurin:21-jre-alpine java -jar /jar/ssds.jar

# 2. 前端：先啟動預設的 nginx 作為佔位（第四章再放入 Angular）
docker run -d --name ssds-web -p 8000:80 nginx:1.30-alpine
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>驗證：</b>約 20 秒後開啟 <code>http://localhost:8080/api/v1/swagger-ui.html</code>，出現 Swagger UI 即表示後端已在容器中啟動並連上 Supabase。
</div>

<!--
【範例目的】
在尚未撰寫 Dockerfile 的情況下，借用官方 eclipse-temurin JRE Image 執行本機 build 的 jar。實務上也常用此方式快速驗證 jar 能否在 Linux + Java 21 環境執行。

【帶讀關鍵行】
- 第 0 步：後端為 Gradle 多模組專案，只有 ssds-api 會產出可執行 jar，檔名已在 build.gradle 固定為 ssds.jar。
- `--env-file .env`：將 .env 中每一行 KEY=VALUE 設為容器的環境變數（SSDS_DB_HOST、SSDS_DB_PASSWORD、MISTRAL_API_KEY 等），Spring Boot 讀取 `${SSDS_DB_PASSWORD}` 時即可取得。
- `-v 主機路徑:容器路徑:ro`：將主機目錄掛載進容器，`ro` 表示唯讀。此為第七章的 bind mount，本章先會使用即可。`${PWD}` 在 PowerShell 與 bash 中皆代表目前目錄。
- `-w /app`：設定容器的工作目錄。application.properties 中圖片上傳路徑為相對路徑 `./uploads/product`，工作目錄決定檔案實際寫入的位置。

【核心說明】
Spring Boot 的任何設定都可以由環境變數覆蓋。專案的 application.properties 採用 `${SSDS_DB_HOST:預設值}` 寫法，因此同一個 jar、同一個 Image，只需更換環境變數即可連線不同的資料庫。第九章雲端平台的「Environment Variables」設定，作用與 --env-file 相同。

【易錯點提醒 ⚠️】
- Windows 建議使用 PowerShell 執行。Git Bash 會將 /jar、/app 等參數自動改寫為 C:/Program Files/Git/app，導致容器找不到檔案；若必須使用 Git Bash，先執行 `export MSYS_NO_PATHCONV=1`。
- .env 中的值不可加引號。--env-file 不會移除引號，`SSDS_DB_PASSWORD="abc"` 會使容器收到含引號的字串，導致連線失敗。

【預期結果】
docker ps 顯示兩個容器皆為 Up；localhost:8080/api/v1/swagger-ui.html 顯示 API 文件；localhost:8000 顯示 Welcome to nginx。
-->

---

# docker ps / stop / start / rm 的語法結構

| 指令 | 說明 |
| --- | --- |
| `docker ps` | 列出執行中的容器 |
| `docker ps -a` | 列出所有容器，包含已停止者 |
| `docker stop <容器>` | 停止執行中的容器（先送 SIGTERM，逾時再送 SIGKILL）|
| `docker start <容器>` | 重新啟動已停止的容器，保留原有設定 |
| `docker rm <容器>` | 刪除已停止的容器 |
| `docker rm -f <容器>` | 強制刪除，包含執行中的容器 |

<!--
【重點解說】
這六個指令是日常管理容器最常用的指令：ps 查看狀態、stop/start 切換執行狀態、rm 刪除容器。

【易錯點提醒 ⚠️】
stop 與 rm 是兩個不同的操作：stop 後容器與其資料仍然存在，可再以 start 啟動；rm 才會將容器刪除。
-->

---

# docker ps / stop / start / rm — 範例

```bash
# 列出執行中的容器
docker ps

# NAMES      IMAGE                          STATUS         PORTS
# ssds-web   nginx:1.30-alpine              Up 3 minutes   0.0.0.0:8000->80/tcp
# ssds-api   eclipse-temurin:21-jre-alpine  Up 3 minutes   0.0.0.0:8080->8080/tcp

# 列出所有容器（含已停止）
docker ps -a

# 停止後端容器（可使用名稱或 ID）
docker stop ssds-api

# 重新啟動，原有設定與環境變數保留
docker start ssds-api

# 重新打包 jar 後：停止並刪除舊容器，再重新 run
docker stop ssds-api && docker rm ssds-api
```

<!--
【帶讀關鍵行】
- PORTS 欄位的 `0.0.0.0:8080->8080/tcp` 即為 -p 設定的映射結果，箭頭左側為主機、右側為容器。容器無法連線時，應先確認此欄位。
- 最後一行是日常開發的固定流程：重新打包後，既有容器不會自動更新，必須先 stop、rm，再重新 run。第四章改用自建 Image 後流程相同。

【易錯點提醒 ⚠️】
docker rm 預設不允許刪除執行中的容器，必須先 stop，或加上 -f 強制刪除。

【預期結果】
docker ps -a 顯示容器狀態由 Up 變為 Exited，執行 start 後再變回 Up。
-->

---

# 使用容器基本指令的注意事項

容器被 `docker rm` 刪除後，未掛載到 Volume 的資料將永久消失；`docker stop` 則不會刪除任何資料。

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>建議：</b>刪除前先以 <code>docker ps -a</code> 確認容器名稱或 ID，避免誤刪。
</div>

```bash
# 刪除所有已停止的容器（執行前請先確認清單）
docker container prune
```

<!--
【重點解說】
對 SSDS 而言，資料庫位於 Supabase，不受容器刪除影響；但使用者上傳的商品圖片寫在容器的 /app/uploads 下，容器刪除後即一併消失。此問題於第七章處理。

【易錯點提醒 ⚠️】
docker container prune 會一次刪除「所有」已停止的容器，確認提示按下 y 前，應先以 ps -a 檢查清單。

【小結】
本頁重點是區分 stop 與 rm：stop 保留容器，rm 刪除容器。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 前景與背景執行

<!--
【段落轉換】
第二部分說明容器的兩種執行模式：前景（foreground）與背景（detached），並介紹如何進入執行中的容器。

【問題引導】
執行 docker run 後終端機無法輸入，是當機了嗎？本部分將說明原因。
-->

---

# 前景執行與背景執行

- **前景執行（預設）**：容器佔用目前的終端機，直到容器結束或以 `Ctrl+C` 中斷
- **背景執行（`-d`）**：僅輸出 Container ID，容器於背景執行，終端機可繼續使用

```bash
# 前景：Spring Boot 啟動 log 直接輸出到終端機，Ctrl+C 會停止服務
docker run --rm -p 8080:8080 --env-file .env \
  -v "${PWD}/ssds-api/build/libs:/jar:ro" \
  eclipse-temurin:21-jre-alpine java -jar /jar/ssds.jar

# 背景：僅輸出 Container ID，終端機立即可用
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  -v "${PWD}/ssds-api/build/libs:/jar:ro" \
  eclipse-temurin:21-jre-alpine java -jar /jar/ssds.jar
```

<!--
【重點解說】
前景執行時，Spring Boot 的 banner 與啟動 log 直接輸出在終端機上，適合初次除錯，可直接觀察是否成功連上 Supabase、是否出現 HikariPool 錯誤。缺點是佔用視窗，且按下 Ctrl+C 會停止服務。

【生活化比喻】
前景執行像在爐火前煎蛋，人必須留在旁邊；背景執行像使用電鍋，按下開關後即可處理其他事情。

【易錯點提醒 ⚠️】
未加 -d 時終端機無法輸入並非當機，而是容器在前景執行。按 Ctrl+C 可中斷，但容器也會隨之停止。

【預期結果】
加上 -d 後，終端機輸出一串 Container ID 並立即回到可輸入狀態。
-->

---

# -it 與 -d 的比較

| 選項 | 用途 | 適用場景 |
| --- | --- | --- |
| `-i` | 保持 STDIN 開啟，可輸入內容 | 需要與容器互動 |
| `-t` | 配置虛擬終端機（pseudo-TTY）| 提供終端機顯示效果 |
| `-it` | `-i` 與 `-t` 合併使用 | 進入容器操作，例如執行 shell |
| `-d` | 背景執行（detached mode）| 長時間執行的服務，例如 web server |

<!--
【重點解說】
-it 用於與容器互動，例如開啟 shell；-d 用於長駐服務，讓容器在背景持續執行。兩者用途相反。

【易錯點提醒 ⚠️】
-it 與 -d 通常不在同一次啟動中併用：互動模式需要持續操作終端機，與背景執行的目的不同。
-->

---

# -it / -d — 範例

```bash
# 互動模式：建立臨時容器，確認 Node 版本是否符合 Angular 21 需求
docker run -it --rm node:22-alpine sh

# 背景模式：長駐執行 SSDS 前端的 nginx
docker run -d --name ssds-web -p 8000:80 nginx:1.30-alpine

# 以 exec 進入執行中的容器（不建立新容器）
docker exec -it ssds-api sh
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>區別：</b><code>docker run -it</code> 建立「新」容器並進入；<code>docker exec -it</code> 進入「既有」容器。
</div>

<!--
【帶讀關鍵行】
- 第一行：進入臨時容器執行 `node -v`、`npm -v`，確認版本後 exit 離開；因為加了 --rm，容器會自動刪除。第四章撰寫 Dockerfile 前，可先用此方式確認環境，再將驗證過的指令寫入 Dockerfile。
- 第二行：背景長駐服務，API 與 Web Server 多以此模式執行。
- 第三行：exec 進入已在執行中的容器，下一頁詳細說明。

【易錯點提醒 ⚠️】
- alpine 系列 Image 沒有 bash，只有 sh。執行 `docker exec -it ssds-api bash` 會出現 executable file not found 錯誤，應改用 sh。
- 第一行的 sh 是該容器的主行程，exit 離開後容器即停止；ssds-api 的主行程是 java，exec 進入後離開不影響服務。

【預期結果】
第一行執行後直接進入容器內的 shell 提示字元。
-->

---

# 什麼是 docker exec？

`docker exec` 在執行中的容器內額外執行一個指令，不影響容器原本的主行程。

```bash
# 在後端容器內部呼叫自身的 API
docker exec -it ssds-api wget -qO- http://localhost:8080/api/v1/v3/api-docs
```

<!--
【概念定義】
exec 不會建立新容器，而是在既有容器中啟動一個額外的行程，常用於檢查設定、確認服務狀態。

【業界實務】
瀏覽器無法連線 localhost:8080 時，可用此方式判斷問題所在：
- 容器內可連線、容器外無法連線 → -p 映射設定有誤
- 容器內也無法連線 → Spring Boot 本身未正常啟動

alpine 版 Image 內建 busybox 的 wget，不需另外安裝 curl。

【易錯點提醒 ⚠️】
exec 執行的必須是可執行檔，不能直接傳入以 && 串接的指令字串。`docker exec -it my_container "echo a && echo b"` 是錯誤寫法，應改為 `docker exec -it my_container sh -c "echo a && echo b"`。

【預期結果】
輸出 OpenAPI 的 JSON 內容，表示 API 在容器內運作正常。
-->

---

# docker exec 的語法結構

| 選項 | 說明 |
| --- | --- |
| `docker exec [OPTIONS] CONTAINER COMMAND` | 基本語法結構 |
| `-i`, `--interactive` | 保持 STDIN 開啟 |
| `-t`, `--tty` | 配置虛擬終端機 |
| `-d`, `--detach` | 於背景執行該指令 |
| `-e KEY=VALUE` | 設定此次執行的環境變數 |
| `-w`, `--workdir` | 指定指令的工作目錄 |

<!--
【重點解說】
exec 的選項與 docker run 相近，因為兩者都是在容器內執行指令；差別在於 exec 作用於已存在的容器。

【易錯點提醒 ⚠️】
exec 開啟的行程依附於容器主行程；容器被 stop 後，exec 的 session 也會隨之結束。
-->

---

# docker exec — 範例

```bash
# 檢查容器實際取得的環境變數（無法連線 Supabase 時優先確認）
docker exec ssds-api env | grep SSDS_DB

# 進入後端容器的 shell，檢查工作目錄與上傳檔案位置
docker exec -it ssds-api sh

# 確認容器可解析 Supabase 的網域（DNS 與對外網路）
docker exec ssds-api nslookup aws-0-ap-south-1.pooler.supabase.com

# 指定工作目錄執行指令：列出 nginx 預設網站目錄
docker exec -w /usr/share/nginx/html ssds-web ls
```

<!--
【帶讀關鍵行】
- 第一行：API 無法連線資料庫時，多數原因出在環境變數，例如 .env 缺少某一行、key 拼錯、值多了引號。此指令可直接列出容器實際取得的 SSDS_DB 開頭變數。
- 第二行：進入容器後以 `pwd` 確認工作目錄、`ls uploads` 確認上傳圖片是否寫入。
- 第三行：資料庫位於 Supabase，容器必須能完成 DNS 解析並連線外部網路；nslookup 回傳 IP 即表示 DNS 正常。
- 第四行：第四章放入 Angular 後，若網頁回傳 404，可先以此確認網站目錄內容。

【易錯點提醒 ⚠️】
- 第一行會將密碼輸出到螢幕，示範或截圖時應注意避免外流。
- exec 進入後所做的修改只存在於該容器，不會寫回 Image；容器刪除後修改即消失。需要永久生效的變更必須寫入 Dockerfile 並重新 build。

【預期結果】
第二行執行後進入容器內的 shell，輸入 exit 離開，容器仍持續在背景執行。
-->

---

# 使用 exec 的注意事項

`docker exec` 進入的是容器內的額外行程；離開該行程（exit）不會停止容器，因為容器的主行程仍在執行。

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>易錯點：</b>以 <code>docker run -it</code> 建立的容器，若互動行程（例如 sh）即為主行程，exit 後整個容器會隨之停止。
</div>

```bash
# 多個指令須包在 sh -c "..." 中
docker exec -it ssds-api sh -c "pwd && ls -la /app && ls /jar"
```

<!--
【重點解說】
exec 與 run -it 的差異在於「離開的是不是主行程」。以 SSDS 為例，exec 進入 ssds-api 後執行 exit，Spring Boot 的 java 行程仍在執行，API 不受影響。

【生活化比喻】
run -it 的互動行程如同店長，店長離開即打烊；exec -it 的行程如同巡店的訪客，訪客離開不影響營業。

【易錯點提醒 ⚠️】
串接多個指令時必須包在 sh -c "..." 中，直接傳入會發生錯誤。

【預期結果】
依序輸出工作目錄 /app、/app 的內容，以及 /jar 下的 ssds.jar。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 容器生命週期

<!--
【段落轉換】
第三部分將前述指令串連起來，說明容器從建立到刪除會經過哪些狀態，並介紹以 logs 除錯的方法。

【重點提醒】
本部分重點在理解「狀態」，指令皆已在前兩部分介紹過。
-->

---

# 容器生命週期

容器的生命週期包含五個狀態：

<div class="flex items-center my-6" style="justify-content: space-between; width: 100%;">
<span style="flex: 1; background:#f0faf9;border:1px solid #9dc4c4;border-radius:8px;padding:14px 8px;font-size:1.15rem;font-weight:700;text-align:center;">created</span>
<span style="flex: none; font-size:1.5rem; color:#4a7c7c; padding:0 8px;">→</span>
<span style="flex: 1; background:#dbeafe;border:1px solid #a7d9d0;border-radius:8px;padding:14px 8px;font-size:1.15rem;font-weight:700;text-align:center;">running</span>
<span style="flex: none; font-size:1.5rem; color:#4a7c7c; padding:0 8px;">→</span>
<span style="flex: 1; background:#f0faf9;border:1px solid #9dc4c4;border-radius:8px;padding:14px 8px;font-size:1.15rem;font-weight:700;text-align:center;">paused</span>
<span style="flex: none; font-size:1.5rem; color:#4a7c7c; padding:0 8px;">→</span>
<span style="flex: 1; background:#fee2e2;border:1px solid #fca5a5;border-radius:8px;padding:14px 8px;font-size:1.15rem;font-weight:700;text-align:center;">stopped</span>
<span style="flex: none; font-size:1.5rem; color:#4a7c7c; padding:0 8px;">→</span>
<span style="flex: 1; background:#f3f4f6;border:1px solid #d1d5db;border-radius:8px;padding:14px 8px;font-size:1.15rem;font-weight:700;text-align:center;">removed</span>
</div>

| 狀態 | 說明 |
| --- | --- |
| `created` | 已建立，尚未啟動 |
| `running` | 執行中 |
| `paused` | 行程凍結，記憶體內容保留 |
| `stopped` | 已停止（`docker ps -a` 顯示為 Exited）|
| `removed` | 已刪除 |

<!--
【生活化比喻】
以店面類比：裝潢完成尚未營業是 created；營業中是 running；臨時公休但物品都留在店內是 paused；打烊拉下鐵門是 stopped；店面退租清空是 removed。

【核心說明】
docker run 等於 create + start 兩個動作。Docker 另有單獨的 docker create 指令，只建立容器而不啟動，日常較少單獨使用。

【預期結果】
能依序說出五個狀態，並對應到切換狀態所使用的指令。
-->

---

# 容器狀態轉換表

| 動作 | 指令 | 狀態變化 |
| --- | --- | --- |
| 建立並啟動 | `docker run` | （不存在）→ running |
| 停止 | `docker stop` | running → stopped |
| 重新啟動 | `docker start` | stopped → running |
| 暫停 | `docker pause` | running → paused |
| 恢復 | `docker unpause` | paused → running |
| 刪除 | `docker rm` | stopped → （不存在）|

<!--
【重點解說】
除 rm 外，其餘指令皆可逆，狀態可來回切換；rm 為單向操作，刪除後無法復原。

【易錯點提醒 ⚠️】
pause 與 stop 機制不同：pause 凍結容器內所有行程（暫停 CPU 排程），行程仍保留在記憶體中，unpause 後從凍結處繼續執行；stop 則終止行程，start 時重新執行啟動流程。
-->

---

# 容器狀態轉換 — 範例

```bash
# 建立並啟動
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  -v "${PWD}/ssds-api/build/libs:/jar:ro" -w /app \
  eclipse-temurin:21-jre-alpine java -jar /jar/ssds.jar

# 暫停與恢復（凍結行程，記憶體內容保留）
docker pause ssds-api
docker unpause ssds-api

# 停止與重新啟動（Spring Boot 重新執行完整啟動流程）
docker stop ssds-api
docker start ssds-api

# 查看目前狀態
docker ps -a --filter name=ssds
```

<!--
【操作提示】
依序執行每一行，並在每一步後執行 docker ps -a，觀察 STATUS 欄位由 Up 變為 Paused、Exited，再回到 Up。

【重點觀察】
- pause 期間在瀏覽器重新整理 Swagger，請求會停滯等待；unpause 後該請求繼續完成。
- stop 後連線直接被拒絕；start 後 Spring Boot 需重新執行啟動流程。SSDS 模組較多且需連線 Supabase，約需十數秒才能提供服務。

【易錯點提醒 ⚠️】
pause 期間容器完全凍結，進行中的 API 請求不會回傳錯誤，而是沒有任何回應；正式環境應謹慎使用。

【預期結果】
最後一行列出 ssds-api 與 ssds-web 目前的實際狀態。
-->

---

# docker logs

`docker logs` 輸出容器的標準輸出（STDOUT）與標準錯誤（STDERR），是容器除錯的第一步。

```bash
docker logs ssds-api
```

| log 訊息 | 常見原因 |
| --- | --- |
| `password authentication failed for user "ssds_app"` | 未帶入 `--env-file`、密碼錯誤或值含引號 |
| `UnknownHostException` / `Network is unreachable` | `SSDS_DB_HOST` 錯誤，或使用了 direct connection |
| `Port 8080 was already in use` | IDE 中的 Spring Boot 仍在執行 |

<!--
【核心說明】
服務無法啟動或無法連線時，第一步應先查看 log，而非直接重啟容器。ssds-api 在 docker ps -a 中顯示 Exited 時，原因幾乎都記錄在 log 中。

【帶讀表格】
- 第一種最常見：可能是忘了加 --env-file（Spring Boot 取不到密碼，但仍以預設的 Supabase 網址連線），也可能是密碼錯誤或值含引號。可用 `docker exec ssds-api env | grep SSDS_DB` 區分。
- 第二種：SSDS_DB_HOST 錯誤，或使用了 Supabase 的 direct connection（第六章說明）。
- 第三種：主機上已有其他程式佔用 8080。

【業界實務】
docker logs 只能取得輸出到 STDOUT/STDERR 的內容。因此容器化的 Spring Boot 專案，logback 通常只設定 console appender、不寫入檔案：寫在容器內的檔案會隨容器刪除而消失，且第九章的雲端平台也是收集 STDOUT 作為 log。

【預期結果】
輸出容器啟動至今的所有紀錄，最後應出現 `Started SsdsApplication in xx seconds`。
-->

---

# docker logs 的語法結構

| 選項 | 說明 |
| --- | --- |
| `docker logs [OPTIONS] CONTAINER` | 基本語法結構 |
| `-f`, `--follow` | 持續輸出新產生的 log |
| `-n`, `--tail` | 僅顯示最後 N 行 |
| `-t`, `--timestamps` | 每行加上時間戳記 |
| `--since` | 僅顯示指定時間點之後的 log |
| `--until` | 僅顯示指定時間點之前的 log |

<!--
【重點解說】
-f 用於即時監看；-n、--since、--until 用於縮小查詢範圍；-t 可補上時間資訊，方便對照事件發生時間。

【易錯點提醒 ⚠️】
-f 會持續佔用終端機輸出新 log，屬正常行為。按 Ctrl+C 即可離開，不影響容器執行。
-->

---

# docker logs — 範例

```bash
# 即時追蹤 log（搭配 Swagger 呼叫 API，確認請求是否送達）
docker logs -f ssds-api

# 僅顯示最後 50 行，並加上時間戳記
docker logs -n 50 -t ssds-api

# 僅顯示最近 30 分鐘的 log
docker logs --since 30m ssds-api

# 篩選錯誤訊息：Spring Boot 的例外堆疊
docker logs ssds-api 2>&1 | grep -i "exception\|error"
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>補充：</b><code>--since</code> 與 <code>--until</code> 可接受相對時間（如 <code>30m</code>、<code>1h</code>）或完整日期時間。PowerShell 沒有 <code>grep</code>，可改用 <code>| Select-String -Pattern "exception|error"</code>。
</div>

<!--
【操作提示】
在一個終端機視窗執行 `docker logs -f ssds-api`，再於 Swagger UI 呼叫一支 API（例如商品列表），觀察 log 是否出現 Hibernate 的 select 語句（dev profile 已開啟 show-sql），藉此確認請求確實送達後端並查詢 Supabase。

【帶讀關鍵行】
第二、三行用於回溯查詢：服務已執行一段時間，只需檢視最近的紀錄。

【易錯點提醒 ⚠️】
容器被 rm 刪除後，log 也一併消失。正式環境通常搭配 log 收集工具長期保存，docker logs 僅適合即時查看。

【預期結果】
第一行執行後畫面持續更新，按 Ctrl+C 離開。
-->

---

# 小結：容器生命週期與除錯

容器除錯的建議順序：

1. 確認狀態：`docker ps -a`
2. 查看紀錄：`docker logs`
3. 進入檢查：`docker exec`
4. 變更狀態：`docker stop` / `start` / `rm`

```bash
docker ps -a && docker logs --tail 20 ssds-api
```

<!--
【小結】
遇到問題時，先確認狀態、再查看 log，最後才變更容器狀態。

【易錯點提醒 ⚠️】
直接 rm 重建容器會一併刪除 log，失去最重要的除錯線索。應先確認 log 中的錯誤原因，再進行處理。
-->

---
layout: default
---

# 練習 1：在容器中執行 SSDS 後端並檢查狀態
### 任務說明

在 `ai-products-selection-backend/` 目錄下完成：

1. 執行 `./gradlew :ssds-api:bootJar -x test`，確認產出 `ssds-api/build/libs/ssds.jar`
2. 以背景模式啟動 `eclipse-temurin:21-jre-alpine`，命名為 `ssds-api`，映射主機 `8080` 至容器 `8080`，以 `--env-file .env` 帶入機密，並將 jar 目錄唯讀掛載至 `/jar`
3. 確認容器於背景執行，記錄 PORTS 欄位內容
4. 查看 log，找到 `Started SsdsApplication`（啟動約需 30 秒）
5. 停止容器並確認狀態為 Exited，再重新啟動並確認回到 Up

<!--
【任務鋪陳】
本題在 SSDS 後端上實際操作第一部分的基本指令。

【出題動機】
第 4 步是本題重點：Spring Boot 容器並非 docker run 後即可使用，需先建立 Spring context、連線 Supabase、初始化 JPA，約需 30 秒。尚未就緒時開啟瀏覽器會出現連線被拒絕，並非啟動失敗。學會以 log 判斷服務是否就緒，是第五章 healthcheck 的基礎。

【易錯點提醒 ⚠️】
必須在後端專案根目錄執行，因為 .env 與 ${PWD} 皆以目前目錄為準；在錯誤目錄執行會出現 `open .env: no such file`。
-->

---
layout: default
---

# 練習 1：參考答案

```bash
# 1. 打包（Windows PowerShell 使用 .\gradlew）
./gradlew :ssds-api:bootJar -x test
ls ssds-api/build/libs/ssds.jar

# 2. 背景啟動
docker run -d --name ssds-api -p 8080:8080 --env-file .env   -v "${PWD}/ssds-api/build/libs:/jar:ro" -w /app   eclipse-temurin:21-jre-alpine java -jar /jar/ssds.jar

# 3. 確認執行中：PORTS 欄為 0.0.0.0:8080->8080/tcp
docker ps

# 4. 約 30 秒後查看 log
docker logs ssds-api | grep "Started SsdsApplication"

# 5. 停止 → 確認 Exited → 重新啟動 → 確認 Up
docker stop ssds-api && docker ps -a --filter name=ssds-api
docker start ssds-api && docker ps --filter name=ssds-api
```

<!--
【帶讀解法】
所有步驟皆使用第一部分介紹的指令，重點在於組合出完整流程。第 3 步的 PORTS 欄位應為 `0.0.0.0:8080->8080/tcp`；第 5 步 STATUS 依序為 `Exited (143)` 與 `Up`。

【易錯點提醒 ⚠️】
- docker ps 預設只顯示執行中的容器，確認已停止狀態需加 -a。
- 第 4 步若查無結果，稍候十秒再試；若容器轉為 Exited，以 `docker logs ssds-api` 查看完整錯誤，多數為 .env 設定問題。
- Exited 的代碼 143 = 128 + 15（SIGTERM），表示由 docker stop 正常停止，並非錯誤。

【預期結果】
docker ps 顯示 ssds-api 回到 Up 狀態。請保留此容器，練習 2 將繼續使用。
-->

---
layout: default
---

# 練習 2：在後端容器中除錯
### 任務說明

延續練習 1 的 `ssds-api` 容器：

1. 以 `docker exec` 列出容器中所有 `SSDS_` 開頭的環境變數，確認 `.env` 已正確帶入
2. 以互動模式進入容器，執行 `pwd` 與 `ls -la`，確認工作目錄為 `/app`
3. 不進入互動模式，直接在容器內以 `wget` 呼叫 `http://localhost:8080/api/v1/v3/api-docs`，確認 API 運作正常
4. 以 `docker logs` 僅顯示最近 10 分鐘的 log
5. **思考題**：使用者於前端上傳的商品圖片存放在何處？執行 `docker rm -f ssds-api` 並重新 `docker run` 後，圖片是否仍存在？Supabase 中的資料呢？

<!--
【任務鋪陳】
本題結合第二部分的 exec 與第三部分的 logs，情境與實際除錯流程一致。

【解題引導】
第 3 步需自行組出 `docker exec ssds-api wget -qO- http://localhost:8080/api/v1/v3/api-docs`，此寫法常用於腳本。專案設定了 context-path，路徑前必須加上 /api/v1。

【出題動機】
第 5 步為後續章節鋪陳：application.properties 的圖片路徑為 `./uploads/product`，工作目錄為 /app，因此圖片存放於容器的 /app/uploads/product。容器刪除後可寫層隨之消失，圖片也一併遺失；Supabase 的資料位於雲端，不受影響。此差異即為第七章 Volume 要解決的問題。
-->

---
layout: default
---

# 練習 2：參考答案

```bash
# 1. 檢查環境變數（會輸出密碼，請勿截圖分享）
docker exec ssds-api env | grep SSDS_

# 2. 進入互動 shell
docker exec -it ssds-api sh
/app # pwd          # 輸出 /app
/app # ls -la
/app # exit

# 3. 不進入互動模式，直接於容器內呼叫 API
docker exec ssds-api wget -qO- http://localhost:8080/api/v1/v3/api-docs

# 4. 依時間篩選 log
docker logs --since 10m ssds-api
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>第 5 題答案：</b>圖片存放於容器的 <code>/app/uploads/product</code>，容器刪除後<b>全部消失</b>；Supabase 的資料位於雲端，不受影響。若要保留上傳檔案，必須將 <code>/app/uploads</code> 掛載至 Volume，此為第七章主題。
</div>

<!--
【帶讀解法】
本題重點在區分 exec -it（互動）與 exec 直接執行指令的差異。

【重點提醒】
資料庫使用雲端託管服務是本專案的優勢；但只要程式會寫入本機檔案，容器化後就必須額外處理。第九章部署至免費雲端平台時會再次遇到此問題，且免費方案通常不提供永久磁碟。

【易錯點提醒 ⚠️】
對執行中的容器直接執行 docker rm 會被拒絕，必須加上 -f。

【預期結果】
第 3 步輸出 OpenAPI JSON。完成後可執行 `docker rm -f ssds-api ssds-web` 清除容器，第四章將改用自建的 Image。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — 容器操作

<table class="summary-table">
<thead>
<tr><th>重點</th><th>說明</th></tr>
</thead>
<tbody>
<tr><td>docker run</td><td>從 Image 建立並啟動一個新的 Container</td></tr>
<tr><td>前景 / 背景</td><td>預設佔用終端機，加上 <code>-d</code> 改為背景執行</td></tr>
<tr><td>docker exec</td><td>在既有容器中執行額外指令，不影響主行程</td></tr>
<tr><td>容器生命週期</td><td>created → running → paused → stopped → removed</td></tr>
<tr><td>docker logs</td><td>輸出 STDOUT/STDERR，是除錯的第一步</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>重點：</b><code>stop</code> 不等於 <code>rm</code>。stop 後容器與資料仍保留，rm 才會刪除容器。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b>Dockerfile — 將 Image 的建置步驟寫成可重複執行的腳本。
</div>

<!--
【回顧】
本章核心概念是「容器操作即狀態管理」：run 建立並啟動、ps 查看狀態、stop/start 切換執行、pause 凍結、exec 進入檢查、logs 查看輸出、rm 刪除。

【重點提醒】
最容易混淆的兩點：stop 不等於 rm，stop 後資料仍在；exec 離開不會停止容器，除非該行程即為容器的主行程。

【預期結果】
能獨立完成「啟動 → 檢查 → 除錯 → 清除」的完整容器操作流程。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
【互動引導】
開放提問：容器的 run、exec、logs 指令，或生命週期的狀態轉換，有任何疑問皆可提出。

【學習建議】
進入下一章前，建議完成本章兩題練習；容器操作是後續各章的基礎。
-->
