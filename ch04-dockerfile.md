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
歡迎來到第四章，Dockerfile。

前面幾章用的 Image 都是別人做好的。如果我們想把 TaskBoard 的後端和前端，打包成自己的 Image，就要靠 Dockerfile。

我們可以把 Dockerfile 想成一份寫下來的食譜，`docker build` 照著做，任何人在任何地方都會做出同一個 Image。

學完這一章，我們就能為 TaskBoard 前後端各寫一份精簡又安全的 Dockerfile。
-->

---
layout: default
---

# Outline

<div class="text-left" style="font-size: 1.05rem; line-height: 2.2;">

- **Dockerfile 常用指令** — FROM / COPY / RUN / CMD / ENTRYPOINT / EXPOSE / ENV
- **docker build 與 Layer Cache** — 建構流程、快取命中與失效
- **Multi-stage Build 與 .dockerignore** — 縮小映像檔、排除無關檔案
- **練習題** — 從一份 Dockerfile 到最佳化
- **總結**

</div>

<!--
這一章分成三部分。第一部分是 Dockerfile 最常用的幾個指令。第二部分看 `docker build` 怎麼運作，以及會直接影響 build 速度的 Layer Cache。第三部分是兩個進階技巧，Multi-stage Build 讓 Image 變小，.dockerignore 避免把不需要的檔案送進去。最後有兩題練習。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Dockerfile 常用指令

<!--
我們先從第一部分開始，看看 Dockerfile 裡最常見的幾個指令，它們幾乎每份 Dockerfile 都會用到。
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
「Dockerfile 是食譜的文字版」，一行一行寫著怎麼組出一個 Image。

先看最簡單的版本，把 Gradle 打包好的 jar 放進 Image 跑起來。FROM 選了只有 JRE 21 的輕量 Image 當基礎，COPY 把 jar 複製進去，CMD 指定容器啟動時執行 `java -jar`。

下面兩行是使用方式。先在本機用 Gradle 打包出 jar，再用 `docker build` 包成 Image。

這個做法最好懂，但有一個缺點。它假設每個要 build 的人，電腦上都裝好 JDK 21 和 Gradle。CI 伺服器不一定有，同事的版本也不一定對。這個問題，我們第三部分用 Multi-stage Build 解決。

另外，檔名預設就叫 Dockerfile，沒有副檔名。用其他檔名的話，要用 `-f` 指定。
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

<!--
這張表整理了七個最常用的指令，我們挑重點看。

FROM 指定基礎 Image，是每份 Dockerfile 的第一行。COPY 把檔案從我們的電腦複製進 Image。RUN 是在 build 的過程中執行指令，例如安裝套件。

CMD 和 ENTRYPOINT 都跟容器啟動時要執行什麼有關，它們的差別等一下會專門講。

要特別注意 EXPOSE，它只是說明容器會用到哪個 port，並不會真的對外開放。真正開放 port，還是要靠 `docker run` 的 `-p`。

ENV 則是設定環境變數，build 和容器執行時都會生效。
-->

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
這一頁把七個指令放在一起，寫一份比較完整的 `taskboard-api` Dockerfile。

先看第二個 ENV，`SPRING_PROFILES_ACTIVE=prod`。它讓 Image 預設啟用 prod 的設定檔。因為只是預設值，`docker run` 時加 `-e` 就能蓋掉，同一個 Image 可以用在不同環境。

再看 RUN 建立使用者，加上後面的 USER app。容器裡的程式預設是用 root 執行的，萬一應用程式被攻破，攻擊者在容器裡就是 root。改用沒有特權的使用者執行 java，風險會小很多，正式環境幾乎一定會要求這樣做。

最後是 ENTRYPOINT 加 CMD 的組合。意思是這個容器固定用來跑這支 jar，但啟動參數可以換。所以 run 的時候在後面加 `--server.port=9090`，服務就會改用 9090 啟動。

另外，ENV 一律寫成有等號的形式，沒有等號的舊寫法官方已經不建議使用。
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
這一頁是很多人剛學 Dockerfile 時最容易搞混的地方。

「ENTRYPOINT 決定容器是什麼，CMD 決定容器預設帶什麼參數執行。」

用食譜來比喻，ENTRYPOINT 是菜名，例如「炒飯」，這道菜做什麼是固定的。CMD 是預設的配料，例如「加蛋」，客人點餐時可以臨時換成加肉。

