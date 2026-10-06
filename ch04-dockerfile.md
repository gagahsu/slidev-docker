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
    「以程式碼定義 Image，讓建置可重複、可驗證」
  </p>
  <Link to="home" style="margin-top: 2rem; color: #5eada0; font-size: 0.9rem;">← 返回目錄</Link>
</div>

<!--
【開場白】
本章主題是 Dockerfile。前幾章使用的 Image 皆由他人建立；若要建立自己的 Image，必須撰寫 Dockerfile。

【概念定義】
Dockerfile 是以文字逐行描述建置步驟的檔案：使用哪個基礎環境、複製哪些檔案、執行哪些指令。docker build 依照 Dockerfile 執行，即可重複產生相同的 Image。

【學習目標】
- 熟悉 Dockerfile 常用指令
- 理解 docker build 與 layer cache 的運作
- 以 multi-stage build 與 .dockerignore 撰寫 ssds-api、ssds-web 的正式 Dockerfile
-->

---
layout: default
---

# Outline

- **Dockerfile 常用指令**
  - FROM / COPY / RUN / CMD / ENTRYPOINT / EXPOSE / ENV
- **docker build 與 Layer Cache**
  - 建置流程、快取命中與失效、多模組專案的寫法
- **Multi-stage Build 與 .dockerignore**
  - `ssds-api`、`ssds-web` 的正式 Dockerfile
- **實作練習**

<!--
【帶讀大綱】
本章分為三個部分：第一部分介紹 Dockerfile 常用指令；第二部分說明 docker build 的運作與 layer cache，SSDS 後端為 Gradle 多模組專案，快取寫法需特別處理；第三部分以 multi-stage build 與 .dockerignore 完成兩份正式 Dockerfile。

【重點預告】
本章產出的兩份 Dockerfile，第五章 Compose 與第九章雲端部署皆會沿用。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Dockerfile 常用指令

<!--
【段落轉換】
第一部分介紹 Dockerfile 中最常用的指令，這些指令幾乎出現在每一份 Dockerfile 中。
-->

---

# 什麼是 Dockerfile？

**Dockerfile** 是描述 Image 建置步驟的純文字檔，`docker build` 依其內容逐行執行並產生 Image。

最基本的版本：將第三章本機打包的 `ssds.jar` 放入 Image 中執行。

```dockerfile
# ai-products-selection-backend/Dockerfile（第一版，後續改良）
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY ssds-api/build/libs/ssds.jar app.jar
EXPOSE 8080
CMD ["java", "-jar", "app.jar"]
```

