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
    「讓資料的生命週期獨立於容器」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
【開場白】
本章主題是 Volume 資料持久化。

【問題引導】
容器中儲存了重要資料，容器被刪除後，這些資料會如何？答案是全部消失。

【學習目標】
- 區分 Volume、Bind Mount、tmpfs 三種掛載方式
- 以 docker volume 指令管理 Volume
- 以臨時容器備份與還原 Volume，並以容器執行 pg_dump 備份 Supabase
-->

---
layout: default
---

# Outline

- **為什麼容器需要外部儲存**
  - SSDS 的商品圖片存放在何處？
- **Volume vs Bind Mount vs tmpfs**
- **docker volume 指令**
- **資料備份與還原**
  - Volume 以 tar 備份、Supabase 以容器執行 pg_dump
- **實作練習**

<!--
【帶讀大綱】
本章分為三個部分：第一部分說明為何需要外部儲存，並比較三種掛載方式；第二部分操作 docker volume 指令；第三部分實作 Volume 的備份與還原，並示範「以容器作為免安裝工具」執行 pg_dump。

【重點預告】
最後兩題練習皆直接在 SSDS 上進行。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Volume vs Bind Mount vs tmpfs

<!--
【段落轉換】
第一部分介紹 Docker 提供的三種掛載方式。
-->

---

# 容器刪除後，資料在哪裡？

容器的檔案系統（可寫層）會隨容器一起刪除。

- SSDS 的資料庫位於 Supabase，容器刪除後**資料表不受影響** ✅
- 商品圖片寫在容器內的 `./uploads/product`（工作目錄 `/app` → `/app/uploads/product`）❌
- 資料庫記錄的是圖片的**相對路徑**；容器重建後檔案不存在，前端顯示破圖

```properties
# application.properties（專案既有設定）
ssds.product-image.storage-path=${SSDS_PRODUCT_IMAGE_STORAGE_PATH:./uploads/product}
ssds.import.staging-path=${IMPORT_STAGING_PATH:./uploads/import-staging}
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>回顧第三章練習 2、第五章練習 2：</b>上傳商品圖片後執行 <code>docker compose down</code> 再 <code>up</code>，圖片即消失。本章解決此問題。
</div>

<!--
【回顧】
第五章最後的問題：上傳商品圖片後 down 再 up，商品資料仍在，但圖片變成破圖。

【核心說明】
資料庫位於 Supabase，與容器無關，因此商品資料與圖片「紀錄」都保留；但圖片「檔案本體」由 Spring Boot 寫入容器自身的檔案系統。容器刪除後，可寫層（writable layer）直接消失，無法復原。

專案 application.properties 的這兩行設定已預留此問題的解法，註解寫明「正式環境應以 SSDS_PRODUCT_IMAGE_STORAGE_PATH 指向持久化 volume」。本章即補上此設定。

【生活化比喻】
容器如同臨時搭建的房屋，隨時可能拆除；貴重物品若放在屋內，房屋拆除後物品也一併消失。
-->

---
layout: default
---

# 什麼是 Volume？

**Volume（資料卷）** 是由 Docker 建立與管理的持久化儲存空間，生命週期獨立於容器。容器刪除後 Volume 仍保留，可掛載至新容器繼續使用。

```bash
docker volume create ssds-uploads
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  -v ssds-uploads:/app/uploads \
  ssds-api:1.0.0
