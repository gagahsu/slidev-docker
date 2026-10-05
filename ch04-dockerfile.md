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

- **Dockerfile 常用指令** — FROM / COPY / RUN / CMD / ENTRYPOINT / EXPOSE / ENV
- **docker build 與 Layer Cache** — 建構流程、快取命中與失效、多模組的眉角
- **Multi-stage Build 與 .dockerignore** — 寫出 `ssds-api`、`ssds-web` 的正式 Dockerfile
- **練習題** — 在自己的專案 build 出兩個 Image
- **總結**

</div>

<!--
這是我們今天的路線圖。

第一部分先搞懂 Dockerfile 裡最常用的幾個指令，這些是寫任何 Dockerfile 都會用到的基本功。

第二部分講 docker build 怎麼運作，還有一個很重要的觀念叫 layer cache，會直接影響我們 build 的速度。我們的後端是 Gradle 多模組專案，快取的寫法會比一般教學範例多一點眉角。

第三部分講 multi-stage build 跟 .dockerignore，最後產出的兩份 Dockerfile，就是第五章 Compose、第九章部署到雲端會一直沿用的正式版本。

最後留兩題練習題，請大家直接在自己的專案上做。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Dockerfile 常用指令

<!--
我們先進入第一部分，來看 Dockerfile 裡最常見的幾個指令。

這幾個指令幾乎每份 Dockerfile 都會用到，大家一定要熟悉它們的語法跟用途。
-->

---

# 什麼是 Dockerfile？

Dockerfile 是一份純文字檔案，裡面一行一行寫著「怎麼組出一個 image」的步驟。

「Dockerfile 是食譜的文字版：照著步驟做，就能在任何地方做出一模一樣的 image。」

先看最陽春的版本：把第三章本機打包好的 `ssds.jar` 塞進 image 裡跑起來。

```dockerfile
# ai-products-selection-backend/Dockerfile（第一版，之後會再改良）
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY ssds-api/build/libs/ssds.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

```bash
./gradlew :ssds-api:bootJar -x test    # 先在本機打包出 jar
docker build -t ssds-api:1.0.0 .       # 再包成 image
docker run -d --name ssds-api -p 8080:8080 --env-file .env ssds-api:1.0.0
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>注意事項：</b> Dockerfile 檔名預設就是 <code>Dockerfile</code>（沒有副檔名），放在專案根目錄；docker build 預設會去找這個檔名，也可以用 <code>-f</code> 指定其他檔名。
</div>

<!--
先給大家看一份最容易理解的 Dockerfile，等一下我們會一行一行拆解。

這份做的事情就是把第三章那串很長的 docker run 指令「固化」進 image：用只有 JRE 21 的輕量 image 當基礎，設定工作目錄到 /app，把 Gradle 打包好的 ssds.jar 複製進去改名成 app.jar，宣告會用到 8080 port，最後指定容器啟動時執行 java -jar。

大家比較一下第三章的寫法：那時候要 -v 把 jar 資料夾借給容器、要 -w 設工作目錄、最後還要自己打 java -jar。現在這些都寫進 Dockerfile 了，docker run 只剩下 port 跟 --env-file。

⚠️ 注意 --env-file 還是要帶。機密值「永遠不進 image」，是在執行的時候才給——這個原則第八章、第九章會一直出現。

這個流程的缺點是：它假設「每個要 build image 的人電腦上都裝好 JDK 21」。第九章雲端平台幫我們 build 的時候，它的機器上可沒有我們的 build 目錄。這個問題第三部分用 multi-stage build 解決，讓 Gradle 也跑在容器裡。
-->

---

# Dockerfile 常用指令一覽

| 指令 | 用途 |
| --- | --- |
| `FROM` | 指定基礎 image，開啟一個新的建構階段 |
| `COPY` | 把檔案或目錄從建構上下文複製進 image |
| `RUN` | 在建構過程中執行指令（例如安裝套件、編譯） |
| `CMD` | 指定容器啟動時的預設執行指令 |
| `ENTRYPOINT` | 把容器設定成像一個可執行檔一樣運作 |
| `EXPOSE` | 宣告容器會用到的網路埠（僅作說明用） |
| `ENV` | 設定環境變數，build 跟 run 階段都會生效 |
| `WORKDIR` / `USER` | 設定工作目錄 / 切換執行身分 |

---

# Dockerfile 常用指令 — 範例

