-- init.sql
-- このファイルは、MySQLデータベースの初期化スクリプトです。
-- Dockerコンテナが起動する際に自動的に実行され、データベースの作成、テーブルの定義、
-- および初期データの挿入を行います。
--
-- チームメンバーへ:
--   - データベースのスキーマ変更や初期データの追加は、このファイルを編集することで行えます。
--   - `DROP TABLE IF EXISTS users;` は開発中にテーブル構造を頻繁に変更する場合に便利ですが、
--     本番環境ではデータが失われる可能性があるため注意が必要です。

SET FOREIGN_KEY_CHECKS = 0;

-- データベースが存在しない場合のみ作成
CREATE DATABASE IF NOT EXISTS bridgedb;
-- bridgedbデータベースを使用
USE bridgedb;

-- 既存のテーブルがあれば削除 (開発用)
DROP TABLE IF EXISTS articles_tag;
DROP TABLE IF EXISTS articles;
DROP TABLE IF EXISTS notices;
DROP TABLE IF EXISTS chats;
DROP TABLE IF EXISTS threads;
DROP TABLE IF EXISTS subscriptions;
DROP TABLE IF EXISTS notices;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS quiz_scores;
DROP TABLE IF EXISTS industry_relations;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS companies;
DROP TABLE IF EXISTS industries;
DROP TABLE IF EXISTS interviews;
DROP TABLE IF EXISTS phone_exercises;
DROP TABLE IF EXISTS photos;
DROP TABLE IF EXISTS quiz_questions;
DROP TABLE IF EXISTS tag;

-- テーブル定義書_ユーザー
CREATE TABLE users (
    id INT(20) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nickname VARCHAR(100) NOT NULL,
    type INT(1) NOT NULL COMMENT '1=学生、2=社会人、3=企業、4=管理者',
    password VARCHAR(255) NOT NULL COMMENT 'ハッシュ化',
    phone_number VARCHAR(15) NOT NULL COMMENT 'ハイフン込の文字列として保存',
    email VARCHAR(255) NOT NULL,
    company_id INT(10),
    report_count INT(10) NOT NULL DEFAULT 0,
    plan_status VARCHAR(20) NOT NULL DEFAULT '無料',
    is_withdrawn BOOLEAN NOT NULL,
    created_at DATETIME NOT NULL,
    society_history INT(2),
    icon INT(10),
    announcement_deletion INT(1) NOT NULL DEFAULT 1 COMMENT '1=新規お知らせなし、2=新規お知らせあり'
);


-- テーブル定義書_業界
CREATE TABLE industries (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    industry VARCHAR(50) NOT NULL
);

-- テーブル定義書_業界中間
CREATE TABLE industry_relations (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    type INT(1) NOT NULL COMMENT '1=希望業界、2=所属業界、3=企業所属業界',
    user_id INT(20) NOT NULL,
    target_id INT(20) NOT NULL,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (target_id) REFERENCES industries(id)
);

-- テーブル定義書_サブスク
CREATE TABLE subscriptions (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT(20) NOT NULL,
    plan_name VARCHAR(50) NOT NULL DEFAULT 'プレミアム',
    start_date DATETIME NOT NULL COMMENT 'サブスク加入日',
    end_date DATETIME NOT NULL COMMENT 'サブスク終了日（予定も含む）',
    is_plan_status BOOLEAN NOT NULL DEFAULT TRUE COMMENT '加入中：true 中断中：false',
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- テーブル定義書_企業情報
CREATE TABLE companies (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15) NOT NULL COMMENT 'ハイフン込の文字列として保存',
    description VARCHAR(255),
    plan_status INT NOT NULL COMMENT '1=加入中、2=中断中',
    is_withdrawn BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL,
    photo_id INT(10)
);

-- テーブル定義書_記事
CREATE TABLE articles (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    title VARCHAR(40) NOT NULL,
    description TEXT(2000) NOT NULL,
    company_id INT(20) NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    total_likes INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL,
    photo1_id INT(10),
    photo2_id INT(10),
    photo3_id INT(10),
    FOREIGN KEY (company_id) REFERENCES companies(id)
);

