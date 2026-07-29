---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: Volume 資料持久化
routeAlias: ch07
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">Volume 資料持久化</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「容器會消失，但資料不必跟著陪葬」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
大家好，歡迎來到第七章，我們今天要聊的主題是 Volume 資料持久化。

前面幾章我們學會了怎麼啟動容器、怎麼寫 Dockerfile、怎麼用 Compose 串起多個服務。但大家有沒有想過一個問題：如果容器裡存了很重要的資料，結果容器被刪掉了，那些資料會去哪裡？

答案是——通通不見。這就是這一章要解決的問題。我們會學到三種讓資料「活得比容器久」的方式：Volume、Bind Mount、還有 tmpfs，也會學怎麼用指令管理它們，最後還會實際操作一次資料備份與還原。

學完這一章，大家就能自信地說：我知道怎麼讓容器裡的資料不要說沒就沒了。
-->

---
layout: default
---

# Outline

- 為什麼容器需要「外部儲存」——資料持久化的痛點
- Volume vs Bind Mount vs tmpfs 三種儲存方式比較
- `docker volume` 指令：create / ls / inspect / rm
- `-v` 短語法 vs `--mount` 長語法
- 實戰：用臨時容器備份與還原 Volume 資料
- 練習題 x2（難度遞增）
- 總結

<!--
這一章的架構分成三大部分。

第一部分，我們先搞懂 Volume、Bind Mount、tmpfs 這三個常常被搞混的名詞，它們各自的定位跟差異。

第二部分，我們會實際操作 docker volume 的管理指令，包含怎麼建立、查詢、檢查一個 Volume。

第三部分是重頭戲——資料備份與還原，我們會用一個很經典的技巧，借用「臨時容器」把 Volume 裡的資料打包成檔案，也學會怎麼把備份還原回去。

最後留兩題練習給大家動手做，難度會慢慢往上疊。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Part 1
## Volume vs Bind Mount vs tmpfs

<!--
我們先進入第一部分，先建立觀念，再談指令。

這部分的重點是搞清楚三種資料儲存方式的差異，因為接下來所有的操作，都是建立在「我們知道自己在用哪一種」的前提上。
-->

---
layout: default
---

# 容器被刪掉之後，資料去哪了？

「容器預設是無狀態（stateless）的，容器內的檔案系統會隨著容器一起被刪除。」

- `docker rm taskboard-db` 刪掉容器，裡面 `task` 表的所有任務資料也一起消失
- 開發測試環境影響不大，正式環境的重要資料一旦跟容器綁在一起就是災難
- Docker 提供三種方式讓資料「活得比容器久」：Volume、Bind Mount、tmpfs

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>還記得第三章練習 2 的伏筆嗎？</b> 我們在 <code>taskboard-db</code> 裡手動建了 task 表、塞了一筆資料。這一章就是要回答那個問題：容器刪掉重建之後，那筆資料還在嗎？
</div>

<!--
大家有沒有經驗過，改一改容器設定，`docker rm` 之後才發現裡面的資料庫資料整個不見了？我自己剛學 Docker 的時候就踩過這個坑。

生活化一點來說，容器就像一間「臨時搭建的房子」，說拆就拆。如果貴重物品都放在房子裡面，房子一拆，東西也跟著沒了。

⚠️ 這是初學者最容易忽略的地方：容器裡的檔案系統預設是跟容器綁在一起的，`docker rm` 之後那個可寫層（writable layer）就直接消失，沒有「垃圾桶」可以復原。

這也是為什麼我們一定要學會今天這三種持久化儲存的方式。
-->

---
layout: default
---

# 什麼是 Volume？

「Volume（資料卷）是由 Docker 建立與管理的持久化儲存空間，儲存在 host 上 Docker 管理的目錄裡，生命週期完全獨立於容器。」

容器刪除後，Volume 資料依然保留，可掛載給新容器繼續使用。

```bash
docker volume create taskboard-db-data
docker run -d --name taskboard-db \
  -v taskboard-db-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=taskboard mysql:8.4
```

Volume 的資料由 Docker 全權管理，我們不需要知道它實際存在 host 的哪個路徑，只需要透過 `docker volume` 指令來操作。

<!--
Volume 是 Docker 官方最推薦的持久化方式，資料庫幾乎一定用這個。

用「外部倉庫」來比喻：容器是一間隨時可能被拆掉重建的房子，Volume 就是我們額外租的倉庫，房子拆了倉庫還在，重新蓋一間新房子，照樣可以把倉庫接回去用。

