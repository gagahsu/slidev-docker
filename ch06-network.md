---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: 網路設定
routeAlias: ch06
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">網路設定</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「讓容器學會互相打招呼，也學會保護自己」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
歡迎來到第六章，網路設定。

上一章我們用 Compose，讓 API 直接寫 db 就連上了資料庫，但當時沒有解釋為什麼。而在第三章，我們還被迫寫了一個不太好看的 `host.docker.internal`。

這一章就要把背後的原理講清楚。容器之間要怎麼找到彼此？外部使用者又要怎麼連進來？學完之後，我們能讓 TaskBoard 只開一個對外的入口，後端和資料庫都安全地藏在內部網路裡。
-->

---
layout: default
---

# Outline

- **Network Driver 種類**（bridge / host / none）
- **Port Mapping 與容器間通訊**
- **自訂 Network 與 DNS 解析**
- **練習題** x2
- **總結**

<!--
這一章分成三部分。第一部分認識 Docker 的三種網路模式，bridge、host、none。第二部分學 port 映射，以及容器之間預設怎麼溝通。第三部分是重點，自訂網路和 DNS 解析，最後再用 nginx 反向代理解決前端的跨域問題。章節最後有兩題練習。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Network Driver 種類

<!--
我們先從最基礎的觀念開始，Network Driver。它決定了容器要用什麼規則，跟其他容器和外界溝通。
-->

---

# 什麼是 Docker Network？

多個 Container 各自運作於獨立沙盒，沒有網路設定時彼此互相看不到。TaskBoard 的 `taskboard-api` 要連 `taskboard-db`、前端要連後端，靠的全是 Docker Network。

Docker Network 負責建立 Container 之間的通訊管道：

> 「Docker's networking subsystem is pluggable, using drivers. Several drivers exist by default.」

Docker 提供多種 **Network Driver（網路驅動程式）**，各代表不同的通訊規則：

- `bridge`：門禁管制的私有網路
- `host`：與主機共用網路，無隔離
- `none`：完全隔離，無對外連線

<!--
直接想 TaskBoard 的三個容器，前端、後端、資料庫。如果什麼都不設定，它們其實各自待在獨立的沙盒裡，彼此看不見。第三章我們繞一大圈寫 `host.docker.internal`，就是因為當時沒有設定網路。

Docker Network 的工作，就是建立容器之間的通訊管道。Docker 提供了幾種 Network Driver，各代表不同的通訊規則。

這一章我們用社區來比喻。bridge 就像有門禁管制的社區，住戶之間可以往來，外人要經過大門。host 則是完全不設圍牆，直接跟主機共用同一條馬路。none 是與世隔絕的孤島，誰都連不到。

記住這個比喻，下一頁看比較表會更好理解。
-->

---

# Network Driver 種類比較

| Driver | 說明 | 適用情境 |
| --- | --- | --- |
| `bridge` | 預設驅動程式，建立一個獨立的私有網路 | 同主機上多個 Container 需要互相溝通 |
| `host` | 移除 Container 與主機之間的網路隔離 | 需要極致效能，且不介意共用主機網路 |
| `none` | 完全隔離 Container 的網路 | 不需要任何網路連線的批次任務 |

```bash
# 三種模式的基本語法
docker run --network bridge taskboard-api:1.0.0   # 預設，TaskBoard 用這個
docker run --network host taskboard-api:1.0.0     # 直接佔用主機 8080
docker run --network none taskboard-api:1.0.0     # 連不到 DB，起不來
```

<!--
這張表是第一部分的核心，我們挑適用情境來看。

bridge 是預設的驅動程式。我們沒有特別指定的時候，容器就掛在預設的 bridge 網路上。同一台主機上的多個容器要互相溝通，用的就是它。

host 會移除容器和主機之間的網路隔離，容器直接借用主機的網路，效能最好，但少了隔離的保護。

none 則是完全隔離，容器連對外連線的能力都沒有，通常用在不需要網路的批次運算。

