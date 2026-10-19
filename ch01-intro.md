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
大家好，歡迎來到 Docker 課程的第一章。

我們先想一個很常見的場景。程式在自己電腦上跑得好好的，一丟到同學的電腦、或是部署到伺服器，就開始出錯。這就是經典的「在我電腦上可以跑」問題。

這一章我們要搞懂三件事：為什麼需要容器化，Docker 的架構怎麼運作，以及實際把 Docker Desktop 裝起來。學完之後，我們就能在自己的電腦上，用一行指令跑起一個資料庫。
-->

---
layout: default
---

# Outline

- **為什麼需要容器化** — VM vs Container 的差異
- **Docker 架構** — Client / Daemon / Registry 怎麼合作
- **安裝與驗證** — 安裝 Docker Desktop、跑第一個 hello-world
- **練習** — 用課程專案 TaskBoard 走一次 `docker run` 流程

<!--
今天的路線是這樣的。我們先從「為什麼」開始，看看容器化解決了什麼問題，順便比較容器和虛擬機。

接著拆開 Docker 的架構，搞懂 Client、Daemon、Registry 各自負責什麼。最後實際安裝 Docker Desktop，並且用課程專案 TaskBoard 走一次 `docker run` 的完整流程。
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
在進入觀念之前，先介紹這門課的貫穿專案，TaskBoard 任務看板。

大家之前學過 Spring Boot、Angular 跟 MySQL，這門課不會再教這三項技術本身。我們要學的，是怎麼把這樣一個三層架構的專案容器化。

看表格的最後一欄，前端和後端之後會各自變成一個 Image，資料庫則直接用官方的 `mysql:8.4`。請求的路線很單純：瀏覽器先到 nginx，nginx 轉給 Spring Boot，Spring Boot 再去查 MySQL。

要特別提醒，這八章是連續的。第一章手動跑起來的 MySQL 容器，第七章還會回來處理它的資料保存問題。所以每一章的練習，請盡量真的動手做過。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 為什麼需要容器化

<!--
先從第一個問題開始：為什麼我們需要容器化？它跟大家比較熟悉的虛擬機，又差在哪裡？
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
想像同一台電腦上有兩個專案。一個需要 Python 3.8，另一個需要 Python 3.11。裝到最後，很可能兩邊都跑不起來。

這就是容器化要解決的問題。「Container 就是應用程式各個組件的獨立隔離流程」，每個 Container 帶著自己需要的函式庫、設定和執行環境，不依賴主機上裝了什麼。

生活一點來說，容器就像便當盒。飯、菜、湯分開裝好，帶到哪裡打開都是同樣的味道。

拉回 TaskBoard，前端、API、資料庫就可以分別放進三個容器，彼此不會互相干擾。不過要注意，Container 不是虛擬機，這個差異我們下一頁馬上來看。
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
這張表是今天最重要的一張，我們挑重點看。

虛擬機是連作業系統都自己帶一份，就像每戶人家都自己蓋一棟房子，水電全部自己接，所以很重、開機很慢。

容器則是共用主機的核心，只帶應用程式需要的檔案。比較像大家住在同一棟大樓，共用水電管線，但每一戶的室內裝潢是獨立的。所以容器啟動只要幾秒，映像檔也小很多。

很多人會以為 Container 是輕量版的 VM，其實兩者原理完全不同。VM 靠 Hypervisor 模擬硬體，Container 靠作業系統層級的隔離機制。在雲端環境裡，常常是 VM 裡面再跑 Container，兩者是互補的。
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
這一頁把 Container 的四個特性整理在一起：自含、隔離、獨立、可攜。

其中「可攜性」就是開頭那個問題的解答。Container 把環境整包帶走，所以在我們電腦上能跑，丟到別台只要有 Docker 的機器，一樣能跑。

不過下面這個提醒也很重要。Container 之間共用同一個主機核心，隔離程度沒有 VM 那麼徹底。如果是很多不同客戶共用一台主機這種情境，通常還要搭配額外的安全設定。