這段範例建立一個叫 taskboard-db-data 的 Volume，掛到容器的 /var/lib/mysql——這是 MySQL 存放所有資料檔案的目錄，記住這個路徑，這就是 MySQL 容器唯一需要持久化的地方。之後就算容器被 rm 掉，Volume 裡的資料完好無缺，重新 run 一個新容器掛上同一個 Volume，所有任務資料原封不動回來。

⚠️ 順帶一提，掛了 Volume 之後 MYSQL_DATABASE 這類初始化環境變數就只在「第一次」生效。因為 MySQL 官方 Image 的初始化腳本會先檢查資料目錄是不是空的，不是空的就直接啟動，不會重跑初始化。所以之後改 MYSQL_PASSWORD 是不會生效的，很多同學會在這裡卡很久。

⚠️ 容易搞混的地方：Volume 是「由 Docker 管理」，我們不用自己去 host 上找路徑，這跟等一下要講的 Bind Mount 完全不一樣。
-->

---
layout: default
---

# 什麼是 Bind Mount？

「Bind Mount（綁定掛載）是把 host 上『既有』的檔案或目錄，直接掛載進容器內，容器看到的就是 host 上那份原始資料。」

掛載的是 host 上原本就存在的路徑，容器刪除不影響 host 端資料。

```bash
# 把本機的 SQL 初始化腳本掛進 MySQL 的 init 目錄（唯讀）
docker run -d --name taskboard-db \
  --mount type=bind,source="$(pwd)"/db/init.sql,target=/docker-entrypoint-initdb.d/init.sql,readonly \
  -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=taskboard mysql:8.4

# 把 Spring Boot 的 log 目錄掛出來，用本機編輯器直接看
docker run -d --name taskboard-api \
  --mount type=bind,source="$(pwd)"/logs,target=/app/logs \
  taskboard-api:1.0.0
```

常見情境：掛設定檔、掛初始化腳本、把容器內的 log 撈到本機看。

<!--
Bind Mount 跟 Volume 最大的不同，就是它掛載的是「host 上原本就存在」的路徑，不是 Docker 幫我們建立管理的空間。

用「書櫃」比喻：書櫃本來就放在我們自己家裡，只是暫時搬進容器這個房間給它用。容器怎麼重建刪除，書櫃始終是我們家的東西。

第一個範例超級實用。MySQL 官方 Image 有個約定：放在 /docker-entrypoint-initdb.d/ 底下的 .sql 或 .sh 檔案，會在資料庫「第一次初始化」時自動執行。所以我們把專案裡的 db/init.sql（建表、塞測試資料）掛進去，容器一起來 schema 就準備好了，新同事完全不用手動跑 SQL。注意最後加了 readonly，容器裡的程式不可能改到我們專案裡的檔案。

第二個範例是把 log 撈出來。容器裡的檔案要用 docker exec 才看得到很麻煩，掛出來之後就能用本機的編輯器或 tail 直接看。

⚠️ 注意事項：Bind Mount 預設可寫，容器裡的程式亂寫亂刪會直接影響 host 上的檔案，敏感目錄一定要加 readonly。

⚠️ 注意事項：Bind Mount 預設是可寫的，容器裡的程式如果亂寫亂刪，會直接影響到 host 上的檔案，所以敏感目錄建議加 `readonly` 或 `ro`。
-->

---
layout: default
---

# 什麼是 tmpfs？

「tmpfs mount 是把資料存在 host 的記憶體中，不會寫入任何檔案系統，容器停止或 host 重開機，資料就會消失。」

寫入速度快，容器一停止內容就消失，無法保留。

```bash
docker run -d --name taskboard-api \
  --mount type=tmpfs,destination=/tmp \
  taskboard-api:1.0.0
```

- 適合暫存資料：session 快取、暫存運算結果
- 只支援 Linux 容器
- 速度快但不持久，是與 Volume、Bind Mount 最本質的差異

<!--
tmpfs 是這三種方式裡面最特別的一個，因為它根本不寫進硬碟，是直接存在記憶體裡。

用「便利貼」來比喻最貼切：便利貼寫東西很快很方便，但只要撤掉（容器一停止），內容就跟著消失，沒辦法留到下次用。

