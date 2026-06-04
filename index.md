---
theme: penguin
class: text-center
highlighter: shiki
lineNumbers: true
drawings:
  persist: false
transition: slide-left
title: Docker 容器化課程
routeAlias: home
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

<style>
.chapter-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
  width: 100%;
  max-width: 960px;
  margin-top: 1.2rem;
}
.chapter-card {
  display: block;
  background: #eff6ff;
  border: 2px solid #2563eb;
  border-radius: 12px;
  padding: 1.2rem 0.8rem;
  text-decoration: none !important;
  color: #1e3a8a !important;
  transition: all 0.2s ease;
}
.chapter-card:hover {
  background: #2563eb;
  color: white !important;
  transform: translateY(-3px);
  box-shadow: 0 6px 16px rgba(37, 99, 235, 0.35);
}
.chapter-card:hover .chapter-subtitle {
  color: rgba(255,255,255,0.85) !important;
}
.chapter-num {
  font-size: 1.6rem;
  font-weight: 900;
  margin-bottom: 0.3rem;
}
.chapter-subtitle {
  font-size: max(13px, 0.88rem);
  color: #1d4ed8;
  margin-top: 0.3rem;
}
</style>

<div class="flex flex-col items-center h-full" style="background: #ffffff; overflow-y: auto; padding: 1.5rem 0;">
  <p style="color: #2563eb; font-size: 1rem; font-weight: 600; letter-spacing: 0.2em; text-transform: uppercase; margin-bottom: 1rem;">Docker 容器化課程</p>
  <h1 style="color: #1e3a8a; font-size: 2.8rem; font-weight: 900; line-height: 1.2; margin-bottom: 0.5rem;">課程目錄</h1>
  <div style="height: 4px; width: 240px; background: linear-gradient(90deg, #2563eb, #60a5fa); border-radius: 2px; margin-bottom: 0.5rem;"></div>
  <p style="color: #93c5fd; font-size: 0.9rem; margin-bottom: 0;">點擊章節卡片開始學習</p>
  <div class="chapter-grid">
    <Link to="ch01" class="chapter-card">
      <div class="chapter-num">Ch 1</div>
      <div>Docker 簡介</div>
      <div class="chapter-subtitle">容器 vs VM / Engine / 架構</div>
    </Link>
    <Link to="ch02" class="chapter-card">
      <div class="chapter-num">Ch 2</div>
      <div>映像檔管理</div>
      <div class="chapter-subtitle">pull / push / build / tag / Hub</div>
    </Link>
    <Link to="ch03" class="chapter-card">
      <div class="chapter-num">Ch 3</div>
      <div>容器操作</div>
      <div class="chapter-subtitle">run / exec / start / stop / logs</div>
    </Link>
    <Link to="ch04" class="chapter-card">
      <div class="chapter-num">Ch 4</div>
      <div>Dockerfile</div>
      <div class="chapter-subtitle">語法 / 最佳實踐 / 多階段建構</div>
    </Link>
    <Link to="ch05" class="chapter-card">
      <div class="chapter-num">Ch 5</div>
      <div>Docker Compose</div>
      <div class="chapter-subtitle">services / networks / volumes</div>
    </Link>
    <Link to="ch06" class="chapter-card">
      <div class="chapter-num">Ch 6</div>
      <div>網路設定</div>
      <div class="chapter-subtitle">bridge / host / overlay / DNS</div>
    </Link>
    <Link to="ch07" class="chapter-card">
      <div class="chapter-num">Ch 7</div>
      <div>Volume 資料持久化</div>
      <div class="chapter-subtitle">named volumes / bind mounts / tmpfs</div>
    </Link>
    <Link to="ch08" class="chapter-card">
      <div class="chapter-num">Ch 8</div>
      <div>部署實戰</div>
      <div class="chapter-subtitle">production / health check / limits</div>
    </Link>
  </div>
</div>
