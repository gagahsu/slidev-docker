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
    「打包一次，到處都能執行」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
【開場白】
本章是 Docker 課程的第一章。

【情境切入】
程式在開發者的電腦上可以正常執行，部署到其他機器或伺服器後卻發生錯誤，原因通常是執行環境不一致。容器化技術正是為了解決這個問題。

【學習目標】
- 理解容器化的目的，以及 Container 與虛擬機（VM）的差異
- 認識 Docker 架構中 Client、Daemon、Registry 的分工
- 安裝 Docker Desktop，並以 hello-world 驗證安裝結果
-->

---
layout: default
---

# Outline

- **為什麼需要容器化**
  - VM 與 Container 的差異
- **Docker 架構**
  - Client / Daemon / Registry
- **安裝與驗證**
  - Docker Desktop、hello-world
- **實作練習**

<!--
【帶讀大綱】
本章分為三個部分：第一部分說明容器化解決的問題，並比較 Container 與 VM；第二部分拆解 Docker 架構，說明指令送出後資料如何流動；第三部分實際安裝 Docker Desktop，並以 hello-world 驗證。

【重點預告】
最後以課程專案 SSDS（AI 選品系統）為情境，安排兩題練習。
-->

---
layout: default
---

# 課程貫穿專案：AI 選品系統（SSDS）

本課程的範例與練習皆以 **ai-products-selection**（程式代號 `ssds`）為對象。課程目標：**將專案包裝為 Docker Image，並部署至雲端平台。**

| 元件 | 技術 | 專案資料夾 | 對應 Image |
| --- | --- | --- | --- |
| 前端 | Angular 21（build 後由 nginx 提供服務） | `ai-products-selection-frontend/` | `ssds-web:1.0.0` |
| 後端 | Spring Boot 4.1 + Gradle 多模組（Java 21） | `ai-products-selection-backend/` | `ssds-api:1.0.0` |
| 資料庫 | Supabase PostgreSQL（雲端託管） | 不放入 Docker | — |

