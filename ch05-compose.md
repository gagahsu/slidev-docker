---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: Docker Compose
routeAlias: ch05
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">Docker Compose</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「一份總譜，指揮所有容器同時上場」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
歡迎來到第五章，Docker Compose。

前面幾章，我們用 `docker run` 一個一個操作容器，上一章也把 TaskBoard 前後端打包成了 Image。但真實的應用不會只有一個容器，TaskBoard 就有三個，而且彼此要互相溝通。

這一章要解決的，就是同時管理很多容器這件麻煩事。學完之後，我們只要一行指令，就能把整套 TaskBoard 啟動起來。
-->

---
layout: default
---

# Outline

- **compose.yaml 語法結構**
- **docker compose 指令**
- **多容器應用範例（web + db）**
- **練習題**：從簡單到進階
- **總結**

<!--
這一章分成三部分。先搞懂 compose.yaml 這份設定檔怎麼寫，再學怎麼用 `docker compose` 指令操作它。最後把 TaskBoard 的資料庫、後端和前端寫進同一份檔案，做出完整的三層架構。中間有兩題練習，從簡單到進階。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# compose.yaml 語法結構

<!--
我們先從設定檔本身開始。compose.yaml 是 Compose 的核心，之後所有指令都是圍繞這份檔案在運作。
-->

---

# 為什麼需要 Docker Compose？

- TaskBoard 光是跑起來就要三個容器：`taskboard-web`、`taskboard-api`、`taskboard-db`，而且彼此要能互相溝通
- 第三章我們用 `docker run` 逐一啟動，那三行指令加起來十幾個參數，還得記得先起資料庫、再起 API，新同事第一天就要照抄一整頁 README
- Docker Compose：「**define and manage multi-container apps in one YAML file, streamlining orchestration**」——用一份 YAML 檔案定義並管理多容器應用
- 比喻：Compose 如同「**樂團總譜**」，一次定義每個容器（樂手）用什麼映像檔（樂器）、跟誰同網路（合奏），再用 `docker compose` 指令統一啟動

<!--
先請大家回想第三章，啟動 TaskBoard 的那三行 `docker run`。

每一行都很長，加起來十幾個參數，還有那個不太好看的 `host.docker.internal`。而且順序很重要，要先起資料庫，再起 API。MySQL 還沒初始化完，API 太早啟動就會連不上、直接停掉。新同事報到第一天，就要照著 README 抄一整頁指令。

Docker Compose 解決的就是這個問題，「用一份 YAML 檔案定義並管理多容器應用」。

我們可以把它想成樂團的總譜。總譜上寫好每位樂手用什麼樂器、跟誰合奏，指揮一舉手，全體一起上場。在 Compose 裡，樂手就是容器，樂器就是 Image。

學完這章，新同事只要 clone 專案，打一行 `docker compose up -d`，整套環境就起來了。
-->

---

# 什麼是 compose.yaml？

| 項目 | 說明 |
| --- | --- |
| 檔案格式 | YAML（YAML Ain't Markup Language） |
| 建議檔名 | `compose.yaml`（新版推薦寫法） |
| 舊版相容檔名 | `docker-compose.yml`（仍可使用，Compose 會自動辨識） |
| 核心概念 | 一份檔案描述多個 Service、Network、Volume |
| 執行方式 | `docker compose` 讀取此檔案並依定義建立資源 |

> ⚠️ **版本注意**：Docker Compose 目前是 Docker CLI 的內建 plugin（v2），指令一律是空格分隔的 `docker compose`，不是舊版獨立執行檔的 `docker-compose`（中間有連字號）。教學文件、網路上的舊文章常常還在用 `docker-compose`，我們統一用新寫法。

<!--
這張表介紹 compose.yaml 的基本資訊，我們挑重點看。

檔名建議用 `compose.yaml`，這是新版推薦的寫法。舊專案常見的 `docker-compose.yml` 一樣可以用，Compose 會自動辨識，不用急著改名。

