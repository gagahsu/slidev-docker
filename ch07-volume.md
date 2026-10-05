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

- 為什麼容器需要「外部儲存」——SSDS 的商品圖片去哪了？
- Volume vs Bind Mount vs tmpfs
- docker volume 指令
- 資料備份與還原情境（Volume 用 tar、Supabase 用容器跑 pg_dump）
- 練習題 / 總結

<!--
今天的路線圖分成三大段。

第一段先搞清楚為什麼需要外部儲存，以及 Docker 提供的三種掛載方式差在哪裡。

第二段帶大家實際操作 docker volume 系列指令。

第三段是實戰：Volume 怎麼備份還原；順便示範「把容器當工具用」——不用在電腦上裝 PostgreSQL，也能用 pg_dump 備份 Supabase。

最後兩題練習，直接在 SSDS 上做。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Volume vs Bind Mount vs tmpfs

<!--
我們先進入第一部分，認識 Docker 提供的三種資料持久化方式。
-->

---

# 容器被刪掉之後，資料去哪了？

「容器預設是無狀態（stateless）的，容器內的檔案系統會隨著容器一起被刪除。」

- SSDS 的資料庫在 Supabase，容器刪掉**資料表不受影響** ✅
- 但商品圖片是寫在容器裡的 `./uploads/product`（工作目錄 `/app` → `/app/uploads/product`）❌
- 資料庫裡記的是圖片的**相對路徑**，容器重建後檔案沒了 → 前端顯示破圖

```properties
# application.properties（專案原本就有的設定）
ssds.product-image.storage-path=${SSDS_PRODUCT_IMAGE_STORAGE_PATH:./uploads/product}
ssds.import.staging-path=${IMPORT_STAGING_PATH:./uploads/import-staging}
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>還記得第三章練習 2、第五章練習 2 的伏筆嗎？</b> 上傳一張商品圖片後 <code>docker compose down</code> 再 <code>up</code>，圖片就不見了。這一章就是要解決它。
</div>

<!--
大家有沒有試過第五章最後那個問題？上傳一張商品圖，down 再 up，商品資料還在，但圖片變成破圖。

原因是：資料庫在 Supabase，跟容器無關，所以商品資料、圖片的「紀錄」都還在；但圖片的「檔案本體」是 Spring Boot 寫在容器自己的檔案系統裡。容器一刪，可寫層（writable layer）就直接消失，沒有垃圾桶可以復原。

大家看專案的 application.properties，這兩行設定其實早就預告了這件事，註解還寫著「正式環境應以 SSDS_PRODUCT_IMAGE_STORAGE_PATH 指向持久化 volume」。寫專案的人已經知道這裡需要 volume，今天我們就把它補上。

生活化一點來說，容器就像一間「臨時搭建的房子」，說拆就拆。如果貴重物品都放在房子裡面，房子一拆，東西也跟著沒了。
-->

---
layout: default
---

# 什麼是 Volume？

「Volume（資料卷）是由 Docker 建立與管理的持久化儲存空間，儲存在 host 上 Docker 管理的目錄裡，生命週期完全獨立於容器。」

容器刪除後，Volume 資料依然保留，可掛載給新容器繼續使用。

```bash
docker volume create ssds-uploads
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  -v ssds-uploads:/app/uploads \
  ssds-api:1.0.0