```
瀏覽器 → ssds-web (nginx :80) ──/api──▶ ssds-api (:8080) ──JDBC──▶ Supabase（雲端 PostgreSQL）
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>課程安排：</b>第 1～3 章認識 Image 與 Container；第 4 章撰寫前後端 Dockerfile；第 5 章以 Compose 同時啟動；第 6～7 章處理網路與上傳檔案；第 8 章準備正式環境；<b>第 9 章將兩個 Image 部署至免費、免綁卡的雲端平台</b>。
</div>

<!--
【核心說明】
- 後端為 Spring Boot 4.1 的 Gradle 多模組專案，唯一可執行的模組是 ssds-api，打包產出 ssds.jar。
- 前端為 Angular 21，build 後產出靜態檔，由 nginx 提供服務。
- 資料庫使用 Supabase 上的 PostgreSQL，因此不需放入 Docker。只需將前後端各包成一個 Image，後端以環境變數連線 Supabase。

【業界實務】
「應用程式容器化、資料庫交由雲端託管服務」是業界常見的架構。

【重點提醒】
九章內容前後銜接：第四章撰寫的 Dockerfile，第五章 Compose 與第九章雲端部署都會沿用。每章練習請在自己的專案上實作。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 為什麼需要容器化

<!--
【段落轉換】
第一部分說明容器化要解決的問題，並比較 Container 與虛擬機（VM）。

【問題引導】
專案換一台電腦或部署到伺服器後無法執行，原因通常是環境不一致：版本不同、缺少套件、作業系統設定不同。
-->

---

# 什麼是容器化？

未容器化時，前端、後端 API、資料庫安裝在同一台機器上，版本與相依套件互相干擾，更換機器須重新設定環境。

**Container（容器）** 是將應用程式及其執行所需的函式庫、設定與執行環境打包在一起的隔離行程，不依賴主機預先安裝的套件。

前端、API、資料庫可分別放入三個容器，各自攜帶所需環境，彼此互不干擾，也不受主機環境影響。

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>類比：</b>容器如同便當盒，飯、菜、湯分格裝好，帶到任何地方打開內容都相同。
</div>

<!--
【問題引導】
同一台電腦上有兩個專案，一個需要 Python 3.8、另一個需要 Python 3.11，會發生版本衝突，最後兩者都無法正常執行。

【概念定義】
Container 讓每個應用程式在獨立的環境中執行，攜帶自身所需的函式庫、設定檔與執行環境，彼此互不影響。

【易錯點提醒 ⚠️】
Container 不是虛擬機，也不包含完整的作業系統。兩者的差異於下一頁說明。
-->

---

# VM vs Container：核心差異

| 面向 | Virtual Machine（虛擬機） | Container（容器） |
| --- | --- | --- |
| 結構 | 包含完整作業系統、核心（Kernel）、驅動程式 | 隔離的行程，僅包含執行應用程式所需的檔案 |
| 資源開銷 | 高，每個 VM 都需啟動完整系統 | 低，多個 Container 共用主機核心 |
| 啟動速度 | 慢，通常需數十秒至數分鐘 | 快，通常數秒內完成 |
| 可攜性 | 較重，映像檔通常以 GB 計 | 輕量，映像檔通常為數十至數百 MB |
| 隔離程度 | 完整系統隔離，安全邊界較強 | 行程層級隔離，共用核心資源 |

<!--
【重點解說】
本表是本章最重要的觀念。VM 自帶完整作業系統；Container 共用主機核心，只攜帶應用程式與函式庫。

【生活化比喻】
VM 如同每戶各自蓋一棟獨立的房子，水電管線全部自行配置；Container 如同同一棟大樓中的住戶，共用水電管線，但各戶室內裝潢與家具獨立。

【核心說明】
兩者運作原理不同：VM 透過 Hypervisor 模擬硬體；Container 透過作業系統層級的隔離機制（namespace、cgroup）。這也是 Container 啟動速度較快的原因。

【業界實務】
兩種技術並不互斥。雲端環境常見「VM 中執行 Container」：以 VM 進行大範圍隔離，再以 Container 進行應用程式層級的隔離。
-->

---

# Container 的特性與限制

Container 的四個核心特性：

- **自含性**：每個 Container 攜帶自身所需的一切，不依賴主機預裝的套件
- **隔離性**：Container 之間互相隔離，單一容器故障不影響其他容器
- **獨立性**：可獨立啟動、停止、刪除
- **可攜性**：在開發機上執行的 Container，在資料中心或雲端環境中行為一致

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>限制：</b>Container 共用主機核心，隔離程度不如 VM。對安全隔離要求高的情境（例如多租戶環境）須搭配額外的安全機制。
</div>

<!--
【重點解說】
可攜性即為「在我的電腦上可以執行」問題的解答：Container 將環境整體打包，只要目標機器安裝了 Docker，執行環境即完全一致。

【易錯點提醒 ⚠️】
Container 之間共用同一個主機核心，隔離並非絕對。多個客戶共用同一台主機等需要嚴格隔離的情境，不能只依賴 Container 本身。

【業界實務】
Container 主要用於確保開發與部署環境一致，現代 CI/CD 流程幾乎都會使用 Docker。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Docker 架構

<!--
【段落轉換】
第二部分拆解 Docker 架構。

【問題引導】
執行 `docker run` 時，由誰接收指令？Image 從何處取得？本部分介紹 Client、Daemon、Registry 三個角色及其合作方式。
-->

---

# Docker 的三大元件

| 元件 | 說明 |
| --- | --- |
| Client（客戶端） | 輸入指令的介面，例如 `docker run` |
| Daemon（守護行程） | 背景執行的 `dockerd`，負責建立與管理 Image、Container、Network |
| Registry（倉庫） | 存放 Image 的服務，Docker Hub 為最常用的公開 Registry |

Docker Client 與 Daemon 之間透過 REST API 溝通，傳輸管道可為 UNIX socket 或網路介面。Docker Desktop 則整合 Daemon、Client、Compose 等工具，一次安裝即可使用。

<!--
【概念定義】
Client 負責送出指令，Daemon 負責實際執行，Registry 負責存放 Image。

【生活化比喻】
如同餐廳點餐：顧客（Client）向服務生點餐，廚房（Daemon）收到訂單後開始製作；食材不足時，廚房向食材倉庫（Registry）調貨。

【重點提醒】
Client 與 Daemon 不一定位於同一台機器。Client 可透過網路連線到遠端的 Daemon，因此 Docker 也能用來管理遠端伺服器上的容器。
-->

---

# 指令流程：以 docker run 為例

以下啟動 SSDS 前端後續將使用的 **nginx**：

```bash
docker run -d --name ssds-web-try -p 8000:80 nginx:1.30-alpine
```

1. **Client** 將 `docker run` 指令送至 **Daemon**
2. **Daemon** 檢查本機是否已有 `nginx:1.30-alpine`
3. 若無，**Daemon** 向 **Registry**（Docker Hub）下載該 Image
4. **Daemon** 以該 Image 建立並啟動新的 **Container**
5. `-p 8000:80` 將主機的 8000 port 映射至容器內的 80 port

開啟瀏覽器連線 `http://localhost:8000`，畫面顯示 **Welcome to nginx!**。第四章將把 Angular build 產出的檔案放入此 nginx。