下面的版本注意很重要。現在的 Compose 是 Docker CLI 內建的 plugin，指令是 docker 空格 compose。網路上很多舊文章寫的是中間有連字號的 `docker-compose`，那是已經停止維護的舊版獨立程式。

直接複製舊文章的指令，很可能會出現 command not found，因為系統上根本沒裝舊版。這門課我們一律使用新寫法。
-->

---

# compose.yaml 的三大區塊

| 區塊 | 用途 | 常見欄位 |
| --- | --- | --- |
| `services` | 定義每個容器要跑什麼 | `image`, `build`, `ports`, `environment`, `volumes`, `depends_on` |
| `networks` | 定義容器之間的通訊網路 | `driver`, `name` |
| `volumes` | 定義資料持久化的儲存空間 | `driver`, `name` |

「**一個 service 就是一個會被跑起來的容器（或一組容器）**」，services 底下每一個 key 就是一個服務名稱，這個名稱同時也會是容器在內部網路裡的主機名稱（hostname），這點在第三部分連線資料庫時會很重要。

<!--
compose.yaml 主要有三大區塊。services 定義要跑哪些容器，networks 定義容器之間的網路，volumes 定義資料要存在哪裡。

這三個裡面，最重要的是 services。「一個 service 就是一個會被跑起來的容器」，services 底下的每一個 key，就是一個服務名稱。

請大家先記住一件事：這個服務名稱，同時也會是容器在內部網路裡的主機名稱。這點在第三部分，API 連線資料庫的時候會非常重要。
-->

---

# — 範例

```yaml
services:
  web:
    image: taskboard-web:1.0.0
    ports:
      - "8080:80"
  api:
    image: taskboard-api:1.0.0
    ports:
      - "8081:8080"
  db:
    image: mysql:8.4
    environment:
      MYSQL_ROOT_PASSWORD: rootpw
      MYSQL_DATABASE: taskboard

networks:
  default:
    driver: bridge

volumes:
  db-data:
```

<!--
這一頁給一個最小的骨架，對照剛才的三大區塊來看。

services 底下有三個服務，web、api、db，分別對應 TaskBoard 的三層。web 和 api 用的是我們上一章打包的 Image，db 用官方的 `mysql:8.4`，並帶入兩個環境變數。下面再宣告一個 network 和一個 volume。

這份還很陽春，API 還沒有資料庫連線設定，資料也還沒真的存進 volume，第三部分會把它補完整。現在先讓大家看看三個服務並排在同一份檔案裡的樣子。

注意 ports 的值有加引號，原因下一頁會說明。
-->

---

# YAML 語法基本規則

| 規則 | 說明 | 範例 |
| --- | --- | --- |
| 縮排代表階層 | 用「空格」縮排，禁止用 Tab | `services:` 底下要縮排 |
| `key: value` | 冒號後面要留一個空格 | `image: nginx` |
| 清單（list） | 用 `-` 開頭表示陣列元素 | `ports: \n  - "80:80"` |
| 字串可省略引號 | 但含特殊字元建議加引號 | `"8080:80"` |
| 註解 | 用 `#` 開頭 | `# 這是註解` |

> ⚠️ 冒號後面沒空格、或用 Tab 縮排，都是新手最常踩的兩個地雷，Compose 會直接報 YAML 解析錯誤。

<!--
很多同學是第一次寫 YAML，這一頁補一下基本功。

YAML 用縮排表示階層，就像整理衣櫃，同一層的東西要對齊，放錯一層就找不到。

表格裡最常出錯的有兩個。第一，縮排只能用空格，不能用 Tab。第二，冒號後面一定要留一個空格。這兩個錯誤，Compose 都會直接報解析錯誤，錯誤訊息通常會告訴我們是第幾行，照著去找就好。

