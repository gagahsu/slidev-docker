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
- **對外連線與反向代理**：容器 → Supabase、瀏覽器 → nginx → api
- **練習題** x2
- **總結**

<!--
今天的內容分成四大塊。

第一部分，我們先搞懂 Docker 提供的幾種網路模式，bridge、host、none，各自適合什麼場景。

第二部分，我們會學怎麼用 -p 把 Container 裡的服務開放到外面，還有 Container 之間預設是怎麼通訊的。

第三部分是重點：自訂 Network。我們會看到自訂 Network 帶來的最大好處——DNS 自動解析，也就是 Container 之間可以直接用名字互相連線，不用再記 IP。

第四部分把網路觀念套回 SSDS：後端容器怎麼連到外面的 Supabase，以及前端 nginx 的反向代理到底在做什麼——這兩件事第九章部署到雲端時都會再遇到。

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

多個 Container 各自運作於獨立沙盒，沒有網路設定時彼此互相看不到。SSDS 的 `ssds-web` 要把 `/api` 轉給 `ssds-api`、`ssds-api` 要連到雲端的 Supabase，靠的全是 Docker Network。

Docker Network 負責建立 Container 之間、以及 Container 與外界的通訊管道：

> 「Docker's networking subsystem is pluggable, using drivers. Several drivers exist by default.」

Docker 提供多種 **Network Driver（網路驅動程式）**，各代表不同的通訊規則：

- `bridge`：門禁管制的私有網路
- `host`：與主機共用網路，無隔離
- `none`：完全隔離，無對外連線

<!--
大家可以直接想 SSDS：一個 nginx 前端容器、一個 Spring Boot 後端容器，再加上遠在雲端的 Supabase。如果什麼都不設定，前後端兩個 Container 其實是互相看不見的，就像住在不同社區的人，彼此不認識。第四章我們被迫用 host.docker.internal 繞一大圈，就是因為當時什麼網路都沒設。

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
docker run --network bridge ssds-api:1.0.0   # 預設，SSDS 用這個
docker run --network host   ssds-api:1.0.0   # 直接佔用主機 8080
docker run --network none   ssds-api:1.0.0   # 連不到 Supabase，起不來
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
docker run -d --name ssds-web nginx:1.28-alpine
docker inspect -f '{{.NetworkSettings.IPAddress}}' ssds-web
# 172.17.0.2

# host：不再有獨立 IP，Spring Boot 的 8080 直接等於主機的 8080
docker run -d --network host --env-file .env --name ssds-api ssds-api:1.0.0
# 不用 -p，但如果本機 IDE 也在跑 8080，就直接衝突

# none：完全沒有網路介面
docker run --rm --network none alpine ip addr
# 只會看到 loopback 介面 lo
```

<!--
我們實際跑一次看看差異。

第一段，用 bridge 模式（也就是不指定 --network 的預設狀況）跑 nginx，它會拿到一個像 172.17.0.2 這樣的私有 IP，這個 IP 只有在 Docker 建立的橋接網路裡看得到。這也解釋了為什麼我們需要 -p：主機上的瀏覽器是連不到 172.17 這個網段的。

第二段，用 host 模式跑 Spring Boot，這時候容器裡監聽的 8080 就直接等於主機的 8080，不需要 -p，沒有中間的 NAT 轉換，效能最好。但代價是沒有隔離——很多同學 IDE 裡本來就開著一個 8080 的 Spring Boot，這樣直接衝突。而且 ⚠️ host 模式在 Windows / Mac 的 Docker Desktop 上行為跟 Linux 不同，不建議大家在開發機上依賴它。

第三段，用 none 模式，進去看網路介面只剩 loopback，完全連不到外面。如果 ssds-api 掛在 none 上，它連 Supabase 的網域名稱都查不到，HikariPool 會報 UnknownHostException，Spring Boot 啟動失敗。

預期結果：三種模式，網路行為完全不同。SSDS 全程用 bridge，這也是 99% 的情況該用的。
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

業界實務上，這是我們部署服務時幾乎每次都會用到的參數，一定要熟悉。第九章的雲端平台會幫我們做這件事——它會把外部的 https 443 轉到容器裡的某個 port，我們只要告訴它是哪個 port。
-->

---

# Port Mapping 的語法結構

| 語法 | 說明 |
| --- | --- |
| `-p 8000:80` | 主機 port:Container port，所有網路介面都可連 |
| `-p 127.0.0.1:8080:8080` | 只綁定主機的 127.0.0.1，限制存取來源 |
| `-P` / `--publish-all` | 隨機映射 Dockerfile 中 EXPOSE 的所有 port |
| `docker port <container>` | 查詢目前 Container 的 port 映射狀況 |

---

# Port Mapping — 範例

```bash
# 前端：主機 8000 對應容器 80，同組組員也能用你的 IP 連進來看
docker run -d -p 8000:80 --name ssds-web ssds-web:1.0.0

