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
    「從啟動到收工，掌握容器操作的每一步」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
歡迎來到第三章，容器操作。

前兩章我們認識了 Docker 的架構，也學會管理 Image。這一章開始，我們要真正操作容器，把它從啟動、運作、停止到刪除，完整走過一次。

這章的指令比較多，但不用死背。重點是理解每個指令用在容器生命週期的哪個階段。學完之後，我們就能自己啟動容器、進去查資料、看 log 除錯，最後乾淨地收拾掉。
-->

---
layout: default
---

# Outline

- 容器基本操作：run / ps / stop / start / rm
- 前景與背景執行：-it 與 -d
- 容器生命週期與 logs 除錯
- 練習題
- 總結

<!--
這一章分成三部分。第一部分學五個基本指令，run、ps、stop、start、rm。第二部分搞懂前景和背景執行的差別，順便學會怎麼進入一個正在跑的容器。第三部分把整個生命週期串起來，並學會用 logs 除錯。最後有兩題練習，用 TaskBoard 的資料庫實際操作一遍。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 容器基本操作

<!--
第一部分，我們從最基本的五個指令開始。這一章會用「開店」來比喻容器，開店、巡店、打烊、重新開門、把店收掉。
-->

---

# 什麼是 docker run？

「`docker run` 會從一個 Image（映像檔）建立一個全新的 Container（容器），如果本地沒有這個 Image，Docker 還會自動幫我們去 Registry 拉下來，然後啟動它。」

```bash
docker run hello-world
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>注意事項：</b> 每次 <code>docker run</code> 都會建立一個「全新」的容器，就算 Image 一樣，跑出來的容器也是不同的個體，這點跟 <code>docker start</code>（啟動既有容器）不一樣。
</div>

<!--
先從 `docker run` 開始。

「`docker run` 會從一個 Image 建立一個全新的 Container」，本機沒有這個 Image 的話，還會自動去 Registry 拉下來，然後啟動它。

用開店來比喻，Image 是開店的標準手冊，`docker run` 就是照著手冊開一間全新的分店。

範例裡的 hello-world 我們第一章跑過，執行後會印出 Hello from Docker!，容器就結束了。

這裡要注意，很多人以為 `docker run` 是打開一個容器，其實它每次都是新建一個。就算 Image 一樣，跑出來的也是不同的容器。要重新打開已經存在的容器，要用等一下會教的 `docker start`。
-->

---

# docker run 的語法結構

| 指令 / 選項 | 說明 |
| --- | --- |
| `docker run [OPTIONS] IMAGE [COMMAND]` | 基本語法結構 |
| `-d`, `--detach` | 背景執行（detached mode），只印出 Container ID |
| `-it` | 互動模式，搭配終端機使用（下一部分細講）|
| `--name` | 幫容器取一個好記的名字 |
| `--rm` | 容器結束後自動刪除，不留垃圾 |
| `-p 主機port:容器port` | 把容器內的 port 映射到主機 |
| `-e KEY=VALUE` | 設定環境變數 |

<!--
這張表是 `docker run` 最常用的選項，我們挑重點看。

`-d` 讓容器在背景執行，`--name` 幫容器取一個好記的名字。`--rm` 很實用，容器結束後自動刪除，不會留下一堆用過的容器。

最常出錯的是 `-p`。它的順序永遠是主機的 port 在左邊，容器的 port 在右邊。方向搞反了，就會連不到服務。

`-e` 是設定環境變數，等一下的範例會大量用到。
-->

---

# docker run — 範例

把 TaskBoard 的三個服務逐一啟動：

```bash
# 1. 資料庫：帶環境變數初始化 database 與帳號
docker run -d --name taskboard-db -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=rootpw \
  -e MYSQL_DATABASE=taskboard \
  -e MYSQL_USER=appuser -e MYSQL_PASSWORD=apppw \
  mysql:8.4

# 2. 後端：用環境變數覆蓋 Spring Boot 的資料庫連線設定
docker run -d --name taskboard-api -p 8081:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://host.docker.internal:3307/taskboard \
  -e SPRING_DATASOURCE_USERNAME=appuser \
  -e SPRING_DATASOURCE_PASSWORD=apppw \
  taskboard-api:1.0.0