另外，像 port 這種含有冒號的值，建議加上引號，當成字串處理，避免被 YAML 誤解成其他格式。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# docker compose 指令

<!--
設定檔寫好了，接下來看怎麼用指令操作它。邏輯跟之前學的 docker 指令很像，只是對象從單一容器，變成整份檔案裡的所有服務。
-->

---

# 常用 docker compose 指令

| 指令 | 用途 | 常用參數 |
| --- | --- | --- |
| `docker compose up` | 建立並啟動所有服務 | `-d`（背景執行）、`--build` |
| `docker compose down` | 停止並移除容器、網路 | `-v`（連 Volume 一起刪除） |
| `docker compose logs` | 查看服務的輸出紀錄 | `-f`（持續追蹤）、`--tail` |
| `docker compose ps` | 列出目前執行中的服務 | — |
| `docker compose build` | 重新建構服務的映像檔 | — |
| `docker compose exec` | 進入執行中的容器下指令 | `<service> <command>` |

「**docker compose up 會一次讀完 compose.yaml，照著裡面的順序把 network、volume、所有 service 都建立並啟動**」，這就是總譜一次指揮全體上場的概念。

<!--
這張表是最常用的 docker compose 指令。

最核心的是三個。`up` 建立並啟動所有服務，加 `-d` 在背景執行，加 `--build` 會先重新建構 Image。`down` 停止並移除容器和網路。`logs` 查看服務的輸出紀錄。

另外 `ps` 和 `exec` 跟之前學的 docker 指令用法一樣，只是對象改成服務名稱。

「docker compose up 會一次讀完 compose.yaml」，把網路、volume 和所有服務建立起來，就像指揮一舉手，全體樂手一起上場。
-->

---

# — 範例

```bash
# 背景啟動所有服務，並在需要時重新建置映像檔
docker compose up -d --build

# 即時追蹤所有服務的日誌（三個服務的 log 會交錯顯示，各有顏色）
docker compose logs -f

# 只看 api 服務最後 50 行日誌
docker compose logs --tail 50 api

# 進資料庫容器下 SQL（不用管容器全名叫什麼）
docker compose exec db mysql -uappuser -papppw taskboard

# 只重新建置並重啟 api（改完 Java 之後最常打的一行）
docker compose up -d --build api

# 停止並移除容器、網路（保留 volume，資料庫資料還在）
docker compose down

# 連同 volume 一起刪除（資料會被清空）
docker compose down -v
```

<!--
這一頁看這些指令的實際用法。

第一行背景啟動所有服務。第二行 `logs -f` 會同時追蹤三個服務的 log，用不同顏色交錯顯示。

請大家特別記住倒數第三個，`docker compose up -d --build api`。這是容器化開發的日常節奏，改完 Controller、存檔、打這一行。Compose 只會重新建構和重啟 api，資料庫和前端完全不動，比整套 down 再 up 快很多。

`docker compose exec db` 接的是服務名稱 db，不是容器全名。Compose 會幫容器名稱加上專案前綴，用 compose exec 就不用記全名。

最後兩行要分清楚。`down` 預設不會刪除 volume，資料庫的資料還在。就像演出結束樂手下台，但樂器還留在後台。加上 `-v` 才是連樂器一起清掉，資料也會被清空。
-->

---

# 使用 docker compose 的注意事項

| 情境 | 說明 |
| --- | --- |
| 指令找不到 | 確認用的是 `docker compose`（有空格），不是舊版 `docker-compose` |
| 修改 compose.yaml 後沒生效 | 需要重新執行 `docker compose up -d` 讓 Compose 套用新設定 |
| 服務啟動但立刻結束 | 用 `docker compose logs <service>` 查看錯誤訊息 |
| Port 衝突 | 檢查 `ports` 設定是否跟主機上其他程式衝突 |