拉回技術。如果只有 CMD，`docker run` 後面加的參數會整個取代 CMD。如果同時有 ENTRYPOINT 和 CMD，後面加的參數只會取代 CMD，ENTRYPOINT 不會被換掉。

最後一列要特別小心。ENTRYPOINT 如果沒有用中括號，寫成殼層式，它會忽略 CMD 和 run 時傳入的參數，行為完全不同。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# docker build 與 Layer Cache

<!--
指令會寫了，接下來看第二部分：`docker build` 背後做了什麼，以及會直接影響 build 速度的 Layer Cache。
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
「docker build 會把 Dockerfile 逐行讀進去，每一行變成一個 layer」，疊起來就是最終的 Image。

先看第一行。`-t` 幫 Image 取名字加版本，最後那個點代表建構上下文，也就是 Docker 會把目前目錄的檔案送給建構程序使用。

這個點很重要。如果我們在錯的目錄執行 build，jar 檔根本沒被送進上下文，Dockerfile 裡的 COPY 就會找不到檔案。

第二行示範用 `-f` 指定不同檔名的 Dockerfile，一個 repo 放多個服務時很常見。

另外，Docker 23.0 之後，build 預設使用 BuildKit 引擎，不用再手動開啟。它的速度和快取處理都比舊版好。
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

<!--
「Layer cache 就像料理時已經切好的菜」，只要食材沒變，下次做菜就不用重新切，直接拿來用。

拉回技術。Dockerfile 每一行執行後的結果，就是一個 layer。重新 build 時，如果這一行和它用到的檔案都沒變，Docker 會直接重用舊的 layer，這叫快取命中。

最關鍵的是第四列，由上而下比對。只要某一行失效，它後面的每一行都會跟著重新執行，不管後面那些行本身有沒有變。

最後一列是個隱蔽的坑。`apt-get update` 和 `apt-get install` 要寫在同一條 RUN 裡。分開寫的話，update 那層會被快取住，之後可能悄悄裝到舊版的套件，而且 build 不會報錯。
-->

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
這一頁是整章對日常工作影響最大的一頁。

先看錯誤示範。`COPY . .` 把整個專案都複製進去，包含所有 Java 檔。我們只要改一行 Controller，這一層就失效，後面的 gradlew 整條重跑，重新下載 Spring Boot 那一大包依賴。

正確示範的思路，是把很少變的和一直變的分開。build.gradle 可能兩週才改一次，src 底下的檔案一天改二十次。所以先只複製 Gradle 的設定檔，跑 dependencies 把依賴鎖在一層。接著才複製 src，執行 bootJar。

這樣只要沒動 build.gradle，依賴那層永遠命中快取。下面寫的差距是，從一兩分鐘縮短到十幾秒，而這每天會發生好幾十次。

另外注意 `--no-daemon`。容器裡的 build 是一次性的，Gradle 留下背景 daemon 沒有意義，所以在 Dockerfile 裡一律加上。
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
這一頁把剛才的觀念整理成原則。

「把常變動的指令放後面，把穩定不變的指令放前面，快取效益才會最大。」

TaskBoard 的前後端剛好是同一個模式。後端的 build.gradle 對應前端的 package.json，都是很少改的依賴清單。後端的 Java 原始碼對應前端的 TypeScript，都是天天改的。所以順序都一樣，先複製清單、安裝依賴，再複製原始碼、編譯。

至於 `--no-cache`，會強制忽略所有快取，從頭跑一次。通常用在懷疑快取有問題的時候，例如明明改了設定卻沒生效，或是 CI 要確保完全乾淨的建構。平常開發不要加，加了就完全沒有加速效果。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Multi-stage Build 與 .dockerignore

<!--
第三部分，我們來看兩個讓 Image 更精簡、更乾淨的技巧，Multi-stage Build 和 .dockerignore。
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
之前的 Dockerfile 都只有一個 FROM。編譯工具、原始碼和最後的成品，全部疊在同一個 Image 裡，裡面塞滿了 build 完就用不到的東西。

「Multi-stage build，一份 Dockerfile 包含多個建構階段，只把需要的成品搬進最終 image。」

延續食譜的比喻，前面的階段負責在廚房做菜，最後一個階段負責裝盤。端給客人的只有做好的菜，廚房裡的鍋碗瓢盆不會一起端出去。

語法上，`FROM` 後面加 `AS` 幫階段取名字，再用 `COPY --from` 從那個階段把檔案拿過來。

如果想檢查中間階段的內容，可以用 `--target` 指定只 build 到那個階段。
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
這一頁是整章的重點，也是之後會直接放進專案裡用的 Dockerfile。