# 3. 前端：Angular 打包後由 nginx 服務
docker run -d --name taskboard-web -p 8080:80 taskboard-web:1.0.0
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>補充：</b> 三行都跑完後，瀏覽器打開 <code>http://localhost:8080</code> 是前端、<code>http://localhost:8081/actuator/health</code> 是後端健康檢查。
</div>

<!--
這一頁我們用最原始的方式，把 TaskBoard 三個服務一個一個跑起來。

第一段資料庫多了 `MYSQL_USER` 和 `MYSQL_PASSWORD`，會建一個給 Spring Boot 用的應用帳號。

第二段是後端，這是最關鍵的觀念。Spring Boot 的設定可以用環境變數覆蓋，規則是把點換成底線、全部大寫。所以 `spring.datasource.url` 就變成 `SPRING_DATASOURCE_URL`。同一個 Image，只要換環境變數，就能連到不同的資料庫，完全不用重新 build。

這裡的 `host.docker.internal` 是暫時的寫法。容器裡的 localhost 指的是容器自己，不是我們的電腦，所以不能寫 localhost。它代表跑 Docker 的這台主機，第六章會用自訂網路改掉它。

三行都跑完後，瀏覽器打開 localhost 的 8080 就是前端。
-->

---

# docker ps / stop / start / rm 的語法結構

| 指令 | 說明 |
| --- | --- |
| `docker ps` | 列出「正在執行中」的容器 |
| `docker ps -a` | 列出「所有」容器，包含已停止的 |
| `docker stop <容器>` | 溫和地停止一個正在執行的容器 |
| `docker start <容器>` | 重新啟動一個已停止的容器（保留原本狀態）|
| `docker rm <容器>` | 刪除一個已停止的容器 |
| `docker rm -f <容器>` | 強制刪除，連正在執行的容器也一起砍掉 |

<!--
容器跑起來之後，接下來就是管理它們。這張表的六個指令，是我們每天都會用到的。

`docker ps` 就像巡店，看看現在有哪些店開著。加上 `-a`，連已經打烊的店也一起列出來。

最容易搞混的是 stop 和 rm。`docker stop` 只是打烊關燈，容器和裡面的東西都還在，隔天 `docker start` 就能重新開門。`docker rm` 才是真的把店收掉拆除。

最後一行的 `-f` 是強制刪除，連正在執行的容器都會直接砍掉，使用時要小心。
-->

---

# docker ps / stop / start / rm — 範例

```bash
# 看目前正在執行的容器
docker ps

# NAMES            IMAGE                STATUS         PORTS
# taskboard-web    taskboard-web:1.0.0  Up 3 minutes   0.0.0.0:8080->80/tcp
# taskboard-api    taskboard-api:1.0.0  Up 3 minutes   0.0.0.0:8081->8080/tcp
# taskboard-db     mysql:8.4            Up 4 minutes   0.0.0.0:3307->3306/tcp

# 連已經停止的容器也一起列出來
docker ps -a

# 下班了，把後端停掉（用名稱或 ID 都可以）
docker stop taskboard-api

# 隔天上班重新啟動，設定與資料都還在
docker start taskboard-api

# 改完 Dockerfile 要換新 Image，先停再刪掉舊容器
docker stop taskboard-api && docker rm taskboard-api
```

<!--
這一頁把剛才的指令實際跑一遍。

先看 `docker ps` 輸出的 PORTS 欄位。`0.0.0.0:8081->8080/tcp` 就是我們用 `-p` 設定的結果，左邊是主機，右邊是容器。以後容器連不上的時候，第一件事就是看這一欄。

接著 stop 停掉後端，再用 start 重新啟動，設定和資料都還在。

最後一行是之後每天都會用到的組合。改了程式重新 build Image 之後，舊容器不會自動更新，一定要先 stop 再 rm，再用新 Image 重新 run。要注意，rm 預設不能刪除執行中的容器，所以要先 stop。