> ⚠️ **版本注意**：`docker compose`（v2, plugin）已內建在新版 Docker Desktop / Docker Engine 裡，不需要額外安裝；如果系統上還裝著舊版獨立執行檔 `docker-compose`（v1），建議直接改用新寫法，v1 已經停止維護。

<!--
這一頁整理幾個常見的狀況，讓大家遇到問題時知道先查什麼。

指令找不到，先確認用的是有空格的 `docker compose`。改了 compose.yaml 沒生效，要再執行一次 `docker compose up -d`，讓 Compose 套用新設定。服務啟動後立刻結束，就用 `docker compose logs` 看錯誤訊息，跟第三章學的除錯順序一樣。

下面的版本注意再強調一次，新版的 Compose 已經內建在 Docker Desktop 裡，不需要另外安裝，舊版也已經停止維護。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 多容器應用範例（web + db）

<!--
指令會用了，現在把語法和指令串起來，做一個最貼近實務的範例，把 TaskBoard 的三個服務完整寫進 Compose。
-->

---

# 服務間如何互相連線？

「**同一個 compose.yaml 裡的所有 service，預設會被放進同一個內部網路，彼此可以用『服務名稱』當作主機名稱互相溝通**」，不需要知道對方的 IP，也不需要額外設定。

例如資料庫 service 命名為 `db`，Spring Boot 的連線字串就直接寫 `jdbc:mysql://db:3306/taskboard`，Compose 內建 DNS 會自動解析成正確的容器 IP。第三章那個難看的 `host.docker.internal:3307` 到這裡終於可以退場了。

| 概念 | 說明 |
| --- | --- |
| 內部網路 | Compose 預設自動建立一個 network，所有 service 都加入 |
| 主機名稱解析 | service 名稱 = 容器的 hostname，可直接用來連線 |
| 對外開放 | 只有設定 `ports` 的 service 才能被主機外部存取 |
| 資料持久化 | db 的資料要寫進 `volumes`，容器刪掉資料才不會不見 |

<!--
這一頁是這一部分最重要的觀念。

「同一個 compose.yaml 裡的所有 service，預設會被放進同一個內部網路」，彼此可以直接用服務名稱當作主機名稱溝通，不需要知道對方的 IP。

延續總譜的比喻，每位樂手都有自己的譜號，總譜上寫「小提琴接鋼琴」，樂手看譜號就知道要跟誰合奏，不用另外查對方站在哪裡。

拉回 TaskBoard，資料庫服務叫 db，Spring Boot 的連線字串就直接寫 db 冒號 3306。Compose 內建的 DNS 會自動找到正確的容器。第三章那個 `host.docker.internal`，到這裡終於可以退場了。

很多人會在連線字串寫 localhost，這是錯的。容器裡的 localhost 指的是容器自己，要連別的容器，一定要寫對方的服務名稱。
-->

---

# 完整範例：TaskBoard 三層架構

```yaml
services:
  web:                                   # Angular + nginx
    build: ./taskboard-web
    ports: ["8080:80"]
    depends_on: [api]

  api:                                   # Spring Boot
    build: ./taskboard-api
    ports: ["8081:8080"]
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://db:3306/taskboard
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: apppw
      SPRING_JPA_HIBERNATE_DDL_AUTO: update
    depends_on:
      db: { condition: service_healthy }  # 等 db 真的能連線再啟動
```

<!--
這份就是 TaskBoard 正式的 compose.yaml，之後每天開發都會用它。因為比較長，拆成兩頁，這頁先看 web 和 api。

web 用 `build: ./taskboard-web`，代表用那個目錄的 Dockerfile 現場建構，也就是上一章寫的 Multi-stage 版本，對外開放 8080。

api 是重點。連線字串直接寫 `jdbc:mysql://db:3306/taskboard`，這個 db 就是下一頁那個服務的名稱。注意 port 是 3306 不是 3307，3307 是映射給主機用的，容器之間走內部網路，用的是容器原本的 port。