下面是三種模式的語法，都是用 `--network` 指定。TaskBoard 全程使用 bridge。要注意 host 模式在 Windows 和 Mac 的 Docker Desktop 上有限制，行為跟 Linux 不一樣。
-->

---

# Network Driver — 範例

```bash
# bridge：預設模式，Container 會拿到獨立的私有 IP
docker run -d --name taskboard-db mysql:8.4
docker inspect -f '{{.NetworkSettings.IPAddress}}' taskboard-db
# 172.17.0.2

# host：不再有獨立 IP，Spring Boot 的 8080 直接等於主機的 8080
docker run -d --network host --name taskboard-api taskboard-api:1.0.0
# 不用 -p，但如果本機 IDE 也在跑 8080，就直接衝突

# none：完全沒有網路介面
docker run --rm --network none alpine ip addr
# 只會看到 loopback 介面 lo
```

<!--
我們實際跑一次，看看三種模式的差異。

第一段用 bridge 模式跑 MySQL，它會拿到一個像 172.17.0.2 這樣的私有 IP。這個 IP 只在 Docker 建立的網路裡看得到，主機上的瀏覽器或資料庫工具連不到，這也是為什麼需要 `-p`。

第二段用 host 模式跑 Spring Boot，容器裡的 8080 就直接等於主機的 8080，不需要 `-p`。但代價是沒有隔離，很多人 IDE 裡本來就開著一個 8080 的服務，兩個就會直接衝突。

第三段用 none 模式，進去看網路介面，只剩下 loopback。如果 taskboard-api 掛在 none 上，它連資料庫都找不到，啟動就會失敗。

結論是三種模式的行為完全不同，絕大多數情況，用 bridge 就對了。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Port Mapping 與容器間通訊

<!--
搞懂三種模式之後，接下來解決兩個更實際的問題：外部使用者要怎麼連進容器？容器之間預設能不能直接溝通？
-->

---

# 什麼是 Port Mapping？

Container 內監聽的 port（例如 80）屬於自己的網路空間，主機外部無法直接連入。

**Port Mapping（port 映射）** 將主機的 port 轉接到 Container 內部的 port：

> 「Use the `--publish` or `-p` flag to make a port available outside the host, and to containers in other bridge networks.」

`-p` 讓外部透過主機的指定 port，連進 Container 內部服務。

<!--
先建立一個直覺。容器預設是關起門來的。

就算 nginx 已經在容器裡監聽 80 port，我們在主機上打開瀏覽器連 localhost，還是連不到。因為那個 80 port 屬於容器自己的網路空間，跟主機的 80 port 是兩個完全不同的地方。

「Port Mapping 將主機的 port 轉接到 Container 內部的 port」，用的就是 `-p` 參數。

用社區來比喻，-p 就像在社區大門裝一支對講機，外面的人按主機的門號，就會轉接到社區裡指定的那一戶。

這是部署服務時幾乎每次都會用到的參數，前面幾章我們也已經用過很多次了。
-->

---

# Port Mapping 的語法結構

| 語法 | 說明 |
| --- | --- |
| `-p 8080:80` | 主機 port:Container port，所有網路介面都可連 |
| `-p 127.0.0.1:8080:80` | 只綁定主機的 127.0.0.1，限制存取來源 |
| `-P` / `--publish-all` | 隨機映射 Dockerfile 中 EXPOSE 的所有 port |
| `docker port <container>` | 查詢目前 Container 的 port 映射狀況 |

<!--
這張表是 port 映射的幾種寫法。

第一列是最常用的格式，主機 port 在左，容器 port 在右。這個順序很容易搞混，寫反了瀏覽器就連不到。

第二列在前面多加了 127.0.0.1，代表只綁定本機，限制只有自己的電腦能連，等一下的範例會說明為什麼重要。

