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
大家好，歡迎來到第六章：網路設定。

前面幾章我們學會怎麼建立 Image、怎麼跑起 Container，但如果我們的應用需要好幾個 Container 一起合作，例如一個 web 服務要連到資料庫，這些 Container 要怎麼互相找到彼此？外部使用者又要怎麼連進我們的服務？

這就是這一章要解決的問題：Docker 的網路設定。學完這章，我們會知道 bridge、host、none 這幾種 Network Driver 有什麼差別，怎麼用 -p 把服務開放給外部連線，以及怎麼建立自訂網路讓 Container 之間可以直接用名稱互相溝通。
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
今天的內容分成三大塊。

第一部分，我們先搞懂 Docker 提供的幾種網路模式，bridge、host、none，各自適合什麼場景。

第二部分，我們會學怎麼用 -p 把 Container 裡的服務開放到外面，還有 Container 之間預設是怎麼通訊的。

第三部分是重點：自訂 Network。我們會看到自訂 Network 帶來的最大好處——DNS 自動解析，也就是 Container 之間可以直接用名字互相 ping 通，不用再記 IP。

最後會有兩題練習，讓大家實際動手操作一次。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Network Driver 種類

<!--
我們先從最基礎的觀念開始：Docker 的 Network Driver。

這決定了 Container 要用什麼方式跟外界溝通，就像社區的大門管制方式一樣，有的社區門禁森嚴，有的社區大門根本不設防。
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
大家可以直接想 TaskBoard：三個 Container，一個 Angular 前端、一個 Spring Boot 後端、一個 MySQL。如果什麼都不設定，這三個 Container 其實是互相看不見的，就像住在不同社區的人，彼此不認識。第三章我們被迫用 host.docker.internal 繞一大圈，就是因為當時什麼網路都沒設。

Docker Network 的工作，就是決定這些「社區」之間、以及社區跟外面馬路（主機、網際網路）之間，要用什麼規則來往。

這裡的類比很重要：bridge 就像一個有門禁管制的社區，host 是完全開放、跟主機共用同一條馬路，none 則是與世隔絕的孤島。記住這個類比，等一下看比較表會更好理解。
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
這張表是今天第一部分的核心。

bridge 是「預設驅動程式」，官方原文說得很直接：「The default network driver」。我們平常沒特別指定 --network 的時候，Container 就是掛在預設的 bridge 網路上。

host 模式是「移除 Container 與 Docker host 之間的網路隔離」，用大白話講就是 Container 直接借用主機的網路，不再有自己獨立的 IP，效能最好，但少了隔離的保護。

none 則是「完全把 Container 與主機和其他 Container 隔離」，這個 Container 連對外連線的能力都沒有，通常用在完全不需要網路的批次運算任務。

⚠️ 易錯點：host 模式在 Windows 和 Mac 上的 Docker Desktop 其實有限制，不像 Linux 上那麼直觀，等一下範例我們會用 Linux 環境的行為來說明。
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
我們實際跑一次看看差異。

第一段，用 bridge 模式（也就是不指定 --network 的預設狀況）跑 MySQL，它會拿到一個像 172.17.0.2 這樣的私有 IP，這個 IP 只有在 Docker 建立的橋接網路裡看得到。這也解釋了為什麼我們需要 -p：主機上的瀏覽器或 Workbench 是連不到 172.17 這個網段的。

第二段，用 host 模式跑 Spring Boot，這時候容器裡監聽的 8080 就直接等於主機的 8080，不需要 -p，沒有中間的 NAT 轉換，效能最好。但代價是沒有隔離——很多同學 IDE 裡本來就開著一個 8080 的 Spring Boot，這樣直接衝突。而且 ⚠️ host 模式在 Windows / Mac 的 Docker Desktop 上行為跟 Linux 不同，不建議大家在開發機上依賴它。

第三段，用 none 模式，進去看網路介面只剩 loopback，完全連不到外面。如果 taskboard-api 掛在 none 上，它連 DNS 都查不到，啟動時直接 Communications link failure。

預期結果：三種模式，網路行為完全不同。TaskBoard 全程用 bridge，這也是 99% 的情況該用的。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Port Mapping 與容器間通訊

