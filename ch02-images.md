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
大家好，歡迎來到第二章：映像檔管理。

上一章我們認識了 Docker 的基本概念，知道 Container（容器）是隔離的執行環境。這一章我們要更深入地了解，這些 Container 到底是「用什麼做出來的」——答案就是 Image（映像檔）。

學完這一章，我們會知道 Image 是怎麼組成的、怎麼從 Docker Hub 拉取和推送 Image，以及 tag（標籤）命名有什麼慣例。這些是我們每天寫 Docker 指令都會用到的基本功。
-->

---
layout: default
---

# Outline

<div class="text-left" style="font-size: 1.1rem;">

1. Image 概念與 Layer 結構
2. 常用指令：pull / push / images / rmi
3. Docker Hub 與 Tag 命名規則
4. 練習題
5. 總結

</div>

<!--
今天的內容分成三大部分。

第一部分先建立 Image 的心智模型，搞懂什麼是 Layer（層）；第二部分帶大家實際操作最常用的四個指令；第三部分介紹 Docker Hub 怎麼用，還有 tag 該怎麼命名才不會搞混版本。

最後會有兩題練習，讓大家把指令實際打一遍，印象才會深。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第一部分
## Image 概念與 Layer 結構

<!--
我們先從最基礎的問題開始：Image 到底是什麼？為什麼它要分層？

這部分建立好觀念之後，後面學指令會輕鬆很多，因為每個指令其實都是在操作「Image 這個東西」。
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
大家可以想像我們自己家裡的便當店，或是連鎖速食店好了。

如果每一分店都各自發揮、沒有標準食譜，那消費者吃到的口味就會參差不齊。Docker Image 解決的就是軟體世界裡類似的問題：不管在誰的電腦上、在哪台伺服器上執行，只要用同一個 Image，跑出來的環境就會一模一樣。

這裡的易錯點是：Image 跟 Container 常常被搞混。⚠️ 大家要記得，Image 是「靜態」的模板，不會自己動；Container 是拿這個模板「啟動」之後的執行實例，是動態的、正在跑的東西。

預期大家聽完這頁，能夠一句話說出 Image 跟 Container 的差別。
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
這頁在講 Image 為什麼要分層，這其實是 Docker 設計裡很聰明的一點。

生活比喻的話，大家可以想成蓋房子：地基打好之後，我們不會把地基敲掉重打，而是往上疊加新的樓層。Docker Image 也是一樣，每一層都是疊加上去的變更，底下的 Layer 不會被修改。

這樣設計的好處是：如果兩個 Image 都是「Python 基礎環境」，那這一層只要下載一次，兩個 Image 可以共用，不用重複佔用硬碟空間，下載速度也會變快。

⚠️ 易錯點：很多同學會以為修改 Image 裡的檔案就是「改掉原本的 Layer」，但其實 Docker 是幫我們建立一個新的 Layer 疊上去，原本的 Layer 完全不會被動到。這也是為什麼 Image 是「不可變（immutable）」的。

用 TaskBoard 來對照就很有感：我們每天改 Controller 改個十幾次，但底層的 Alpine 跟 JRE 21 從頭到尾沒變，所以每次重新建 Image，真正需要重做的只有最上面那層 jar，這就是為什麼容器化的專案 rebuild 可以那麼快。

預期結果：大家聽完能理解，為什麼下載新 Image 時，有時候會看到「有幾層很快就下載完」——那是因為本機已經有一樣的 Layer 了。
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
這頁把「Image」跟「Registry」的關係講清楚，讓同學知道 Image 平常放在哪裡、我們去哪裡找。

生活比喻的話，Registry 就像是「食譜分享網站」，Docker Hub 就是目前全世界最大的那個食譜網站，上面有各種現成的食譜可以直接拿來用，也可以把自己研發的食譜分享上去。

業界實務上，我們幾乎不會每個 Image 都自己從零開始寫，而是先去 Docker Hub 找官方 Image 當基礎，這樣比較安全也比較省力，因為官方 Image 通常會定期更新修補安全漏洞。

⚠️ 易錯點：同學常常以為只有 Docker Hub 這一個 Registry，但其實企業內部也常常會架設「私有 Registry」，例如自己公司內網的 registry-host。這點我們在後面 push 的章節會看到範例。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第二部分
## 常用指令：pull / push / images / rmi

<!--
觀念建立好了，接下來我們就實際動手，把 Image 相關最常用的四個指令走過一遍：pull、push、images、rmi。

這四個指令幾乎是我們每天都會用到的基本操作，大家一定要練到反射動作。
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
這頁先給大家一張總表，等一下每個指令都會拆開來看實際範例。