把常用指令都用上，寫一份比較完整的 `ssds-api` Dockerfile：

```dockerfile
FROM eclipse-temurin:21-jre-alpine
ENV SPRING_PROFILES_ACTIVE=prod
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app \
 && mkdir -p /app/uploads && chown -R app:app /app
COPY ssds-api/build/libs/ssds.jar app.jar
USER app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
CMD ["--server.port=8080"]
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>ENV 語法：</b> 現行寫法一律用 <code>ENV KEY=VALUE</code>，舊式 <code>ENV KEY VALUE</code>（沒有等號）已經是過時寫法，官方文件建議不要再用。
</div>

<!--
這份範例把 ENV、RUN、USER、ENTRYPOINT、CMD 都放進來，讓大家看看它們怎麼搭配。

`ENV SPRING_PROFILES_ACTIVE=prod`：我們專案的 application.properties 寫的是 `spring.profiles.active=${SPRING_PROFILES_ACTIVE:dev}`，不設的話預設跑 dev，會開 show-sql 跟 SQL 參數 trace，log 量非常大。image 裡預設 prod，正式環境就安靜；本機想看 SQL 的時候 docker run 加 `-e SPRING_PROFILES_ACTIVE=dev` 就能蓋掉。

那個 RUN addgroup / adduser 加上 USER app 是資安上的好習慣：容器裡的行程預設是用 root 跑的，萬一應用程式被攻破，攻擊者在容器內就是 root。建一個沒有特權的使用者來跑 java，風險小很多。

⚠️ 注意 `mkdir -p /app/uploads && chown`：我們的專案會把商品圖片寫到 `./uploads/product`。切成 app 使用者之後，如果 /app 還是 root 的，Spring Boot 一寫檔就是 Permission denied。所以要在切換身分「之前」，先用 root 把目錄建好、把擁有者改成 app。第七章掛 Volume 時這個目錄也會用到。

ENTRYPOINT 加 CMD 的組合，意思是「這個容器就是拿來跑這支 jar 的（ENTRYPOINT 固定），但啟動參數可以換（CMD 可覆蓋）」。所以 `docker run ssds-api:1.0.0 --server.port=9090` 就會用 9090 起服務，Spring Boot 會自動吃這個命令列參數。

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

⚠️ 易錯點：ENTRYPOINT 如果寫成殼層式，也就是沒有中括號的那種寫法，官方文件明確說它會忽略 CMD 跟執行時傳入的參數，而且 java 會變成 sh 的子行程，docker stop 送的 SIGTERM 收不到，Spring Boot 沒辦法優雅關閉，等 10 秒後被強制砍掉。寫的時候一律用中括號。
-->

---

# 容器化前的準備：加上 Actuator 健康檢查

第五章 healthcheck、第九章雲端平台都需要一個「問一下就知道活著沒」的網址：

```groovy
// ssds-api/build.gradle — dependencies 區塊加一行
implementation 'org.springframework.boot:spring-boot-starter-actuator'
```

```bash
# 重新 bootRun 或 build 之後
curl http://localhost:8080/api/v1/actuator/health
# {"status":"UP"}
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>路徑注意：</b> 專案設定了 <code>server.servlet.context-path=/api/v1</code>，所以 actuator 也在 <code>/api/v1</code> 底下，<b>不是</b> <code>/actuator/health</code>。
</div>

<!--
在寫正式的 Dockerfile 之前，我們先對專案做一個很小的改動：加上 Spring Boot Actuator。

為什麼？容器跑起來之後，Docker、Compose、雲端平台都需要一個方法判斷「這個服務到底好了沒」。光看容器是 Up 不夠——Spring Boot 啟動要十幾秒，中間 java 行程早就在了，但還沒辦法服務；或是跑起來了，但連不上 Supabase。Actuator 的 /health 端點會實際檢查資料庫連線，全部正常才回 UP。

加一行依賴就好，版本由 Spring Boot BOM 決定，不用寫。我們專案的 SecurityConfig 目前是全部 permitAll，所以不用另外開放權限。

⚠️ 注意路徑：大家專案 CONTEXT.md 裡有寫，context-path 統一設成 /api/v1，所以 actuator 也被移到這個前綴底下。第五章跟第九章設定健康檢查路徑的時候，一定要寫 /api/v1/actuator/health，寫錯的話平台會一直判定服務掛掉、不斷重啟。

