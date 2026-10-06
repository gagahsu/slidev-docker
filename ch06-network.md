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
    「容器之間的連線、隔離與對外存取」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
【開場白】
本章主題是 Docker 的網路設定。

【問題引導】
多個容器合作時，容器之間如何找到彼此？外部使用者如何連線至容器中的服務？容器又如何連線至外部的資料庫？

【學習目標】
- 區分 bridge、host、none 三種 Network Driver
- 以 -p 對外開放服務，並理解容器間通訊的限制
- 建立自訂網路，以容器名稱互相連線
- 理解 SSDS 的兩條關鍵路徑：容器 → Supabase、瀏覽器 → nginx → api
-->

---
layout: default
---

# Outline

- **Network Driver 種類**
  - bridge / host / none
- **Port Mapping 與容器間通訊**
- **自訂 Network 與 DNS 解析**
- **對外連線與反向代理**
  - 容器 → Supabase、瀏覽器 → nginx → api
- **實作練習**

<!--
【帶讀大綱】
本章分為四個部分：第一部分比較三種網路模式；第二部分說明 -p 與容器間預設的通訊方式；第三部分為本章重點，介紹自訂網路的 DNS 自動解析；第四部分將網路觀念套用至 SSDS：後端連線 Supabase，以及前端 nginx 的反向代理。

【重點預告】
第四部分的兩條路徑，第九章部署至雲端時會再次遇到。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Network Driver 種類

<!--
【段落轉換】
第一部分介紹 Docker 的 Network Driver，它決定容器與外界溝通的方式。
-->

---

# 什麼是 Docker Network？

每個容器各自在獨立的網路空間中執行，未設定網路時彼此無法直接連線。SSDS 的 `ssds-web` 須將 `/api` 轉送至 `ssds-api`，`ssds-api` 須連線雲端的 Supabase，皆仰賴 Docker Network。

Docker 的網路子系統以 **Network Driver（網路驅動程式）** 實作，預設提供以下幾種：

| Driver | 特性 |
| --- | --- |
| `bridge` | 有存取管制的私有網路 |
| `host` | 與主機共用網路，無隔離 |
| `none` | 完全隔離，無對外連線 |

<!--
【情境切入】
SSDS 包含一個 nginx 前端容器、一個 Spring Boot 後端容器，以及位於雲端的 Supabase。未做任何設定時，前後端兩個容器無法以名稱互相連線；第四章因此改用 host.docker.internal 繞經主機。

【生活化比喻】
bridge 如同設有門禁的社區；host 如同與主機共用同一條道路，沒有門禁；none 如同與外界隔絕的孤島。
-->

---

# Network Driver 種類比較

| Driver | 說明 | 適用情境 |
| --- | --- | --- |
| `bridge` | 預設驅動程式，建立獨立的私有網路 | 同一主機上多個容器互相溝通 |
| `host` | 移除容器與主機之間的網路隔離 | 需要最佳網路效能，且可接受共用主機網路 |
| `none` | 完全隔離容器網路 | 不需任何網路的批次任務 |

```bash
# 三種模式的基本語法
docker run --network bridge ssds-api:1.0.0   # 預設，SSDS 使用此模式
docker run --network host   ssds-api:1.0.0   # 直接佔用主機的 8080
docker run --network none   ssds-api:1.0.0   # 無法連線 Supabase，啟動失敗
```

<!--
【重點解說】
- bridge：預設驅動程式。未指定 --network 時，容器即連接至預設的 bridge 網路。
- host：容器直接使用主機的網路，不再擁有獨立 IP；效能最佳，但失去隔離保護。
- none：容器與主機及其他容器完全隔離，沒有對外連線能力，通常用於不需網路的批次運算。

【易錯點提醒 ⚠️】
host 模式在 Linux 上行為最直觀。Docker Desktop（Windows / macOS）自 4.34 版起支援 host 模式，但須於 Settings → Resources → Network 手動啟用，且僅支援 TCP / UDP，行為與 Linux 不完全相同，不建議開發時依賴。
-->

