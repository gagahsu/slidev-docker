---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: Docker 簡介
routeAlias: ch01
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">Docker 簡介</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「打包一次，到處都能跑」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
大家好，歡迎來到 Docker 課程的第一堂課。

在正式進入 Docker 之前，我們先來想一個大家可能都遇過的場景：明明程式在自己電腦上跑得好好的，一丟到別台機器、或是丟到伺服器上就出錯了。這堂課就是要解決這個「在我電腦上是可以跑的」的經典痛點。

今天這一章我們會學到三件事：第一，為什麼我們需要容器化，Container 跟傳統的虛擬機（VM）差在哪裡；第二，Docker 的架構長什麼樣子，Client、Daemon、Registry 這三個角色怎麼合作；第三，實際把 Docker Desktop 裝起來，並且用 hello-world 驗證安裝成功。

準備好的話，我們開始吧。
-->

---
layout: default
---

# Outline

- **第一部分：為什麼需要容器化** — VM vs Container 的差異
- **第二部分：Docker 架構** — Client / Daemon / Registry 怎麼合作
- **第三部分：安裝與驗證** — 安裝 Docker Desktop、跑第一個 hello-world
- **練習** — 用課程專案 TaskBoard 走一次 `docker run` 流程

<!--
跟大家說明一下今天的路線圖。

我們會先從「為什麼」開始，也就是容器化到底解決了什麼問題，順便比較一下容器跟虛擬機的差異，這是最基礎但也最容易被忽略的觀念。

接著我們會拆開 Docker 的架構，搞懂 Client、Daemon、Registry 這三個名詞到底各自負責什麼，指令下下去之後資料是怎麼流動的。

最後我們會捲起袖子實際安裝 Docker Desktop，並且用官方提供的 hello-world 映像檔驗證安裝有沒有成功。這三部分學完，大家就對 Docker 有一個完整的第一印象了。
-->

---
layout: default
---

# 課程貫穿專案：TaskBoard

這八章的範例與練習，都圍繞同一個專案 **TaskBoard（任務看板）**，剛好用上大家已經學過的三項技術：

| 元件 | 技術 | 專案資料夾 | 之後的 Image |
| --- | --- | --- | --- |
| 前端 | Angular（build 後用 nginx 服務） | `taskboard-web/` | `taskboard-web:1.0.0` |
| 後端 | Spring Boot + Gradle（Java 21） | `taskboard-api/` | `taskboard-api:1.0.0` |
| 資料庫 | MySQL 8.4 | `db/init.sql` | `mysql:8.4`（官方 Image） |