```

Volume 的資料由 Docker 全權管理，我們不需要知道它實際存在 host 的哪個路徑，只需要透過 `docker volume` 指令來操作。

<!--
Volume 是 Docker 官方最推薦的持久化方式，需要長期保存的資料幾乎一定用這個。

用「外部倉庫」來比喻：容器是一間隨時可能被拆掉重建的房子，Volume 就是我們額外租的倉庫，房子拆了倉庫還在，重新蓋一間新房子，照樣可以把倉庫接回去用。

這段範例建立一個叫 ssds-uploads 的 Volume，掛到容器的 /app/uploads。為什麼掛 /app/uploads 而不是 /app/uploads/product？因為商品圖片跟 Excel 匯入的暫存檔都在 uploads 底下，一個 Volume 一起顧好。

⚠️ 還記得第四章 Dockerfile 裡那行 `mkdir -p /app/uploads && chown -R app:app /app` 嗎？這裡就派上用場了。空的 Volume 第一次掛上去時，Docker 會把 image 裡同路徑的內容、包含擁有者權限一起複製進 Volume。因為 image 裡 /app/uploads 已經是 app 使用者的，Volume 也就是 app 的，Spring Boot 才寫得進去。如果 Dockerfile 沒先建這個目錄，Volume 會是 root 擁有，非 root 的 Spring Boot 一寫圖片就 Permission denied。
-->

---
layout: default
---

# 什麼是 Bind Mount？

「Bind Mount（綁定掛載）是把 host 上『既有』的檔案或目錄，直接掛載進容器內，容器看到的就是 host 上那份原始資料。」

```bash
# 改 nginx 設定不用重 build：把本機的 nginx/ 唯讀掛進去，改完 docker restart 就生效
docker run -d --name ssds-web -p 8000:80 \
  --mount type=bind,src="${PWD}/nginx",dst=/etc/nginx/templates,readonly \
  ssds-web:1.0.0

# 把上傳目錄直接掛到本機資料夾，用檔案總管就看得到圖片
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  --mount type=bind,source="${PWD}/uploads",target=/app/uploads \
  ssds-api:1.0.0
```

常見情境：掛設定檔、掛開發用的原始碼、把容器產生的檔案撈到本機看。第三章用 `-v .../build/libs:/jar:ro` 借 jar 給容器，也是 bind mount。

<!--
Bind Mount 跟 Volume 最大的不同，就是它掛載的是「host 上原本就存在」的路徑，不是 Docker 幫我們建立管理的空間。

用「書櫃」比喻：書櫃本來就放在我們自己家裡，只是暫時搬進容器這個房間給它用。容器怎麼重建刪除，書櫃始終是我們家的東西。

第一個範例很實用：調 nginx 設定的時候，每改一次就重 build 前端 image 要好幾分鐘。把 template 檔 bind mount 進去，改完存檔、docker restart ssds-web，幾秒就生效。確定沒問題再 build 進 image。注意加了 readonly，容器裡的程式不可能改到我們專案裡的檔案。

第二個範例是把上傳目錄掛到本機，用檔案總管就能直接看到上傳的圖片，開發除錯很方便。

⚠️ Windows 注意事項：bind mount 的路徑在 PowerShell 用 ${PWD}，在 Git Bash 有時候會被轉換成奇怪的路徑，遇到的話改用 PowerShell 或寫完整的 C:/... 路徑。另外 Windows 的檔案透過 Docker Desktop 掛進 Linux 容器，大量小檔案時效能會比 Volume 差。

⚠️ 注意事項：Bind Mount 預設是可寫的，容器裡的程式如果亂寫亂刪，會直接影響到 host 上的檔案，所以敏感目錄建議加 readonly 或 ro。
-->

---
layout: default
---

# 什麼是 tmpfs？

「tmpfs mount 是把資料存在 host 的記憶體中，不會寫入任何檔案系統，容器停止或 host 重開機，資料就會消失。」

寫入速度快，容器一停止內容就消失，無法保留。

```bash
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  -v ssds-uploads:/app/uploads \
  --mount type=tmpfs,destination=/tmp \
  ssds-api:1.0.0