---

# Network Driver — 範例

```bash
# bridge：預設模式，容器取得獨立的私有 IP
docker run -d --name ssds-web nginx:1.30-alpine
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ssds-web
# 172.17.0.2

# host：沒有獨立 IP，Spring Boot 的 8080 即為主機的 8080
docker run -d --network host --env-file .env --name ssds-api ssds-api:1.0.0
# 不需 -p；若本機 IDE 也在使用 8080，則直接衝突

# none：沒有對外網路介面
docker run --rm --network none alpine ip addr
# 只有 loopback 介面 lo
```

<!--
【帶讀關鍵行】
- bridge：容器取得 172.17.0.2 這類私有 IP，此 IP 只存在於 Docker 建立的橋接網路中。主機上的瀏覽器無法直接連線此網段，因此需要 -p。
- host：容器監聽的 8080 即為主機的 8080，不需 -p，沒有 NAT 轉換，效能最佳；但沒有隔離，若 IDE 中已有 Spring Boot 使用 8080 就會衝突。
- none：容器內只有 loopback 介面。若 ssds-api 使用 none 模式，將無法解析 Supabase 網域，HikariPool 出現 UnknownHostException，Spring Boot 啟動失敗。

【補充】
`docker inspect` 範例使用 `.NetworkSettings.Networks` 取得各網路的 IP。舊教學常用的頂層欄位 `.NetworkSettings.IPAddress` 已列為 deprecated，且只反映預設 bridge 網路；容器加入自訂網路時會回傳空值。

【預期結果】
三種模式的網路行為完全不同。SSDS 全程使用 bridge，絕大多數情境也應使用 bridge。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Port Mapping 與容器間通訊

<!--
【段落轉換】
第二部分說明兩個問題：外部使用者如何連線至容器中的服務？容器之間預設能否直接通訊？
-->

---

# 什麼是 Port Mapping？

容器內監聽的 port（例如 80）位於容器自己的網路空間，主機外部無法直接連入。

**Port Mapping（port 映射）** 將主機的 port 轉接至容器內部的 port。以 `-p`（`--publish`）設定後，外部即可經由主機的指定 port 連線至容器內的服務。

<!--
【核心說明】
容器預設對外封閉。即使 nginx 已在容器中監聽 80，主機上開啟瀏覽器連線 localhost 仍無法存取，因為容器的 80 與主機的 80 位於不同的網路空間。-p 即在兩者之間建立轉接。

【業界實務】
部署服務時幾乎都會使用此參數。第九章的雲端平台會自動處理：將外部的 https 443 轉送至容器內指定的 port，只需告知平台容器使用哪個 port。
-->

---

# Port Mapping 的語法結構

| 語法 | 說明 |
| --- | --- |
| `-p 8000:80` | 主機 port:容器 port，所有網路介面皆可連線 |
| `-p 127.0.0.1:8080:8080` | 只綁定主機的 127.0.0.1，限制存取來源 |
| `-P` / `--publish-all` | 將 Dockerfile 中 EXPOSE 的所有 port 隨機映射至主機 |
| `docker port <container>` | 查詢容器目前的 port 映射 |

<!--
【重點解說】
-p 的格式固定為「主機 port : 容器 port」；可在最前方加上主機 IP，限制只接受來自該介面的連線。
-->

---

# Port Mapping — 範例

```bash
# 前端：主機 8000 對應容器 80，同網段的其他電腦也能經由主機 IP 連線
docker run -d -p 8000:80 --name ssds-web ssds-web:1.0.0

# 後端：只允許本機連線（供自己使用 Swagger），外部無法連入
docker run -d -p 127.0.0.1:8080:8080 --env-file .env --name ssds-api ssds-api:1.0.0

# 由 Docker 選擇未被佔用的主機 port（依 Dockerfile 的 EXPOSE 8080）
docker run -d -P --env-file .env --name ssds-api-2 ssds-api:1.0.0

# 查詢實際映射的 port
docker port ssds-api-2
# 8080/tcp -> 0.0.0.0:32768
```