預期結果：本機重新啟動後，打這個網址會回 {"status":"UP"}。這個改動請 commit 進專案，後面每一章都會用到。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# docker build 與 Layer Cache

<!--
接下來進入第二部分，來看看 docker build 到底在背後做了什麼事，還有一個對建構效率影響很大的觀念：layer cache（層快取）。
-->

---

# 什麼是 docker build？

「docker build 會把 Dockerfile 逐行讀進去，每一行變成一個 layer（層），疊起來組成最終的 image。」

```bash
# 在 ai-products-selection-backend/ 目錄下執行
docker build -t ssds-api:1.0.0 .

# 在上一層目錄，指定建構上下文與 Dockerfile 位置
docker build -t ssds-web:1.0.0 \
  -f ai-products-selection-frontend/Dockerfile ai-products-selection-frontend
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>版本注意：</b> Docker 23.0 之後，docker build 預設就是用 BuildKit 引擎執行（不用再手動設定 <code>DOCKER_BUILDKIT=1</code>），BuildKit 的建構速度與快取管理都比舊版引擎更好。
</div>

<!--
docker build 這個指令做的事情，就是把我們寫好的 Dockerfile 一行一行讀進去執行，每執行完一行產生一個 layer，這些 layer 疊起來就是最終的 image。

指令裡的 -t ssds-api:1.0.0 是幫 image 取名字加版本號，最後那個點代表「建構上下文」，也就是 Docker 會把當前目錄的檔案送給建構程序使用。

⚠️ 這個點很重要：Dockerfile 裡所有 COPY 的來源路徑，都是「相對於建構上下文」。如果在錯的目錄執行 docker build，COPY ssds-api/build/libs/ssds.jar 就會報 not found，因為那個檔案根本沒被送進上下文。

第二行示範在專案外層 build 前端：-f 指定 Dockerfile 在哪，最後一個參數指定上下文是前端資料夾。第五章 Compose 的 build.context 就是在設定這個。

⚠️ 版本注意：現在的 Docker（23.0 以後）預設就是用 BuildKit 這個新引擎在跑 build，以前舊版要手動加環境變數 DOCKER_BUILDKIT=1 才會啟用，現在不用了，是預設行為。
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
| COPY 比對內容 | `COPY` 會比對檔案內容的 checksum，檔案一改就失效 |

---

# Layer Cache — 範例：Gradle 多模組依賴

```dockerfile
# 錯誤示範：原始碼跟建構檔一起複製
COPY . .
RUN ./gradlew --no-daemon :ssds-api:bootJar   # 改一行 Java 就要重抓所有依賴