```

Volume 的實際存放位置由 Docker 管理，使用者透過 `docker volume` 指令操作即可。

<!--
【核心說明】
Volume 是 Docker 官方建議的持久化方式，需要長期保存的資料幾乎都使用 Volume。

【生活化比喻】
容器是可能隨時拆除重建的房屋，Volume 是另外租用的倉庫；房屋拆除後倉庫仍在，新建的房屋可以繼續使用同一個倉庫。

【帶讀關鍵行】
範例建立名為 ssds-uploads 的 Volume，掛載至容器的 /app/uploads。選擇 /app/uploads 而非 /app/uploads/product，是因為商品圖片與 Excel 匯入暫存檔都在 uploads 之下，一個 Volume 即可同時保護。

【易錯點提醒 ⚠️】
第四章 Dockerfile 中的 `mkdir -p /app/uploads && chown -R app:app /app` 在此發揮作用：空的 Volume 首次掛載時，Docker 會將 Image 中同路徑的內容（含擁有者權限）複製進 Volume。Image 中 /app/uploads 屬於 app 使用者，Volume 也就屬於 app，Spring Boot 才能寫入。若 Dockerfile 未預先建立此目錄，Volume 將屬於 root，以非 root 身分執行的 Spring Boot 寫入圖片時會出現 Permission denied。
-->

---
layout: default
---

# 什麼是 Bind Mount？

**Bind Mount（綁定掛載）** 將主機上既有的檔案或目錄直接掛載至容器，容器存取的即為主機上的原始資料。

```bash
# 修改 nginx 設定不需重新建置：將本機 nginx/ 以唯讀方式掛入，修改後 docker restart 即生效
docker run -d --name ssds-web -p 8000:80 \
  --mount type=bind,src="${PWD}/nginx",dst=/etc/nginx/templates,readonly \
  ssds-web:1.0.0

# 將上傳目錄掛載至本機資料夾，可直接以檔案總管檢視圖片
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  --mount type=bind,source="${PWD}/uploads",target=/app/uploads \
  ssds-api:1.0.0
```

常見用途：掛載設定檔、開發用原始碼、將容器產生的檔案取出至本機。第三章以 `-v .../build/libs:/jar:ro` 提供 jar 給容器，也是 bind mount。

<!--
【核心說明】
Bind Mount 與 Volume 最大的差異：Bind Mount 掛載的是主機上原本就存在的路徑，而非由 Docker 建立管理的空間。

【帶讀關鍵行】
- 第一個範例：調整 nginx 設定時，每次重新建置前端 Image 需數分鐘。以 bind mount 掛入 template 檔，修改後執行 docker restart ssds-web，數秒即可生效；確認無誤後再建置進 Image。readonly 確保容器內的程式無法修改專案檔案。
- 第二個範例：將上傳目錄掛載至本機，可直接檢視上傳的圖片，方便開發除錯。

【易錯點提醒 ⚠️】
- Windows：PowerShell 使用 ${PWD}；Git Bash 可能將路徑轉換為錯誤格式，此時改用 PowerShell 或完整的 C:/... 路徑。Windows 檔案經 Docker Desktop 掛入 Linux 容器時，大量小檔案的存取效能低於 Volume。
- Bind Mount 預設可寫入，容器內的程式若誤刪檔案會直接影響主機，敏感目錄應加上 readonly 或 ro。
-->

---
layout: default
---

# 什麼是 tmpfs？

**tmpfs mount** 將資料存放於主機記憶體，不寫入任何檔案系統；容器停止後資料即消失。

```bash
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  -v ssds-uploads:/app/uploads \
  --mount type=tmpfs,destination=/tmp \
  ssds-api:1.0.0