<!--
【帶讀關鍵行】
- 第一段：最常用的寫法，左側為主機、右側為容器。
- 第二段：`-p 8080:8080` 會綁定 0.0.0.0，同一 Wi-Fi 下的任何人都能連線 API；而專案的 SecurityConfig 目前為全部 permitAll。加上 127.0.0.1 前綴後只有本機可連線，Swagger 仍可使用。
- 第三段：大寫 -P 依 Dockerfile 的 EXPOSE 8080 自動選擇可用的主機 port，適合同時執行多個實例；port 為隨機，需以 docker port 查詢。

【易錯點提醒 ⚠️】
主機 port 與容器 port 的順序容易混淆，寫反會導致瀏覽器無法連線。

【預期結果】
第一段執行後，瀏覽器連線 http://localhost:8000 顯示 SSDS 登入畫面。
-->

---

# 容器間通訊的限制

在**預設的 bridge network** 上，容器之間只能以 IP 互相連線，**無法以容器名稱解析**；且容器重新啟動後 IP 可能改變。

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <b>過時做法：</b>早期以 <code>--link</code> 讓容器以名稱溝通，此參數已列為 legacy，不建議使用。現行做法為建立「自訂 bridge network」，容器名稱會自動由 DNS 解析。
</div>

<!--
【問題引導】
若容器皆在預設 bridge 網路上，將 ssds-web 的 API_URL 設為 http://ssds-api:8080，nginx 啟動時會出現 host not found in upstream，容器隨即結束。

【重點提醒】
解決方式為建立自訂的 bridge network，此為下一部分的主題，也是本章最重要的觀念。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 自訂 Network 與 DNS 解析

<!--
【段落轉換】
第三部分說明容器如何以名稱互相連線，而非依賴 IP。此部分為本章重點。
-->

---

# 什麼是自訂 Network？

預設 bridge network 沒有名稱解析，容器只能以 IP 互相連線。

**自訂 Network（User-defined Network）** 是自行建立的網路，連接在同一自訂 bridge network 上的容器，可以名稱或別名互相解析。

容器加入自訂網路後，Docker 以內建的 **DNS Server（127.0.0.11）** 將容器名稱解析為 IP；無法解析的名稱（例如 Supabase 網域）則轉交主機的 DNS 處理。

<!--
【核心說明】
自訂網路中，Docker 內建的 DNS（127.0.0.11）負責將容器名稱轉換為 IP。查詢外部網域（例如 aws-0-ap-south-1.pooler.supabase.com）時，會再轉交主機的 DNS，因此對外連線不受影響。

【生活化比喻】
以往拜訪朋友必須記住門牌座標；社區設置電子門牌系統後，只需輸入姓名即可導引至對方住處。

【業界實務】
多個容器需要合作的專案，幾乎都使用自訂網路，此為標準做法。
-->

---

# 自訂 Network 的語法結構

| 指令 | 說明 |
| --- | --- |
| `docker network create <name>` | 建立自訂 bridge 網路 |
| `docker network create -d bridge <name>` | 明確指定 bridge 驅動 |
| `docker run --network <name> ...` | 啟動容器時加入指定網路 |
| `docker network connect <name> <container>` | 將既有容器加入網路 |
| `docker network inspect <name>` | 查看網路設定與已加入的容器 |
| `docker network ls` / `rm <name>` | 列出 / 刪除網路 |

<!--
【重點解說】
建立網路後，以 --network 讓容器加入；已啟動的容器可用 network connect 加入。network inspect 可確認哪些容器在網路中，是排查連線問題的常用指令。
-->

---

# 自訂 Network — 範例