# 後端：只允許本機連線（Swagger 自己看就好），外部連不進來
docker run -d -p 127.0.0.1:8080:8080 --env-file .env --name ssds-api ssds-api:1.0.0

# 讓 Docker 自動挑一個沒被佔用的主機 port（會用 Dockerfile 裡的 EXPOSE 8080）
docker run -d -P --env-file .env --name ssds-api-2 ssds-api:1.0.0

# 查詢實際映射到哪個 port
docker port ssds-api-2
# 8080/tcp -> 0.0.0.0:32768
```

<!--
第一段是最常用的寫法，格式是「主機 port : Container port」，順序是左邊主機、右邊 Container。⚠️ 這個順序很容易搞混，是新手最常犯的錯誤之一，寫反了瀏覽器就連不到。

第二段是我特別想推薦給大家的做法。寫 -p 8080:8080 其實會把後端綁在 0.0.0.0，也就是同一個 wifi 底下的任何人都能連你的 API——而我們專案的 SecurityConfig 目前是全部 permitAll。加上 127.0.0.1 前綴之後，只有你自己的電腦連得到，Swagger 一樣能用，但外面的人連不進來。

第三段的 -P 大寫，Docker 會讀 Dockerfile 裡的 EXPOSE 8080，自動找一個沒人用的主機 port 映射過去。這在同時要跑好幾個實例、懶得自己分配 port 的時候很方便，但因為 port 是隨機的，要用 docker port 查才知道。

預期結果：第一段跑完，瀏覽器連 http://localhost:8000 就看得到 SSDS 的登入畫面。
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

如果什麼都不做，Container 都掛在預設的 bridge 網路上，這時候它們只能透過 IP 互相連，不能用名字。所以如果第四章的 ssds-web 把 API_URL 設成 http://ssds-api:8080，在預設網路上 nginx 會一啟動就報 host not found in upstream，容器直接退出。

⚠️ 版本注意：以前很多教學會教大家用 --link 這個參數來解決這個問題。但這個做法現在已經過時了，官方也不建議使用。現在正確的做法是建立一個自訂的 bridge network。

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

Container 加入自訂網路後，Docker 會啟動內建 **DNS Server（位址 127.0.0.11）**，自動將容器名稱解析成對應 IP；不認識的名稱（例如 Supabase 網域）再轉給主機的 DNS。

<!--
還記得上一頁我們說的問題嗎？預設網路只能用 IP，很不方便。

自訂 Network 解決的就是這個問題。我們自己建立一個網路，把相關的 Container 都加進去，Docker 會在背後啟動一個內建的 DNS 伺服器，位址是 127.0.0.11，專門負責把容器名稱翻譯成 IP。如果查的是外面的網域，例如 aws-0-ap-south-1.pooler.supabase.com，它會再往外轉給主機的 DNS，所以連外完全不受影響。

這就像小時候玩的門牌遊戲，以前你要找到朋友家，只能死記座標「第三排第五個」，現在社區裝了電子門牌系統，你喊名字，系統自動幫你導航過去。

業界實務上，只要是多個 Container 需要合作的專案，幾乎一定會用自訂 Network，這是標準做法。
-->

---

# 自訂 Network 的語法結構

| 指令 | 說明 |
| --- | --- |
| `docker network create <name>` | 建立一個新的自訂 bridge 網路 |
| `docker network create -d bridge <name>` | 明確指定使用 bridge 驅動 |
| `docker run --network <name> ...` | 啟動 Container 時直接加入指定網路 |
| `docker network connect <name> <container>` | 讓已存在的 Container 加入網路 |
| `docker network inspect <name>` | 查看網路設定與有哪些 Container 在裡面 |
| `docker network ls` / `rm <name>` | 列出 / 刪除網路 |

---

# 自訂 Network — 範例

```bash
# 1. 建立 SSDS 專用網路
docker network create ssds-net