大家可以先注意到，這幾個指令的動詞都很直覺：pull 是「拉」下來、push 是「推」上去、images 是「列出」、rmi 是 remove image 的縮寫。

⚠️ 易錯點：`docker rmi` 不是 `docker rm`，`rm` 是刪除 Container，`rmi` 才是刪除 Image，兩個字很像但操作對象完全不同，很多新手會搞混。
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
這頁帶大家實際操作 pull 指令，順便把 TaskBoard 後面幾章要用的基礎 Image 先準備好。

先看第一個範例，`docker pull mysql`，沒有指定 tag，Docker 預設會抓 `latest` 這個標籤。下面才是我們專案真正的做法：明確寫出 `mysql:8.4`。這在正式環境非常重要，因為 latest 會一直變動，哪天 MySQL 出了 9.0，我們的 latest 就悄悄升上去了，Spring Boot 的 driver 相容性可能直接出問題。

⚠️ 易錯點：很多同學誤以為 `latest` 代表「最新穩定版」，但 latest 只是「一個標籤名稱」，維護者想指到哪個版本都可以。專案一律鎖版本。

另外注意 `eclipse-temurin:21-jre-alpine` 這個名字：temurin 是 Eclipse 基金會維護的 OpenJDK 發行版，`21` 是 Java 版本，`jre` 表示只有執行環境沒有編譯器，`alpine` 是很精簡的 Linux 發行版。光是選 jre 不選 jdk、選 alpine 不選一般版，Image 就可以從四百多 MB 降到一百多 MB。

預期結果：執行完用 `docker images`，應該可以看到這幾個 Image 都躺在本機了。
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
這頁把 images 跟 rmi 放在一起講，因為它們是一組「查看 → 清理」的操作。

大家看這份清單，`taskboard-api` 的 `1.0.0` 跟 `latest` 兩列，IMAGE ID 都是 8f3c1a92be04，完全一樣——代表它們其實是同一份 Image，只是貼了兩張不同的標籤紙，就像同一道菜可以同時叫「今日特餐」跟「主廚推薦」，硬碟上只佔一份空間。

也順便看一下大小：`taskboard-web` 只有 52MB，因為 Angular 打包出來就是一堆靜態檔案加上精簡版 nginx；`taskboard-api` 198MB，多出來的是 JRE；`mysql` 最肥，600 多 MB。這個大小差異在第四章講 multi-stage build 的時候會更有感覺。

⚠️ 易錯點：如果這個 Image 目前有 Container 正在使用（不管是執行中還是停止狀態），直接 `docker rmi` 會刪除失敗，要先把相關的 Container 刪掉，或加上 `-f` 強制刪除（但要小心使用）。

預期結果：刪除成功後，再執行一次 `docker images`，剛剛那個 Image 就不會出現在清單裡了。
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
這頁講 push 指令的語法結構，實際範例下一頁馬上就會看到。

push 就是跟 pull 反過來，把我們本機做好的 Image 上傳到 Registry，讓其他人或其他伺服器可以直接 pull 下來用，不用再重新建置一次。

⚠️ 易錯點：push 之前一定要先登入，沒登入會直接被拒絕，錯誤訊息通常會提示 unauthorized。另外要注意，Docker daemon 預設會「同時」推送 Image 的多個 Layer，不是一層一層乖乖排隊，所以進度條看起來會同時跳動好幾條。
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
這頁走一次完整的 push 流程，這也是實際工作上最常用到的組合技：tag + push。

大家可以看到，我們不會直接把本機叫 `taskboard-api:1.0.0` 的 Image push 出去，而是要先用 `docker image tag` 幫它「重新貼一張標籤」，把目標 Registry 的位置寫進去，Docker 才知道這個 Image 該送去哪裡。沒有前綴的話，Docker 預設就是往 Docker Hub 送。

實務上這幾行不會是人手動打的，而是寫在 CI 腳本裡：Gradle build 完 jar、docker build 出 Image、打上 commit 版本的 tag、push 上 registry，然後伺服器那端 pull 下來重啟。這整條線我們第八章會完整走一次。

⚠️ 易錯點：`docker image tag` 不是「改名」，而是「新增一張標籤」，原本的 `taskboard-api:1.0.0` 還是會存在，本機會同時看到兩個名稱但指向同一個 Image ID。

預期結果：push 成功後，到 Docker Hub 或自己架設的 Registry 網頁上，應該就能看到剛剛上傳的這個 repository 跟 tag。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第三部分
## Docker Hub 與 Tag 命名規則

<!--
第三部分我們來看 Docker Hub 這個平台本身，還有一個大家實務上一定會遇到的問題：Tag 到底該怎麼命名？

