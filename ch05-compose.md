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
歡迎大家來到第五章，Docker Compose。前面幾章我們學會了用 docker run 操作單一容器，但真實的應用往往不會只有一個容器，這章就是要解決「同時管理很多容器」這件麻煩事。
-->

---
layout: default
---

# Outline

- **第一部分**：compose.yaml 語法結構
- **第二部分**：docker compose 指令
- **第三部分**：多容器應用範例（web + db）
- **練習題**：從簡單到進階
- **總結**

<!--
今天的路線圖：先搞懂 compose.yaml 怎麼寫，再學怎麼用指令操作它，最後動手做一個 web 加資料庫的完整範例，中間穿插兩題練習讓大家實際動手。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第一部分
# compose.yaml 語法結構

<!--
先從設定檔本身開始，這是 Compose 的核心，之後所有指令都是圍繞這份檔案在動作。
-->

---

# 為什麼需要 Docker Compose？

- TaskBoard 光是跑起來就要三個容器：`taskboard-web`、`taskboard-api`、`taskboard-db`，而且彼此要能互相溝通
- 第三章我們用 `docker run` 逐一啟動，那三行指令加起來十幾個參數，還得記得先起資料庫、再起 API，新同事第一天就要照抄一整頁 README
- Docker Compose：「**define and manage multi-container apps in one YAML file, streamlining orchestration**」——用一份 YAML 檔案定義並管理多容器應用
- 比喻：Compose 如同「**樂團總譜**」，一次定義每個容器（樂手）用什麼映像檔（樂器）、跟誰同網路（合奏），再用 `docker compose` 指令統一啟動

<!--
這頁是動機頁，重點是讓大家有共鳴：手動 docker run 管理多容器很痛。

請大家回想第三章那三行 docker run，每一行都又臭又長，還有那個醜醜的 host.docker.internal。而且真實情況更慘：新人報到，你要他把三行指令照順序打對，中間 MySQL 還要等它初始化完，API 太早起來會連不上就掛掉，他就得再 docker start 一次。

這章之後，這一切變成一個指令：docker compose up -d。新人 clone 完專案打這一行，整套環境就起來了。

生活比喻就是樂團總譜，一份譜勝過口頭一個一個交代。
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
這頁把命名跟版本差異講清楚。⚠️ 版本注意：docker compose（v2，內建 plugin）vs docker-compose（v1，獨立執行檔，已經停止維護）。易錯點是很多人複製貼上舊文章的指令會噴「command not found」，因為系統上沒裝 v1 的 docker-compose 執行檔。檔名部分，compose.yaml 是新推薦寫法，但舊專案的 docker-compose.yml 完全相容，不用急著改名。
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
這頁介紹 compose.yaml 的三大區塊：services、networks、volumes。

重點是 services 底下的 key（例如接下來範例裡的 web 跟 db）之後會變成容器互相連線的主機名稱，這是 Compose 網路的核心概念，大家先有印象，第三部分會實際用到。
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
這頁給一個最小可跑的骨架，對照剛剛講的三大區塊：三個 service、一個 network、一個 volume。

這份還很陽春，API 還沒有連線設定、資料也還沒真的持久化，我們第三部分會把它補完整。先讓大家看到 TaskBoard 三個服務並排在同一份檔案裡的樣子。

⚠️ 易錯點：YAML 對縮排非常敏感，縮排一定要用空格不能用 tab，層級錯一格整份檔案就解析失敗。
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
這頁純粹補基本功，因為很多同學是第一次接觸 YAML。生活比喻：YAML 就像整理衣櫃分層放，同一層要對齊，亂放（縮排錯）東西就找不到。易錯點 ⚠️ 已經標在頁面上：Tab 縮排跟冒號少空格是最常見兩個錯誤，出錯訊息通常會直接告訴我們是第幾行。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第二部分
# docker compose 指令

<!--
設定檔寫好了，接下來就是怎麼用指令去操作它，這部分跟我們之前學的 docker 指令邏輯很像，只是操作對象從單一容器變成整份 compose.yaml 裡的所有服務。
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
這兩頁一組，先表格再範例。重點指令是 up / down / logs，這也是這章大綱要求的核心。