在實際專案裡，Container 最主要是解決「開發到部署環境一致」的問題，這也是為什麼現代的 CI/CD 流程幾乎都會用到 Docker。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Docker 架構

<!--
知道容器是什麼之後，接下來看 Docker 的架構：當我們打下一行 `docker run`，背後到底是誰在做事？
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
Docker 有三個關鍵角色。Client 是我們打指令的地方，Daemon 是在背景真正做事的程式，Registry 則是存放 Image 的倉庫。

我們可以把它想成餐廳點餐。我們是客人，跟服務生點餐，這就是 Client。廚房收到訂單開始做菜，這是 Daemon。食材不夠的時候，廚房會去食材倉庫調貨，那個倉庫就是 Registry。

拉回技術，Client 和 Daemon 之間是透過 REST API 溝通的。所以它們不一定要在同一台機器上，Client 也可以連到遠端伺服器的 Daemon，去管理那邊的容器。
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
這一頁我們直接拿 TaskBoard 的資料庫，走一次 `docker run` 背後的流程。

先看參數。`-d` 讓容器在背景執行，`--name taskboard-db` 幫容器取名字，之後所有指令都用這個名字操作它。`-e` 是帶環境變數進去，MySQL 官方 Image 就是靠這兩個變數設定 root 密碼和建立資料庫。

`-p 3307:3306` 是 port 映射，左邊是我們電腦的 port，右邊是容器裡的 port。主機用 3307 而不是 3306，是因為很多人電腦本來就裝了 MySQL，佔用了 3306，這樣可以避開衝突。

流程就是下面這五步。Client 把指令送給 Daemon，Daemon 先找本機有沒有 `mysql:8.4`，沒有就去 Registry 下載，接著建立並啟動容器。

第一次執行要等下載，這是正常的。執行完會印出一長串容器 ID，接著用 DBeaver 連 `localhost:3307`，就能看到一個叫 taskboard 的空資料庫。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 安裝與驗證

<!--
觀念講得差不多了，接下來我們動手，把 Docker Desktop 裝起來並且驗證它能正常運作。
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
安裝之前，先確認一下 Windows 的環境條件。

這張表挑兩個重點看。第一個是後端，建議使用 WSL 2，它讓 Windows 可以跑一個真正的 Linux 核心，Docker 容器就是靠這個核心運作的。第二個是硬體，BIOS 裡要開啟硬體虛擬化。

很多人安裝失敗，就是忘了開虛擬化，或是 WSL 版本太舊。安裝前可以先用 `wsl --version` 檢查一下。

授權的部分大家不用擔心。個人學習和教學是免費的，只有規模比較大的企業商用才需要付費。
-->

---

# 安裝流程總覽

<div class="grid grid-cols-4 gap-3 mt-6 text-center text-sm">

<div class="p-3 rounded" style="background:#eef4ff; border:1px solid #c7dbff;">
<div class="text-2xl">①</div>
<b>下載</b><br/>官網取得 Installer.exe
</div>

<div class="p-3 rounded" style="background:#eef4ff; border:1px solid #c7dbff;">
<div class="text-2xl">②</div>
<b>安裝</b><br/>Configuration → 解壓 → 完成
</div>

<div class="p-3 rounded" style="background:#eef4ff; border:1px solid #c7dbff;">
<div class="text-2xl">③</div>
<b>啟動</b><br/>同意條款 → 進主畫面
</div>

<div class="p-3 rounded" style="background:#e6f7f2; border:1px solid #a8ded0;">
<div class="text-2xl">④</div>
<b>驗證</b><br/><code>docker run hello-world</code>
</div>

</div>

<div class="mt-8 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 接下來每一步都是<b>實機操作畫面</b>（Docker Desktop 4.86.0 / Windows 11），照著做就能裝完。
</div>

<!--
在看實機畫面之前，先給大家一張流程總覽。

