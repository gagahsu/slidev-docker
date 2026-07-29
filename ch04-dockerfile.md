---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: Dockerfile
routeAlias: ch04
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
  <h1 style="color: #1a5c5c; font-size: 3.8rem; font-weight: 900; line-height: 1.15; margin-bottom: 1.5rem;">Dockerfile</h1>
  <div style="height: 4px; width: 320px; background: linear-gradient(90deg, #5eada0, #a7d9d0); border-radius: 2px; margin-bottom: 1.5rem;"></div>
  <p style="color: #4a7c7c; font-size: 1.15rem; font-style: italic;">
    「一份寫下來的食譜，讓映像檔可以被重複、被驗證、被信任地做出來」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
大家好，這一章我們要來學 Dockerfile。

前面幾章我們學過怎麼拉取 image、怎麼操作 container，但那些 image 都是別人做好的。如果我們想做出屬於自己的 image，就要靠 Dockerfile。

Dockerfile 是什麼呢？大家可以把它想成「食譜的文字版寫法」。食譜上一步一步寫著要放什麼料、怎麼處理，照著做就會得到同一道菜。Dockerfile 也是一樣，一行一行寫著要用什麼基礎環境、複製什麼檔案、跑什麼指令，docker build 照著做，就會產出同一個 image。

今天這堂課會涵蓋三個重點：Dockerfile 常用指令、docker build 跟 layer cache 的觀念、還有 multi-stage build 跟 .dockerignore。準備好我們就開始吧。
-->

---
layout: default
---

# Outline

<div class="text-left" style="font-size: 1.05rem; line-height: 2.2;">

1. **Dockerfile 常用指令** — FROM / COPY / RUN / CMD / ENTRYPOINT / EXPOSE / ENV
2. **docker build 與 Layer Cache** — 建構流程、快取命中與失效
3. **Multi-stage Build 與 .dockerignore** — 縮小映像檔、排除無關檔案
4. **練習題** — 從一份 Dockerfile 到最佳化
5. **總結**

</div>

<!--
這是我們今天的路線圖。

第一部分先搞懂 Dockerfile 裡最常用的幾個指令，這些是寫任何 Dockerfile 都會用到的基本功。

第二部分講 docker build 怎麼運作，還有一個很重要的觀念叫 layer cache，會直接影響我們 build 的速度。

第三部分講進階一點的技巧，multi-stage build 可以讓映像檔變小很多，還有 .dockerignore 可以避免把不必要的檔案打包進去。

最後留兩題練習題，讓大家動手寫寫看。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Part 1
## Dockerfile 常用指令

<!--
我們先進入第一部分，來看 Dockerfile 裡最常見的幾個指令。

這幾個指令幾乎每份 Dockerfile 都會用到，大家一定要熟悉它們的語法跟用途。
-->

---

# 什麼是 Dockerfile？

Dockerfile 是一份純文字檔案，裡面一行一行寫著「怎麼組出一個 image」的步驟。

「Dockerfile 是食譜的文字版：照著步驟做，就能在任何地方做出一模一樣的 image。」

先看最陽春的版本：把 Gradle 已經打包好的 `taskboard-api.jar` 塞進 image 裡跑起來。

```dockerfile
# taskboard-api/Dockerfile（第一版，之後會再改良）
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY build/libs/taskboard-api-1.0.0.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

```bash
./gradlew bootJar                       # 先在本機打包出 jar
docker build -t taskboard-api:1.0.0 .   # 再包成 image
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>注意事項：</b> Dockerfile 檔名預設就是 <code>Dockerfile</code>（沒有副檔名），docker build 預設會去找這個檔名，也可以用 <code>-f</code> 指定其他檔名。
</div>

<!--
先給大家看一份最容易理解的 Dockerfile，等一下我們會一行一行拆解。

這份做的事情很單純：用只有 JRE 21 的輕量 image 當基礎，設定工作目錄到 /app，把 Gradle 打包好的 jar 複製進去改名成 app.jar，宣告會用到 8080 port，最後指定容器啟動時執行 java -jar。