<!--
搞懂了三種 Network Driver，接下來我們要解決一個更實際的問題：外部使用者要怎麼連到我們 Container 裡面跑的服務？還有，Container 之間預設能不能直接互相通訊？
-->

---

# 什麼是 Port Mapping？

Container 內監聽的 port（例如 80）屬於自己的網路空間，主機外部無法直接連入。

**Port Mapping（port 映射）** 將主機的 port 轉接到 Container 內部的 port：

> 「Use the `--publish` or `-p` flag to make a port available outside the host, and to containers in other bridge networks.」

`-p` 讓外部透過主機的指定 port，連進 Container 內部服務。

<!--
這邊先建立一個直覺：Container 預設是關起門來的，外面的人連不進去。就算 nginx 在 Container 裡面已經在監聽 80 port，你在主機上開瀏覽器打 localhost 還是連不到，因為那個 80 port 是 Container 自己的，跟主機的 80 port 是兩個完全不同的空間。

-p 的作用，就是幫我們在主機和 Container 之間開一條轉接線。等一下看語法大家就會清楚了。

業界實務上，這是我們部署服務時幾乎每次都會用到的參數，一定要熟悉。
-->

---

# Port Mapping 的語法結構

| 語法 | 說明 |
| --- | --- |
| `-p 8080:80` | 主機 port:Container port，所有網路介面都可連 |
| `-p 127.0.0.1:8080:80` | 只綁定主機的 127.0.0.1，限制存取來源 |
| `-P` / `--publish-all` | 隨機映射 Dockerfile 中 EXPOSE 的所有 port |
| `docker port <container>` | 查詢目前 Container 的 port 映射狀況 |

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
第一段是最常用的寫法，格式是「主機 port : Container port」，順序是左邊主機、右邊 Container。⚠️ 這個順序很容易搞混，是新手最常犯的錯誤之一，寫反了瀏覽器就連不到。

第二段是我特別想推薦給大家的做法。前面我們都寫 -p 3307:3306，這樣其實會把資料庫綁在 0.0.0.0，也就是同一個 wifi 底下的任何人都能連你的 MySQL，帳密還是 appuser/apppw 這種弱密碼。加上 127.0.0.1 前綴之後，只有你自己的電腦連得到，Workbench 一樣能用，但外面的人連不進來。

第三段的 -P 大寫，Docker 會讀 Dockerfile 裡的 EXPOSE 8080，自動找一個沒人用的主機 port 映射過去。這在同時要跑好幾個測試環境、懶得自己分配 port 的時候很方便，但因為 port 是隨機的，要用 docker port 查才知道。

預期結果：第一段跑完，瀏覽器連 http://localhost:8080 就看得到 TaskBoard 的畫面。
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
這頁是一個很重要的轉折點。我們剛剛學會怎麼用 -p 開放服務給外部連線，但 Container 之間彼此要怎麼溝通呢？

如果什麼都不做，Container 都掛在預設的 bridge 網路上，這時候它們只能透過 IP 互相連，不能用名字。

⚠️ 版本注意：以前很多教學會教大家用 --link 這個參數來解決這個問題，讓 Container 可以用名稱互相連線。但這個做法現在已經過時了，官方也不建議使用。現在正確的做法是建立一個自訂的 bridge network，Container 掛上去之後就會自動有 DNS 解析，直接用容器名稱就能互相連通，完全不需要 --link 這種舊式寫法。

這就是我們接下來第三部分要學的內容，也是這一章最重要的觀念。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 自訂 Network 與 DNS 解析

<!--
我們剛剛留了一個問題：Container 之間要怎麼用名字互相溝通，而不是死記 IP？答案就是自訂 Network。這一部分是今天的重點，大家要打起精神。
-->

---

# 什麼是自訂 Network？

預設 bridge network 沒有自動 DNS 解析，Container 只能用 IP 互相找，且 IP 在重啟後可能改變。

**自訂 Network（User-defined Network）** 是自行建立的獨立網路，具備自動 DNS 解析：

> 「On a user-defined bridge network, containers can resolve each other by name or alias.」