```

- 適合暫存資料：上傳過程中的 multipart 暫存檔、快取
- 只支援 Linux 容器
- 速度快但不持久，是與 Volume、Bind Mount 最本質的差異

<!--
tmpfs 是這三種方式裡面最特別的一個，因為它根本不寫進硬碟，是直接存在記憶體裡。

用「便利貼」來比喻最貼切：便利貼寫東西很快很方便，但只要撤掉（容器一停止），內容就跟著消失，沒辦法留到下次用。

範例裡我們把 tmpfs 掛到 /tmp。Spring Boot 處理檔案上傳時，Multipart 的暫存檔預設寫在 java.io.tmpdir，也就是 /tmp。這種資料寫完馬上就處理掉，放記憶體最快，而且容器一停自動清空，不會累積垃圾。

⚠️ 易錯點：tmpfs 吃的是記憶體。我們專案匯入檔上限 50MB，如果同時好幾個人上傳大檔，tmpfs 會吃掉不少記憶體——第九章免費雲端只有 512MB，那邊就不建議用。
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
| 適合情境 | 使用者上傳檔、需要備份遷移的資料 | 開發時掛設定檔、原始碼 | 暫存快取 |
| SSDS 的用法 | `ssds-uploads` → `/app/uploads` | nginx template、第三章的 jar | api 的 `/tmp` |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>選擇原則：</b> 需要 Docker 幫忙管理、備份、遷移，選 Volume；需要直接存取 host 上的既有檔案，選 Bind Mount；只是暫存、不在乎重開就消失，選 tmpfs。資料庫？SSDS 交給 Supabase，三種都不用。
</div>

<!--
這張表把三種方式攤開來一次比較，我們可以看到它們的差異其實蠻清楚的：管理權在誰手上、資料放在哪裡、容器不在了資料還在不在。

實務上的判斷原則很簡單：使用者上傳的檔案這種要備份、要遷移的重要資料，優先選 Volume；本機開發時要即時改設定，選 Bind Mount；只是暫存用、不怕遺失的，才考慮 tmpfs。

如果是一般專案自己跑資料庫容器（MySQL、PostgreSQL），資料目錄也一定要掛 Volume。我們 SSDS 把資料庫交給 Supabase 託管，所以這個問題由 Supabase 幫我們處理掉了，這也是用託管資料庫的好處之一。

⚠️ 容易誤解的地方：Bind Mount 的資料「容器刪除後仍保留」，是因為它本來就存在 host 上，不是 Docker 幫忙保留的，這跟 Volume 的持久化邏輯是不一樣的概念。
-->

---
layout: default
---

# 補充：`-v` 短語法 vs `--mount` 長語法

Docker 官方文件建議「優先使用 `--mount`」，因為它語意明確、參數完整；`-v` 是比較早期的簡短寫法，範例中仍然很常見。

```bash
# --mount 長語法（推薦）
docker run --mount type=volume,src=ssds-uploads,dst=/app/uploads ssds-api:1.0.0

# -v 短語法（常見但語意較不明確）
docker run -v ssds-uploads:/app/uploads ssds-api:1.0.0
```

⚠️ Docker 版本注意：`-v` 冒號左邊是「名稱」就是 Volume、是「路徑」就是 Bind Mount — `-v uploads:/app/uploads` 跟 `-v ./uploads:/app/uploads` 只差兩個字元，意義完全不同。Compose 裡的短語法同理。

<!--
這一頁專門講兩種寫法的差異，因為我們接下來的範例會兩種都用到。

`--mount` 的好處是每個參數都寫得清清楚楚，type、source、target 一目了然；`-v` 比較精簡，但有一個很陰險的坑：冒號左邊是名字還是路徑，決定了它是 Volume 還是 Bind Mount。`-v uploads:/app/uploads` 會建立一個叫 uploads 的 Volume；`-v ./uploads:/app/uploads` 才是掛本機的 uploads 資料夾。少打一個 ./，資料就跑到完全不同的地方。

在 Compose 的 yaml 檔案裡，短語法還是很常見，不算錯誤寫法，但團隊合作時長語法會讓設定更好懂。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# docker volume 指令

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

⚠️ 提醒大家：因為這張表有五列，我們把實際範例拆到下一頁，等一下就能看到完整的操作過程跟輸出結果。
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
local     ssds_ssds-uploads          # Compose 建的會自動加「專案名稱_」前綴

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
我們一步步操作一次：先 create 建立 ssds-uploads，接著用 ls 確認它存在。

大家注意 ls 輸出的第二列，那是用 Compose 起的時候自動建的 Volume。Compose 會幫 Volume 加上「專案名稱_」的前綴，我們 compose.yaml 寫了 name: ssds，所以變成 ssds_ssds-uploads。這解釋了一個很多人困惑的現象：明明 compose.yaml 裡寫 ssds-uploads，docker volume ls 卻看到兩個。等一下 Compose 那頁會教怎麼讓兩邊用同一個。

重點在 inspect 這個指令，它會告訴我們這個 Volume 在 host 上實際的路徑，也就是 Mountpoint 這個欄位。

⚠️ Windows / Mac 注意：Docker Desktop 的 Mountpoint 路徑是在 Docker Desktop 內部的 Linux VM 裡，不是在你的 C 槽，所以在檔案總管找不到。要看內容請用下一部分的「臨時容器」技巧。
-->

---
layout: default
---

# 掛載 Volume 到容器

```bash
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  --mount source=ssds-uploads,target=/app/uploads \
  ssds-api:1.0.0