請大家特別記住 `docker compose up -d --build api` 這一行，這是容器化開發的日常節奏：改完 Controller、存檔、打這一行，Compose 只會重 build 跟重啟 api 這個服務，資料庫跟前端完全不動，也不會斷線。比起 `down` 再 `up` 整套快非常多。

`docker compose exec db mysql ...` 也很好用，注意它接的是「服務名稱 db」，不是容器全名。Compose 會自動幫容器加上專案名稱前綴（例如 taskboard-db-1），用 docker exec 就得打全名，用 compose exec 打 db 就好。

易錯點 ⚠️：docker compose down 預設不會刪除 volume，資料庫的資料還在，這是刻意設計避免誤刪資料；真的要清空重來才加 -v。生活比喻：down 就像「謝幕」，樂手（容器）先下台，但樂器（volume）還放在後台沒被丟掉，除非我們明確說要清場（-v）。
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
這頁整理常見的踩雷情境，讓大家遇到問題時知道第一步該查什麼。⚠️ 版本注意再次強調，因為這是這門課特別要求釘死的重點：一律用 docker compose（v2），避免大家去抄網路上舊教學的 docker-compose 指令而卡住。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第三部分
# 多容器應用範例（web + db）

<!--
現在把前面學的語法跟指令串起來，做一個最貼近實務的範例：一個網站服務加一個資料庫服務，這也是 Compose 最經典的應用場景。
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
這頁是這一部分最重要的觀念：service 名稱就是 DNS 名稱。生活比喻延續樂團總譜，每個樂手（容器）都有自己的譜號（服務名稱），總譜上寫「小提琴呼應鋼琴」，樂手之間看譜號就知道要跟誰合奏，不用另外查對方站在哪裡（IP）。易錯點 ⚠️：很多新手會在連線字串裡寫 localhost 或 127.0.0.1，這是錯的，因為那是「容器自己」，要連別的容器一定要寫對方的 service 名稱。
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
這份就是 TaskBoard 的正式 compose.yaml，大家之後每天開發都會用它。我們一個服務一個服務看。

web 用 `build: ./taskboard-web`，代表拿那個目錄的 Dockerfile 現場建置，就是第四章我們寫的那份 multi-stage。對外開 8080。

api 是重點。連線字串直接寫 `jdbc:mysql://db:3306/taskboard`，這裡的 db 就是下面那個 service 的名稱，Compose 的內建 DNS 會解析。而且注意 port 是 3306 不是 3307——3307 是我們映射給「主機」用的，容器之間走內部網路，用的是容器原本的 port。這個觀念第六章會再深入。

那些 SPRING_ 開頭的環境變數，就是第三章講過的 Spring Boot 設定覆蓋規則。整份 application.yml 都不用改，換環境只換 compose 檔。

db 的兩個重點：資料掛到 named volume db-data，容器刪掉重建資料還在（第七章主題）；還有 healthcheck，用 mysqladmin ping 每五秒問一次「你能接受連線了嗎」，最多問十次。

然後看 api 的 depends_on 寫法：`condition: service_healthy`。這一行解決了大家在第三章遇到的痛點——API 比資料庫早就緒就會啟動失敗。加上這個條件之後，Compose 會乖乖等到 db 的 healthcheck 通過才啟動 api。這是新版 Compose 才有的寫法，比舊版單純列服務名稱可靠太多。
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
這頁補強實務眉角。

⚠️ 易錯點一：depends_on 如果只寫服務名稱，它只管「容器有沒有啟動」，不管「MySQL 有沒有準備好接受連線」。MySQL 容器啟動了不代表能連，中間還有十幾秒的初始化。Spring Boot 一連不上就直接啟動失敗退出，這是大家最常遇到的狀況。解法就是我們範例裡的 healthcheck 加 condition: service_healthy。

⚠️ 易錯點二：密碼直接寫在 yaml 裡只適合教學跟本機開發，實務上要搬到 .env，第八章會完整示範。