```
瀏覽器 → taskboard-web (nginx :80) → taskboard-api (:8080) → taskboard-db (:3306)
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>課程節奏：</b> 第 1～3 章先用官方 Image 把三個服務手動跑起來，第 4 章自己寫 Dockerfile 打包 API 與前端，第 5 章用 Compose 一次拉起整套，第 6～8 章處理網路、資料持久化與正式部署。
</div>

<!--
在進入觀念之前，先跟大家介紹這門課的「貫穿專案」。

大家之前已經學過 Spring Boot、Angular 跟 MySQL，這門課不會再教這三項技術本身，而是把它們當成素材：我們要學的是怎麼把一個真實的三層架構專案容器化。

專案叫 TaskBoard，就是一個任務看板，功能很單純——建立任務、查詢任務、更新狀態。業務邏輯刻意做得簡單，因為我們的重點在 Docker，不在 CRUD。

架構就是最標準的三層：Angular 打包成靜態檔案由 nginx 服務，使用者的請求打到 Spring Boot API，API 再連到 MySQL。

⚠️ 提醒大家一件很重要的事：這八章是連續的，第一章我們手動跑起來的 MySQL 容器，第七章還會回來處理它的資料持久化問題。所以每一章的練習請盡量真的動手做過，後面才不會接不上。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第一部分
# 為什麼需要容器化

<!--
第一部分，我們來聊聊「為什麼需要容器化」。

大家可以先想想自己有沒有遇過這種情況：專案在自己電腦上明明可以跑，結果換一台電腦、或是部署到伺服器上就整個壞掉。這種情況背後的原因通常都是環境不一致——版本不同、缺少某個套件、作業系統設定不一樣。

接下來我們就是要理解，容器化是怎麼解決這個問題的，還有它跟我們比較熟悉的虛擬機（VM）到底有什麼不同。
-->

---

# 什麼是容器化？

沒有容器化時，前端、後端 API、資料庫混裝在同一台機器上，版本與依賴套件互相干擾，換機器就得重新設定環境。

「Container（容器）就是應用程式各個組件的獨立隔離流程，每個 Container 擁有所有運作所需的內容，不依賴主機上預先安裝的依賴項。」

前端、API、資料庫可分別放進三個容器，各自帶著所需環境，彼此互不干擾，也不受主機環境影響。

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>生活比喻：</b> 容器就像便當盒，飯、菜、湯分開裝好，帶到哪裡打開都是同樣的味道，不會因為換了餐廳的餐具就走味。
</div>

<!--
先問大家一個問題：如果同一台電腦上同時裝了兩個專案，一個需要 Python 3.8，另一個需要 Python 3.11，會發生什麼事？沒錯，版本衝突，裝到最後兩邊都不能跑。

這就是容器化要解決的問題。Container 讓每個應用程式都活在自己的小房間裡，帶著自己需要的所有東西——函式庫、設定檔、執行環境，彼此互不影響。

生活化一點來說，就像便當盒，飯菜湯分開裝好，不管拿到哪裡打開都是一樣的味道，不會因為換了地方就走味、串味。

⚠️ 這裡要提醒大家，Container 不是虛擬機，它不是完整的作業系統，這個差異我們下一頁馬上會講到，是很多人剛學 Docker 時最容易搞混的地方。
-->

---

# VM vs Container：核心差異

| 面向 | Virtual Machine（虛擬機） | Container（容器） |
| --- | --- | --- |
| 結構 | 包含完整作業系統、核心（Kernel）、驅動程式 | 隔離的流程，只包含執行應用程式所需的檔案 |
| 資源開銷 | 高，每個 VM 都要啟動一份完整系統 | 低，多個 Container 共享主機核心 |
| 啟動速度 | 慢，通常要數十秒到數分鐘 | 快，通常幾秒內就能啟動 |
| 可攜性 | 較重，映像檔通常數 GB 起跳 | 輕量，映像檔通常只有數十到數百 MB |
| 隔離程度 | 完整系統隔離，安全邊界較強 | 流程層級隔離，共享核心資源 |

<!--
這張表格是今天最重要的一張，大家一定要搞清楚。

虛擬機是「連作業系統都自己帶一份」，就像每個人都自己蓋一棟完整的房子，裡面水電瓦斯全部自己接一套，當然很重、很慢。

容器則是共用主機的核心（Kernel），只帶自己需要的應用程式和函式庫，比較像大家住在同一棟大樓裡，共用水電管線，但每一戶室內裝潢、家具都是獨立的，互不干擾。

⚠️ 常見誤解是以為 Container 是「輕量版的 VM」，其實它們運作原理完全不同：VM 靠 Hypervisor 模擬硬體，Container 靠作業系統層級的隔離機制（namespace、cgroup）。這也是為什麼 Container 啟動速度可以快這麼多。

實務上這兩個技術也不是互斥的，雲端環境常常是「VM 裡面跑 Container」，先用 VM 做大範圍的隔離，裡面再用 Container 做應用程式層級的隔離，兩者互補。
-->

---

# 使用 Container 的注意事項

Container 的四個核心特性：

- **自含性**：每個 Container 帶著自己需要的一切，不依賴主機預裝的套件
- **隔離性**：Container 之間互相隔離，一個出問題不會拖垮其他人
- **獨立性**：可以獨立啟動、停止、刪除，不影響其他 Container
- **可攜性**：「開發機器上運行的 Container，在資料中心或雲端環境中運作方式相同」

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>注意：</b> Container 因為共用主機核心，所以隔離程度不如 VM 那麼徹底，如果對安全隔離要求非常高（例如多租戶環境），還是要搭配額外的安全機制。
</div>

<!--
這一頁把 Container 的四個特性攤開來講清楚：自含、隔離、獨立、可攜。

「可攜性」是我一開始講的「在我電腦上可以跑」問題的解答——因為 Container 把環境整包帶走，所以在你電腦上能跑，丟到別的機器上，只要有 Docker，一樣可以跑，環境完全一致。

⚠️ 但要提醒大家，Container 的隔離不是無敵的，它跟 VM 那種完整系統層級的隔離不一樣，Container 之間還是共用同一個主機核心。所以如果是需要嚴格安全隔離的場景，例如多個不同客戶共用同一台主機，通常還會搭配額外的安全設定，不能只靠 Container 本身。

業界實務上，Container 主要拿來解決「開發到部署環境一致」的問題，這也是為什麼幾乎所有現代的 CI/CD 流程都會用到 Docker。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第二部分
# Docker 架構

<!--
第二部分，我們來拆解 Docker 的架構。

前面我們知道了 Container 是什麼，但當我們打一個 `docker run` 指令的時候，背後到底發生了什麼事？誰負責接收這個指令？映像檔又是從哪裡來的？

這一部分我們會認識三個關鍵角色：Client、Daemon、Registry，搞懂他們之間怎麼互相合作。
-->

---

# Docker 的三大元件

| 元件 | 說明 |
| --- | --- |
| Client（客戶端） | 我們打指令的地方，例如 `docker run`，是使用者主要的互動介面 |
| Daemon（守護行程） | 背景執行的 `dockerd`，負責實際建立、管理 Image、Container、Network |
| Registry（倉庫） | 儲存 Image 的地方，Docker Hub 是最常用的公開 Registry |

「Docker Client 與 Daemon 之間透過 REST API、UNIX socket 或網路介面通訊」，Docker Desktop 則整合 Daemon、Client、Compose 等工具，一次安裝即可完成部署。

<!--
先把三個角色的關係講清楚：Client 是我們打字的地方，Daemon 是真正做事的背景程式，Registry 則是倉庫，專門存放 Image。

大家可以把這個關係想成餐廳點餐：我們（Client）跟服務生說要點什麼餐，廚房（Daemon）收到訂單後開始準備，如果食材不夠，廚房就會去食材倉庫（Registry）調貨。

⚠️ 這裡要特別提醒，Client 跟 Daemon 不一定要在同一台機器上，Client 可以透過網路連到遠端的 Daemon，這也是為什麼 Docker 可以拿來管理遠端伺服器上的容器。
-->

---

# 指令怎麼流動：以 docker run 為例

當我們打下 `docker run` 這個指令，背後其實是 Client、Daemon、Registry 三方合作的結果。這裡直接把 TaskBoard 的資料庫跑起來：

```bash
docker run -d --name taskboard-db -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=rootpw \
  -e MYSQL_DATABASE=taskboard \
  mysql:8.4