```

- 適用於暫存資料：上傳過程中的 multipart 暫存檔、快取
- 僅支援 Linux 容器
- 寫入速度快但不持久，為與 Volume、Bind Mount 最本質的差異

<!--
【生活化比喻】
tmpfs 如同便利貼：書寫快速方便，但撕下後（容器停止）內容即消失。

【帶讀關鍵行】
範例將 tmpfs 掛載至 /tmp。Spring Boot 處理檔案上傳時，multipart 暫存檔預設寫入 java.io.tmpdir（即 /tmp）。此類資料寫入後隨即處理完畢，存放於記憶體速度最快，且容器停止後自動清空。

【易錯點提醒 ⚠️】
tmpfs 使用的是記憶體。專案匯入檔上限 50MB，多人同時上傳大型檔案時會佔用大量記憶體；第九章免費雲端方案只有 512MB，不建議使用。
-->

---
layout: default
---

# Volume vs Bind Mount vs tmpfs 比較

| 比較項目 | Volume | Bind Mount | tmpfs |
| --- | --- | --- | --- |
| 儲存位置 | Docker 管理的主機目錄 | 主機上任意指定路徑 | 主機記憶體 |
| 管理方式 | `docker volume` 指令 | 主機檔案系統 | 隨容器生命週期 |
| 資料持久性 | 容器刪除後仍保留 | 容器刪除後仍保留（位於主機） | 容器停止即消失 |
| 適用情境 | 使用者上傳檔、需備份遷移的資料 | 開發時掛載設定檔、原始碼 | 暫存、快取 |
| SSDS 用法 | `ssds-uploads` → `/app/uploads` | nginx template、第三章的 jar | api 的 `/tmp` |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>選擇原則：</b>需要 Docker 管理、備份、遷移 → Volume；需要直接存取主機既有檔案 → Bind Mount；僅需暫存 → tmpfs。資料庫由 Supabase 託管，三者皆不需要。
</div>

<!--
【重點解說】
三者的差異在於：由誰管理、資料存放位置，以及容器刪除後資料是否保留。

【業界實務】
自行執行資料庫容器（MySQL、PostgreSQL）的專案，資料目錄必須掛載 Volume。SSDS 的資料庫由 Supabase 託管，此問題由 Supabase 處理，這也是使用託管資料庫的優點之一。

【易錯點提醒 ⚠️】
Bind Mount 的資料在容器刪除後仍保留，是因為資料本來就位於主機上，並非 Docker 保留；與 Volume 的持久化機制不同。
-->

---
layout: default
---

# 補充：`-v` 短語法 vs `--mount` 長語法

Docker 官方文件建議優先使用 `--mount`，語意明確且參數完整；`-v` 為較早期的簡短寫法，仍廣泛使用。

```bash
# --mount 長語法（建議）
docker run --mount type=volume,src=ssds-uploads,dst=/app/uploads ssds-api:1.0.0

# -v 短語法
docker run -v ssds-uploads:/app/uploads ssds-api:1.0.0
```

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <code>-v</code> 冒號左側為「名稱」時是 Volume，為「路徑」時是 Bind Mount。<code>-v uploads:/app/uploads</code> 與 <code>-v ./uploads:/app/uploads</code> 僅差兩個字元，意義完全不同。Compose 的短語法亦同。
</div>

<!--
【重點解說】
--mount 的 type、source、target 皆明確寫出；-v 較精簡，但冒號左側是名稱或路徑，決定了它是 Volume 還是 Bind Mount。`-v uploads:/app/uploads` 會建立名為 uploads 的 Volume；`-v ./uploads:/app/uploads` 才是掛載本機的 uploads 資料夾。

【業界實務】
Compose 的 YAML 中短語法仍很常見，並非錯誤寫法；團隊協作時長語法較易理解。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# docker volume 指令

<!--
【段落轉換】
第二部分介紹 Volume 的管理指令。
-->

---
layout: default
---

# docker volume 常用指令

| 指令 | 說明 |
| --- | --- |
| `docker volume create <name>` | 建立 Volume |
| `docker volume ls` | 列出所有 Volume |
| `docker volume inspect <name>` | 檢視 Volume 詳細資訊（如主機上的實際路徑） |
| `docker volume rm <name>` | 刪除指定 Volume |
| `docker volume prune` | 刪除未被任何容器使用的 Volume |

<!--
【重點解說】
create、ls、inspect、rm、prune 涵蓋 Volume 從建立到清理的完整生命週期。

【補充】
Docker Engine 23 起，`docker volume prune` 預設只刪除匿名 Volume；需一併刪除未使用的具名 Volume 時須加上 `-a`。
-->

---
layout: default
---

# docker volume 常用指令 — 範例

```bash
$ docker volume create ssds-uploads
ssds-uploads

