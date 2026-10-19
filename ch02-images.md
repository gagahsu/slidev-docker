---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: 映像檔管理
routeAlias: ch02
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">映像檔管理</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「Image 就是食譜，Container 才是端上桌的那盤菜」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
歡迎來到第二章，映像檔管理。

上一章我們用一行 `docker run` 跑起了 TaskBoard 的資料庫。那個容器到底是用什麼做出來的？答案就是 Image。

這一章我們會搞懂 Image 是怎麼組成的，學會從 Registry 下載和上傳 Image，還有版本標籤該怎麼命名。學完之後，我們就能把自己的 Image 貼上版本號，分享給整個團隊。
-->

---
layout: default
---

# Outline

<div class="text-left" style="font-size: 1.1rem;">

- Image 概念與 Layer 結構
- 常用指令：pull / push / images / rmi
- Docker Hub 與 Tag 命名規則
- 練習題
- 總結

</div>

<!--
這一章分成三部分。先建立 Image 的觀念，搞懂什麼是 Layer。接著實際操作 pull、push、images、rmi 這幾個最常用的指令。最後看 Docker Hub 怎麼用，以及 Tag 該怎麼命名才不會搞混版本。章節最後有一題練習，讓大家把指令實際打一遍。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Image 概念與 Layer 結構

<!--
先從最基礎的問題開始：Image 到底是什麼？它為什麼要一層一層疊起來？
-->

---

# 什麼是 Image？

「Image（映像檔）是一個標準化的封裝，裡面包含執行 Container 所需要的所有檔案、程式庫、執行環境與設定。」

- Image 是固定不變的模板，內容不會因執行環境而改變
- Container 是根據 Image 啟動的執行實例，同一個 Image 可以同時啟動多個 Container

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>重點：</b> Image 是「模板」，Container 是「跑起來的實例」。一個 Image 可以同時啟動很多個 Container。
</div>

<!--
想像一家連鎖餐廳，如果每家分店都各自發揮、沒有標準食譜，客人吃到的口味就會參差不齊。

Docker Image 解決的就是類似的問題。「Image 是一個標準化的封裝」，裡面有執行 Container 需要的所有檔案、程式庫和設定。

用食譜來比喻，Image 就是那份標準食譜，Container 是照著食譜做出來、端上桌的那盤菜。同一份食譜可以同時做出很多盤菜，同一個 Image 也可以同時啟動很多個 Container。

很多人會把這兩個搞混。記住一句話就好：Image 是靜態的模板，Container 是跑起來的實例。
-->

---

# Image 的 Layer 結構

「Image 採用分層（Layer）架構，每一層代表一組檔案系統的變更——新增、刪除或修改某些檔案。」

以 TaskBoard 的後端 `taskboard-api` 為例：

- 最底層：作業系統基礎環境（Alpine Linux）
- 中間層：JRE 21 執行環境（`eclipse-temurin:21-jre-alpine`）
- 再上一層：Gradle 產出的相依函式庫
- 最上層：複製我們自己打包出來的 `taskboard-api.jar`

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>重點：</b> Image「建立後不可修改」，只能在既有 Layer 上面疊加新的 Layer；相同的底層 Layer 可以被多個 Image 共用，不用重複下載。
</div>

<!--
Image 有一個很聰明的設計，叫做 Layer，分層。

「每一層代表一組檔案系統的變更」。以 TaskBoard 的後端為例，最底層是 Alpine Linux，往上是 JRE 21，再往上是相依函式庫，最上面才是我們自己打包的 jar 檔。

Image 建立之後就不能修改，只能在上面疊加新的一層。很多人以為改檔案就是改掉原本那一層，其實 Docker 是建了一個新的 Layer 疊上去，底下完全不動。

這樣設計有兩個好處。第一，相同的底層可以被很多 Image 共用，不用重複下載。第二，我們每天改 Controller 改十幾次，但底層的 Alpine 和 JRE 從頭到尾沒變，每次重建只需要重做最上面那層 jar，所以會很快。
-->

---

# Registry 與 Image 的關係

「Registry 是儲存和分發 Image 的服務，Docker Hub 是預設的全球公開 Registry，提供超過十萬個開發者製作的 Image。」

常見的三種 Image 來源：