第三列是大寫的 `-P`，Docker 會讀取 Dockerfile 裡 EXPOSE 的 port，自動挑一個主機上沒被佔用的 port 映射過去。

最後的 `docker port`，可以查詢容器目前實際的映射狀況。
-->

---

# Port Mapping — 範例

```bash
# 前端：主機 8080 對應容器 80，同事也能用你的 IP 連進來看
docker run -d -p 8080:80 --name taskboard-web taskboard-web:1.0.0

# 資料庫：只允許本機連線，外部連不進來（開發機的正確做法）
docker run -d -p 127.0.0.1:3307:3306 --name taskboard-db mysql:8.4

# 讓 Docker 自動挑一個沒被佔用的主機 port（會用 Dockerfile 裡的 EXPOSE 8080）
docker run -d -P --name taskboard-api taskboard-api:1.0.0

# 查詢實際映射到哪個 port
docker port taskboard-api
# 8080/tcp -> 0.0.0.0:32768
```

<!--
這一頁看實際的寫法。

第一段是最常用的，前端的主機 8080 對應容器的 80。這樣寫，同一個網路下的同事也能用我們的 IP 連進來看。

第二段是特別推薦的做法。前面我們都寫 3307 對 3306，其實會讓同一個 Wi-Fi 底下的任何人都能連到我們的 MySQL，而且密碼還很簡單。在前面加上 127.0.0.1，就只有自己的電腦連得到，資料庫工具一樣能用，外面的人連不進來。

第三段的大寫 `-P`，適合同時跑好幾個測試環境、不想自己分配 port 的時候。因為 port 是隨機的，要用最後一行的 `docker port` 查詢，才知道實際是哪一個。

第一段跑完，打開瀏覽器連 localhost 的 8080，就能看到 TaskBoard 的畫面。
-->

---

# 容器間通訊的注意事項

**預設的 bridge network** 上，Container 之間可透過 IP 互相連線，但官方文件指出限制：

> 「Containers on the default bridge network can only access each other by IP addresses, unless you use the `--link` option.」

預設情況下 Container **無法用名稱互相找到對方**，只能用 IP，且 IP 在重啟後可能改變。

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>版本注意：</b> 早期 Docker 提供 <code>--link</code> 參數讓 Container 之間可以用名稱溝通，但這個做法已經<b>不建議使用（legacy）</b>。現行的正確做法是改用「自訂 bridge network」，容器名稱會自動被 DNS 解析，完全不需要 --link。這也是我們下一部分要學的重點。
</div>

<!--
這一頁是一個重要的轉折。

剛才解決了外部怎麼連進來，那容器之間呢？如果什麼都不做，容器都掛在預設的 bridge 網路上。官方文件說得很清楚，「預設 bridge 網路上的容器，只能用 IP 位址互相存取」。

只能用 IP 有兩個問題。第一，IP 很難記。第二，容器重啟之後，IP 可能會改變，寫死在設定裡的位址就失效了。

下面的版本注意要特別留意。以前很多教學會用 `--link` 參數，讓容器可以用名稱互連。但這個做法已經過時，官方不建議再使用。現在正確的做法是建立自訂網路，這就是接下來第三部分的重點。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 自訂 Network 與 DNS 解析

<!--
我們剛才留了一個問題：容器之間要怎麼用名字溝通，而不是死記 IP？答案就是自訂 Network，這是這一章最重要的觀念。
-->

---

# 什麼是自訂 Network？

預設 bridge network 沒有自動 DNS 解析，Container 只能用 IP 互相找，且 IP 在重啟後可能改變。

**自訂 Network（User-defined Network）** 是自行建立的獨立網路，具備自動 DNS 解析：

> 「On a user-defined bridge network, containers can resolve each other by name or alias.」

Container 加入自訂網路後，Docker 會啟動內建 **DNS Server（位址 127.0.0.11）**，自動將容器名稱解析成對應 IP。

<!--
預設 bridge 網路沒有自動 DNS 解析，容器只能用 IP 互相找。