# 看看 Volume 裡有什麼：借一個臨時容器掛進去 ls，用完即丟
docker run --rm -v ssds-uploads:/data alpine ls -R /data
# /data/product/101/3f2a...c1.jpg
```

掛載之後，Spring Boot 寫進 `/app/uploads` 的所有檔案，都實際落在 `ssds-uploads` 這個 Volume 裡；`docker rm -f ssds-api` 後再 run 一次並掛同一個 Volume，圖片原封不動。

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>注意：</b> 若掛載的是「空」Volume，image 裡該路徑原本的檔案與<b>擁有者權限</b>會自動複製進去；若 Volume 裡已經有資料，直接沿用既有資料，image 裡同路徑的內容會被遮蔽。
</div>

<!--
這頁示範怎麼把 Volume 掛進 ssds-api 容器，接著用一個很實用的技巧看 Volume 內容：借一個 alpine 臨時容器，把 Volume 掛到 /data，ls 完 --rm 自動刪掉。這招不用管 Docker Desktop 的 VM 路徑，任何平台都能用，下一部分的備份也是同樣的原理。

⚠️ 下面那個提示框講的是 Volume 的初始化規則：空的 Volume 第一次掛上去時，Docker 會把 image 裡同路徑的內容複製進去，這就是為什麼 Dockerfile 要先把 /app/uploads 建好、權限給 app。Volume 一旦有東西，之後就以 Volume 為準。
-->

---
layout: default
---

# 使用 Volume 的注意事項

「刪除容器不會自動刪除它掛載的 Volume」——這是設計上的保護機制，避免我們不小心把重要資料清掉。

- 匿名 Volume（沒有指定名稱）搭配 `docker run --rm`，容器結束時會一併被刪除
- `docker compose down` 保留 Volume；`docker compose down -v` 會**連 Volume 一起刪**
- 想清除所有沒被使用的 Volume，用 `docker volume prune`，這個動作無法復原
- Volume 只存在**這台機器**上：換電腦、上雲端，Volume 不會跟著走（第九章會再遇到）

<!--
這頁整理四個大家最容易忽略、也最容易出包的注意事項。

第一個是匿名 Volume 的例外狀況：如果我們建立容器時沒有指定 Volume 名稱，Docker 會自動生成一個亂數名稱的匿名 Volume，搭配 --rm 時會被一起清掉。

第二個是 Compose 的 down -v，這個 -v 很順手就打上去了，打下去所有上傳圖片就沒了。

⚠️ 第三點是最容易誤觸的地雷：docker volume prune 會把所有「目前沒有容器在用」的 Volume 全部刪光，而且沒有辦法復原。

第四點是觀念：Volume 是存在 Docker 主機上的。我們在自己電腦掛的 Volume，部署到雲端平台時不會跟過去，雲端平台要嘛提供它自己的「持久化磁碟」，要嘛就沒有——第九章會講到免費方案的限制。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 資料備份與還原情境

<!--
第三部分是這一章的重頭戲，我們要學怎麼把 Volume 裡的資料打包備份、還有怎麼把備份還原回去，這在維運工作裡是非常實用的技巧。順便學一個很實用的觀念：把容器當成「免安裝的工具」來用。
-->

---
layout: default
---

# 為什麼需要備份 Volume？

雖然 Volume 的資料不會隨容器刪除而消失，但如果 host 本身出問題（硬碟壞掉、要換電腦、要搬到另一台主機），Volume 裡的資料還是會不見。

「備份 Volume 最經典的做法，是借用一個『臨時容器』，把 Volume 掛進去，再用 `tar` 打包成一個檔案，存到 host 的某個路徑。」

這個臨時容器不需要跑任何服務，它唯一的任務就是幫我們搬資料，做完就可以丟掉，所以我們通常會搭配 `--rm` 參數讓它用完即焚。

<!--
大家可能會想：Volume 不是已經很安全了嗎？為什麼還要備份？

Volume 只是讓資料不跟著容器一起消失，但它還是存在這台機器上。電腦重灌、Docker Desktop 重置、換新筆電，Volume 一樣會不見。

備份的思路很簡單：既然 Volume 只能被容器掛載，那我們就找一個最小的容器（alpine，只有 5MB），同時掛上「要備份的 Volume」跟「主機上的一個資料夾」，在容器裡用 tar 把前者打包到後者，做完 --rm 丟掉。
-->

---
layout: default
---

# 備份 Volume 的步驟

| 步驟 | 說明 |
| --- | --- |
| 1 | 啟動一個臨時容器，用 `-v` 掛上要備份的 Volume（建議唯讀 `:ro`） |
| 2 | 同時用 bind mount 把 host 上的資料夾掛進去，當作備份檔的存放位置 |
| 3 | 在容器內執行 `tar czf`，把 Volume 打包壓縮到 host 資料夾 |
| 4 | 容器加上 `--rm`，執行完畢自動刪除，不留垃圾 |

<!--
這四個步驟請大家記起來，其實就是一行 docker run，只是一次用上了 Volume、Bind Mount、--rm 三個觀念，算是本章的綜合應用。
-->

---
layout: default
---

# 備份 — 範例

```bash
# 做法 A：用臨時 alpine 容器打包 Volume（商品圖片、匯入暫存檔）
docker run --rm \
  -v ssds-uploads:/data:ro \
  -v "${PWD}/backup:/backup" \
  alpine tar czf /backup/ssds-uploads-20261005.tgz -C /data .