命名沒有規範，團隊合作的時候會很容易搞混版本，這部分會給大家一套實用的命名慣例。
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
這頁介紹 Docker Hub 這個平台整體長什麼樣子。

我們可以把 Docker Hub 想成是「Image 界的 GitHub」——GitHub 存的是程式碼，Docker Hub 存的是打包好的 Image。而且它跟 GitHub 一樣，也有公開跟私人儲存庫的區別。

業界實務上，公司內部的專案通常會用私人 Repository，避免商業邏輯外流；而開源專案或工具類的 Image，通常會放在公開 Repository 讓大家自由使用。

⚠️ 易錯點：很多新手會以為 Docker Hub 上的 Image 都是安全可信的，但其實任何人都可以上傳 Image，並不是每個都是官方認證。挑選 Image 時，建議優先選「Docker Official Image」或標示為「Verified Publisher」的來源。
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
這頁是整個 Tag 命名規則的重點，也是我們實際團隊合作時最容易吵架的地方，一定要花時間講清楚。

生活比喻的話，如果便當店的便當都叫「今日便當」而不寫日期，我們永遠不知道自己吃到的是哪一天做的。Tag 命名也是一樣的道理，命名得越清楚，之後追查問題或回滾版本才會越輕鬆。

業界實務上，比較成熟的團隊會同時打上多個 tag，例如同一個建置同時打上 `1.4.2` 跟 `git-a1b2c3d`，這樣既方便閱讀版本號，又能精確對應到程式碼的那次 commit。

⚠️ 易錯點：正式環境（production）千萬不要只依賴 `latest` 這個標籤，因為 latest 會一直被覆蓋更新，今天部署的 latest 跟明天的 latest 內容可能完全不同，容易造成「本機測試沒問題，正式環境卻爆炸」的狀況。
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
這頁把 Tag 命名規則落地成實際會打的指令，讓大家看到「概念」跟「動手做」是怎麼串起來的。

大家可以注意到，這裡示範了同一個建置同時貼上三種不同精細度的 tag：`latest`、`1.4`、`1.4.2`，這在實務上很常見，方便不同情境的使用者選擇要抓哪一個版本。比方說測試環境可以固定抓 `1.4`，自動吃到修 bug 的小版本；正式環境則鎖死 `1.4.2`，什麼都不會自己動。

順帶一提，這個 `1.4.2` 從哪裡來？實務上通常就是 `build.gradle` 裡面 `version = '1.4.2'` 那一行，CI 腳本讀出來直接當 tag 用，程式碼版本跟 Image 版本就永遠對得起來。

⚠️ 易錯點：推送到 Docker Hub 時，Image 名稱前面一定要帶帳號或組織名稱（例如 `myaccount/taskboard-api`），不然 Docker 會預設當作要推去 Docker 官方的命名空間，直接被拒絕。

預期結果：推送完成後，到 Docker Hub 網站上該帳號的 Repository 頁面，應該能同時看到 `1.4.2` 和 `1.4` 兩個 tag。
-->

---
layout: default
---

# 練習 1：準備 TaskBoard 的基礎 Image
### 任務說明

我們要把 TaskBoard 後面幾章需要的基礎 Image 先準備好。請完成以下操作：

1. 從 Docker Hub 下載 `eclipse-temurin` 的 `21-jre-alpine` 版本（之後用來跑 `taskboard-api.jar`）
2. 用 `docker images` 確認本機已經有這個 Image，並記下它的 IMAGE ID 與大小
3. 幫這個 Image 新增一個標籤，命名為 `taskboard-runtime:v1`
4. 刪除原本的 `eclipse-temurin:21-jre-alpine` 標籤（保留 `taskboard-runtime:v1`）
5. 再執行一次 `docker images`，確認 `taskboard-runtime:v1` 還在，而且 IMAGE ID 跟第 2 步記下的一樣

<!--
這一題是基本功練習，檢驗大家對 pull / images / tag / rmi 四個指令的熟練度，順便把第四章要用的 runtime Image 先抓下來。

引導思考：大家覺得如果直接刪除 `eclipse-temurin:21-jre-alpine`，剛剛貼的 `taskboard-runtime:v1` 會不會也一起消失？想想看 Image ID 跟 tag 之間的關係。第 5 步就是要大家自己驗證這件事。
-->

---
layout: default
---

# 練習 1：解題提示
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
公布解答，順便解釋第 4 步背後的原理。

⚠️ 這題最容易錯的地方，是同學會擔心「刪掉 eclipse-temurin 會不會連 taskboard-runtime:v1 也一起不見」，答案是不會。反過來說，如果最後一個 tag 也被刪掉，那份 Image 才會真的從硬碟上消失。