執行過程中，`docker ps -a` 會看到狀態從 Up 變成 Exited，start 之後又變回 Up。
-->

---

# 使用容器基本指令的注意事項

「容器一旦被 `docker rm` 刪除，裡面沒有掛載到 Volume 的資料就永久消失了，這跟 `docker stop` 完全不同。」

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>小提醒：</b> 養成習慣，刪除前先用 <code>docker ps -a</code> 確認容器名稱或 ID，避免刪錯棚。
</div>

```bash
# 一次清掉所有已停止的容器（要小心使用）
docker container prune
```

<!--
這一頁要強調一個很多人踩過的坑。

「容器一旦被 `docker rm` 刪除，沒有掛載到 Volume 的資料就永久消失了。」

用開店來說，打烊之後櫃子裡的東西都還在，隔天開門都找得到。但拆店之後，東西就真的沒了。

下面這行 `docker container prune` 會一次清掉所有已停止的容器。它很方便，但如果沒先確認清單就按下去，可能會把想留的容器也清掉。所以刪除之前，先用 `docker ps -a` 看一下，養成這個習慣。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 前景與背景執行

<!--
基本指令會了，接下來看容器執行的兩種模式：前景和背景。很多人第一次覺得終端機被卡住，就是這個原因。
-->

---

# 前景執行與背景執行是什麼？

「預設情況下，`docker run` 是『前景執行』（foreground），容器會佔用目前的終端機視窗，直到容器結束或我們手動中斷（Ctrl+C）。」

加上 `-d`（detach，背景執行）之後，Docker 只印出 Container ID，容器轉到背景執行，終端機立即可繼續使用。

```bash
# 前景：Spring Boot 的啟動 log 直接洗在終端機上，Ctrl+C 會把服務停掉
docker run taskboard-api:1.0.0

# 背景：只印出 Container ID，終端機馬上還給你
docker run -d --name taskboard-api taskboard-api:1.0.0
```

<!--
「預設情況下，`docker run` 是前景執行」，容器會佔用目前的終端機，直到容器結束或我們按 Ctrl+C。加上 `-d` 之後，Docker 只印出 Container ID，終端機馬上就能繼續用。

用開店來比喻，前景執行就像店長親自站櫃檯，人一離開，店就關了。背景執行則是交給店員顧店，店長可以去忙別的事。

Spring Boot 的例子最好懂。不加 `-d`，Spring 的啟動 log 會直接洗在終端機上，第一次除錯時其實很方便，可以馬上看到有沒有連上資料庫。但它會佔住視窗，而且一按 Ctrl+C，服務就停了。

所以長時間運行的服務，我們都會加上 `-d`。
-->

---

# -it 與 -d 的比較

| 選項 | 用途 | 適合場景 |
| --- | --- | --- |
| `-i` | 保持 STDIN 開啟，可以輸入內容 | 需要跟容器互動 |
| `-t` | 分配一個虛擬終端機（pseudo-TTY）| 讓畫面有終端機的顯示效果 |
| `-it` | `-i` 加 `-t` 合併使用 | 進入容器內部操作，例如跑 shell |
| `-d` | 背景執行（detached mode）| 長時間運行的服務，例如 web server |

<!--
這張表比較兩個最常搭配的選項，`-it` 和 `-d`，它們的方向剛好相反。

`-i` 讓我們可以輸入內容，`-t` 提供終端機的顯示效果，合起來的 `-it` 代表「我要跟容器對話」，適合開一個互動式的 shell。

`-d` 則是「讓它自己在背景跑」，適合 web server、資料庫這類長駐服務。

所以這兩個通常不會用在同一次啟動。互動模式需要我們盯著畫面，跟背景執行的用途剛好衝突。
-->

---

# -it / -d — 範例