| 類型 | 說明 |
| --- | --- |
| Docker 官方 Image | 例如 `nginx`、`python`、`mysql`，由 Docker 官方維護 |
| 驗證發行商 Image | 由知名廠商（如 Bitnami）發布並驗證 |
| 個人 / 組織 Image | 開發者自己 push 上去的 Image |

<!--
知道 Image 是什麼之後，下一個問題是：Image 平常放在哪裡？

答案是 Registry，「儲存和分發 Image 的服務」。Docker Hub 是預設的公開 Registry，就像全世界最大的食譜分享網站，可以直接拿現成的食譜，也可以把自己的分享上去。

表格裡三種來源，挑重點看。在實際專案裡，我們很少從零開始做 Image，通常會先找官方 Image 當基礎，因為官方會定期修補安全漏洞，比較可靠。

另外要注意，Registry 不是只有 Docker Hub。很多公司會在內網架設自己的私有 Registry，等一下 push 的範例就會看到。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 常用指令：pull / push / images / rmi

<!--
觀念建立好了，接下來我們實際動手，把最常用的四個 Image 指令走一遍。
-->

---

# Image 常用指令總覽

| 指令 | 說明 |
| --- | --- |
| `docker pull` | 從 Registry 下載 Image 到本機 |
| `docker push` | 把本機的 Image 上傳到 Registry |
| `docker images` | 列出本機所有的 Image |
| `docker images -a` | 連中間層 Image 也一併列出 |
| `docker rmi` | 刪除本機的 Image |
| `docker tag` | 幫 Image 新增一個標籤（常搭配 push 使用） |

<!--
先看一張總表，等一下每個指令都會拆開來看範例。

這幾個指令的名字都很直覺。pull 是從 Registry 拉下來，push 是推上去，images 是列出本機的 Image，rmi 是 remove image 的縮寫。

這裡有一個很多新手會搞混的地方。`docker rmi` 刪的是 Image，`docker rm` 刪的是 Container，兩個字很像，操作對象完全不同。

最後一行的 `docker tag` 是幫 Image 新增標籤，通常會跟 push 搭配使用。
-->

---

# docker pull — 範例

先把 TaskBoard 之後會用到的基礎 Image 都抓下來：

```bash
# 沒指定 tag，預設抓 latest（不建議用在專案上）
docker pull mysql

# 指定版本，TaskBoard 專案統一用這幾個
docker pull mysql:8.4                      # 資料庫
docker pull eclipse-temurin:21-jre-alpine  # 跑 taskboard-api.jar
docker pull nginx:1.27-alpine              # 服務 Angular 打包後的靜態檔

# 從公司內部私有 registry 下載
docker pull registry-host:5000/myadmin/taskboard-api:1.0.0
```

執行後 Docker 會逐層（layer）顯示下載進度，如果本機已經有相同的 Layer，會直接顯示 `Already exists`，不會重複下載。

<!--
這一頁我們用 pull，把 TaskBoard 之後會用到的基礎 Image 先抓下來。

先看第一行，`docker pull mysql` 沒有指定 tag，Docker 會預設抓 latest。很多人以為 latest 代表最新的穩定版，其實它只是一個標籤名稱，維護者想指到哪個版本都可以。哪天 MySQL 出了新的大版本，latest 就會悄悄換掉，Spring Boot 的連線可能直接出問題。所以專案裡我們一律鎖定版本，像下面寫的 `mysql:8.4`。

再看 `eclipse-temurin:21-jre-alpine` 這個名字。21 是 Java 版本，jre 表示只有執行環境，alpine 是很精簡的 Linux。選 jre 加 alpine，Image 可以從四百多 MB 降到一百多 MB。

執行後，Docker 會一層一層顯示下載進度。本機已經有的 Layer，會直接顯示 Already exists。
-->

---

# docker images / docker rmi — 範例

查看本機有哪些 Image，以及刪除不需要的 Image：

```bash
# 列出本機所有 Image
docker images

# REPOSITORY        TAG               IMAGE ID       SIZE
# taskboard-api     1.0.0             8f3c1a92be04   198MB
# taskboard-api     latest            8f3c1a92be04   198MB
# taskboard-web     1.0.0             2d47e5b310cc   52MB
# mysql             8.4               a19b7c4d5e6f   612MB
# eclipse-temurin   21-jre-alpine     71e0d3f8a1b2   187MB

# 用 Image ID 刪除
docker rmi 2d47e5b310cc

# 用 repository:tag 刪除
docker rmi taskboard-web:1.0.0
```