<!--
【範例目的】
以 SSDS 前端將使用的 nginx 為例，完整走過指令送出後的流程。Angular build 後的產物為 HTML、JS、CSS 靜態檔，需由 Web Server 提供服務，nginx 為業界常用的選擇。

【帶讀關鍵行】
- `-d`：背景執行，避免 log 佔用終端機。
- `--name ssds-web-try`：指定容器名稱，後續指令可直接以名稱操作。
- `-p 8000:80`：port 映射，冒號左側為主機 port、右側為容器內 port。

【重點提醒】
主機端使用 8000，是因為 8080 保留給 Spring Boot 後端、4200 為 Angular 的 ng serve，選用不衝突的 port。

【易錯點提醒 ⚠️】
首次執行需等待 Image 下載，屬正常現象。之後再使用同一個 Image 會直接使用本機快取，數秒內即可啟動。

【預期結果】
終端機輸出一串 Container ID，瀏覽器開啟 localhost:8000 顯示 Welcome to nginx。完成後以 `docker rm -f ssds-web-try` 刪除，相關指令於第三章詳細說明。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# 安裝與驗證

<!--
【段落轉換】
第三部分安裝 Docker Desktop：確認系統需求、依序完成安裝步驟，最後以 hello-world 驗證。
-->

---

# 安裝 Docker Desktop（Windows）

| 項目 | 需求 / 說明 |
| --- | --- |
| 作業系統 | Windows 11 64 位元 23H2 以上（Docker 僅支援仍在 Microsoft 服務週期內的 Windows 版本） |
| 後端 | WSL 2（Windows Subsystem for Linux 2），版本 2.1.5 以上 |
| 硬體 | 64 位元處理器（支援 SLAT）、4GB 以上記憶體、BIOS/UEFI 啟用硬體虛擬化 |
| 安裝模式 | 個別使用者模式（免管理員權限，建議）或全使用者模式 |
| WSL 版本檢查 | `wsl --version` |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>授權：</b>個人使用、教育及非商業開源專案可免費使用 Docker Desktop；員工超過 250 人或年營收超過 1000 萬美元的企業商用須付費訂閱。
</div>

<!--
【重點解說】
WSL 2 讓 Windows 執行真正的 Linux 核心，Docker 容器即依賴此核心運作，為目前建議的後端。

【重點提醒】
Windows 10 已於 2025 年 10 月 14 日結束一般支援。Docker 僅支援仍在 Microsoft 服務週期內的 Windows 版本，因此新安裝應使用 Windows 11。

【易錯點提醒 ⚠️】
常見安裝失敗原因為 BIOS 未啟用硬體虛擬化，或 WSL 版本過舊。安裝前可先以 `wsl --version` 確認，必要時執行 `wsl --update`。

【補充】
個人學習與教學可免費使用，僅一定規模以上的企業商用須付費。
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
<b>啟動</b><br/>同意條款 → 進入主畫面
</div>

<div class="p-3 rounded" style="background:#e6f7f2; border:1px solid #a8ded0;">
<div class="text-2xl">④</div>
<b>驗證</b><br/><code>docker run hello-world</code>
</div>

</div>

<div class="mt-8 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 以下各步驟皆為<b>實機操作畫面</b>（Docker Desktop 4.86.0 / Windows 11）。
</div>

<!--
【重點解說】
安裝流程共四步：下載、安裝、啟動、驗證。後續每頁皆附實際操作畫面。

【重點提醒】
畫面版本為 Docker Desktop 4.86.0。若安裝的版本較新，畫面細節可能略有差異，但流程相同。
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

