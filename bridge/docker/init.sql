-- init.sql
-- このファイルは、MySQLデータベースの初期化スクリプトです。
-- Dockerコンテナが起動する際に自動的に実行され、データベースの作成、テーブルの定義、
-- および初期データの挿入を行います。
--
-- チームメンバーへ:
--   - データベースのスキーマ変更や初期データの追加は、このファイルを編集することで行えます。
--   - `DROP TABLE IF EXISTS users;` は開発中にテーブル構造を頻繁に変更する場合に便利ですが、
--     本番環境ではデータが失われる可能性があるため注意が必要です。

-- データベースが存在しない場合のみ作成
CREATE DATABASE IF NOT EXISTS bridgedb;
-- bridgedbデータベースを使用
USE bridgedb;

-- 既存のusersテーブルがあれば削除 (開発用)
DROP TABLE IF EXISTS users;

-- ユーザーテーブルの作成
CREATE TABLE users(
    id BIGINT PRIMARY KEY AUTO_INCREMENT, -- 主キー、自動増分
    name VARCHAR(255) NOT NULL, -- ユーザー名 (必須)
    email VARCHAR(255) UNIQUE NOT NULL, -- メールアドレス (必須、ユニーク)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 作成日時 (自動設定)
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP -- 更新日時 (自動更新)
);

-- サンプルデータの挿入
INSERT INTO users(name, email) VALUES('山田太郎', 'taro.yamada@example.com');
INSERT INTO users(name, email) VALUES('佐藤花子', 'hanako.sato@example.com');
INSERT INTO users(name, email) VALUES('鈴木一郎', 'ichiro.suzuki@example.com');