```bash
# 1. 建立 SSDS 專用網路
docker network create ssds-net

# 2. 後端加入網路，不對外開放 port（只供 nginx 由內部連線）
docker run -d --network ssds-net --name ssds-api --env-file .env ssds-api:1.0.0

# 3. 前端加入同一網路，API_URL 使用容器名稱
docker run -d --network ssds-net -p 8000:80 --name ssds-web \
  -e API_URL=http://ssds-api:8080 \
  ssds-web:1.0.0

# 4. 驗證 DNS 解析
docker exec ssds-web nslookup ssds-api
# Name:    ssds-api
# Address: 172.18.0.2
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>對照第四章：</b>先前預設 <code>API_URL=http://host.docker.internal:8080</code>（由容器繞至主機，再經 <code>-p</code> 回到容器）；改用自訂網路後直接寫 <code>ssds-api:8080</code>，容器對容器走內部網路，api 不需設定 <code>-p</code>。
</div>

<!--
【帶讀關鍵行】
- 第 1 步：建立 ssds-net 網路。
- 第 2 步：後端加入網路且未設定 -p。nginx 由網路內部連線，不需經過主機；後端不對外暴露，使用者只能透過前端的 /api 路徑存取。
- 第 3 步：API_URL 由 `http://host.docker.internal:8080` 改為 `http://ssds-api:8080`，主機名稱改為容器名稱。
- 第 4 步：nslookup 回傳 IP，表示 Docker 內建 DNS 已成功解析 ssds-api。

【易錯點提醒 ⚠️】
- 8080 是容器內 Spring Boot 監聽的 port。容器對容器走內部網路，不經過 -p 映射，因此一律使用容器內的 port。即使第 2 步使用了 -p 9090:8080，API_URL 仍應寫 8080。
- 兩個容器必須位於同一個自訂網路才能互相解析。
-->

---

# 自訂 Network 的注意事項

| 項目 | 說明 |
| --- | --- |
| `--link` | 已列為 legacy，一律改用自訂 bridge network |
| 隔離性 | 只有同一自訂網路中的容器能互相通訊，不同網路預設隔離 |
| 啟動順序 | nginx 啟動時即解析 `proxy_pass` 的主機名稱，**ssds-api 須先存在**，否則出現 `host not found in upstream` 並結束 |
| 與 Compose 的關係 | 第五章 `API_URL: http://api:8080` 能夠連通，是因為 Compose 自動建立自訂網路並將所有服務加入 |

<!--
【重點解說】
- 自訂網路的隔離性優於預設網路，不相關的服務不會意外互相連線。
- nginx 在啟動時解析 proxy_pass 的主機名稱，解析失敗即無法啟動。手動 docker run 時須先啟動 ssds-api 再啟動 ssds-web；Compose 中以 depends_on 確保順序。

【回顧】
第五章使用 Compose 時，API_URL 直接寫 api 即可連通，原因即在此：Compose 自動執行 docker network create，並將所有服務加入該網路。Compose 只是將本章手動執行的指令封裝起來。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 對外連線與反向代理

<!--
【段落轉換】
第四部分將網路觀念套用至 SSDS 的兩條關鍵路徑：
1. ssds-api 容器對外連線至 Supabase
2. 瀏覽器連線至 ssds-web，nginx 再將 /api 轉送至 ssds-api

第九章部署至雲端時，問題多半出現在這兩條路徑上。
-->

---
zoom: 0.95
---

# 容器 → Supabase：對外連線

容器預設**可直接連線網際網路**（bridge 網路提供 NAT），`ssds-api` 只需環境變數即可連線 Supabase：

```bash
# 在容器內測試 DNS 與 TCP 連線（alpine 內建 busybox 的 nslookup / nc）
docker exec ssds-api nslookup aws-0-ap-south-1.pooler.supabase.com
docker exec ssds-api nc -zv -w 3 aws-0-ap-south-1.pooler.supabase.com 6543
```

