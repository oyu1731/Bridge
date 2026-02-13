# Bridge README (2026)
Bridge は Flutter Web (フロントエンド) と Spring Boot (バックエンド) を核とした、モダンなフルスタックアプリケーションです。
この README はアプリの概要、開発の始め方、開発のコツ、本番移行の流れをまとめています。

## アプリ概要
### 全体構成
- フロントエンド: Flutter Web (Firebase Hosting で配信)
- バックエンド: Spring Boot 3.x (Docker で動作)
- データベース: MySQL 8.x (Docker コンテナ)
- 決済: Stripe (stripe-cli で webhook 転送)
- Stripe テストカード (サンドボックス用)
  - 成功パターン: `4242 4242 4242 4242`
  - 失敗パターン: `4000 0000 0000 0002`
  - 有効期限・CVC は任意
  - 参考: https://docs.stripe.com/terminal/references/testing?locale=ja-JP


### API ベース URL
- 開発: http://localhost:8080
- 本番: https://api.bridge-tesg.com

補足:
- ドメイン bridge-tesg.com はお名前ドットコムで取得

## 開発環境の作り方
### 必須ツール
- Docker Desktop
- Flutter SDK (3.7.x 以上)
- VS Code (拡張機能: Dart / Flutter / Spring Boot)
- Java 17 (Docker を使わずにバックエンドを動かす場合のみ)

### 環境変数の作成
[docker/.env](docker/.env) を作成して必要な値を設定します。
このファイルは Git にプッシュしないでください。

#### Stripe
- `STRIPE_API_KEY`: Stripe ダッシュボードのシークレットキー (sk_test_...)
- `STRIPE_WEBHOOK_SECRET`: `stripe listen` 実行時に表示される `whsec_...`

#### Gmail 送信
- `MAIL_USER`: Gmail アドレス
- `MAIL_PASS`: Google のアプリパスワード (16 桁)
- `MAIL_HOST`: smtp.gmail.com
- `MAIL_PORT`: 587

#### データベース
- `MYSQL_ROOT_PASSWORD`: 任意の強力なパスワード
- `MYSQL_DATABASE`: bridgedb
- `MYSQL_USER`: bridgeuser
- `MYSQL_PASSWORD`: bridgepass

## 開発の始め方
### Windows 一括起動
```bat
start_dev.bat
```

このスクリプトで以下を実行します。
- [docker](docker) 配下の Docker サービスをビルド・起動
- [docker/init.sql](docker/init.sql) で初期データ投入
- Flutter Web をポート 5000 で起動

### 手動起動
バックエンド + DB:
```bash
cd docker
docker-compose up -d --build
```

フロントエンド:
```bash
cd frontend
flutter run -d chrome --web-port 5000
```

### ポート一覧
- フロント: http://localhost:5000
- バックエンド: http://localhost:8080
- MySQL: localhost:3306

## 開発のコツ
- バックエンドは MySQL のヘルスチェック完了後に起動します (20-30 秒程度待ち)
- 初期データ更新は [docker/init.sql](docker/init.sql) を編集し、ボリューム削除後に再構築
- API URL はビルドモードで切り替わります (開発は localhost / 本番は本番 URL)

## よく使うコマンド
- Docker 内の MySQL の中身確認
```bash
docker exec -it bridge-mysql mysql -u root -prootpassword
use bridgedb
select * from 〇〇
```

- Git 関連
```bash
git add .
git commit -m "コミットメッセージ"
git push origin <ブランチ名>
git pull origin <ブランチ名>
```

- Firebase 関連
```bash
flutter clean
flutter pub get
flutter build web
firebase deploy --only hosting
```

## トラブルシュート
- バックエンドが起動しない: `docker-compose -f docker/docker-compose.yml logs backend`
- CORS エラー: バックエンドの AllowedOrigins にフロントの URL が含まれているか確認

## 簡単なユーザーマニュアル
### 1. ログイン/サインアップ
- トップ画面で「学生」「社会人」「企業」から登録
- 既存アカウントはサインインでログイン
- ログイン後はユーザー種別に応じたホームへ自動遷移

### 2. 共通の画面操作
- ヘッダーのナビゲーションから主要ページへ移動
- 右上の通知アイコンでお知らせを確認
- プロフィールメニューでプロフィール編集/パスワード変更/ログアウト