$ docker volume ls
DRIVER    VOLUME NAME
local     ssds-uploads
local     ssds_ssds-uploads          # Compose 建立的 Volume 會加上「專案名稱_」前綴

$ docker volume inspect ssds-uploads
[
    {
        "Driver": "local",
        "Mountpoint": "/var/lib/docker/volumes/ssds-uploads/_data",
        "Name": "ssds-uploads",
        "Scope": "local"
    }
]
```

<!--
【帶讀關鍵行】
- ls 輸出的第二列為 Compose 自動建立的 Volume。Compose 會加上「專案名稱_」前綴，compose.yaml 設定了 name: ssds，因此名稱為 ssds_ssds-uploads。這解釋了 compose.yaml 中只寫 ssds-uploads，docker volume ls 卻出現兩個 Volume 的原因；後續 Compose 頁面說明如何統一。
- inspect 的 Mountpoint 欄位為 Volume 在主機上的實際路徑。

【易錯點提醒 ⚠️】
Docker Desktop（Windows / macOS）的 Mountpoint 位於 Docker Desktop 內部的 Linux VM 中，無法以檔案總管找到。檢視內容請使用下一頁的「臨時容器」技巧。
-->

---
layout: default
---

# 掛載 Volume 至容器

```bash
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  --mount source=ssds-uploads,target=/app/uploads \
  ssds-api:1.0.0

# 檢視 Volume 內容：以臨時容器掛載後執行 ls，執行完即刪除
docker run --rm -v ssds-uploads:/data alpine ls -R /data
# /data/product/101/3f2a...c1.jpg
```

掛載後，Spring Boot 寫入 `/app/uploads` 的所有檔案皆存放於 `ssds-uploads`。執行 `docker rm -f ssds-api` 後再以同一個 Volume 重新啟動，圖片完整保留。

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>初始化規則：</b>掛載「空」Volume 時，Image 中該路徑的檔案與<b>擁有者權限</b>會自動複製進 Volume；Volume 已有資料時則直接沿用，Image 中同路徑的內容會被遮蔽。
</div>

<!--
【操作提示】
以 alpine 臨時容器將 Volume 掛載至 /data，執行 ls 後以 --rm 自動刪除。此方式不受 Docker Desktop VM 路徑影響，任何平台皆適用；下一部分的備份也採用相同原理。

【重點解說】
空的 Volume 首次掛載時，Docker 會複製 Image 中同路徑的內容，因此 Dockerfile 必須預先建立 /app/uploads 並將權限交給 app。Volume 一旦有內容，之後即以 Volume 為準。
-->

---
layout: default
---

# 使用 Volume 的注意事項

刪除容器不會自動刪除其掛載的 Volume，此設計可避免誤刪重要資料。

- 匿名 Volume（未指定名稱）搭配 `docker run --rm` 時，容器結束後會一併刪除
- `docker compose down` 保留 Volume；`docker compose down -v` 會**一併刪除 Volume**
- `docker volume prune` 刪除未使用的 Volume，無法復原
- Volume 只存在於**目前這台主機**：更換電腦或部署至雲端時不會隨之移動（第九章說明）

<!--
【重點解說】
- 建立容器時若未指定 Volume 名稱，Docker 會產生隨機名稱的匿名 Volume，搭配 --rm 時一併刪除。
- Compose 的 down -v 很容易順手輸入，執行後所有上傳圖片即消失。
- Volume 存放於 Docker 主機上。本機的 Volume 不會隨部署移至雲端；雲端平台若未提供持久化磁碟，容器重建後資料即消失，第九章說明免費方案的限制。

【易錯點提醒 ⚠️】
docker volume prune 執行後無法復原，執行前請以 docker volume ls 確認清單。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 資料備份與還原

<!--
【段落轉換】
第三部分說明如何將 Volume 打包備份並還原，同時介紹「以容器作為免安裝工具」的用法。
-->

---
layout: default
---

# 為什麼需要備份 Volume？

Volume 雖不隨容器刪除而消失，但主機發生問題時（硬碟故障、更換電腦、搬遷至其他主機），Volume 中的資料仍會遺失。

備份 Volume 的標準做法：以**臨時容器**同時掛載 Volume 與主機資料夾，在容器中以 `tar` 將 Volume 內容打包至主機資料夾；臨時容器搭配 `--rm`，執行完畢即自動刪除。

<!--
【問題引導】
Volume 已經可以保留資料，為何仍需備份？Volume 只保證資料不隨容器消失，但仍存放於同一台主機；電腦重灌、Docker Desktop 重置、更換筆電，Volume 都會遺失。

【核心說明】
Volume 只能由容器掛載，因此使用最小的容器（alpine，約 5MB），同時掛載「要備份的 Volume」與「主機上的資料夾」，在容器內以 tar 將前者打包至後者，完成後以 --rm 刪除。
-->

---
layout: default
---

# 備份 Volume 的步驟

| 步驟 | 說明 |
| --- | --- |
| 1 | 啟動臨時容器，以 `-v` 掛載要備份的 Volume（建議唯讀 `:ro`） |
| 2 | 同時以 bind mount 掛載主機資料夾，作為備份檔存放位置 |
| 3 | 在容器內執行 `tar czf`，將 Volume 打包壓縮至主機資料夾 |
| 4 | 加上 `--rm`，執行完畢自動刪除容器 |

<!--
【重點解說】
四個步驟實際上只是一行 docker run，同時運用了 Volume、Bind Mount 與 --rm 三個觀念，為本章的綜合應用。
-->

---
layout: default
---

# 備份 — 範例

```bash
# 做法 A：以臨時 alpine 容器打包 Volume（商品圖片、匯入暫存檔）
docker run --rm \
  -v ssds-uploads:/data:ro \
  -v "${PWD}/backup:/backup" \
  alpine tar czf /backup/ssds-uploads-20261006.tgz -C /data .