| Supabase 連線方式 | Host 範例 | Port | IPv4 | 本專案用途 |
| --- | --- | --- | --- | --- |
| Direct connection | `db.<ref>.supabase.co` | 5432 | ❌ 僅 IPv6（IPv4 需付費加購） | 不使用 |
| Transaction pooler | `aws-0-<region>.pooler.supabase.com` | **6543** | ✅ | 應用程式（`SSDS_DB_PORT`） |
| Session pooler | `aws-0-<region>.pooler.supabase.com` | 5432 | ✅ | Flyway migration |

<!--
【核心說明】
bridge 網路提供 NAT，容器預設即可對外連線。ssds-api 讀取 SSDS_DB_HOST、SSDS_DB_PORT 後即可連線 Supabase，不需額外網路設定。

【易錯點提醒 ⚠️】
Supabase 的 Direct connection（db.xxx.supabase.co）預設只有 IPv6 位址。Docker Desktop 的預設網路與多數免費雲端平台（包含第九章的 Render）對外只支援 IPv4，使用 direct connection 會出現 Network is unreachable 或 UnknownHost 等錯誤。SSDS_DB_HOST 必須使用 pooler 網址。

【重點解說】
專案的 application.properties 已設定使用 pooler：應用程式使用 6543 的 transaction pooler，Flyway 使用 5432 的 session pooler，兩者皆支援 IPv4。Flyway 不能使用 6543 的原因（advisory lock）記載於專案註解中。

【補充】
pooler 主機名稱的前綴（aws-0 或 aws-1）依專案建立時間而異，請以 Supabase 後台 Connect 畫面顯示的網址為準。

【操作提示】
nc -zv 用於測試 TCP 連線，顯示 open 即表示網路可達；此後若仍無法連線，問題在於帳號密碼而非網路。
-->

---

# 瀏覽器 → nginx → api：反向代理

SSDS 前端的 `environment.prod.ts` 設定 `apiBaseUrl: '/api/v1'`（**相對路徑**），請求流程如下：

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
💡 <b>為何不讓瀏覽器直接呼叫後端？</b>後端 <code>SecurityConfig</code> 的 CORS 白名單只有 <code>localhost:4200</code>。透過反向代理，瀏覽器只面對單一網域，<b>不需修改 CORS 設定</b>，本機、Compose、雲端皆相同。
</div>

<!--
【核心說明】
environment.prod.ts 的 apiBaseUrl 為 /api/v1，不含網域，因此 production build 的網頁會將 API 請求送回自身網域。ssds-web 容器中的 nginx 負責將 /api 開頭的請求轉送至後端，即為反向代理。

【重點解說】
proxy_pass 的斜線規則：
- proxy_pass 只有「協定 + 主機 + port」而無路徑時，請求的 URI 原樣轉送。瀏覽器請求 /api/v1/products，後端即收到 /api/v1/products，與 context-path 相符。
- proxy_pass 帶有路徑時（即使只是一個斜線），nginx 會將 location 比對到的 /api/ 替換為該路徑，後端收到 /v1/products，全部回傳 404。

【易錯點提醒 ⚠️】
從雲端平台複製後端網址時常多帶結尾斜線。API_URL 一律不加結尾斜線。

【業界實務】
若讓瀏覽器直接呼叫後端網址，部署至雲端後網域改變，請求會被 CORS 阻擋，必須修改後端程式並重新部署。透過反向代理，瀏覽器始終只與單一網域溝通，不會觸發 CORS。
-->

---
layout: default
---

# 練習 1：讓 web 以名稱連線 api
### 任務說明

以自訂網路取代第四章的 `host.docker.internal`，並將後端隱藏於內部網路：