# 正確示範：先複製「所有」Gradle 設定，把依賴下載鎖在一層
COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle                           # wrapper + libs.versions.toml
COPY ssds-api/build.gradle         ssds-api/
COPY ssds-core/build.gradle        ssds-core/
COPY ssds-ai/build.gradle          ssds-ai/
COPY ssds-ingest/build.gradle      ssds-ingest/
COPY ssds-calibration/build.gradle ssds-calibration/
COPY ssds-infra/build.gradle       ssds-infra/
RUN ./gradlew --no-daemon :ssds-api:dependencies > /dev/null
COPY . .
RUN ./gradlew --no-daemon :ssds-api:bootJar -x test
```

<!--
這頁是整章對大家日常工作影響最大的一頁。

先看錯誤示範。`COPY . .` 把整個專案複製進去，包含所有 Java 檔。結果就是我們只要改一行 Controller，這層的內容就變了，快取失效，後面的 gradlew 整條重跑——重新下載 Gradle 9.5.1 本體、重新從 Maven Central 下載 Spring Boot、POI、ICU4J 那一大包依賴。改一行程式碼等好幾分鐘。

正確示範的思路是：把「很少變的」跟「一直變的」分開。我們是多模組專案，Gradle 要能解析依賴，需要的東西比單模組多：
- gradlew 跟 gradle 目錄：wrapper 腳本、wrapper jar，還有版本目錄 libs.versions.toml 也在 gradle 目錄裡
- 根目錄的 settings.gradle、build.gradle
- 六個子模組各自的 build.gradle——settings.gradle 裡 include 了六個模組，少一個 Gradle 就會抱怨找不到專案設定

跑一次 `:ssds-api:dependencies` 把可執行模組需要的依賴抓進這一層；接著才 COPY 全部原始碼，跑 bootJar。只要沒動任何 build.gradle，依賴那層永遠命中快取。

`-x test` 是跳過測試：我們有些測試會用 Testcontainers，要在 build 容器裡再開 Docker，太複雜；測試留在本機或 CI 跑。`--no-daemon`：容器建構是一次性的，Gradle daemon 留著沒意義。

⚠️ 新增模組的時候記得回來這裡補一行 COPY，否則 Gradle 會在依賴那層失敗。
-->

---

# 使用 Layer Cache 的注意事項

「把常變動的指令放後面，把穩定不變的指令放前面，快取效益才會最大。」

| 原則 | 說明 |
| --- | --- |
| 依賴安裝要早 | `build.gradle`（後端）、`package.json` + `package-lock.json`（前端）先 COPY 進去再安裝 |
| 原始碼複製要晚 | `src/` 底下的 Java 與 TypeScript 幾乎天天改，放在依賴安裝之後再 COPY |
| 順序決定快取範圍 | 只要某一行失效，Dockerfile 裡它之後的每一行都會重新執行 |
| `--no-cache` | 建構時強制忽略所有快取，從頭重新跑一次 |

```bash
docker build --no-cache -t ssds-api:1.0.0 .
```

<!--
這頁的觀念很重要，先講結論：常常改動的東西放後面，很少改動的東西放前面。

為什麼呢？因為 Docker 是由上往下比對的，只要某一行的內容變了，那一行『以及它之後的所有行』都要重新跑，不管後面那些行本身有沒有變。

SSDS 的兩個專案剛好是同一個模式：後端的 build.gradle 對應前端的 package.json，兩者都是「很少改的依賴清單」；後端的 src/main/java 對應前端的 src/app，兩者都是「天天改的原始碼」。順序都是先複製清單、裝依賴，再複製原始碼、編譯。

至於什麼時候該用 --no-cache？最常見的情境是懷疑快取「髒了」——比方說明明改了設定卻沒生效，或者 CI 上要確保完全乾淨的建構。平常開發不要加，加了就完全沒有快取加速可言。

⚠️ 大家想像一下，如果反過來把原始碼放前面、依賴清單放後面，那我們每改一行程式碼，後面裝套件的那一大串全部都要重跑，build 時間會拖得很長，這就是順序沒排好的代價。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Multi-stage Build 與 .dockerignore

<!--
第三部分我們來看兩個能讓映像檔更精簡、更乾淨的技巧：multi-stage build（多階段建構）跟 .dockerignore。

這部分寫完的兩份 Dockerfile，就是我們專案的正式版本。
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
之前我們寫的 Dockerfile 都只有一個 FROM，而且 jar 是在本機 build 好才 COPY 進去。如果改成在容器裡編譯，那編譯器、Gradle、原始碼、依賴快取全部都會疊在同一個 image 裡，image 會很肥大。

Multi-stage build 解決的就是這個問題。我們可以開多個階段，前面的階段負責「做菜」——編譯程式碼、安裝開發套件；最後一個階段負責「裝盤」——只把做好的成品複製過來，其他半成品跟廚房裡的鍋碗瓢盆（建構工具）通通不會帶到最終的 image 裡。

用 COPY --from=階段名稱，就能把前面階段的產出物指定複製過來。

⚠️ 大家要記得，中間階段不會出現在最終 image 裡，所以如果要 debug 中間階段的內容，可以用 --target 指定 build 到那個階段就好，方便檢查。
-->

---
zoom: 0.85
---

# Multi-stage Build — ssds-api（正式版）

```dockerfile
# ai-products-selection-backend/Dockerfile
# ---- 第一階段：用專案的 Gradle Wrapper 編譯 ----
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /src
COPY gradlew settings.gradle build.gradle ./
COPY gradle ./gradle
COPY ssds-api/build.gradle ssds-api/
COPY ssds-core/build.gradle ssds-core/
COPY ssds-ai/build.gradle ssds-ai/
COPY ssds-ingest/build.gradle ssds-ingest/
COPY ssds-calibration/build.gradle ssds-calibration/
COPY ssds-infra/build.gradle ssds-infra/
RUN chmod +x gradlew && ./gradlew --no-daemon :ssds-api:dependencies > /dev/null
COPY . .
RUN ./gradlew --no-daemon :ssds-api:bootJar -x test

# ---- 第二階段：只留 JRE 跟 ssds.jar ----
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app \
 && mkdir -p /app/uploads && chown -R app:app /app