# 做法 B：資料庫在 Supabase → 以 postgres 官方 Image 作為免安裝的 pg_dump
docker run --rm --env-file .env -v "${PWD}/backup:/backup" postgres:17-alpine \
  sh -c 'PGPASSWORD="$SSDS_DB_PASSWORD" pg_dump \
    -h "$SSDS_DB_HOST" -p 5432 -U "$SSDS_DB_USER" -d "$SSDS_DB_NAME" \
    --schema=public --data-only -f /backup/ssds-data-20261006.sql'
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>做法 B：</b>本機不需安裝 PostgreSQL，<code>postgres:17-alpine</code> 只用於提供 <code>pg_dump</code>；連線使用 <b>Session pooler（5432）</b>，transaction pooler（6543）不適用於 pg_dump 這類長時間的 session。
</div>

<!--
【帶讀關鍵行】
做法 A：
- `:ro` 唯讀掛載，確保備份過程不會修改資料。
- `-C /data .`：切換至 /data 後打包目前目錄，tar 檔內為相對路徑，還原時較易處理。

做法 B：
- 容器不只能執行服務，也能作為免安裝的工具。傳統做法需在本機安裝 PostgreSQL 才有 pg_dump；改用官方 postgres Image 執行 pg_dump，完成後 --rm 刪除，本機不需安裝任何軟體。
- `--env-file .env`：容器取得 SSDS_DB_* 連線資訊，密碼不會出現在指令列或 shell history。
- 以單引號包住 sh -c 的內容，使 $SSDS_DB_HOST 等變數在容器內展開，而非在 PowerShell 中展開。
- port 固定為 5432：.env 中的 SSDS_DB_PORT 為 6543 的 transaction pooler，pg_dump 須使用 session pooler。
- `--data-only`：只備份資料，schema 由 Flyway 管理，不需備份。

【易錯點提醒 ⚠️】
- pg_dump 的版本必須大於或等於伺服器版本。可於 Supabase SQL Editor 執行 `select version();` 確認；若專案已升級至 PostgreSQL 18，改用 `postgres:18-alpine`。
- 日常使用的 ssds_app 為受限角色，若部分資料表沒有 SELECT 權限，備份會失敗。此為 Supabase 的權限設計，與 Docker 無關；完整備份應由負責 schema 的組員以具權限的帳號執行。共用資料庫的還原（寫入）須先與全組確認。
-->