大家注意這個流程：先在本機 `./gradlew bootJar` 打包，再 docker build。這是最好懂的做法，但有個明顯缺點——它假設「每個要 build image 的人電腦上都裝好 JDK 21 跟 Gradle」。CI 伺服器上不見得有，同事的環境也不見得對。這個問題我們第三部分用 multi-stage build 解決，讓 Gradle 也跑在容器裡。

⚠️ 大家要注意，檔名如果不是叫 Dockerfile，docker build 預設是找不到的，要用 -f 參數手動指定路徑。實務上一個 repo 有多個服務時，常會看到 `Dockerfile.api`、`Dockerfile.web` 這種命名。
-->

---

# Dockerfile 常用指令一覽

| 指令 | 用途 |
| --- | --- |
| `FROM` | 指定基礎 image，開啟一個新的建構階段 |
| `COPY` | 把檔案或目錄從建構上下文複製進 image |
| `RUN` | 在建構過程中執行指令（例如安裝套件） |
| `CMD` | 指定容器啟動時的預設執行指令 |
| `ENTRYPOINT` | 把容器設定成像一個可執行檔一樣運作 |
| `EXPOSE` | 宣告容器會用到的網路埠（僅作說明用） |
| `ENV` | 設定環境變數，build 跟 run 階段都會生效 |

---

# Dockerfile 常用指令 — 範例

把七個指令都用上，寫一份比較完整的 `taskboard-api` Dockerfile：

```dockerfile
FROM eclipse-temurin:21-jre-alpine
ENV APP_HOME=/app
ENV SPRING_PROFILES_ACTIVE=prod
WORKDIR $APP_HOME
RUN addgroup -S app && adduser -S app -G app
COPY build/libs/taskboard-api-1.0.0.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
CMD ["--server.port=8080"]
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>ENV 語法：</b> 現行寫法一律用 <code>ENV KEY=VALUE</code>，舊式 <code>ENV KEY VALUE</code>（沒有等號）已經是過時寫法，官方文件建議不要再用。
</div>

<!--
這份範例把 ENV、RUN、ENTRYPOINT、CMD 都放進來，讓大家看看它們怎麼搭配。

ENV APP_HOME=/app 設定環境變數，後面 WORKDIR 直接用 $APP_HOME。第二個 ENV 更實用：`SPRING_PROFILES_ACTIVE=prod` 等於在 image 裡預設啟用 prod profile，這樣容器一跑起來就會讀 application-prod.yml。而且因為它只是「預設值」，我們 docker run 的時候加一個 `-e SPRING_PROFILES_ACTIVE=dev` 就能蓋掉，同一個 image 兩種環境都能用。

那個 RUN addgroup / adduser 加上 USER app 是資安上的好習慣：容器裡的行程預設是用 root 跑的，萬一應用程式被攻破，攻擊者在容器內就是 root。建一個沒有特權的使用者來跑 java，風險小很多。這在正式環境的 code review 幾乎一定會被要求。

ENTRYPOINT 加 CMD 的組合，意思是「這個容器就是拿來跑這支 jar 的（ENTRYPOINT 固定），但啟動參數可以換（CMD 可覆蓋）」。所以 `docker run taskboard-api:1.0.0 --server.port=9090` 就會用 9090 起服務，Spring Boot 會自動吃這個命令列參數。

⚠️ 版本注意：ENV 一律寫成 KEY=VALUE 的等號形式，舊式沒有等號的寫法官方已列為過時。
-->

---

# 什麼是 CMD 與 ENTRYPOINT 的差異？

「ENTRYPOINT 決定容器『是什麼』，CMD 決定容器『預設帶什麼參數執行』。」

| 情境 | 行為 |
| --- | --- |
| 只有 `CMD ["exec","p1"]` | 容器啟動時執行 `exec p1` |
| 只有 `ENTRYPOINT ["exec","p1"]` | 容器啟動時一定執行 `exec p1`，`docker run` 後面接的參數會補在後面 |
| `ENTRYPOINT ["exec","p1"]` + `CMD ["p2"]` | 執行 `exec p1 p2`，`p2` 是可被覆蓋的預設參數 |
| `ENTRYPOINT` 用殼層式（無中括號） | 會忽略 `CMD` 與 `docker run` 傳入的任何參數 |

<!--
這頁是很多人剛學 Dockerfile 時最容易搞混的地方，我們用便當盒來比喻一下。

ENTRYPOINT 就像便當盒本身——不管你怎麼換菜色，這個盒子的用途不會變。CMD 則像是預設配好的菜色，你可以在點餐的時候臨時換掉。

所以如果只有 CMD，docker run 後面加的參數會整個「取代」CMD。但如果同時有 ENTRYPOINT 跟 CMD，docker run 後面加的參數只會取代 CMD 那部分，ENTRYPOINT 本身是不會被換掉的。

⚠️ 易錯點：ENTRYPOINT 如果寫成殼層式，也就是沒有中括號的那種寫法，官方文件明確說它會忽略 CMD 跟執行時傳入的參數，這跟外層式（中括號）行為完全不同，寫的時候一定要留意用哪一種形式。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Part 2
## docker build 與 Layer Cache

<!--
接下來進入第二部分，來看看 docker build 到底在背後做了什麼事，還有一個對建構效率影響很大的觀念：layer cache（層快取）。
-->

---

# 什麼是 docker build？

「docker build 會把 Dockerfile 逐行讀進去，每一行變成一個 layer（層），疊起來組成最終的 image。」

```bash
# 在 taskboard-api/ 目錄下執行
docker build -t taskboard-api:1.0.0 .