```bash
# 互動模式：開一個「用完就丟」的容器，測試 Gradle 版本對不對
docker run -it --rm gradle:8.10-jdk21 bash

# 背景模式：長駐執行 TaskBoard 後端服務
docker run -d --name taskboard-api -p 8081:8080 taskboard-api:1.0.0

# 用 exec 進入「已經在跑」的容器，而不是新建一個
docker exec -it taskboard-api sh
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>關鍵區別：</b> <code>docker run -it</code> 是建立「新」容器並進去；<code>docker exec -it</code> 是進入「已經存在」的容器。
</div>

<!--
這一頁對照三種用法。

第一行是互動模式的實際用途。我們想確認 `gradle:8.10-jdk21` 裡的 Java 是不是 21，就開一個臨時容器進去看，看完 exit 離開。因為加了 `--rm`，容器會自動消失。第四章寫 Dockerfile 之前，很適合先這樣進去確認環境。

第二行是背景執行，我們部署的 API 和資料庫幾乎都是這種模式。

第三行帶到下一個重點，`docker exec`。它不是新建容器，而是進入一個已經在跑的容器。

這裡有一個差別要記住。第一行的容器，一 exit 離開 bash 就會停止，因為 bash 是它的主行程。第三行進去 taskboard-api 再離開，服務照常運作，因為它的主行程是 java。
-->

---

# 什麼是 docker exec？

「`docker exec` 會在一個『正在執行中』的容器裡，額外執行一個新指令，不會影響容器原本的主行程。」

```bash
# 進到資料庫容器裡，直接用 mysql client 查資料
docker exec -it taskboard-db mysql -uappuser -papppw taskboard
```

<!--
容器跑起來之後，如果想進去看看裡面的狀況，就要用 `docker exec`。

「`docker exec` 會在一個正在執行中的容器裡，額外執行一個新指令」，不會影響容器原本的主行程。

這個範例特別實用。以前我們要開 MySQL Workbench 才能查資料，現在容器裡本來就有 mysql 的命令列工具，一行指令就能進到 SQL 提示字元，直接查 Spring Boot 到底有沒有把資料寫進去。

這裡有個小細節，`-u` 和 `-p` 後面要直接接帳號密碼，中間不能有空格。執行後就會看到 mysql 的提示字元，可以開始下 SQL。
-->

---

# docker exec 的語法結構

| 選項 | 說明 |
| --- | --- |
| `docker exec [OPTIONS] CONTAINER COMMAND` | 基本語法結構 |
| `-i`, `--interactive` | 保持 STDIN 開啟 |
| `-t`, `--tty` | 分配虛擬終端機 |
| `-d`, `--detach` | 在背景執行這個指令 |
| `-e KEY=VALUE` | 設定這次執行的環境變數 |
| `-w`, `--workdir` | 指定指令執行的工作目錄 |

<!--
這張表是 `docker exec` 的選項，跟 `docker run` 很像。因為 exec 本質上也是在容器裡跑一個指令，差別只是容器已經存在。

最常用的一樣是 `-it`，進入互動模式。另外 `-w` 可以指定在哪個目錄執行指令，`-e` 可以只對這次執行設定環境變數。

要注意的是，exec 只能用在執行中的容器。如果容器被 stop 了，exec 進去的 session 也會跟著結束。
-->

---

# docker exec — 範例

```bash
# 進資料庫容器下 SQL：確認 Spring Boot 的 JPA 有沒有幫我們建表
docker exec -it taskboard-db mysql -uappuser -papppw taskboard -e "show tables;"

# 進後端容器的 shell，看看 jar 檔到底放在哪
docker exec -it taskboard-api sh

# 檢查容器實際吃到的環境變數（除錯資料庫連線必看）
docker exec taskboard-api env | grep SPRING