---
layout: default
---

# 還原 Volume — 範例

```bash
# 1. 建立新的 Volume（模擬更換電腦）
docker volume create ssds-uploads-restore

# 2. 將 tar 解壓至新 Volume
docker run --rm \
  -v ssds-uploads-restore:/data \
  -v "${PWD}/backup:/backup:ro" \
  alpine sh -c "tar xzf /backup/ssds-uploads-20261006.tgz -C /data && chown -R 100:101 /data"

# 3. 以還原的 Volume 啟動 api，開啟前端確認圖片皆已恢復
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  -v ssds-uploads-restore:/app/uploads ssds-api:1.0.0
```

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <b>權限：</b>解壓時以 root 執行，檔案擁有者會變為 root，非 root 的 <code>app</code> 使用者無法寫入。<code>100:101</code> 為範例值，請以 <code>docker run --rm --entrypoint id ssds-api:1.0.0</code> 確認 app 的 uid:gid。
</div>

<!--
【核心說明】
還原為備份的反向操作：建立新 Volume、以臨時容器將 tar 解壓至其中，再掛載給服務使用。

【易錯點提醒 ⚠️】
api 以非 root 的 app 使用者執行，而 alpine 臨時容器預設為 root。解壓出的檔案屬於 root，app 可以讀取（舊圖片可顯示），但無法寫入（新上傳失敗），因此解壓後須 chown 給 app 的 uid/gid。

【操作提示】
uid/gid 依 Image 而異，不應記憶固定數字。`docker run --rm --entrypoint id ssds-api:1.0.0` 以 --entrypoint 覆蓋 Dockerfile 的 ENTRYPOINT，改為執行 id 指令，輸出 app 使用者的 uid 與 gid。

【預期結果】
前端商品頁的圖片全部恢復，且可繼續上傳新圖片。
-->

---
layout: default
---

# 補充：在 Compose 中宣告 Volume

```yaml
# ai-products-selection/compose.yaml（僅列出本章新增部分）
services:
  api:
    # ...沿用第五章
    volumes:
      - type: volume
        source: ssds-uploads
        target: /app/uploads
    tmpfs:
      - /tmp

volumes:
  ssds-uploads:
    name: ssds-uploads      # 固定實際名稱，不加上「ssds_」前綴
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>name 的作用：</b>未設定 <code>name</code> 時 Compose 建立 <code>ssds_ssds-uploads</code>；設定後名稱為 <code>ssds-uploads</code>，與手動 <code>docker run -v ssds-uploads:...</code> 使用同一個 Volume，備份指令不需修改。
</div>

<!--
【帶讀關鍵行】
- api 服務加入 volumes 與 tmpfs；最外層 volumes 區塊宣告 ssds-uploads。
- 使用長語法 type: volume，與 --mount 同樣語意明確。
- volumes 區塊中的 name：Compose 預設會加上專案名稱前綴，設定 name 後即使用指定名稱，使 Compose 與手動 docker run 共用同一個 Volume，前述備份還原指令不需修改。

【易錯點提醒 ⚠️】
docker compose down 保留 Volume；down -v 會一併刪除 ssds-uploads，所有上傳圖片隨之消失。
-->

---
layout: default
---

# 練習 1：保存 SSDS 的商品圖片
### 任務說明

1. **重現問題**：以第五章的 compose.yaml 啟動，於前端上傳一張商品圖片 → `docker compose down` → `docker compose up -d` → 圖片是否仍存在？
2. 修改 `compose.yaml`：以長語法為 `api` 掛載名為 `ssds-uploads` 的 Volume 至 `/app/uploads`，並於 `volumes` 區塊以 `name` 固定名稱
3. 再上傳一張圖片 → `down` → `up -d` → 確認圖片仍存在
4. 以臨時 alpine 容器執行 `ls -R`，檢視 Volume 中的檔案結構
5. **思考題**：執行 `docker compose down -v` 會發生什麼事？

<!--
【任務鋪陳】
本題先實際觀察問題，再進行修正。

【出題動機】
- 第 1 步：圖片紀錄在 Supabase、檔案在容器中，down 之後商品頁顯示破圖。
- 第 2、3 步：修正並驗證。
- 第 4 步：練習以臨時容器檢視 Volume。
- 第 5 步：觀念題。
-->

---
layout: default
zoom: 0.9
---

# 練習 1：參考答案

```yaml
# ai-products-selection/compose.yaml
name: ssds
services:
  api:
    build: ./ai-products-selection-backend
    image: ssds-api:1.0.0
    ports: ["8080:8080"]
    env_file: ./ai-products-selection-backend/.env
    volumes:
      - type: volume
        source: ssds-uploads
        target: /app/uploads
    # healthcheck 沿用第五章
  web:
    # 沿用第五章