```bash
./gradlew :ssds-api:bootJar -x test    # 本機打包 jar
docker build -t ssds-api:1.0.0 .       # 建置 Image
docker run -d --name ssds-api -p 8080:8080 --env-file .env ssds-api:1.0.0
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>注意：</b>Dockerfile 預設檔名為 <code>Dockerfile</code>（無副檔名），放在專案根目錄；如需使用其他檔名，以 <code>-f</code> 指定。
</div>

<!--
【帶讀關鍵行】
此 Dockerfile 將第三章的 docker run 參數固定於 Image 中：以僅含 JRE 21 的 Image 為基礎，設定工作目錄為 /app，複製 ssds.jar 並更名為 app.jar，宣告使用 8080 port，最後指定啟動時執行 java -jar。

【回顧】
第三章需以 -v 掛載 jar、以 -w 設定工作目錄、自行輸入 java -jar；改用 Dockerfile 後，docker run 只需指定 port 與 --env-file。

【重點提醒】
--env-file 仍須在執行時提供。機密值不寫入 Image，只在執行時注入，此原則於第八、九章持續沿用。

【易錯點提醒 ⚠️】
此版本假設建置者的電腦已安裝 JDK 21 並完成打包。第九章由雲端平台建置時，平台上沒有本機的 build 目錄。第三部分將以 multi-stage build 讓 Gradle 也在容器中執行，解決此問題。
-->

---

# Dockerfile 常用指令一覽

| 指令 | 用途 |
| --- | --- |
| `FROM` | 指定基礎 Image，開始一個新的建置階段 |
| `COPY` | 將建置上下文中的檔案或目錄複製進 Image |
| `RUN` | 建置過程中執行指令（例如安裝套件、編譯） |
| `CMD` | 指定容器啟動時的預設指令或參數 |
| `ENTRYPOINT` | 指定容器啟動時固定執行的程式 |
| `EXPOSE` | 宣告容器使用的 port（僅作說明，不會實際開放） |
| `ENV` | 設定環境變數，建置與執行階段皆有效 |
| `WORKDIR` / `USER` | 設定工作目錄 / 切換執行身分 |

<!--
【重點解說】
上表為撰寫 Dockerfile 最常用的指令，下一頁以完整範例示範其搭配方式。

【易錯點提醒 ⚠️】
EXPOSE 僅為文件性質的宣告，實際對外開放 port 仍須於 docker run 時以 -p 指定。
-->

---

# Dockerfile 常用指令 — 範例

使用上述指令撰寫較完整的 `ssds-api` Dockerfile：

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
💡 <b>ENV 語法：</b>使用 <code>ENV KEY=VALUE</code>。舊式 <code>ENV KEY VALUE</code>（無等號）已不建議使用。
</div>

<!--
【帶讀關鍵行】
- `ENV SPRING_PROFILES_ACTIVE=prod`：專案的 application.properties 為 `spring.profiles.active=${SPRING_PROFILES_ACTIVE:dev}`，未設定時預設為 dev，會開啟 show-sql 與 SQL 參數 trace，log 量大。Image 預設為 prod；本機需要查看 SQL 時，以 `-e SPRING_PROFILES_ACTIVE=dev` 覆蓋。
- `RUN addgroup / adduser` 與 `USER app`：容器內行程預設以 root 執行，應用程式若遭入侵，攻擊者即取得容器內的 root 權限。改以無特權使用者執行可降低風險。
- `mkdir -p /app/uploads && chown`：專案將商品圖片寫入 `./uploads/product`。切換為 app 使用者後，若 /app 仍屬於 root，寫入時會發生 Permission denied。因此須在切換身分前，以 root 建立目錄並變更擁有者。第七章掛載 Volume 時亦會使用此目錄。
- `ENTRYPOINT` + `CMD`：ENTRYPOINT 固定執行 jar，CMD 提供可覆蓋的預設參數。執行 `docker run ssds-api:1.0.0 --server.port=9090` 即以 9090 啟動，Spring Boot 會讀取此命令列參數。
-->

---

# CMD 與 ENTRYPOINT 的差異

`ENTRYPOINT` 決定容器執行的程式，`CMD` 提供預設參數。

| 情境 | 行為 |
| --- | --- |
| 只有 `CMD ["exec","p1"]` | 啟動時執行 `exec p1`；`docker run` 後的參數會取代整個 CMD |
| 只有 `ENTRYPOINT ["exec","p1"]` | 啟動時必定執行 `exec p1`，`docker run` 後的參數附加於後 |
| `ENTRYPOINT ["exec","p1"]` + `CMD ["p2"]` | 執行 `exec p1 p2`，`p2` 為可覆蓋的預設參數 |
| `ENTRYPOINT` 使用 shell 形式（無中括號） | 忽略 `CMD` 與 `docker run` 傳入的參數 |

<!--
【生活化比喻】
ENTRYPOINT 如同便當盒本身，用途固定；CMD 如同預設的菜色，點餐時可以更換。

【核心說明】
只有 CMD 時，docker run 後的參數會取代整個 CMD；同時有 ENTRYPOINT 與 CMD 時，docker run 後的參數只取代 CMD 部分，ENTRYPOINT 維持不變。

【易錯點提醒 ⚠️】
ENTRYPOINT 使用 shell 形式（無中括號）時，除了忽略 CMD 與執行時參數外，java 會成為 sh 的子行程，無法收到 docker stop 送出的 SIGTERM；Spring Boot 因此無法正常關閉，10 秒後被強制終止。應一律使用 exec 形式（中括號）。
-->

---

# 容器化前的準備：加入 Actuator 健康檢查

第五章 healthcheck 與第九章雲端平台，都需要可判斷服務狀態的端點：

```groovy
// ssds-api/build.gradle — dependencies 區塊加入
implementation 'org.springframework.boot:spring-boot-starter-actuator'
```

```bash
# 重新 bootRun 或 build 後
curl http://localhost:8080/api/v1/actuator/health
# {"status":"UP"}
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
⚠️ <b>路徑：</b>專案設定 <code>server.servlet.context-path=/api/v1</code>，actuator 亦位於 <code>/api/v1</code> 之下，<b>不是</b> <code>/actuator/health</code>。
</div>

