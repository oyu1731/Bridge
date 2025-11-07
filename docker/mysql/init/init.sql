SET FOREIGN_KEY_CHECKS = 0;

-- ========== DATABASE ==========
CREATE DATABASE IF NOT EXISTS bridgedb;
USE bridgedb;

-- ========== DROP TABLES (順序最適化) ==========
DROP TABLE IF EXISTS articles_tag;
DROP TABLE IF EXISTS notices;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS phone_exercises;
DROP TABLE IF EXISTS interviews;
DROP TABLE IF EXISTS quiz_scores;
DROP TABLE IF EXISTS quiz_questions;
DROP TABLE IF EXISTS chats;
DROP TABLE IF EXISTS threads;
DROP TABLE IF EXISTS articles;
DROP TABLE IF EXISTS industry_relations;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS photos;
DROP TABLE IF EXISTS industries;
DROP TABLE IF EXISTS tag;

-- ========== TABLE: photos ==========
CREATE TABLE photos (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    photo_path VARCHAR(255) NOT NULL,
    user_id INT(20)
);

-- ========== TABLE: users ==========
CREATE TABLE users (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nickname VARCHAR(100) NOT NULL,
    type INT(1) NOT NULL COMMENT '1=学生、2=社会人、3=企業、4=管理者',
    password VARCHAR(255) NOT NULL COMMENT 'ハッシュ化',
    phone_number VARCHAR(15) NOT NULL COMMENT 'ハイフン込の文字列として保存',
    email VARCHAR(255) NOT NULL,
    company_id INT(20),
    report_count INT(10) NOT NULL DEFAULT 0,
    plan_status VARCHAR(20) NOT NULL DEFAULT '無料',
    is_withdrawn BOOLEAN NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    society_history INT(2),
    icon INT(20),
    announcement_deletion INT(1) NOT NULL DEFAULT 1 COMMENT '1=新規お知らせなし、2=新規お知らせあり',
    token INT(3) NOT NULL DEFAULT 50 COMMENT '面接練習やメール添削で使用',
    FOREIGN KEY (icon) REFERENCES photos(id)
);

-- ========== TABLE: industries ==========
CREATE TABLE industries (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    industry VARCHAR(50) NOT NULL
);

-- ========== TABLE: companies ==========
CREATE TABLE companies (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15) NOT NULL COMMENT 'ハイフン込の文字列として保存',
    description VARCHAR(255),
    plan_status INT NOT NULL COMMENT '1=加入中、2=中断中',
    is_withdrawn BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL,
    photo_id INT(20),
    FOREIGN KEY (photo_id) REFERENCES photos(id)
);

-- users → companies 外部キー（循環回避のためここで追加）
ALTER TABLE users
    ADD CONSTRAINT fk_users_company FOREIGN KEY (company_id) REFERENCES companies(id);