volumes:
  ssds-uploads:
    name: ssds-uploads
```

```bash
docker compose up -d                                  # 上傳圖片後
docker compose down && docker compose up -d           # 圖片仍存在
docker run --rm -v ssds-uploads:/data alpine ls -R /data
# /data/product/<商品ID>/<隨機檔名>.jpg
```

**第 5 題：**`down -v` 會一併刪除 `ssds-uploads`，再次 `up` 後圖片全部消失（Supabase 中的資料不受影響）。

<!--
【帶讀解法】
只列出與 Volume 相關的部分，其餘沿用第五章。

【易錯點提醒 ⚠️】
- services 下的 volumes（掛載）與最外層的 volumes（宣告）是兩個不同的設定，兩者都必須撰寫。只寫掛載未寫宣告，Compose 會出現 undefined volume。
- target 寫成 /app/uploads/product 也可以保存圖片，但 Excel 匯入的暫存檔不受保護，建議掛載整個 uploads。

【預期結果】
down 再 up 後商品圖片仍存在；ls -R 可看到 product 資料夾與圖片檔。
-->

---
layout: default
---

# 練習 2：備份並還原商品圖片
### 任務說明

延續練習 1 的 `ssds-uploads`（至少包含兩張圖片）：

1. 在 `ai-products-selection/` 下建立 `backup/` 資料夾
2. 以臨時 alpine 容器將 `ssds-uploads` 打包為 `backup/ssds-uploads-<今天日期>.tgz`
3. 建立新 Volume `ssds-uploads-restore`，將備份解壓至其中，並修正擁有者權限
4. 修改 compose.yaml 使 api 改為掛載 `ssds-uploads-restore`，`up -d` 後確認舊圖片皆存在，**且可上傳新圖片**
5. （選做）以 `postgres:17-alpine` 執行 `pg_dump --data-only`，將具讀取權限的資料備份為 `.sql`

<!--
【任務鋪陳】
本題完整走過「備份 → 模擬災難 → 還原 → 驗證」流程。

【出題動機】
- 第 3 步的權限修正為重點：還原後看似成功，但上傳新圖片時回傳 500，log 中出現 AccessDeniedException。
- 第 4 步必須測試上傳新圖片，只檢查舊圖片會遺漏權限問題。
- 第 5 步為選做，體驗以容器作為工具。

【易錯點提醒 ⚠️】
第 5 步只做備份（讀取），不可對共用的 Supabase 執行還原（寫入）。
-->

---
layout: default
zoom: 0.9
---

# 練習 2：參考答案

```bash
# 1. 建立備份資料夾
mkdir backup

# 2. 備份
docker run --rm -v ssds-uploads:/data:ro -v "${PWD}/backup:/backup" \
  alpine tar czf /backup/ssds-uploads-20261006.tgz -C /data .
docker run --rm -v "${PWD}/backup:/backup:ro" alpine tar tzf /backup/ssds-uploads-20261006.tgz | head

