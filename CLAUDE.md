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
- `ch01-*.md` … `ch09-*.md` — Chapter slide files (9 chapters)

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
| 8 | ch08-deploy.md | 上線前準備 |
| 9 | ch09-cloud-deploy.md | 雲端部署（免費免綁卡） |

## 貫穿專案：SSDS（AI 選品系統，所有範例 / 練習 / 實作的統一情境）

學生自己的專案 `ai-products-selection/`（前後端各自是獨立 git repo）。
目標：上完九章，學生能把專案包成 Docker image 並部署到免費、免綁卡的雲端平台。
資料庫是 **Supabase PostgreSQL（雲端託管）**，不放進 Docker、Compose 也沒有 db 服務。

```
ai-products-selection/
├── compose.yaml                          # Ch5 起，放在兩個 repo 的上一層
├── ai-products-selection-backend/        # Spring Boot 4.1 + Gradle 9.5.1 多模組 (Groovy DSL), Java 21
│   ├── settings.gradle                   # ssds-api / core / ai / ingest / calibration / infra
│   ├── ssds-api/                         # 唯一可執行模組，bootJar → ssds-api/build/libs/ssds.jar
│   ├── .env / .env.example               # SSDS_DB_*、MISTRAL_API_KEY、SSDS_JWT_SECRET…
│   └── Dockerfile / .dockerignore        # Ch4 產出
└── ai-products-selection-frontend/       # Angular 21（npm），build 後用 nginx 服務
    ├── openapi.json                      # npm run generate:api → src/app/api（gitignored，需 Java）
    ├── nginx/default.conf.template       # Ch4 產出，/api/ → proxy_pass ${API_URL}
    └── Dockerfile / .dockerignore        # Ch4 產出
```

固定命名（章節間務必一致）：

| 項目 | 值 |
| ---- | -- |
| Image | `ssds-api:1.0.0`、`ssds-web:1.0.0`；Docker Hub `myaccount/ssds-api`、`myaccount/ssds-web` |
| Container（docker run） | `ssds-api`、`ssds-web` |
| Compose | `name: ssds`；service `api`、`web` |
| Network | `ssds-net`（custom bridge，Ch6） |
| Volume | `ssds-uploads` → `/app/uploads`（商品圖片 + 匯入暫存） |
| Port 映射 | api `8080:8080`、web `8000:80` |
| context-path | `/api/v1`（所有 API、actuator、swagger 都在其下） |
| Health | API `GET /api/v1/actuator/health`（Ch4 加 actuator）、web `GET /` |
| web → api | 環境變數 `API_URL`：預設 `http://host.docker.internal:8080`、Compose `http://api:8080`、雲端用後端公開 https 網址（不加結尾 `/`） |
| DB 連線 | Supabase **pooler**（IPv4）`aws-0-ap-south-1.pooler.supabase.com:6543`，不用 direct connection（IPv6） |

基礎 Image：build 用 `eclipse-temurin:21-jdk-alpine`（+ 專案 `./gradlew`）、`node:22-alpine`（+ `openjdk21-jre-headless` 跑 openapi-generator）；
runtime 用 `eclipse-temurin:21-jre-alpine`、`nginx:1.30-alpine`。

各章在專案中的切入點：

| Ch | 專案情境 |
| -- | ------- |
| 1 | `docker run nginx` 理解 Client/Daemon/Registry；介紹 SSDS 架構（DB 在 Supabase） |
| 2 | pull 四個基礎 image、對 `ssds-api` 打 tag、push 到 registry |
| 3 | 用官方 JRE image + bind mount 跑本機 build 的 `ssds.jar`，`--env-file .env`，exec / logs 除錯 |
| 4 | Actuator、多模組 Gradle 的 layer cache、兩份 multi-stage Dockerfile、nginx template、.dockerignore |
| 5 | Compose 一次拉起 api + web，`env_file`、healthcheck、`depends_on: service_healthy` |
| 6 | custom bridge + DNS、nginx 反向代理 `/api`（免 CORS）、容器連 Supabase pooler |
| 7 | 商品圖片持久化（`ssds-uploads`）、tar 備份還原、`postgres:17-alpine` 當 pg_dump 工具 |
| 8 | 兩種 `.env`、`SSDS_JWT_SECRET`、tag 策略、Docker Hub（`--platform linux/amd64`）、512MB + `JAVA_TOOL_OPTIONS` |
| 9 | 平台調查（2026/10）；Render 方式 A（Git + Dockerfile）、方式 B（Existing Image + GitHub Actions + Deploy Hook）；Railway 備案 |

## Slidev Conventions

- Theme: `penguin` for all decks
- Color accent: `#5eada0` (teal)
- Per-slide layouts: `layout:` in slide front-matter (`section`, `two-cols`, `cover`, `default`)
- Progressive reveal: `v-click` / `v-clicks`
- Custom styles: inline in frontmatter `style:` block
- Tailwind utility classes work directly in slide markdown