整個安裝只有四步：下載、安裝、啟動、驗證。接下來每一頁都是實際操作的畫面，大家可以一邊看一邊跟著做。

畫面上的版本是 Docker Desktop 4.86.0。如果我們裝的版本比較新，畫面細節可能有點不同，但流程是一樣的。
-->

---

# ① 下載 Docker Desktop

<div class="grid grid-cols-3 gap-4">

<div class="col-span-2">
<img src="/docker-install-01-download-page.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
</div>

<div class="text-sm" style="color:#57606a;">

**下載頁面**

<a href="https://www.docker.com/products/docker-desktop/" target="_blank">docker.com/products/<br/>docker-desktop</a>

按下藍色的 **Download Docker Desktop**，網站會自動偵測作業系統，Windows 會下載到 `Docker Desktop Installer.exe`。

<div class="mt-3 p-2 bg-blue-50 border-l-4 border-blue-400 text-gray-700">
安裝文件：<br/><a href="https://docs.docker.com/desktop/setup/install/windows-install/" target="_blank">docs.docker.com/desktop/<br/>setup/install/windows-install</a>
</div>

</div>

</div>

<!--
第一步，到 Docker 官網的下載頁面。

畫面正中間這顆藍色的 Download Docker Desktop 按鈕，就是下載入口。網站會自動偵測作業系統，推薦對應的版本。如果偵測錯了，可以從按鈕旁邊的下拉選單手動選擇。

右邊也放了官方安裝文件的連結。遇到比較特殊的環境問題，可以去那邊查。
-->

---

# ① 下載完成

<div class="flex flex-col items-center">

<img src="/docker-install-02-downloaded.png" style="width: 82%; border-radius: 6px; border: 1px solid #d0d7de;" />

<p class="mt-3 text-sm" style="color: #57606a;">
下載資料夾裡出現 <code>Docker Desktop Installer.exe</code>，檔案約 <b>600 MB</b>，<b>雙擊</b>它開始安裝
</p>

</div>

<!--
下載完成之後，到下載資料夾找 `Docker Desktop Installer.exe`。

注意一下檔案大小，大約 600 MB。如果檔案明顯小很多，很可能是下載中斷了，重新下載一次就好。

找到之後雙擊它，就會進入安裝精靈。
-->

---

# ② 安裝精靈 — Configuration

<div class="grid grid-cols-2 gap-6 items-center">

<div>
<img src="/docker-install-03-config.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
</div>

<div class="text-sm" style="color:#57606a;">

安裝精靈的第一個畫面，有兩個選項：

- **Per-user installation（Recommended）** — 只裝給目前使用者，**不需要管理員權限**，使用 WSL 2 後端
- **All-users installation** — 全機器安裝，需要管理員密碼
- **Add shortcut to desktop** — 建立桌面捷徑，建議保留

<div class="mt-3 p-2 bg-blue-50 border-l-4 border-blue-400 text-gray-700">
💡 教學環境直接用預設值，按 <b>OK</b> 即可。
</div>

</div>

</div>

<!--
雙擊之後，第一個畫面是 Configuration，要選擇安裝模式。

預設的 Per-user installation 是官方推薦的選項。它只裝給目前的使用者，不需要管理員權限，後端用的是 WSL 2。對我們上課來說，這個選項最方便。

下面的 All-users installation 是全機器安裝，會要求管理員密碼。如果選了它卻沒有管理員權限，安裝會直接失敗。不確定的話，維持預設就好。

Add shortcut to desktop 建議勾著，等一下比較好找。確認之後按 OK。
-->

---

# ② 安裝精靈 — 安裝中 / 完成

<div class="grid grid-cols-2 gap-6">

<div>
<img src="/docker-install-04-installing.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
<p class="text-center mt-2 text-sm" style="color: #57606a;">Unpacking files… 解壓縮中，約 1–2 分鐘</p>
</div>