範例裡我們把 tmpfs 掛到 /tmp。Spring Boot 處理檔案上傳時，Multipart 的暫存檔就是寫在 /tmp，這種資料寫完馬上就處理掉，放記憶體最快，而且容器一停自動清空，不會累積垃圾。

⚠️ 易錯點：tmpfs 只能用在 Linux 容器上，Windows 容器不支援；而且千萬別把重要資料放進 tmpfs，容器一重啟，資料就真的救不回來了。
-->

---
layout: default
---

# Volume vs Bind Mount vs tmpfs 比較

| 比較項目 | Volume | Bind Mount | tmpfs |
| --- | --- | --- | --- |
| 儲存位置 | Docker 管理的 host 目錄 | host 上任意指定路徑 | host 記憶體 |
| 管理方式 | `docker volume` 指令管理 | 依賴 host 檔案系統 | 隨容器生命週期 |
| 資料持久性 | 容器刪除後仍保留 | 容器刪除後仍保留（在 host 上）| 容器停止即消失 |
| 適合情境 | 資料庫、需要備份遷移的資料 | 開發環境掛載原始碼、設定檔 | 暫存快取、機敏暫存資料 |
| TaskBoard 的用法 | `taskboard-db-data` → `/var/lib/mysql` | `db/init.sql`、API 的 `logs/` | API 的 `/tmp` |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>選擇原則：</b> 需要 Docker 幫忙管理、備份、遷移，選 Volume；需要直接存取 host 上的既有檔案（設定檔、SQL 腳本），選 Bind Mount；只是暫存、不在乎重開就消失，選 tmpfs。
</div>

<!--
這張表把三種方式攤開來一次比較，我們可以看到它們的差異其實蠻清楚的：管理權在誰手上、資料放在哪裡、容器不在了資料還在不在。

實務上的判斷原則很簡單：資料庫這種要備份、要遷移的重要資料，優先選 Volume；本機開發時要即時看到程式碼變化，選 Bind Mount；只是暫存用、不怕遺失的，才考慮 tmpfs。

⚠️ 容易誤解的地方：Bind Mount 的資料「容器刪除後仍保留」，是因為它本來就存在 host 上，不是 Docker 幫忙保留的，這跟 Volume 的持久化邏輯是不一樣的概念。
-->

---
layout: default
---

# 補充：`-v` 短語法 vs `--mount` 長語法

Docker 官方文件建議「優先使用 `--mount`」，因為它語意明確、參數完整；`-v` 是比較早期的簡短寫法，範例中仍然很常見。

```bash
# --mount 長語法（推薦）
docker run --mount type=volume,src=taskboard-db-data,dst=/var/lib/mysql mysql:8.4

# -v 短語法（常見但語意較不明確）
docker run -v taskboard-db-data:/var/lib/mysql mysql:8.4
```

⚠️ Docker 版本注意：在 Compose 檔案中，官方建議 Volume／Bind Mount 都用 `type: bind` / `type: volume` 的長語法明確標示類型，短語法 `./data:/data` 目前仍支援、也很常出現在範例中，並不算錯誤，但團隊協作時長語法可讀性更好。

<!--
這一頁專門講兩種寫法的差異，因為我們接下來的範例會兩種都用到。

`--mount` 的好處是每個參數都寫得清清楚楚，type、source、target 一目了然；`-v` 比較精簡，但如果沒背熟順序容易搞混主機路徑跟容器路徑誰在前面。

⚠️ 特別提醒：在 Compose 的 yaml 檔案裡，短語法 `./data:/data` 還是很常見，不算錯誤寫法，但官方文件比較推薦用 `type: bind` 的長語法，尤其是團隊合作、需要清楚標示唯讀等選項的時候，長語法會讓設定更好懂。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Part 2
## docker volume 指令

<!--
第二部分我們要正式進入 Volume 的管理指令，把剛剛學到的觀念，轉換成實際能操作的指令。
-->

---
layout: default
---

# docker volume 常用指令

| 指令 | 說明 |
| --- | --- |
| `docker volume create <name>` | 建立一個新的 Volume |
| `docker volume ls` | 列出所有 Volume |
| `docker volume inspect <name>` | 檢查 Volume 的詳細資訊（如 host 上實際路徑）|
| `docker volume rm <name>` | 刪除指定 Volume |
| `docker volume prune` | 清除所有未被任何容器使用的 Volume |

<!--
這張表把最常用的五個 Volume 指令整理起來，create、ls、inspect、rm、prune，這幾個指令涵蓋了 Volume 從建立到清理的完整生命週期。