Container 加入自訂網路後，Docker 會啟動內建 **DNS Server（位址 127.0.0.11）**，自動將容器名稱解析成對應 IP。

<!--
還記得上一頁我們說的問題嗎？預設網路只能用 IP，很不方便。

自訂 Network 解決的就是這個問題。我們自己建立一個網路，把相關的 Container 都加進去，Docker 會在背後啟動一個內建的 DNS 伺服器，位址是 127.0.0.11，專門負責把容器名稱翻譯成 IP。

這就像小時候玩的門牌遊戲，以前你要找到朋友家，只能死記座標「第三排第五個」，現在社區裝了電子門牌系統，你喊名字，系統自動幫你導航過去。

業界實務上，只要是多個 Container 需要合作的專案，例如 web 服務要連資料庫，幾乎一定會用自訂 Network，這是標準做法。
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
這頁是整章最重要的一頁，我們終於把第三章那個難看的寫法修好了。

第一步建立 taskboard-net，就像新建了一個有門禁的社區。

第二步，資料庫加入網路，而且注意：這次完全沒有 -p。因為 API 是從網路內部連過來的，不需要經過主機。資料庫不對外曝露，這是正式環境的標準做法。

第三步是重點中的重點。連線字串從 `host.docker.internal:3307` 變成 `taskboard-db:3306`，兩個地方都改了：主機名稱變成容器名稱，port 從 3307 變回 3306。

⚠️ 這個 port 的變化請大家一定要弄懂，這是最多人卡住的地方。3307 是「主機」看到的 port，是 -p 映射出來的；但現在 API 容器是從內部網路直接找 taskboard-db，走的是容器對容器，這條路上根本沒有經過 -p 的映射，所以要用 MySQL 容器內部真正在聽的 3306。簡單記法：容器對容器，一律用容器內的原始 port。

第四步用 ping 驗證，看到有回應就代表 Docker 內建的 DNS（127.0.0.11）成功把 taskboard-db 這個名字翻譯成 IP 了。

⚠️ 另一個易錯點：兩個容器必須在「同一個」自訂網路才找得到彼此，掛在不同網路一樣是陌生人。
-->

---

# 使用自訂 Network 的注意事項

| 項目 | 說明 |
| --- | --- |
| ⚠️ 版本注意 | 舊式的 `--link` 容器連結參數已經不建議使用（deprecated），現行做法一律改用自訂 bridge network，DNS 會自動解析容器名稱 |
| 隔離性 | 只有加入同一個自訂網路的 Container 才能互相通訊，不同網路之間預設是隔離的，比預設 bridge 網路「大家都能互連」更安全 |
| 與 Docker Compose 的關係 | 第五章的 `compose.yaml` 之所以能直接寫 `jdbc:mysql://db:3306/...`，就是因為 Compose 自動幫我們建了一個自訂網路，服務名稱天生就能互相解析 |

<!--
這頁幫大家整理三個重點。

第一個，也是最重要的：--link 已經過時了，不要再用，現在的標準做法就是自訂 bridge network。網路上還在教 --link 的多半是比較舊的資料。

第二個，自訂網路的隔離性比預設網路好，不相關的服務不會意外連上彼此。

第三個是回頭解謎：上一章我們用 Compose，連線字串直接寫 db 就通了，當時沒解釋為什麼。答案就是這一頁——Compose 背後自動幫我們做了 docker network create 加上把所有服務掛進去這兩件事，只是它沒告訴我們。所以 Compose 不是魔法，只是把我們今天手動打的這些指令包起來了。
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
這頁是把今天學的 DNS 解析用在真實痛點上，大家做過 Angular 專案應該都被 CORS 咬過。

問題是這樣：前端在 localhost:8080，後端在 localhost:8081，瀏覽器認為這是兩個不同來源，AJAX 請求會被擋下來，除非後端加一堆 CORS 設定。很多人的做法是在 Spring Boot 加 @CrossOrigin，但那是治標，而且正式環境要維護一份允許清單。

比較好的做法是這頁的反向代理。瀏覽器只認識 localhost:8080 這一個來源，它打 /api/tasks，nginx 收到之後在容器網路內部轉發給 taskboard-api:8080。注意 proxy_pass 那行的主機名稱——就是我們剛剛學的容器名稱 DNS 解析，因為 nginx 容器跟 API 容器在同一個 taskboard-net 上。