# 指定工作目錄執行指令：看 Angular 打包出來的靜態檔
docker exec -w /usr/share/nginx/html taskboard-web ls
```

<!--
這四行是除錯 TaskBoard 時的標準工具組。

第一行用 `-e` 直接帶一句 SQL 進去，確認 JPA 有沒有幫我們建表。不用進互動模式，很適合寫在腳本裡。

第二行進後端的 shell 逛一圈，確認 jar 檔放在哪裡。

第三行是最推薦大家記起來的。API 連不上資料庫的時候，大部分問題都出在環境變數，可能拼錯，可能少打一個 `-e`。這行會把容器實際收到的 SPRING 開頭變數全部列出來，一看就知道。

第四行查看 nginx 目錄下有沒有 Angular 的檔案，網頁出現 404 時先查這個。

要提醒的是，exec 進去改的東西只存在這個容器裡，不會寫回 Image。要永久生效，必須改 Dockerfile 重新 build。
-->

---

# 使用 exec 的注意事項

「`docker exec` 進入的是容器內部的一個『額外行程』，離開這個行程（例如 exit）不會讓容器本身停止，因為容器真正的主行程還在跑。」

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>易錯點：</b> 這點跟 <code>docker run -it</code> 不一樣！在 run 建立的容器裡，如果互動的行程（例如 bash）就是主行程，exit 離開就會讓整個容器跟著停止。
</div>

```bash
# 多重指令一定要包在 sh -c "..." 裡面
docker exec -it taskboard-api sh -c "ls /app && cat /app/application.yml"
```

<!--
這一頁把 exec 和 run 的差異講清楚，因為這是最多人搞混的地方。

「`docker exec` 進入的是容器內部的一個額外行程」，離開它不會讓容器停止，因為主行程還在跑。

用開店來說，`docker run -it` 進去的我們就是店長，店長一走，整間店就打烊了。`docker exec -it` 則像臨時進去巡店的訪客，訪客離開，店照常營業。

下面這行還有一個常見錯誤。要在 exec 裡串好幾個指令，一定要包在 `sh -c` 裡面，直接把兩個指令用 and 符號串起來丟進去，會報錯。執行後會先列出 app 目錄，再印出設定檔的內容。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 容器生命週期

<!--
第三部分，我們把前面學過的指令串起來，看一個容器從建立到消失，會經過哪些狀態。
-->

---

# 容器生命週期是什麼？

「容器的生命週期有五個狀態：`created`（已建立未啟動）→ `running`（執行中）→ `paused`（暫停）→ `stopped`（已停止）→ `removed`（已刪除）。」

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

<!--
「容器的生命週期有五個狀態」，created、running、paused、stopped、removed。

繼續用開店來比喻。裝潢好但還沒開門，是 created。掛牌營業，是 running。老闆臨時公休，但東西都還在店裡，是 paused。晚上拉下鐵門，是 stopped。最後房東收回店面、全部清空，就是 removed。

這裡有一個很多人不知道的細節。`docker run` 其實是 create 和 start 兩個動作合在一起。Docker 底層還有一個單獨的 `docker create` 指令，只是我們平常很少單獨用它。

接下來看每個狀態要用哪個指令切換。
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
這張表把每個狀態轉換對應到指令，等於是前面指令的總複習。

我們可以發現，除了 rm 之外，其他動作都可以來回切換，只有 rm 是單向的，一去不回。

要特別說明 pause 和 stop 的差別。pause 是把容器裡的行程凍結，行程還留在記憶體裡，unpause 之後會從凍結的地方繼續。stop 則是真的把行程結束，start 時要重新啟動。這是兩種完全不同的機制。
-->

---

# 容器狀態轉換 — 範例

```bash
# 建立並啟動
docker run -d --name taskboard-api -p 8081:8080 taskboard-api:1.0.0

# 暫停與恢復（凍結行程，記憶體內容保留）
docker pause taskboard-api
docker unpause taskboard-api

# 停止與重新啟動（Spring Boot 會完整重跑一次啟動流程）
docker stop taskboard-api
docker start taskboard-api