<!--
pull 下來之後，我們用 images 看本機有什麼，用 rmi 清掉不要的。

看這份清單，`taskboard-api` 的 1.0.0 和 latest 兩列，IMAGE ID 完全一樣。代表它們是同一份 Image，只是貼了兩張不同的標籤，硬碟上只佔一份空間。

也看一下大小。`taskboard-web` 只有 52MB，因為裡面只有靜態檔案加上精簡版的 nginx。`mysql` 最大，六百多 MB。

刪除的時候，可以用 Image ID，也可以用名稱加 tag。要注意，如果有 Container 還在使用這個 Image，就算是停止狀態，rmi 也會失敗，要先把 Container 刪掉。

刪除成功後，再執行一次 `docker images`，那個 Image 就不會出現了。
-->

---

# docker push — 語法與選項

`docker image push [OPTIONS] NAME[:TAG]`，用來把本機的 Image 上傳到 Registry。

| 選項 | 說明 |
| --- | --- |
| `-a`, `--all-tags` | 一次推送這個 Image 的所有標籤 |
| `--platform` | 指定推送特定平台的版本，例如 `linux/amd64` |
| `-q`, `--quiet` | 只顯示精簡輸出，不顯示詳細進度 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>重點：</b> push 之前一定要先 <code>docker login</code> 完成登入驗證，而且 Image 名稱前面要帶上目標 Registry 的位置，才知道要推去哪裡。
</div>

<!--
接下來看 push，它跟 pull 剛好相反，是把本機的 Image 上傳到 Registry，讓其他人或伺服器直接拉下來用。

表格裡最常用的是 `-a`，一次推送同一個 Image 的所有標籤。

這頁下面的提醒很重要。push 之前一定要先 `docker login`，沒登入會直接被拒絕，錯誤訊息通常是 unauthorized。另外，Image 名稱前面要帶上 Registry 的位置，Docker 才知道要推去哪裡。

推送的時候，Docker 會同時上傳好幾個 Layer，所以進度條會一起跳動，這是正常的。
-->

---

# docker push — 範例

把本機建好的 `taskboard-api` 推到公司內部 Registry，完整流程如下：

```bash
# Step 1：登入 registry
docker login registry-host:5000

# Step 2：幫本機 Image 打上目標位置的 tag
docker image tag taskboard-api:1.0.0 registry-host:5000/myadmin/taskboard-api:1.0.0

# Step 3：推送上去
docker push registry-host:5000/myadmin/taskboard-api:1.0.0

# 一次推送這個 repository 的所有標籤版本
docker push -a registry-host:5000/myadmin/taskboard-api
```

<!--
這一頁走一次完整的 push 流程，把 `taskboard-api` 推到公司的私有 Registry。

關鍵在 Step 2。我們不會直接推送 `taskboard-api:1.0.0`，而是先用 `docker image tag` 再貼一張標籤，把 Registry 的位址寫進名稱裡。沒有寫位址的話，Docker 預設就是送去 Docker Hub。

要注意，tag 不是改名，而是新增一張標籤。原本的名稱還在，兩個名稱指向同一個 Image ID。

最後一行的 `-a`，會一次推送這個 repository 的所有版本。

在實際專案裡，這幾行通常不是手動打的，而是寫在 CI 腳本裡，這條流程我們第八章會完整走一次。推送成功後，到 Registry 的網頁上，就能看到剛上傳的 repository 和 tag。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Docker Hub 與 Tag 命名規則

<!--
指令會用了，接下來看兩件實務上一定會遇到的事：Docker Hub 這個平台，以及 Tag 該怎麼命名。
-->

---

# 什麼是 Docker Hub？

「Docker Hub 是全球最大的容器映像庫，協助開發者存儲、管理和分享 Image，確保容器化應用程式的可靠部署與分發。」

Docker Hub 提供的核心功能：

| 功能 | 說明 |
| --- | --- |
| Repository（儲存庫）| 存放同一個專案不同版本 Image 的地方，公開儲存庫無限制，也有私人儲存庫選項 |
| 官方 / 驗證 Image | 提供品質有保證的現成 Image，可以直接拿來當基礎 |
| 自動化建置 | 可串接 GitHub / Bitbucket，程式碼一 push 就自動建置新 Image |
| 搜尋與探索 | 可以直接在網站或用 `docker search` 找需要的 Image |