# 指定不同檔名的 Dockerfile（單一 repo 放多個服務時常見）
docker build -f Dockerfile.web -t taskboard-web:1.0.0 ./taskboard-web
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>版本注意：</b> Docker 23.0 之後，docker build 預設就是用 BuildKit 引擎執行（不用再手動設定 <code>DOCKER_BUILDKIT=1</code>），BuildKit 的建構速度與快取管理都比舊版引擎更好。
</div>

<!--
docker build 這個指令做的事情，就是把我們寫好的 Dockerfile 一行一行讀進去執行，每執行完一行產生一個 layer，這些 layer 疊起來就是最終的 image。

指令裡的 -t taskboard-api:1.0.0 是幫 image 取名字加版本號，最後那個點代表「建構上下文」，也就是 Docker 會把當前目錄的檔案送給建構程序使用。⚠️ 這個點很重要：如果我們的 jar 在 build/libs/ 底下，而執行 build 的位置在專案外面，Dockerfile 裡的 COPY 就會找不到檔案，因為那個檔案根本沒被送進上下文。

⚠️ 版本注意：現在的 Docker（23.0 以後）預設就是用 BuildKit 這個新引擎在跑 build，以前舊版要手動加環境變數 DOCKER_BUILDKIT=1 才會啟用，現在不用了，是預設行為。BuildKit 對快取的處理更聰明，也支援更多進階功能。
-->

---

# 什麼是 Layer Cache？

「Layer cache 就像料理時已經切好的菜，只要食材沒變，下次做菜就不用重新切，直接拿來用。」

| 觀念 | 說明 |
| --- | --- |
| Layer（層） | Dockerfile 每一行指令執行後產生的結果快照 |
| Cache 命中 | 該行指令與依賴內容沒變，直接重用舊 layer |
| Cache 失效 | 該行或前面任何一行有變動，這行以後全部重新執行 |
| 由上而下比對 | Docker 由 Dockerfile 第一行開始逐行比對，一旦某行失效，後面全部跟著失效 |
| RUN 指令拆分 | `apt-get update` 與 `apt-get install` 分開寫會造成過期套件問題 |

---

# Layer Cache — 範例：Gradle 依賴

