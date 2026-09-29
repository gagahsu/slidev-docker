-- 動態問卷系統 schema（對應 SURVEY-SPEC.md §3；MySQL 8.4）
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS dynamic_survey;
CREATE DATABASE dynamic_survey
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE dynamic_survey;

CREATE TABLE users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(50)  NOT NULL,
  email      VARCHAR(100) NOT NULL UNIQUE,
  password   VARCHAR(100) NOT NULL,
  phone      VARCHAR(20),
  role       VARCHAR(10)  NOT NULL DEFAULT 'USER',
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_users_role CHECK (role IN ('USER', 'ADMIN'))
) ENGINE=InnoDB;

CREATE TABLE surveys (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  title       VARCHAR(50) NOT NULL,
  description VARCHAR(300),
  start_date  DATE        NOT NULL,
  end_date    DATE        NOT NULL,
  published   TINYINT     NOT NULL DEFAULT 0,
  created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chk_survey_dates CHECK (end_date >= start_date)
) ENGINE=InnoDB;

CREATE TABLE questions (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  survey_id   INT          NOT NULL,
  title       VARCHAR(200) NOT NULL,
  type        VARCHAR(10)  NOT NULL,
  required    TINYINT      NOT NULL DEFAULT 0,
  order_index INT          NOT NULL,
  INDEX idx_questions_survey (survey_id),
  CONSTRAINT chk_question_type CHECK (type IN ('SINGLE', 'MULTI', 'TEXT')),
  FOREIGN KEY (survey_id) REFERENCES surveys(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE options (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  question_id INT          NOT NULL,
  label       VARCHAR(100) NOT NULL,
  order_index INT          NOT NULL,
  INDEX idx_options_question (question_id),
  FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE survey_responses (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  survey_id    INT          NOT NULL,
  user_id      INT,
  name         VARCHAR(50)  NOT NULL,
  phone        VARCHAR(20)  NOT NULL,
  email        VARCHAR(100) NOT NULL,
  age          INT,
  submitted_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_survey_email (survey_id, email),
  CONSTRAINT chk_response_age CHECK (age IS NULL OR age BETWEEN 1 AND 120),
  FOREIGN KEY (survey_id) REFERENCES surveys(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id)   REFERENCES users(id)   ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE response_answers (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  response_id INT NOT NULL,
  question_id INT NOT NULL,
  answer_text VARCHAR(500),
  INDEX idx_answers_response (response_id),
  INDEX idx_answers_question (question_id),
  FOREIGN KEY (response_id) REFERENCES survey_responses(id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES questions(id)        ON DELETE CASCADE
) ENGINE=InnoDB;
-- 動態問卷系統範例資料（先執行 schema.sql）
-- 日期一律相對於 CURDATE()，所以「進行中 / 尚未開始 / 已結束」不論何時執行都成立。
SET NAMES utf8mb4;
USE dynamic_survey;

-- 三個帳號的密碼都是 Passw0rd12（下面是它的 BCrypt 雜湊，Spring Security 登入可直接使用）
INSERT INTO users (id, name, email, password, phone, role) VALUES
  (1, '管理員', 'admin@example.com', '$2a$10$ZHHVvagYM0fBxyUFpkYVpuSIIU3EGC/C0LFJtt/.6Ak6d//C3XZm6', '0900000000', 'ADMIN'),
  (2, '王小明', 'ming@example.com',  '$2a$10$ZHHVvagYM0fBxyUFpkYVpuSIIU3EGC/C0LFJtt/.6Ak6d//C3XZm6', '0911111111', 'USER'),
  (3, '林美玲', 'mei@example.com',   '$2a$10$ZHHVvagYM0fBxyUFpkYVpuSIIU3EGC/C0LFJtt/.6Ak6d//C3XZm6', '0922222222', 'USER');

INSERT INTO surveys (id, title, description, start_date, end_date, published) VALUES
  (1, '校園活動調查',   '哪個活動最受歡迎？',   DATE_SUB(CURDATE(), INTERVAL 30 DAY), DATE_SUB(CURDATE(), INTERVAL 10 DAY), 1), -- 已結束
  (2, '午餐偏好調查',   '幫公司餐廳選菜單',     DATE_SUB(CURDATE(), INTERVAL 5 DAY),  DATE_ADD(CURDATE(), INTERVAL 10 DAY), 1), -- 進行中
  (3, '新品口味調查',   '下一款冰淇淋口味',     DATE_SUB(CURDATE(), INTERVAL 2 DAY),  DATE_ADD(CURDATE(), INTERVAL 20 DAY), 1), -- 進行中
  (4, '員工旅遊意願',   '今年要不要辦旅遊',     DATE_ADD(CURDATE(), INTERVAL 3 DAY),  DATE_ADD(CURDATE(), INTERVAL 13 DAY), 1), -- 尚未開始
  (5, '會員滿意度調查', '草稿，尚未發佈',       DATE_ADD(CURDATE(), INTERVAL 5 DAY),  DATE_ADD(CURDATE(), INTERVAL 15 DAY), 0), -- 未發佈
  (6, '課程回饋調查',   '這堂課難度如何',       DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 5 DAY),  1); -- 進行中

INSERT INTO questions (id, survey_id, title, type, required, order_index) VALUES
  (1, 2, '你平常午餐吃什麼？',     'SINGLE', 1, 1),
  (2, 2, '喜歡哪些配菜？',         'MULTI',  0, 2),
  (3, 2, '想給餐廳的建議',         'TEXT',   0, 3),
  (4, 1, '最喜歡的校園活動',       'SINGLE', 1, 1),
  (5, 3, '最想嘗試的口味',         'SINGLE', 1, 1),
  (6, 3, '你期待的產品名稱',       'TEXT',   0, 2),
  (7, 6, '課程難度',               'SINGLE', 1, 1),
  (8, 4, '你會參加嗎？',           'SINGLE', 1, 1),
  (9, 5, '對我們有什麼意見？',     'TEXT',   0, 1);

INSERT INTO options (id, question_id, label, order_index) VALUES
  (1, 1, '便當', 1), (2, 1, '麵食', 2), (3, 1, '輕食', 3),
  (4, 2, '青菜', 1), (5, 2, '滷蛋', 2), (6, 2, '豆腐', 3), (7, 2, '肉類', 4),
  (8, 4, '運動會', 1), (9, 4, '園遊會', 2), (10, 4, '音樂祭', 3),
  (11, 5, '抹茶', 1), (12, 5, '芝麻', 2), (13, 5, '芋頭', 3),
  (14, 7, '太簡單', 1), (15, 7, '剛好', 2), (16, 7, '太難', 3),
  (17, 8, '參加', 1), (18, 8, '不參加', 2);

INSERT INTO survey_responses (id, survey_id, user_id, name, phone, email, age, submitted_at) VALUES
  (1,  1, NULL, '陳志明', '0933000001', 'a1@example.com', 20,   DATE_SUB(NOW(), INTERVAL 20 DAY)),
  (2,  1, 2,    '王小明', '0911111111', 'ming@example.com', 25, DATE_SUB(NOW(), INTERVAL 19 DAY)),
  (3,  1, NULL, '黃雅婷', '0933000003', 'a3@example.com', NULL, DATE_SUB(NOW(), INTERVAL 15 DAY)),
  (4,  2, 2,    '王小明', '0911111111', 'ming@example.com', 25, DATE_SUB(NOW(), INTERVAL 4 DAY)),
  (5,  2, 3,    '林美玲', '0922222222', 'mei@example.com', 31,  DATE_SUB(NOW(), INTERVAL 3 DAY)),
  (6,  2, NULL, '張大偉', '0933000006', 'a6@example.com', 45,   DATE_SUB(NOW(), INTERVAL 2 DAY)),
  (7,  2, NULL, '李佳蓉', '0933000007', 'a7@example.com', NULL, DATE_SUB(NOW(), INTERVAL 1 DAY)),
  (8,  3, 3,    '林美玲', '0922222222', 'mei@example.com', 31,  DATE_SUB(NOW(), INTERVAL 1 DAY)),
  (9,  6, NULL, '吳建宏', '0933000009', 'a9@example.com', 28,   DATE_SUB(NOW(), INTERVAL 2 DAY)),
  (10, 6, 2,    '王小明', '0911111111', 'ming@example.com', 25, DATE_SUB(NOW(), INTERVAL 1 DAY));

-- 多選題答案以分號 ; 串接
INSERT INTO response_answers (response_id, question_id, answer_text) VALUES
  (1, 4, '運動會'), (2, 4, '園遊會'), (3, 4, '園遊會'),
  (4, 1, '便當'), (4, 2, '青菜;滷蛋'),          (4, 3, '菜色可以多一點變化'),
  (5, 1, '輕食'), (5, 2, '青菜;豆腐;肉類'),
  (6, 1, '便當'), (6, 2, '滷蛋;肉類'),          (6, 3, '希望有素食選項'),
  (7, 1, '麵食'),
  (8, 5, '抹茶'), (8, 6, '綠意盎然'),
  (9, 7, '剛好'), (10, 7, '太難');
-- 第 45 章練習「Refresh Token」新增的資料表（先執行 schema.sql）
SET NAMES utf8mb4;
USE dynamic_survey;

CREATE TABLE refresh_tokens (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  email       VARCHAR(100) NOT NULL,
  token       VARCHAR(500) NOT NULL,
  expiry_date DATETIME(6)  NOT NULL,
  UNIQUE KEY uk_refresh_token (token(255)),
  INDEX idx_refresh_email (email)
) ENGINE=InnoDB;