⚠️ 易錯點三特別提醒 Java 同學：`docker compose up -d` 看到 image 已經存在就不會重 build，所以你改了 Java 檔重新 up，跑的還是舊版程式，然後就開始懷疑人生。改了程式碼一定要加 --build。
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
第一題基礎，練習 services 底下常用欄位跟 ports 映射的寫法。

第 5 步是這題真正的用意：讓大家自己把第三章那行 docker run 跟這份 YAML 逐項對照——-p 變成 ports、-e 變成 environment、image 名稱變成 image。Compose 不是新東西，只是把同樣的參數換個地方寫，而且寫在檔案裡可以進版控、可以被 review、新人 clone 下來就能用。

給大家一點時間動手寫，寫完再看下一頁提示。
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
提示頁給完整解答，重點提醒 ports 的寫法是「主機 port : 容器 port」，順序不能顛倒。

⚠️ 易錯點一：有人會把 3307:3306 寫反成 3306:3307，結果 GUI 工具連 3307 連不上。⚠️ 易錯點二：ports 的值一定要加引號寫成字串，因為 YAML 會把沒引號的 `3307:3306` 當成六十進位數字解析，這是 YAML 的經典陷阱。

預期結果：compose ps 顯示 db 是 running，exec 能進去下 SQL。
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
第二題整合本章所有重點：build、多服務、服務名稱連線、healthcheck、volume 持久化。

第 2 點我特別禁止 localhost，因為這是最多人犯的錯：習慣性把 application.yml 的 localhost 照抄進來，然後 API 一直連不上，因為容器裡的 localhost 是容器自己。

第 6 點是留給第七章的伏筆，也是驗收：對照第三章練習 2 那個「容器一刪資料就沒了」的痛點，現在掛了 volume 之後，整套 down 掉再 up 起來，任務資料還在。有掛跟沒掛的差別，做過一次就永遠記得。
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
提示頁對照第三部分的完整範例，重點複習三件事：連線字串的 host 寫服務名稱 db 而且 port 用 3306；volume 掛在 MySQL 的資料目錄 /var/lib/mysql；down 不加 -v 資料才會保留。

⚠️ 易錯點：忘記在檔案最下面加 volumes 區塊宣告 db-data，Compose 會直接報錯說找不到這個 volume。另一個是掛載路徑打錯——MySQL 是 /var/lib/mysql，PostgreSQL 才是 /var/lib/postgresql/data，抄錯的話資料一樣不會被保存，而且要到下次重建才發現。

預期結果：第 6 步 down 再 up 之後，前端頁面上的任務清單完整還在。
-->

---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — Docker Compose

<table class="summary-table">
<tr><th>主題</th><th>重點回顧</th></tr>
<tr><td>compose.yaml</td><td>一份 YAML 檔案定義 services / networks / volumes</td></tr>
<tr><td>版本</td><td>一律用 <code>docker compose</code>（v2 plugin），不用舊版 <code>docker-compose</code></td></tr>
<tr><td>核心指令</td><td><code>up</code>、<code>down</code>、<code>logs</code>，加上 <code>-d</code>、<code>--build</code>、<code>-f</code>、<code>--tail</code> 等參數</td></tr>
<tr><td>服務連線</td><td>同網路下用「服務名稱」互相連線，不用查 IP</td></tr>
<tr><td>資料持久化</td><td>資料庫等狀態要掛 <code>volumes</code>，容器刪掉資料才不會不見</td></tr>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> Compose 就是那份總譜，一次指揮所有容器（樂手）照著劇本上場，取代逐一手動輸入 <code>docker run</code>。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入網路設定，學習 bridge / host / none 三種模式與自訂 Network。
</div>

<!--
總結這一章：Compose 解決的核心痛點是「多容器協作」，我們學了 YAML 語法、compose.yaml 三大區塊、核心指令 up/down/logs，也做了一個完整 web+db 範例並練習了兩題。下一章會接著談網路設定的細節，跟今天服務之間怎麼互相連線會有更深入的討論。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對 compose.yaml 的語法結構、up/down/logs 這些指令，或是多容器連線的方式，有沒有什麼疑問？都歡迎提出來討論。
-->