```dockerfile
# 錯誤示範：原始碼跟建構檔一起複製
COPY . .
RUN ./gradlew bootJar --no-daemon      # 改一行 Java 就要重抓所有依賴

# 正確示範：先複製 Gradle 設定，把依賴下載鎖在一層
COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle
RUN ./gradlew dependencies --no-daemon  # build.gradle 沒改就吃快取
COPY src ./src
RUN ./gradlew bootJar --no-daemon
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>差多少？</b> Spring Boot 專案第一次抓依賴常要一兩分鐘，排好順序之後，只改 Java 檔重 build 大約十幾秒 — 差距每天會發生幾十次。
</div>

<!--
這頁是整章對大家日常工作影響最大的一頁。

先看錯誤示範。`COPY . .` 把整個專案複製進去，包含 src 底下所有 Java 檔。結果就是我們只要改一行 Controller，這層的內容就變了，快取失效，後面的 gradlew 整條重跑——重新解析 build.gradle、重新從 Maven Central 下載 Spring Boot 那一大包依賴。改一行程式碼等一分半，一天下來浪費的時間很可觀。

正確示範的思路是：把「很少變的」跟「一直變的」分開。build.gradle 我們可能兩個禮拜才動一次，src 底下的檔案一天改二十次。所以先只複製 gradlew、settings.gradle、build.gradle 跟 gradle wrapper 目錄，跑一次 dependencies 把所有依賴抓進 image 的那一層；接著才複製 src，跑 bootJar。這樣只要沒動 build.gradle，依賴那層永遠命中快取，重 build 只要重跑編譯那一步。

注意 `--no-daemon` 這個參數：Gradle 平常會在背景留一個 daemon 行程加速後續建構，但容器建構是一次性的，留 daemon 只會讓 build 卡住不結束，所以在 Dockerfile 裡一律要加。

順帶一提，apt-get update 跟 install 一定要用 && 寫在同一條 RUN，這是同樣的快取陷阱，只是換成 Debian 套件。⚠️ 這個坑很隱蔽，build 不會報錯，只是悄悄裝到舊版套件。
-->

---

# 使用 Layer Cache 的注意事項

「把常變動的指令放後面，把穩定不變的指令放前面，快取效益才會最大。」

| 原則 | 說明 |
| --- | --- |
| 依賴安裝要早 | `build.gradle`（後端）、`package.json`（前端）這種依賴清單，先 COPY 進去再 RUN 安裝 |
| 原始碼複製要晚 | `src/` 底下的 Java 與 TypeScript 幾乎天天改，放在依賴安裝之後再 COPY |
| 順序決定快取範圍 | 只要某一行失效，Dockerfile 裡它之後的每一行都會重新執行 |
| `--no-cache` | 建構時強制忽略所有快取，從頭重新跑一次 |

```bash
docker build --no-cache -t taskboard-api:1.0.0 .
```

<!--
這頁的觀念很重要，先講結論：常常改動的東西放後面，很少改動的東西放前面。

為什麼呢？因為 Docker 是由上往下比對的，只要某一行的內容變了，那一行『以及它之後的所有行』都要重新跑，不管後面那些行本身有沒有變。

TaskBoard 的兩個服務剛好是同一個模式：後端的 build.gradle 對應前端的 package.json，兩者都是「很少改的依賴清單」；後端的 src/main/java 對應前端的 src/app，兩者都是「天天改的原始碼」。順序都是先複製清單、裝依賴，再複製原始碼、編譯。

至於什麼時候該用 --no-cache？最常見的情境是懷疑快取「髒了」——比方說明明改了設定卻沒生效，或者 CI 上要確保完全乾淨的建構。平常開發不要加，加了就完全沒有快取加速可言。

如果我們想要完全不使用任何舊快取，可以加上 --no-cache，這在確認環境乾淨、或者懷疑快取有問題時很有用。

⚠️ 大家想像一下，如果反過來把原始碼放前面、依賴清單放後面，那我們每改一行程式碼，後面裝套件的那一大串全部都要重跑，build 時間會拖得很長，這就是順序沒排好的代價。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Part 3
## Multi-stage Build 與 .dockerignore

<!--
第三部分我們來看兩個能讓映像檔更精簡、更乾淨的技巧：multi-stage build（多階段建構）跟 .dockerignore。
-->

---

# 什麼是 Multi-stage Build？

「Multi-stage build：一份 Dockerfile 包含多個『建構階段』，只把需要的成品搬進最終 image，其餘建構工具不會被打包進去。」

| 語法元素 | 用途 |
| --- | --- |
| `FROM <image> AS <stage-name>` | 開啟一個具名的建構階段 |
| `COPY --from=<stage-name>` | 從指定階段複製檔案到目前階段 |
| `--target <stage-name>` | build 時指定只建到某個階段為止 |
| 多個 `FROM` | 一份 Dockerfile 可以有多個建構階段 |

<!--
之前我們寫的 Dockerfile 都只有一個 FROM，所有建構工具、原始碼、最後產出的東西全部都疊在同一個 image 裡，這樣 image 會很肥大，裡面塞了一堆 build 完就用不到的東西，例如編譯器、開發套件。

Multi-stage build 解決的就是這個問題。我們可以開多個階段，前面的階段負責「做菜」——編譯程式碼、安裝開發套件；最後一個階段負責「裝盤」——只把做好的成品複製過來，其他半成品跟廚房裡的鍋碗瓢盆（建構工具）通通不會帶到最終的 image 裡。

用 COPY --from=階段名稱，就能把前面階段的產出物指定複製過來。

⚠️ 大家要記得，中間階段不會出現在最終 image 裡，所以如果要 debug 中間階段的內容，可以用 --target 指定 build 到那個階段就好，方便檢查。
-->

---

# Multi-stage Build — taskboard-api

```dockerfile
# ---- 第一階段：用 Gradle 編譯，本機不需要裝 JDK ----
FROM gradle:8.10-jdk21 AS build
WORKDIR /src
COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle
RUN ./gradlew dependencies --no-daemon
COPY src ./src
RUN ./gradlew bootJar --no-daemon

