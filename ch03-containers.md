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
大家好，這一章我們要來聊「容器操作」。

前面幾章我們認識了 Image（映像檔）跟 Docker 的基本概念，這一章開始我們要動手，把容器一步步「開機、運作、關機、丟棄」，完整跑過一次它的生命週期。

⚠️ 這章的指令會比較多，但大家不用死背，重點是理解每個指令在生命週期的哪個階段被使用。

預期結果：上完這章，大家應該能自己啟動一個容器、進去裡面看一看、查它的 log、然後乾淨地收拾掉。
-->

---
layout: default
---

# Outline

1. 容器基本操作：run / ps / stop / start / rm
2. 前景與背景執行：-it 與 -d
3. 容器生命週期與 logs 除錯
4. 練習題
5. 總結

<!--
先看一下這章的地圖。

我們會分三大部分：第一部分學會操作容器的五個基本指令；第二部分搞懂「前景執行」跟「背景執行」的差別，順便學會怎麼「溜進」一個正在跑的容器；第三部分把整個容器生命週期串起來，並學會用 logs 除錯。

最後有兩題練習，讓大家動手做過一遍會記得比較牢。

⚠️ 提醒大家，這些指令都要在終端機（terminal）裡實際打過一次，光看投影片是記不住的。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Part 1
## 容器基本操作

<!--
第一部分，我們從最基本的五個指令開始：run、ps、stop、start、rm。

這五個指令就像是容器的「開店五步驟」：開店（run）、看看誰在店裡（ps）、暫時打烊（stop）、重新開門（start）、把店收掉（rm）。

⚠️ 這五個指令的順序很重要，很多新手會搞混 stop 跟 rm，以為 stop 就是刪除，其實 stop 只是「先關燈」，容器本體還在。
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
大家可以先想像開一家新分店：docker run 就是「用同一份食譜，開一間全新的分店」。

這裡示範的 hello-world 是 Docker 官方拿來測試安裝有沒有成功的最小範例，執行完會印出一段歡迎訊息然後容器就結束了。

⚠️ 易錯點：很多剛學 Docker 的人會以為 docker run 是「打開」一個容器，其實它每次都是「新建」一個容器。如果要打開已經存在但關閉的容器，要用的是待會會教的 docker start。

預期結果：終端機會印出一段 "Hello from Docker!" 的歡迎訊息。
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
這張表整理了 docker run 最常用的幾個選項，我們一項一項看過。

大家可以把這些選項想成點餐時的「加購選項」：要不要外帶（-d 背景執行）、要不要現場吃（-it 互動）、要不要貼名牌（--name）、吃完要不要順手收桌（--rm）。

⚠️ 易錯點：-p 的順序永遠是「主機的 port : 容器的 port」，方向搞反很容易連不到服務。

下一頁我們馬上看實際範例。
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
這頁把 TaskBoard 整套用最原始的方式跑起來，之後第五章我們會知道這三行可以濃縮成一個 docker compose up。

第一行是資料庫。MySQL 官方 Image 支援四個初始化環境變數，MYSQL_DATABASE 會幫我們建好空的 taskboard 資料庫，MYSQL_USER 跟 MYSQL_PASSWORD 會建一個非 root 的應用帳號，並直接授權它操作那個資料庫——這正好對應大家在 application.yml 裡設定的那組帳密。

第二行是後端。請大家特別注意這個觀念：Spring Boot 的設定可以用環境變數覆蓋，規則是把 properties 的點換成底線、全部大寫，所以 `spring.datasource.url` 就變成 `SPRING_DATASOURCE_URL`。這是容器化 Spring Boot 最關鍵的一招——同一個 Image，靠不同環境變數就能連到開發、測試、正式三套不同的資料庫，完全不用改程式、不用重 build。

⚠️ 這裡的 `host.docker.internal` 是暫時的權宜寫法。容器裡的 localhost 指的是「容器自己」，不是我們的電腦，所以 API 容器不能寫 localhost:3307。host.docker.internal 是 Docker Desktop 提供的特殊網域名稱，代表「跑 Docker 的這台主機」。這個寫法很醜，第六章我們會用自訂網路，讓 API 直接寫 `jdbc:mysql://taskboard-db:3306/taskboard` 就好。

⚠️ 易錯點：如果沒有加 -d，終端機會被「卡住」，因為容器是前景執行、佔用了目前的終端機視窗，下一部分會細講。

