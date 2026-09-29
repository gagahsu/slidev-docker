# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Commands

```bash
pnpm dev              # Start dev server at localhost:3030
pnpm build            # Build to dist/ for deployment
pnpm export           # Export slides to PDF
```

Package manager is **pnpm** (not npm/yarn). The `.npmrc` sets `shamefully-hoist=true` required by Slidev.

## Architecture

This is a **Slidev** presentation project for Docker curriculum. All slide files live at the root level.

### Entry Point
- `index.md` — Portal page (目錄頁) with chapter navigation cards. Imports all chapter decks via `src:`.

### Slide Decks
- `ch01-*.md`, `ch02-*.md`, … — Chapter slide files

### Vue Components
- `global-bottom.vue` — Footer rendered on every slide showing page X/Y

### Templates
- `_template/` — Blueprint for new chapters (slides.md, global-bottom.vue, package.json, style.css)

## Navigation

```yaml
# In slide frontmatter:
routeAlias: ch01
```

```html
<Link to="ch01">Go to Ch01</Link>
<Link to="home">← 返回目錄</Link>
```

## Adding a New Chapter

1. Copy `_template/slides.md` → `<chXX-name>.md` at root
2. Set `routeAlias: chXX` and `title:` in frontmatter
3. Add `src: ./<chXX-name>.md` block at end of `index.md`
4. Add `<Link to="chXX" class="chapter-card">` card to `index.md`'s `.chapter-grid`
5. Run `pnpm dev` — no additional installs needed

## Planned Chapters

| Ch | File | Topic |
| -- | ---- | ----- |
| 1 | ch01-intro.md | Docker 簡介 |
| 2 | ch02-images.md | 映像檔管理 |
| 3 | ch03-containers.md | 容器操作 |
| 4 | ch04-dockerfile.md | Dockerfile |
| 5 | ch05-compose.md | Docker Compose |
| 6 | ch06-network.md | 網路設定 |
| 7 | ch07-volume.md | Volume 資料持久化 |
| 8 | ch08-deploy.md | 部署實戰 |

## 貫穿專案：動態問卷系統（所有範例 / 練習 / 實作的統一情境）

學生先修：Spring Boot (Gradle) / Angular / MySQL，並且做完「動態問卷系統」（規格見 `SURVEY-SPEC.md`，各 repo 內容一致，修改時要同步）。八章的範例與練習一律套用同一個
動態問卷系統，章節之間有連續性 — Ch1 建立的東西 Ch8 還在用。

專案結構（各部分的完成版都在其他 repo 的 `reference/`，見下方「參考答案」）：

```
survey/
├── survey-api/          # Spring Boot 4.1.1 + Gradle (Groovy DSL), Java 21 = slidev-springboot/reference/dynamic-survey
│   ├── build.gradle     #   bootJar 固定檔名 survey-api.jar；含 actuator（/actuator/health）
│   ├── gradlew / gradle/wrapper/
│   └── src/main/java/com/example/survey/
├── survey-web/          # Angular 21，build 後用 nginx 靜態服務 = slidev-angular/reference/survey-web
│   ├── package.json / .npmrc（legacy-peer-deps）
│   └── src/
├── db/init.sql          # 建表 + 範例資料（= slidev-mysql 的 schema.sql + seed.sql + ch45-refresh-tokens.sql）
└── docker-compose.yml
```

固定命名（章節間務必一致）：

| 項目 | 值 |
| ---- | -- |
| Image | `survey-api:1.0.0`、`survey-web:1.0.0`、`mysql:8.4` |
| Container | `survey-api`、`survey-web`、`survey-db` |
| Compose service | `api`、`web`、`db` |
| Network | `survey-net`（custom bridge） |
| Volume | `survey-db-data`（MySQL 資料）、`survey-api-logs`（`docker run` 時的名稱；Compose 內叫 `db-data`、`api-logs`，實際名稱會加專案名前綴，如 `survey_db-data`） |
| Port 映射 | web `8080:80`、api `8081:8080`、db `3307:3306` |
| DB | database `dynamic_survey` / user `appuser` / password `apppw`（root 密碼 `rootpw`） |
| 連線字串 | `jdbc:mysql://survey-db:3306/dynamic_survey`（Compose 內用 `jdbc:mysql://db:3306/dynamic_survey`） |
| Health | API `GET /actuator/health`、web `GET /` |
| 時區 | API 容器要設 `TZ=Asia/Taipei`（問卷狀態用 `LocalDate.now()` 判斷；容器預設是 UTC，凌晨 0～8 點會差一天） |
| 瀏覽器入口 | `http://localhost:8080`（nginx，`/api` 反向代理到 API；前端 production build 用同源的 `/api`，不需要 CORS） |
| Registry | Docker Hub 帳號示範用 `myaccount` |

基礎 Image：build 用 `gradle:8.14-jdk21`、`node:22-alpine`；runtime 用
`eclipse-temurin:21-jre-alpine`、`nginx:1.27-alpine`。

各章在專案中的切入點：

| Ch | 專案情境 |
| -- | ------- |
| 1 | 用 `docker run` 跑起 `survey-db`，理解 Client/Daemon/Registry 流程 |
| 2 | pull 基礎 image、對 `survey-api` 打 tag、push 到 registry |
| 3 | 三個容器的生命週期、`exec` 進 MySQL 查資料、看 Spring Boot logs |
| 4 | 寫 API 的 Gradle multi-stage Dockerfile、web 的 node→nginx multi-stage |
| 5 | 用 Compose 一次拉起 db + api + web，`depends_on` / healthcheck |
| 6 | custom bridge + DNS 服務名連線、nginx 反向代理 `/api` |
| 7 | MySQL 資料持久化、備份還原、Gradle cache 與 log 掛載 |
| 8 | `.env`、健康檢查、資源限制、image tag 策略與 CI/CD |

## Slidev Conventions

- Theme: `penguin` for all decks
- Color accent: `#5eada0` (teal)
- Per-slide layouts: `layout:` in slide front-matter (`section`, `two-cols`, `cover`, `default`)
- Progressive reveal: `v-click` / `v-clicks`
- Custom styles: inline in frontmatter `style:` block
- Tailwind utility classes work directly in slide markdown

## 參考答案與驗證

- **`reference/survey/`**：Dockerfile（API、Web）、`nginx.conf`、`docker-compose.yml`、`db/init.sql`，已用真的 Docker 建置與 Playwright 端對端測試驗證過。**投影片裡的 Dockerfile、compose、nginx 設定必須取自這裡**；改題目時先在這裡跑過再改投影片
- nginx 反向代理要寫 `proxy_set_header Host $http_host;`（含 port）。寫成 `$host` 會讓 Spring 覺得 `Origin: http://localhost:8080` 與 Host 不同而回 403（CORS）
- API 容器要用非 root 使用者時，`/app/logs` 要在 image 裡先建好並 `chown`，named volume 掛上去才有寫入權限