「在自訂的 bridge 網路上，容器可以用名稱互相解析。」容器加入自訂網路後，Docker 會啟動一個內建的 DNS 伺服器，位址是 127.0.0.11，專門把容器名稱翻譯成 IP。

延續社區的比喻，預設網路就像社區沒有住戶名冊，要找人只能記門牌號碼。自訂網路則是社區管理室有一本名冊，我們報出住戶名字，管理室就幫我們接通，不用管對方住幾號。

拉回實務，只要是多個容器需要合作的專案，例如 API 要連資料庫，幾乎一定會用自訂網路，這是標準做法。
-->

---

# 自訂 Network 的語法結構

| 指令 | 說明 |
| --- | --- |
| `docker network create <name>` | 建立一個新的自訂 bridge 網路 |
| `docker network create -d bridge <name>` | 明確指定使用 bridge 驅動 |
| `docker run --network <name> ...` | 啟動 Container 時直接加入指定網路 |
| `docker network connect <name> <container>` | 讓已存在的 Container 加入網路 |
| `docker network ls` | 列出目前所有網路 |
| `docker network rm <name>` | 刪除自訂網路 |

<!--
這張表是自訂網路的相關指令。

最常用的是前三個。`docker network create` 建立網路，預設就是 bridge 驅動，所以第二列的 `-d bridge` 寫不寫都一樣。`docker run` 時用 `--network` 讓容器直接加入。

如果容器已經在跑，可以用 `docker network connect` 把它加進網路，不用重建。

另外 `ls` 列出所有網路，`rm` 刪除網路，用法跟之前學的指令一樣。
-->

---

# 自訂 Network — 範例

```bash
# 1. 建立 TaskBoard 專用網路
docker network create taskboard-net

# 2. 資料庫加入網路，不對外開 port
docker run -d --network taskboard-net --name taskboard-db \
  -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=taskboard \
  -e MYSQL_USER=appuser -e MYSQL_PASSWORD=apppw mysql:8.4

# 3. 後端加入同一網路，連線字串終於可以寫服務名稱了
docker run -d --network taskboard-net -p 8081:8080 --name taskboard-api \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://taskboard-db:3306/taskboard \
  -e SPRING_DATASOURCE_USERNAME=appuser \
  -e SPRING_DATASOURCE_PASSWORD=apppw \
  taskboard-api:1.0.0

# 4. 驗證 DNS 解析
docker exec taskboard-api ping -c 2 taskboard-db
# PING taskboard-db (172.18.0.2): 56 data bytes
# 64 bytes from 172.18.0.2: seq=0 ttl=64 time=0.085 ms
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>對照第三章：</b> 當時被迫寫 <code>host.docker.internal:3307</code>（繞出容器再繞回來），現在直接寫 <code>taskboard-db:3306</code> — 容器內走的是內部網路，用的是 MySQL 原本的 3306，不是主機映射的 3307。
</div>

<!--
這一頁是整章最重要的一頁，我們終於把第三章那個寫法修好了。

第一步建立 taskboard-net，就像新建了一個有住戶名冊的社區。

第二步，資料庫加入網路，而且注意這次完全沒有 `-p`。API 是從網路內部連過來的，不需要經過主機。資料庫不對外開放，這是正式環境的標準做法。

第三步是重點。連線字串從 `host.docker.internal:3307` 變成 `taskboard-db:3306`，主機名稱和 port 都改了。

這個 port 的變化，是最多人卡住的地方。3307 是 `-p` 映射給主機看的 port。現在 API 從內部網路直接找資料庫，這條路上根本沒有經過 `-p`，所以要用 MySQL 在容器裡真正監聽的 3306。簡單記法是，容器對容器，一律用容器內的原始 port。

第四步用 ping 驗證，看到回應，就代表內建 DNS 成功把名字翻譯成 IP 了。
-->

---

# 使用自訂 Network 的注意事項

| 項目 | 說明 |
| --- | --- |
| ⚠️ 版本注意 | 舊式的 `--link` 容器連結參數已經不建議使用（deprecated），現行做法一律改用自訂 bridge network，DNS 會自動解析容器名稱 |
| 隔離性 | 只有加入同一個自訂網路的 Container 才能互相通訊，不同網路之間預設是隔離的，比預設 bridge 網路「大家都能互連」更安全 |
| 與 Docker Compose 的關係 | 第五章的 `compose.yaml` 之所以能直接寫 `jdbc:mysql://db:3306/...`，就是因為 Compose 自動幫我們建了一個自訂網路，服務名稱天生就能互相解析 |