# 2. 後端加入網路，不對外開 port（只讓 nginx 從內部找它）
docker run -d --network ssds-net --name ssds-api --env-file .env ssds-api:1.0.0

# 3. 前端加入同一網路，API_URL 終於可以寫容器名稱了
docker run -d --network ssds-net -p 8000:80 --name ssds-web \
  -e API_URL=http://ssds-api:8080 \
  ssds-web:1.0.0

# 4. 驗證 DNS 解析
docker exec ssds-web nslookup ssds-api
# Name:    ssds-api
# Address: 172.18.0.2
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>對照第四章：</b> 當時預設 <code>API_URL=http://host.docker.internal:8080</code>（繞出容器到主機、再經過 <code>-p</code> 繞回來），現在直接寫 <code>ssds-api:8080</code> — 容器對容器走內部網路，api 甚至不需要 <code>-p</code>。
</div>

<!--
這頁是整章最重要的一頁，我們終於把第四章那個 host.docker.internal 的寫法換掉了。

第一步建立 ssds-net，就像新建了一個有門禁的社區。

第二步，後端加入網路，而且注意：這次完全沒有 -p。因為 nginx 是從網路內部連過來的，不需要經過主機。後端不對外曝露，使用者只能透過前端的 /api 路徑存取它。

第三步是重點。API_URL 從 `http://host.docker.internal:8080` 變成 `http://ssds-api:8080`：主機名稱變成容器名稱。

⚠️ 這裡的 port 觀念請大家一定要弄懂：8080 是「容器內」Spring Boot 在聽的 port。容器對容器走內部網路，這條路上根本沒有經過 -p 的映射，所以一律用容器內的原始 port。如果你在第二步用了 -p 9090:8080，API_URL 還是要寫 8080，不是 9090。

第四步用 nslookup 驗證，看到 IP 就代表 Docker 內建的 DNS（127.0.0.11）成功把 ssds-api 這個名字翻譯成 IP 了。

⚠️ 另一個易錯點：兩個容器必須在「同一個」自訂網路才找得到彼此，掛在不同網路一樣是陌生人。
-->

---

# 使用自訂 Network 的注意事項

| 項目 | 說明 |
| --- | --- |
| ⚠️ 版本注意 | 舊式的 `--link` 容器連結參數已經不建議使用（deprecated），現行做法一律改用自訂 bridge network |
| 隔離性 | 只有加入同一個自訂網路的 Container 才能互相通訊，不同網路之間預設是隔離的 |
| 啟動順序 | nginx 啟動時就會解析 `proxy_pass` 的主機名稱，**ssds-api 要先存在**，否則 nginx 報 `host not found in upstream` 直接退出 |
| 與 Docker Compose 的關係 | 第五章的 `API_URL: http://api:8080` 之所以能通，就是因為 Compose 自動建了一個自訂網路，服務名稱天生就能互相解析 |

<!--
這頁幫大家整理四個重點。

第一個：--link 已經過時了，不要再用。

第二個，自訂網路的隔離性比預設網路好，不相關的服務不會意外連上彼此。

第三個是 nginx 特有的坑：nginx 在「啟動」那一刻就會去查 proxy_pass 裡的主機名稱，查不到就整個啟動失敗。所以手動 docker run 的時候要先起 ssds-api 再起 ssds-web。Compose 裡我們用 depends_on 確保了這個順序。

第四個是回頭解謎：上一章我們用 Compose，API_URL 直接寫 api 就通了，當時沒解釋為什麼。答案就是這一頁——Compose 背後自動幫我們做了 docker network create 加上把所有服務掛進去這兩件事。Compose 不是魔法，只是把今天手動打的這些指令包起來了。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 對外連線與反向代理

<!--
最後一部分，我們把網路觀念套回 SSDS 專案的兩條關鍵路徑：

第一條，ssds-api 容器往外連到 Supabase。
第二條，使用者的瀏覽器連到 ssds-web，nginx 再把 /api 轉給 ssds-api。

第九章部署到雲端，出問題的幾乎都是這兩條路，所以這裡要先搞懂。
-->