<!--
【問題引導】
容器狀態為 Up 並不代表服務可用：Spring Boot 啟動需十數秒，期間 java 行程已存在但尚無法提供服務；也可能已啟動但無法連線 Supabase。Docker、Compose 與雲端平台都需要判斷服務是否就緒的方法。

【核心說明】
Actuator 的 /health 端點會實際檢查資料庫連線等元件，全部正常時才回傳 UP。只需加入一行相依套件，版本由 Spring Boot BOM 管理。專案 SecurityConfig 目前為全部 permitAll，不需另外開放權限。

【易錯點提醒 ⚠️】
專案 CONTEXT.md 規定 context-path 為 /api/v1，actuator 也位於此前綴下。第五章與第九章設定健康檢查路徑時必須寫成 /api/v1/actuator/health；路徑錯誤會導致平台持續判定服務異常並反覆重啟。

【預期結果】
重新啟動後呼叫此網址回傳 {"status":"UP"}。請將此修改 commit 至專案，後續各章皆會使用。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# docker build 與 Layer Cache

<!--
【段落轉換】
第二部分說明 docker build 的運作，以及影響建置效率的 layer cache（層快取）機制。
-->

---

# 什麼是 docker build？

`docker build` 依序執行 Dockerfile 的指令，每個會變更檔案系統的指令產生一個 layer，疊加組成最終的 Image。

```bash
# 在 ai-products-selection-backend/ 目錄下執行
docker build -t ssds-api:1.0.0 .

# 在上一層目錄執行：以 -f 指定 Dockerfile，最後一個參數為建置上下文
docker build -t ssds-web:1.0.0 \
  -f ai-products-selection-frontend/Dockerfile ai-products-selection-frontend
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>BuildKit：</b>Docker Engine 23.0 起，docker build 預設使用 BuildKit 引擎（不需設定 <code>DOCKER_BUILDKIT=1</code>），建置速度與快取管理皆優於舊版引擎。
</div>

<!--
【帶讀關鍵行】
- `-t ssds-api:1.0.0`：指定 Image 名稱與版本。
- 最後的 `.`：建置上下文（build context），Docker 會將此目錄的檔案送交建置程序使用。
- 第二個範例：在專案外層建置前端，-f 指定 Dockerfile 位置，最後一個參數指定上下文為前端資料夾。第五章 Compose 的 build.context 即對應此設定。

【易錯點提醒 ⚠️】
Dockerfile 中所有 COPY 的來源路徑皆相對於建置上下文。在錯誤目錄執行 docker build，`COPY ssds-api/build/libs/ssds.jar` 會出現 not found，因為該檔案不在上下文中。
-->

---

# 什麼是 Layer Cache？

**Layer cache**：建置時若某一步驟的指令與輸入內容未變，Docker 直接重用先前產生的 layer，不重新執行。

| 觀念 | 說明 |
| --- | --- |
| Layer（層） | Dockerfile 指令執行後產生的檔案系統快照 |
| 快取命中 | 指令與輸入內容未變，直接重用舊 layer（輸出顯示 `CACHED`） |
| 快取失效 | 該步驟有變動，該步驟及其後所有步驟重新執行 |
| 由上而下比對 | 從第一行開始逐行比對，某行失效後，後續全部失效 |
| COPY 比對內容 | `COPY` 比對檔案內容的 checksum，檔案修改即失效 |

<!--
【生活化比喻】
如同料理時已切好的食材：食材未變時，下次料理可直接使用，不需重新處理。

【重點解說】
快取由上而下比對，因此 Dockerfile 指令的排列順序直接影響建置速度。下一頁以 SSDS 後端示範。
-->

---

# Layer Cache — 範例：Gradle 多模組相依套件

```dockerfile
# 錯誤示範：原始碼與建置設定一起複製
COPY . .
RUN ./gradlew --no-daemon :ssds-api:bootJar   # 修改任何 Java 檔都會重新下載所有依賴

# 正確示範：先複製所有 Gradle 設定，將依賴下載固定為獨立一層
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
【帶讀關鍵行】
- 錯誤示範：`COPY . .` 複製包含 Java 原始碼在內的整個專案。修改任何一行 Controller，此層即失效，後續 gradlew 全部重新執行：重新下載 Gradle 9.5.1、重新從 Maven Central 下載 Spring Boot、POI、ICU4J 等相依套件，每次建置需數分鐘。
- 正確示範：將「很少變動」與「經常變動」的檔案分開。多模組專案解析相依套件需要：
  - gradlew 與 gradle 目錄（wrapper 腳本、wrapper jar、版本目錄 libs.versions.toml）
  - 根目錄的 settings.gradle、build.gradle
  - 六個子模組各自的 build.gradle（settings.gradle include 了六個模組，缺少任一個 Gradle 即會報錯）