<!--
這一頁整理三個重點。

第一，`--link` 已經過時了，現在的標準做法就是自訂 bridge 網路。網路上還在教 `--link` 的，多半是比較舊的資料。

第二，隔離性。只有加入同一個自訂網路的容器，才能互相溝通。不相關的服務不會意外連上彼此，比預設網路更安全。反過來說，兩個容器掛在不同網路，一樣找不到對方。

第三，回頭解答上一章的謎。Compose 裡直接寫 db 就能連上，是因為 Compose 自動幫我們建了一個自訂網路，再把所有服務加進去。所以 Compose 不是魔法，只是把今天手動打的這些指令包起來了。
-->

---
layout: default
---

# 實戰：nginx 反向代理 /api

前端 Angular 打 `http://localhost:8081/api/tasks` 會遇到 **CORS 跨域**問題。實務解法：讓 nginx 把 `/api` 轉發給後端，瀏覽器眼中只有一個來源。

```nginx
# taskboard-web/nginx.conf
server {
  listen 80;

  location / {                          # Angular 路由 fallback
    root /usr/share/nginx/html;
    try_files $uri $uri/ /index.html;
  }

  location /api/ {                      # 轉發給後端容器
    proxy_pass http://taskboard-api:8080/api/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }
}
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>成果：</b> Angular 的 <code>environment.apiUrl</code> 直接寫 <code>/api</code>（相對路徑）即可 — 開發、測試、正式環境完全不用改前端程式碼。
</div>

<!--
這一頁把今天學的 DNS 解析，用在一個真實的痛點上。做過 Angular 專案的同學，應該都遇過 CORS 跨域問題。

前端在 8080，後端在 8081，瀏覽器認為這是兩個不同的來源，請求會被擋下來。

比較好的做法是反向代理。先看第二個 location。瀏覽器呼叫 `/api/tasks`，nginx 收到之後，在容器網路內部轉發給 `taskboard-api:8080`。這個主機名稱，就是剛才學的容器名稱解析。從瀏覽器的角度，它從頭到尾只跟一個網站說話，不會跨域。

再看第一個 location 的 try_files。Angular 的路由都在前端，使用者在某個頁面重新整理，nginx 會去找一個不存在的檔案，回傳 404。try_files 的意思是找不到就回 index.html，讓 Angular 自己處理路由。

結果是 Angular 的 API 位址直接寫相對路徑 `/api`，各個環境都不用改前端程式。

【講師】可補充 proxy_pass 結尾有沒有寫路徑，轉發出去的網址會不同，要跟後端 Controller 的路徑對得上。
-->

---
layout: default
---

# 練習 1：讓 API 用名稱連上資料庫
### 任務說明

把第三章那個 `host.docker.internal` 的醜寫法徹底修掉。

**目標：**

1. 建立一個名為 `taskboard-net` 的自訂網路
2. 啟動 `taskboard-db`（`mysql:8.4`）加入這個網路，**不要加 `-p`**
3. 啟動 `taskboard-api` 加入同一個網路，`-p 8081:8080`，連線字串改用服務名稱
4. 用 `docker exec` 驗證 API 容器能 ping 通 `taskboard-db`
5. 看 `docker logs taskboard-api`，確認 Spring Boot 成功啟動、沒有 `Communications link failure`

<!--
接下來是練習一，把第三章那個 `host.docker.internal` 的寫法徹底修掉。

任務是建立 taskboard-net，讓資料庫和 API 都加入這個網路。資料庫不要加 `-p`，API 的連線字串改用容器名稱。最後用 ping 和 log 驗證。

請大家想一個問題：資料庫沒有對外開放任何 port，API 還連得到它嗎？為什麼？

另外要注意，第五步才是真正的驗收。ping 得通只代表網路通了，Spring Boot 真的連上資料庫並啟動完成，才算過關。

我們先暫停一下，自己動手試試看。

【講師】給大家五到八分鐘，卡住的同學可以先看下一頁提示。
-->

---
layout: default
---

# 練習 1：解題提示
### 提示說明

```bash
docker network create taskboard-net