```

1. **Client** 把 `docker run` 指令送給 **Daemon**
2. **Daemon** 檢查本機有沒有 `mysql:8.4` 這個 Image
3. 如果沒有，**Daemon** 會向 **Registry**（例如 Docker Hub）發出 `docker pull` 請求下載 Image
4. **Daemon** 用這個 Image 建立並啟動一個新的 **Container**
5. Container 啟動後，`-p 3307:3306` 把主機的 3307 port 映射到容器內的 3306 port

執行後，我們就能用平常慣用的 MySQL Workbench 或 DBeaver，連到 `localhost:3307` 使用這個資料庫。

<!--
這頁我們把「打指令之後發生了什麼事」完整走過一遍，這是理解 Docker 架構最直觀的方式。

我們直接拿 TaskBoard 專案的資料庫來當例子。以前大家在自己電腦上裝 MySQL，要下載安裝檔、設定密碼、設定路徑，弄個十幾分鐘跑不掉；現在一行指令就有一台乾淨的 MySQL 8.4。

帶大家看一下參數：`-d` 是背景執行，不然終端機會被 MySQL 的 log 佔滿；`--name taskboard-db` 幫容器取名字，之後所有指令都可以用這個名字操作它；`-p 3307:3306` 是 port 映射，冒號左邊是我們電腦的 port、右邊是容器裡面的 port；`-e` 則是帶環境變數進去，MySQL 官方 Image 就是靠 MYSQL_ROOT_PASSWORD 跟 MYSQL_DATABASE 這兩個變數來初始化的。

⚠️ 這裡特別解釋一下為什麼主機端用 3307 而不是 3306：很多同學電腦上本來就裝了 MySQL，佔用了 3306，如果這裡也用 3306 就會 port 衝突啟動失敗。用 3307 可以完全避開，容器內部仍然是標準的 3306。

流程走一遍：我們在 Client 打指令，Daemon 收到後先看看本機倉庫有沒有這個 Image，沒有的話就跑去 Registry（Docker Hub）拉一份下來，拉完之後才真正建立 Container 並啟動它。

⚠️ 易錯點：第一次執行會需要等待下載時間，mysql:8.4 大概幾百 MB，這是正常的，不是指令壞掉了。之後同一個 Image 再跑就直接用本機快取，一兩秒就起來。

預期結果：指令跑完會印出一長串容器 ID，用 GUI 工具連 localhost:3307、帳號 root、密碼 rootpw，就能看到裡面已經有一個叫 taskboard 的空資料庫。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 第三部分
# 安裝與驗證

<!--
第三部分，我們要動手把 Docker Desktop 裝起來。

前面講了這麼多觀念，現在終於可以實際操作了。這一部分我們會看系統需求、安裝步驟，最後用官方提供的 hello-world 映像檔驗證安裝是否成功。
-->

---

# 安裝 Docker Desktop（Windows）

| 項目 | 需求 / 說明 |
| --- | --- |
| 作業系統 | Windows 10 64 位元 22H2 以上，或 Windows 11 64 位元 23H2 以上 |
| 後端 | 建議使用 WSL 2（Windows Subsystem for Linux 2） |
| 硬體 | 64 位元處理器支援 SLAT，8GB 系統記憶體，BIOS/UEFI 啟用硬體虛擬化 |
| 安裝模式 | 個別使用者模式（免管理員權限，推薦）或全使用者模式 |
| WSL 版本檢查 | 安裝前後皆可用 `wsl --version` 確認 |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>補充：</b> 個人使用、教育及非商業開源專案可免費使用 Docker Desktop；超過 250 人或年營收超過 1000 萬美元的企業則需要付費訂閱。
</div>

<!--
安裝 Docker Desktop 之前，我們先確認一下環境條件，這張表格列出最重要的幾個需求。

現在絕大多數新的 Windows 電腦都建議用 WSL 2 這個後端，它讓 Windows 可以跑一個真正的 Linux 核心，Docker 容器就是靠這個核心運作的。

⚠️ 易錯點：很多人安裝失敗是因為忘記在 BIOS 裡開啟硬體虛擬化功能，或是 WSL 2 版本太舊。安裝前可以先用 `wsl --version` 檢查一下版本。

補充一下授權部分，個人學習完全不用擔心，免費使用沒有問題，只有規模比較大的企業才需要付費訂閱，這點大家不用太緊張。
-->

---

# 安裝 Docker Desktop — 範例

```powershell
# 個別使用者模式安裝（免管理員權限，推薦）
"Docker Desktop Installer.exe" install --user