預期結果：三行跑完 `docker ps` 應該看到三個容器都是 Up 狀態。
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
這六個指令是我們每天都會用到的容器管理指令，先掃過一遍。

大家可以把 docker ps 想成「巡店」：看看現在有哪些店還開著（ps）、或是連已經打烊的店也一起列出來（ps -a）。

⚠️ 易錯點：docker stop 跟 docker rm 是兩件不同的事，stop 只是「打烊關燈」，容器資料都還在；rm 才是真的把店「收掉拆除」。剛學的人很容易把兩個搞混。

下一頁看實際範例。
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
這幾行就是最常見的巡店流程：先看誰在跑（ps），關掉一家（stop），過一陣子想重開就 start，真的不要了才 rm。

大家注意 ps 輸出的 PORTS 欄位，`0.0.0.0:8081->8080/tcp` 就是我們 -p 設定的映射結果，箭頭左邊是主機、右邊是容器內。以後容器連不上的時候，第一件事就是看這欄有沒有東西。

最後一行是大家之後每天都會用到的組合技：改了程式重新 build Image 之後，舊容器不會自動更新，一定要先 stop 再 rm，然後用新 Image 重新 run 一次。

⚠️ 易錯點：docker rm 對「正在執行中」的容器預設不給刪，會報錯，一定要先 stop，或加 -f 強制刪除。

預期結果：docker ps -a 會看到容器狀態從 Up 變成 Exited，start 之後又變回 Up。
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
這頁想強調一個很多人踩過的坑：以為 stop 完資料就沒事了，結果過陣子手滑 rm 掉，才發現資料真的救不回來了。

生活化的比喻是「打烊」跟「拆店」的差別：打烊之後櫃子裡的東西都還在，隔天開門都找得到；但拆店之後東西就真的沒了。

⚠️ 易錯點：docker container prune 這個指令會一次刪掉「所有」已停止的容器，沒有二次確認就下去按 y 的話，可能會把想留的容器一起清掉，使用前務必先用 ps -a 確認清單。

預期結果：大家應該能講出 stop 跟 rm 的差別，這是這一頁最重要的收穫。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Part 2
## 前景與背景執行

<!--
第二部分，我們要搞懂容器執行時的兩種模式：前景（foreground）跟背景（detached）。

這個概念很像我們去餐廳吃飯：前景執行像是「站在櫃檯前面等現點現做」，你走開餐點就中斷了；背景執行像是「內用點餐後回座位滑手機」，廚房自己在後面默默做，你不用一直盯著。

⚠️ 這部分很多人一開始會搞不清楚終端機為什麼被「卡住」，我們待會解釋原因。
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
Spring Boot 的例子最好懂：不加 -d 的時候，那個 Spring 的 ASCII banner 跟啟動 log 會直接洗在你的終端機上，這其實在第一次除錯的時候很好用，可以直接看到它有沒有連上資料庫。但它會佔住視窗，而且你一按 Ctrl+C 服務就停了。

大家可以把前景執行想成「顧著爐子煎蛋」，你人一定要站在旁邊，離開爐子蛋就糊了；背景執行則是「丟進電鍋按下開關」，你可以去忙別的事，電鍋自己煮。

⚠️ 易錯點：很多新手第一次執行 docker run 沒加 -d，發現終端機卡住以為當機了，其實只是容器在前景執行，按 Ctrl+C 就能中斷（但也會把容器停掉）。

預期結果：加了 -d 之後，終端機馬上印出一長串 Container ID 並回到可輸入狀態。
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
這張表整理了兩種最常搭配的組合：-it 跟 -d，方向剛好相反。

-it 是「我要跟容器對話」，適合拿來開一個互動式的 shell；-d 則是「我不想理它，讓它自己在背景跑」，適合拿來跑長駐服務。

⚠️ 易錯點：-it 跟 -d 通常不會一起用在同一次啟動，因為互動模式本來就需要你「盯著」畫面，跟背景執行的精神是衝突的。

下一頁看範例對照。
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
第一行示範互動模式的實際用途：我想確認 gradle:8.10-jdk21 這個 Image 裡的 Java 到底是不是 21、Gradle 指令能不能跑，就開一個臨時容器進去打 `java -version`、`gradle -v`，看完 exit 離開，加了 --rm 容器自動消失，不留垃圾。這在第四章寫 Dockerfile 之前很好用——先進去確認環境，再把確認過的指令寫進 Dockerfile。

第二行是背景長駐服務，我們平常部署的 API、資料庫幾乎都是這種模式。