### 3. スレッド機能
- 公式スレッド: 運営が作成するテーマ
- 非公式スレッド: ユーザーが作成するテーマ
- 参加条件 (全員/学生のみ/社会人のみ) に応じて表示
- 非公式スレッドは「スレッド作成」から新規作成

### 4. 企業情報/記事
- 企業一覧から企業情報を検索・閲覧
- 企業記事は一覧/詳細で閲覧
- 企業ユーザーは記事投稿/投稿記事一覧を利用可能

### 5. AI トレーニング (学生/社会人)
- AI 練習: 面接/電話/メールなどの練習モード
- 1問1答: クイズ形式の学習

### 6. プラン/決済 (企業)
- プロフィールメニューの「プラン確認」で無料/有料を確認
- 必要に応じてプレミアムへアップグレード

### 7. 管理者機能
- スレッド管理/通報一覧/アカウント管理/お知らせ管理

## 本番環境への移行
注記:
- 開発環境ではドメイン取得は不要です。
- 本番環境 (EC2) ではセキュリティの都合上、独自ドメインの取得が必須です。

### 本番インフラ構成
- ドメイン管理: お名前.com (bridge-tesg.com)
- DNS/CDN: Cloudflare (SSL/TLS 提供)
- サーバー: AWS EC2 (Ubuntu または Amazon Linux)
- 実行環境: Docker / Docker Compose

### Step 1: ドメイン設定 (お名前.com ↔ Cloudflare)
参考検索: https://www.google.com/search?q=%E3%83%89%E3%83%A1%E3%82%A4%E3%83%B3%E3%81%AE%E7%AE%A1%E7%90%86%E6%A8%A9%E9%99%90%E3%82%92%E3%81%8A%E5%90%8D%E5%89%8D.com%E3%81%8B%E3%82%89Cloudflare%E3%81%AB%E7%A7%BB%E3%81%97%E3%81%BE%E3%81%99%E3%80%82

#### Cloudflare でサイト登録
- Cloudflare にログインし「サイトを追加」から bridge-tesg.com を入力
- 無料プランを選択
- Cloudflare から指定される 2 つのネームサーバーをメモ

#### お名前.com でネームサーバー変更
- お名前.com Navi にログイン
- 「ネームサーバーの変更」メニューを開く
- 対象ドメインにチェックし「他のネームサーバーを利用」タブを選択
- Cloudflare でメモした 2 つのネームサーバーを入力して保存

反映には数時間から最大 24 時間かかる場合があります。

### Step 2: Cloudflare 詳細設定
DNS レコード:
- Type: A
- Name: api
- IPv4 address: EC2 のパブリック IP
- Proxy status: Proxied (オレンジ色の雲)

SSL/TLS:
- Encryption mode: Flexible
- ブラウザ ↔ Cloudflare は HTTPS
- Cloudflare ↔ EC2 は HTTP (80)

Edge Certificates:
- Always Use HTTPS: ON

### Step 3: EC2 へデプロイ
セキュリティグループで以下を開放します。
- 80 (HTTP): Cloudflare からのリクエスト受付
- 22 (SSH): メンテナンス用

Cloudflare 無料プラン (80 番固定) に対応するため、Docker 側でポート変換を行います。

```yaml
# docker/docker-compose.yml
services:
    backend:
        ports:
            - "80:8080"
```

起動コマンド:
```bash
git clone https://github.com/oyu1731/Bridge.git
cd Bridge/docker
nano .env
docker-compose up -d --build
```

### Step 4: フロントエンド (Firebase)
API ベース URL が本番を向いているか確認し、ビルドしてデプロイします。

```bash
flutter build web
firebase deploy
```

### 本番疎通確認
- https://api.bridge-tesg.com/api/industries にアクセスし JSON が返ることを確認

### 本番トラブルシュート
- 521 Error: EC2 の 80 番ポートが閉じているか、docker-compose が落ちています
- CORS Error: バックエンドの AllowedOrigins にフロント URL が含まれているか確認

## 主要ディレクトリ
- [frontend](frontend): Flutter Web
- [backend](backend): Spring Boot API
- [docker](docker): Dockerfiles / compose / 初期データ