# 做法 B：資料庫在 Supabase → 用 postgres 官方 image 當「免安裝的 pg_dump」
docker run --rm --env-file .env -v "${PWD}/backup:/backup" postgres:17-alpine \
  sh -c 'PGPASSWORD="$SSDS_DB_PASSWORD" pg_dump \
    -h "$SSDS_DB_HOST" -p 5432 -U "$SSDS_DB_USER" -d "$SSDS_DB_NAME" \
    --schema=public --data-only -f /backup/ssds-data-20261005.sql'
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>做法 B 的重點：</b> 電腦上不用裝 PostgreSQL，<code>postgres:17-alpine</code> 只是拿來借 <code>pg_dump</code> 這支工具；連線走 <b>Session pooler（5432）</b>，transaction pooler（6543）不適合 pg_dump 這種長時間的 session。
</div>

<!--
做法 A 是標準的 Volume 備份：:ro 唯讀掛載，確保備份過程不會改到資料；-C /data . 的意思是「切到 /data 再打包當前目錄」，這樣 tar 檔裡的路徑是相對的，還原時比較好處理。

做法 B 是這頁的彩蛋，也是很多人沒想過的用法：容器不只能拿來跑服務，也能拿來當「免安裝的工具」。我們的資料庫在 Supabase，想留一份資料備份，傳統做法是在電腦上裝 PostgreSQL 才有 pg_dump。現在一行 docker run，用官方 postgres image 裡的 pg_dump，跑完 --rm 丟掉，電腦上什麼都沒多裝。