我們接下來會逐一示範這些指令的實際輸出長什麼樣子。

⚠️ 提醒大家：因為這張表有五列，我們把實際範例拆到下一頁，等一下就能看到完整的操作過程跟輸出結果。
-->

---
layout: default
---

# docker volume 常用指令 — 範例

```bash
$ docker volume create taskboard-db-data
taskboard-db-data

$ docker volume ls
DRIVER    VOLUME NAME
local     taskboard-db-data
local     taskboard_db-data          # Compose 建的會自動加專案名稱前綴

$ docker volume inspect taskboard-db-data
[
    {
        "Driver": "local",
        "Mountpoint": "/var/lib/docker/volumes/taskboard-db-data/_data",
        "Name": "taskboard-db-data",
        "Scope": "local"
    }
]
```

<!--
我們一步步操作一次：先 create 建立 taskboard-db-data，接著用 ls 確認它存在。

大家注意 ls 輸出的第二列，那是第五章用 Compose 起的時候自動建的 Volume。Compose 會幫 Volume 加上「專案名稱_」的前綴，專案名稱預設就是資料夾名稱。這解釋了一個很多人困惑的現象：明明 compose.yaml 裡寫 db-data，docker volume ls 卻看到 taskboard_db-data。也因為這個前綴，不同專案的同名 Volume 不會互相打架。

重點在 inspect 這個指令，它會告訴我們這個 Volume 在 host 上實際的路徑，也就是 Mountpoint 這個欄位。平常我們不太需要直接去操作這個路徑，但 debug 的時候會很有用。

⚠️ 預期結果：如果 inspect 出來的 Mountpoint 路徑我們去 host 上直接看，會發現真的有一個對應的資料夾，證明 Volume 底層其實還是存在 host 檔案系統上，只是由 Docker 幫我們統一管理，我們平常不需要手動碰它。
-->

---
layout: default
---

# 掛載 Volume 到容器

```bash
docker run -d --name taskboard-db \
  --mount source=taskboard-db-data,target=/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=taskboard mysql:8.4

docker run -d --name taskboard-db \
  -v taskboard-db-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=taskboard mysql:8.4
```

兩個指令效果完全一樣，只是語法不同。掛載之後，MySQL 寫進 `/var/lib/mysql` 的所有資料檔，都實際落在 `taskboard-db-data` 這個 Volume 裡。

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>注意：</b> 若掛載的是「空」Volume，image 裡該路徑原本的檔案會自動複製進去（MySQL 會在此時跑初始化建立 <code>taskboard</code> 資料庫）；若 Volume 裡已經有資料，直接沿用既有資料，<b>初始化腳本與 <code>MYSQL_*</code> 環境變數都不會再執行</b>。
</div>

<!--
這頁示範怎麼把 Volume 掛進 MySQL 容器，用 --mount 跟 -v 各示範一次，兩種語法等價。

⚠️ 下面那個提示框是這一章最多人踩的坑，我要花點時間講。

第一次啟動時 Volume 是空的，MySQL 的 entrypoint 腳本發現資料目錄空空如也，就會跑初始化：建 taskboard 資料庫、建 appuser 帳號、執行 /docker-entrypoint-initdb.d 底下的 SQL。

但第二次之後，Volume 裡已經有資料了，腳本一看「資料目錄有東西」就直接啟動 MySQL，完全跳過初始化。所以如果你後來改了 MYSQL_PASSWORD、或是改了 init.sql 想加一張表，重啟容器你會發現完全沒生效，然後開始懷疑人生。

解法有兩個：要嘛用 SQL 手動改，要嘛 docker volume rm 把 Volume 砍掉重來（開發環境常這樣做）。知道這個機制，就不會浪費一小時在那邊 debug。
-->

---
layout: default
---

# 使用 Volume 的注意事項

「刪除容器不會自動刪除它掛載的 Volume」——這是設計上的保護機制，避免我們不小心把重要資料清掉。

- 匿名 Volume（沒有指定名稱）搭配 `docker run --rm`，容器結束時會一併被刪除
- 掛載到「非空」的 Volume 或目錄，既有內容會被優先保留，容器 image 內同路徑的檔案會被遮蔽
- 想清除所有沒被使用的 Volume，用 `docker volume prune`，這個動作無法復原

<!--
這頁整理三個大家最容易忽略、也最容易出包的注意事項。