# ---- 第二階段：只留 JRE 跟打包好的 jar ----
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=build /src/build/libs/*.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>成果：</b> 建構階段的 <code>gradle:8.10-jdk21</code> 約 800MB，但最終 image 只有 <b>約 200MB</b> — 完整 JDK、Gradle、原始碼、依賴快取全部留在第一階段，不會進到成品裡。
</div>

<!--
這頁是整章的重頭戲，也是大家之後真的會複製貼上到專案裡用的 Dockerfile。

先看第一階段。FROM gradle:8.10-jdk21 AS build，這個 image 裡面有完整 JDK 21 跟 Gradle，所以編譯這件事整個搬進容器裡做了。這解決了前面提到的問題：現在不管是誰的電腦、或是 CI 伺服器，只要有 Docker 就能 build，完全不需要在本機裝 JDK 21，也不會有「我電腦是 JDK 17 所以 build 失敗」這種事。

中間那幾行就是我們剛剛講的快取排序：先 gradlew 跟 build.gradle，抓依賴，再 src，才 bootJar。

第二階段是關鍵。FROM eclipse-temurin:21-jre-alpine 重新開一個乾淨的環境，注意是 jre 不是 jdk——我們只要「跑」jar，不需要編譯器。然後用 COPY --from=build 把第一階段產出的 jar 撈過來。

大家想一下差別有多大：第一階段那個容器裡有 JDK、有 Gradle、有整個 ~/.gradle 的依賴快取、有全部原始碼，加起來快 1GB。這些東西對「執行」一點用都沒有，全部被丟掉了。最終 image 只有 Alpine + JRE + 一支 jar，200MB 左右。

這不只是省硬碟。image 越小，push 越快、pull 越快、部署越快，而且攻擊面越小——image 裡沒有編譯器跟原始碼，就算被攻進去能做的事也少。

⚠️ 這裡的 COPY --from=build 用了 *.jar 萬用字元，前提是 build/libs 底下只有一支 jar。如果 Gradle 同時產出 plain jar，記得在 build.gradle 關掉 `jar { enabled = false }`，否則會複製到錯的那支，容器一跑就報 no main manifest attribute。
-->

---

# Multi-stage Build — taskboard-web

Angular 更適合 multi-stage：Node 只在建構時需要，跑起來根本用不到。

```dockerfile
# ---- 第一階段：用 Node 編譯 Angular ----
FROM node:20-alpine AS build
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build          # 產出到 dist/taskboard-web/browser

# ---- 第二階段：只留 nginx 跟靜態檔 ----
FROM nginx:1.27-alpine
COPY --from=build /src/dist/taskboard-web/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>成果：</b> 建構階段含 <code>node_modules</code> 動輒 <b>1GB 以上</b>，最終 image 只有 nginx 加幾 MB 的靜態檔，<b>約 50MB</b>。
</div>

<!--
前端這份比後端更能感受到 multi-stage 的價值。

大家想想 Angular 專案的 node_modules 有多大，隨便都是幾百 MB 到 1GB。但這些東西是「編譯時」才需要的——Angular 編譯完就是一堆 HTML、CSS、JS 靜態檔案，瀏覽器下載它們就能跑，執行階段完全不需要 Node，更不需要 node_modules。

所以第一階段用 node:20-alpine 跑 npm ci 跟 npm run build，第二階段直接換成 nginx，只把 dist 底下的產出物複製到 nginx 的預設網站根目錄。最終 image 五十幾 MB，裡面連 Node 都沒有。

注意 `npm ci` 不是 `npm install`。ci 會嚴格照著 package-lock.json 安裝，版本完全鎖定，而且會先清空 node_modules，這正是我們要的可重現建構；install 則可能會去更新 lock 檔，同一份程式碼在不同時間 build 出不同結果。容器建構一律用 ci。

⚠️ 那個 dist 路徑要注意版本差異：Angular 17 之後預設輸出到 `dist/<專案名>/browser`，17 以前是 `dist/<專案名>`。路徑寫錯的話 build 會過，但容器跑起來打開網頁是 nginx 的預設歡迎頁或 404。第三章教的 `docker exec -w /usr/share/nginx/html taskboard-web ls` 就是拿來查這個的。

至於那個 nginx.conf，主要是設定 Angular 路由的 fallback（所有找不到的路徑都回 index.html），還有把 /api 轉發到後端——這個第六章會完整講。
-->

---

# 什麼是 .dockerignore？

「.dockerignore 用來排除不需要送進建構上下文的檔案，讓上下文更乾淨、build 更快。」

| 項目 | 說明 |
| --- | --- |
| 用途 | 排除不需要送進建構上下文的檔案或目錄 |
| 語法 | 跟 `.gitignore` 的排除模式類似 |
| 放置位置 | 與 Dockerfile 同一目錄（通常是專案根目錄） |
| 常見排除對象 | `node_modules`、`build/`、`.gradle/`、`.git`、本機環境檔 |
| 效益 | 縮小建構上下文、避免機密檔案被打包、加快 build 速度 |

```plaintext
# taskboard-api/.dockerignore        # taskboard-web/.dockerignore
.git                                 # .git
.gradle/                             # node_modules/
build/                               # dist/
*.md                                 # .env*
src/main/resources/application-local.yml
```

<!--
.dockerignore 這個檔案的用法，跟大家熟悉的 .gitignore 幾乎一模一樣，寫法也是每行一個排除規則。

它解決的問題是：docker build 執行時，會把當前目錄整個打包成「建構上下文」送給建構程序。TaskBoard 兩個專案都有很痛的例子——前端的 node_modules 動輒 1GB，後端的 .gradle 快取跟 build 目錄也是幾百 MB，這些全部都會被送進去，光是「送」就要等好幾十秒，而且送進去之後第一階段還會用 npm ci / gradlew 重做一次，完全是白費工。

資安面更要小心。後端專案裡常有 `application-local.yml` 放著本機資料庫密碼，前端常有 `.env` 放 API key，這些都絕對不能進 image——因為 image 是會被 push 到 registry 的，任何人 pull 下來都能翻出來看。

順帶一提，排除所有 Markdown 只要寫一行 *.md 就可以了。

⚠️ 易錯點：.dockerignore 只影響「建構上下文」要不要送進去，不等於 image 裡不會出現這些檔案。如果 Dockerfile 裡用 COPY . . 把整個上下文複製進去，那有沒有 .dockerignore 排除掉 .env，會直接決定機密檔案會不會被打包進最終 image，這點務必小心。
-->

---
layout: default
---

# 練習 1：修好 taskboard-api 的 Dockerfile
### 任務說明

同事寫的這份 Dockerfile 可以動，但每次改一行 Java 就要重抓一次所有 Spring Boot 依賴，build 一次要一分半：

```dockerfile
FROM gradle:8.10-jdk21
WORKDIR /src
COPY . .
RUN ./gradlew bootJar --no-daemon
EXPOSE 8080
CMD ["java", "-jar", "build/libs/taskboard-api-1.0.0.jar"]
```

任務：

1. 調整指令順序，讓「只改 `src/` 、沒改 `build.gradle`」時，依賴下載那層可以吃到 layer cache
2. 實測：改一行 Controller 再 build 一次，觀察哪幾步顯示 `CACHED`

---
layout: default
---

# 練習 1：解題提示
### 提示說明

1. 先問自己：`build.gradle` 跟 `src/` 底下的 Java 檔，哪個改動頻率低？
2. 把低頻的先 `COPY` 進去 — 注意 Gradle 需要的是 **四樣東西**：`gradlew`、`settings.gradle`、`build.gradle`、`gradle/` 目錄（wrapper）
3. 接著 `RUN ./gradlew dependencies --no-daemon` 把依賴鎖成獨立一層
4. 最後才 `COPY src ./src` 並執行 `bootJar`

```dockerfile
COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle
RUN ./gradlew dependencies --no-daemon
COPY src ./src
RUN ./gradlew bootJar --no-daemon
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>常見錯誤：</b> 只 COPY 了 <code>build.gradle</code> 卻忘記 <code>gradle/</code> 目錄，build 會失敗在 <code>gradlew: gradle-wrapper.jar not found</code>。
</div>

---
layout: default
---

# 練習 2：把 taskboard-web 改成 Multi-stage
### 任務說明

前端目前這份 Dockerfile 建出來的 image 有 **1.2GB**，而且裡面看得到完整原始碼與 `.env`：

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build
EXPOSE 4200
CMD ["npx", "http-server", "dist/taskboard-web/browser"]
```

任務：

1. 改寫成 multi-stage：第一階段用 Node 編譯，第二階段換成 `nginx:1.27-alpine`，只複製 `dist/taskboard-web/browser` 的產出物
2. 把 `npm install` 換成 `npm ci`，並調整順序讓依賴安裝能吃快取
3. 新增 `.dockerignore`，確保 `node_modules`、`dist`、`.env` 不會被送進建構上下文
4. 驗證：`docker images` 比較改寫前後的大小，並進容器確認裡面沒有 `.ts` 原始碼與 `.env`

---
layout: default
---

# 練習 2：解題提示
### 提示說明

```dockerfile
FROM node:20-alpine AS build
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:1.27-alpine
COPY --from=build /src/dist/taskboard-web/browser /usr/share/nginx/html
EXPOSE 80
```

```plaintext
# .dockerignore
node_modules
dist
.env*
.git
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>驗證方式：</b> <code>docker run --rm -it taskboard-web:1.0.0 sh</code> 進容器，
<code>ls /usr/share/nginx/html</code> 應該只有 <code>index.html</code> 跟一堆雜湊檔名的 js/css，找不到任何 <code>.ts</code>。
</div>

<!--
這兩題練習的講稿放在這裡一起講。

練習一是快取排序，重點是讓大家自己動手體會「順序改一下，build 時間從 90 秒變 15 秒」。請務必真的 build 兩次比較，光看投影片沒有感覺。那個提示裡的常見錯誤我特別標出來，因為十個人有八個會忘記 COPY gradle 目錄——gradlew 只是一個 shell 腳本，真正的執行邏輯在 gradle/wrapper/gradle-wrapper.jar 裡面。

練習二是這章的驗收題，把 multi-stage、npm ci、.dockerignore 三個技巧結合起來。1.2GB 變 50MB，這個數字差距最能讓大家記住 multi-stage 的價值。

⚠️ 另外提醒第 4 步的驗證一定要做。很多人以為「我沒有 COPY .env 就沒事」，但只要寫了 COPY . . 而 .dockerignore 沒排除，機密就進 image 了，而且 image 一 push 到 registry 全公司都看得到。

⚠️ 易錯點：很多人會忘記，就算用了 multi-stage build，如果 .dockerignore 沒排除 .env，第一階段 COPY . . 的時候還是會把 .env 讀進建構上下文，只是不一定會出現在『最終』image 裡，但只要哪個階段不小心 COPY 到它，就會外洩，所以兩個技巧要一起用才安全。

大家做完可以自己 docker build 一次，然後用 docker images 看看體積差多少，會很有成就感。
-->

---
layout: default
---

<style>
.summary-table { width: 100%; border-collapse: collapse; margin: 1.5rem 0; }
.summary-table th { text-align: left; padding: 10px 8px; color: #64748b; font-weight: 600; font-size: 0.95rem; border: none !important; border-bottom: 2px solid #e2e8f0 !important; }
.summary-table td { text-align: left; padding: 12px 8px; border: none !important; border-bottom: 1px solid #e2e8f0 !important; }
</style>

# 本章總結 — Dockerfile

<table class="summary-table">
<tr><th>主題</th><th>重點回顧</th></tr>
<tr><td>常用指令</td><td><code>FROM</code>、<code>COPY</code>、<code>RUN</code>、<code>CMD</code>、<code>ENTRYPOINT</code>、<code>EXPOSE</code>、<code>ENV</code>，各司其職</td></tr>
<tr><td>ENV 語法</td><td>現行一律用 <code>ENV KEY=VALUE</code>，不用舊式空格寫法</td></tr>
<tr><td>docker build</td><td>讀 Dockerfile 逐行執行，每行變成一個 layer；Docker 23.0+ 預設用 BuildKit</td></tr>
<tr><td>Layer Cache</td><td>順序決定快取效益，常變動的指令放後面</td></tr>
<tr><td>Multi-stage Build</td><td>用多個 <code>FROM</code> 階段，只把需要的成品搬進最終 image</td></tr>
<tr><td>.dockerignore</td><td>排除不需要的檔案，避免機密外洩、加快 build</td></tr>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入 Docker Compose，學習用一份 YAML 檔案一次定義、啟動多個服務。
</div>

<!--
今天這一章的內容比較扎實，我們快速複習一下。

我們學了 Dockerfile 最核心的幾個指令，也搞懂了 CMD 跟 ENTRYPOINT 的差異。接著理解了 docker build 背後的 layer 跟快取機制，知道指令順序會直接影響 build 速度。最後學了 multi-stage build 跟 .dockerignore 這兩個能讓 image 更精簡、更安全的技巧。

⚠️ 版本注意：今天特別提醒兩個版本相關的重點，一個是 ENV 語法要用等號寫法，另一個是 Docker 23.0 之後 build 預設就是用 BuildKit，這兩個都是這幾年 Docker 生態系的現行標準，大家寫新的 Dockerfile 就照這個標準寫。

下一章我們會進入 Docker Compose，把多個 container 組合起來一起管理，我們下堂課見。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對 Dockerfile 常用指令、Layer Cache 機制，或是 Multi-stage Build，有沒有什麼疑問？都歡迎提出來討論。

如果對 FROM、COPY、RUN 這些指令還不熟，建議回去自己動手寫一份簡單的 Dockerfile 練習一下，實際 build 過一次比看十次投影片都有用。
-->