幾個細節：
- --env-file .env 讓容器拿到 SSDS_DB_* 這些連線資訊，密碼不會出現在指令列、也不會留在 shell history。
- 單引號包住 sh -c 的內容，讓 $SSDS_DB_HOST 這些變數在「容器裡」展開，而不是在你的 PowerShell 裡展開。
- port 寫死 5432：.env 裡的 SSDS_DB_PORT 是 6543 的 transaction pooler，pg_dump 要用 session pooler。
- --data-only 只備份資料：schema 由 Flyway 管理，不需要備份。
- pg_dump 的版本要大於等於伺服器版本，用 17 比較保險。

⚠️ 權限注意：我們日常用的 ssds_app 是受限角色，讀資料沒問題，但如果遇到某些表沒有 SELECT 權限就會失敗。這是 Supabase 的權限設計，不是 Docker 的問題；真的要做完整備份請找負責 schema 的組員，用有權限的帳號跑。共用資料庫的還原（寫入）更要先跟全組確認，不要自己動手。
-->

---
layout: default
---

# 還原 Volume — 範例

```bash
# 1. 建一個全新的 Volume（模擬換了一台電腦）
docker volume create ssds-uploads-restore

# 2. 把 tar 解壓回新 Volume
docker run --rm \
  -v ssds-uploads-restore:/data \
  -v "${PWD}/backup:/backup:ro" \
  alpine sh -c "tar xzf /backup/ssds-uploads-20261005.tgz -C /data && chown -R 100:101 /data"

# 3. 用還原出來的 Volume 啟動 api，打開前端確認圖片都回來了
docker run -d --name ssds-api -p 8080:8080 --env-file .env \
  -v ssds-uploads-restore:/app/uploads ssds-api:1.0.0
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>權限：</b> 解壓時用的是 root，檔案擁有者會變成 root，非 root 的 <code>app</code> 使用者就寫不進去了。<code>100:101</code> 是 alpine 上 <code>adduser -S</code> 建出來的 app 的 uid:gid，可用 <code>docker run --rm --entrypoint id ssds-api:1.0.0</code> 確認。
</div>

<!--
還原就是備份的反方向：建新 Volume、臨時容器把 tar 解壓進去、再掛給真正的服務用。

⚠️ 這頁有個第四章埋下的坑：我們的 api 是用非 root 的 app 使用者執行。alpine 臨時容器預設是 root，解壓出來的檔案擁有者是 root，app 讀得到（所以舊圖片看得到），但寫不進去（新上傳會失敗）。所以解壓完要 chown 給 app 的 uid/gid。

uid/gid 每個 image 可能不一樣，不要背數字，用 `docker run --rm --entrypoint id ssds-api:1.0.0` 查——--entrypoint 會蓋掉 Dockerfile 的 ENTRYPOINT，改成跑 id 指令，印出 app 使用者的 uid 跟 gid。

預期結果：前端商品頁的圖片全部回來，而且可以繼續上傳新圖片。
-->

---
layout: default
---

# 補充：在 Compose 中宣告 Volume

```yaml
# ai-products-selection/compose.yaml（只列出這章新增的部分）
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
    name: ssds-uploads      # 固定實際名稱，不要被加上「ssds_」前綴
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>name 的作用：</b> 沒寫 <code>name</code> 時 Compose 會建立 <code>ssds_ssds-uploads</code>；寫了之後就叫 <code>ssds-uploads</code>，跟手動 <code>docker run -v ssds-uploads:...</code> 用的是同一個 Volume，備份指令也不用改名字。
</div>