---
zoom: 0.95
---

# 容器 → Supabase：對外連線

容器預設**可以直接連網際網路**（bridge 網路會做 NAT），所以 `ssds-api` 用環境變數就能連 Supabase：

```bash
# 從容器內測試 DNS 與 TCP 連線（alpine 內建 busybox 的 nslookup / nc）
docker exec ssds-api nslookup aws-0-ap-south-1.pooler.supabase.com
docker exec ssds-api nc -zv -w 3 aws-0-ap-south-1.pooler.supabase.com 6543
```

| Supabase 連線方式 | Host 範例 | Port | IPv4 | 本專案 |
| --- | --- | --- | --- | --- |
| Direct connection | `db.<ref>.supabase.co` | 5432 | ❌ 只有 IPv6（IPv4 要付費加購） | 不用 |
| Transaction pooler | `aws-0-<region>.pooler.supabase.com` | **6543** | ✅ | 應用程式（`SSDS_DB_PORT`） |
| Session pooler | `aws-0-<region>.pooler.supabase.com` | 5432 | ✅ | Flyway migration |

<!--
這頁講第一條路：容器往外連。

好消息是容器預設就能上網，bridge 網路會幫我們做 NAT，所以 ssds-api 讀到 SSDS_DB_HOST、SSDS_DB_PORT 就能直接連 Supabase，不用任何網路設定。

但有一個坑，大家一定要知道：Supabase 的「Direct connection」網址 db.xxx.supabase.co 預設只有 IPv6 位址。Docker Desktop 預設網路、大部分免費雲端平台（包含第九章要用的 Render），對外連線都只有 IPv4。用 direct connection 的話會出現 Network is unreachable 或 UnknownHost 之類的錯誤。

我們專案的 application.properties 已經寫好用 pooler：應用程式走 6543 的 transaction pooler，Flyway 走 5432 的 session pooler，兩個都有 IPv4，所以容器裡、雲端上都能連。專案註解裡也有解釋為什麼 Flyway 不能走 6543（advisory lock）。

⚠️ 所以結論是：SSDS_DB_HOST 一定要用 pooler 的網址，不要因為在 Supabase 後台看到「Direct connection」就換過去。

nc -zv 是測 TCP 連線用的，看到 open 就代表網路通了，接下來連不上就是帳密問題，不是網路問題。
-->

---

# 瀏覽器 → nginx → api：反向代理

SSDS 前端的 production 設定 `environment.prod.ts` 寫的是 `apiBaseUrl: '/api/v1'`（**相對路徑**），所以：

```text
瀏覽器
  │ GET /api/v1/products
  ▼
ssds-web (nginx :80)
  │ location /api/ → proxy_pass ${API_URL}
  ▼
ssds-api (:8080) → context-path /api/v1 → ProductController
```

```nginx
location /api/ {
    proxy_pass ${API_URL};
}
# ✅ http://ssds-api:8080   → 後端收到 /api/v1/products
# ❌ http://ssds-api:8080/  → 後端收到 /v1/products（404）
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>為什麼不讓瀏覽器直接打後端？</b> 後端 <code>SecurityConfig</code> 的 CORS 白名單只有 <code>localhost:4200</code>。走反向代理後，瀏覽器眼中只有一個網域，<b>CORS 一行都不用改</b>，本機、Compose、雲端都一樣。
</div>

<!--
這頁是第二條路：反向代理。

大家打開前端的 src/environments/environment.prod.ts，apiBaseUrl 寫的是 /api/v1，沒有網域。意思是 production build 出來的網頁，會把 API 請求送回「自己的網域」。所以在 ssds-web 容器裡，nginx 必須負責把 /api 開頭的請求轉給後端，這就是反向代理。

proxy_pass 的斜線規則是 nginx 最經典的坑：
- proxy_pass 後面只有「協定+主機+port」、沒有任何路徑時，請求的 URI 原封不動轉過去。瀏覽器打 /api/v1/products，後端就收到 /api/v1/products，剛好對上 context-path。
- 一旦 proxy_pass 後面帶了路徑，哪怕只是一個斜線，nginx 會把 location 比對到的 /api/ 那段「替換」成你寫的路徑，後端收到 /v1/products，全部 404。

⚠️ 這個坑第九章一定會有人踩：從雲端平台複製後端網址時，常常會多帶一個結尾斜線。API_URL 一律不要有結尾斜線。

為什麼要繞這一圈？因為 CORS。後端 SecurityConfig 裡 CORS 只允許 localhost:4200 跟一個測試 port。如果讓瀏覽器直接打後端的網址，部署到雲端後網域變了，就會被 CORS 擋下來，還得改後端程式碼重新部署。走反向代理，瀏覽器從頭到尾只跟一個網域說話，根本不會觸發 CORS。
-->

---
layout: default
---

# 練習 1：讓 web 用名稱連上 api
### 任務說明

把第四章那個 `host.docker.internal` 的寫法換掉，並把後端藏起來。

**目標：**

1. 建立一個名為 `ssds-net` 的自訂網路
2. 啟動 `ssds-api`（帶 `--env-file .env`）加入這個網路，**不要加 `-p`**
3. 啟動 `ssds-web` 加入同一個網路，`-p 8000:80`，用 `-e API_URL=...` 指向 api 的**容器名稱**
4. 用 `docker exec` 驗證 web 容器能解析 `ssds-api`
5. 驗證：`http://localhost:8000` 能登入並載入資料；`http://localhost:8080/api/v1/actuator/health` **應該連不上**

