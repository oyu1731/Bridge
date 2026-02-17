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
    description TEXT,
    plan_status INT NOT NULL COMMENT '1=加入中、2=中断中',
    is_withdrawn BOOLEAN NOT NULL DEFAULT FALSE,
    created_at DATETIME NOT NULL,
    photo_id INT(10)
);

-- テーブル定義書_記事
CREATE TABLE articles (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    title VARCHAR(40) NOT NULL,
    description TEXT NOT NULL,
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
    FOREIGN KEY (user_id) REFERENCES users(id),
    nickname VARCHAR(100) NOT NULL
);

-- テーブル定義書_面接
CREATE TABLE interviews (
    id INT(20) PRIMARY KEY NOT NULL AUTO_INCREMENT,
    question TEXT(255) NOT NULL,
    type INT(1) NOT NULL COMMENT '1=一般、2=カジュアル、3=圧迫'
);

-- -- テーブル定義書_電話対応
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
-- photos
INSERT INTO photos (photo_path, user_id) VALUES
-- デフォルト初期アイコン
('/uploads/photos/Defalut_icon.jpg', NULL),
-- 企業写真（10枚）- user_idはNULL
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_photo.jpg', NULL),      -- ID: 2
('/uploads/photos/Biden_Wind_Co_Ltd_photo.jpg', NULL),           -- ID: 3
('/uploads/photos/Withdrawn_Company_photo.jpg', NULL),           -- ID: 4
('/uploads/photos/Tech_Innovation_Co_Ltd_photo.jpg', NULL),      -- ID: 5
('/uploads/photos/Global_Human_Resources_Services_Co_Ltd_photo.jpg', NULL), -- ID: 6
('/uploads/photos/Environmental_Solution_Co_Ltd_photo.jpg', NULL), -- ID: 7
('/uploads/photos/Education_Plus_Co_Ltd_photo.jpg', NULL),       -- ID: 8
('/uploads/photos/Fintech_Partners_Co_Ltd_photo.jpg', NULL),     -- ID: 9
('/uploads/photos/Medical_Tech_Co_Ltd_photo.jpg', NULL),         -- ID: 10
('/uploads/photos/Smart_City_Solution_Co_Ltd_photo.jpg', NULL),  -- ID: 11
-- 記事写真（16枚）- user_idはNULL
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_post1_no1.jpg', NULL), -- ID: 12
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_post1_no2.jpg', NULL), -- ID: 13
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_post1_no3.jpg', NULL), -- ID: 14
('/uploads/photos/Biden_Wind_Co_Ltd_post2_no1.jpg', NULL),      -- ID: 15
('/uploads/photos/Tech_Innovation_Co_Ltd_post3_no1.jpg', NULL), -- ID: 16
('/uploads/photos/Global_Human_Resources_Services_Co_Ltd_post4_no1.jpg', NULL), -- ID: 17
('/uploads/photos/Environmental_Solution_Co_Ltd_post5_no1.jpg', NULL), -- ID: 18
('/uploads/photos/Environmental_Solution_Co_Ltd_post5_no2.jpg', NULL), -- ID: 19
('/uploads/photos/Environmental_Solution_Co_Ltd_post5_no3.jpg', NULL), -- ID: 20
('/uploads/photos/Education_Plus_Co_Ltd_post6_no1.jpg', NULL),  -- ID: 21
('/uploads/photos/Education_Plus_Co_Ltd_post6_no2.jpg', NULL),  -- ID: 22
('/uploads/photos/Education_Plus_Co_Ltd_post6_no3.jpg', NULL),  -- ID: 23
('/uploads/photos/Fintech_Partners_Co_Ltd_post7_no1.jpg', NULL), -- ID: 24
('/uploads/photos/Medical_Tech_Co_Ltd_post8_no1.jpg', NULL),    -- ID: 25
('/uploads/photos/Smart_City_Solution_Co_Ltd_post9_no1.jpg', NULL), -- ID: 26
('/uploads/photos/Yamashita_Sangyo_Co_Ltd_post10_no1.jpg', NULL), -- ID: 27
-- 追加分
-- 企業ロゴ (ID: 27-36)
('/uploads/photos/Mirai_IT_Solution_photo.jpg', NULL),          -- ID: 28
('/uploads/photos/Hidamari_Kensetsu_photo.jpg', NULL),          -- ID: 29
('/uploads/photos/Seijitsu_Logistics_photo.jpg', NULL),         -- ID: 30
('/uploads/photos/Kagayaki_Kyoiku_photo.jpg', NULL),            -- ID: 31
('/uploads/photos/Sokai_Food_Service_photo.jpg', NULL),         -- ID: 32
('/uploads/photos/Sozo_Creative_Lab_photo.jpg', NULL),          -- ID: 33
('/uploads/photos/Heiwa_Energy_photo.jpg', NULL),               -- ID: 34
('/uploads/photos/Jiai_Medical_photo.jpg', NULL),              -- ID: 35
('/uploads/photos/Hisho_Tourism_photo.jpg', NULL),              -- ID: 36
('/uploads/photos/Daichi_Agriculture_photo.jpg', NULL),         -- ID: 37
-- 記事11 (未来IT: 1枚)
('/uploads/photos/Mirai_IT_Solution_post11_no1.jpg', NULL),     -- ID: 38
-- 記事12 (未来IT: 3枚)
('/uploads/photos/Mirai_IT_Solution_post12_no1.jpg', NULL),     -- ID: 39
('/uploads/photos/Mirai_IT_Solution_post12_no2.jpg', NULL),     -- ID: 40
('/uploads/photos/Mirai_IT_Solution_post12_no3.jpg', NULL),     -- ID: 41
-- 記事13, 14 (陽だまり建設: 各1枚)
('/uploads/photos/Hidamari_Kensetsu_post13_no1.jpg', NULL),     -- ID: 42
('/uploads/photos/Hidamari_Kensetsu_post14_no1.jpg', NULL),     -- ID: 43
-- 記事15 (誠実ロジ: 3枚)
('/uploads/photos/Seijitsu_Logistics_post15_no1.jpg', NULL),    -- ID: 44
('/uploads/photos/Seijitsu_Logistics_post15_no2.jpg', NULL),    -- ID: 45
('/uploads/photos/Seijitsu_Logistics_post15_no3.jpg', NULL),    -- ID: 46
-- 記事16-20 (各1枚)
('/uploads/photos/Kagayaki_Kyoiku_post16_no1.jpg', NULL),       -- ID: 47
('/uploads/photos/Sokai_Food_Service_post17_no1.jpg', NULL),    -- ID: 48
('/uploads/photos/Sozo_Creative_Lab_post18_no1.jpg', NULL),     -- ID: 49
('/uploads/photos/Heiwa_Energy_post19_no1.jpg', NULL),          -- ID: 50
('/uploads/photos/Jiai_Medical_post20_no1.jpg', NULL),          -- ID: 51
-- 記事21 (飛翔ツーリズム: 3枚)
('/uploads/photos/Hisho_Tourism_post21_no1.jpg', NULL),         -- ID: 52
('/uploads/photos/Hisho_Tourism_post21_no2.jpg', NULL),         -- ID: 53
('/uploads/photos/Hisho_Tourism_post21_no3.jpg', NULL),         -- ID: 54
-- 記事22-26 (各1枚)
('/uploads/photos/Daichi_Agriculture_post22_no1.jpg', NULL),    -- ID: 55
('/uploads/photos/Mirai_IT_Solution_post23_no1.jpg', NULL),     -- ID: 56
('/uploads/photos/Hidamari_Kensetsu_post24_no1.jpg', NULL),     -- ID: 57
('/uploads/photos/Seijitsu_Logistics_post25_no1.jpg', NULL),    -- ID: 58
('/uploads/photos/Kagayaki_Kyoiku_post26_no1.jpg', NULL),       -- ID: 59
-- 記事27 (爽快フード: 3枚)
('/uploads/photos/Sokai_Food_Service_post27_no1.jpg', NULL),    -- ID: 60
('/uploads/photos/Sokai_Food_Service_post27_no2.jpg', NULL),    -- ID: 61
('/uploads/photos/Sokai_Food_Service_post27_no3.jpg', NULL),    -- ID: 62
-- 記事28-32 (各1枚)
('/uploads/photos/Sozo_Creative_Lab_post28_no1.jpg', NULL),     -- ID: 63
('/uploads/photos/Heiwa_Energy_post29_no1.jpg', NULL),          -- ID: 64
('/uploads/photos/Jiai_Medical_post30_no1.jpg', NULL),          -- ID: 65
('/uploads/photos/Hisho_Tourism_post31_no1.jpg', NULL),         -- ID: 66
('/uploads/photos/Daichi_Agriculture_post32_no1.jpg', NULL),    -- ID: 67
-- サンプルユーザーのアイコン用
('/uploads/photos/icon1.jpg', NULL), -- ID: 68
('/uploads/photos/icon2.jpg', NULL), -- ID: 69
('/uploads/photos/icon3.jpg', NULL), -- ID: 70
('/uploads/photos/icon4.jpg', NULL), -- ID: 71
('/uploads/photos/icon5.jpg', NULL); -- ID: 72