# 用 PowerShell 執行並等待安裝完成
Start-Process 'Docker Desktop Installer.exe' -Wait -ArgumentList 'install', '--user'

# 安裝前後檢查 WSL 版本
wsl --version
wsl --update
```

安裝完成後，從開始功能表搜尋「Docker」並開啟 Docker Desktop，第一次啟動需要同意訂閱服務條款，之後 Docker Desktop 就會自動啟動 Daemon，讓我們可以開始使用 `docker` 指令。

<!--
這頁帶大家看實際的安裝指令。大部分人會直接用滑鼠雙擊安裝程式走互動式安裝，但如果是在公司內部要批次佈署，也可以用命令列參數自動化安裝，像這裡的 `--user` 就是指定用個別使用者模式，不需要系統管理員權限。

⚠️ 易錯點：第一次啟動 Docker Desktop 一定要記得同意授權條款，不然 Docker Desktop 是不會啟動的，這時候會覺得「怎麼裝完打不開」，其實只是條款還沒按同意。

預期結果：Docker Desktop 啟動之後，工作列會出現鯨魚圖示，圖示穩定顯示（不再轉圈圈）就代表 Daemon 已經準備好，我們可以打開終端機開始下指令了。
-->

---

# 安裝 Docker Desktop（macOS）

| 項目 | 需求 / 說明 |
| --- | --- |
| 晶片 | Apple Silicon（M 系列）或 Intel 皆支援 |
| 作業系統 | 現行 macOS 版本及前兩個主要版本 |
| 硬體 | 至少 4GB RAM |
| Rosetta 2 | Apple Silicon 建議安裝，非必要 |
| 安裝檔 | 依晶片類型下載對應的 `Docker.dmg` |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>補充：</b> Apple Silicon 與 Intel 版本的安裝檔不同，下載前先確認自己的晶片類型（選單列 → 關於這台 Mac）。
</div>

<!--
Mac 安裝分兩種晶片：Apple Silicon 跟 Intel，下載頁面會自動列出兩個版本，選錯晶片會裝不起來。

跟 Windows 不一樣，Mac 這邊沒有 WSL 這種東西，Docker Desktop 直接用 macOS 內建的虛擬化框架來跑 Linux 核心。

⚠️ 易錯點：Apple Silicon 的 Mac 如果要跑一些只有 x86 版本的舊 Image，可能要靠 Rosetta 2 才能正常執行，這也是為什麼建議裝一下。
-->

---

# 安裝 Docker Desktop（macOS）— 範例

圖形介面安裝：下載 `Docker.dmg` → 雙擊開啟 → 把 Docker 圖示拖進「應用程式」資料夾 → 開啟 `Docker.app`。

也可以用命令列安裝：

```bash
sudo hdiutil attach Docker.dmg
sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
sudo hdiutil detach /Volumes/Docker
```

安裝完成後，從「應用程式」資料夾開啟 `Docker.app`，選單列出現鯨魚圖示，並同意訂閱服務條款，就代表 Docker Desktop 已啟動。

<!--
Mac 安裝最直覺的方式就是圖形介面：拖拉安裝，跟裝一般 Mac 軟體一樣。

如果是要幫多台機器批次安裝，命令列這幾行指令可以做到無人值守安裝，`--accept-license` 直接跳過條款確認畫面，`--user` 這個參數則可以指定安裝給哪個使用者。

⚠️ 易錯點：命令列安裝需要 `sudo` 權限，沒有管理員密碼會安裝失敗。

預期結果：選單列出現鯨魚圖示且不再跳動，代表 Daemon 已經啟動完成，可以打開終端機開始使用 `docker` 指令。
-->

---

# 驗證安裝：docker run hello-world

Docker Desktop 裝好、啟動之後，我們可以用官方提供的 `hello-world` 這個最小 Image 來驗證整個環境是否正常運作。

```bash
docker run hello-world
```

這個指令會依序完成：Client 送出請求給 Daemon，Daemon 在本機找不到 `hello-world` 這個 Image，於是向 Docker Hub（Registry）下載，下載完成後建立並啟動 Container，Container 印出一段確認訊息後就自動結束。

看到畫面出現「Hello from Docker!」開頭的文字，就代表我們的 Client、Daemon、Registry 三個環節全部串起來，Docker 安裝成功。

<!--
這是安裝完之後最重要的一步：驗證。`docker run hello-world` 是 Docker 官方特地準備的最小範例，專門用來確認整個環境有沒有裝對。

大家可以把這個過程對照我們第二部分講的架構圖：Client 發出指令、Daemon 去 Registry 拉 Image、拉完建立 Container 執行，這個 hello-world 範例正好把三個角色全部走過一遍，是很好的複習。

⚠️ 易錯點：如果執行後出現連線錯誤，通常是 Docker Desktop 還沒完全啟動，或是 WSL 2 沒有正常運作，可以先確認工作列鯨魚圖示是否已經停止轉圈。

預期結果：終端機會印出一段「Hello from Docker!」開頭的文字，說明這則訊息是從一個容器裡面印出來的，看到這段文字，就代表我們的 Docker 環境已經可以正常使用了。
-->

---
layout: default
---

# 練習 1：TaskBoard 該用 VM 還是 Container？
### 任務說明

TaskBoard 團隊有三位開發者，每個人電腦上的環境都不太一樣：

- A 的電腦裝了 **MySQL 5.7**（舊專案在用），TaskBoard 需要 **MySQL 8.4**
- B 的 JDK 是 **17**，TaskBoard 的 Gradle 設定要求 **JDK 21**
- C 的 Node 是 **18**，Angular 專案要 **Node 20** 才裝得起 dependency

請回答：要讓三個人都能跑起同一套 TaskBoard，用 Container 還是 VM 比較合適？理由是什麼？

---
layout: default
---

# 練習 1：TaskBoard 該用 VM 還是 Container？
### 解題提示

1. 先想清楚：三個人缺的是「不同作業系統」，還是「同一個 OS 上的不同版本執行環境」？
2. 回顧「VM vs Container 核心差異」那張表格，特別留意「資源開銷」與「啟動速度」
3. 如果用 VM：每個人要為 MySQL、API、前端各開一台裝著完整 OS 的虛擬機，一台幾 GB 記憶體，開機要幾分鐘
4. 如果用 Container：`mysql:8.4`、`gradle:8.10-jdk21`、`node:20-alpine` 各自帶著自己需要的版本，共用主機核心，秒級啟動
5. 想想「隔離性」這個特性：A 電腦上原本的 MySQL 5.7 會不會被容器裡的 8.4 影響？

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>答案方向：</b> 用 Container。三個人缺的只是「執行環境版本」，不是不同的作業系統，Container 的隔離已經足夠，而且開發機不必付出跑三套 OS 的代價。
</div>

---
layout: default
---

# 練習 2：走一遍 TaskBoard 資料庫的啟動流程
### 任務說明

假設我們在一台剛裝好 Docker Desktop、從來沒下載過任何 Image 的電腦上，執行：

```bash
docker run -d --name taskboard-db -p 3307:3306 \
  -e MYSQL_ROOT_PASSWORD=rootpw \
  -e MYSQL_DATABASE=taskboard \
  mysql:8.4