1. 建立名為 `ssds-net` 的自訂網路
2. 啟動 `ssds-api`（帶入 `--env-file .env`）並加入此網路，**不設定 `-p`**
3. 啟動 `ssds-web` 加入同一網路，設定 `-p 8000:80`，以 `-e API_URL=...` 指向 api 的**容器名稱**
4. 以 `docker exec` 驗證 web 容器可解析 `ssds-api`
5. 驗證：`http://localhost:8000` 可登入並載入資料；`http://localhost:8080/api/v1/actuator/health` **應無法連線**

<!--
【任務鋪陳】
本題練習建立網路、加入容器與以名稱連線。

【出題動機】
- 第 2 點刻意不設定 -p，體會後端不對主機暴露也能被前端使用。
- 第 5 點包含兩項驗證：前端可用表示反向代理正常；直接連線 8080 失敗表示後端已隱藏，系統只有單一入口。
-->

---
layout: default
---

# 練習 1：參考答案

```bash
# 清除先前同名容器
docker rm -f ssds-api ssds-web

# 1. 建立網路
docker network create ssds-net

# 2. 後端加入網路，不設定 -p
docker run -d --network ssds-net --name ssds-api \
  --env-file ai-products-selection-backend/.env ssds-api:1.0.0
docker logs -f ssds-api            # 等到 Started SsdsApplication 後按 Ctrl+C

# 3. 前端加入同一網路
docker run -d --network ssds-net -p 8000:80 --name ssds-web \
  -e API_URL=http://ssds-api:8080 ssds-web:1.0.0

# 4. 驗證 DNS 解析
docker exec ssds-web nslookup ssds-api          # 回傳 172.18.x.x

# 5. 驗證：前端可用、後端未對外
curl -s http://localhost:8000/api/v1/actuator/health   # {"status":"UP"}
curl -s http://localhost:8080/api/v1/actuator/health   # 連線失敗
```

<!--
【帶讀解法】
第 5 步的第一行經由 nginx 反向代理取得健康狀態，證明 web → api 路徑正常；第二行直接連線主機 8080 失敗，證明後端未對外開放。

【易錯點提醒 ⚠️】
- 兩個容器都必須加上 `--network ssds-net`。遺漏任一個，容器會連接至預設網路，nginx 出現 `host not found in upstream "ssds-api"` 並結束；可用 `docker network inspect ssds-net` 確認已加入的容器。
- API_URL 結尾不可加斜線，否則所有 API 回傳 404。
-->

---
layout: default
---

# 練習 2：網路除錯演練
### 任務說明

刻意製造三種錯誤，練習由外而內逐層定位問題：

1. 將 `ssds-web` 的 `API_URL` 改為 `http://localhost:8080` 並重新啟動 → 瀏覽器出現什麼錯誤？`docker logs ssds-web` 顯示什麼？
2. 將 `API_URL` 改為 `http://ssds-api:8080/`（多一個斜線）→ 前端出現什麼狀況？`docker logs ssds-api` 是否收到請求？
3. 將後端 `.env` 的 `SSDS_DB_HOST` 暫時改為 direct connection 網址 `db.<ref>.supabase.co`、`SSDS_DB_PORT=5432` → `docker logs ssds-api` 顯示什麼錯誤？
4. 以 `docker exec ssds-api nslookup` / `nc -zv` 分別測試 pooler 與 direct 網址，比較結果
5. 全部改回正確設定，確認系統恢復正常

<!--
【任務鋪陳】
本題為本章的整合題，三種錯誤皆為第九章雲端部署最常見的問題，先於本機觀察症狀。

【易錯點提醒 ⚠️】
修改 .env 前請先備份，完成後務必還原，否則後續章節將無法連線。
-->

---
layout: default
zoom: 0.88
---

# 練習 2：參考答案