<div>
<img src="/docker-install-05-succeeded.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
<p class="text-center mt-2 text-sm" style="color: #57606a;">Installation succeeded → 按 <b>Close</b></p>
</div>

</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>個別使用者模式不需要登出</b>；若選的是全使用者模式，這裡可能會要求你登出 Windows 再重新登入。
</div>

<!--
按下 OK 之後就進入安裝過程。

左邊是 Unpacking files，進度條大概會跑一到兩分鐘。這段時間它在解壓縮檔案、設定 WSL 2 的整合環境，耐心等它跑完，不要中途關掉。

右邊出現 Installation succeeded，就代表安裝完成了，按 Close 關掉。

如果我們選的是個別使用者模式，裝完不需要登出 Windows，可以直接開來用。只有全使用者模式，才可能要求登出再登入。
-->

---

# ③ 首次啟動 — 服務條款

<div class="grid grid-cols-2 gap-6 items-center">

<div>
<img src="/docker-install-06-terms.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
</div>

<div class="text-sm" style="color:#57606a;">

從**桌面捷徑**或開始功能表開啟 Docker Desktop，第一次啟動會跳出 **Docker Subscription Service Agreement**。

按 **Accept** 才會繼續啟動。

<div class="mt-3 p-2 bg-blue-50 border-l-4 border-blue-400 text-gray-700">
⚠️ 這裡沒按 Accept，Docker Desktop 就不會啟動 — 很多人以為是「裝完打不開」，其實只是條款還沒同意。
</div>

<div class="mt-3 p-2" style="background:#fff8e6; border-left:4px solid #e3b341;">
超過 250 人或年營收超過 1000 萬美元的企業商用需付費訂閱；個人學習與教學免費。
</div>

</div>

</div>

<!--
安裝完成後，從桌面捷徑或開始功能表打開 Docker Desktop。

第一次啟動一定會跳出服務條款，要按右下角的 Accept 才會繼續。

這是最常見的「裝完打不開」原因。其實程式不是壞了，只是停在條款這一步，還沒按同意。

授權的部分前面提過，個人學習和教學都是免費的，大家可以放心按下去。
-->

---

# ③ 首次啟動 — 登入畫面可略過

<div class="grid grid-cols-2 gap-6 items-center">

<div>
<img src="/docker-install-07-welcome.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
</div>

<div class="text-sm" style="color:#57606a;">

接著會出現 **Welcome to Docker**，要求登入 Docker 帳號。

**本課程不需要登入**，直接按右上角的 **Skip** 就好。

什麼時候才需要 Docker 帳號？

- 要 **push** 自己的 Image 到 Docker Hub（第 2 章會用到）
- 要拉取私有 Registry 的 Image
- 要提高匿名拉取的速率限制

</div>

</div>

<!--
同意條款之後，會看到 Welcome to Docker 的畫面，希望我們登入 Docker 帳號。

這門課的前半段完全不需要登入，直接按右上角的 Skip 跳過就好。

什麼時候才需要帳號呢？主要有三種情況。第一，要把自己的 Image 推到 Docker Hub，第二章會用到。第二，要拉公司私有 Registry 的 Image。第三，Docker Hub 對沒登入的使用者有下載次數限制，登入後會比較寬鬆。
-->

---

# ③ Docker Desktop 主畫面

<div class="flex flex-col items-center">

<img src="/docker-install-08-dashboard.png" style="width: 70%; border-radius: 6px; border: 1px solid #d0d7de;" />

</div>

<div class="mt-3 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>安裝成功的判斷依據：</b> 左下角顯示綠色的 <b>Engine running</b>，右下角顯示版本號（此處為 v4.86.0），工作列鯨魚圖示不再轉圈 — 代表 Daemon 已就緒，可以開終端機下 <code>docker</code> 指令了。
</div>

<!--
按下 Skip 之後，就進入 Docker Desktop 的主畫面。

左邊這一排是主要功能，Containers、Images、Volumes 這幾個，後面每一章都會用到。現在還沒跑任何東西，所以 Containers 這頁是空的。