-- テーブル定義書_スレッド
CREATE TABLE threads (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT(20) NOT NULL,
    title VARCHAR(40) NOT NULL,
    type INT(1) NOT NULL COMMENT '1=公式、2=非公式',
    description VARCHAR(255),
    entry_criteria INT(1) NOT NULL COMMENT '1=全員、2=学生のみ。3=社会人のみ',
    industry VARCHAR(20),
    last_update_date DATETIME NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- テーブル定義書_チャット
CREATE TABLE chats (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT(20) NOT NULL,
    content TEXT(255) NOT NULL,
    thread_id INT(20) NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    deleted_at DATETIME,
    created_at DATETIME NOT NULL,
    photo_id INT(10),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (thread_id) REFERENCES threads(id)
);

-- テーブル定義書_写真
CREATE TABLE photos (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    photo_path VARCHAR(255) NOT NULL,
    user_id INT(20)
);

-- テーブル定義書_一問一答
CREATE TABLE quiz_questions (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    question TEXT(100) NOT NULL,
    is_answer BOOLEAN NOT NULL,
    expanation TEXT(255) NOT NULL
);

-- テーブル定義書_一問一答スコア
CREATE TABLE quiz_scores (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT(20) NOT NULL,
    score INT(2) NOT NULL,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- テーブル定義書_面接
CREATE TABLE interviews (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    question TEXT(255) NOT NULL,
    type INT(1) NOT NULL COMMENT '1=一般、2=カジュアル、3=圧迫'
);

-- テーブル定義書_電話対応
CREATE TABLE phone_exercises (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    example TEXT(255) NOT NULL,
    difficulty INT(1) NOT NULL COMMENT '1=簡単、2=普通、3=難しい'
);

-- テーブル定義書_お知らせテーブル
CREATE TABLE notifications (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    type INT(1) NOT NULL COMMENT '1=学生, 2=社会人, 3=企業, 4=学生×社会人, 5=学生×企業, 6=社会人×企業, 7=全員, 8=特定のユーザー',
    title VARCHAR(50) NOT NULL,
    content TEXT(2000) NOT NULL,
    user_id INT(20),
    created_at DATETIME NOT NULL,
    reservation_time DATETIME,
    send_flag DATETIME COMMENT '送信フラグが2になった時の日付',
    send_flag_int INT(1) NOT NULL COMMENT '1=予約, 2=送信完了',
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- テーブル定義書_通報テーブル
CREATE TABLE notices (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
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

-- テーブル定義書_記事タグ中間テーブル
CREATE TABLE articles_tag (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    article_id INT(20) NOT NULL,
    tag_id INT(20) NOT NULL,
    creation_date DATETIME,
    FOREIGN KEY (article_id) REFERENCES articles(id)
);

-- テーブル定義書_タグテーブル
CREATE TABLE tag (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    tag VARCHAR(50) NOT NULL
);

-- 外部キー制約の追加 (photosテーブルを参照するテーブル)
ALTER TABLE users
ADD CONSTRAINT fk_users_company_id FOREIGN KEY (company_id) REFERENCES companies(id),
ADD CONSTRAINT fk_users_icon FOREIGN KEY (icon) REFERENCES photos(id);

ALTER TABLE companies
ADD CONSTRAINT fk_companies_photo_id FOREIGN KEY (photo_id) REFERENCES photos(id);

ALTER TABLE articles
ADD CONSTRAINT fk_articles_photo1_id FOREIGN KEY (photo1_id) REFERENCES photos(id),
ADD CONSTRAINT fk_articles_photo2_id FOREIGN KEY (photo2_id) REFERENCES photos(id),
ADD CONSTRAINT fk_articles_photo3_id FOREIGN KEY (photo3_id) REFERENCES photos(id);

ALTER TABLE chats
ADD CONSTRAINT fk_chats_photo_id FOREIGN KEY (photo_id) REFERENCES photos(id);

ALTER TABLE industry_relations
ADD CONSTRAINT fk_industry_relations_user_id FOREIGN KEY (user_id) REFERENCES users(id),
ADD CONSTRAINT fk_industry_relations_target_id FOREIGN KEY (target_id) REFERENCES industries(id);

ALTER TABLE articles_tag
ADD CONSTRAINT fk_articles_tag_tag_id FOREIGN KEY (tag_id) REFERENCES tag(id);
-- 仮データ挿入
-- photos
INSERT INTO photos (photo_path, user_id) VALUES
('/path/to/photo1.jpg', 1),
('/path/to/photo2.jpg', 2),
('/path/to/photo3.jpg', 3);

-- users
-- companies
INSERT INTO companies (name, address, phone_number, description, plan_status, is_withdrawn, created_at, photo_id) VALUES
('株式会社Bridge', '東京都渋谷区', '03-1234-5678', 'IT企業です', 1, FALSE, NOW(), 1);

-- users
INSERT INTO users (nickname, type, password, phone_number, email, company_id, report_count, plan_status, is_withdrawn, created_at, society_history, icon, announcement_deletion) VALUES
('学生ユーザー', 1, 'hashed_password_student', '090-1111-2222', 'student@example.com', NULL, 0, '無料', FALSE, NOW(), NULL, 1, 1),
('社会人ユーザー', 2, 'hashed_password_worker', '080-3333-4444', 'worker@example.com', NULL, 0, '無料', FALSE, NOW(), 5, 2, 1),
('企業ユーザー', 3, 'hashed_password_company', '070-5555-6666', 'company@example.com', 1, 0, '無料', FALSE, NOW(), NULL, 3, 1),
('管理者ユーザー', 4, 'hashed_password_admin', '060-7777-8888', 'admin@example.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1);

-- industries
INSERT INTO industries (industry) VALUES
('IT'),
('製造業'),
('サービス業');

-- subscriptions
INSERT INTO subscriptions (user_id, plan_name, start_date, end_date, is_plan_status, created_at) VALUES
(1, '無料', NOW(), '2026-01-01 00:00:00', TRUE, NOW()),
(2, 'プレミアム', NOW(), '2026-01-01 00:00:00', TRUE, NOW());

-- articles
INSERT INTO articles (title, description, company_id, is_deleted, total_likes, created_at, photo1_id, photo2_id, photo3_id) VALUES
('記事タイトル1', '記事説明1', 1, FALSE, 10, NOW(), 1, NULL, NULL),
('記事タイトル2', '記事説明2', 1, FALSE, 5, NOW(), NULL, 2, NULL);

-- threads
INSERT INTO threads (user_id, title, type, description, entry_criteria, industry, last_update_date, is_deleted, created_at) VALUES
(1, '公式スレッド', 1, '公式スレッドの説明', 1, 'IT', NOW(), FALSE, NOW()),
(2, '非公式スレッド', 2, '非公式スレッドの説明', 2, '製造業', NOW(), FALSE, NOW());

-- chats
INSERT INTO chats (user_id, content, thread_id, is_deleted, deleted_at, created_at, photo_id) VALUES
(1, 'チャットメッセージ1', 1, FALSE, NULL, NOW(), NULL),
(2, 'チャットメッセージ2', 1, FALSE, NULL, NOW(), NULL);

-- quiz_questions
INSERT INTO quiz_questions (question, is_answer, expanation) VALUES
('問題1', TRUE, '解説1'),
('問題2', FALSE, '解説2');

-- quiz_scores
INSERT INTO quiz_scores (user_id, score, created_at) VALUES
(1, 80, NOW()),
(2, 90, NOW());

-- interviews
INSERT INTO interviews (question, type) VALUES
('面接質問1', 1),
('面接質問2', 2);

-- phone_exercises
INSERT INTO phone_exercises (example, difficulty) VALUES
('電話対応例題1', 1),
('電話対応例題2', 2);

-- notifications
INSERT INTO notifications (type, title, content, user_id, created_at, reservation_time, send_flag, send_flag_int) VALUES
(7, '全体お知らせ', '全体向けのお知らせです', NULL, NOW(), NULL, NULL, 2),
(1, '学生向けお知らせ', '学生向けのお知らせです', 1, NOW(), '2025-11-05 10:00:00', NULL, 1);

-- notices
INSERT INTO notices (from_user_id, to_user_id, type, thread_id, chat_id, created_at) VALUES
(1, 2, 1, 1, NULL, NOW()),
(2, 1, 2, NULL, 1, NOW());

-- tag
INSERT INTO tag (tag) VALUES
('説明会開催中'),
('会社員の日常'),
('インターン開催中'),
('就活イベント情報'),
('新卒募集中'),
('全社員のご紹介'),
('エンジニア採用'),
('会社紹介'),
('新卒社員のリアル'),
('先輩インタビュー'),
('新人社員インタビュー'),
('社内イベント'),
('最新ニュース'),
('スレッド開設'),
('キャリアアドバイス'),
('面接のコツ'),
('社員の推しポイント');

-- articles_tag
INSERT INTO articles_tag (article_id, tag_id, creation_date) VALUES
(1, 1, NOW()), -- 記事1 に「説明会開催中」
(1, 8, NOW()), -- 記事1 に「会社紹介」
(2, 14, NOW()), -- 記事2 に「スレッド開設」
(2, 2, NOW()); -- 記事2 に「会社員の日常」

-- industry_relations
INSERT INTO industry_relations (type, user_id, target_id, created_at) VALUES
(1, 1, 1, NOW()),
(2, 2, 2, NOW()),
(3, 3, 1, NOW());

SET FOREIGN_KEY_CHECKS = 1;