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

## 貫穿專案：TaskBoard（所有範例 / 練習 / 實作的統一情境）

學生先修：Spring Boot (Gradle) / Angular / MySQL。八章的範例與練習一律套用同一個
TaskBoard 專案，章節之間有連續性 — Ch1 建立的東西 Ch8 還在用。

專案結構：

```
taskboard/
├── taskboard-api/          # Spring Boot 3.5 + Gradle (Groovy DSL), Java 21
│   ├── build.gradle
│   ├── gradlew / gradle/wrapper/
│   └── src/main/java/com/example/taskboard/
├── taskboard-web/          # Angular 20，build 後用 nginx 靜態服務
│   ├── package.json
│   └── src/
├── db/init.sql             # 建表 SQL
└── docker-compose.yml
```

固定命名（章節間務必一致）：

| 項目 | 值 |
| ---- | -- |
| Image | `taskboard-api:1.0.0`、`taskboard-web:1.0.0`、`mysql:8.4` |
| Container | `taskboard-api`、`taskboard-web`、`taskboard-db` |
| Compose service | `api`、`web`、`db` |
| Network | `taskboard-net`（custom bridge） |
| Volume | `taskboard-db-data`（MySQL 資料）、`taskboard-api-logs` |
| Port 映射 | web `8080:80`、api `8081:8080`、db `3307:3306` |
| DB | database `taskboard` / user `appuser` / password `apppw` |
| 連線字串 | `jdbc:mysql://taskboard-db:3306/taskboard`（Compose 內用 `jdbc:mysql://db:3306/taskboard`） |
| Health | API `GET /actuator/health`、web `GET /` |
| Registry | Docker Hub 帳號示範用 `myaccount` |

基礎 Image：build 用 `gradle:8.10-jdk21`、`node:20-alpine`；runtime 用
`eclipse-temurin:21-jre-alpine`、`nginx:1.27-alpine`。

各章在專案中的切入點：

| Ch | 專案情境 |
| -- | ------- |
| 1 | 用 `docker run` 跑起 `taskboard-db`，理解 Client/Daemon/Registry 流程 |
| 2 | pull 基礎 image、對 `taskboard-api` 打 tag、push 到 registry |
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