最重要的是左下角，綠色的 Engine running，代表 Docker 的 Daemon 已經跑起來了。如果看到的是 Starting 或紅色的 Engine stopped，先等一下或重開 Docker Desktop，這時候下指令一定會失敗。

看到 Engine running，就可以打開終端機來驗證了。
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
用 Mac 的同學看這一頁。

Mac 有兩種晶片，Apple Silicon 和 Intel，安裝檔是不一樣的。下載前先從選單列的「關於這台 Mac」確認自己的晶片，選錯會裝不起來。

跟 Windows 不同，Mac 沒有 WSL，Docker Desktop 直接用 macOS 內建的虛擬化框架來跑 Linux 核心。

Apple Silicon 的 Mac 建議順手裝 Rosetta 2。遇到一些只有 x86 版本的舊 Image，就要靠它才能執行。
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
Mac 最直覺的安裝方式是圖形介面，把 Docker 圖示拖進應用程式資料夾，跟裝一般 Mac 軟體一樣。

如果要幫很多台機器批次安裝，可以用下面這三行指令。關鍵是中間那行的 `--accept-license`，它會直接跳過條款確認畫面，做到無人值守安裝。要注意這些指令都需要 `sudo` 權限，沒有管理員密碼會失敗。

裝好之後打開 `Docker.app`，選單列出現鯨魚圖示而且不再跳動，就代表 Daemon 已經啟動完成，可以開始用 `docker` 指令了。
-->

---

# 驗證安裝：docker run hello-world

Docker Desktop 裝好、啟動之後，我們可以用官方提供的 `hello-world` 這個最小 Image 來驗證整個環境是否正常運作。

```bash
docker --version
docker run hello-world
```

這個指令會依序完成：Client 送出請求給 Daemon，Daemon 在本機找不到 `hello-world` 這個 Image，於是向 Docker Hub（Registry）下載，下載完成後建立並啟動 Container，Container 印出一段確認訊息後就自動結束。

看到畫面出現「Hello from Docker!」開頭的文字，就代表我們的 Client、Daemon、Registry 三個環節全部串起來，Docker 安裝成功。

<!--
裝好之後，最重要的一步是驗證。

我們先用 `docker --version` 確認指令存在，再執行 `docker run hello-world`。hello-world 是官方準備的最小 Image，專門用來確認環境有沒有裝對。

這個過程正好把前面講的架構走一遍。Client 發出指令，Daemon 在本機找不到 Image，就去 Docker Hub 下載，下載完建立容器執行，容器印出一段訊息後自動結束。

看到「Hello from Docker!」開頭的文字，就代表 Client、Daemon、Registry 三個環節都串起來了。

如果出現連線錯誤，通常是 Docker Desktop 還沒完全啟動，回去確認一下 Engine running。
-->

---

# ④ 驗證安裝 — 實際執行畫面

<div class="grid grid-cols-3 gap-4">

<div class="col-span-2">
<img src="/docker-install-09-hello-world.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
</div>

<div class="text-sm" style="color:#57606a;">

**對照架構三角色**

<div class="p-2 mb-2 rounded" style="background:#f6f8fa;">
<b>Client</b><br/>你打的 <code>docker run</code>
</div>

<div class="p-2 mb-2 rounded" style="background:#f6f8fa;">
<b>Registry</b><br/><code>Unable to find image … locally</code><br/><code>Pulling from library/hello-world</code>
</div>

<div class="p-2 mb-2 rounded" style="background:#f6f8fa;">
<b>Daemon</b><br/>建立並執行 Container，印出<br/><code>Hello from Docker!</code>
</div>

</div>

</div>

<!--
這是實際跑出來的畫面，我們對照右邊的三個角色來看。

最上面的 Docker version 29.7.2 是 Docker Engine 的版本，跟 Docker Desktop 的 4.86.0 是兩個不同的版本號，不要搞混。