點選 **Download Docker Desktop**，網站會自動偵測作業系統；Windows 下載的檔案為 `Docker Desktop Installer.exe`。

<div class="mt-3 p-2 bg-blue-50 border-l-4 border-blue-400 text-gray-700">
安裝文件：<br/><a href="https://docs.docker.com/desktop/setup/install/windows-install/" target="_blank">docs.docker.com/desktop/<br/>setup/install/windows-install</a>
</div>

</div>

</div>

<!--
【操作提示】
至 docker.com/products/docker-desktop 下載安裝檔。網站會依作業系統推薦對應版本；若偵測錯誤，可由按鈕旁的下拉選單手動選擇 Windows / macOS / Linux。

【補充】
特殊環境的安裝問題，可參考右側的官方安裝文件。
-->

---

# ① 下載完成

<div class="flex flex-col items-center">

<img src="/docker-install-02-downloaded.png" style="width: 82%; border-radius: 6px; border: 1px solid #d0d7de;" />

<p class="mt-3 text-sm" style="color: #57606a;">
下載資料夾中出現 <code>Docker Desktop Installer.exe</code>（約 <b>600 MB</b>），<b>雙擊</b>開始安裝
</p>

</div>

<!--
【操作提示】
於「下載」資料夾找到 Docker Desktop Installer.exe，雙擊進入安裝精靈。

【易錯點提醒 ⚠️】
檔案約 600 MB。若檔案明顯較小，可能是下載中斷，請重新下載。
-->

---

# ② 安裝精靈 — Configuration

<div class="grid grid-cols-2 gap-6 items-center">

<div>
<img src="/docker-install-03-config.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
</div>

<div class="text-sm" style="color:#57606a;">

安裝精靈第一個畫面的選項：

- **Per-user installation（Recommended）** — 僅安裝給目前使用者，**不需管理員權限**，使用 WSL 2 後端
- **All-users installation** — 全機安裝，需管理員密碼
- **Add shortcut to desktop** — 建立桌面捷徑，建議保留

<div class="mt-3 p-2 bg-blue-50 border-l-4 border-blue-400 text-gray-700">
💡 教學環境使用預設值，按 <b>OK</b> 即可。
</div>

</div>

</div>

<!--
【重點解說】
預設的 Per-user installation 為官方建議選項，不需管理員權限，後端使用 WSL 2，最適合課堂環境。All-users installation 適用於多個使用者帳號都需使用 Docker 的電腦。

【易錯點提醒 ⚠️】
選擇 All-users installation 但沒有管理員權限，安裝會失敗。不確定時請維持預設值。
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
💡 <b>個別使用者模式不需登出</b>；全使用者模式可能要求登出 Windows 後重新登入。
</div>

<!--
【操作提示】
Unpacking files 階段約一至兩分鐘，期間會解壓縮檔案並設定 WSL 2 整合環境，請勿中途關閉。出現 Installation succeeded 即表示安裝完成，按 Close 關閉安裝精靈。

【重點提醒】
Per-user installation 安裝後不需登出 Windows；全使用者模式則可能要求登出，請先儲存工作中的檔案。
-->

---

# ③ 首次啟動 — 服務條款

<div class="grid grid-cols-2 gap-6 items-center">

<div>
<img src="/docker-install-06-terms.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
</div>

<div class="text-sm" style="color:#57606a;">

由**桌面捷徑**或開始功能表開啟 Docker Desktop，首次啟動會顯示 **Docker Subscription Service Agreement**。

按 **Accept** 後才會繼續啟動。

<div class="mt-3 p-2 bg-blue-50 border-l-4 border-blue-400 text-gray-700">
⚠️ 未按 Accept 時 Docker Desktop 不會啟動，此為「安裝後無法開啟」最常見的原因。
</div>

<div class="mt-3 p-2" style="background:#fff8e6; border-left:4px solid #e3b341;">
員工超過 250 人或年營收超過 1000 萬美元的企業商用須付費訂閱；個人學習與教學免費。
</div>

</div>

</div>

<!--
【操作提示】
首次啟動會顯示訂閱服務條款，按右下角 Accept 後繼續。

【易錯點提醒 ⚠️】
「安裝後無法開啟」多數是因為尚未同意條款，程式停留在此步驟。
-->