第三行帶到下一個重點：exec，它不是新建容器，而是「溜進」一個已經在運作中的容器，下一頁細講。

⚠️ 易錯點：第一行的容器一旦 exit 離開 bash，容器就會跟著停止，因為 bash 是這個容器的主行程。但第二行的 taskboard-api 不一樣，它的主行程是 java，所以 exec 進去再離開，服務照常運作。

預期結果：第一行會直接進入容器內的 shell 提示字元。
-->

---

# 什麼是 docker exec？

「`docker exec` 會在一個『正在執行中』的容器裡，額外執行一個新指令，不會影響容器原本的主行程。」

```bash
# 進到資料庫容器裡，直接用 mysql client 查資料
docker exec -it taskboard-db mysql -uappuser -papppw taskboard
```

<!--
大家平常除錯的時候，最常用的就是這招：容器已經跑起來了，想進去看看設定檔對不對、log 在哪裡，就用 exec 進去看。

這個範例特別實用：以前我們要用 MySQL Workbench 才能查資料，現在容器裡本來就附了 mysql 這個命令列 client，一行指令就進到 SQL 提示字元，可以直接 `select * from task;` 確認 Spring Boot 到底有沒有把資料寫進去。這是除錯 API 時最快的驗證方式。

⚠️ 易錯點：docker exec 執行的指令必須是「可執行檔」，不能直接丟一串用 && 串起來的指令。例如 docker exec -it my_container "echo a && echo b" 是錯的，要寫成 docker exec -it my_container sh -c "echo a && echo b" 才對。

預期結果：執行後會拿到容器內的 shell 提示字元，可以在裡面下 ls、cat 等指令查看。
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
這張表跟 docker run 的選項有點像，因為 exec 本質上也是在容器裡「跑一個指令」，差別只是容器已經存在、不用重新建立。

⚠️ 易錯點：exec 執行的指令只在容器主行程存活期間有效，如果容器本身被 stop 了，exec 進去的 session 也會跟著結束。

下一頁看實際範例。
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
這四行是除錯 TaskBoard 時的標準工具組，大家一定會用到。

第一行：JPA 設定 ddl-auto 之後，最快確認「表到底建起來沒」的方法。用 -e 帶 SQL 進去，不用進互動模式，很適合寫在腳本裡。

第二行：進後端容器逛一圈，確認 jar 檔的路徑跟我們 Dockerfile 寫的一不一樣。

第三行是我最推薦大家記起來的一行。API 連不上資料庫的時候，九成問題出在環境變數：可能 key 拼錯、可能 docker run 的時候少打一個 -e。這行直接把容器實際收到的 SPRING_ 開頭變數列出來，一看就知道。

第四行確認 Angular 的 dist 檔案有沒有正確複製到 nginx 的預設目錄。網頁打開是 404 的時候先查這個。

⚠️ 易錯點：exec 進去改的東西只存在這個容器裡，不會回寫到 Image，容器被刪掉改動就一起消失。要永久生效必須改 Dockerfile 重新 build。

預期結果：第二行執行後畫面會進入容器內的 shell，打 exit 離開，容器本身仍繼續在背景執行。
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
這頁要特別把 exec 跟 run 的差異講清楚，因為這是最多人搞混的地方。

用生活比喻來說：run -it 像是「你就是店長，你一走整間店就打烊了」；exec -it 則是「你只是臨時進去巡店的訪客，你走了店還是照常營業」。

套到 TaskBoard：exec 進 taskboard-api 打 exit，Spring Boot 的 java 行程還在跑，API 完全不受影響，因為我們只是開了一個額外的 shell 行程。

⚠️ 易錯點：串接指令一定要包在 sh -c "..." 裡面，直接丟多重指令會報錯，這是官方文件特別強調的一點。

預期結果：這頁執行完會先列出 /app 目錄內容，再印出設定檔內容。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Part 3
## 容器生命週期

<!--
第三部分，我們把前面學到的指令串起來，看整個容器從「出生」到「消失」會經過哪些狀態。

這部分很適合用「開店」的比喻貫穿：開幕（created）→ 營業中（running）→ 公休暫停（paused）→ 打烊（stopped）→ 拆店（removed）。

⚠️ 這部分的重點是理解「狀態」而不是背指令，指令我們前面都學過了。
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
大家可以把這五個狀態對照到一間店：裝潢好但還沒開門營業就是 created；掛牌營業就是 running；老闆臨時說今天公休但東西都還在店裡是 paused；晚上拉下鐵門是 stopped；房東把店面收回去重新裝潢就是 removed，東西全部清空。