-- ========== TABLE: subscriptions ==========
CREATE TABLE subscriptions (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id INT(20) NOT NULL,
    plan_name VARCHAR(50) NOT NULL DEFAULT 'プレミアム',
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    is_plan_status BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ========== TABLE: articles ==========
CREATE TABLE articles (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(40) NOT NULL,
    description TEXT NOT NULL,
    company_id INT(20) NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    total_likes INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    photo1_id INT(20),
    photo2_id INT(20),
    photo3_id INT(20),
    FOREIGN KEY (company_id) REFERENCES companies(id),
    FOREIGN KEY (photo1_id) REFERENCES photos(id),
    FOREIGN KEY (photo2_id) REFERENCES photos(id),
    FOREIGN KEY (photo3_id) REFERENCES photos(id)
);

-- ========== TABLE: threads ==========
CREATE TABLE threads (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id INT(20) NOT NULL,
    title VARCHAR(40) NOT NULL,
    type INT(1) NOT NULL COMMENT '1=公式、2=非公式',
    description VARCHAR(255),
    entry_criteria INT(1) NOT NULL COMMENT '1=全員、2=学生のみ、3=社会人のみ',
    last_update_date DATETIME NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ========== TABLE: chats ==========
CREATE TABLE chats (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id INT(20) NOT NULL,
    content TEXT NOT NULL,
    thread_id INT(20) NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at DATETIME,
    created_at DATETIME NOT NULL,
    photo_id INT(20),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (thread_id) REFERENCES threads(id),
    FOREIGN KEY (photo_id) REFERENCES photos(id)
);

-- ========== TABLE: quiz_questions ==========
CREATE TABLE quiz_questions (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    question TEXT NOT NULL,
    is_answer BOOLEAN NOT NULL,
    expanation TEXT NOT NULL
);

-- ========== TABLE: quiz_scores ==========
CREATE TABLE quiz_scores (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id INT(20) NOT NULL,
    score INT(2) NOT NULL,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ========== TABLE: interviews ==========
CREATE TABLE interviews (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    question TEXT NOT NULL,
    type INT(1) NOT NULL COMMENT '1=一般、2=カジュアル、3=圧迫'
);

-- ========== TABLE: phone_exercises ==========
CREATE TABLE phone_exercises (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    example TEXT NOT NULL,
    difficulty INT(1) NOT NULL COMMENT '1=簡単、2=普通、3=難しい'
);

-- ========== TABLE: notifications ==========
CREATE TABLE notifications (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    type INT(1) NOT NULL COMMENT '1=学生, 2=社会人, 3=企業, 4=学生×社会人, 5=学生×企業, 6=社会人×企業, 7=全員, 8=特定のユーザー',
    title VARCHAR(50) NOT NULL,
    content TEXT NOT NULL,
    user_id INT(20),
    created_at DATETIME NOT NULL,
    reservation_time DATETIME,
    send_flag DATETIME,
    send_flag_int INT(1) NOT NULL COMMENT '1=予約, 2=送信完了',
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- ========== TABLE: notices ==========
CREATE TABLE notices (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    from_user_id INT(20) NOT NULL,
    to_user_id INT(20) NOT NULL,
    type INT(1) NOT NULL COMMENT '1=スレッド、2=メッセージ',
    thread_id INT(20),
    chat_id INT(20),
    created_at DATETIME,
    FOREIGN KEY (from_user_id) REFERENCES users(id),
    FOREIGN KEY (to_user_id) REFERENCES users(id),
    FOREIGN KEY (thread_id) REFERENCES threads(id),
    FOREIGN KEY (chat_id) REFERENCES chats(id)
);

-- ========== TABLE: tag ==========
CREATE TABLE tag (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    tag VARCHAR(50) NOT NULL
);

-- ========== TABLE: articles_tag ==========
CREATE TABLE articles_tag (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    article_id INT(20) NOT NULL,
    tag_id INT(20) NOT NULL,
    creation_date DATETIME,
    FOREIGN KEY (article_id) REFERENCES articles(id),
    FOREIGN KEY (tag_id) REFERENCES tag(id)
);

-- ========== TABLE: industry_relations ==========
CREATE TABLE industry_relations (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    type INT(1) NOT NULL COMMENT '1=希望業界、2=所属業界、3=企業所属業界',
    user_id INT(20) NOT NULL,
    target_id INT(20) NOT NULL,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (target_id) REFERENCES industries(id)
);

SET FOREIGN_KEY_CHECKS = 1;

-- ========= INSERT 初期データ =========

INSERT INTO photos (photo_path, user_id) VALUES
('/path/to/photo1.jpg', 1),
('/path/to/photo2.jpg', 2),
('/path/to/photo3.jpg', 3);

INSERT INTO companies (name, address, phone_number, description, plan_status, is_withdrawn, created_at, photo_id) VALUES
('株式会社Bridge', '東京都渋谷区', '03-1234-5678', 'IT企業です', 1, FALSE, NOW(), 1);

INSERT INTO users (nickname, type, password, phone_number, email, company_id, report_count, plan_status, is_withdrawn, created_at, society_history, icon, announcement_deletion) VALUES
('学生ユーザー', 1, 'hashed_password_student', '090-1111-2222', 'student@example.com', NULL, 0, '無料', FALSE, NOW(), NULL, 1, 1),
('社会人ユーザー', 2, 'hashed_password_worker', '080-3333-4444', 'worker@example.com', NULL, 0, '無料', FALSE, NOW(), 5, 2, 1),
('企業ユーザー', 3, 'hashed_password_company', '070-5555-6666', 'company@example.com', 1, 0, '無料', FALSE, NOW(), NULL, 3, 1),
('管理者ユーザー', 4, 'hashed_password_admin', '060-7777-8888', 'admin@example.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1);

INSERT INTO industries (industry) VALUES
('IT'), ('製造業'), ('サービス業'), ('建設業'), ('小売業');

INSERT INTO subscriptions (user_id, plan_name, start_date, end_date, is_plan_status, created_at) VALUES
(1, '無料', NOW(), '2026-01-01', TRUE, NOW()),
(2, 'プレミアム', NOW(), '2026-01-01', TRUE, NOW());

INSERT INTO articles (title, description, company_id, is_deleted, total_likes, created_at, photo1_id) VALUES
('記事タイトル1', '記事説明1', 1, FALSE, 10, NOW(), 1),
('記事タイトル2', '記事説明2', 1, FALSE, 5, NOW(), 2);

INSERT INTO threads (user_id, title, type, description, entry_criteria, last_update_date, is_deleted, created_at) VALUES
(1, '公式スレッド', 1, '公式スレッドの説明', 1, '2025-10-01 12:00:00', FALSE, '2025-09-01 10:00:00'),
(2, '非公式スレッド', 2, '非公式スレッドの説明', 2, '2025-10-01 12:00:00', FALSE, '2025-09-01 10:00:00');

INSERT INTO chats (user_id, content, thread_id, is_deleted, created_at) VALUES
(1, 'チャットメッセージ1', 1, FALSE, NOW()),
(2, 'チャットメッセージ2', 1, FALSE, NOW());

INSERT INTO quiz_questions (question, is_answer, expanation) VALUES
('問題1', TRUE, '解説1'),
('問題2', FALSE, '解説2');

INSERT INTO quiz_scores (user_id, score, created_at) VALUES
(1, 80, NOW()),
(2, 90, NOW());

INSERT INTO interviews (question, type) VALUES
('面接質問1', 1),
('面接質問2', 2);

INSERT INTO phone_exercises (example, difficulty) VALUES
('電話対応例題1', 1),
('電話対応例題2', 2);

INSERT INTO notifications (type, title, content, user_id, created_at, send_flag_int) VALUES
(7, '全体お知らせ', '全体向けのお知らせです', NULL, NOW(), 2),
(1, '学生向けお知らせ', '学生向けのお知らせです', 1, NOW(), 1);

INSERT INTO notices (from_user_id, to_user_id, type, thread_id, chat_id, created_at) VALUES
(1, 2, 1, 1, NULL, NOW()),
(2, 1, 2, NULL, 1, NOW());

INSERT INTO tag (tag) VALUES
('プログラミング'),
('デザイン'),
('ビジネス');

INSERT INTO articles_tag (article_id, tag_id, creation_date) VALUES
(1, 1, NOW()),
(1, 2, NOW()),
(2, 3, NOW());

INSERT INTO industry_relations (type, user_id, target_id, created_at) VALUES
(1, 1, 1, NOW()),
(2, 2, 2, NOW()),
(3, 3, 1, NOW());