docker run -d --network taskboard-net --name taskboard-db \
  -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=taskboard \
  -e MYSQL_USER=appuser -e MYSQL_PASSWORD=apppw mysql:8.4

docker run -d --network taskboard-net -p 8081:8080 --name taskboard-api \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://taskboard-db:3306/taskboard \
  -e SPRING_DATASOURCE_USERNAME=appuser -e SPRING_DATASOURCE_PASSWORD=apppw \
  taskboard-api:1.0.0

docker exec taskboard-api ping -c 2 taskboard-db
docker logs taskboard-api | tail -20
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>兩個必踩的坑：</b> (1) 連線字串 port 要寫 <b>3306</b> 不是 3307 — 容器對容器不經過 <code>-p</code> 映射。
(2) 兩個容器都要加 <code>--network taskboard-net</code>，漏一個就掉回預設網路，用 <code>docker network inspect taskboard-net</code> 可以查誰在裡面。
</div>

<!--
我們來看解答。

回答剛才的問題，連得到。API 和資料庫在同一個自訂網路裡，是在內部直接溝通，不需要經過主機，所以資料庫不用開放任何 port。

下面的警示框有兩個很常見的坑。第一是 port。大家已經很習慣 3307，很容易反射性寫上去，結果一直連不到，因為資料庫容器裡根本沒有程式在聽 3307。

第二是忘了加 `--network`。少加一個，那個容器就會掉回預設網路，名稱解析不到，錯誤訊息會是 UnknownHostException。用 `docker network inspect` 可以查看哪些容器真的在網路裡。
-->

---
layout: default
---

# 練習 2：完整三層網路 + 反向代理
### 任務說明

**目標：** 前端對外、後端與資料庫全部藏在內部網路。

1. 沿用 `taskboard-net`，啟動 `taskboard-db`（不對外）與 `taskboard-api`（**這次也不要加 `-p`**）
2. 幫 `taskboard-web` 寫一份 `nginx.conf`，把 `/api/` 反向代理到 `http://taskboard-api:8080/api/`，並加上 SPA 的 `try_files` fallback
3. 重新 build `taskboard-web:1.0.0`，啟動時只開放 `-p 8080:80`
4. 驗證：
   - 瀏覽器打開 `http://localhost:8080` 看得到前端，新增任務會成功寫進資料庫
   - `curl http://localhost:8081/actuator/health` **應該連不上**（API 沒對外）
   - `docker exec taskboard-web ping -c 2 taskboard-api` 應該通
5. 想一想：整套只曝露一個 port，這對正式環境的資安有什麼好處？

<!--
練習二是本章的整合題，目標是前端對外，後端和資料庫全部藏在內部網路。

這次 API 也不加 `-p`。要幫前端寫一份 nginx.conf，把 `/api/` 轉發給後端，並加上 try_files。重新 build 前端之後，整套只開放 8080 一個 port。

驗證有三項，其中第二項特別重要。請大家親自確認，直接連 8081 的 API 是連不上的。

第五題請大家想一想：整套只開放一個 port，對正式環境的資安有什麼好處？