<!--
第一題是暖身題，但情境完全實用：建立網路、加入容器、用名稱連線。

第 2 點特別強調不要加 -p，讓大家體會「後端不需要對主機曝露也能被前端使用」。第 5 點有兩個驗證：前端能用代表反向代理通了；直接打 8080 連不上代表後端真的藏起來了——整套只有一個入口。

大家先自己動手試試看，卡住再看下一頁提示。
-->

---
layout: default
---

# 練習 1：解題提示
### 提示說明

```bash
docker network create ssds-net

docker run -d --network ssds-net --name ssds-api \
  --env-file ai-products-selection-backend/.env ssds-api:1.0.0

docker logs -f ssds-api            # 等到 Started SsdsApplication 再起 web

docker run -d --network ssds-net -p 8000:80 --name ssds-web \
  -e API_URL=http://ssds-api:8080 ssds-web:1.0.0

docker exec ssds-web nslookup ssds-api
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>兩個必踩的坑：</b> (1) 兩個容器都要加 <code>--network ssds-net</code>，漏一個就掉回預設網路，nginx 會報 <code>host not found in upstream "ssds-api"</code>，用 <code>docker network inspect ssds-net</code> 可以查誰在裡面。
(2) <code>API_URL</code> 結尾<b>不要</b>加斜線。
</div>

<!--
提示的關鍵在下面那個警示框，這兩個坑十個人有八個會踩。

第一個是忘記加 --network，容器就跑到預設 bridge 去了，名稱解析不到。nginx 的錯誤訊息會出現在 docker logs ssds-web 裡，而且容器會直接 Exited。

第二個是結尾斜線，上一頁講過了，症狀是前端所有 API 都 404。

如果之前的 ssds-api、ssds-web 容器還在，先 docker rm -f 清掉再做，不然會撞名。
-->

---
layout: default
---

# 練習 2：網路除錯演練
### 任務說明

**目標：** 故意弄壞三個地方，練習從外往內一層一層找問題。

1. 把 `ssds-web` 的 `API_URL` 改成 `http://localhost:8080` 重新啟動 → 瀏覽器操作後看到什麼錯誤？`docker logs ssds-web` 說什麼？
2. 把 `API_URL` 改成 `http://ssds-api:8080/`（多一個斜線）→ 前端出現什麼狀況？`docker logs ssds-api` 有收到請求嗎？
3. 把後端 `.env` 的 `SSDS_DB_HOST` 暫時改成 Supabase 的 direct connection 網址 `db.<ref>.supabase.co`、`SSDS_DB_PORT=5432` → `docker logs ssds-api` 報什麼錯？
4. 用 `docker exec ssds-api nslookup` / `nc -zv` 分別測試 pooler 與 direct 兩個網址，比較結果
5. 全部改回正確設定，確認系統恢復正常

<!--
第二題是本章的整合題，而且是除錯演練——第九章部署到雲端，最常遇到的就是這三種問題，先在本機看過一次症狀，到時候就不會慌。