第一階段用 `gradle:8.10-jdk21`，裡面有完整的 JDK 和 Gradle，所以編譯整個搬進容器裡做。不管誰的電腦或 CI 伺服器，只要有 Docker 就能 build，不用再擔心本機的 JDK 版本。中間幾行就是剛才講的快取排序。

第二階段是關鍵。重新從 `eclipse-temurin:21-jre-alpine` 開始，注意是 jre 不是 jdk，我們只需要執行，不需要編譯器。再用 `COPY --from=build` 把第一階段產出的 jar 拿過來。

結果是，第一階段將近 1GB 的 JDK、Gradle、依賴快取和原始碼，全部留在原地。最終 Image 只有大約 200MB。Image 越小，push、pull、部署都越快，裡面沒有編譯器和原始碼，也更安全。

要注意 `*.jar` 這個寫法，前提是 build 目錄底下只有一支 jar。如果 Gradle 也產出了 plain jar，要在 build.gradle 把它關掉，不然可能複製到錯的那支。
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
前端比後端更能感受到 Multi-stage 的價值。

Angular 專案的 node_modules 動輒幾百 MB 到 1GB。但這些只有編譯時需要，編譯完就是一堆 HTML、CSS、JS 靜態檔，執行時完全用不到 Node。

所以第一階段用 node 執行 `npm ci` 和 `npm run build`，第二階段直接換成 nginx，只把 dist 底下的產出物複製到 nginx 的網站目錄。最終 Image 大約 50MB，裡面連 Node 都沒有。

注意這裡用的是 `npm ci`，不是 `npm install`。ci 會嚴格照著 lock 檔安裝，版本完全固定，每次 build 結果都一樣。容器建構一律用 ci。

另外 dist 路徑有版本差異，Angular 17 之後多了一層 browser。路徑寫錯的話，build 會成功，但打開網頁只會看到 nginx 的預設頁面。
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

<!--
最後一個技巧是 .dockerignore。

「.dockerignore 用來排除不需要送進建構上下文的檔案」，寫法跟大家熟悉的 .gitignore 幾乎一樣。

為什麼需要它？前面說過，`docker build` 會把整個目錄送進建構上下文。TaskBoard 前端的 node_modules 動輒 1GB，後端的 .gradle 和 build 目錄也有幾百 MB。這些全部送進去，光是傳送就要等好幾十秒，而且進去之後，第一階段還會重新安裝一次，完全白費。

表格的最後一列也很重要，它還能避免機密檔案被打包進去，下一頁的範例會看到。
-->

---

# .dockerignore — 範例

TaskBoard 前後端各放一份，與各自的 Dockerfile 同一層：

<div class="grid grid-cols-2 gap-6">

<div>

```plaintext
# taskboard-api/.dockerignore
.git
.gradle/
build/
*.md
src/main/resources/application-local.yml
```

</div>

<div>

```plaintext
# taskboard-web/.dockerignore
.git
node_modules/
dist/
.env*
```

</div>

</div>

<!--
TaskBoard 的前後端各放一份 .dockerignore，跟各自的 Dockerfile 在同一層。

左邊是後端，排除 Gradle 的快取和 build 目錄，還有 `application-local.yml`，這個檔案常常放著本機資料庫的密碼。右邊是前端，排除 node_modules、dist，以及 `.env` 開頭的檔案，裡面常有 API key。

這些機密絕對不能進 Image。Image 會被 push 到 Registry，任何人拉下來都能翻出來看。

要特別提醒，.dockerignore 決定的是哪些檔案會送進建構上下文。如果 Dockerfile 寫了 `COPY . .`，有沒有排除 `.env`，就直接決定機密會不會被打包進 Image。
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

<!--
接下來是練習一，修好 taskboard-api 的 Dockerfile。

同事寫的這份可以動，但每改一行 Java，就要重新下載所有依賴，build 一次要一分半。任務是調整指令順序，讓只改 src 的時候，依賴那層能吃到快取，並且實際 build 兩次，觀察哪幾步出現 CACHED。

請大家先想一個問題：這份 Dockerfile 裡，哪一行讓快取整個失效了？

我們先暫停一下，自己動手試試看。

【講師】給大家五到八分鐘，提醒一定要真的 build 兩次比較時間。
-->

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

<!--
我們來看解題的關鍵。

回答剛才的問題，是 `COPY . .` 這一行。它把原始碼和建構檔一起複製，只要改了任何一個 Java 檔，這層就失效，後面的下載依賴全部重跑。