COPY --from=build /src/ssds-api/build/libs/ssds.jar app.jar
USER app
ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

<!--
這頁是整章的重頭戲，也是大家要放進專案根目錄的 Dockerfile。

先看第一階段。為什麼用 eclipse-temurin:21-jdk-alpine，而不是官方的 gradle image？因為我們專案用的是 Gradle 9.5.1（寫在 gradle-wrapper.properties），gradle 官方 image 的版本不見得剛好一樣。用 JDK image 加上專案自己的 ./gradlew，wrapper 會自動下載「專案指定」的 Gradle 版本，跟大家本機一模一樣。JDK 21 也剛好符合 build.gradle 裡 toolchain 的 21，Gradle 不用另外下載 JDK。

`chmod +x gradlew` 是保險：從 Windows 送進來的檔案有時候沒有執行權限，會出現 Permission denied。

⚠️ 另一個 Windows 常見坑：gradlew 如果被 Git 轉成 CRLF 換行，Linux 會報 `/bin/sh^M: bad interpreter`。我們專案的 .gitattributes 已經寫了 `/gradlew text eol=lf`，所以不會有這個問題，這也是那一行存在的原因。

第二階段：jre 不是 jdk，我們只要「跑」jar。COPY --from=build 把第一階段產出的 ssds.jar 撈過來——檔名固定是 ssds.jar，因為 ssds-api/build.gradle 裡寫了 archiveFileName = 'ssds.jar'，所以這裡不用萬用字元，也不怕複製到 plain jar。

大家想一下差別有多大：第一階段的容器裡有 JDK、有 Gradle、有整個 ~/.gradle 的依賴快取、有全部原始碼，加起來超過 1GB。這些東西對「執行」一點用都沒有，全部被丟掉了。最終 image 只有 Alpine + JRE + 一支 100MB 的 jar，`docker images` 顯示約 480MB（壓縮後約 170MB）。

⚠️ 第一次 build 要等比較久（下載 Gradle、所有依賴、編譯六個模組），大概 3 到 6 分鐘，這是正常的。第二次只改 Java 的話，依賴那層會顯示 CACHED。
-->

---
zoom: 0.95
---

# Multi-stage Build — ssds-web（正式版）