那些 SPRING 開頭的環境變數，就是第三章講過的設定覆蓋規則。application.yml 完全不用改，換環境只要換 compose 檔。

最後看 depends_on，條件寫的是 `service_healthy`，代表要等 db 真的能連線，才啟動 api。下一頁會看到 db 怎麼回報自己的健康狀態。
-->

---

# 完整範例：TaskBoard 三層架構（續）

```yaml
services:
  # ...（接上頁 web、api）

  db:                                    # MySQL
    image: mysql:8.4
    environment:
      MYSQL_ROOT_PASSWORD: rootpw
      MYSQL_DATABASE: taskboard
      MYSQL_USER: appuser
      MYSQL_PASSWORD: apppw
    volumes:
      - db-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      retries: 10

volumes:
  db-data:
```

<!--
接著看 db 和最下面的 volumes。

db 有兩個重點。第一，資料掛到名為 db-data 的 volume，容器刪掉重建，資料還在，這是第七章的主題。第二是 healthcheck，用 `mysqladmin ping` 每五秒問一次「可以接受連線了嗎」，最多問十次。

回到上一頁的 depends_on。如果只寫服務名稱，Compose 只保證 db 容器啟動了，不保證 MySQL 已經初始化完成。加上 healthcheck 和 `service_healthy` 條件之後，Compose 會等到 db 的健康檢查通過，才啟動 api。這解決了第三章遇到的痛點，API 比資料庫早就緒就啟動失敗。

最下面的 volumes 區塊，要宣告 db-data，Compose 才知道要建立這個 volume。
-->

---

# 使用多容器範例的注意事項

| 情境 | 說明 |
| --- | --- |
| `depends_on` 的限制 | 單純列服務名稱只保證「容器啟動」，不保證 MySQL 已就緒；要搭配 `condition: service_healthy` |
| API 啟動就掛掉 | 先看 `docker compose logs api`，`Communications link failure` 幾乎都是資料庫還沒 ready |
| 環境變數管理密碼 | 正式環境改用 `.env` 檔搭配 `${VAR}`，不要把 `apppw` 寫死在 yaml 進版控 |
| 資料庫資料保存 | 一定要用 `volumes` 掛載 `/var/lib/mysql`，否則 `down -v` 後資料全消失 |
| 改了 Java 沒生效 | `docker compose up -d` 不會自動重 build，要加 `--build` |

> ⚠️ 敏感資訊（像上面範例裡的密碼）直接寫在 compose.yaml 只適合本地開發示範，正式環境請改用 `.env` 檔搭配 `${VAR}` 語法，或 Compose 的 `secrets` 機制。

<!--
這一頁整理多容器範例的幾個實務眉角。

第一個就是剛才講的 depends_on。單純列服務名稱，只保證容器啟動，不保證 MySQL 能連線，一定要搭配 healthcheck。如果 API 啟動就停掉，先看 api 的 log，出現 Communications link failure，幾乎都是資料庫還沒準備好。

第二，密碼直接寫在 compose.yaml 裡，只適合本機開發和教學。正式環境要改用 `.env` 檔，第八章會完整示範。

最後一列要特別提醒寫 Java 的同學。`docker compose up -d` 看到 Image 已經存在，就不會重新 build。改了 Java 再 up，跑的還是舊版程式。改了程式碼，一定要加 `--build`。
-->

---

# 練習題一：任務說明

**難度：基礎**

先把 TaskBoard 的資料庫從 `docker run` 搬進 Compose。請寫一份 `compose.yaml`：

1. 一個叫 `db` 的服務，使用 `mysql:8.4` 映像檔
2. 主機 `3307` 對應到容器 `3306`
3. 帶入四個環境變數：`MYSQL_ROOT_PASSWORD=rootpw`、`MYSQL_DATABASE=taskboard`、`MYSQL_USER=appuser`、`MYSQL_PASSWORD=apppw`
4. `docker compose up -d` 啟動後，用 `docker compose exec db mysql -uappuser -papppw taskboard` 確認能連進去
5. 對照一下：這份 YAML 跟第三章那行又臭又長的 `docker run`，內容其實一模一樣