| 故障 | 瀏覽器症狀 | 檢查位置 | 關鍵訊息 |
| --- | --- | --- | --- |
| `API_URL=http://localhost:8080` | 502 Bad Gateway | `docker logs ssds-web` | `connect() failed (111: Connection refused)` |
| `API_URL` 多結尾斜線 | API 全部 404 | `docker logs ssds-api` | 收到的路徑為 `/v1/...`，缺少 `/api` |
| 使用 direct connection | 502；api 持續重啟或 unhealthy | `docker logs ssds-api` | `Network is unreachable` / `UnknownHostException` |

```bash
# 1. 重建 web：localhost 指向 nginx 自身
docker rm -f ssds-web
docker run -d --network ssds-net -p 8000:80 --name ssds-web \
  -e API_URL=http://localhost:8080 ssds-web:1.0.0

# 4. 比較兩種網址
docker exec ssds-api nslookup db.<ref>.supabase.co          # 只有 IPv6（AAAA）
docker exec ssds-api nslookup aws-0-ap-south-1.pooler.supabase.com   # 有 IPv4
docker exec ssds-api nc -zv -w 3 aws-0-ap-south-1.pooler.supabase.com 6543   # open
```

<div class="mt-2 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>除錯順序：</b>瀏覽器 DevTools 查看 HTTP 狀態碼 → <code>docker logs ssds-web</code> 確認 nginx 是否轉送 → <code>docker logs ssds-api</code> 確認後端是否收到請求、是否連上 Supabase。
</div>

<!--
【帶讀解法】
- 第 1 題：localhost 在 nginx 容器中指向自身，8080 沒有程式監聽，因此回傳 502。
- 第 2 題：多出的斜線使後端收到的路徑缺少 /api，後端 log 中可看到請求確實送達，只是路徑錯誤。
- 第 3 題：direct connection 只有 IPv6，Docker Desktop 預設不具 IPv6 對外能力，api 無法啟動。
- 第 4 題：direct 網址只回傳 IPv6（AAAA）位址；pooler 網址回傳 IPv4。

【重點提醒】
第九章雲端部署發生問題時，症狀與本表幾乎相同，只是 docker logs 改為雲端平台的 Logs 頁面。

【核心說明】
HTTP 狀態碼判讀：502 表示 nginx 無法連線後端；404 表示已連線但路徑錯誤；500 表示後端程式本身發生錯誤。由最接近使用者的一層開始逐層往內檢查，即可定位問題。
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
<tr><td>bridge / host / none</td><td>預設的隔離私有網路 / 共用主機網路 / 完全無網路</td></tr>
<tr><td>Port Mapping</td><td><code>-p 主機port:容器port</code>；容器對容器一律使用容器內的 port</td></tr>
<tr><td>自訂 Network</td><td>內建 DNS（127.0.0.11），以容器名稱互連，取代過時的 <code>--link</code></td></tr>
<tr><td>連線 Supabase</td><td>容器預設可對外連線；一律使用 <b>pooler（IPv4）</b>，不使用 direct connection（IPv6）</td></tr>
<tr><td>反向代理</td><td>nginx 將 <code>/api/</code> 轉送至後端，同網域免 CORS；<code>API_URL</code> 不加結尾斜線</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b>Volume 資料持久化 — 讓使用者上傳的商品圖片在容器刪除後仍然保留。
</div>

<!--
【回顧】
- 三種基本網路模式：bridge（預設）、host（共用主機）、none（完全隔離）。
- -p 用於對外開放服務，格式為「主機 port : 容器 port」；容器之間互連不經過 -p，使用容器內的 port。
- 預設網路不提供名稱解析；自訂網路提供，可直接以容器名稱互連，Compose 自動完成此設定。
- 連線 Supabase 必須使用 pooler 網址（IPv4）；反向代理使前後端同網域而免除 CORS，API_URL 不可有結尾斜線。

【課程預覽】
下一章處理第三章留下的問題：上傳的圖片如何不隨容器刪除而消失。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
【互動引導】
開放提問：bridge / host / none、port mapping、自訂網路的 DNS 解析、反向代理或 Supabase 連線，有任何疑問皆可提出。
-->