<!--
我們可以把 Docker Hub 想成 Image 界的 GitHub。GitHub 存程式碼，Docker Hub 存打包好的 Image，一樣分成公開和私人儲存庫。

表格挑兩個重點。Repository 是存放同一個專案各個版本的地方。官方和驗證 Image 則是品質有保證的現成 Image，可以直接拿來當基礎。

在實際專案裡，公司內部的專案通常放私人儲存庫，避免商業邏輯外流。開源工具類的 Image，才會放在公開儲存庫。

這裡要提醒一下，Docker Hub 上任何人都可以上傳 Image，不是每個都可信。挑選的時候，優先選 Docker Official Image 或 Verified Publisher 的來源。
-->

---

# Tag（標籤）命名規則

「Tag 是附加在 Image 名稱後面的識別字串，格式為 `repository:tag`，用來區分同一個 Image 的不同版本。」

常見的命名慣例：

| 命名方式 | 範例 | 用途 |
| --- | --- | --- |
| 語意化版本 | `taskboard-api:1.4.2` | 明確標示版本號，正式環境首選 |
| 主版本簡寫 | `taskboard-api:1.4`、`taskboard-api:1` | 允許在小版本內自動更新 |
| latest | `taskboard-api:latest` | 預設標籤，不建議在正式環境依賴它 |
| 環境標籤 | `taskboard-api:staging`、`taskboard-api:prod` | 依部署環境區分 |
| Commit / 建置編號 | `taskboard-api:git-a1b2c3d` | 精確對應到某一次程式碼版本，方便追蹤 |

<!--
Tag 就是貼在 Image 名稱後面的版本標記，格式是 repository 冒號 tag。

想像一下，如果食譜上永遠只寫「最新版」，不寫日期，我們永遠不知道手上這份是哪一天改的。Tag 也是一樣，命名越清楚，之後追查問題或回滾版本就越輕鬆。

表格裡最重要的是語意化版本，例如 1.4.2，正式環境首選。比較成熟的團隊會同時打好幾個 tag，例如 1.4.2 再加上 commit 編號，既好讀，又能精確對應到某一次程式碼。

最容易踩的坑是正式環境只用 latest。latest 會一直被覆蓋，今天部署的 latest 跟明天的可能完全不同，就會出現本機沒問題、正式環境卻壞掉的情況。
-->

---

# Tag 命名 — 實際範例

TaskBoard 後端發布一個新版本的完整流程：

```bash
# 在 taskboard-api/ 目錄下建置 Image（Dockerfile 第四章會寫）
docker build -t taskboard-api:latest .

# 同時貼上不同精細度的版本 tag
docker image tag taskboard-api:latest taskboard-api:1.4.2
docker image tag taskboard-api:latest taskboard-api:1.4

# 推送到 Docker Hub（帳號為 myaccount）
docker image tag taskboard-api:latest myaccount/taskboard-api:1.4.2
docker push myaccount/taskboard-api:1.4.2

# 一次推送所有本機的 taskboard-api 標籤
docker push -a myaccount/taskboard-api
```

<!--
這一頁把 Tag 命名落地成實際的指令，看 TaskBoard 後端怎麼發布新版本。

先 build 出 latest，接著同一個 Image 再貼上 1.4.2 和 1.4 兩個標籤。這樣不同環境可以各取所需。測試環境固定抓 1.4，自動吃到修 bug 的小版本。正式環境鎖死 1.4.2，什麼都不會自己變。

這個 1.4.2 實務上通常來自 `build.gradle` 裡的 version 設定，CI 讀出來直接當 tag，程式碼版本和 Image 版本就永遠對得起來。

推送到 Docker Hub 時，名稱前面一定要帶帳號，例如 `myaccount/taskboard-api`，不然會被當成要推到官方的命名空間，直接被拒絕。

完成後，到 Docker Hub 的頁面上，就能看到這些 tag。
-->

---
layout: default
---

# 練習：準備 TaskBoard 的基礎 Image
### 任務說明

我們要把 TaskBoard 後面幾章需要的基礎 Image 先準備好。請完成以下操作：