<!--
接下來是練習一，難度基礎。我們把 TaskBoard 的資料庫從 `docker run` 搬進 Compose。

任務是寫一份只有 db 服務的 compose.yaml，設定 port 映射和四個環境變數，啟動後用 `docker compose exec` 連進資料庫確認。

第五步是這題真正的用意。請大家把這份 YAML 跟第三章那行 `docker run` 逐項對照，想一想：`-p`、`-e` 和 Image 名稱，分別對應到 YAML 的哪個欄位？

我們先暫停一下，自己動手試試看。

【講師】給大家五分鐘動手寫，寫完再看下一頁提示。
-->

---

# 練習題一：解題提示

```yaml
services:
  db:
    image: mysql:8.4
    ports:
      - "3307:3306"
    environment:
      MYSQL_ROOT_PASSWORD: rootpw
      MYSQL_DATABASE: taskboard
      MYSQL_USER: appuser
      MYSQL_PASSWORD: apppw
```

啟動與驗證：

```bash
docker compose up -d
docker compose ps
docker compose logs db | grep "ready for connections"
docker compose exec db mysql -uappuser -papppw taskboard -e "show tables;"
```

<!--
我們來看解答。

回答剛才的問題，`-p` 變成 ports，`-e` 變成 environment，Image 名稱變成 image。Compose 不是新東西，只是把同樣的參數換個地方寫。差別在於寫在檔案裡，可以進版控、可以被 review，新同事 clone 下來就能用。

ports 的寫法是主機 port 在左、容器 port 在右，順序不能顛倒，而且要加引號寫成字串。

下面是啟動和驗證的指令。`docker compose ps` 會看到 db 是 running，log 裡找得到 ready for connections，最後一行 exec 能成功執行 SQL。
-->

---

# 練習題二：任務說明

**難度：進階**

把 TaskBoard 整套三層架構寫成一份 `compose.yaml`：

1. `db` 服務：`mysql:8.4`，資料庫 `taskboard`，資料用 named volume `db-data` 掛在 `/var/lib/mysql`
2. `api` 服務：用 `build: ./taskboard-api` 建置，對外開 `8081:8080`，透過**服務名稱**連線資料庫（不准出現 `localhost` 或 `host.docker.internal`）
3. `web` 服務：用 `build: ./taskboard-web` 建置，對外開 `8080:80`
4. 幫 `db` 加上 healthcheck，並讓 `api` 等到 `db` 健康之後才啟動
5. 驗證：`docker compose logs api` 要看到 Spring Boot 正常啟動、沒有 `Communications link failure`
6. 最後測試持久化：新增一筆任務 → `docker compose down`（不加 `-v`）→ `up -d` → 資料是否還在？

<!--
練習二難度進階，把 TaskBoard 整套三層架構寫成一份 compose.yaml。

這題整合了本章所有重點，build、多服務、用服務名稱連線、healthcheck，還有 volume 持久化。

第二點特別禁止 localhost，這是最多人犯的錯。習慣性把 application.yml 裡的 localhost 照抄過來，API 就會一直連不上。

第六步請大家想一想：新增一筆任務後，`docker compose down` 再 `up`，資料還會在嗎？對照第三章練習二那個「容器一刪資料就沒了」的問題，這次有什麼不同？

我們先暫停一下，自己動手試試看。

【講師】給大家十到十五分鐘，提醒 down 不要加 -v。
-->

---

# 練習題二：解題提示

```yaml
services:
  web:
    build: ./taskboard-web
    ports: ["8080:80"]
    depends_on: [api]
  api:
    build: ./taskboard-api
    ports: ["8081:8080"]
    environment:
      SPRING_DATASOURCE_URL: jdbc:mysql://db:3306/taskboard
      SPRING_DATASOURCE_USERNAME: appuser
      SPRING_DATASOURCE_PASSWORD: apppw
    depends_on:
      db: { condition: service_healthy }
```