```dockerfile
# ai-products-selection-frontend/Dockerfile
# ---- 第一階段：用 Node 編譯 Angular ----
FROM node:22-alpine AS build
# npm run generate:api 用的 openapi-generator 是 Java 程式，build 階段要有 JRE
RUN apk add --no-cache openjdk21-jre-headless
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run generate:api && npx ng build --configuration production

# ---- 第二階段：只留 nginx 跟靜態檔 ----
FROM nginx:1.28-alpine
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /src/dist/ai-products-selection-frontend/browser /usr/share/nginx/html
ENV API_URL=http://host.docker.internal:8080
EXPOSE 80
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>成果：</b> 建構階段含 <code>node_modules</code> 超過 <b>1GB</b>，最終 image 只有 nginx 加約 2MB 的靜態檔，<b>約 95MB</b>（壓縮後約 26MB）。
</div>

<!--
前端這份比後端更能感受到 multi-stage 的價值，但我們專案有一個特別的坑，要先講。

大家專案的 src/app/api 資料夾是用 openapi-generator 從 openapi.json 產生的，而且被 .gitignore 排除了——所以 GitHub 上、Docker 建構上下文裡，都「沒有」這個資料夾。如果直接 ng build，會看到一大堆 `Could not resolve "../../api"` 的錯誤。解法是 build 前先跑 `npm run generate:api`。但 openapi-generator-cli 雖然是用 npm 裝的，底層其實是一支 Java 程式，node:22-alpine 裡沒有 Java，所以要先 `apk add openjdk21-jre-headless`。這就是「build 需要什麼工具，就要在 build 階段裝什麼」的真實案例。反正第一階段最後會被丟掉，裝 JRE 不會讓最終 image 變大。

為什麼是 node:22？Angular 21 要求 Node 20.19 以上或 22.12 以上，22 是目前的 LTS。

`npm ci` 不是 `npm install`：ci 會嚴格照著 package-lock.json 安裝，版本完全鎖定，這正是我們要的可重現建構。專案用的是 npm（有 package-lock.json），不是 pnpm。

第二階段換成 nginx，只把 dist 底下的產出物複製到 nginx 的預設網站根目錄。

⚠️ dist 路徑要注意：Angular 17 之後預設輸出到 `dist/<專案名>/browser`，我們專案名稱是 ai-products-selection-frontend（angular.json 裡定義的）。路徑寫錯的話 build 會過，但容器跑起來打開網頁是 nginx 的預設歡迎頁。

nginx 設定檔跟 API_URL 這個環境變數是做什麼的？簡單講：瀏覽器打 /api/v1/... 的時候，nginx 幫忙轉給後端。預設的 host.docker.internal 代表「跑 Docker 的這台電腦」，所以本機用 8080 跑著 ssds-api 就能接上。第六章會完整拆解，第九章部署到雲端時只要改這個環境變數就好。
-->

---
zoom: 0.97
---

# 前端的 nginx 設定檔（先照抄，第六章詳解）

```nginx
# ai-products-selection-frontend/nginx/default.conf.template
server {
    listen       80;
    server_name  _;
    root         /usr/share/nginx/html;
    index        index.html;

    # Angular 前端路由：找不到的路徑一律回 index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # /api 開頭的請求轉給後端；${API_URL} 會在容器啟動時被換成環境變數的值
    location /api/ {
        proxy_pass ${API_URL};
        proxy_ssl_server_name on;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 50m;
        proxy_read_timeout   120s;
    }
}
```

<!--
這份設定檔請先照抄，放在前端專案的 nginx 資料夾下，檔名結尾是 .template。

為什麼是 .template？nginx 官方 image 有一個貼心功能：容器啟動時，會把 /etc/nginx/templates 底下的 .template 檔，用 envsubst 把 ${變數} 換成環境變數的值，再輸出到 conf.d 生效。所以我們可以用同一個 image，在本機、Compose、雲端分別把 API_URL 設成不同值。像 $uri、$scheme 這種 nginx 自己的變數不會被換掉，因為它只替換「真的存在的環境變數」。

`location /` 那段是 Angular 路由的必要設定：使用者直接打開 /products/123 這種前端路由網址，伺服器上並沒有這個檔案，要回 index.html 讓 Angular Router 接手，否則重新整理就 404。

`location /api/` 那段是反向代理：我們專案 production 環境的 environment.prod.ts 裡，apiBaseUrl 寫的是相對路徑 `/api/v1`，所以瀏覽器會把 API 請求送回「網頁自己的網域」，由 nginx 轉給後端。好處是瀏覽器眼中前後端同一個網域，完全不會有 CORS 問題——這點非常重要，因為後端 SecurityConfig 裡的 CORS 白名單目前只寫了 localhost:4200。

client_max_body_size 50m 是因為專案的 Excel 匯入功能上限 50MB，nginx 預設只收 1MB；proxy_read_timeout 拉長是因為 AI 分析的 API 可能比較慢。

⚠️ proxy_ssl_server_name on 這行本機用不到，第九章雲端的後端網址是 https，少了這行 TLS 握手會失敗。
-->

---
zoom: 0.94
---

# 什麼是 .dockerignore？

「.dockerignore 用來排除不需要送進建構上下文的檔案，讓上下文更乾淨、build 更快。」

| 項目 | 說明 |
| --- | --- |
| 用途 | 排除不需要送進建構上下文的檔案或目錄 |
| 語法 | 跟 `.gitignore` 的排除模式類似 |
| 放置位置 | 與 Dockerfile 同一目錄（專案根目錄） |
| 效益 | 縮小建構上下文、**避免 `.env` 被打包**、加快 build 速度 |

```plaintext
# ai-products-selection-backend/.dockerignore    # ai-products-selection-frontend/.dockerignore
.git                                             .git
.gradle                                          node_modules
**/build                                         dist
.idea                                            .angular
uploads                                          src/app/api
.env                                             .env*
*.md                                             *.md
```

<!--
.dockerignore 這個檔案的用法，跟大家熟悉的 .gitignore 幾乎一模一樣，寫法也是每行一個排除規則。

它解決的問題是：docker build 執行時，會把當前目錄整個打包成「建構上下文」送給建構程序。SSDS 兩個專案都有很痛的例子——前端的 node_modules 超過 1GB，後端的 .gradle 快取跟各模組的 build 目錄也是幾百 MB，這些全部都會被送進去，光是「送」就要等好幾十秒，而且送進去之後第一階段還會用 npm ci / gradlew 重做一次，完全是白費工。前端還要排除 src/app/api，確保每次都用 openapi.json 重新產生，不會混到舊檔。

資安面更要小心。後端專案根目錄的 .env 放著 Supabase 密碼、Mistral API key、Apify token。後端 Dockerfile 第一階段寫的是 `COPY . .`，如果沒排除，.env 就會被複製進建構階段；更糟的是，如果有人在第二階段也寫了 COPY . .，.env 就進了最終 image。image 會被 push 到 Docker Hub，任何人 pull 下來都能翻出來看。

⚠️ 注意 `**/build`：兩顆星代表任何深度的 build 資料夾，我們六個子模組各有一個，只寫 build 只會排除根目錄那個。

⚠️ 易錯點：.dockerignore 一定要跟 Dockerfile 放在建構上下文的根目錄，放錯位置等於沒寫。
-->

---
layout: default
---

# 練習 1：修好 ssds-api 的 Dockerfile 快取
### 任務說明

組員寫的這份 Dockerfile 可以動，但每次改一行 Java 就要重抓 Gradle 和所有依賴，build 一次要五分鐘：

```dockerfile
FROM eclipse-temurin:21-jdk-alpine
WORKDIR /src
COPY . .
RUN ./gradlew --no-daemon :ssds-api:bootJar -x test
EXPOSE 8080
CMD ["java", "-jar", "ssds-api/build/libs/ssds.jar"]
```

任務：

1. 改成 multi-stage，最終 image 用 `eclipse-temurin:21-jre-alpine`，並以非 root 使用者執行
2. 調整順序，讓「只改 Java、沒改任何 build.gradle」時，依賴下載那層吃到 layer cache
3. 補上 `.dockerignore`，確認 `.env` 不會進建構上下文
4. 實測：`docker build -t ssds-api:1.0.0 .` 兩次，第二次前隨便改一行 Controller，觀察哪幾步顯示 `CACHED`

---
layout: default
---

# 練習 1：解題提示
### 提示說明

1. 先問自己：`build.gradle` 跟 `src/` 底下的 Java 檔，哪個改動頻率低？
2. 多模組專案，Gradle 解析依賴需要：`gradlew`、`gradle/` 目錄（含 `libs.versions.toml`）、根目錄的 `settings.gradle` + `build.gradle`、**六個子模組各自的 `build.gradle`**
3. 接著 `RUN ./gradlew --no-daemon :ssds-api:dependencies` 把依賴鎖成獨立一層
4. 最後才 `COPY . .` 並執行 `bootJar`；第二階段 `COPY --from=build /src/ssds-api/build/libs/ssds.jar app.jar`
5. 驗證 `.env` 沒進去：`docker run --rm --entrypoint ls ssds-api:1.0.0 -la /app`

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>常見錯誤：</b> 漏了某個子模組的 <code>build.gradle</code>，依賴那層會失敗或抓不完整；漏了 <code>gradle/</code> 目錄則會出現 <code>Could not find or load main class org.gradle.wrapper.GradleWrapperMain</code>。
</div>

---
layout: default
---

# 練習 2：把 ssds-web 包成 Image
### 任務說明

在 `ai-products-selection-frontend/` 下，組員寫了第一版 Dockerfile，但一 build 就失敗：

```dockerfile
FROM node:22-alpine
WORKDIR /app
COPY . .
RUN npm install
RUN npx ng build
```

```plaintext
X [ERROR] Could not resolve "../../api"
    src/app/features/trends/trends.component.ts:2:55