-- users
-- companies
INSERT INTO companies (name, address, phone_number, description, plan_status, is_withdrawn, created_at, photo_id) VALUES
('株式会社ヤマシタ産業', '東京都渋谷区', '070-5555-5555', '株式会社ヤマシタ産業 は、1978年（昭和53年）創業の総合商社・製造サポート企業です。\n\n創業以来、地域の産業発展とお客様のビジネス成功を第一に考え、物流・資材・機械設備の供給から、製造現場の改善提案まで幅広いサービスを提供しています。\n\n当社は主に以下の事業を展開しています：\n・産業資材の販売\n・物流・在庫管理サービス\n・機械装備の導入支援・保守サービス\n\n私たちは「信頼」「品質」「スピード」を行動指針として、長年培ってきたノウハウとネットワークを生かし、地域社会と企業の成長に貢献しています。', 1, FALSE, NOW(), 2),
('バイデンウィンド株式会社', '大阪府大阪市', '070-6666-6666', 'バイデンウィンド株式会社は、再生可能エネルギー分野に特化した企業です。\n\n主に風力発電事業を展開しており、環境に優しいエネルギーソリューションを提供しています。\n当社の主な事業内容は以下の通りです：\n・風力発電所の企画、設計、建設、運営\n・再生可能エネルギーに関するコンサルティングサービス\n・地域社会との連携による環境保護活動\n\n私たちは、持続可能な社会の実現に向けて、革新的な技術とサービスを提供し、クリーンエネルギーの普及に貢献しています。',1, FALSE, NOW(), 3),
('退会済み企業', '愛知県名古屋市', '070-5555-6666', '退会済み企業の説明文です。企業一覧に表示され、投稿されていた記事も残ります。', 1, TRUE, NOW(), 3),
('テック・イノベーション株式会社', '東京都千代田区', '070-7777-7777', 'テック・イノベーション株式会社は、最先端のAI・機械学習技術を活用したソリューション企業です。\n\nクラウド、ビッグデータ、IoTなど、デジタル変革に必要な技術を提供し、企業のデジタル化を支援しています。\n\n主な事業：\n・AI・機械学習ソリューション開発\n・クラウドインフラ構築\n・データ分析・活用支援', 1, FALSE, NOW(), 4),
('グローバル人材サービス株式会社', '京都府京都市', '070-8888-8888', 'グローバル人材サービス株式会社は、国際的な人材育成・派遣事業を展開する企業です。\n\n多言語対応、文化交流、キャリア開発支援を通じて、グローバル人材の育成と雇用創出に貢献しています。\n\n主な事業：\n・グローバル人材育成\n・人材派遣サービス\n・言語研修・コンサルティング', 1, FALSE, NOW(), 5),
('環境ソリューション株式会社', '福岡県福岡市', '070-9999-9999', '環境ソリューション株式会社は、環境問題への取組みとサステナビリティ実現を目指す企業です。\n\n廃棄物管理、リサイクル事業、環境コンサルティングを通じて、企業のカーボンニュートラル化を支援しています。\n\n主な事業：\n・廃棄物処理・リサイクル\n・環境監査\n・サステナビリティコンサルティング', 1, FALSE, NOW(), 6),
('エデュケーション・プラス株式会社', '大阪府大阪市', '070-1010-1010', 'エデュケーション・プラス株式会社は、教育技術（EdTech）を活用した学習支援企業です。\n\nオンライン教育プラットフォーム、AI学習システム、企業研修サービスを提供し、人材育成を支援しています。\n\n主な事業：\n・オンライン教育プラットフォーム運営\n・AI学習システム開発\n・企業向け研修プログラム', 1, FALSE, NOW(), 7),
('フィンテック・パートナーズ株式会社', '東京都中央区', '070-1111-1111', 'フィンテック・パートナーズ株式会社は、金融テクノロジー分野のリーディング企業です。\n\nデジタル決済、ブロックチェーン技術、金融アナリティクスソリューションを提供し、金融サービスの革新を推進しています。\n\n主な事業：\n・デジタル決済システム\n・ブロックチェーン技術\n・金融データ分析', 1, FALSE, NOW(), 8),
('メディカル・テック株式会社', '名古屋市中区', '070-1212-1212', 'メディカル・テック株式会社は、医療とテクノロジーの融合で、医療の質と効率を向上させる企業です。\n\n医療用ソフトウェア、遠隔診療システム、健康管理アプリを開発し、より良い医療環境の実現に貢献しています。\n\n主な事業：\n・医療用ソフトウェア開発\n・遠隔医療システム\n・健康管理プラットフォーム', 1, FALSE, NOW(), 9),
('スマートシティ・ソリューション株式会社', '東京都港区', '070-1313-1313', 'スマートシティ・ソリューション株式会社は、スマートシティ実現に向けたIoT・AI技術を提供する企業です。\n\nスマートトラフィック、スマート照明、統合管理システムなど、都市の持続可能な発展を支援しています。\n\n主な事業：\n・スマートシティプラットフォーム\n・IoTセンサーソリューション\n・都市データ分析', 1, FALSE, NOW(), 10),
-- 追加分
('未来ITソリューション株式会社', '東京都港区', '03-1111-1111', '未来ITソリューション株式会社は、人工知能とクラウドテクノロジーを駆使した革新的なIT企業です。2015年の創業以来、企業のデジタルトランスフォーメーションを支援し、効率化と新たな価値創造を実現してきました。\n\n当社の強みは、最先端のAIアルゴリズムと大規模データ分析技術にあります。製造業の品質管理、小売業の需要予測、金融業のリスク分析など、多様な業界において実績を積み重ねています。\n\n主な事業内容：\n・AIを活用した業務自動化ソリューション\n・クラウドインフラの設計・構築・運用\n・IoTデバイスと連携したスマートファクトリー実現\n\n私たちは「テクノロジーで未来を拓く」をミッションとして、クライアントの課題解決に真摯に取り組んでいます。', 1, FALSE, NOW(), 29),
('陽だまり建設株式会社', '埼玉県さいたま市', '048-222-2222', '陽だまり建設株式会社は、1972年に創業した地域密着型の総合建設会社です。関東地方を中心に、戸建住宅から集合住宅、商業施設まで幅広く手がけてきました。\n\n当社の特徴は、自然素材を活かした温もりのある住空間づくりです。国産木材や漆喰など、環境に優しい素材を積極的に採用し、健康で快適な暮らしを提案しています。また、耐震性と耐久性に優れた工法で、長く安心して住み続けられる家づくりを追求しています。\n\n主な事業内容：\n・注文住宅の設計・施工\n・リフォーム・リノベーション\n・太陽光発電システムの導入\n・住宅診断とメンテナンス\n\n「家づくりは人生づくり」を合言葉に、お客様の夢を形にしています。', 1, FALSE, NOW(), 30),
('誠実ロジスティクス株式会社', '千葉県成田市', '0476-33-3333', '誠実ロジスティクス株式会社は、国際物流から国内配送まで一貫したサービスを提供する総合物流企業です。成田空港に近い立地を活かし、迅速な国際貨物の取り扱いが可能です。\n\n当社は「正確・迅速・安全」をサービス理念として掲げ、24時間365日の体制でお客様のビジネスをサポートしています。最新の倉庫管理システムを導入し、在庫管理の最適化や配送効率の向上に努めています。\n\n主な事業内容：\n・国際航空貨物の輸出入業務\n・国内輸送サービス（トラック・鉄道）\n・倉庫保管・在庫管理\n・サプライチェーンコンサルティング\n\nグローバルな物流ネットワークで、日本のものづくりを世界へ届けています。', 1, FALSE, NOW(), 31),
('輝き教育アカデミー株式会社', '東京都新宿区', '03-4444-4444', '輝き教育アカデミー株式会社は、次世代を担う子どもたちの可能性を最大限に引き出す教育サービスを提供しています。2010年の設立以来、個別指導塾を中心に、プログラミング教室、英語教育、キャリア教育など多角的に展開しています。\n\n当社の特徴は、一人ひとりの個性や学習スタイルに合わせたオーダーメイドのカリキュラムです。AIを活用した学習分析で、効果的な学習方法を提案します。また、グローバル人材育成を視野に入れ、国際的な視野を養うプログラムも充実しています。\n\n主な事業内容：\n・小学生から高校生までの個別指導\n・プログラミング・ロボット教室\n・英語4技能（読む・聞く・話す・書く）育成\n・オンライン学習プラットフォーム運営\n\n「学ぶ喜びをすべての子どもに」を理念として、教育の未来を創造します。', 1, FALSE, NOW(), 32),
('爽快フードサービス株式会社', '大阪府大阪市', '06-5555-5555', '爽快フードサービス株式会社は、「食を通じた健康と幸せの提供」を理念に、飲食店の運営・管理から食品の開発・販売まで幅広く展開する企業です。関西を拠点に全国へ展開しています。\n\n当社の強みは、地元の新鮮な食材を活かしたメニュー開発と、革新的な店舗コンセプトです。特に、健康志向の高まりに対応した「ヘルシーでありながら美味しい」を追求した料理には定評があります。また、フードロス削減にも積極的に取り組み、持続可能な食の提供を目指しています。\n\n主な事業内容：\n・レストラン・カフェの運営\n・企業向け給食サービス\n・食品の開発・製造\n・飲食店コンサルティング\n\n「美味しい笑顔が生まれる食卓」を目指して日々進化し続けています。', 1, FALSE, NOW(), 33),
('創造クリエイティブ・ラボ株式会社', '東京都渋谷区', '03-6666-6666', '創造クリエイティブ・ラボ株式会社は、デジタル時代のブランディングとコミュニケーションを専門とするクリエイティブエージェンシーです。大手企業からスタートアップまで、多様なクライアントと共に価値あるプロジェクトを実現してきました。\n\n当社は、戦略的なデザイン思考と最先端のテクノロジーを融合させ、ユーザーエクスペリエンス（UX）を重視したソリューションを提供しています。ウェブサイト、アプリケーション、プロモーションコンテンツなど、デジタル領域を中心に幅広く対応しています。\n\n主な事業内容：\n・ブランド戦略策定・コンサルティング\n・UI/UXデザイン・開発\n・デジタルマーケティング支援\n・動画制作・コンテンツ制作\n\n「美しさと機能性の調和」を追求し、クライアントのビジョンを形に変えます。', 1, FALSE, NOW(), 34),
('平和エネルギー株式会社', '石川県金沢市', '076-777-7777', '平和エネルギー株式会社は、持続可能な社会の実現に向けて、再生可能エネルギーの普及に取り組むエネルギー企業です。太陽光、風力、地熱など、多様な自然エネルギー源を活用した発電事業を展開しています。\n\n当社は、地域と共生するエネルギープロジェクトを重視しています。発電施設の建設にあたっては、地元の環境や生態系への影響を最小限に抑える配慮を行い、地域住民との対話を大切にしています。また、エネルギーの地産地消を推進し、地域経済の活性化にも貢献しています。\n\n主な事業内容：\n・太陽光発電所の開発・運営\n・風力発電プロジェクト\n・省エネルギーコンサルティング\n・家庭向け太陽光パネル設置\n\n「自然と調和したクリーンなエネルギーで、次世代に豊かな地球を」をビジョンに掲げています。', 1, FALSE, NOW(), 35),
('慈愛メディカル株式会社', '福岡県福岡市', '092-888-8888', '慈愛メディカル株式会社は、医療と介護の質的向上を目指して、医療機器の販売から介護施設の運営まで総合的に展開するヘルスケア企業です。九州地方を中心に、高齢化社会の課題解決に取り組んでいます。\n\n当社は、最先端の医療テクノロジーと温かな人間的ケアの融合を目指しています。遠隔診療システムの導入や、AIを活用した健康管理アプリの開発など、デジタル技術を駆使した新しい医療・介護サービスの提供に注力しています。\n\n主な事業内容：\n・医療機器・消耗品の販売\n・介護施設の運営・管理\n・在宅医療・介護支援サービス\n・健康管理アプリの開発\n\n「医療の進歩と人間の温もりを両立させる」ことで、誰もが安心して暮らせる社会の実現を目指します。', 1, FALSE, NOW(), 36),
('飛翔ツーリズム株式会社', '北海道札幌市', '011-999-9999', '飛翔ツーリズム株式会社は、北海道の雄大な自然を舞台に、特別な旅の体験を提供する旅行会社です。2005年の創業以来、個人旅行から団体旅行、企業研修旅行まで、幅広いニーズに対応してきました。\n\n当社の特徴は、地元のガイドと連携した「地域密着型」のツアープログラムです。観光名所だけでなく、一般の旅行ではなかなか訪れないローカルなスポットや、地域の文化・食を体験できるプログラムを多数用意しています。また、エコツーリズムにも力を入れており、自然環境の保全に配慮した旅行を提案しています。\n\n主な事業内容：\n・国内・海外旅行の企画・手配\n・企業研修・社員旅行の企画\n・地域活性化プロジェクト\n・旅行関連Webメディアの運営\n\n「旅で人生を豊かに」をモットーに、心に残る旅の創造を続けています。', 1, FALSE, NOW(), 37),
('大地アグリカルチャー株式会社', '宮崎県宮崎市', '0985-10-1010', '大地アグリカルチャー株式会社は、持続可能な農業の実現を目指し、スマート農業技術の開発と実践に取り組む農業法人です。宮崎県の温暖な気候を活かした野菜栽培を基盤とし、全国へ高品質な農産物を供給しています。\n\n当社は、IoTセンサーやAIを活用したデータ駆動型農業を推進しています。圃場の環境データをリアルタイムで収集・分析し、最適な水やりや施肥を実現することで、収量の向上と品質の安定化を図っています。また、植物工場での完全人工光型栽培にも挑戦し、天候に左右されない安定的な生産体制を構築しています。\n\n主な事業内容：\n・野菜の栽培・販売（露地・施設）\n・スマート農業システムの開発・販売\n・農業技術のコンサルティング\n・農業体験・教育プログラム\n\n「自然とテクノロジーの調和で、未来の農業を創る」を理念に、農業の新しい可能性を追求しています。', 1, FALSE, NOW(), 38),
-- プロコン用
('テスト企業01', '東京都千代田区1-1', '03-0001-0001', 'テスト企業01の説明です', 1, FALSE, NOW(), NULL),
('テスト企業02', '東京都千代田区1-2', '03-0001-0002', 'テスト企業02の説明です', 1, FALSE, NOW(), NULL),
('テスト企業03', '東京都千代田区1-3', '03-0001-0003', 'テスト企業03の説明です', 1, FALSE, NOW(), NULL),
('テスト企業04', '東京都千代田区1-4', '03-0001-0004', 'テスト企業04の説明です', 1, FALSE, NOW(), NULL),
('テスト企業05', '東京都千代田区1-5', '03-0001-0005', 'テスト企業05の説明です', 1, FALSE, NOW(), NULL),
('テスト企業06', '東京都千代田区1-6', '03-0001-0006', 'テスト企業06の説明です', 1, FALSE, NOW(), NULL),
('テスト企業07', '東京都千代田区1-7', '03-0001-0007', 'テスト企業07の説明です', 1, FALSE, NOW(), NULL),
('テスト企業08', '東京都千代田区1-8', '03-0001-0008', 'テスト企業08の説明です', 1, FALSE, NOW(), NULL),
('テスト企業09', '東京都千代田区1-9', '03-0001-0009', 'テスト企業09の説明です', 1, FALSE, NOW(), NULL),
('テスト企業10', '東京都千代田区1-10', '03-0001-0010', 'テスト企業10の説明です', 1, FALSE, NOW(), NULL),
('テスト企業11', '東京都千代田区1-11', '03-0001-0011', 'テスト企業11の説明です', 1, FALSE, NOW(), NULL),
('テスト企業12', '東京都千代田区1-12', '03-0001-0012', 'テスト企業12の説明です', 1, FALSE, NOW(), NULL),
('テスト企業13', '東京都千代田区1-13', '03-0001-0013', 'テスト企業13の説明です', 1, FALSE, NOW(), NULL),
('テスト企業14', '東京都千代田区1-14', '03-0001-0014', 'テスト企業14の説明です', 1, FALSE, NOW(), NULL),
('テスト企業15', '東京都千代田区1-15', '03-0001-0015', 'テスト企業15の説明です', 1, FALSE, NOW(), NULL);
-- users
INSERT INTO users (nickname, type, password, phone_number, email, company_id, report_count, plan_status, is_withdrawn, created_at, society_history, icon, announcement_deletion, token, otp, otp_expires_at) VALUES
-- 学生:type=1
('佐々木一郎', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-1111-1111', 'sasaki@mail.com', NULL, 0, '学生プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('安藤花子', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-2222-2222', 'andou@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('理系くん', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-2222-3333', 'rikei@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('文系ちゃん', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-1111-2222', 'bunkei@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('退会済み学生', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-1234-5678', 'stu.delete@mail.com', NULL, 0, '無料', TRUE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
-- 社会人:type=2
('松井二郎', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-3333-3333', 'matsui@mail.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 6, NULL, 1, 50, NULL, NULL),
('高田鳥子', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-4444-4444', 'takada@mail.com', NULL, 0, '無料', FALSE, NOW(), 4, NULL, 1, 50, NULL, NULL),
('残業三昧くん', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-3333-4444', 'zangyou@mail.com', NULL, 0, '無料', FALSE, NOW(), 3, NULL, 1, 50, NULL, NULL),
('新卒ちゃん', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-3333-4444', 'shinsotsu@mail.com', NULL, 0, '無料', FALSE, NOW(), 2, NULL, 1, 50, NULL, NULL),
('退会済み社会人', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-4444-5555', 'wor.delete@mail.com', NULL, 0, '無料', TRUE, NOW(), 7, NULL, 1, 50, NULL, NULL),
-- 企業:type=3
('株式会社ヤマシタ産業', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-5555-5555', 'yamashita@mail.com', 1, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('バイデンウィンド株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-6666-6666', 'umeda@mail.com', 2, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('退会済み企業', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-5555-6666', 'com.delete@mail.com', 3, 0, '企業プレミアム', TRUE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
-- 管理者:type=4
('管理者-森本四郎', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-7777-7777', 'morimoto@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者-西川月子', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-8888-8888', 'nishikawa@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),

-- 通報用
('違反スゴ助', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-1234-5678', 'notices@mail.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),

-- 企業や記事用追加企業
('テック・イノベーション株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-7777-7777', 'techinnovation@mail.com', 4, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('グローバル人材サービス株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-8888-8888', 'global@mail.com', 5, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('環境ソリューション株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-9999-9999', 'ecosolution@mail.com', 6, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('エデュケーション・プラス株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-1010-1010', 'education@mail.com', 7, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('フィンテック・パートナーズ株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-1111-1111', 'fintech@mail.com', 8, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('メディカル・テック株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-1212-1212', 'medtech@mail.com', 9, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('スマートシティ・ソリューション株式会社', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-1313-1313', 'smartcity@mail.com', 10, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
-- 追加分
('未来IT担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '03-1111-1111', 'mirai@example.com', 11, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('陽だまり担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '048-222-2222', 'hidamari@example.com', 12, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('誠実ロジ担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '0476-33-3333', 'seijitsu@example.com', 13, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('輝き教育担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '03-4444-4444', 'kagayaki@example.com', 14, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('爽快フード担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '06-5555-5555', 'sokai@example.com', 15, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('創造ラボ担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '03-6666-6666', 'sozo@example.com', 16, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('平和エネルギー担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '076-777-7777', 'heiwa@example.com', 17, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('慈愛メディカル担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '092-888-8888', 'jiai@example.com', 18, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('飛翔ツーリズム担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '011-999-9999', 'hisho@example.com', 19, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('大地アグリ担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '0985-10-1010', 'daichi@example.com', 20, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
-- admin追加
('admin', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-0001', 'admin@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
-- プロコン用操作アカウント（１５人分、学生「無料」、社会人「プレミアム」、企業、「プレミアム」、管理者）
-- 学生 (ID 35-49)
('学生1', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1001', 'stu_1@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生2', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1002', 'stu_2@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生3', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1003', 'stu_3@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生4', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1004', 'stu_4@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生5', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1005', 'stu_5@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生6', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1006', 'stu_6@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生7', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1007', 'stu_7@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生8', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1008', 'stu_8@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生9', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1009', 'stu_9@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生10', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1010', 'stu_10@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生11', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1011', 'stu_11@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生12', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1012', 'stu_12@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生13', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1013', 'stu_13@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生14', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1014', 'stu_14@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('学生15', 1, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '090-0000-1015', 'stu_15@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),

-- 社会人 (ID 50-64) / type=2, 社会人プレミアム
('社会人1', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2001', 'sha_1@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 5, NULL, 1, 50, NULL, NULL),
('社会人2', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2002', 'sha_2@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 3, NULL, 1, 50, NULL, NULL),
('社会人3', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2003', 'sha_3@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 8, NULL, 1, 50, NULL, NULL),
('社会人4', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2004', 'sha_4@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 2, NULL, 1, 50, NULL, NULL),
('社会人5', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2005', 'sha_5@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 10, NULL, 1, 50, NULL, NULL),
('社会人6', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2006', 'sha_6@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 4, NULL, 1, 50, NULL, NULL),
('社会人7', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2007', 'sha_7@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 6, NULL, 1, 50, NULL, NULL),
('社会人8', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2008', 'sha_8@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 1, NULL, 1, 50, NULL, NULL),
('社会人9', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2009', 'sha_9@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 12, NULL, 1, 50, NULL, NULL),
('社会人10', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2010', 'sha_10@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 5, NULL, 1, 50, NULL, NULL),
('社会人11', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2011', 'sha_11@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 7, NULL, 1, 50, NULL, NULL),
('社会人12', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2012', 'sha_12@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 3, NULL, 1, 50, NULL, NULL),
('社会人13', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2013', 'sha_13@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 9, NULL, 1, 50, NULL, NULL),
('社会人14', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2014', 'sha_14@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 4, NULL, 1, 50, NULL, NULL),
('社会人15', 2, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '080-0000-2015', 'sha_15@test.com', NULL, 0, '社会人プレミアム', FALSE, NOW(), 6, NULL, 1, 50, NULL, NULL),

-- 企業担当 (ID 65-79) / type=3, 企業プレミアム, company_id=21-35を順に紐付け
('企業1担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3001', 'co_1@test.com', 21, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業2担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3002', 'co_2@test.com', 22, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業3担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3003', 'co_3@test.com', 23, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業4担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3004', 'co_4@test.com', 24, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業5担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3005', 'co_5@test.com', 25, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業6担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3006', 'co_6@test.com', 26, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業7担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3007', 'co_7@test.com', 27, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業8担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3008', 'co_8@test.com', 28, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業9担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3009', 'co_9@test.com', 29, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業10担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3010', 'co_10@test.com', 30, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業11担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3011', 'co_11@test.com', 31, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業12担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3012', 'co_12@test.com', 32, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業13担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3013', 'co_13@test.com', 33, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業14担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3014', 'co_14@test.com', 34, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('企業15担当', 3, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '070-0000-3015', 'co_15@test.com', 35, 0, '企業プレミアム', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),

-- 管理者 (ID 80-94) / type=4, 無料
('管理者1', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4001', 'ad_1@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者2', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4002', 'ad_2@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者3', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4003', 'ad_3@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者4', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4004', 'ad_4@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者5', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4005', 'ad_5@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者6', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4006', 'ad_6@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者7', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4007', 'ad_7@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者8', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4008', 'ad_8@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者9', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4009', 'ad_9@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者10', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4010', 'ad_10@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者11', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4011', 'ad_11@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者12', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4012', 'ad_12@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者13', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4013', 'ad_13@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者14', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4014', 'ad_14@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL),
('管理者15', 4, '$2a$10$KTfBUv8s4j8qVlPrAhdtOuU6F33cQKY/wG2bFi4doiIeDVvDaKaSC', '060-0000-4015', 'ad_15@test.com', NULL, 0, '無料', FALSE, NOW(), NULL, NULL, 1, 50, NULL, NULL);

-- 初期ユーザーのアイコン紐づけ
UPDATE users SET icon = 68 WHERE nickname = '理系くん';
UPDATE users SET icon = 69 WHERE nickname = '松井二郎';
UPDATE users SET icon = 70 WHERE nickname = '新卒ちゃん';
UPDATE users SET icon = 71 WHERE nickname = '残業三昧くん';
UPDATE users SET icon = 72 WHERE nickname = '安藤花子';

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

-- subscriptions
INSERT INTO subscriptions (user_id, plan_name, start_date, end_date, is_plan_status, created_at) VALUES
(1, '学生プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(6, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(11, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(12, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(13, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
-- プロコン用
-- 社会人プレミアム (ID 50-64)１ヶ月
(50, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(51, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(52, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(53, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(54, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(55, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(56, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(57, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(58, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(59, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(60, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(61, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(62, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(63, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
(64, '社会人プレミアム', NOW(), NOW() + INTERVAL 1 MONTH, TRUE, NOW()),
-- 企業
(65, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(66, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(67, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(68, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(69, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(70, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(71, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(72, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(73, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(74, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(75, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(76, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(77, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(78, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW()),
(79, '企業プレミアム', NOW(), NOW() + INTERVAL 1 YEAR, TRUE, NOW());

-- articles
INSERT INTO articles (title, description, company_id, is_deleted, total_likes, created_at, photo1_id, photo2_id, photo3_id) VALUES
('会社説明会のお知らせ', 'みなさんこんにちは！当社ではオンライン会社説明会を随時開催中です。\n-----２月のスケジュール-----\n・５日（月）11:00～12:30\n・７日（水）10:00～11:30\n・１５日（木）11:00～12:30\n・２０日（火）13:00～14:30\n・２３日（金）10:00～11:30\n\n本社採用サイトからエントリーをお願いいたします。\nurl=httqs://www.yamashita_sangyou.recruit \n\n\n皆様のご参加お待ちしています！', 1, FALSE, 0, NOW(), 12, 13, 14),  -- photo1_id=12, photo2_id=13, photo3_id=14
('スレッドを開設しました', 'みなさんこんにちは。本日「バイデンウィンド（株）」のスレッドを開設しました。\n\n就職活動に関する質問等、採用担当の者がお答えします！\n採用には一切影響いたしませんので、お気軽にご参加ください。\nみなさんの投稿お待ちしています！', 2, FALSE, 0, NOW(), 15, NULL, NULL),  -- photo1_id=15
('AI・機械学習技術セミナーのご案内', 'テック・イノベーション株式会社では、最先端のAI・機械学習技術に関するセミナーを開催いたします。\n業界の第一線の専門家による講演会を予定しており、参加者には特別な情報をお得にご提供いたします。\nご興味のある方は、ぜひお気軽にお申し込みください。', 4, FALSE, 0, NOW(), 16, NULL, NULL),  -- photo1_id=16
('国際人材育成プログラム2026年開始', 'グローバル人材サービス株式会社では、2026年度の国際人材育成プログラムの参加者を募集しています。\n多言語対応・文化交流・キャリア形成支援など、充実した研修内容を用意しております。\nこのプログラムを通じてグローバルに活躍できる人材へとステップアップしませんか？', 5, FALSE, 0, NOW(), 17, NULL, NULL),  -- photo1_id=17
('環境配慮型製品ラインアップ拡充', '環境ソリューション株式会社では、持続可能な社会実現に向けた新製品をリリースいたします。\n廃棄物処理・リサイクル・環境監査を統合したソリューションで、企業のカーボンニュートラル化を支援します。\n環境への取り組みを始めたい企業様との協力をお待ちしています。', 6, FALSE, 0, NOW(), 18, 19, 20),  -- photo1_id=18, photo2_id=19, photo3_id=20

('EdTech新サービス「AI学習サポート」ベータ版開始', 'エデュケーション・プラス株式会社が新しいAI学習支援システムのベータ版を公開いたします。\nタブレットやPCで利用可能な本システムは、個人の学習進度に合わせた最適なカリキュラムを提供します。\n無料トライアルもご用意しておりますので、ぜひお試しください。', 7, FALSE, 0, NOW(), 21, 22, 23),  -- photo1_id=21, photo2_id=22, photo3_id=23
('フィンテック・パートナーズ新規事業説明会', 'デジタル決済・ブロックチェーン技術を活用したフィンテック・パートナーズより、新規事業についての説明会を開催いたします。\n金融DXに興味のある学生・社会人の皆様ご参加ください。\n企業説明・選考対策セッションも同時開催予定です。', 8, FALSE, 0, NOW(), 23, NULL, NULL),  -- photo1_id=23
('メディカル・テック医療従事者向けセミナー開催', 'メディカル・テック株式会社では、医療現場でのデジタル化について学ぶセミナーを開催いたします。\n遠隔診療・患者データ管理・医療AIなど、最新の医療テクノロジーについてのお話となります。\n医療業界への就職を検討されている方もぜひご参加ください。', 9, FALSE, 0, NOW(), 25, NULL, NULL),  -- photo1_id=25
('スマートシティ技術説明会・インターン募集', 'スマートシティ・ソリューション株式会社は、IoT・AI技術を活用した都市構想についての説明会を実施いたします。\nあわせて、2026年夏期インターンシップの参加者も募集中です。\nスマートシティの実現に携わりたい皆様のご応募をお待ちしています。', 10, FALSE, 0, NOW(), 26, NULL, NULL),  -- photo1_id=26
('株式会社ヤマシタ産業 新卒採用開始のお知らせ', '株式会社ヤマシタ産業では、2026年度新卒採用を開始いたしました。\n製造業界に興味のある学生の皆様、ぜひ当社の採用情報をご覧ください。\nエントリーは当社採用サイトからお願いいたします。', 1, FALSE, 0, NOW(), 27, NULL, NULL),  -- photo1_id=27
-- 追加分
('AIが導く2030年の働き方ビジョン', '生成AIの発展により、エンジニアの役割は「コードを書くこと」から\n「課題を定義すること」へシフトしています。未来ITでは、AIをバディとして\n使いこなし生産性を最大化する新しい研修プログラムを開始。\n実際に残業時間を30%削減したチームの事例を詳しく紹介します。', 11, FALSE, 0, NOW(), 37, NULL, NULL),
('エンジニアの楽園？新オフィスの全貌', '昨年末に完成した新オフィスは「創造性の解放」がコンセプト。\n固定席を廃止したフリーアドレス制に加え、集中力を高めるための\n「サイレントルーム」や、議論を活性化させるエリアを設置。\n本格カフェ空間も完備。写真付きで新しいフロアを案内します！', 11, FALSE, 0, NOW(), 39, 40, 41),
('木のぬくもりが繋ぐ、家族の未来', '陽だまり建設が提案する「呼吸する家」シリーズ。厳選された国産無垢材を\n贅沢に使用し、化学物質を極限まで排除した住まい作りを実現しました。\n調湿効果により一年中快適な室内環境を保つことができます。今回は、\n3年前に建築されたオーナー様宅を訪問し、その後の住み心地を伺いました。', 12, FALSE, 0, NOW(), 42, NULL, NULL),
('「震度7」に耐えうる最新耐震技術', '地震大国日本において、住まいの安全性は最優先事項です。\n陽だまり建設では、独自の「ハイブリッド制震工法」を採用。建物の衝撃を\n逃がす技術により、大地震後の余震にも強い構造を実現しました。\n実物大の家を用いた実験映像とともに、技術的な裏付けを解説します。', 12, FALSE, 0, NOW(), 43, NULL, NULL),
('物流2024年問題を乗り越える自動倉庫', '物流業界が直面している人手不足と労働規制。誠実ロジスティクスでは、\n最新の「走行型ピッキングロボット」を100台導入しました。\nこれにより、人間が歩き回る時間を削減し出荷効率を従来の2.5倍に向上。\nテクノロジーを活用した持続可能な物流インフラの構築戦略を公開します。', 13, FALSE, 0, NOW(), 44, 45, 46),
('「正解のない時代」を生き抜く教育', 'これからの時代に求められるのは、知識量ではなく「問いを立てる力」です。\n輝き教育アカデミーでは、小学生から参加できるワークショップを定期開催。\n教科書に載っていない社会課題に対し、自分たちなりの解決策を形にする\n当校独自の教育メソッドと、実際に子供たちが作った作品を紹介します。', 14, FALSE, 0, NOW(), 47, NULL, NULL),
('究極の食感！「爽快テリヤキバーガー」', '「一口で笑顔になるバーガーを」という目標を掲げ、開発期間に\n1年以上を費やした自信作が完成。特にこだわったのは特注石窯で\n焼き上げた「天然酵母バンズ」です。開発担当シェフが語る素材選びの苦労と\n最高の一皿に込めた想いを、インタビュー形式で詳しくお届けします。', 15, FALSE, 0, NOW(), 48, NULL, NULL),
('デザインが企業の「意思」を視覚化する', 'ロゴやWEBサイトは単なる飾りではありません。それは企業の理念を\n伝えるための重要なコミュニケーションツールです。創造ラボでは、\n企業の「魂」をデザインに昇華させます。老舗メーカーのリブランディング\nプロジェクトを例に、戦略的なデザインのプロセスを特別に公開します。', 16, FALSE, 0, NOW(), 49, NULL, NULL),
('能登から世界へ！風力発電プロジェクト', '石川県の海岸線沿いに広がる風車群。自然エネルギーの普及は、\n地域の理解と共生なしには成り立ちません。私たちは発電所の建設だけでなく\n環境教育や伝統工芸支援にも力を入れています。地方からエネルギー\n自給率向上を目指す、私たちの挑戦の足跡と未来への展望を綴ります。', 17, FALSE, 0, NOW(), 50, NULL, NULL),
('0.1mmの病変を見逃さない医療の眼', '慈愛メディカルでは、最新の「高精細3テスラMRI」を導入しました。\n微細な血管の異変を鮮明に映し出すことが可能になり、早期発見が\n難しい疾患に対しても大きな力を発揮します。診断精度の向上による\n治療への影響と、これからの地域医療のあり方について解説します。', 18, FALSE, 0, NOW(), 51, NULL, NULL),
('ガイドブックに載らない、秘境の旅', '大手の旅行会社では提供できない「体験」を求めて。今回のツアー先は、\nヒマラヤ山脈の麓にある小さな村です。ネットも繋がらない環境で、\n現地の家族と食事を作り、満天の星空の下で語り合う。利便性から切り離された\n場所で見つかる本当の「豊かさ」を、美しい写真とともに振り返ります。', 19, FALSE, 0, NOW(), 52, 53, 54),
('ITと農業が融合する、新しい土壌', '「きつい・汚い・稼げない」という農業のイメージを払拭したい。\n大地アグリでは、スマホ一つでハウスの環境を管理できるスマート農法を\n実践しています。データに基づいた栽培管理により、高級イチゴの\n安定生産に成功。農業技術が拓く日本の食の未来について熱く語ります。', 20, FALSE, 0, NOW(), 55, NULL, NULL),
('【学生限定】2Week実践型インターン', '未来ITのインターンは、単なる見学ではありません。実際に進行中の\n開発チームに配属され、プロのアドバイスを受けながら新機能の\n実装に挑戦していただきます。「現場の厳しさと楽しさ」を同時に知る、\nあなたのスキルを試す絶好の機会です。意欲ある学生の応募を待っています！', 11, FALSE, 0, NOW(), 56, NULL, NULL),
('「地図に残る仕事」の最前線に立つ', '建設現場の朝は早く活気に満ちています。入社3年目の現場監督の\n1日に密着。協力会社と連携し、安全を守り抜く責任ある仕事です。\n更地が次第に「家」の形を成していく過程を一番近くで見守れるのは、\nこの仕事の醍醐味。若手が現場で成長していくリアルな姿を追いました。', 12, FALSE, 0, NOW(), 56, NULL, NULL),
('プロが教える「事故ゼロ」の運転術', '誠実ロジスティクスのドライバーは、単に荷物を運ぶだけではありません。\n安全教育を受け、プロの自覚を持った「安全の伝道師」です。\n一般の方にも役立つ、事故を防ぐための視線移動や確認のポイントを、\n社内の研修映像を交えて熟練ドライバーが分かりやすくレクチャーします。', 13, FALSE, 0, NOW(), 58, NULL, NULL),
('英語で描く、感性のキャンバス', '人気カリキュラム「English Art」。この授業では、デッサンの技法を\nすべて英語で学びます。言葉のニュアンスの違いを楽しみながら、\n自分の感情を色と形にしていく。語学を学ぶこと自体が目的ではなく、\n英語を使って「表現する」ことを楽しむ、新しいスタイルの教室です。', 14, FALSE, 0, NOW(), 58, NULL, NULL),
('キッチンカーで届ける「出来立て」の感動', 'レストランの味をもっと身近に。爽快フードサービスが展開する\nキッチンカープロジェクトが始動。オフィス街やフェスに駆けつけ、\nその場で「石窯ピッツァ」を焼き上げます。店舗クオリティを維持する\n工夫やメニュー開発の裏側に迫ります。訪問スケジュールも公開中！', 15, FALSE, 0, NOW(), 60, 61, 62),
('働く場所が、人生を面白くする', '「会社の机に座るのが楽しみになるオフィス」を作りたい。\n創造ラボがプロデュースしたリノベーション事例をご紹介します。\nシンボルツリーを配置し、木漏れ日の中で仕事をする感覚を演出。\n「リラックスと集中」を両立させる空間設計のノウハウを解説します。', 16, FALSE, 0, NOW(), 63, NULL, NULL),
('わが家の「エネルギー自給自足」計画', '電気代の高騰が続く今、太陽光発電への関心が高まっています。\n平和エネルギーでは、各家庭に合わせた最適な設置シミュレーションを無料で提供。\n「元を取るのに何年かかる？」そんな疑問に専門家が回答します。\n実際に導入して光熱費を大幅に削減したお客様の生の声も掲載中です。', 17, FALSE, 0, NOW(), 63, NULL, NULL),
('24時間365日、地域を守る医療の砦', '「夜中に子供が熱を出した」そんな時に真っ先に思い出してもらえる場所でありたい。\n慈愛メディカルの医師たちが地域医療の役割について座談会を行いました。\n単に病気を治すだけでなく、安心を届けるために日々どのような体制で\n備えているのか。地域に根ざした医療従事者の熱い想いを届けます。', 18, FALSE, 0, NOW(), 64, NULL, NULL),
('日本再発見！癒やしの隠れ宿5選', 'たまにはスマホを置いて、自分を甘やかす時間を作りませんか。\n全国の温泉地を巡った添乗員が「本当は秘密にしたい」宿を厳選。\n雪景色の露天風呂、山菜料理、そして心まで洗われるような静寂。\n日常を忘れさせてくれる最高の休日を、飛翔ツーリズムが提案します。', 19, FALSE, 0, NOW(), 65, NULL, NULL),
('産地直送！スマート農業マルシェ開催', '大地アグリの農場から、朝採れの野菜を直接お届けします！\n今週末、駅前広場にて「スマート農業マルシェ」を開催。\n甘いトマトや新鮮なレタスの販売に加え、最新ドローンの操作体験も実施。\nテクノロジーが育てた力強い野菜の味を、ぜひ会場で体験してください。', 20, FALSE, 0, NOW(), 67, NULL, NULL);

-- entry_criteria: 1=全員、2=学生のみ。3=社会人のみ
-- 非公式スレッド:type=2,userid=各ユーザー,
-- threads
INSERT INTO threads (user_id, title, type, description, entry_criteria, last_update_date, is_deleted, created_at) VALUES
-- 公式スレッド:type=1,userid=7(管理者)
(14, '学生×社会人スレッド', 1, 'こちらは、学生と社会人の公式スレッドです。どなたでも参加できます。', 1, NOW(), FALSE, NOW()),
(14, '学生スレッド', 1, 'こちらは、学生の方のみの公式スレッドです。学生の方はどなたでも参加できます。', 2, NOW(), FALSE, NOW()),
(14, '社会人スレッド', 1, 'こちらは、社会人の方のみの公式スレッドです。社会人の方はどなたでも参加できます。', 3, NOW(), FALSE, NOW()),
(4, '就活って何から始めたらいいですか？', 2, '27卒の文系です。まだ希望業界も定まっておらず焦っています。経験談などあれば教えてください！', 2, NOW(), FALSE, NOW()),
(8, '面接の練習方法を教えてください', 2, '社会人2年目です。転職活動中ですが、面接が苦手で困っています。効果的な練習方法があれば教えてください。', 3, NOW(), FALSE, NOW()),
(1, '自己PRの書き方について', 2, '就活中の大学4年生です。自己PRの書き方に悩んでいます。良い例やアドバイスがあれば教えてください。', 2, NOW(), FALSE, NOW()),
(6, '資格取得のおすすめ', 2, '社会人3年目です。キャリアアップのために資格取得を考えています。おすすめの資格や勉強法があれば教えてください。', 3, NOW(), FALSE, NOW()),
(2, 'ESの添削ポイントを教えてください', 2, 'エントリーシートの文章が薄い気がします。採用担当の目線で見てほしいです。', 1, NOW(), FALSE, NOW()),
(3, 'インターン参加で気をつけること', 2, '夏インターンに初参加します。服装や準備、当日の立ち回りについて教えてください。', 1, NOW(), FALSE, NOW()),
(5, '転職1年目のキャリア相談', 2, '現職に慣れてきましたが、次のステップが不安です。資格や実務経験の積み方を相談させてください。', 3, NOW(), FALSE, NOW()),
(7, '学業と就活の両立どうしてる？', 2, '研究が忙しく、就活に時間を割けません。みなさんの工夫を聞かせてください。', 2, NOW(), FALSE, NOW()),
(9, '一次面接の頻出質問まとめ', 2, 'これから面接が始まります。よく聞かれる質問と対策があれば共有してください。', 1, NOW(), FALSE, NOW()),
(10, 'OB/OG訪問で聞くべきこと', 2, '初めてのOB/OG訪問です。失礼にならない質問や聞くべきポイントを教えてください。', 1, NOW(), FALSE, NOW()),
(16, '27卒と話したい！', 3, 'このスレッドは不適切な内容を含んでいます。通報テスト用スレッドです。', 1, NOW(), TRUE, NOW()),
(11, '株式会社ヤマシタ産業スレッド', 3, '株式会社ヤマシタ産業の採用に関する質問はこちらでどうぞ！', 5, NOW(), FALSE, NOW()),
(12, 'バイデンウィンド株式会社スレッド', 3, 'バイデンウィンド株式会社の採用に関する質問はこちらでどうぞ！', 5, NOW(), FALSE, NOW());

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
(16, '27卒の理系です！同じ卒業年度の方としたいです！可能な限り、選考状況など共有してくれるとモチベになります！', 8, FALSE, NULL, NOW(), NULL),
(3, '文系27卒です！よろしくお願いします', 8, FALSE, NULL, NOW(), NULL),

(4, '27卒理系です。今内定2社です。', 8, FALSE, NULL, NOW(), NULL),
(2, '私は商社志望で今3社から内定もらってるよ！', 8, FALSE, NULL, NOW(), NULL),
(16, 'いいね～！SNS交換しよー！', 8, FALSE, NULL, NOW(), NULL);

-- -- quiz_questions
-- INSERT INTO quiz_questions (question, is_answer, expanation) VALUES
-- ('問題1', TRUE, '解説1'),
-- ('問題2', FALSE, '解説2');

-- quiz_scores
INSERT INTO quiz_scores (user_id, score, created_at, nickname) VALUES
(1, 24, NOW(),'佐々木一郎'),
(2, 12, NOW(),'安藤花子'),
(3, 51, NOW(),'理系くん'),
(4, 2, NOW(),'文系ちゃん'),
(5, 15, NOW(),'いとー'),
(6, 27, NOW(),'松井二郎'),
(7, 9, NOW(),'キャリア女子'),
(8, 21, NOW(),'転職マン'),
(9, 4, NOW(),'残業三昧くん'),
(10, 33, NOW(),'新卒ちゃん');

-- interviews 初期データ挿入
INSERT INTO interviews (question, type) VALUES
-- 一般質問
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
('数ある企業の中で、なぜ「この業界」なのですか？', 1),
('逆質問はありますか？（私に聞きたいことは何ですか？）', 1),
('意見が対立した際、どのように収束させますか？', 1),
('自分とは異なる価値観を持つ人と働く際、何を意識しますか？', 1),
('これまでに既存の仕組みを改善した経験はありますか？', 1),
('挫折した際、どのようにして立ち直りましたか？', 1),
('人から受けて嬉しかったアドバイスは何ですか？', 1),
('あなたが定義する「成功」とは何ですか？', 1),
('企業を選ぶ際、最も重視する軸は何ですか？', 1),
('入社後に具体的に携わりたいプロジェクトはありますか？', 1),
('これまでの最大の成果と、その要因を教えてください。', 1),
('優先順位をつける際、どのような基準で判断しますか？', 1),
('新しい技術や知識を習得する際、自分なりの工夫はありますか？', 1),
('変化の激しい環境に対して、どのように適応しますか？', 1),
('理想のリーダー像を教えてください。', 1),
('当社のビジョンについて、共感するポイントはどこですか？', 1),
('仕事を通じて社会にどのような貢献をしたいですか？', 1),
('自身の生産性を高めるために行っていることはありますか？', 1),
('入社後、1ヶ月以内に成し遂げたいことは何ですか？', 1),
('倫理的に難しい判断を迫られたらどうしますか？', 1),

-- カジュアル質問
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
('一番好きな食べ物、または勝負飯は何ですか？', 2),
('今までに行った旅行先で、一番印象に残っている場所は？', 2),
('自分は「朝型」ですか、それとも「夜型」ですか？', 2),
('ついついやってしまう「癖」や「習慣」はありますか？', 2),
('子供の頃の夢は何でしたか？', 2),
('誰にも負けない小さな特技はありますか？', 2),
('人生で影響を受けたインフルエンサーや著名人は？', 2),
('毎日欠かさずチェックしているアプリはありますか？', 2),
('最近あった「小さな幸せ」を教えてください。', 2),
('もし宝くじで1億円当たったら、まず何をしますか？', 2),
('一番好きな季節とその理由を教えてください。', 2),
('インドア派ですか、それともアウトドア派ですか？', 2),
('一番リラックスできる場所はどこですか？', 2),
('自分の中で密かに誇りに思っていることは？', 2),
('物事を決めるときは「直感派」ですか「論理派」ですか？', 2),
('ストレスが溜まったときのおすすめの解消法は？', 2),
('長年集めているものや、コレクションはありますか？', 2),
('人から言われて意外だった第一印象はありますか？', 2),
('理想の上司を有名人に例えると誰ですか？', 2),
('10年後の自分へメッセージを送るとしたら何と言いますか？', 2),

-- 圧迫質問
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
('あなたの計画は非現実的ではありませんか？', 3),
('あなたのキャリアプランは、当社でなくても実現可能では？', 3),
('正直に言って、今の回答は少し論理性に欠けませんか？', 3),
('もし希望していない部署に配属されたら、やる気を失いませんか？', 3),
('あなたのこれまでの成長スピードは、遅いとは思いませんか？', 3),
('当社の社風には合わない気がしますが、どう説得しますか？', 3),
('あなたの強みは、当社のレベルでは「普通」ではありませんか？', 3),
('学業（または前職）の成績が芳しくないようですが、理由は？', 3),
('厳しい指摘を受けたとき、感情的にならずに対処できますか？', 3),
('当社を採用見送りにした場合、あなたは後悔すると思いますか？', 3),
('あなたの発言には具体性が足りないように感じますが、いかがですか？', 3),
('もし「明日までにこれを終わらせろ」と無理な指示を受けたら？', 3),
('挫折経験が少ないようですが、困難に直面して折れませんか？', 3),
('あなたのスキルセットは、今のトレンドからズレていませんか？', 3),
('なぜ今の大学（または会社）を選んだのですか？妥協ではありませんか？', 3),
('チームが失敗したとき、自分の責任をどう認識しますか？', 3),
('給与に見合うだけの働きを、具体的にどう示してくれますか？', 3),
('あなたが採用されたとして、周囲の社員にどうメリットを与えますか？', 3),
('回答がマニュアル通りに聞こえますが、本音はどうですか？', 3),
('これまでで一番「逃げ出したい」と思った瞬間はどう乗り切りましたか？', 3),
('あなたが今日話したことの中で、一つだけ嘘があるとしたら何ですか？', 3);

-- -- phone_exercises
-- INSERT INTO phone_exercises (example, difficulty) VALUES
-- ('電話対応例題1', 1),
-- ('電話対応例題2', 2);

-- 1. 既存のデータをクリア（テーブル作成直後なら不要ですが、あっても問題ありません）
TRUNCATE TABLE notifications;

-- 2. 現実的なテストデータの挿入
INSERT INTO notifications (
    type, title, content, user_id, created_at, reservation_time, send_flag, send_flag_int, category, is_deleted
) VALUES
-- 1. 全員向けの重要なメンテナンスお知らせ（送信完了）
(7, 
 'システムメンテナンスのお知らせ', 
 '2026年3月1日（日）のAM 02:00〜05:00の間、サーバーメンテナンスを実施いたします。この間、サービスが一時的にご利用いただけなくなります。ご不便をおかけしますが、ご理解のほどよろしくお願いいたします。', 
 NULL, '2026-02-15 10:00:00', NULL, '2026-02-15 10:00:00', 2, 2, FALSE),

-- 2. 学生向けの新着イベント情報（送信完了）
(1, 
 '【学生限定】春のキャリア相談会開催決定！', 
 '就職活動を控えた学生の皆様を対象に、プロのカウンセラーによる個別相談会を開催します。参加費は無料です。詳細はマイページからご確認ください。', 
 NULL, '2026-02-16 09:00:00', NULL, '2026-02-16 09:00:00', 2, 1, FALSE),

-- 3. 特定のユーザーへの個別通知（送信完了）
(8, 
 'プロフィール情報の確認をお願いします', 
 'ご登録いただいたプロフィール情報に一部不足がございます。設定画面より「スキル」の項目を追記いただくと、よりマッチした情報をお届けできるようになります。', 
 1, '2026-02-17 11:30:00', NULL, '2026-02-17 11:30:00', 2, 1, FALSE),

-- 4. 未来の予約投稿：社会人・企業向けの共同セミナー案内（予約中）
(6, 
 '【予約】社会人×企業 マッチングフォーラム2026', 
 '来月開催される合同マッチングイベントの先行予約を開始しました。異業種交流を目的としたネットワーキングセッションも予定しております。', 
 NULL, '2026-02-17 12:00:00', '2026-03-01 10:00:00', NULL, 1, 1, FALSE),

-- 5. 全員向けの運営ニュース（送信完了）
(7, 
 'Bridgeサービスロゴのリニューアルについて', 
 '本日よりBridgeのロゴが新しくなりました！より使いやすく、より繋がりやすいプラットフォームを目指して日々改善を行ってまいります。', 
 NULL, '2026-01-20 15:00:00', NULL, '2026-01-20 15:00:00', 2, 1, FALSE);
 
 -- notices
INSERT INTO notices (from_user_id, to_user_id, type, thread_id, chat_id, created_at) VALUES
(1, 2, 2, 1, NULL, NOW()),
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
-- 追加分
(11, 7, NOW()), (12, 8, NOW()), (13, 8, NOW()), (15, 13, NOW()),
(17, 13, NOW()), (18, 8, NOW()), (21, 13, NOW()), (23, 3, NOW());

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
(3, 23, 6, NOW()),
(3, 24, 6, NOW()), -- 未来IT (ソフト)
(3, 25, 5, NOW()), -- 陽だまり (サービス/インフラ)
(3, 26, 5, NOW()), -- 誠実ロジ
(3, 27, 5, NOW()), -- 輝き教育
(3, 28, 5, NOW()), -- 爽快フード
(3, 29, 7, NOW()), -- 創造ラボ (広告)
(3, 30, 5, NOW()), -- 平和エネ
(3, 31, 5, NOW()), -- 慈愛メディ
(3, 32, 5, NOW()), -- 飛翔ツー
(3, 33, 1, NOW()), -- 大地アグリ (メーカー)
-- プロコン用
-- 学生
(1, 35, 1, NOW()), (1, 36, 2, NOW()), (1, 37, 3, NOW()), (1, 38, 4, NOW()), (1, 39, 5, NOW()),
(1, 40, 6, NOW()), (1, 41, 7, NOW()), (1, 42, 8, NOW()), (1, 43, 1, NOW()), (1, 44, 2, NOW()),
(1, 45, 3, NOW()), (1, 46, 4, NOW()), (1, 47, 5, NOW()), (1, 48, 6, NOW()), (1, 49, 7, NOW()),

-- 社会人 (ID 50-64)
(2, 50, 8, NOW()), (2, 51, 1, NOW()), (2, 52, 2, NOW()), (2, 53, 3, NOW()), (2, 54, 8, NOW()), 
(2, 55, 1, NOW()), (2, 56, 2, NOW()), (2, 57, 3, NOW()), (2, 58, 4, NOW()), (2, 59, 5, NOW()), 
(2, 60, 6, NOW()), (2, 61, 7, NOW()), (2, 62, 8, NOW()), (2, 63, 1, NOW()), (2, 64, 2, NOW()), 

-- 企業担当 (ID 65-79)
(3, 65, 3, NOW()), (3, 66, 4, NOW()), (3, 67, 5, NOW()), (3, 68, 6, NOW()),(3, 69, 7, NOW()), 
(3, 70, 8, NOW()), (3, 71, 1, NOW()), (3, 72, 2, NOW()), (3, 73, 3, NOW()),(3, 74, 4, NOW()), 
(3, 75, 5, NOW()), (3, 76, 6, NOW()), (3, 77, 7, NOW()), (3, 78, 8, NOW()),(3, 79, 1, NOW()), 

-- 管理者 (ID 80-94)
(4, 80, 2, NOW()), (4, 81, 3, NOW()), (4, 82, 4, NOW()), (4, 83, 5, NOW()),(4, 84, 8, NOW()), 
(4, 85, 1, NOW()), (4, 86, 2, NOW()), (4, 87, 3, NOW()), (4, 88, 4, NOW()),(4, 89, 5, NOW()), 
(4, 90, 6, NOW()), (4, 91, 7, NOW()), (4, 92, 8, NOW()), (4, 93, 1, NOW()),(4, 94, 2, NOW());

-- article_likes テーブルにいいねデータを追加
INSERT INTO article_likes (article_id, user_id, created_at) VALUES
-- 記事1: 10いいね
(1, 1, NOW()), (1, 2, NOW()), (1, 3, NOW()), (1, 4, NOW()), (1, 5, NOW()),
(1, 6, NOW()), (1, 7, NOW()), (1, 8, NOW()), (1, 9, NOW()), (1, 10, NOW()),
-- 記事11: 15いいね
(11, 1, NOW()), (11, 2, NOW()), (11, 3, NOW()), (11, 4, NOW()), (11, 5, NOW()),
(11, 6, NOW()), (11, 7, NOW()), (11, 8, NOW()), (11, 9, NOW()), (11, 10, NOW()),
(11, 11, NOW()), (11, 12, NOW()), (11, 13, NOW()), (11, 14, NOW()), (11, 15, NOW()),
-- 記事12: 12いいね
(12, 1, NOW()), (12, 2, NOW()), (12, 3, NOW()), (12, 4, NOW()), (12, 5, NOW()),
(12, 6, NOW()), (12, 7, NOW()), (12, 8, NOW()), (12, 9, NOW()), (12, 10, NOW()),
(12, 11, NOW()), (12, 12, NOW()),
-- 記事13: 8いいね
(13, 1, NOW()), (13, 2, NOW()), (13, 3, NOW()), (13, 4, NOW()),
(13, 5, NOW()), (13, 6, NOW()), (13, 7, NOW()), (13, 8, NOW()),
-- 記事14: 6いいね
(14, 1, NOW()), (14, 2, NOW()), (14, 3, NOW()),
(14, 4, NOW()), (14, 5, NOW()), (14, 6, NOW()),
-- 記事15: 10いいね
(15, 1, NOW()), (15, 2, NOW()), (15, 3, NOW()), (15, 4, NOW()), (15, 5, NOW()),
(15, 6, NOW()), (15, 7, NOW()), (15, 8, NOW()), (15, 9, NOW()), (15, 10, NOW()),
-- 記事16: 20いいね
(16, 1, NOW()), (16, 2, NOW()), (16, 3, NOW()), (16, 4, NOW()), (16, 5, NOW()),
(16, 6, NOW()), (16, 7, NOW()), (16, 8, NOW()), (16, 9, NOW()), (16, 10, NOW()),
(16, 11, NOW()), (16, 12, NOW()), (16, 13, NOW()), (16, 14, NOW()), (16, 15, NOW()),
(16, 16, NOW()), (16, 17, NOW()), (16, 18, NOW()), (16, 19, NOW()), (16, 20, NOW()),
-- 記事17: 25いいね
(17, 1, NOW()), (17, 2, NOW()), (17, 3, NOW()), (17, 4, NOW()), (17, 5, NOW()),
(17, 6, NOW()), (17, 7, NOW()), (17, 8, NOW()), (17, 9, NOW()), (17, 10, NOW()),
(17, 11, NOW()), (17, 12, NOW()), (17, 13, NOW()), (17, 14, NOW()), (17, 15, NOW()),
(17, 16, NOW()), (17, 17, NOW()), (17, 18, NOW()), (17, 19, NOW()), (17, 20, NOW()),
(17, 21, NOW()), (17, 22, NOW()), (17, 23, NOW()), (17, 24, NOW()), (17, 25, NOW()),
-- 記事18: 15いいね
(18, 1, NOW()), (18, 2, NOW()), (18, 3, NOW()), (18, 4, NOW()), (18, 5, NOW()),
(18, 6, NOW()), (18, 7, NOW()), (18, 8, NOW()), (18, 9, NOW()), (18, 10, NOW()),
(18, 11, NOW()), (18, 12, NOW()), (18, 13, NOW()), (18, 14, NOW()), (18, 15, NOW()),
-- 記事19: 10いいね
(19, 1, NOW()), (19, 2, NOW()), (19, 3, NOW()), (19, 4, NOW()), (19, 5, NOW()),
(19, 6, NOW()), (19, 7, NOW()), (19, 8, NOW()), (19, 9, NOW()), (19, 10, NOW()),
-- 記事20: 8いいね
(20, 1, NOW()), (20, 2, NOW()), (20, 3, NOW()), (20, 4, NOW()),
(20, 5, NOW()), (20, 6, NOW()), (20, 7, NOW()), (20, 8, NOW()),
-- 記事21: 25いいね
(21, 1, NOW()), (21, 2, NOW()), (21, 3, NOW()), (21, 4, NOW()), (21, 5, NOW()),
(21, 6, NOW()), (21, 7, NOW()), (21, 8, NOW()), (21, 9, NOW()), (21, 10, NOW()),
(21, 11, NOW()), (21, 12, NOW()), (21, 13, NOW()), (21, 14, NOW()), (21, 15, NOW()),
(21, 16, NOW()), (21, 17, NOW()), (21, 18, NOW()), (21, 19, NOW()), (21, 20, NOW()),
(21, 21, NOW()), (21, 22, NOW()), (21, 23, NOW()), (21, 24, NOW()), (21, 25, NOW()),
-- 記事22: 12いいね
(22, 1, NOW()), (22, 2, NOW()), (22, 3, NOW()), (22, 4, NOW()), (22, 5, NOW()),
(22, 6, NOW()), (22, 7, NOW()), (22, 8, NOW()), (22, 9, NOW()), (22, 10, NOW()),
(22, 11, NOW()), (22, 12, NOW()),
-- 記事23: 20いいね
(23, 1, NOW()), (23, 2, NOW()), (23, 3, NOW()), (23, 4, NOW()), (23, 5, NOW()),
(23, 6, NOW()), (23, 7, NOW()), (23, 8, NOW()), (23, 9, NOW()), (23, 10, NOW()),
(23, 11, NOW()), (23, 12, NOW()), (23, 13, NOW()), (23, 14, NOW()), (23, 15, NOW()),
(23, 16, NOW()), (23, 17, NOW()), (23, 18, NOW()), (23, 19, NOW()), (23, 20, NOW()),
-- 記事24: 10いいね
(24, 1, NOW()), (24, 2, NOW()), (24, 3, NOW()), (24, 4, NOW()), (24, 5, NOW()),
(24, 6, NOW()), (24, 7, NOW()), (24, 8, NOW()), (24, 9, NOW()), (24, 10, NOW()),
-- 記事25: 5いいね
(25, 1, NOW()), (25, 2, NOW()), (25, 3, NOW()), (25, 4, NOW()), (25, 5, NOW()),
-- 記事26: 10いいね
(26, 1, NOW()), (26, 2, NOW()), (26, 3, NOW()), (26, 4, NOW()), (26, 5, NOW()),
(26, 6, NOW()), (26, 7, NOW()), (26, 8, NOW()), (26, 9, NOW()), (26, 10, NOW()),
-- 記事27: 30いいね（ユーザー1〜30）
(27, 1, NOW()), (27, 2, NOW()), (27, 3, NOW()), (27, 4, NOW()), (27, 5, NOW()),
(27, 6, NOW()), (27, 7, NOW()), (27, 8, NOW()), (27, 9, NOW()), (27, 10, NOW()),
(27, 11, NOW()), (27, 12, NOW()), (27, 13, NOW()), (27, 14, NOW()), (27, 15, NOW()),
(27, 16, NOW()), (27, 17, NOW()), (27, 18, NOW()), (27, 19, NOW()), (27, 20, NOW()),
(27, 21, NOW()), (27, 22, NOW()), (27, 23, NOW()), (27, 24, NOW()), (27, 25, NOW()),
(27, 26, NOW()), (27, 27, NOW()), (27, 28, NOW()), (27, 29, NOW()), (27, 30, NOW()),
-- 記事28: 7いいね
(28, 1, NOW()), (28, 2, NOW()), (28, 3, NOW()), (28, 4, NOW()),
(28, 5, NOW()), (28, 6, NOW()), (28, 7, NOW()),
-- 記事29: 3いいね
(29, 1, NOW()), (29, 2, NOW()), (29, 3, NOW()),
-- 記事30: 15いいね
(30, 1, NOW()), (30, 2, NOW()), (30, 3, NOW()), (30, 4, NOW()), (30, 5, NOW()),
(30, 6, NOW()), (30, 7, NOW()), (30, 8, NOW()), (30, 9, NOW()), (30, 10, NOW()),
(30, 11, NOW()), (30, 12, NOW()), (30, 13, NOW()), (30, 14, NOW()), (30, 15, NOW()),
-- 記事31: 20いいね
(31, 1, NOW()), (31, 2, NOW()), (31, 3, NOW()), (31, 4, NOW()), (31, 5, NOW()),
(31, 6, NOW()), (31, 7, NOW()), (31, 8, NOW()), (31, 9, NOW()), (31, 10, NOW()),
(31, 11, NOW()), (31, 12, NOW()), (31, 13, NOW()), (31, 14, NOW()), (31, 15, NOW()),
(31, 16, NOW()), (31, 17, NOW()), (31, 18, NOW()), (31, 19, NOW()), (31, 20, NOW()),
-- 記事32: 15いいね
(32, 1, NOW()), (32, 2, NOW()), (32, 3, NOW()), (32, 4, NOW()), (32, 5, NOW()),
(32, 6, NOW()), (32, 7, NOW()), (32, 8, NOW()), (32, 9, NOW()), (32, 10, NOW()),
(32, 11, NOW()), (32, 12, NOW()), (32, 13, NOW()), (32, 14, NOW()), (32, 15, NOW());

-- articlesテーブルのtotal_likesを実際のいいね数で更新
UPDATE articles SET total_likes = 10 WHERE id = 1;
UPDATE articles SET total_likes = 0 WHERE id = 2;
UPDATE articles SET total_likes = 0 WHERE id = 3;
UPDATE articles SET total_likes = 0 WHERE id = 4;
UPDATE articles SET total_likes = 0 WHERE id = 5;
UPDATE articles SET total_likes = 0 WHERE id = 6;
UPDATE articles SET total_likes = 0 WHERE id = 7;
UPDATE articles SET total_likes = 0 WHERE id = 8;
UPDATE articles SET total_likes = 0 WHERE id = 9;
UPDATE articles SET total_likes = 0 WHERE id = 10;
UPDATE articles SET total_likes = 15 WHERE id = 11;
UPDATE articles SET total_likes = 12 WHERE id = 12;
UPDATE articles SET total_likes = 8 WHERE id = 13;
UPDATE articles SET total_likes = 6 WHERE id = 14;
UPDATE articles SET total_likes = 10 WHERE id = 15;
UPDATE articles SET total_likes = 20 WHERE id = 16;
UPDATE articles SET total_likes = 25 WHERE id = 17;
UPDATE articles SET total_likes = 15 WHERE id = 18;
UPDATE articles SET total_likes = 10 WHERE id = 19;
UPDATE articles SET total_likes = 8 WHERE id = 20;
UPDATE articles SET total_likes = 25 WHERE id = 21;
UPDATE articles SET total_likes = 12 WHERE id = 22;
UPDATE articles SET total_likes = 20 WHERE id = 23;
UPDATE articles SET total_likes = 10 WHERE id = 24;
UPDATE articles SET total_likes = 5 WHERE id = 25;
UPDATE articles SET total_likes = 10 WHERE id = 26;
UPDATE articles SET total_likes = 30 WHERE id = 27;
UPDATE articles SET total_likes = 7 WHERE id = 28;
UPDATE articles SET total_likes = 3 WHERE id = 29;
UPDATE articles SET total_likes = 15 WHERE id = 30;
UPDATE articles SET total_likes = 20 WHERE id = 31;
UPDATE articles SET total_likes = 15 WHERE id = 32;

SET FOREIGN_KEY_CHECKS = 1;