第一個是好消息：`docker rm` 不會自動把 Volume 也刪掉，這是刻意設計的保護機制。

第二個是匿名 Volume 的例外狀況：如果我們建立容器時沒有指定 Volume 名稱，Docker 會自動生成一個亂數名稱的匿名 Volume，這種 Volume 如果搭配 `--rm` 參數，容器結束時會被一起清掉，這點跟具名 Volume 不一樣，要特別留意。

⚠️ 第三點是最容易誤觸的地雷：`docker volume prune` 這個指令會把所有「目前沒有容器在用」的 Volume 全部刪光，而且沒有辦法復原，執行前最好先用 `docker volume ls` 確認一下，不要手滑。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Part 3
## 資料備份與還原情境

<!--
第三部分是這一章的重頭戲，我們要學怎麼把 Volume 裡的資料打包備份、還有怎麼把備份還原回去，這在維運工作裡是非常實用的技巧。
-->

---
layout: default
---

# 為什麼需要備份 Volume？

雖然 Volume 的資料不會隨容器刪除而消失，但如果 host 本身出問題（硬碟壞掉、要換機器、要搬到雲端），Volume 裡的資料還是會不見。

「備份 Volume 最經典的做法，是借用一個『臨時容器』，把 Volume 掛進去，再用 `tar` 打包成一個檔案，存到 host 的某個路徑。」

這個臨時容器不需要跑任何服務，它唯一的任務就是幫我們搬資料，做完就可以丟掉，所以我們通常會搭配 `--rm` 參數讓它用完即焚。

<!--
大家可能會想：Volume 不是已經很安全了嗎？為什麼還要備份？

沒錯，Volume 讓資料不會因為容器被刪除而消失，但它終究還是存在同一台 host 上。如果 host 本身硬碟壞了、要換新機器、要搬去雲端，Volume 資料一樣會不見。這就是為什麼我們還是需要「備份」這個動作，把資料額外複製出來一份。

這裡介紹的技巧很經典：借一個臨時容器，把 Volume 掛進去，用 tar 指令打包，再把打包好的檔案掛到 host 的另一個路徑存起來。做完之後這個臨時容器就可以丟掉了，所以通常會加 --rm。

⚠️ 這個技巧的精髓在於：我們不是直接操作 Volume 底層路徑，而是「透過容器」去讀寫 Volume，這樣不管 Volume 實際存在哪裡，操作方式都一致。
-->

---
layout: default
---

# 備份 Volume 的步驟

| 步驟 | 說明 |
| --- | --- |
| 1 | 建立一個掛載了目標 Volume 的臨時容器（也可用既有的服務容器） |
| 2 | 啟動另一個容器，透過 `--volumes-from` 借用第一個容器的 Volume |
| 3 | 同時把 host 的目前目錄掛到這個容器的 `/backup` |
| 4 | 在容器內執行 `tar cvf`，把 Volume 內容打包進 `/backup` |
| 5 | 打包完成後，備份檔就直接留在 host 上，容器可以刪除 |

<!--
這五個步驟是備份的標準流程，我們接下來這頁就會看到對應的實際指令。

核心觀念是 `--volumes-from`，它可以讓一個容器直接「借用」另一個容器已經掛載的 Volume，不用重新指定一次。

⚠️ 這五個步驟看起來多，但其實核心就兩個指令，等一下的範例會讓大家看得更清楚。
-->

---
layout: default
---

# 備份 Volume — 範例