第 1 點：localhost 在 nginx 容器裡是自己，nginx 連 8080 沒人聽，瀏覽器會看到 502 Bad Gateway，nginx log 會有 connect() failed (111: Connection refused)。

第 2 點：多了斜線，後端收到的路徑少了 /api，全部 404。看 ssds-api 的 log 會發現請求確實有進來，只是路徑不對。

第 3 點：direct connection 只有 IPv6，Docker Desktop 預設沒有 IPv6 對外，會看到 Network is unreachable 之類的連線錯誤，api 一直起不來。

第 4 點讓大家親眼看到差別：nslookup direct 網址只會回 IPv6 位址（AAAA），pooler 會回 IPv4。

⚠️ 第 3 點改 .env 之前先備份，做完一定要改回來，不然後面都連不上。
-->

---
layout: default
zoom: 0.93
---

# 練習 2：解題提示
### 提示說明

| 故障 | 瀏覽器症狀 | 去哪裡看 | 關鍵訊息 |
| --- | --- | --- | --- |
| `API_URL=http://localhost:8080` | 502 Bad Gateway | `docker logs ssds-web` | `connect() failed (111: Connection refused)` |
| `API_URL` 多結尾斜線 | API 全部 404 | `docker logs ssds-api` | 收到的路徑是 `/v1/...`，少了 `/api` |
| 用 direct connection | 502，api 一直重啟或 unhealthy | `docker logs ssds-api` | `Network is unreachable` / `UnknownHostException` |

```bash
docker exec ssds-api nslookup db.<ref>.supabase.co  # 僅 IPv6
docker exec ssds-api \
  nslookup aws-0-ap-south-1.pooler.supabase.com     # 有 IPv4
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>除錯順序：</b> 瀏覽器 DevTools 看 HTTP 狀態碼 → <code>docker logs ssds-web</code> 看 nginx 有沒有轉出去 → <code>docker logs ssds-api</code> 看後端有沒有收到、有沒有連上 Supabase。從外往內一層一層看。
</div>

<!--
這張表請大家截圖收好，第九章雲端部署出問題時，症狀跟這張表幾乎一模一樣，只是 docker logs 換成雲端平台的 Logs 頁面。

那個除錯順序請大家記起來，這是分層架構除錯的通用心法：從使用者最近的那一層開始往內查，才能定位問題卡在哪一段。502 是 nginx 連不到後端；404 是有連到但路徑不對；500 是後端程式自己出錯。
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
<tr><td>bridge / host / none</td><td>預設有隔離的私有網路 / 共用主機網路 / 完全沒有網路</td></tr>
<tr><td>Port Mapping</td><td><code>-p 主機port:容器port</code>；容器對容器一律用容器內的 port</td></tr>
<tr><td>自訂 Network</td><td>內建 DNS（127.0.0.11），用容器名稱互連，取代過時的 <code>--link</code></td></tr>
<tr><td>連 Supabase</td><td>容器預設可對外；一律用 <b>pooler（IPv4）</b>，不用 direct connection（IPv6）</td></tr>
<tr><td>反向代理</td><td>nginx 把 <code>/api/</code> 轉給後端，同網域免 CORS；<code>API_URL</code> 不加結尾斜線</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入 Volume 資料持久化，讓使用者上傳的商品圖片活得比 Container 久。
</div>

<!--
我們來快速複習一下今天學到的東西。

第一，網路驅動有三種基本模式：bridge 預設、host 共用主機、none 完全隔離。

第二，-p 是我們對外開放服務的方式，格式一定要記得是「主機 port 在左、容器 port 在右」；而容器之間互連不經過 -p，用容器內的 port。

第三，也是今天最重要的觀念：預設網路沒有自動 DNS；自訂網路才有，可以直接用容器名稱互連。Compose 自動幫我們做了這件事。

第四，套回專案：連 Supabase 要用 pooler 網址（IPv4），反向代理讓前後端同網域、不用處理 CORS，API_URL 不能有結尾斜線。這兩點第九章會直接用上。

下一章我們處理第三章留下的伏筆：上傳的圖片怎麼不會隨著容器消失。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對 bridge/host/none 三種模式、port mapping、自訂 Network 的 DNS 解析，或是反向代理、連 Supabase 的問題，有沒有什麼疑問？都歡迎提出來討論。
-->
