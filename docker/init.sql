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
DROP TABLE IF EXISTS article_likes;
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
    announcement_deletion INT(1) NOT NULL DEFAULT 1 COMMENT '1=新規お知らせなし、2=新規お知らせあり',
    token INT(10) NOT NULL DEFAULT 50 COMMENT '面接練習やメール添削で使用',
    otp VARCHAR(6) COMMENT 'パスワード再設定用ワンタイムパスワード',
    otp_expires_at DATETIME COMMENT 'OTP有効期限'
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

-- テーブル定義書_記事いいね
CREATE TABLE article_likes (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    article_id INT(20) NOT NULL,
    user_id INT(20) NOT NULL,
    created_at DATETIME NOT NULL,
    FOREIGN KEY (article_id) REFERENCES articles(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    UNIQUE KEY unique_article_user (article_id, user_id)
);

-- テーブル定義書_スレッド
CREATE TABLE threads (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    user_id INT(20) NOT NULL,
    title VARCHAR(40) NOT NULL,
    type INT(1) NOT NULL COMMENT '1=公式、2=非公式',
    description VARCHAR(255),
    entry_criteria INT(1) NOT NULL COMMENT '1=全員、2=学生のみ。3=社会人のみ',
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

-- -- テーブル定義書_一問一答
-- CREATE TABLE quiz_questions (
--     id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
--     question TEXT(100) NOT NULL,
--     is_answer BOOLEAN NOT NULL,
--     expanation TEXT(255) NOT NULL
-- );

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
-- CREATE TABLE phone_exercises (
--     id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
--     example TEXT(255) NOT NULL,
--     difficulty INT(1) NOT NULL COMMENT '1=簡単、2=普通、3=難しい'
-- );

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
    category INT(1) NOT NULL COMMENT '1=運営情報, 2=重要',
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
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

-- 画像
-- photos
INSERT INTO photos (photo_path, user_id) VALUES
-- 企業写真（10枚）- user_idはNULL
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_photo.jpg', NULL),      -- ID: 1
('/uploads/photos/Biden_Wind_Co_Ltd_photo.jpg', NULL),           -- ID: 2
('/uploads/photos/Withdrawn_Company_photo.jpg', NULL),           -- ID: 3
('/uploads/photos/Tech_Innovation_Co_Ltd_photo.jpg', NULL),      -- ID: 4
('/uploads/photos/Global_Human_Resources_Services_Co_Ltd_photo.jpg', NULL), -- ID: 5
('/uploads/photos/Environmental_Solution_Co_Ltd_photo.jpg', NULL), -- ID: 6
('/uploads/photos/Education_Plus_Co_Ltd_photo.jpg', NULL),       -- ID: 7
('/uploads/photos/Fintech_Partners_Co_Ltd_photo.jpg', NULL),     -- ID: 8
('/uploads/photos/Medical_Tech_Co_Ltd_photo.jpg', NULL),         -- ID: 9
('/uploads/photos/Smart_City_Solution_Co_Ltd_photo.jpg', NULL),  -- ID: 10
-- 記事写真（16枚）- user_idはNULL
-- 記事ID 1（3枚）
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_post1_no1.jpg', NULL), -- ID: 11
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_post1_no2.jpg', NULL), -- ID: 12
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_post1_no3.jpg', NULL), -- ID: 13
-- 記事ID 2（1枚）
('/uploads/photos/Biden_Wind_Co_Ltd_post2_no1.jpg', NULL),      -- ID: 14
-- 記事ID 3（1枚）
('/uploads/photos/Tech_Innovation_Co_Ltd_post3_no1.jpg', NULL), -- ID: 15
-- 記事ID 4（1枚）
('/uploads/photos/Global_Human_Resources_Services_Co_Ltd_post4_no1.jpg', NULL), -- ID: 16
-- 記事ID 5（3枚）
('/uploads/photos/Environmental_Solution_Co_Ltd_post5_no1.jpg', NULL), -- ID: 17
('/uploads/photos/Environmental_Solution_Co_Ltd_post5_no2.jpg', NULL), -- ID: 18
('/uploads/photos/Environmental_Solution_Co_Ltd_post5_no3.jpg', NULL), -- ID: 19
-- 記事ID 6（3枚）
('/uploads/photos/Education_Plus_Co_Ltd_post6_no1.jpg', NULL),  -- ID: 20
('/uploads/photos/Education_Plus_Co_Ltd_post6_no2.jpg', NULL),  -- ID: 21
('/uploads/photos/Education_Plus_Co_Ltd_post6_no3.jpg', NULL),  -- ID: 22
-- 記事ID 7（1枚）
('/uploads/photos/Fintech_Partners_Co_Ltd_post7_no1.jpg', NULL), -- ID: 23
-- 記事ID 8（1枚）
('/uploads/photos/Medical_Tech_Co_Ltd_post8_no1.jpg', NULL),    -- ID: 24
-- 記事ID 9（1枚）
('/uploads/photos/Smart_City_Solution_Co_Ltd_post9_no1.jpg', NULL), -- ID: 25
-- 記事ID 10（1枚）
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_post10_no1.jpg', NULL); -- ID: 26

-- 企業
-- companies
INSERT INTO companies (name, address, phone_number, description, plan_status, is_withdrawn, created_at, photo_id) VALUES
('株式会社ヤマシタ産業', '東京都渋谷区', '070-5555-5555', '株式会社ヤマシタ産業 は、1978年（昭和53年）創業の総合商社・製造サポート企業です。\n\n創業以来、地域の産業発展とお客様のビジネス成功を第一に考え、物流・資材・機械設備の供給から、製造現場の改善提案まで幅広いサービスを提供しています。\n\n当社は主に以下の事業を展開しています：\n・産業資材の販売\n・物流・在庫管理サービス\n・機械装備の導入支援・保守サービス\n\n私たちは「信頼」「品質」「スピード」を行動指針として、長年培ってきたノウハウとネットワークを生かし、地域社会と企業の成長に貢献しています。', 1, FALSE, NOW(), 1),
('バイデンウィンド株式会社', '大阪府大阪市', '070-6666-6666', 'バイデンウィンド株式会社は、再生可能エネルギー分野に特化した企業です。\n\n主に風力発電事業を展開しており、環境に優しいエネルギーソリューションを提供しています。\n当社の主な事業内容は以下の通りです：\n・風力発電所の企画、設計、建設、運営\n・再生可能エネルギーに関するコンサルティングサービス\n・地域社会との連携による環境保護活動\n\n私たちは、持続可能な社会の実現に向けて、革新的な技術とサービスを提供し、クリーンエネルギーの普及に貢献しています。',1, FALSE, NOW(), 2),
('退会済み企業', '愛知県名古屋市', '070-5555-6666', '退会済み企業の説明文です。企業一覧に表示され、投稿されていた記事も残ります。', 1, TRUE, NOW(), 3),
('テック・イノベーション株式会社', '東京都千代田区', '070-7777-7777', 'テック・イノベーション株式会社は、最先端のAI・機械学習技術を活用したソリューション企業です。\n\nクラウド、ビッグデータ、IoTなど、デジタル変革に必要な技術を提供し、企業のデジタル化を支援しています。\n\n主な事業：\n・AI・機械学習ソリューション開発\n・クラウドインフラ構築\n・データ分析・活用支援', 1, FALSE, NOW(), 4),
('グローバル人材サービス株式会社', '京都府京都市', '070-8888-8888', 'グローバル人材サービス株式会社は、国際的な人材育成・派遣事業を展開する企業です。\n\n多言語対応、文化交流、キャリア開発支援を通じて、グローバル人材の育成と雇用創出に貢献しています。\n\n主な事業：\n・グローバル人材育成\n・人材派遣サービス\n・言語研修・コンサルティング', 1, FALSE, NOW(), 5),
('環境ソリューション株式会社', '福岡県福岡市', '070-9999-9999', '環境ソリューション株式会社は、環境問題への取組みとサステナビリティ実現を目指す企業です。\n\n廃棄物管理、リサイクル事業、環境コンサルティングを通じて、企業のカーボンニュートラル化を支援しています。\n\n主な事業：\n・廃棄物処理・リサイクル\n・環境監査\n・サステナビリティコンサルティング', 1, FALSE, NOW(), 6),
('エデュケーション・プラス株式会社', '大阪府大阪市', '070-1010-1010', 'エデュケーション・プラス株式会社は、教育技術（EdTech）を活用した学習支援企業です。\n\nオンライン教育プラットフォーム、AI学習システム、企業研修サービスを提供し、人材育成を支援しています。\n\n主な事業：\n・オンライン教育プラットフォーム運営\n・AI学習システム開発\n・企業向け研修プログラム', 1, FALSE, NOW(), 7),
('フィンテック・パートナーズ株式会社', '東京都中央区', '070-1111-1111', 'フィンテック・パートナーズ株式会社は、金融テクノロジー分野のリーディング企業です。\n\nデジタル決済、ブロックチェーン技術、金融アナリティクスソリューションを提供し、金融サービスの革新を推進しています。\n\n主な事業：\n・デジタル決済システム\n・ブロックチェーン技術\n・金融データ分析', 1, FALSE, NOW(), 8),
('メディカル・テック株式会社', '名古屋市中区', '070-1212-1212', 'メディカル・テック株式会社は、医療とテクノロジーの融合で、医療の質と効率を向上させる企業です。\n\n医療用ソフトウェア、遠隔診療システム、健康管理アプリを開発し、より良い医療環境の実現に貢献しています。\n\n主な事業：\n・医療用ソフトウェア開発\n・遠隔医療システム\n・健康管理プラットフォーム', 1, FALSE, NOW(), 9),
('スマートシティ・ソリューション株式会社', '東京都港区', '070-1313-1313', 'スマートシティ・ソリューション株式会社は、スマートシティ実現に向けたIoT・AI技術を提供する企業です。\n\nスマートトラフィック、スマート照明、統合管理システムなど、都市の持続可能な発展を支援しています。\n\n主な事業：\n・スマートシティプラットフォーム\n・IoTセンサーソリューション\n・都市データ分析', 1, FALSE, NOW(), 10);

-- ユーザー
-- users
INSERT INTO users (nickname, type, password, phone_number, email, company_id, report_count, plan_status, is_withdrawn, created_at, society_history, icon, announcement_deletion, token) VALUES
-- 学生:type=1
('佐々木一郎', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-1111-1111', 'sasaki@mail.com', NULL, 0, '学生プレミアム', FALSE, NOW(), NULL, NULL, 1, 50),
('安藤花子', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-2222-2222', 'andou@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50),
('理系くん', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-2222-3333', 'rikei@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50),
('文系ちゃん', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-1111-2222', 'bunkei@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50),
('退会済み学生', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-1234-5678', 'stu.delete@mail.com', NULL, 0, '無料', TRUE, NOW(), NULL, NULL, 1, 50),
-- 社会人:type=2
('松井二郎', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-3333-3333', 'matsui@mail.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 5, NULL, 1, 50),
('高田鳥子', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-4444-4444', 'takada@mail.com', NULL, 0, '無料', FALSE, NOW(), 3, NULL, 1, 50),
('残業三昧くん', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-3333-4444', 'zangyou@mail.com', NULL, 0, '無料', FALSE, NOW(), 2, NULL, 1, 50),
('新卒ちゃん', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-3333-4444', 'shinsotsu@mail.com', NULL, 0, '無料', FALSE, NOW(), 1, NULL, 1, 50),
('退会済み社会人', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-4444-5555', 'wor.delete@mail.com', NULL, 0, '無料', TRUE, NOW(), 6, NULL, 1, 50),
-- 企業:type=3
('株式会社ヤマシタ産業', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-5555-5555', 'yamashita@mail.com', 1, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50),
('バイデンウィンド株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-6666-6666', 'umeda@mail.com', 2, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50),
('退会済み企業', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-5555-6666', 'com.delete@mail.com', 3, 0, '企業プレミアム', TRUE, NOW(), NULL, NULL, 1, 50),
-- 管理者:type=4
('管理者-森本四郎', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-7777-7777', 'morimoto@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50),
('管理者-西川月子', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-8888-8888', 'nishikawa@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50),

-- 通報用
('違反スゴ助', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-1234-5678', 'notices@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50),

-- 企業や記事用追加企業
('テック・イノベーション株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-7777-7777', 'techinnovation@mail.com', 4, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50),
('グローバル人材サービス株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-8888-8888', 'global@mail.com', 5, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50),
('環境ソリューション株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-9999-9999', 'ecosolution@mail.com', 6, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50),
('エデュケーション・プラス株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-1010-1010', 'education@mail.com', 7, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50),
('フィンテック・パートナーズ株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-1111-1111', 'fintech@mail.com', 8, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50),
('メディカル・テック株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-1212-1212', 'medtech@mail.com', 9, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50),
('スマートシティ・ソリューション株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-1313-1313', 'smartcity@mail.com', 10, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50);

-- 業界
-- industries
INSERT INTO industries (industry) VALUES
('メーカー'),
('商社'),
('流通・小売'),
('金融'),
('サービス・インフラ'),
('ソフトウェア・通信'),
('広告・出版・マスコミ'),
('官公庁・公社・団体');

-- サブスクリプション
-- subscriptions
INSERT INTO subscriptions (user_id, plan_name, start_date, end_date, is_plan_status, created_at) VALUES
(1, '学生プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(6, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(11, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(12, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(13, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW());

-- 記事
-- articles
INSERT INTO articles (title, description, company_id, is_deleted, total_likes, created_at, photo1_id, photo2_id, photo3_id) VALUES
('会社説明会のお知らせ', 'みなさんこんにちは！当社ではオンライン会社説明会を随時開催中です。\n-----２月のスケジュール-----\n・５日（月）11:00～12:30\n・７日（水）10:00～11:30\n・１５日（木）11:00～12:30\n・２０日（火）13:00～14:30\n・２３日（金）10:00～11:30\n\n本社採用サイトからエントリーをお願いいたします。\nurl=httqs://www.yamashita_sangyou.recruit \n\n\n皆様のご参加お待ちしています！', 1, FALSE, 10, NOW(), 11, 12, 13),  -- photo1_id=11, photo2_id=12, photo3_id=13
('スレッドを開設しました', 'みなさんこんにちは。本日「バイデンウィンド（株）」のスレッドを開設しました。\n\n就職活動に関する質問等、採用担当の者がお答えします！\n採用には一切影響いたしませんので、お気軽にご参加ください。\nみなさんの投稿お待ちしています！', 2, FALSE, 5, NOW(), 14, NULL, NULL),  -- photo1_id=14
('AI・機械学習技術セミナーのご案内', 'テック・イノベーション株式会社では、最先端のAI・機械学習技術に関するセミナーを開催いたします。\n業界の第一線の専門家による講演会を予定しており、参加者には特別な情報をお得にご提供いたします。\nご興味のある方は、ぜひお気軽にお申し込みください。', 4, FALSE, 0, NOW(), 15, NULL, NULL),  -- photo1_id=15
('国際人材育成プログラム2026年開始', 'グローバル人材サービス株式会社では、2026年度の国際人材育成プログラムの参加者を募集しています。\n多言語対応・文化交流・キャリア形成支援など、充実した研修内容を用意しております。\nこのプログラムを通じてグローバルに活躍できる人材へとステップアップしませんか？', 5, FALSE, 0, NOW(), 16, NULL, NULL),  -- photo1_id=16
('環境配慮型製品ラインアップ拡充', '環境ソリューション株式会社では、持続可能な社会実現に向けた新製品をリリースいたします。\n廃棄物処理・リサイクル・環境監査を統合したソリューションで、企業のカーボンニュートラル化を支援します。\n環境への取り組みを始めたい企業様との協力をお待ちしています。', 6, FALSE, 0, NOW(), 17, 18, 19),  -- photo1_id=17, photo2_id=18, photo3_id=19

('EdTech新サービス「AI学習サポート」ベータ版開始', 'エデュケーション・プラス株式会社が新しいAI学習支援システムのベータ版を公開いたします。\nタブレットやPCで利用可能な本システムは、個人の学習進度に合わせた最適なカリキュラムを提供します。\n無料トライアルもご用意しておりますので、ぜひお試しください。', 7, FALSE, 0, NOW(), 20, 21, 22),  -- photo1_id=20, photo2_id=21, photo3_id=22
('フィンテック・パートナーズ新規事業説明会', 'デジタル決済・ブロックチェーン技術を活用したフィンテック・パートナーズより、新規事業についての説明会を開催いたします。\n金融DXに興味のある学生・社会人の皆様ご参加ください。\n企業説明・選考対策セッションも同時開催予定です。', 8, FALSE, 0, NOW(), 23, NULL, NULL),  -- photo1_id=23
('メディカル・テック医療従事者向けセミナー開催', 'メディカル・テック株式会社では、医療現場でのデジタル化について学ぶセミナーを開催いたします。\n遠隔診療・患者データ管理・医療AIなど、最新の医療テクノロジーについてのお話となります。\n医療業界への就職を検討されている方もぜひご参加ください。', 9, FALSE, 0, NOW(), 24, NULL, NULL),  -- photo1_id=24
('スマートシティ技術説明会・インターン募集', 'スマートシティ・ソリューション株式会社は、IoT・AI技術を活用した都市構想についての説明会を実施いたします。\nあわせて、2026年夏期インターンシップの参加者も募集中です。\nスマートシティの実現に携わりたい皆様のご応募をお待ちしています。', 10, FALSE, 0, NOW(), 25, NULL, NULL),  -- photo1_id=25
('株式会社ヤマシタ産業 新卒採用開始のお知らせ', '株式会社ヤマシタ産業では、2026年度新卒採用を開始いたしました。\n製造業界に興味のある学生の皆様、ぜひ当社の採用情報をご覧ください。\nエントリーは当社採用サイトからお願いいたします。', 1, FALSE, 0, NOW(), 26, NULL, NULL);  -- photo1_id=26

-- スレッド
-- threads
-- entry_criteria: 1=全員、2=学生のみ。3=社会人のみ
INSERT INTO threads (user_id, title, type, description, entry_criteria, last_update_date, is_deleted, created_at) VALUES
-- 公式スレッド:type=1,userid=14(管理者)
(14, '学生×社会人スレッド', 1, 'こちらは、学生と社会人の公式スレッドです。どなたでも参加できます。', 1, NOW(), FALSE, NOW()),
(14, '学生スレッド', 1, 'こちらは、学生の方のみの公式スレッドです。学生の方はどなたでも参加できます。', 2, NOW(), FALSE, NOW()),
(14, '社会人スレッド', 1, 'こちらは、社会人の方のみの公式スレッドです。社会人の方はどなたでも参加できます。', 3, NOW(), FALSE, NOW()),
-- 非公式スレッド:type=2,userid=各ユーザー,
(2, '27卒の就活相談室', 2, '27卒の学生同士で就活について情報交換や相談ができる場です。気軽に参加してください！', 2, NOW(), FALSE, NOW()),
(4, '就活って何から始めたらいいですか？', 2, '27卒の文系です。まだ希望業界も定まっておらず焦っています。経験談などあれば教えてください！', 2, NOW(), FALSE, NOW()),

(8, '面接の練習方法を教えてください', 2, '社会人2年目です。転職活動中ですが、面接が苦手で困っています。効果的な練習方法があれば教えてください。', 3, NOW(), FALSE, NOW()),
(1, '自己PRの書き方について', 2, '就活中の大学4年生です。自己PRの書き方に悩んでいます。良い例やアドバイスがあれば教えてください。', 2, NOW(), FALSE, NOW()),
(6, '資格取得のおすすめ', 2, '社会人3年目です。キャリアアップのために資格取得を考えています。おすすめの資格や勉強法があれば教えてください。', 3, NOW(), FALSE, NOW()),
(16, '27卒と話したい！', 2, 'このスレッドは不適切な内容を含んでいます。通報テスト用スレッドです。', 1, NOW(), TRUE, NOW()),
(11, '株式会社ヤマシタ産業スレッド', 2, '株式会社ヤマシタ産業の採用に関する質問はこちらでどうぞ！', 1, NOW(), FALSE, NOW()),

(12, 'バイデンウィンド株式会社スレッド', 2, 'バイデンウィンド株式会社の採用に関する質問はこちらでどうぞ！', 1, NOW(), FALSE, NOW()),
(9, '新卒だけどもうやめたい', 2, 'まだ一年も経っていないのに、辞めちゃって経歴に傷がつくのは嫌だけど、続けられる自信もない・・・', 3, NOW(), FALSE, NOW()),
(10, 'リモートワークのメリット・デメリット', 2, 'リモートワークが増えてきたけど、実際どうなんだろう？経験者の意見を聞きたいです。', 3, NOW(), FALSE, NOW()),
(13, '副業ってどう思いますか？', 2, '副業を始めたいけど、会社にバレないか心配です。経験者の意見を聞きたいです。', 3, NOW(), FALSE, NOW()),
(15, '転職活動の進め方', 2, '転職を考えていますが、何から始めたらいいのか分かりません。アドバイスをお願いします。', 3, NOW(), FALSE, NOW());

-- チャット
-- chats
INSERT INTO chats (user_id, content, thread_id, is_deleted, deleted_at, created_at, photo_id) VALUES
(8, '最近就活の早期化が進みすぎだと思う。', 1, FALSE, NULL, NOW(), NULL),
(3, '27卒に人気の業界ってどこ？やっぱりITかな。', 1, FALSE, NULL, NOW(), NULL),
(5, '私は金融業界を志望してるよ。安定してるし、将来性もあるからね。', 1, FALSE, NULL, NOW(), NULL),
(1, 'インフル流行ってて怖い。オンライン面接にしてくれてる企業嬉しい', 2, FALSE, NULL, NOW(), NULL),
(4, '就活のモチベがないんだよなー特にやりたいこともないし。', 2, FALSE, NULL, NOW(), NULL),

(2, 'わかる気がする。別に働かずに済むなら働かないもんな～', 2, FALSE, NULL, NOW(), NULL),
(8, '残業やばくて転職したいけど、そんな時間すらない。', 3, FALSE, NULL, NOW(), NULL),
(6, 'それなら体壊す前に辞めてしまうのも手だと思う。健康第一。', 3, FALSE, NULL, NOW(), NULL),
(7, 'ほんとにそう。体壊してからじゃ遅いよ～', 3, FALSE, NULL, NOW(), NULL),
(4, '私は自己分析から始めたよ。自分の強み弱みを理解するのが大事かなって。', 4, FALSE, NULL, NOW(), NULL),

(1, '自己分析ってどうやるの？本とか読むの？', 4, FALSE, NULL, NOW(), NULL),
(5, '私は友達とか家族に自分の良いところ聞いたりしたよ。意外な発見があるかも。', 4, FALSE, NULL, NOW(), NULL),
(2, 'あとは、過去の経験を振り返ってみるのもいいよ。成功体験とか失敗体験とか。', 4, FALSE, NULL, NOW(), NULL),
(6, '答えを暗記するのはあんまりおすすめしないな～', 5, FALSE, NULL, NOW(), NULL),
(2, 'それこそ、ここのAI練習に面接練習あるからやってみたらいい。', 5, FALSE, NULL, NOW(), NULL),

(3, '俺もたまーにやってる！色々フィードバックくれるからいいよ', 5, FALSE, NULL, NOW(), NULL),
(8, '確かに繰り返し練習するのが一番効果的かも。', 5, FALSE, NULL, NOW(), NULL),
(2, '自分の話したいことエピソードやアピールポイントをちゃんと固めておくことかな。', 5, FALSE, NULL, NOW(), NULL),
(1, 'そもそも自己PRと自分の強みって何が違うの？', 6, FALSE, NULL, NOW(), NULL),
(7, '自己PRは具体的なエピソードを交えた方がいい。サークル、ゼミ、バイト何でもいいから経験を話すべき。', 6, FALSE, NULL, NOW(), NULL),

(2, '私は資格勉強のこと話した！自分が一番頑張ったものをいえばいいよ。', 6, FALSE, NULL, NOW(), NULL),
(6, '資格は業界によるけど、IT系なら基本情報技術者とか持ってると有利かも。', 7, FALSE, NULL, NOW(), NULL),
(7, '社会人になるとなかなか勉強する時間取れないから、計画的に進めるのが大事だよね。', 7, FALSE, NULL, NOW(), NULL),
(16, '27卒の理系です！同じ卒業年度の方としたいです！選考状況など共有してくれるとモチベになります！', 8, FALSE, NULL, NOW(), NULL),
(3, '文系27卒です！よろしくお願いします', 8, FALSE, NULL, NOW(), NULL),

(4, '27卒理系です。今内定2社です。', 8, FALSE, NULL, NOW(), NULL),
(2, '私は商社志望で今3社から内定もらってるよ！', 8, FALSE, NULL, NOW(), NULL),
(16, 'いいね～！SNS交換したい！', 8, FALSE, NULL, NOW(), NULL);

-- クイズ
-- quiz_questions
-- INSERT INTO quiz_questions (question, is_answer, expanation) VALUES
-- ('問題1', TRUE, '解説1'),
-- ('問題2', FALSE, '解説2');

-- quiz_scores
INSERT INTO quiz_scores (user_id, score, created_at) VALUES
(1, 80, NOW()),
(6, 90, NOW());


-- interviews 初期データ挿入
INSERT INTO interviews (question, type) VALUES
-- 一般質問 20問
('自己紹介をお願いします。', 1),
('あなたの強みと弱みを教えてください。', 1),
('学生時代に力を入れたことは何ですか？', 1),
('志望動機を教えてください。', 1),
('今までの経験で最も困難だったことは何ですか？', 1),
('チームで取り組んだ経験について教えてください。', 1),
('短所を克服した経験はありますか？', 1),
('5年後のキャリアプランを教えてください。', 1),
('仕事で大切にしている価値観は何ですか？', 1),
('失敗から学んだことはありますか？', 1),
('リーダー経験はありますか？具体的に教えてください。', 1),
('ストレスをどのように管理していますか？', 1),
('あなたが尊敬する人物は誰ですか？', 1),
('最近学んだことで印象に残ったことは何ですか？', 1),
('どのような環境で力を発揮できますか？', 1),
('自分を一言で表すと何ですか？', 1),
('困難な状況での意思決定の経験はありますか？', 1),
('学生時代の趣味や特技について教えてください。', 1),
('仕事を通して実現したいことは何ですか？', 1),
('チーム内での役割について意識していることは何ですか？', 1),

-- カジュアル質問 20問
('最近ハマっていることは何ですか？', 2),
('休日の過ごし方を教えてください。', 2),
('最近読んだ本や記事で印象に残ったことは？', 2),
('友人や同僚からどんな人と言われますか？', 2),
('学生時代に楽しかった思い出は何ですか？', 2),
('これまでに挑戦したことは何ですか？', 2),
('自分を動物に例えると何ですか？', 2),
('これまでに影響を受けた映画やドラマは？', 2),
('理想の一日を教えてください。', 2),
('好きな仕事のスタイルは何ですか？', 2),
('座右の銘や大切にしている言葉はありますか？', 2),
('尊敬する友人や家族はいますか？', 2),
('最近のニュースで関心を持ったものは？', 2),
('あなたにとって仕事とは何ですか？', 2),
('これまでに感動した出来事は何ですか？', 2),
('好きなスポーツや運動は何ですか？', 2),
('普段から意識している健康法はありますか？', 2),
('最近挑戦してみたいことは何ですか？', 2),
('自分の長所を活かせる場面はどんなときですか？', 2),
('働く上で大切にしていることは何ですか？', 2),

-- 圧迫質問 20問
('なぜ他の候補者よりあなたを採用すべきですか？', 3),
('あなたの弱みは致命的だと思いませんか？', 3),
('この会社で結果を出せる自信はありますか？', 3),
('これまでの経験で失敗したことは何ですか？', 3),
('当社の業務に適応できると思いますか？', 3),
('あなたのスキルは当社には不十分では？', 3),
('短期間で成果を出す自信はありますか？', 3),
('他に優秀な候補者がいる中で、あなたの強みは何ですか？', 3),
('残業やプレッシャーに耐えられますか？', 3),
('学生時代の失敗をどう会社で活かせますか？', 3),
('入社してもすぐに辞めるのでは？', 3),
('他社でも同じ質問をされていると思いますが、何が違いますか？', 3),
('あなたの提案は現実的だと思いますか？', 3),
('チーム内でうまくやれなかった経験は？', 3),
('あなたにこの仕事は向いていないのでは？', 3),
('結果を出せなかった場合、どう責任を取りますか？', 3),
('上司の指示に納得できない場合どうしますか？', 3),
('他の社員に比べて経験不足では？', 3),
('この業界でやっていける自信はありますか？', 3),
('あなたの計画は非現実的ではありませんか？', 3);


-- phone_exercises
-- INSERT INTO phone_exercises (example, difficulty) VALUES
-- ('電話対応例題1', 1),
-- ('電話対応例題2', 2);

-- notifications
INSERT INTO notifications (type, title, content, user_id, created_at, reservation_time, send_flag, send_flag_int, category, is_deleted) VALUES
(7, 'ご登録ありがとうございます！', 'Bridgeにご登録いただきありがとうございます。', NULL, NOW(), NULL, NOW(), 2, 1, FALSE),
(4, 'Bridgeの使い方', 'Bridgeではさまざまな機能がご利用いただけます。\nAI練習\nAI練習では、トークンを消費して面接練習・電話対応練習・メール添削が行えます。\nまた、プレミアムプランに加入することでトークンを増やすことができます。\n\n一問一答\n一問一答では、社会人なら知っていて当然のマナーや言葉遣いを〇✕で回答します。\n\nスレッドでは、他のユーザーと交流が出来ます。非公式スレッドを作成することもできるので、気軽にスレッドを作ってみましょう。\n\n企業情報では、Bridgeに参加している企業の記事や企業情報を閲覧できます。', NULL, NOW(), NULL, NOW(), 1, 1, FALSE);

-- notices
INSERT INTO notices (from_user_id, to_user_id, type, thread_id, chat_id, created_at) VALUES
(3, 16, 1, 8, NULL, NOW()),
(4, 16, 2, NULL, 28, NOW()),
(2, 16, 2, NULL, 28,NOW());

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
(2, 14, NOW()); -- 記事2 に「スレッド開設」

-- industry_relations
INSERT INTO industry_relations (type, user_id, target_id, created_at) VALUES
(1, 1, 1, NOW()),
(1, 1, 3, NOW()),
(1, 2, 2, NOW()),
(1, 3, 1, NOW()),
(1, 3, 2, NOW()),
(1, 4, 6, NOW()),
(1, 4, 7, NOW()),
(1, 5, 4, NOW()),
(2, 6, 1, NOW()),
(2, 7, 3, NOW()),
(2, 8, 2, NOW()),
(2, 9, 6, NOW()),
(2, 10, 7, NOW()),
(3, 11, 1, NOW()),
(3, 11, 3, NOW()),
(3, 12, 1, NOW()),
(3, 12, 5, NOW()),
(3, 13, 4, NOW()),
(3, 14, 6, NOW()),
(3, 14, 1, NOW()),
(3, 15, 1, NOW()),
(3, 15, 7, NOW()),
(3, 16, 5, NOW()),
(3, 17, 4, NOW()),
(3, 17, 2, NOW()),
(3, 18, 2, NOW()),
(3, 19, 3, NOW()),
(3, 19, 5, NOW()),
(3, 20, 6, NOW()),
(3, 20, 1, NOW()),
(3, 21, 4, NOW()),
(3, 21, 7, NOW()),
(3, 22, 2, NOW()),
(3, 22, 3, NOW()),
(3, 23, 5, NOW()),
(3, 23, 6, NOW());

SET FOREIGN_KEY_CHECKS = 1;