⚠️ 易錯點：docker run 其實是「create + start」兩個動作合在一起做，很多人不知道 Docker 底層還有一個單獨的 docker create 指令，只是我們平常很少單獨用它。

預期結果：大家應該能照順序講出這五個狀態，並且知道對應到哪個指令。
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
這張表把每個狀態轉換對應到的指令整理出來，等於是我們前面學過指令的「總複習」。

大家可以發現，除了 rm 之外，其他指令都是「可逆」的，狀態可以來回切換；只有 rm 是單向的，一去不復返。

⚠️ 易錯點：pause 跟 stop 不一樣，pause 是把容器內的所有行程「凍結」（暫停 CPU 排程），但行程還在記憶體裡，unpause 之後會立刻從凍結的地方繼續動作，跟 stop/start 是完全不同的機制。

下一頁看實際範例。
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
大家可以照這個順序在終端機一步步跑過一次，中間每執行一行就順手打一次 docker ps -a，親眼看著 STATUS 欄位從 Up 變 Paused、變 Exited、再變回 Up，會比死背這張表更有感覺。

這裡順便讓大家體會 pause 跟 stop 的差別：pause 之後打 API 會「卡住」等待，unpause 之後那個請求會繼續完成；stop 之後打 API 是直接連線被拒絕，而且 start 起來 Spring Boot 要重新跑一次啟動流程，等個幾秒才會服務。

⚠️ 易錯點：pause 期間容器完全凍結，如果這時候有使用者正在打這個服務的 API，請求會卡住沒有回應，不是報錯，是真的沒反應，正式環境要謹慎使用。

預期結果：最後一行的 docker ps -a 會顯示 taskboard-api 目前的實際狀態。
-->

---

# 為什麼需要 docker logs？

「`docker logs` 會把容器的標準輸出（STDOUT）跟標準錯誤（STDERR）印出來，這是除錯的第一道防線。」

```bash
docker logs taskboard-api
```

<!--
這是我們平常除錯最先做的一件事：服務跑不起來、連不上，第一步永遠是先看 log，而不是急著重開容器。

對 Spring Boot 來說這頁特別重要。API 容器 `docker ps` 顯示 Exited，原因幾乎都寫在 log 裡：可能是 `Communications link failure`（連不到資料庫）、可能是 `Port 8080 was already in use`、也可能是 `Table 'taskboard.task' doesn't exist`。不看 log 就重開，重開一百次還是同一個錯。

⚠️ 易錯點：docker logs 只能看到容器「輸出到 STDOUT/STDERR」的內容。這也是為什麼容器化的 Spring Boot 專案，logback 通常只設定 console appender，不寫檔案——寫進容器裡的檔案，容器一刪就沒了，還不如直接印到標準輸出讓 Docker 收。

預期結果：畫面會印出容器啟動至今的所有輸出紀錄。
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
這張表整理了 docker logs 最常用的選項，跟前面幾個指令的表格排版一樣，我們照樣配範例來看。

⚠️ 易錯點：-f 會讓終端機「一直卡住」持續輸出，這是正常的，因為它在即時監看，要離開的話按 Ctrl+C 就好，不會影響容器本身繼續運作。

下一頁看實際範例。
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
第一行是我們日常除錯最常打的指令。實務上的用法是：開一個終端機視窗掛著 `docker logs -f taskboard-api`，然後去瀏覽器操作 Angular 前端，新增一筆任務，回頭看 log 有沒有跳出 Hibernate 的 insert 語句——這樣就能確定請求到底有沒有打到後端、有沒有寫進資料庫。

第二、三行則是回顧型的查詢，服務已經跑了很久，我們只想看最近發生了什麼事，不想從頭滑到尾。

⚠️ 易錯點：如果容器已經被 rm 刪除，log 也會一起消失，正式環境通常會搭配額外的 log 收集工具（例如集中式日誌系統）長期保存，docker logs 只適合當下即時查看。

預期結果：第一行執行後畫面會持續更新，直到我們按 Ctrl+C 離開。
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
這頁是第三部分的總結，也是整章的核心心法：遇到問題不要慌，先看狀態、再看 log，最後才動手改變容器的狀態。

⚠️ 易錯點：很多新手一遇到問題就直接 rm 重建，這樣反而把最有價值的除錯線索（log）一起刪掉了，正確順序應該是先看完 log 確認問題再處理。