- 執行 `:ssds-api:dependencies` 將可執行模組所需的相依套件下載至此層；之後才複製全部原始碼並執行 bootJar。只要 build.gradle 未修改，相依套件層就會命中快取。

【補充】
- `-x test`：跳過測試。部分測試使用 Testcontainers，需在建置容器中再啟動 Docker，過於複雜；測試應於本機或 CI 執行。
- `--no-daemon`：容器建置為一次性執行，保留 Gradle daemon 沒有意義。
- 進階寫法：BuildKit 支援 `RUN --mount=type=cache,target=/root/.gradle`，可讓 Gradle 快取跨建置保留，即使快取層失效也不需重新下載全部依賴。

【易錯點提醒 ⚠️】
新增子模組時，須在此處補上對應的 COPY，否則相依套件層會失敗。
-->

---

# Layer Cache 的排序原則

將穩定的步驟放在前面、經常變動的步驟放在後面，快取效益最大。

| 原則 | 說明 |
| --- | --- |
| 先安裝相依套件 | 先 COPY `build.gradle`（後端）、`package.json` + `package-lock.json`（前端）再安裝 |
| 後複製原始碼 | `src/` 下的 Java 與 TypeScript 經常修改，於安裝相依套件後再 COPY |
| 順序決定快取範圍 | 某行失效後，其後所有步驟皆重新執行 |
| `--no-cache` | 忽略所有快取，從頭重新建置 |

```bash
docker build --no-cache -t ssds-api:1.0.0 .
```

<!--
【核心說明】
Docker 由上而下比對，某一行內容變動時，該行與其後所有步驟都必須重新執行，無論後續步驟本身是否變動。

【重點解說】
SSDS 前後端採用相同模式：後端的 build.gradle 對應前端的 package.json，皆為很少修改的相依清單；後端的 src/main/java 對應前端的 src/app，皆為經常修改的原始碼。順序皆為先複製清單並安裝相依套件，再複製原始碼並編譯。

【業界實務】
--no-cache 適用於懷疑快取異常（例如修改設定卻未生效），或 CI 需確保完全乾淨的建置。日常開發不應使用，否則失去快取加速的效果。

【易錯點提醒 ⚠️】
若原始碼放在前面、相依清單放在後面，每修改一行程式碼，後續安裝套件的步驟都必須重新執行，建置時間大幅增加。
-->

---
layout: section
class: flex flex-col justify-center items-center text-center
---

# Multi-stage Build 與 .dockerignore

<!--
【段落轉換】
第三部分介紹兩項讓 Image 更精簡、更安全的技巧：multi-stage build（多階段建置）與 .dockerignore。本部分完成的兩份 Dockerfile 即為專案的正式版本。
-->

---

# 什麼是 Multi-stage Build？

**Multi-stage build**：一份 Dockerfile 包含多個建置階段，最終 Image 只保留所需的成品，建置工具不會被打包進去。

| 語法 | 用途 |
| --- | --- |
| `FROM <image> AS <stage-name>` | 開始一個具名的建置階段 |
| `COPY --from=<stage-name>` | 從指定階段複製檔案至目前階段 |
| `--target <stage-name>` | 建置時只執行到指定階段為止 |
| 多個 `FROM` | 一份 Dockerfile 可包含多個建置階段 |

<!--
【問題引導】
若在容器中編譯，編譯器、Gradle、原始碼與相依快取都會留在同一個 Image 中，使 Image 過於龐大。

【生活化比喻】
前面的階段負責「烹調」：編譯程式、安裝開發套件；最後的階段負責「裝盤」：只複製成品，烹調用具（建置工具）不會帶入最終 Image。

【重點提醒】
中間階段不會出現在最終 Image 中。需要檢查中間階段的內容時，可使用 --target 只建置到該階段。
-->

---
zoom: 0.85
---

# Multi-stage Build — ssds-api（正式版）