```

1. 寫出從指令送出到 Container 啟動的完整步驟，標出 Client / Daemon / Registry 各負責哪一段
2. 說明 `-p 3307:3306` 中兩個 port 分別屬於誰
3. 如果同事把指令改成 `-p 3306:3306`，而他電腦本來就裝了 MySQL，會發生什麼事？

---
layout: default
---

# 練習 2：走一遍 TaskBoard 資料庫的啟動流程
### 解題提示

1. 回顧「指令怎麼流動：以 docker run 為例」那五個步驟
2. 先問自己：本機有沒有 `mysql:8.4`？既然是全新安裝，答案是沒有 → 所以會多一段下載
3. 沒有 Image 的話，Daemon 會向誰要求下載？下載完才進入建立與啟動 Container 的階段
4. Port 映射：冒號左邊 `3307` 是**主機**的 port，右邊 `3306` 是**容器內**的 port
5. 第 3 小題想想：主機的 3306 已經被本機 MySQL 佔用，Docker 再去綁同一個 port 會怎樣

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>第 3 小題答案：</b> 容器會啟動失敗，錯誤訊息類似 <code>port is already allocated</code>。容器內部用什麼 port 是它家的事，但主機端的 port 全機器只能有一個人佔用。
</div>

<!--
這兩題練習題的講稿：第一題重點在幫大家把 VM 和 Container 的差異從表格轉換成實際判斷能力，而且情境就是大家真的會遇到的——同一個團隊裡每個人環境版本都不一樣。第二題則是把 Docker 架構的運作流程用 TaskBoard 的資料庫再走一次，確保大家不只是背名詞，而是真的理解 Client、Daemon、Registry 怎麼合作。

第二題的第三小題是刻意設計的，port 衝突是新手最常撞到的錯誤之一，先在紙上想過一次，實際遇到才不會慌。

⚠️ 提醒同學，練習的時候不用急著看提示，先自己想過一輪，卡住了再對照提示頁，這樣印象會比較深刻。另外第二題請真的動手執行，因為這個 taskboard-db 容器我們後面幾章都還會用到。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — Docker 簡介

<table class="summary-table">
<tr><th>重點</th><th>說明</th></tr>
<tr><td>容器化</td><td>解決「環境不一致」的痛點，Container 具備自含、隔離、獨立、可攜四大特性</td></tr>
<tr><td>VM vs Container</td><td>VM 帶完整作業系統，隔離強但資源開銷大；Container 共用主機核心，輕量且啟動快</td></tr>
<tr><td>Docker 架構</td><td>Client（下指令）、Daemon（實際執行）、Registry（存放 Image）三方組成</td></tr>
<tr><td>docker run 流程</td><td>Daemon 先檢查本機 Image，沒有的話才向 Registry 下載</td></tr>
<tr><td>安裝驗證</td><td>裝完 Docker Desktop 後，用 <code>docker run hello-world</code> 驗證環境</td></tr>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> Container 讓應用程式帶著它需要的環境一起走，到哪裡都能穩定運行，這是 Docker 最核心的價值。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將深入認識 Image（映像檔）管理，學習下載、建立、刪除與版本 Tag 命名。
</div>

<!--
今天這一章我們從「為什麼需要容器化」出發，比較了 VM 跟 Container 的差異，接著拆解了 Docker 的三大元件 Client、Daemon、Registry，最後動手把 Docker Desktop 裝起來，並且用 hello-world 驗證安裝成功。

如果今天只能記住一件事，那就是：Container 讓我們把應用程式跟它需要的環境打包在一起，帶到哪裡都能穩定運行，這就是 Docker 最核心的價值。

下一章我們會更深入認識 Image（映像檔）的管理，包括怎麼下載、建立、還有怎麼管理版本，敬請期待。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對今天的容器化概念、VM 與 Container 的差異，或是 Docker 架構、安裝流程，有沒有什麼疑問？都歡迎提出來討論。
-->