<!--
我們來看解答，一樣分兩頁，這頁是 web 和 api。

web 和 api 都用 build 指定目錄，ports 分別是 8080 和 8081。api 的連線字串，主機名稱寫服務名稱 db，port 用容器內部的 3306，完全沒有出現 localhost。

depends_on 用 `service_healthy` 條件，讓 api 等 db 健康之後才啟動。下一頁的 db 就要負責提供這個 healthcheck。
-->

---

# 練習題二：解題提示（續）

```yaml
services:
  # ...（接上頁 web、api）
  db:
    image: mysql:8.4
    environment:
      MYSQL_DATABASE: taskboard
      MYSQL_ROOT_PASSWORD: rootpw
      MYSQL_USER: appuser
      MYSQL_PASSWORD: apppw
    volumes: [db-data:/var/lib/mysql]
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 5s
      retries: 10

volumes:
  db-data:
```

<!--
這頁是 db 和 volumes。

db 加上 healthcheck，資料掛在 db-data 這個 volume 的 `/var/lib/mysql`，最下面宣告 volumes。

回答第六步的問題。因為資料存在 volume 裡，down 不加 `-v` 只會移除容器，volume 還在。重新 up 之後，前端頁面上的任務清單完整還在。這就是跟第三章最大的差別。

有兩個常見錯誤。一是忘記在最下面宣告 db-data，Compose 會直接報錯。二是掛載路徑打錯，MySQL 的資料目錄是 `/var/lib/mysql`，路徑錯了資料一樣不會被保存，而且要到下次重建才會發現。
-->

---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — Docker Compose

<table class="summary-table">
<thead>
<tr><th>主題</th><th>重點回顧</th></tr>
</thead>
<tbody>
<tr><td>compose.yaml</td><td>一份 YAML 檔案定義 services / networks / volumes</td></tr>
<tr><td>版本</td><td>一律用 <code>docker compose</code>（v2 plugin），不用舊版 <code>docker-compose</code></td></tr>
<tr><td>核心指令</td><td><code>up</code>、<code>down</code>、<code>logs</code>，加上 <code>-d</code>、<code>--build</code>、<code>-f</code>、<code>--tail</code> 等參數</td></tr>
<tr><td>服務連線</td><td>同網路下用「服務名稱」互相連線，不用查 IP</td></tr>
<tr><td>資料持久化</td><td>資料庫等狀態要掛 <code>volumes</code>，容器刪掉資料才不會不見</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> Compose 就是那份總譜，一次指揮所有容器（樂手）照著劇本上場，取代逐一手動輸入 <code>docker run</code>。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入網路設定，學習 bridge / host / none 三種模式與自訂 Network。
</div>

<!--
我們回顧一下這一章。

第一，compose.yaml 用一份檔案定義 services、networks、volumes。第二，一律使用新版的 `docker compose`，不用舊版的連字號寫法。第三，核心指令是 up、down、logs，改了程式要記得加 `--build`。第四，同一份 Compose 裡的服務，直接用服務名稱互相連線。第五，資料庫的資料要掛 volume，容器刪掉資料才不會不見。

Compose 就是那份總譜，一次指揮所有容器上場，取代一行一行手動輸入 `docker run`。

下一章，我們會深入網路設定，看看服務名稱連線背後的原理。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
這一章我們把 TaskBoard 三個服務寫進同一份 compose.yaml，從此一行指令就能啟動整套環境。

建議大家把練習二的 compose.yaml 留在專案裡，接下來幾章都會在這份檔案上繼續修改。我們下一章見。

【講師】開放 Q&A，可以引導大家回想 depends_on 加 healthcheck 的用途、down 和 down -v 的差別。
-->