# 查看目前狀態
docker ps -a --filter name=taskboard
```

<!--
建議大家照這個順序，在終端機一步步跑一次。每執行一行，就打一次 `docker ps -a`，親眼看著 STATUS 從 Up 變成 Paused、Exited，再變回 Up。

這裡可以體會 pause 和 stop 的差別。pause 之後呼叫 API，請求會卡住等待，unpause 之後那個請求會繼續完成。stop 之後呼叫 API，連線會直接被拒絕，而且 start 起來之後，Spring Boot 要重新跑一次啟動流程，等幾秒才能服務。

也因為 pause 期間請求會卡住、沒有任何回應，正式環境要謹慎使用。

最後一行用 `--filter` 篩選名稱，只列出 TaskBoard 相關的容器狀態。
-->

---

# 為什麼需要 docker logs？

「`docker logs` 會把容器的標準輸出（STDOUT）跟標準錯誤（STDERR）印出來，這是除錯的第一道防線。」

```bash
docker logs taskboard-api
```

<!--
容器出問題的時候，我們第一件事要做的，不是重開，而是看 log。

「`docker logs` 會把容器的標準輸出跟標準錯誤印出來」，這是除錯的第一道防線。

對 Spring Boot 來說特別重要。API 容器顯示 Exited，原因幾乎都寫在 log 裡。可能是連不到資料庫的 Communications link failure，可能是 port 被佔用，也可能是資料表不存在。不看 log 就重開，重開幾次都是同一個錯。

要注意，docker logs 只看得到輸出到標準輸出的內容。所以容器化的 Spring Boot 專案，通常讓 log 直接印到 console，而不是寫進容器裡的檔案。檔案在容器裡，容器一刪就沒了。
-->

---

# docker logs 的語法結構

| 選項 | 說明 |
| --- | --- |
| `docker logs [OPTIONS] CONTAINER` | 基本語法結構 |
| `-f`, `--follow` | 持續即時串流輸出新的 log |
| `-n`, `--tail` | 只看最後 N 行 |
| `-t`, `--timestamps` | 每行加上時間戳記 |
| `--since` | 只看某個時間點之後的 log |
| `--until` | 只看某個時間點之前的 log |

<!--
這張表是 `docker logs` 常用的選項。

最常用的是 `-f`，持續即時輸出新的 log。`-n` 只看最後幾行，`-t` 加上時間戳記，`--since` 和 `--until` 則可以篩選時間範圍。

使用 `-f` 時，終端機會一直停在那裡持續輸出，這是正常的，因為它在即時監看。要離開按 Ctrl+C 就好，不會影響容器繼續運作。
-->

---

# docker logs — 範例

```bash
# 即時追蹤 log（最常用於除錯：一邊按前端，一邊看 API 有沒有收到請求）
docker logs -f taskboard-api

# 只看最後 50 行，並加上時間戳記
docker logs -n 50 -t taskboard-api

# 只看最近 30 分鐘的 log
docker logs --since 30m taskboard-api

# 直接撈出錯誤：Spring Boot 的例外堆疊都在這
docker logs taskboard-api 2>&1 | grep -i "exception\|error"
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>補充：</b> <code>--since</code> 跟 <code>--until</code> 除了接受相對時間（如 <code>30m</code>、<code>1h</code>），也能接受完整的日期時間格式。
</div>

<!--
第一行是日常除錯最常打的指令。實務上的用法是，開一個終端機視窗掛著 `docker logs -f taskboard-api`，然後去瀏覽器操作前端，新增一筆任務。回頭看 log 有沒有出現 insert 語句，就能確定請求有沒有打到後端、有沒有寫進資料庫。

第二、三行是回顧型的查詢。服務已經跑了很久，我們只想看最近發生的事，不想從頭滑到尾。

最後一行把 log 裡有 exception 或 error 的行直接撈出來，Spring Boot 的錯誤訊息都在這裡。

要提醒的是，容器被刪除後，log 也會一起消失。正式環境通常會搭配集中式的日誌系統長期保存，docker logs 比較適合當下即時查看。
-->

---

# 總結：容器生命週期與除錯

「容器操作的核心心法：先確認狀態（`ps`），再決定要不要進去看看（`exec`）或查記錄（`logs`），最後才動手改變狀態（`stop` / `start` / `rm`）。」

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>複習重點：</b> <code>run</code> 建立並啟動、<code>stop</code> 停止、<code>start</code> 重新啟動、<code>rm</code> 刪除，<code>logs</code> 用於查看輸出紀錄。
</div>