```

任務：

1. 找出錯誤原因並修好（提示：看一下 `.gitignore` 和 `package.json` 的 scripts）
2. 改寫成 multi-stage：第二階段用 `nginx:1.28-alpine`，加上 `nginx/default.conf.template`
3. 把 `npm install` 換成 `npm ci`，並調整順序讓依賴安裝能吃快取
4. 新增 `.dockerignore`，並驗證：`docker images` 看大小、進容器確認沒有 `.ts` 原始碼

---
layout: default
---

# 練習 2：解題提示
### 提示說明

1. `src/app/api` 被 `.gitignore` 排除，是 `npm run generate:api` 產生的；而 openapi-generator 需要 **Java** → build 階段 `apk add --no-cache openjdk21-jre-headless`
2. 依賴快取：先 `COPY package.json package-lock.json ./` → `RUN npm ci` → 再 `COPY . .`
3. 輸出路徑看 `angular.json`：`dist/ai-products-selection-frontend/browser`

```bash
docker build -t ssds-web:1.0.0 .
docker run -d --name ssds-web -p 8000:80 ssds-web:1.0.0
docker exec ssds-web ls /usr/share/nginx/html          # 只有 index.html 與雜湊檔名的 js/css
docker exec ssds-web cat /etc/nginx/conf.d/default.conf  # ${API_URL} 已被換成實際網址
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>端到端驗證：</b> 本機 8080 跑著 <code>ssds-api</code> 容器時，打開 <code>http://localhost:8000</code> 登入，畫面能載入資料，就代表 web → nginx 反向代理 → api → Supabase 整條通了。
</div>