---

# ③ 首次啟動 — 略過登入

<div class="grid grid-cols-2 gap-6 items-center">

<div>
<img src="/docker-install-07-welcome.png" style="width: 100%; border-radius: 6px; border: 1px solid #d0d7de;" />
</div>

<div class="text-sm" style="color:#57606a;">

接著顯示 **Welcome to Docker**，要求登入 Docker 帳號。

**本課程前半段不需登入**，按右上角 **Skip** 即可。

需要 Docker 帳號的情境：

- **push** Image 至 Docker Hub（第 2、8 章）
- 拉取私有 Registry 的 Image
- 提高拉取次數上限（匿名：每 6 小時 100 次；登入：每 6 小時 200 次）

</div>

</div>

<!--
【操作提示】
按右上角 Skip 略過登入。

【重點解說】
需要登入 Docker 帳號的情境有三種：推送 Image 至 Docker Hub、拉取私有 Image，以及提高拉取次數上限。Docker Hub 對匿名使用者以 IP 計算，每 6 小時上限 100 次；免費帳號登入後為每 6 小時 200 次。課堂上多人共用同一個對外 IP 時，匿名額度容易用完。
-->

---

# ③ Docker Desktop 主畫面

<div class="flex flex-col items-center">

<img src="/docker-install-08-dashboard.png" style="width: 70%; border-radius: 6px; border: 1px solid #d0d7de;" />

</div>

<div class="mt-3 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>安裝成功的判斷依據：</b>左下角顯示綠色 <b>Engine running</b>，右下角顯示版本號（此處為 v4.86.0），工作列鯨魚圖示停止轉動，表示 Daemon 已就緒，可於終端機執行 <code>docker</code> 指令。
</div>

<!--
【重點解說】
左側為主要功能：Containers、Images、Volumes、Logs，後續各章皆會使用。目前尚未執行任何容器，因此 Containers 頁面為空。

【重點提醒】
左下角的 Engine running 表示 Docker Daemon 已啟動。

【易錯點提醒 ⚠️】
若顯示 Starting 或紅色 Engine stopped，請稍候或重新啟動 Docker Desktop，此時執行 docker 指令會失敗。
-->

---

# 安裝 Docker Desktop（macOS）

| 項目 | 需求 / 說明 |
| --- | --- |
| 晶片 | Apple Silicon（M 系列）或 Intel |
| 作業系統 | 目前的 macOS 版本及前兩個主要版本 |
| 硬體 | 至少 4GB RAM |
| Rosetta 2 | Apple Silicon 建議安裝（執行 x86 Image 時使用） |
| 安裝檔 | 依晶片類型下載對應的 `Docker.dmg` |

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>補充：</b>Apple Silicon 與 Intel 的安裝檔不同，下載前請至「選單列 → 關於這台 Mac」確認晶片類型。
</div>

<!--
【重點解說】
macOS 沒有 WSL，Docker Desktop 直接使用 macOS 內建的虛擬化框架執行 Linux 核心。下載頁面會列出 Apple Silicon 與 Intel 兩個版本，選錯晶片版本將無法安裝。

【易錯點提醒 ⚠️】
Apple Silicon 執行僅提供 x86 版本的 Image 時，需依賴 Rosetta 2，因此建議安裝。
-->

---

# 安裝 Docker Desktop（macOS）— 範例

圖形介面安裝：下載 `Docker.dmg` → 雙擊開啟 → 將 Docker 圖示拖入「應用程式」資料夾 → 開啟 `Docker.app`。

命令列安裝：

```bash
sudo hdiutil attach Docker.dmg
sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
sudo hdiutil detach /Volumes/Docker
```

安裝完成後開啟 `Docker.app` 並同意訂閱服務條款，選單列出現鯨魚圖示即表示 Docker Desktop 已啟動。

<!--
【重點解說】
圖形介面安裝方式與一般 macOS 軟體相同。命令列方式適合批次安裝多台機器：`--accept-license` 略過條款確認畫面，另可加上 `--user=<帳號>` 指定安裝的使用者。

【易錯點提醒 ⚠️】
命令列安裝需要 sudo 權限，沒有管理員密碼將無法安裝。

【預期結果】
選單列的鯨魚圖示停止跳動，表示 Daemon 已啟動，可於終端機使用 docker 指令。
-->