```dockerfile
# ai-products-selection-backend/Dockerfile
# ---- 第一階段：以專案的 Gradle Wrapper 編譯 ----
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

# ---- 第二階段：僅保留 JRE 與 ssds.jar ----
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
【帶讀關鍵行】
- 第一階段使用 `eclipse-temurin:21-jdk-alpine` 而非官方 gradle Image：專案使用 Gradle 9.5.1（定義於 gradle-wrapper.properties），官方 gradle Image 的版本不一定相同。以 JDK Image 搭配專案的 ./gradlew，wrapper 會下載專案指定的 Gradle 版本，與本機一致。JDK 21 也符合 build.gradle 中 toolchain 的設定，Gradle 不需另外下載 JDK。
- `chmod +x gradlew`：從 Windows 傳入的檔案可能沒有執行權限，避免出現 Permission denied。
- 第二階段使用 jre 而非 jdk，只需執行 jar。`COPY --from=build` 取出第一階段產生的 ssds.jar；檔名固定為 ssds.jar（ssds-api/build.gradle 設定了 `archiveFileName = 'ssds.jar'`），因此不需使用萬用字元，也不會誤複製 plain jar。

【易錯點提醒 ⚠️】
- gradlew 若被 Git 轉為 CRLF 換行，Linux 會出現 `/bin/sh^M: bad interpreter`。專案的 .gitattributes 已設定 `/gradlew text eol=lf` 以避免此問題。
- 首次建置需下載 Gradle、全部相依套件並編譯六個模組，約需 3 至 6 分鐘，屬正常現象。之後僅修改 Java 時，相依套件層會顯示 CACHED。

【重點解說】
第一階段包含 JDK、Gradle、~/.gradle 相依快取與全部原始碼，總計超過 1GB，這些對執行皆無用處。最終 Image 僅包含 Alpine、JRE 與約 100MB 的 jar，`docker images` 顯示約 480MB（壓縮後約 170MB）。
-->

---
zoom: 0.95
---

# Multi-stage Build — ssds-web（正式版）

```dockerfile
# ai-products-selection-frontend/Dockerfile
# ---- 第一階段：以 Node 編譯 Angular ----
FROM node:22-alpine AS build
# npm run generate:api 使用的 openapi-generator 為 Java 程式，建置階段需要 JRE
RUN apk add --no-cache openjdk21-jre-headless
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run generate:api && npx ng build --configuration production