解法就是把改動頻率低的先複製。Gradle 需要的是四樣東西，gradlew、settings.gradle、build.gradle，以及 gradle 目錄。先用它們跑 dependencies，最後才複製 src 執行 bootJar。

下面的常見錯誤，很多人都會犯。只複製了 build.gradle，卻忘了 gradle 目錄。gradlew 只是一個腳本，真正的執行邏輯在 wrapper 的 jar 檔裡，少了它 build 就會失敗。
-->

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

<!--
練習二是這一章的驗收題，把 taskboard-web 改成 Multi-stage。

先看目前的狀況。這份 Dockerfile 用 node 一路做到底，建出來的 Image 有 1.2GB，而且裡面看得到完整的原始碼和 `.env`。

請大家先想一想：這個 Image 裡，哪些東西是執行時根本用不到的？

下一頁是具體的任務要求。
-->

---
layout: default
---

# 練習 2：把 taskboard-web 改成 Multi-stage
### 任務要求

1. 改寫成 multi-stage：第一階段用 Node 編譯，第二階段換成 `nginx:1.27-alpine`，只複製 `dist/taskboard-web/browser` 的產出物
2. 把 `npm install` 換成 `npm ci`，並調整順序讓依賴安裝能吃快取
3. 新增 `.dockerignore`，確保 `node_modules`、`dist`、`.env` 不會被送進建構上下文
4. 驗證：`docker images` 比較改寫前後的大小，並進容器確認裡面沒有 `.ts` 原始碼與 `.env`

<!--
任務有四步。第一，改寫成 Multi-stage，第一階段用 Node 編譯，第二階段換成 nginx，只複製 dist 底下的產出物。第二，把 `npm install` 換成 `npm ci`，並調整順序吃快取。第三，加上 .dockerignore。第四，比較改寫前後的大小，並進容器確認沒有原始碼和 `.env`。

這題把 Multi-stage、npm ci 和 .dockerignore 三個技巧結合在一起。

我們先暫停一下，自己動手試試看。

【講師】給大家十分鐘左右，提醒第四步的驗證一定要做。
-->

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
我們來看解答。

回答剛才的問題。執行時用不到的，包括 Node 本身、整個 node_modules、TypeScript 原始碼，還有 `.env`。所以第一階段負責編譯，第二階段從 nginx 重新開始，只把編譯好的靜態檔複製過去。

很多人會以為用了 Multi-stage 就安全了。但如果 .dockerignore 沒排除 `.env`，第一階段的 `COPY . .` 還是會把它讀進去，只要哪個階段不小心複製到，就會外洩。所以這兩個技巧要一起用。

最後進容器檢查，應該找不到任何 ts 檔，Image 也從 1.2GB 降到大約 50MB。
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
<tr><td>ENV 語法</td><td>現行一律用 <code>ENV KEY=VALUE</code>，不用舊式空格寫法</td></tr>
<tr><td>docker build</td><td>讀 Dockerfile 逐行執行，每行變成一個 layer；Docker 23.0+ 預設用 BuildKit</td></tr>
<tr><td>Layer Cache</td><td>順序決定快取效益，常變動的指令放後面</td></tr>
<tr><td>Multi-stage Build</td><td>用多個 <code>FROM</code> 階段，只把需要的成品搬進最終 image</td></tr>
<tr><td>.dockerignore</td><td>排除不需要的檔案，避免機密外洩、加快 build</td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b> 我們將進入 Docker Compose，學習用一份 YAML 檔案一次定義、啟動多個服務。
</div>

<!--
我們回顧一下這一章。

第一，Dockerfile 用幾個常用指令把組 Image 的步驟寫下來，ENTRYPOINT 決定跑什麼，CMD 決定預設參數。第二，`docker build` 每一行產生一個 layer。第三，Layer Cache 由上而下比對，常變動的指令要放後面。第四，Multi-stage Build 只把成品搬進最終 Image。最後，.dockerignore 讓 build 更快，也避免機密外洩。

下一章，我們要用 Docker Compose，把 TaskBoard 的三個服務一次啟動。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
這一章我們親手為 TaskBoard 寫出了前後端的 Dockerfile，也學會讓 build 更快、Image 更小、更安全。

建議大家自己動手寫一份 Dockerfile 並 build 一次，實際做過一次，比看投影片有用得多。我們下一章見。

【講師】開放 Q&A，可以引導大家回想 CMD 和 ENTRYPOINT 的差別、快取順序的原則。
-->