---

# 驗證安裝：docker run hello-world

Docker Desktop 啟動後，以官方提供的最小 Image `hello-world` 驗證環境。

```bash
docker --version
docker run hello-world
```

執行流程：

1. Client 將請求送至 Daemon
2. Daemon 於本機找不到 `hello-world`，向 Docker Hub 下載
3. Daemon 建立並啟動 Container
4. Container 輸出確認訊息後結束

畫面出現以「Hello from Docker!」開頭的訊息，即表示 Client、Daemon、Registry 皆運作正常。

<!--
【範例目的】
hello-world 是 Docker 官方提供的最小範例，用於確認環境安裝是否正確。

【回顧】
此流程正好走過第二部分介紹的三個角色：Client 送出指令、Daemon 向 Registry 下載 Image、建立 Container 並執行。

【易錯點提醒 ⚠️】
若出現連線錯誤，通常是 Docker Desktop 尚未完全啟動，或 WSL 2 未正常運作；請確認主畫面左下角為 Engine running。

【預期結果】
終端機輸出以「Hello from Docker!」開頭的訊息。
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
<b>Client</b><br/>輸入 <code>docker run</code>
</div>

<div class="p-2 mb-2 rounded" style="background:#f6f8fa;">
<b>Registry</b><br/><code>Unable to find image … locally</code><br/><code>Pulling from library/hello-world</code>
</div>

<div class="p-2 mb-2 rounded" style="background:#f6f8fa;">
<b>Daemon</b><br/>建立並執行 Container，輸出<br/><code>Hello from Docker!</code>
</div>

</div>

</div>

<!--
【帶讀關鍵行】
- `Docker version 29.7.2`：Docker Engine 的版本，與 Docker Desktop 的 4.86.0 是不同的版本號。
- `Unable to find image 'hello-world:latest' locally`：Daemon 於本機查無此 Image。
- `Pulling from library/hello-world`：向 Docker Hub 下載，出現 Pull complete 表示下載完成。
- `Hello from Docker!`：Daemon 建立容器並執行，容器輸出訊息後結束。

【補充】
輸出中的「To generate this message, Docker took the following steps」段落，即列出本頁所述的四個步驟。

【易錯點提醒 ⚠️】
出現 error during connect 或 cannot connect to the Docker daemon，表示 Docker Desktop 尚未完全啟動，請確認主畫面左下角為 Engine running。
-->

---
layout: default
---

# 練習 1：SSDS 該用 VM 還是 Container？
### 任務說明

SSDS 小組三位組員的開發環境不同：

- A 的 JDK 為 **17**（舊專案使用），SSDS 後端的 Gradle toolchain 要求 **JDK 21**
- B 的 Node 為 **18**，Angular 21 要求 **Node 20.19 / 22.12 / 24** 以上
- C 使用 Mac，A、B 使用 Windows；專案最後須部署至 **Linux 雲端主機**進行展示

請回答：要讓三人與雲端主機執行同一套 SSDS，應採用 Container 或 VM？理由為何？

<!--
【任務鋪陳】
本題將 VM 與 Container 的比較表轉換為實際判斷，情境為小組開發時常見的環境差異。

【出題動機】
判斷時先釐清：組員缺少的是「不同作業系統」，還是「同一套程式所需的執行環境版本」。
-->

---
layout: default
---

# 練習 1：參考答案

**應採用 Container。**

| 判斷依據 | 說明 |
| --- | --- |
| 問題本質 | 組員缺少的是執行環境版本（JDK 21、Node 22），並非不同作業系統；Container 的隔離即已足夠 |
| 資源開銷 | VM 每台需配置數 GB 記憶體並啟動完整 OS，雲端免費方案（約 512MB）無法容納 |
| 可攜性 | `eclipse-temurin:21-jre-alpine`、`node:22-alpine`、`nginx:1.30-alpine` 各自攜帶所需版本，Windows / Mac / Linux 行為一致 |
| 部署一致性 | 同一個 Image 在開發機與雲端平台行為相同，第 9 章即直接部署此 Image |
| 資料庫 | Supabase 位於雲端，各環境皆以網路連線，不需各自安裝 |

<!--
【帶讀解法】
關鍵在於辨識問題本質：組員的作業系統不同，但真正造成問題的是 JDK 與 Node 版本。Container 只需攜帶正確版本的執行環境，即可在三種作業系統與雲端主機上一致執行。

