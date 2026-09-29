# survey：動態問卷系統的 Docker 參考答案

把 MySQL 課、Spring Boot 課、Angular 課做出來的「動態問卷系統」，用 Docker 一個指令跑起來。
（Dockerfile、nginx 設定、compose 都是投影片裡的最終版；已用真的 Docker 建置並用 Playwright 端對端測試驗證。）

## 準備專案

這個資料夾只放 Docker 相關檔案，另外兩個專案要從其他 repo 複製進來：

```bash
# 在這個資料夾（reference/survey）執行；路徑依實際位置調整
cp -r ../../../slidev-springboot/reference/dynamic-survey/{build.gradle,settings.gradle,gradlew,gradlew.bat,gradle,src} survey-api/
cp -r ../../../slidev-angular/reference/survey-web/{package.json,package-lock.json,.npmrc,angular.json,tsconfig*.json,public,src} survey-web/
```

最後長這樣：

```
survey/
├── survey-api/   # Spring Boot 4.1.1（Dockerfile + 上面複製的檔案）
├── survey-web/   # Angular 21（Dockerfile、nginx.conf + 上面複製的檔案）
├── db/init.sql   # 建表 + 範例資料（schema.sql + seed.sql + ch45-refresh-tokens.sql）
└── docker-compose.yml
```

## 啟動

```bash
docker compose up -d --build        # 第一次要 build，約幾分鐘
docker compose ps                   # 三個容器都要是 running / healthy
# 瀏覽器：http://localhost:8080      （前端；/api 由 nginx 轉給後端）
# 管理員：admin@example.com / Passw0rd12；一般會員：ming@example.com / Passw0rd12
```

正式環境用 `.env`（不進版控）：

```bash
cp .env.example .env                # 填入 MYSQL_ROOT_PASSWORD、MYSQL_PASSWORD、JWT_SECRET（openssl rand -base64 48）
docker compose -f docker-compose.env.yml up -d --build
```

## 幾個容易踩的地方

| 現象 | 原因 |
| --- | --- |
| 登入回 403 | nginx 要用 `proxy_set_header Host $http_host;`（含 port），寫成 `$host` 會被 Spring 當成跨域請求 |
| API 啟動失敗：`Schema-validation: missing table` | 資料庫沒有匯入 `db/init.sql`（API 用 `ddl-auto=validate`，不會幫忙建表） |
| 改了 `MYSQL_PASSWORD` 沒生效 / 想重匯 `init.sql` | 資料目錄已有資料，MySQL 不會重跑初始化：`docker compose down -v` 砍掉 Volume 重來 |
| 凌晨（台灣時間 0～8 點）問卷狀態差一天 | 容器預設 UTC；API 要設 `TZ: Asia/Taipei` |
| `npm ci` 失敗（peer dependency） | 忘了 COPY `.npmrc`（`legacy-peer-deps=true`） |
| 日誌寫不進 `/app/logs` | image 裡要先建好 `logs` 並 `chown` 給非 root 使用者，Volume 才有權限 |

## 驗證

```bash
cd ../../../slidev-angular/reference/survey-web
BASE=http://localhost:8080 node e2e/e2e.mjs      # Playwright 端對端測試，全部 PASS
```