預期結果：大家能講出容器生命週期的五個狀態，以及每個狀態要用哪個指令切換。
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
這是本章第一題，把 Part 1 的五個基本指令實際操作一遍，順便把後面每一章都要用的資料庫容器建起來。

第 3 步特別重要：MySQL 容器不是 docker run 完就能連的，它要先初始化資料目錄、建立資料庫跟帳號，這段時間大概幾秒到十幾秒。很多同學 API 連不上資料庫，其實只是 MySQL 還沒 ready。學會用 log 判斷「資料庫真的可以接受連線了」，是這題最大的收穫，這也是第五章 healthcheck 要解決的問題。

⚠️ 易錯點：記得用 -d 背景執行，不然終端機會被 MySQL 的 log 佔滿。
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
提示都是 Part 1 教過的原班指令，只是要大家自己組出完整流程。

⚠️ 易錯點：docker ps 預設只顯示執行中的容器，要確認「已停止」的狀態記得加 -a。另外第 3 步如果 grep 不到，先等個十秒再試一次，不是指令打錯。

預期結果：最後 docker ps 能看到 taskboard-db 回到 Up 狀態。請保留這個容器，練習 2 還要用。
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
這一題把 Part 2 的 exec 跟 Part 3 的 logs 串在一起，而且情境完全是真實除錯會做的事。

第 3 步要大家自己組出 `docker exec taskboard-db mysql -uappuser -papppw taskboard -e "select * from task;"` 這種寫法，這是寫在腳本裡最常用的形式。

第 5 步是刻意留的伏筆，答案是「資料會全部不見」，因為容器的可寫層跟容器同生共死。這個痛點就是第七章 Volume 要解決的問題，這裡先讓大家在腦中留一個問號，不要真的刪掉容器。

⚠️ 易錯點：第 1 步 mysql 指令的 -u 跟 -p 後面「不能有空格」，寫成 `-u appuser` 會失敗。
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
這題重點是分清楚 exec -it（互動）跟 exec 直接帶指令的差別，以及第 5 題那個伏筆。

第 5 題請大家一定要有感：這就是為什麼「容器不能拿來存資料」這句話會被講一百次。我們現在手上的 taskboard-db 是很脆弱的，同事誤下一個 docker rm，開發資料全部歸零。第七章我們會用一行 -v 參數把這個問題解決掉。

⚠️ 易錯點：如果直接對執行中的容器下 docker rm，Docker 會拒絕，除非加 -f。

預期結果：第 3 步應該印出一張表格，看到剛剛 insert 的那筆「學會 docker exec」。請不要刪掉 taskboard-db 容器，後面幾章還會用到。
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
<tr><th>重點</th><th>說明</th></tr>
<tr><td>docker run</td><td>從 Image 建立並啟動一個全新的 Container</td></tr>
<tr><td>前景 / 背景</td><td>預設會佔用終端機，加 <code>-d</code> 轉為背景執行</td></tr>
<tr><td>docker exec</td><td>進入「已存在」的容器執行額外指令，不影響主行程</td></tr>
<tr><td>容器生命週期</td><td>created → running → paused → stopped → removed</td></tr>
<tr><td>docker logs</td><td>印出 STDOUT/STDERR，是除錯的第一步</td></tr>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> <code>stop</code> 不等於 <code>rm</code>，stop 資料還在，rm 才是真的刪除，這是最容易搞混的兩個指令。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入 Dockerfile，學習怎麼把「怎麼組 image」寫成可重複執行的腳本。
</div>

<!--
這章內容不少，但如果只能記住一件事，那就是「容器操作 = 管理狀態」。

大家把它想成開店的比喻就很好記：run 開幕、ps 巡店、stop/start 打烊開門、pause 臨時公休、exec 是從後門溜進去看、logs 是監視器回放、rm 才是真的拆店。

⚠️ 最後再強調一次最容易搞混的兩點：stop 不等於 rm，資料還在；exec 離開不會讓容器停止，除非那個行程本身就是容器的主行程。

預期結果：大家應該能夠獨立完成「啟動 → 巡查 → 除錯 → 清理」這一整套容器操作流程。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對容器的 run、exec、logs 這些指令，或是生命週期狀態轉換，有沒有什麼疑問？都歡迎提出來討論。

⚠️ 建議大家在進入下一章之前，先把這章練習的兩題親手做過一遍，容器操作是後面所有章節的基本功。
-->