【重點提醒】
VM 適用於需要不同作業系統核心或強隔離的情境；本題兩者皆非必要，採用 VM 只會增加資源成本。
-->

---
layout: default
---

# 練習 2：nginx 容器的啟動流程
### 任務說明

在一台剛安裝 Docker Desktop、尚未下載任何 Image 的電腦上執行：

```bash
docker run -d --name ssds-web-try -p 8000:80 nginx:1.30-alpine
```

1. 寫出從指令送出到 Container 啟動的完整步驟，並標示 Client / Daemon / Registry 各自負責的部分
2. 說明 `-p 8000:80` 中兩個 port 分別屬於何者
3. 若組員將指令改為 `-p 8080:80`，而 IDE 中的 Spring Boot 後端正佔用 8080，會發生什麼情況？

<!--
【任務鋪陳】
本題再次走過 Docker 架構的運作流程，確認能說明 Client、Daemon、Registry 的分工，而非僅記憶名詞。

【出題動機】
第 3 小題刻意設計：在 IDE 執行 Spring Boot 時預設佔用 8080，port 衝突是初學者最常遇到的錯誤之一。
-->

---
layout: default
---

# 練習 2：參考答案

**1. 啟動步驟**

| 步驟 | 負責者 | 動作 |
| --- | --- | --- |
| 1 | Client | 將 `docker run` 請求送至 Daemon |
| 2 | Daemon | 檢查本機 Image，查無 `nginx:1.30-alpine` |
| 3 | Daemon → Registry | 向 Docker Hub 下載 `nginx:1.30-alpine` |
| 4 | Daemon | 以該 Image 建立並啟動 Container `ssds-web-try` |
| 5 | Daemon | 設定 port 映射：主機 8000 → 容器 80 |

**2.** `8000` 為**主機**的 port，`80` 為**容器內** nginx 監聽的 port。

**3.** 容器啟動失敗，錯誤訊息包含 `port is already allocated`（或 `bind: address already in use`）。容器內部使用的 port 互不影響，但主機上同一個 port 只能被一個程式佔用。

<!--
【帶讀解法】
第 1 小題對應「指令流程」頁的五個步驟；因為是全新安裝，第 3 步的下載必定會發生。

【重點提醒】
第 3 小題的處理方式：改用其他主機 port（例如 8000），或先停止佔用 8080 的程式。

【操作提示】
請實際執行本題指令，完成後以 `docker rm -f ssds-web-try` 刪除容器。
-->

---
layout: default
zoom: 0.94
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
<tr><td>容器化</td><td>解決環境不一致的問題；Container 具備自含、隔離、獨立、可攜四項特性</td></tr>
<tr><td>VM vs Container</td><td>VM 包含完整作業系統，隔離強但資源開銷大；Container 共用主機核心，輕量且啟動快</td></tr>
<tr><td>Docker 架構</td><td>Client（送出指令）、Daemon（實際執行）、Registry（存放 Image）</td></tr>
<tr><td>docker run 流程</td><td>Daemon 先檢查本機 Image，查無時才向 Registry 下載</td></tr>
<tr><td>安裝驗證</td><td>安裝 Docker Desktop 後，以 <code>docker run hello-world</code> 驗證環境</td></tr>
<tr><td>貫穿專案</td><td>SSDS 前端 → <code>ssds-web</code>、後端 → <code>ssds-api</code>；資料庫使用雲端 Supabase，不放入 Docker</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>重點：</b>Container 將應用程式與其執行環境一併打包，在任何環境皆能穩定執行，這是 Docker 的核心價值。
</div>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b>映像檔管理 — Image 的下載、標記、刪除與版本命名。
</div>

<!--
【回顧】
本章從容器化的目的出發，比較 VM 與 Container，拆解 Docker 的三大元件，最後安裝 Docker Desktop 並以 hello-world 驗證。

【重點提醒】
Container 將應用程式與執行環境打包在一起，在任何環境皆能穩定執行。

【課程預覽】
下一章介紹 Image 的管理，包含下載、標記、刪除與版本命名。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
【互動引導】
開放提問：容器化概念、VM 與 Container 的差異、Docker 架構或安裝流程，有任何疑問皆可提出。
-->