# ---- 第二階段：僅保留 nginx 與靜態檔 ----
FROM nginx:1.30-alpine
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /src/dist/ai-products-selection-frontend/browser /usr/share/nginx/html
ENV API_URL=http://host.docker.internal:8080
EXPOSE 80
```

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>成果：</b>建置階段含 <code>node_modules</code> 超過 <b>1GB</b>；最終 Image 僅包含 nginx 與約 2MB 的靜態檔，<b>約 95MB</b>（壓縮後約 26MB）。
</div>

<!--
【核心說明】
專案的 src/app/api 由 openapi-generator 依 openapi.json 產生，且被 .gitignore 排除，因此 GitHub 與 Docker 建置上下文中都沒有此資料夾。直接執行 ng build 會出現大量 `Could not resolve "../../api"` 錯誤，必須先執行 `npm run generate:api`。openapi-generator-cli 雖以 npm 安裝，底層為 Java 程式，node:22-alpine 不含 Java，因此須先 `apk add openjdk21-jre-headless`。第一階段最終會被捨棄，安裝 JRE 不影響最終 Image 大小。

【帶讀關鍵行】
- `node:22`：Angular 21 支援 Node 20.19、22.12 或 24 以上。Node 22 目前為維護期 LTS（支援至 2027 年 4 月）；新專案亦可改用 `node:24-alpine`（Active LTS）。
- `npm ci`：嚴格依照 package-lock.json 安裝，版本完全鎖定，確保建置可重現。專案使用 npm，不是 pnpm。
- 第二階段改用 nginx，只將 dist 下的產出複製至 nginx 預設網站根目錄。
- `API_URL`：瀏覽器請求 /api/v1/... 時，由 nginx 轉送至後端。預設值 host.docker.internal 代表執行 Docker 的主機，本機 8080 執行 ssds-api 時即可連線。第六章詳細說明，第九章部署時只需修改此環境變數。

【易錯點提醒 ⚠️】
Angular 17 起預設輸出至 `dist/<專案名>/browser`，本專案名稱為 ai-products-selection-frontend（定義於 angular.json）。路徑錯誤時建置仍會成功，但開啟網頁只會看到 nginx 預設歡迎頁。
-->

---
zoom: 0.97
---

# 前端 nginx 設定檔（第六章詳解）

```nginx
# ai-products-selection-frontend/nginx/default.conf.template
server {
    listen       80;
    server_name  _;
    root         /usr/share/nginx/html;
    index        index.html;

    # Angular 前端路由：找不到的路徑一律回傳 index.html
    location / {
        try_files $uri $uri/ /index.html;
    }

    # /api 開頭的請求轉送至後端；${API_URL} 於容器啟動時替換為環境變數值
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
【核心說明】
nginx 官方 Image 在容器啟動時，會以 envsubst 將 /etc/nginx/templates 下 .template 檔中的 ${變數} 替換為環境變數值，再輸出至 conf.d 生效。因此同一個 Image 可在本機、Compose、雲端分別設定不同的 API_URL。$uri、$scheme 等 nginx 內建變數不會被替換，因為 envsubst 只替換實際存在的環境變數。

【帶讀關鍵行】
- `location /`：Angular 路由必要設定。使用者直接開啟 /products/123 等前端路由網址時，伺服器上並無此檔案，需回傳 index.html 由 Angular Router 處理，否則重新整理會出現 404。
- `location /api/`：反向代理。專案 environment.prod.ts 的 apiBaseUrl 為相對路徑 `/api/v1`，瀏覽器將 API 請求送回網頁所在網域，由 nginx 轉送至後端。前後端對瀏覽器而言為同一網域，不會發生 CORS 問題；後端 SecurityConfig 的 CORS 白名單目前只有 localhost:4200，因此此設計很重要。
- `client_max_body_size 50m`：專案的 Excel 匯入上限為 50MB，nginx 預設只接受 1MB。
- `proxy_read_timeout 120s`：AI 分析 API 回應時間可能較長。
- `proxy_ssl_server_name on`：第九章雲端後端網址為 https，缺少此設定 TLS 交握會失敗。

【補充】
nginx 1.30 起，proxy 預設使用 HTTP/1.1 並啟用 keep-alive，不需再手動設定 `proxy_http_version 1.1`。
-->

---
zoom: 0.94
---

# 什麼是 .dockerignore？

**.dockerignore** 用於排除不需送入建置上下文的檔案，縮小上下文並避免機密外洩。

| 項目 | 說明 |
| --- | --- |
| 語法 | 與 `.gitignore` 的排除規則類似 |
| 位置 | 建置上下文的根目錄（通常與 Dockerfile 同目錄） |
| 效益 | 縮小建置上下文、**避免 `.env` 被打包**、加快建置速度 |

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
【核心說明】
docker build 會將目前目錄整體作為建置上下文送交建置程序。SSDS 前端的 node_modules 超過 1GB，後端的 .gradle 快取與各模組 build 目錄也有數百 MB；未排除時傳送就需數十秒，且第一階段仍會以 npm ci / gradlew 重新產生，毫無用處。前端另排除 src/app/api，確保每次皆由 openapi.json 重新產生。

【重點提醒】
後端根目錄的 .env 包含 Supabase 密碼、Mistral API key、Apify token。後端 Dockerfile 第一階段使用 `COPY . .`，未排除時 .env 會進入建置階段；若第二階段也寫了 `COPY . .`，.env 就會進入最終 Image。Image 推送至 Docker Hub 後，任何人皆可取得其中內容。

【易錯點提醒 ⚠️】
- `**/build`：兩個星號代表任意深度的 build 資料夾。六個子模組各有一個 build 目錄，只寫 build 只會排除根目錄的那一個。
- .dockerignore 必須位於建置上下文的根目錄，放錯位置即無效。
-->

---
layout: default
---

# 練習 1：改善 ssds-api 的 Dockerfile 快取
### 任務說明

組員撰寫的 Dockerfile 可以運作，但每修改一行 Java 就會重新下載 Gradle 與所有相依套件，每次建置約需五分鐘：

```dockerfile
FROM eclipse-temurin:21-jdk-alpine
WORKDIR /src
COPY . .
RUN ./gradlew --no-daemon :ssds-api:bootJar -x test
EXPOSE 8080
CMD ["java", "-jar", "ssds-api/build/libs/ssds.jar"]
```

1. 改為 multi-stage，最終 Image 使用 `eclipse-temurin:21-jre-alpine`，並以非 root 使用者執行
2. 調整順序，使「只修改 Java、未修改任何 build.gradle」時，相依套件下載層能命中快取
3. 新增 `.dockerignore`，確認 `.env` 不會進入建置上下文
4. 實測：執行 `docker build -t ssds-api:1.0.0 .` 兩次，第二次前修改一行 Controller，觀察哪些步驟顯示 `CACHED`

<!--
【任務鋪陳】
本題練習快取排序與 multi-stage build，實際比較調整順序前後的建置時間差異。

【出題動機】
多模組專案最容易遺漏子模組的 build.gradle，本題讓學生實際遇到此問題。請務必實際建置兩次比較。
-->

---
layout: default
zoom: 0.85
---

# 練習 1：參考答案

<div class="grid grid-cols-2 gap-4">
<div>

```dockerfile
# Dockerfile
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
RUN chmod +x gradlew \
 && ./gradlew --no-daemon :ssds-api:dependencies > /dev/null
COPY . .
RUN ./gradlew --no-daemon :ssds-api:bootJar -x test

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

</div>
<div>

```plaintext
# .dockerignore
.git
.gradle
**/build
.idea
uploads
.env
*.md
```

```bash
# 第一次建置（約 3–6 分鐘）
docker build -t ssds-api:1.0.0 .

# 修改一行 Controller 後再次建置
docker build -t ssds-api:1.0.0 .
# => CACHED [build] COPY gradlew settings.gradle ...
# => CACHED [build] RUN ... ./gradlew ... dependencies
# =>        [build] COPY . .
# =>        [build] RUN ./gradlew ... bootJar

# 驗證 .env 未進入 Image
docker run --rm --entrypoint ls ssds-api:1.0.0 -la /app
```

</div>
</div>

<!--
【帶讀解法】
- 相依套件層所需檔案：gradlew、gradle/ 目錄（含 libs.versions.toml）、根目錄的 settings.gradle 與 build.gradle，以及六個子模組各自的 build.gradle。
- 第二次建置時，相依套件下載以前的步驟皆顯示 CACHED，只有 `COPY . .` 與 bootJar 重新執行，建置時間由數分鐘縮短為數十秒。
- 最後一行輸出應只有 app.jar 與 uploads 目錄，沒有 .env。

【易錯點提醒 ⚠️】
- 遺漏某個子模組的 build.gradle，相依套件層會失敗或下載不完整。
- 遺漏 gradle/ 目錄會出現 `Could not find or load main class org.gradle.wrapper.GradleWrapperMain`。
-->

---
layout: default
---

# 練習 2：將 ssds-web 包裝為 Image
### 任務說明

`ai-products-selection-frontend/` 下的第一版 Dockerfile 建置失敗：

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

1. 找出錯誤原因並修正（提示：檢查 `.gitignore` 與 `package.json` 的 scripts）
2. 改寫為 multi-stage：第二階段使用 `nginx:1.30-alpine`，並加入 `nginx/default.conf.template`
3. 將 `npm install` 改為 `npm ci`，並調整順序使相依套件安裝能命中快取
4. 新增 `.dockerignore`，並驗證：以 `docker images` 查看大小、進入容器確認沒有 `.ts` 原始碼

<!--
【任務鋪陳】
本題為本章的驗收題，第一步為真實的除錯情境：建置失敗、錯誤訊息看似程式碼問題，實際上是建置環境缺少一個步驟。

【出題動機】
本機開發時 src/app/api 早已產生，因此不會察覺；換到乾淨的環境（Docker、CI、雲端平台）才會出現問題。容器化的價值之一，就是迫使所有隱含的建置步驟明確寫出。
-->

---
layout: default
zoom: 0.88
---

# 練習 2：參考答案

<div class="grid grid-cols-2 gap-4">
<div>

**1. 原因：**`src/app/api` 被 `.gitignore` 排除，須以 `npm run generate:api` 產生；openapi-generator 需要 Java。

```dockerfile
# Dockerfile
FROM node:22-alpine AS build
RUN apk add --no-cache openjdk21-jre-headless
WORKDIR /src
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run generate:api \
 && npx ng build --configuration production

FROM nginx:1.30-alpine
COPY nginx/default.conf.template \
     /etc/nginx/templates/default.conf.template
COPY --from=build \
     /src/dist/ai-products-selection-frontend/browser \
     /usr/share/nginx/html
ENV API_URL=http://host.docker.internal:8080
EXPOSE 80
```

</div>
<div>

```plaintext
# .dockerignore
.git
node_modules
dist
.angular
src/app/api
.env*
*.md
```

```bash
docker build -t ssds-web:1.0.0 .
docker images ssds-web                  # 約 95MB
docker run -d --name ssds-web -p 8000:80 ssds-web:1.0.0

# 只有 index.html 與雜湊檔名的 js/css，沒有 .ts
docker exec ssds-web ls /usr/share/nginx/html

# ${API_URL} 已替換為實際網址
docker exec ssds-web cat /etc/nginx/conf.d/default.conf
```

</div>
</div>

<div class="mt-2 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
💡 <b>端到端驗證：</b>本機 8080 執行 <code>ssds-api</code> 容器時，開啟 <code>http://localhost:8000</code> 登入並載入資料，即表示 web → nginx 反向代理 → api → Supabase 全線連通。
</div>

<!--
【帶讀解法】
- 錯誤原因：src/app/api 為產生的程式碼且未納入版本控制，建置環境中不存在。
- 相依套件快取：先 COPY package.json 與 package-lock.json → npm ci → 再 COPY 原始碼。
- 輸出路徑依 angular.json：`dist/ai-products-selection-frontend/browser`。

【易錯點提醒 ⚠️】
第 4 步的驗證必須執行。未 COPY .env 不代表安全：只要使用 `COPY . .` 且 .dockerignore 未排除，機密就會進入建置上下文。

【重點提醒】
完成後應有兩個 Image：ssds-api:1.0.0 與 ssds-web:1.0.0。請將兩份 Dockerfile、.dockerignore、nginx 設定檔 commit 至各自的 repo，第九章雲端平台會直接從 GitHub 讀取這些檔案進行建置。
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
<tr><th>主題</th><th>重點</th></tr>
</thead>
<tbody>
<tr><td>常用指令</td><td><code>FROM</code>、<code>COPY</code>、<code>RUN</code>、<code>CMD</code>、<code>ENTRYPOINT</code>、<code>EXPOSE</code>、<code>ENV</code></td></tr>
<tr><td>健康檢查</td><td>加入 Actuator，路徑為 <code>/api/v1/actuator/health</code>（受 context-path 影響）</td></tr>
<tr><td>Layer Cache</td><td>先 COPY 所有 build.gradle / package-lock.json 並安裝相依套件，再 COPY 原始碼</td></tr>
<tr><td>ssds-api</td><td>JDK + gradlew 編譯 → JRE + <code>ssds.jar</code>，非 root 執行，約 480MB</td></tr>
<tr><td>ssds-web</td><td>Node（+ JRE 執行 generate:api）編譯 → nginx + 靜態檔，約 95MB</td></tr>
<tr><td>.dockerignore</td><td>排除 <code>node_modules</code>、<code>**/build</code>，<b>必須排除 <code>.env</code></b></td></tr>
</tbody>
</table>

<div class="mt-4 p-3 bg-blue-50 border-l-4 border-blue-400 text-gray-700 text-sm text-left">
🚀 <b>下一章：</b>Docker Compose — 以一份 YAML 同時建置並啟動 ssds-api 與 ssds-web。
</div>

<!--
【回顧】
本章介紹 Dockerfile 的核心指令與 CMD / ENTRYPOINT 的差異，說明 docker build 的 layer 與快取機制（多模組專案須先複製所有子模組的 build.gradle），最後以 multi-stage build 完成前後端正式 Dockerfile，並以 .dockerignore 確保 .env 不外洩。

【重點提醒】
請確認以下檔案皆已 commit：
- 後端：Dockerfile、.dockerignore、ssds-api/build.gradle 的 actuator 相依套件
- 前端：Dockerfile、.dockerignore、nginx/default.conf.template

【課程預覽】
下一章以 Docker Compose 統一管理兩個容器。
-->

---
layout: end
---

# Q & A

有任何問題嗎？

<!--
【互動引導】
開放提問：Dockerfile 常用指令、Layer Cache 機制或 Multi-stage Build，有任何疑問皆可提出。

【操作提示】
專案建置失敗時，先確認錯誤發生在哪一個階段、哪一行 RUN，再對照本章的常見問題：gradlew 權限、缺少子模組的 build.gradle、缺少 generate:api、dist 路徑錯誤。
-->