```bash
docker ps -a && docker logs --tail 20 taskboard-api
```

<!--
這一頁是第三部分的總結，也是整章的核心心法。

「先確認狀態，再決定要不要進去看看或查記錄，最後才動手改變狀態。」

很多新手一遇到問題，就直接 rm 再重建。這樣反而把最有價值的除錯線索，也就是 log，一起刪掉了。正確的順序是先 ps、再 logs、必要時 exec 進去，確認問題之後才處理。

下面這行就是這個心法的縮影，先看所有容器的狀態，再看後端最後 20 行的 log。
-->

---
layout: default
---

# 練習 1：啟動 TaskBoard 資料庫並巡查
### 任務說明

我們要把 TaskBoard 的資料庫容器完整操作一遍：

1. 用背景模式啟動 `mysql:8.4`，命名為 `taskboard-db`，主機 `3307` 映射到容器 `3306`，並帶入四個環境變數：
   `MYSQL_ROOT_PASSWORD=rootpw`、`MYSQL_DATABASE=taskboard`、`MYSQL_USER=appuser`、`MYSQL_PASSWORD=apppw`
2. 確認容器有成功在背景執行，並記下 PORTS 欄位顯示的內容
3. 查看這個容器的 log，找到 `ready for connections` 這句話（MySQL 要跑幾秒初始化，太快查會看不到）
4. 停止容器，並確認狀態變成 Exited
5. 重新啟動它，再確認狀態變回 Up

<!--
接下來是練習一，我們把 TaskBoard 的資料庫容器完整操作一遍，順便把後面每一章都會用到的資料庫建起來。

任務是用背景模式啟動 `taskboard-db`，確認它在執行，查看 log，然後停止再重新啟動。

請大家特別想一想第三步：為什麼要在 log 裡找 ready for connections 這句話？容器 run 起來，不就代表資料庫可以用了嗎？

我們先暫停一下，自己動手試試看。

【講師】給大家五分鐘操作，提醒 MySQL 初始化需要幾秒鐘。
-->

---
layout: default
---

# 練習 1：解題提示
### 提示說明

1. 啟動：
   ```bash
   docker run -d --name taskboard-db -p 3307:3306 \
     -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=taskboard \
     -e MYSQL_USER=appuser -e MYSQL_PASSWORD=apppw mysql:8.4
   ```
2. 確認執行中：`docker ps`（PORTS 欄應顯示 `0.0.0.0:3307->3306/tcp`）
3. 查看 log：`docker logs taskboard-db | grep "ready for connections"`
4. 停止並確認：`docker stop taskboard-db && docker ps -a`
5. 重新啟動：`docker start taskboard-db`

<!--
我們來看解題的關鍵，這些都是第一部分教過的指令，重點在把它們組成完整流程。

回答剛才的問題。MySQL 容器 run 起來，不代表馬上能連。它要先初始化資料目錄、建立資料庫和帳號，大概需要幾秒到十幾秒。看到 ready for connections，才代表真的可以接受連線。很多時候 API 連不上資料庫，其實只是 MySQL 還沒準備好，這也是第五章 healthcheck 要解決的問題。

如果第三步 grep 不到，先等十秒再試一次，不是指令打錯。另外確認已停止的容器，記得加 `-a`。請保留這個容器，練習二還要用。
-->

---
layout: default
---

# 練習 2：進資料庫容器除錯
### 任務說明

延續練習 1 的 `taskboard-db` 容器：

1. 用互動模式進入容器，執行 `mysql -uappuser -papppw taskboard`，再下 `show tables;` 看看現在有沒有表
2. 在 SQL 提示字元裡手動建一張表並塞一筆資料（模擬 Spring Boot 的 JPA 之後會做的事）：
   ```sql
   CREATE TABLE task (id BIGINT PRIMARY KEY AUTO_INCREMENT,
                      title VARCHAR(100), done BOOLEAN DEFAULT FALSE);
   INSERT INTO task (title) VALUES ('學會 docker exec');
   ```