我們先暫停一下，自己動手試試看。

【講師】給大家十到十五分鐘，第五題可以開放小組討論。
-->

---
layout: default
---

# 練習 2：解題提示
### 提示說明

```bash
docker run -d --network taskboard-net --name taskboard-db \
  -e MYSQL_ROOT_PASSWORD=rootpw -e MYSQL_DATABASE=taskboard \
  -e MYSQL_USER=appuser -e MYSQL_PASSWORD=apppw mysql:8.4

docker run -d --network taskboard-net --name taskboard-api \
  -e SPRING_DATASOURCE_URL=jdbc:mysql://taskboard-db:3306/taskboard \
  -e SPRING_DATASOURCE_USERNAME=appuser -e SPRING_DATASOURCE_PASSWORD=apppw \
  taskboard-api:1.0.0        # 注意：沒有 -p

docker run -d --network taskboard-net -p 8080:80 --name taskboard-web \
  taskboard-web:1.0.0        # 整套只有這一個對外 port
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>除錯順序：</b> 前端按下去沒反應時 → 先 <code>docker logs taskboard-web</code> 看 nginx 有沒有收到 <code>/api/</code> 請求 → 再 <code>docker logs taskboard-api</code> 看後端有沒有收到轉發。從外往內一層一層看。
</div>

<!--
我們來看解答。重點在 taskboard-api 這次完全沒有 `-p`，它只服務同一個網路裡的 nginx，不需要對外開放。整套只有前端那一個對外的 port。

回答第五題。只開放一個 port，代表防火牆規則簡單，需要稽核的入口只有一個。攻擊者從外面連不到 API，也掃不到資料庫的弱密碼，少了一整個攻擊面。

如果順手幫資料庫加了 `-p`，功能不會壞，但等於把資料庫曝露在主機網路上，是不必要的風險。

下面的除錯順序請記起來。先看 nginx 的 log，有沒有收到 `/api/` 的請求，再看 API 的 log，有沒有收到轉發。從離使用者最近的那一層開始，往內一層一層查。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — 網路設定

<table class="summary-table">
<thead>
<tr><th>重點</th><th>說明</th></tr>
</thead>
<tbody>
<tr><td>bridge</td><td>預設模式，有隔離的私有網路</td></tr>
<tr><td>host</td><td>容器直接共用主機網路</td></tr>
<tr><td>none</td><td>完全沒有網路</td></tr>
<tr><td>Port Mapping</td><td><code>-p 主機port:容器port</code>，把容器內服務開放給主機外部連線</td></tr>
<tr><td>自訂 Network</td><td>提供內建 DNS，容器可用「名稱」互相通訊，取代已過時的 <code>--link</code></td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> 預設 bridge network 下容器只能用 IP 互連；自訂 Network 才有 DNS，可以直接用容器名稱互連。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入 Volume 資料持久化，學習怎麼讓資料活得比 Container 久。
</div>

<!--
我們回顧一下這一章。

第一，Docker 有三種基本的網路模式，bridge 是預設的私有網路，host 直接共用主機網路，none 完全沒有網路。第二，`-p` 把容器的服務開放給外部，主機 port 在左，容器 port 在右，加上 127.0.0.1 可以限制只有本機能連。第三，也是最重要的，預設網路只能用 IP 互連，自訂網路才有 DNS，可以直接用容器名稱溝通。第四，`--link` 已經過時，改用自訂網路。最後，用 nginx 反向代理，讓整套服務只需要一個對外入口。

下一章，我們要處理資料保存的問題，讓資料活得比容器更久。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
這一章我們讓 TaskBoard 的容器學會用名字互相溝通，也把後端和資料庫藏進了內部網路。

建議大家保留練習二做好的 taskboard-net 和三個容器，下一章處理資料持久化時會接著用。我們下一章見。

【講師】開放 Q&A，可以引導大家回想容器對容器為什麼用 3306、自訂網路和預設網路的差別。
-->