接著這行 Unable to find image locally 是關鍵，代表 Daemon 先在本機找，沒找到。於是下一行 Pulling from library/hello-world，它去 Docker Hub 把 Image 拉下來。拉完之後，Daemon 建立容器執行，印出 Hello from Docker!。

如果看到 cannot connect to the Docker daemon，代表 Docker Desktop 還沒啟動完成。
-->

---
layout: default
---

# 練習：走一遍 TaskBoard 資料庫的啟動流程
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

<!--
接下來是本章的練習。

假設我們在一台剛裝好 Docker、從來沒下載過任何 Image 的電腦上，執行這段建立 TaskBoard 資料庫的指令。請寫出從指令送出到容器啟動的完整步驟，標出 Client、Daemon、Registry 各負責哪一段。

第三小題請大家想一想：如果同事把 port 改成 3306，而他的電腦本來就裝了 MySQL，會發生什麼事？

我們先暫停一下，自己動手試試看。

【講師】給大家三到五分鐘，鼓勵實際執行指令，這個 taskboard-db 容器後面幾章都會用到。
-->

---
layout: default
---

# 練習：走一遍 TaskBoard 資料庫的啟動流程
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
我們來看解題的關鍵。

因為是全新安裝，本機一定沒有 `mysql:8.4`，所以流程會多一段下載。Client 把指令交給 Daemon，Daemon 找不到 Image，就向 Registry 下載，下載完才建立並啟動容器。

port 映射的部分，冒號左邊的 3307 是主機的 port，右邊的 3306 是容器裡的 port。

回到第三小題。主機的 3306 已經被本機的 MySQL 佔走了，Docker 再去綁同一個 port，容器就會啟動失敗，錯誤訊息會出現 `port is already allocated`。容器裡面用什麼 port 沒關係，但主機上的 port 一次只能給一個程式使用。
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
<thead>
<tr><th>重點</th><th>說明</th></tr>
</thead>
<tbody>
<tr><td>容器化</td><td>解決「環境不一致」的痛點，Container 具備自含、隔離、獨立、可攜四大特性</td></tr>
<tr><td>VM vs Container</td><td>VM 帶完整作業系統，隔離強但資源開銷大；Container 共用主機核心，輕量且啟動快</td></tr>
<tr><td>Docker 架構</td><td>Client（下指令）、Daemon（實際執行）、Registry（存放 Image）三方組成</td></tr>
<tr><td>docker run 流程</td><td>Daemon 先檢查本機 Image，沒有的話才向 Registry 下載</td></tr>
<tr><td>安裝驗證</td><td>裝完 Docker Desktop 後，用 <code>docker run hello-world</code> 驗證環境</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>記住：</b> Container 讓應用程式帶著它需要的環境一起走，到哪裡都能穩定運行，這是 Docker 最核心的價值。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將深入認識 Image（映像檔）管理，學習下載、建立、刪除與版本 Tag 命名。
</div>

<!--
我們來回顧一下這一章。

第一，容器化解決的是環境不一致的問題，Container 自己帶著需要的環境。第二，VM 帶完整作業系統，Container 共用主機核心，所以更輕量、啟動更快。第三，Docker 由 Client、Daemon、Registry 三個角色組成。第四，`docker run` 會先找本機的 Image，沒有才去 Registry 下載。最後，我們用 hello-world 驗證了安裝。

如果只記得一件事，那就是：Container 讓應用程式帶著環境一起走，到哪裡都能穩定運行。

下一章，我們會深入 Image 的管理，學習下載、刪除和版本標籤。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
這一章就到這裡。我們從容器化的動機出發，一路走到親手把 Docker 裝起來、跑起第一個資料庫容器。

接下來，記得讓 taskboard-db 這個容器留著，後面幾章都會繼續用到它。我們下一章見。

【講師】開放 Q&A，可以引導大家回想 VM 和 Container 的差異、Docker 架構或安裝過程的問題。
-->