<!--
最後把這章學的東西放回 compose.yaml：api 服務加上 volumes 跟 tmpfs，最下面的 volumes 區塊宣告 ssds-uploads。

這裡用的是長語法 type: volume，跟 --mount 一樣語意清楚。

volumes 區塊裡的 name 是個小技巧：Compose 預設會幫 Volume 加上專案名稱前綴，寫了 name 之後就用我們指定的名字。好處是 Compose 跟手動 docker run 用的是同一個 Volume，前面那些備份還原指令完全不用改。

⚠️ 再提醒一次：docker compose down 保留 Volume；down -v 會連 ssds-uploads 一起刪掉，上傳的圖片全部消失。
-->

---
layout: default
---

# 練習 1：讓 SSDS 的商品圖片活下來
### 任務說明

1. **先重現問題**：用第五章的 compose.yaml 啟動，在前端上傳一張商品圖片 → `docker compose down` → `docker compose up -d` → 圖片是否還在？
2. 修改 `compose.yaml`：幫 `api` 掛上名為 `ssds-uploads` 的 Volume 到 `/app/uploads`（長語法），並在 `volumes` 區塊用 `name` 固定名稱
3. 再上傳一張圖片 → `down` → `up -d` → 確認圖片還在
4. 用臨時 alpine 容器 `ls -R` 看 Volume 裡的檔案結構
5. **想一想**：如果 `docker compose down -v` 會發生什麼事？

<!--
這一題讓大家先「親眼看到問題」，再動手修。

第 1 步故意重現：圖片紀錄在 Supabase、檔案在容器裡，down 之後商品頁就是破圖。

第 2、3 步是修正與驗證。

第 4 步練習「臨時容器看 Volume」的技巧，會看到 product/商品ID/亂數檔名.jpg 這樣的結構。

第 5 步是觀念題：-v 會把 Volume 一起刪，圖片又沒了。
-->

---
layout: default
---

# 練習 1：解題提示
### 提示說明

```yaml
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
docker compose up -d
docker run --rm -v ssds-uploads:/data alpine ls -R /data
```

<!--
提示頁只列出跟 Volume 有關的部分，其他沿用第五章。

⚠️ 易錯點一：services 底下的 volumes（掛載）跟最外層的 volumes（宣告）是兩個不同的東西，兩個都要寫。只寫掛載不寫宣告，Compose 會報 undefined volume。

⚠️ 易錯點二：target 寫成 /app/uploads/product 也可以存圖片，但 Excel 匯入的暫存檔就沒被保護到，建議掛整個 uploads。

預期結果：down 再 up 之後，商品圖片還在；ls -R 看得到 product 資料夾跟圖片檔。
-->

---
layout: default
---

# 練習 2：備份並還原商品圖片
### 任務說明

延續練習 1 的 `ssds-uploads`（裡面至少有兩張圖片）：

1. 在 `ai-products-selection/` 下建立 `backup/` 資料夾
2. 用臨時 alpine 容器把 `ssds-uploads` 打包成 `backup/ssds-uploads-<今天日期>.tgz`
3. 建立新 Volume `ssds-uploads-restore`，把備份解壓進去，並修正擁有者權限
4. 修改 compose.yaml 讓 api 改掛 `ssds-uploads-restore`，`up -d` 後確認舊圖片都在、**也能上傳新圖片**
5. （選做）用 `postgres:17-alpine` 跑 `pg_dump --data-only`，把你有權限讀的資料備份成 `.sql`

<!--
這一題完整走過「備份 → 模擬災難 → 還原 → 驗證」。

第 3 步的權限修正是重點，很多人還原完覺得成功了，結果一上傳新圖就 500。看 log 會看到 AccessDeniedException。

第 4 步一定要測「上傳新圖」，只看舊圖會漏掉權限問題。