<!--
這兩題練習的講稿放在這裡一起講。

練習一是快取排序加 multi-stage，重點是讓大家自己動手體會「順序改一下，build 時間從五分鐘變幾十秒」。請務必真的 build 兩次比較，光看投影片沒有感覺。多模組專案最容易漏的就是子模組的 build.gradle，這題故意讓大家踩一次。

練習二是這章的驗收題，而且第一步是一個真實的除錯情境：build 失敗、錯誤訊息看起來像是程式碼有問題，其實是「建構環境少了一個步驟」。大家平常在本機開發，src/app/api 早就產生過了所以沒感覺；換到一個乾淨的環境（Docker、CI、雲端平台）才會現形。這就是容器化最大的價值之一：逼我們把「隱含的建構步驟」全部寫清楚。

⚠️ 第 4 步的驗證一定要做。很多人以為「我沒有 COPY .env 就沒事」，但只要寫了 COPY . . 而 .dockerignore 沒排除，機密就進建構上下文了。

做完之後，大家手上應該有兩個 image：ssds-api:1.0.0 跟 ssds-web:1.0.0。請把兩份 Dockerfile、.dockerignore、nginx 設定檔都 commit 進各自的 repo，第九章雲端平台會直接從 GitHub 讀這些檔案來 build。
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
<thead>
<tr><th>主題</th><th>重點回顧</th></tr>
</thead>
<tbody>
<tr><td>常用指令</td><td><code>FROM</code>、<code>COPY</code>、<code>RUN</code>、<code>CMD</code>、<code>ENTRYPOINT</code>、<code>EXPOSE</code>、<code>ENV</code>，各司其職</td></tr>
<tr><td>健康檢查</td><td>加 Actuator，路徑是 <code>/api/v1/actuator/health</code>（受 context-path 影響）</td></tr>
<tr><td>Layer Cache</td><td>先 COPY 所有 build.gradle / package-lock.json 裝依賴，再 COPY 原始碼</td></tr>
<tr><td>ssds-api</td><td>JDK + gradlew 編譯 → JRE + <code>ssds.jar</code>，非 root 執行，約 480MB</td></tr>
<tr><td>ssds-web</td><td>Node（+ JRE 跑 generate:api）編譯 → nginx + 靜態檔，約 95MB</td></tr>
<tr><td>.dockerignore</td><td>排除 <code>node_modules</code>、<code>**/build</code>，<b>一定要排除 <code>.env</code></b></td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入 Docker Compose，用一份 YAML 一次 build、啟動 ssds-api 與 ssds-web。
</div>

<!--
今天這一章的內容比較扎實，我們快速複習一下。

我們學了 Dockerfile 最核心的幾個指令，也搞懂了 CMD 跟 ENTRYPOINT 的差異。接著理解了 docker build 背後的 layer 跟快取機制，知道多模組專案要把每個子模組的 build.gradle 都先複製進去。最後用 multi-stage build 寫出了前後端的正式 Dockerfile，並且用 .dockerignore 確保 .env 不會外洩。

⚠️ 這章做完的檔案非常重要，請確認都 commit 了：
- 後端：Dockerfile、.dockerignore、ssds-api/build.gradle 的 actuator
- 前端：Dockerfile、.dockerignore、nginx/default.conf.template

下一章我們會進入 Docker Compose，把兩個 container 組合起來一起管理，我們下堂課見。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
現在開放 Q&A 時間。

大家對 Dockerfile 常用指令、Layer Cache 機制，或是 Multi-stage Build，有沒有什麼疑問？都歡迎提出來討論。

如果自己專案 build 失敗，先看錯誤是在哪一個階段、哪一行 RUN，再對照今天講的幾個坑：gradlew 權限、少了子模組的 build.gradle、少了 generate:api、dist 路徑寫錯。
-->
