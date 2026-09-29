# ---- 第一階段：用 Node 編譯 Angular ----
FROM node:22-alpine AS build
WORKDIR /src
# .npmrc 內含 legacy-peer-deps=true，缺了 npm ci 會因為 peer dependency 失敗
COPY package.json package-lock.json .npmrc ./
RUN npm ci
COPY . .
RUN npm run build          # 產出到 dist/survey-web/browser

# ---- 第二階段：只留 nginx 跟靜態檔 ----
FROM nginx:1.27-alpine
COPY --from=build /src/dist/survey-web/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