# 3. 查詢 app 的 uid/gid（例如 uid=100 gid=101），還原並修正擁有者
docker run --rm --entrypoint id ssds-api:1.0.0
docker volume create ssds-uploads-restore
docker run --rm -v ssds-uploads-restore:/data -v "${PWD}/backup:/backup:ro" \
  alpine sh -c "tar xzf /backup/ssds-uploads-20261006.tgz -C /data && chown -R 100:101 /data"

# 4. compose.yaml：services.api.volumes 的 source 與 volumes 區塊改為 ssds-uploads-restore
docker compose up -d

# 5.（選做）
docker run --rm --env-file ai-products-selection-backend/.env -v "${PWD}/backup:/backup" \
  postgres:17-alpine sh -c 'PGPASSWORD="$SSDS_DB_PASSWORD" pg_dump -h "$SSDS_DB_HOST" -p 5432 \
  -U "$SSDS_DB_USER" -d "$SSDS_DB_NAME" --schema=public --data-only -f /backup/ssds-data-20261006.sql'
```

<div class="mt-2 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <b>常見錯誤：</b>還原後未執行 <code>chown</code>，舊圖片可顯示但新圖片上傳失敗，api log 出現 <code>AccessDeniedException: /app/uploads/product/...</code>。
</div>

<!--
【帶讀解法】
- 第 2 步的第二行以 `tar tzf` 列出備份檔內容，確認路徑為 ./product/... 的相對路徑。
- 備份時使用 -C /data .，還原時也使用 -C /data，兩者對應，路徑才不會多一層或少一層。

【預期結果】
掛載還原的 Volume 後，舊圖片與新上傳的圖片皆正常。
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
<thead>
<tr><th>重點</th><th>說明</th></tr>
</thead>
<tbody>
<tr><td>持久化的必要性</td><td>容器可寫層隨容器消失；SSDS 的資料庫在 Supabase，但<b>上傳檔案</b>在容器中</td></tr>
<tr><td>三種掛載</td><td>Volume（Docker 管理）、Bind Mount（主機路徑）、tmpfs（記憶體）</td></tr>
<tr><td>SSDS 用法</td><td><code>ssds-uploads</code> → <code>/app/uploads</code>；Dockerfile 預先建立目錄並 chown 給 app</td></tr>
<tr><td>備份還原</td><td>臨時 alpine 容器 + <code>tar</code>；還原後執行 <code>chown</code></td></tr>
<tr><td>容器作為工具</td><td>以 <code>postgres:17-alpine</code> 提供 <code>pg_dump</code>，免安裝備份 Supabase</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-yellow-50 border-l-4 border-yellow-400 text-gray-700 text-sm text-left">
⚠️ <b>第九章預告：</b>免費雲端方案多數<b>不提供持久化磁碟</b>，容器重新部署或休眠後，上傳的圖片同樣會消失。課堂展示可接受；需長期保存時，應改存至 Supabase Storage 等物件儲存服務。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b>上線前準備 — <code>.env</code> 管理、Image Tag 策略、推送 Docker Hub、記憶體限制。
</div>

<!--
【回顧】
本章解決第三章留下的問題：容器中寫入的檔案隨容器刪除而消失。SSDS 的資料庫由 Supabase 託管，只需處理上傳檔案：以一個 Volume 保護 /app/uploads，並以臨時容器完成備份與還原，同時學會以容器作為免安裝工具。

【重點提醒】
第九章的免費雲端方案通常不提供持久化磁碟，重新部署或閒置休眠後喚醒時，容器皆為全新狀態，上傳的圖片會消失。課堂展示可以接受；若需長期營運，應將檔案存放於物件儲存（例如 Supabase Storage），使容器完全無狀態。

【課程預覽】
下一章處理正式上線前的準備工作。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
【互動引導】
開放提問：Volume、Bind Mount、tmpfs 的差異，或備份還原流程，有任何疑問皆可提出。
-->