3. 離開 SQL，用 `docker exec` 搭配 `-e` 參數，不進互動模式直接查出這筆資料
4. 用 `docker logs` 只看最近 10 分鐘的 log
5. **想一想（先別動手）**：如果現在 `docker rm -f taskboard-db` 再重新 `docker run`，剛剛那筆資料還在嗎？

<!--
練習二延續剛才的 taskboard-db，把 exec 和 logs 串在一起，情境就是真實除錯會做的事。

任務是進入容器的 mysql，手動建一張 task 表、塞一筆資料，再用不進互動模式的方式查出來，最後看最近十分鐘的 log。

第五題請大家先想就好，不要真的動手：如果現在把 taskboard-db 刪掉再重新 run，剛剛那筆資料還在嗎？

我們先暫停一下，自己動手試試看。

【講師】給大家五到八分鐘，提醒 mysql 的 -u 和 -p 後面不能有空格，並且不要真的刪除容器。
-->

---
layout: default
---

# 練習 2：解題提示
### 提示說明

```bash
# 1-2. 進互動 SQL 提示字元，貼上建表與 insert
docker exec -it taskboard-db mysql -uappuser -papppw taskboard

# 3. 不進互動模式，直接下 SQL 查資料
docker exec taskboard-db mysql -uappuser -papppw taskboard \
  -e "select * from task;"

# 4. 篩選時間查 log
docker logs --since 10m taskboard-db
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>第 5 題答案：</b> 資料會<b>全部消失</b>。容器刪掉，它的可寫層就一起沒了。要讓資料活下來，必須把 MySQL 的資料目錄掛到 Volume 上 — 這正是第七章的主題。
</div>

<!--
我們來看解答。第一個指令用 `-it` 進互動模式，第二個不加 `-it`，直接用 `-e` 帶 SQL 進去，這是寫在腳本裡最常用的形式。執行後會印出一張表，看到剛才 insert 的「學會 docker exec」。

回到第五題，答案是資料會全部消失。容器刪掉，它的可寫層就一起沒了。

這就是為什麼大家常聽到「容器不要拿來存資料」。我們現在的 taskboard-db 其實很脆弱，同事一個手滑 rm，開發資料就歸零。第七章我們會用 Volume 解決這個問題。

請大家先不要刪掉 taskboard-db，後面幾章還會用到。
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
<tr><td>docker run</td><td>從 Image 建立並啟動一個全新的 Container</td></tr>
<tr><td>前景 / 背景</td><td>預設會佔用終端機，加 <code>-d</code> 轉為背景執行</td></tr>
<tr><td>docker exec</td><td>進入「已存在」的容器執行額外指令，不影響主行程</td></tr>
<tr><td>容器生命週期</td><td>created → running → paused → stopped → removed</td></tr>
<tr><td>docker logs</td><td>印出 STDOUT/STDERR，是除錯的第一步</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> <code>stop</code> 不等於 <code>rm</code>，stop 資料還在，rm 才是真的刪除，這是最容易搞混的兩個指令。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入 Dockerfile，學習怎麼把「怎麼組 image」寫成可重複執行的腳本。
</div>

<!--
我們回顧一下這一章。

第一，`docker run` 每次都會建立一個全新的容器。第二，預設是前景執行，加 `-d` 轉到背景。第三，`docker exec` 進入已經存在的容器，離開不會讓容器停止。第四，容器有五個狀態，除了 rm，其他都能來回切換。第五，`docker logs` 是除錯的第一步。

用開店來串，run 是開幕，ps 是巡店，stop 和 start 是打烊和開門，exec 是進去巡視，logs 是看監視器回放，rm 才是真的拆店。

下一章，我們要學 Dockerfile，把 TaskBoard 自己打包成 Image。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
這一章我們把容器從開幕到拆店完整走了一遍，也學會了遇到問題先看狀態、再看 log 的除錯順序。

進入下一章之前，建議把兩題練習親手做過一遍。容器操作是後面所有章節的基本功。我們下一章見。

【講師】開放 Q&A，可以引導大家回想 stop 和 rm 的差別、exec 和 run -it 的差別。
-->