從瀏覽器的角度，它從頭到尾只跟一個網站說話，沒有跨域，CORS 設定一行都不用寫。

另外那個 try_files 也很重要：Angular 是 SPA，路由都在前端。使用者直接輸入網址 /tasks/5 重新整理的話，nginx 會去找一個叫 tasks/5 的實體檔案，找不到就回 404。try_files 的意思是「找不到就統一回 index.html」，讓 Angular 自己處理路由。這是所有 SPA 部署都要設的一行，忘了就會出現「首頁正常但重新整理 404」的經典災情。

⚠️ 易錯點：proxy_pass 結尾的斜線有沒有寫，轉發出去的路徑會不一樣。寫成 `proxy_pass http://taskboard-api:8080;`（沒有 /api/）時，後端收到的路徑會保留 /api 前綴。兩種都可以用，重點是要跟後端 Controller 的 @RequestMapping 對得上。
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
第一題是暖身題，但情境完全實用：建立網路、加入容器、用名稱連線。

第 2 點特別強調不要加 -p，讓大家體會「資料庫不需要對主機曝露也能被 API 使用」。第 5 點是真正的驗收——ping 通只證明網路通了，Spring Boot 真的連上資料庫並啟動完成，才算過關。

大家先自己動手試試看，卡住再看下一頁提示。
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
提示的關鍵在下面那個警示框，這兩個坑十個人有八個會踩。

第一個是 port。大家已經很習慣 3307 了，反射性就寫上去，結果 API 一直連不到——因為 taskboard-db 容器內部根本沒有人在聽 3307。

第二個是忘記加 --network，容器就跑到預設 bridge 去了，這時候名稱解析不到，錯誤訊息會是 UnknownHostException。用 docker network inspect 看 Containers 區塊，就知道誰真的在網路裡。
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
第二題是本章的整合題，把 port mapping、自訂網路、DNS 解析、反向代理全部串起來，而且做出來的就是正式環境該有的樣子。

這其實是一個典型的三層式架構：只有前端這一個入口對外，後端跟資料庫完全藏在內部網路裡，一個 port 都不曝露。

第 4 點的第二個驗證特別重要，我要大家親自確認「API 真的連不到」。很多人會覺得少開 port 很不方便，但這正是重點——攻擊者從外面連不到你的 API，就少了一整個攻擊面。

第 5 題請大家討論一下：只開一個 port 意味著防火牆規則簡單、可稽核的入口只有一個、資料庫弱密碼也不會被外面掃到。
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
重點在於 taskboard-api 這次完全沒有 -p。它只服務同一個網路裡的 nginx，不需要曝露給主機外部。實務上資料庫跟內部 API 都是這樣處理，除非本機除錯需要才臨時開。

⚠️ 易錯點：如果同學順手幫 db 加了 -p 3306:3306，功能上不會壞，但等於把資料庫曝露在主機網路上，是不必要的風險。

那個除錯順序請大家記起來，這是分層架構除錯的通用心法：從使用者最近的那一層開始往內查，才能定位問題卡在哪一段。
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
我們來快速複習一下今天學到的東西。

第一，網路驅動有三種基本模式：bridge 預設、host 共用主機、none 完全隔離，各自對應不同的使用情境。

第二，-p 是我們對外開放服務的方式，格式一定要記得是「主機 port 在左、容器 port 在右」。

第三，也是今天最重要的觀念：預設網路沒有自動 DNS，Container 之間只能用 IP；自訂網路才有自動 DNS 解析，可以直接用容器名稱互連。

第四，⚠️ --link 這個舊式做法已經不建議使用了，我們以後看到教學提到 --link，都要知道現在該換成自訂 bridge network 才對。

這一章的內容是下一章 Volume 資料持久化的重要基礎，兩者都是讓 Container 之間、以及 Container 與外部資源溝通所需要的基礎建設知識，敬請期待下一章！
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對 bridge/host/none 三種模式、port mapping，或是自訂 Network 的 DNS 解析，有沒有什麼疑問？都歡迎提出來討論。
-->