1. 從 Docker Hub 下載 `eclipse-temurin` 的 `21-jre-alpine` 版本（之後用來跑 `taskboard-api.jar`）
2. 用 `docker images` 確認本機已經有這個 Image，並記下它的 IMAGE ID 與大小
3. 幫這個 Image 新增一個標籤，命名為 `taskboard-runtime:v1`
4. 刪除原本的 `eclipse-temurin:21-jre-alpine` 標籤（保留 `taskboard-runtime:v1`）
5. 再執行一次 `docker images`，確認 `taskboard-runtime:v1` 還在，而且 IMAGE ID 跟第 2 步記下的一樣

<!--
接下來是本章的練習，我們順便把第四章要用的 runtime Image 先準備好。

任務是：下載 `eclipse-temurin:21-jre-alpine`，記下它的 IMAGE ID，幫它貼上新標籤 `taskboard-runtime:v1`，再刪掉原本的標籤。

請大家先想一個問題：刪掉 `eclipse-temurin` 這個標籤之後，剛剛貼的 `taskboard-runtime:v1` 會不會一起消失？

我們先暫停一下，自己動手試試看。

【講師】給大家三到五分鐘操作，提醒第五步要比對 IMAGE ID。
-->

---
layout: default
---

# 練習：解題提示
### 提示說明

```bash
docker pull eclipse-temurin:21-jre-alpine
docker images                       # 記下 IMAGE ID，約 187MB
docker image tag eclipse-temurin:21-jre-alpine taskboard-runtime:v1
docker rmi eclipse-temurin:21-jre-alpine
docker images                       # taskboard-runtime:v1 還在，ID 不變
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>提示：</b> tag 只是貼在同一個 Image ID 上的標籤紙，刪除其中一個標籤不會刪掉底層的 Image，只要還有至少一個 tag 指著它，Image 就還在。
</div>

<!--
我們來看解答。前面四個指令依序就是 pull、images、tag、rmi。

回到剛才的問題，`taskboard-runtime:v1` 不會消失。因為 tag 只是貼在同一個 Image ID 上的標籤，刪掉其中一張，不會刪到底層的 Image。只要還有至少一個 tag 指著它，Image 就還在。反過來說，最後一個 tag 也被刪掉時，Image 才會真的從硬碟上消失。

所以最後一次 `docker images`，只會看到 `taskboard-runtime:v1`，而且 IMAGE ID 跟一開始記下的完全一樣。
-->

---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — 映像檔管理

<table class="summary-table">
<thead>
<tr><th>重點</th><th>說明</th></tr>
</thead>
<tbody>
<tr><td>Image vs Container</td><td>Image 是標準化的封裝模板，Container 是拿它啟動後的執行實例</td></tr>
<tr><td>Layer 架構</td><td>Layer 一旦建立就不可修改，相同 Layer 可在不同 Image 間共用</td></tr>
<tr><td>核心指令</td><td><code>pull</code> 下載、<code>push</code> 上傳、<code>images</code> 查看清單、<code>rmi</code> 刪除</td></tr>
<tr><td>Registry</td><td>Docker Hub 是預設的全球 Registry，也可架設私有 Registry 存放內部 Image</td></tr>
<tr><td>Tag 命名</td><td>建議搭配語意化版本（例如 <code>1.4.2</code>），正式環境避免只依賴 <code>latest</code></td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> Image 一旦 build 完成就不可變，要更新版本就該貼上新的 Tag，而不是覆蓋 <code>latest</code>。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入容器操作，學習 `run`、`exec`、`logs` 等每天都會用到的指令。
</div>

<!--
我們回顧一下這一章。

第一，Image 是標準化的模板，Container 是用它啟動的實例，就像食譜和端上桌的菜。第二，Image 由一層層的 Layer 疊起來，建立後不能修改，相同的 Layer 可以共用。第三，pull、push、images、rmi 是每天都會用到的四個指令。第四，Docker Hub 是預設的 Registry，公司也可以架私有的。最後，Tag 建議用語意化版本，正式環境不要只依賴 latest。

學完這一章，我們已經能把 Image 貼上有意義的版本，推送到 Registry 跟團隊分享。下一章，我們會進入容器操作。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
這一章我們把 Image 從裡到外看了一遍，從分層結構，到下載、上傳和版本命名。

記得剛才準備好的 `taskboard-runtime:v1`，第四章寫 Dockerfile 時還會用到。我們下一章見。

【講師】開放 Q&A，可以引導大家回想 tag 和 Image ID 的關係、latest 的風險。
-->