預期結果：最後一次 `docker images` 只會看到 `taskboard-runtime:v1`，看不到 `eclipse-temurin`，但兩者的 IMAGE ID 完全相同。
-->

---
layout: default
---

# 練習 2：發布 taskboard-api 到私有 Registry
### 任務說明

TaskBoard 後端修完一批 bug，要發布 `2.0.0` 版到公司內部的私有 Registry（位址 `registry-host:5000`，命名空間 `myadmin`）：

1. 本機已經有一個建置好的 Image，叫做 `taskboard-api:latest`
2. 幫它同時貼上 `2.0.0` 與 `2.0` 兩種精細度的版本標籤，並加上正確的 Registry 位置前綴
3. 登入該 Registry
4. 把 `2.0.0` 這個版本推送上去
5. 想一想：測試環境的部署腳本應該固定抓哪一個 tag？正式環境呢？

<!--
這題比第一題更貼近實際工作場景，把 tag 命名規則跟 push 指令結合在一起。

引導思考：如果之後要讓其他同事直接抓「最新的 2.0 系列版本」而不用記完整版本號，我們應該怎麼設計 tag？

第 5 小題是這章的核心觀念：測試環境抓 `2.0`，這樣我們一發 2.0.1 的修補版，測試環境重啟就自動吃到新版；正式環境鎖 `2.0.0`，除非有人明確改版本號，否則永遠不會變。

⚠️ 提醒大家，這題重點不只是「指令打得出來」，而是要想清楚 tag 該怎麼命名才符合語意化版本的精神。
-->

---
layout: default
---

# 練習 2：解題提示
### 提示說明

```bash
# 貼上兩種精細度的版本標籤，並加上 registry 前綴
docker image tag taskboard-api:latest registry-host:5000/myadmin/taskboard-api:2.0.0
docker image tag taskboard-api:latest registry-host:5000/myadmin/taskboard-api:2.0

# 登入私有 registry
docker login registry-host:5000

# 推送指定版本
docker push registry-host:5000/myadmin/taskboard-api:2.0.0
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>提示：</b> 想把 2.0.0 跟 2.0 一次推送完，可以改用 <code>docker push -a registry-host:5000/myadmin/taskboard-api</code>。第 5 小題：測試環境抓 <code>2.0</code>（自動吃到修補版），正式環境鎖 <code>2.0.0</code>（版本完全固定）。
</div>

<!--
公布解答，也順便補充 `-a` 選項的用法，讓同學知道有更省力的做法。

⚠️ 易錯點提醒：Image 名稱前面一定要完整帶上 `registry-host:5000/myadmin/` 這串前綴，這是 Docker 用來判斷「要推去哪個 Registry、哪個帳號底下」的依據，漏掉就會推錯地方或直接失敗。

預期結果：登入成功、推送完成後，去該 Registry 的網頁介面應該能看到 `my-app` 這個 repository，底下有 `2.0.0` 這個 tag。
-->

---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — 映像檔管理

<table class="summary-table">
<tr><th>重點</th><th>說明</th></tr>
<tr><td>Image vs Container</td><td>Image 是標準化的封裝模板，Container 是拿它啟動後的執行實例</td></tr>
<tr><td>Layer 架構</td><td>Layer 一旦建立就不可修改，相同 Layer 可在不同 Image 間共用</td></tr>
<tr><td>核心指令</td><td><code>pull</code> 下載、<code>push</code> 上傳、<code>images</code> 查看清單、<code>rmi</code> 刪除</td></tr>
<tr><td>Registry</td><td>Docker Hub 是預設的全球 Registry，也可架設私有 Registry 存放內部 Image</td></tr>
<tr><td>Tag 命名</td><td>建議搭配語意化版本（例如 <code>1.4.2</code>），正式環境避免只依賴 <code>latest</code></td></tr>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> Image 一旦 build 完成就不可變，要更新版本就該貼上新的 Tag，而不是覆蓋 <code>latest</code>。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入容器操作，學習 `run`、`exec`、`logs` 等每天都會用到的指令。
</div>

<!--
這一章的重點回顧一下。

我們從「Image 是食譜、Container 是端出來的菜」這個比喻出發，理解了 Image 的分層設計，接著實際操作了 pull、push、images、rmi 四個最常用的指令，最後學了 Docker Hub 的功能跟 Tag 命名的實務慣例。

學完這一章，我們應該能夠自己把一個應用程式打包、貼上有意義的版本標籤，然後推送到 Registry 上跟團隊分享了。下一章我們會進一步認識容器操作的細節。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對 Image 的分層結構、pull/push/images/rmi 這幾個指令，或是 Tag 命名慣例，有沒有什麼疑問？都歡迎提出來討論。
-->