```bash
# 做法 A：借用執行中的 taskboard-db 容器，把它的 Volume 打包
docker run --rm --volumes-from taskboard-db -v $(pwd):/backup \
  alpine tar cvf /backup/db-backup.tar /var/lib/mysql

# 做法 B（資料庫建議）：用 mysqldump 匯出邏輯備份
docker exec taskboard-db mysqldump -uroot -prootpw taskboard > taskboard.sql
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>做法 A 的前提：</b> 直接打包 MySQL 資料檔屬於「實體備份」，容器<b>執行中</b>打包可能抓到寫到一半的檔案。正式作業要先 <code>docker stop taskboard-db</code> 再打包，或改用做法 B。
</div>

<!--
這頁講備份，我給了兩個做法，實務上要分清楚什麼時候用哪個。

做法 A 是 Docker 通用的 Volume 備份技巧：啟動一個臨時的 alpine 容器，用 --volumes-from 借用 taskboard-db 已經掛好的 Volume，同時把 host 目前目錄掛到 /backup，然後在容器內跑 tar 打包。打包出來的檔案透過掛載直接落在我們的電腦上。加了 --rm，臨時容器用完自動消失。

這招的價值在於「通用」——不管 Volume 裡裝的是 MySQL、上傳的檔案還是什麼，都能這樣備份。

但對資料庫來說，做法 B 才是標準答案。mysqldump 匯出的是 SQL 語句，好處是：檔案小、可讀、可以跨版本還原（MySQL 8.4 匯出的可以進 8.0），而且不用停機。做法 A 匯出的是實體資料檔，換個 MySQL 版本可能就讀不起來，而且執行中打包有一致性風險——就像有人正在寫字的時候拍照，可能拍到寫一半的筆劃。

⚠️ 提醒大家看那個警示框。實務上 Volume tar 備份適合拿來搬遷整台機器（先停服務再打包），日常定期備份資料庫則用 mysqldump。
-->

---
layout: default
---

# 還原 Volume — 範例

```bash
# 對應做法 A：把 tar 解壓回一個全新的 Volume
docker run --rm -v taskboard-db-restore:/var/lib/mysql -v $(pwd):/backup \
  alpine sh -c "cd /var/lib/mysql && tar xvf /backup/db-backup.tar --strip 3"

# 用還原出來的 Volume 啟動新容器驗證
docker run -d --name taskboard-db-check \
  -v taskboard-db-restore:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=rootpw mysql:8.4

# 對應做法 B：把 SQL 灌回資料庫
docker exec -i taskboard-db mysql -uroot -prootpw taskboard < taskboard.sql
```

<!--
還原跟備份是鏡像對稱的：一樣借用臨時容器，差別只在這次是解壓縮而不是打包。

比較需要注意的是 --strip 這個參數。我們打包的時候路徑是 /var/lib/mysql，tar 檔裡面就會包著 var/lib/mysql 這三層目錄。解壓縮如果不處理，就會變成 /var/lib/mysql/var/lib/mysql，資料庫當然找不到檔案。--strip 3 的意思是把最外面三層路徑去掉，讓內容直接落在目標目錄下。

⚠️ 易錯點：strip 的數字要跟打包時的路徑深度對應。打包 /var/lib/mysql 就 strip 3，打包 /dbdata 就 strip 1。數字錯了不會報錯，但還原出來的目錄結構對不上，容器啟動會失敗。

做法 B 的還原就簡單多了，就是把 SQL 檔灌回去。注意那個 `docker exec -i`，一定要有 -i 才能把 host 的檔案內容透過標準輸入送進容器裡，少了 -i 這行不會work。

我建議大家還原之後一定要「用新 Volume 啟一個容器驗證」，中間那段就是在做這件事。沒驗證過的備份等於沒有備份——這是維運界的血淚共識。
-->

---
layout: default
---

# 補充：在 Compose 中宣告 Volume

```yaml
services:
  db:
    image: mysql:8.4
    volumes:
      - db-data:/var/lib/mysql                      # Volume：資料持久化
      - ./db/init.sql:/docker-entrypoint-initdb.d/init.sql:ro   # Bind：初始化腳本
    environment:
      MYSQL_ROOT_PASSWORD: rootpw
      MYSQL_DATABASE: taskboard

  api:
    build: ./taskboard-api
    volumes:
      - ./logs:/app/logs                            # Bind：log 撈到本機看
    tmpfs:
      - /tmp                                        # tmpfs：上傳暫存檔

volumes:
  db-data:
```

三種掛載方式在同一份檔案裡各司其職。別忘了在最底下的 `volumes:` 區塊宣告具名 Volume。

<!--
這頁把三種掛載方式在 TaskBoard 的實際位置一次呈現，大家可以當成範本直接抄。

db 有兩個掛載：Volume 掛資料目錄負責持久化，Bind Mount 掛 init.sql 負責第一次的建表，而且加了 :ro 唯讀，容器不可能改到我們專案裡的檔案。

api 的 ./logs 是把容器裡的 log 目錄接到本機，這樣用本機編輯器就能看 log，不用一直 docker logs。tmpfs 掛 /tmp 給檔案上傳的暫存檔用。

⚠️ 最容易忘記的還是最底下的 volumes 區塊。只有具名 Volume 需要宣告，Bind Mount（以 ./ 或 / 開頭的路徑）不用。
-->

<!--
這頁補充一下在 Compose 裡怎麼宣告跟使用 Volume，這是實務上最常見的使用方式，因為我們很少會單獨用 docker run 去長期跑一個資料庫服務。

範例裡我們讓 MySQL 服務把資料存到 db-data 這個具名 Volume，重點是檔案最底下要用 volumes 區塊把 db-data 宣告出來，Compose 才知道這是一個要建立管理的 Volume，而不是打錯字的路徑。

⚠️ 容易忘記的地方：如果忘記在最底下宣告 volumes 區塊，Compose 執行時會直接報錯，找不到這個 Volume 的定義，這是新手很容易漏掉的一步。
-->

---
layout: default
---

# 練習 1：讓 TaskBoard 的資料活下來
### 任務說明

正面回答第三章留下的問題。請完成：

1. 建立名為 `taskboard-db-data` 的 Volume
2. 啟動 `taskboard-db`（`mysql:8.4`），把 Volume 掛到 `/var/lib/mysql`
3. 進容器建一張 `task` 表並塞兩筆任務資料
4. `docker volume inspect` 看這個 Volume 在 host 上的實際路徑
5. **強制刪除容器**，再用 `docker volume ls` 確認 Volume 還在
6. 用**同一個 Volume** 啟動一個全新的容器，進去 `select * from task;` — 資料還在嗎？

<!--
第一題是暖身，但它要親手推翻大家第三章的認知。

第三章練習 2 我們做過一模一樣的事：建表、塞資料、然後我說「刪掉容器資料就沒了」。這次唯一的差別只有多掛了一個 Volume，結果就完全不同。

第 6 步請大家一定要親眼看到那兩筆資料重新出現在新容器裡。同樣的 rm、同樣的 run，差別只在那一行 -v，這個對比做過一次，volume 的價值就永遠忘不掉了。

引導思考：為什麼容器刪掉了，Volume 卻還在？因為它們的生命週期本來就是分開管理的。
-->

---
layout: default
---

# 練習 1：解題提示

```bash
docker volume create taskboard-db-data
docker run -d --name taskboard-db -v taskboard-db-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=taskboard mysql:8.4

# 等 MySQL ready 後建表塞資料
docker exec taskboard-db mysql -uroot -prootpw taskboard -e \
  "CREATE TABLE task(id BIGINT PRIMARY KEY AUTO_INCREMENT, title VARCHAR(100));
   INSERT INTO task(title) VALUES ('學會 Volume'),('備份資料庫');"

docker volume inspect taskboard-db-data
docker rm -f taskboard-db          # 容器沒了
docker volume ls                   # Volume 還在

# 用同一個 Volume 起新容器
docker run -d --name taskboard-db-2 -v taskboard-db-data:/var/lib/mysql \
  -e MYSQL_ROOT_PASSWORD=rootpw mysql:8.4
docker exec taskboard-db-2 mysql -uroot -prootpw taskboard -e "select * from task;"
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>兩筆資料完整出現</b> — 這就是第三章那個問題的答案。容器是隨時可拋棄的，資料不是。
</div>

<!--
⚠️ 提醒兩件事。第一，docker rm -f 是強制刪除執行中的容器，不加 -f 會失敗。第二，新容器我沒有再寫 MYSQL_DATABASE，因為 Volume 裡已經有資料，那些初始化變數本來就不會再生效——這正好呼應前面講過的機制。

預期結果：最後那行 select 印出「學會 Volume」跟「備份資料庫」兩筆。請保留這個 Volume，練習 2 要用。
-->

---
layout: default
---

# 練習 2：備份並還原 TaskBoard 資料庫
### 任務說明

情境：公司要把 TaskBoard 從你的開發機搬到測試伺服器。

1. 用 `mysqldump` 把 `taskboard` 資料庫匯出成 `taskboard.sql`（邏輯備份）
2. 另外用臨時容器 + `tar`，把 `taskboard-db-data` 打包成 `db-backup.tar`（實體備份）
3. 建立全新的 Volume `taskboard-db-restore`，把 tar 還原進去
4. 用還原後的 Volume 啟動新容器，`select * from task;` 確認資料完整
5. **想一想並回答**：兩種備份方式，哪一種檔案比較小？哪一種可以跨 MySQL 版本還原？正式環境的每日排程備份該用哪一種？

<!--
第二題把備份還原完整走一遍，情境是真實會遇到的「換機器」。