第 5 步選做，讓大家體驗「容器當工具」。⚠️ 只做備份（讀），不要對共用的 Supabase 做還原（寫）。
-->

---
layout: default
---

# 練習 2：解題提示
### 提示說明

```bash
# 2. 備份
docker run --rm -v ssds-uploads:/data:ro -v "${PWD}/backup:/backup" \
  alpine tar czf /backup/ssds-uploads-20261005.tgz -C /data .

# 3. 還原到新 Volume，並把擁有者改回 app
docker run --rm --entrypoint id ssds-api:1.0.0  # 查 app 的 uid/gid，例如 uid=100 gid=101
docker volume create ssds-uploads-restore
docker run --rm -v ssds-uploads-restore:/data -v "${PWD}/backup:/backup:ro" \
  alpine sh -c "tar xzf /backup/ssds-uploads-20261005.tgz -C /data && chown -R 100:101 /data"

# 4. compose.yaml 的 source 與 volumes 區塊改成 ssds-uploads-restore 後
docker compose up -d
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>常見錯誤：</b> 還原後忘了 <code>chown</code>，舊圖看得到、新圖上傳失敗，api log 出現 <code>AccessDeniedException: /app/uploads/product/...</code>。
</div>

<!--
提示頁把整套流程寫完整了，大家對照一下自己的指令。

⚠️ 除了權限之外，另一個常見錯誤是 tar 的 -C 參數：備份時用 -C /data .，還原時也要 -C /data，兩邊對齊，路徑才不會多一層或少一層。可以用 `tar tzf 備份檔 | head` 先看看 tar 檔裡的路徑長什麼樣子。

預期結果：還原後的 Volume 掛上去，舊圖、新圖都正常。
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
<tr><td>為什麼要持久化</td><td>容器可寫層隨容器消失；SSDS 的 DB 在 Supabase，但<b>上傳檔案</b>在容器裡</td></tr>
<tr><td>三種掛載</td><td>Volume（Docker 管理）、Bind Mount（host 路徑）、tmpfs（記憶體）</td></tr>
<tr><td>SSDS 用法</td><td><code>ssds-uploads</code> → <code>/app/uploads</code>；Dockerfile 預先建目錄並 chown 給 app</td></tr>
<tr><td>備份還原</td><td>臨時 alpine 容器 + <code>tar</code>；還原後記得 <code>chown</code></td></tr>
<tr><td>容器當工具</td><td><code>postgres:17-alpine</code> 借 <code>pg_dump</code>，免安裝備份 Supabase</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>預告第九章：</b> 免費雲端方案大多<b>沒有持久化磁碟</b>，容器重新部署或休眠後，上傳的圖片一樣會消失。Demo 可以接受；要長期保存，下一步是改存到 Supabase Storage 之類的物件儲存。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 正式環境準備 — <code>.env</code> 管理、Image Tag 策略、推送 Docker Hub、記憶體限制。
</div>

<!--
這一章我們解決了第三章就埋下的伏筆：容器裡寫的檔案，容器一刪就沒了。

SSDS 比一般專案幸運的地方是資料庫交給 Supabase 託管，所以只剩上傳檔案這一塊要處理。我們用一個 Volume 把 /app/uploads 保護起來，學會了用臨時容器備份、還原，也學會了把容器當成免安裝的工具。

⚠️ 先幫大家打預防針：第九章要用的免費雲端平台，免費方案通常沒有持久化磁碟，重新部署、或閒置休眠後喚醒，容器都是全新的，上傳的圖片會消失。對課堂 demo 來說可以接受；如果專案之後要長期營運，正規做法是把檔案存到物件儲存（例如同樣在 Supabase 裡的 Storage），容器本身就可以完全無狀態。

下一章我們處理正式上線前的準備工作。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對 Volume、Bind Mount、tmpfs 的差異，或是備份還原的流程，有沒有什麼疑問？都歡迎提出來討論。
-->