第 5 題是這題的靈魂，不做完等於白做。答案是：mysqldump 檔案小很多（只有 SQL 語句，沒有索引結構跟預留空間），而且可以跨版本、甚至跨到雲端的 RDS 都能還原；tar 是整包資料檔，換版本可能讀不起來。所以每日排程備份用 mysqldump，tar 適合整台機器搬遷時連同其他 Volume 一起打包。

引導思考：如果是搬到另一台實體主機，這個流程哪裡要調整？答案是中間要多一步 scp 或其他方式把備份檔傳過去，其餘完全一樣——這正是容器化的好處，兩邊環境保證相同。
-->

---
layout: default
---

# 練習 2：解題提示

```bash
# 1. 邏輯備份
docker exec taskboard-db-2 mysqldump -uroot -prootpw taskboard > taskboard.sql

# 2. 實體備份：借用執行中容器的 Volume
docker run --rm --volumes-from taskboard-db-2 -v $(pwd):/backup \
  alpine tar cvf /backup/db-backup.tar /var/lib/mysql

# 3. 還原到新 Volume（注意 --strip 3 對應 /var/lib/mysql 三層）
docker run --rm -v taskboard-db-restore:/var/lib/mysql -v $(pwd):/backup \
  alpine sh -c "cd /var/lib/mysql && tar xvf /backup/db-backup.tar --strip 3"

# 4. 用還原的 Volume 啟動並驗證
docker run -d --name taskboard-db-restored \
  -v taskboard-db-restore:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=rootpw mysql:8.4
docker exec taskboard-db-restored mysql -uroot -prootpw taskboard -e "select * from task;"
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>第 5 題答案：</b> <code>taskboard.sql</code> 通常只有幾 KB，<code>db-backup.tar</code> 動輒上百 MB（含 InnoDB 預留空間）。
mysqldump 可跨版本、跨主機還原，正式環境的每日排程一律用它；tar 適合整機搬遷。
</div>

<!--
⚠️ 兩個易錯點。第一是 --strip 的數字，打包 /var/lib/mysql 是三層所以 strip 3，如果數字錯了不會報錯，但容器啟動會失敗，log 會說找不到資料檔。第二是 tar 備份時 MySQL 還在跑，嚴格來說有一致性風險，正式作業要先 stop。

預期結果：最後那行 select 印出跟原本一樣的兩筆任務，證明資料完整搬過去了。做完記得清理：docker rm -f 那幾個測試容器，還有 docker volume rm 用不到的 Volume。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — Volume 資料持久化

<table class="summary-table">
<tr><th>重點</th><th>說明</th></tr>
<tr><td>Volume</td><td>由 Docker 管理，適合資料庫等需持久化的資料，如租來的「外部倉庫」</td></tr>
<tr><td>Bind Mount</td><td>直接掛載 host 既有路徑，適合開發時同步原始碼，如借用「自己家的書櫃」</td></tr>
<tr><td>tmpfs</td><td>存在記憶體中，容器一停止就消失，適合暫存資料，如「便利貼」</td></tr>
<tr><td>核心指令</td><td><code>docker volume create / ls / inspect / rm / prune</code></td></tr>
<tr><td>備份／還原</td><td>用「臨時容器 + tar」完成，不需直接碰觸 host 底層路徑</td></tr>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> 容器被刪除，沒有掛載 Volume 的資料就永久消失，重要資料一定要掛 Volume。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入部署實戰，把 image、容器、網路、Volume 全部串起來上線一個服務。
</div>

<!--
我們花一分鐘回顧一下這一章學到的東西。

三種儲存方式的定位要分清楚：Volume 給 Docker 管、Bind Mount 直接借用 host 路徑、tmpfs 存在記憶體裡説丟就丟。

指令的部分，create、ls、inspect、rm、prune 這五個是我們平常管理 Volume 會一直用到的。

最重要的實戰技巧是備份還原：不需要直接去 host 底層路徑操作，透過臨時容器搭配 --volumes-from 跟 tar，就能把資料乾淨地搬進搬出。

大家學完這一章，下次再遇到「容器刪掉資料就不見了」這種問題,應該就知道怎麼提前避開這個坑了。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對 Volume、Bind Mount、tmpfs 這三種儲存方式的差異，或是備份還原的做法，有沒有什麼疑問？都歡迎提出來討論。

建議回去動手把兩個練習題再做一次，操作過一遍會比單純看投影片印象深刻很多。
-->
