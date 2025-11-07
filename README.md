# Bridgeアプリケーション開発ガイド

このドキュメントは、Bridgeアプリケーションの開発環境のセットアップ、開発手順、および主要なファイルについて説明します。
チームメンバーの皆さんがスムーズに開発を開始できるよう、Spring Bootが初めての方にも分かりやすく解説しています。

## 1. プロジェクト概要

このプロジェクトは、Flutter (フロントエンド) と Spring Boot (バックエンド) をDockerで連携させたアプリケーションです。
データベースにはMySQLを使用しています。

- **フロントエンド**: Flutter (Webアプリケーションとして動作)
- **バックエンド**: Spring Boot (RESTful APIを提供)
- **データベース**: MySQL (Dockerコンテナで動作)
- **開発環境**: Flutterはローカルでホットリロードを有効にして開発し、Spring BootとMySQLはDockerコンテナで起動します。

## 2. 開発環境のセットアップ

### 前提条件

以下のツールがローカル環境にインストールされていることを確認してください。

- **Docker Desktop**: Dockerコンテナを管理するために必要です。
  - [Docker Desktopのインストール](https://www.docker.com/products/docker-desktop)
- **Flutter SDK**: Flutterアプリケーションを開発・実行するために必要です。
  - [Flutter SDKのインストール](https://flutter.dev/docs/get-started/install)
- **Java Development Kit (JDK) 17以上**: Spring Bootアプリケーションをビルド・実行するために必要です。
  - [OpenJDKのダウンロード](https://openjdk.java.net/install/)
- **Maven**: Spring Bootアプリケーションをビルドするために必要です。
  - [Mavenのインストール](https://maven.apache.org/install.html)
- **Visual Studio Code (推奨)**: 開発IDEとして推奨します。
  - [VS Codeのインストール](https://code.visualstudio.com/download)
  - 以下の拡張機能をインストールすると便利です:
    - Dart (Flutter開発用)
    - Spring Boot Extension Pack (Spring Boot開発用)
    - Docker (Dockerファイル操作用)

### 開発環境の起動 (推奨)

プロジェクトルート (`bridge/`) にある `start_dev.bat` ファイルを実行することで、Spring Bootバックエンド、MySQL、およびローカルのFlutterアプリケーションを一発で起動できます。

1.  `bridge/` ディレクトリに移動します。
2.  `start.bat` をダブルクリックして実行します。

これにより、以下の処理が自動的に行われます。

-   `bridge/docker` ディレクトリで `docker-compose up --build -d` が実行され、MySQLとSpring BootバックエンドのDockerコンテナが起動します。
-   Spring Bootバックエンドが起動するまで約15秒間待機します。
-   `bridge/frontend` ディレクトリで `flutter run -d chrome --web-port 5000` が実行され、Flutterアプリケーションが新しいコマンドプロンプトとChromeブラウザで起動します。

**重要**: Flutterのホットリロードを有効にするため、Flutterアプリケーションが起動しているコマンドプロンプトウィンドウは閉じないでください。

### Dockerコンテナの手動起動・停止

`start_dev.bat` を使用しない場合、Dockerコンテナは手動で起動・停止できます。

-   **起動**:
    ```bash
    cd bridge/docker
    docker-compose up --build -d
    ```
-   **停止**:
    ```bash
    cd bridge/docker
    docker-compose down
    ```

### Flutterアプリケーションの手動起動

-   **起動**:
    ```bash
    cd bridge/frontend
    flutter run
    ```

## 3. 主要なファイルとディレクトリ構造

プロジェクトの主要なファイルとディレクトリについて説明します。

### `bridge/` (プロジェクトルート)

-   `README.md`: このファイル。
-   `start.bat`: 開発環境を一発で起動するためのバッチファイル。
-   `.gitignore`: Gitでバージョン管理しないファイルを指定する設定ファイル。

### `bridge/docker/` (Docker関連ファイル)

-   `docker-compose.yml`: Dockerコンテナの定義と連携を設定するファイル。
    -   `mysql`: MySQLデータベースサービス。
    -   `backend`: Spring Bootバックエンドサービス。
    -   `frontend` (コメントアウト): DockerでFlutterを起動する場合のサービス定義。
-   `Dockerfile.backend`: Spring BootバックエンドのDockerイメージをビルドするためのDockerfile。
-   `Dockerfile.frontend`: FlutterフロントエンドのDockerイメージをビルドするためのDockerfile。
-   `nginx.conf`: Nginxのリバースプロキシ設定ファイル。FlutterのWebアプリ配信とバックエンドAPIへのルーティングを定義。
-   `init.sql`: MySQLデータベースの初期化スクリプト。データベース作成、テーブル定義、初期データ挿入を行います。

### `bridge/backend/` (Spring Bootバックエンド)

-   `pom.xml`: Mavenのプロジェクト設定ファイル。依存関係やビルド設定を定義。
-   `src/main/java/com/bridge/backend/`: Javaソースコードのルートディレクトリ。
    -   `BridgeBackendApplication.java`: Spring Bootアプリケーションのエントリポイント。
    -   `controller/UserController.java`: ユーザー情報に関するRESTful APIエンドポイントを定義。
    -   `entity/User.java`: データベースの `users` テーブルに対応するJPAエンティティ。
    -   `repository/UserRepository.java`: `User` エンティティのデータアクセス操作を提供するリポジトリ。
-   `src/main/resources/application.properties`: Spring Bootアプリケーションの設定ファイル。
    -   データベース接続情報、JPA設定、サーバーポート、CORS設定などが含まれます。

### `bridge/frontend/` (Flutterフロントエンド)

-   `pubspec.yaml`: Flutterプロジェクトの設定ファイル。依存関係やアセットを定義。
-   `lib/main.dart`: Flutterアプリケーションのエントリポイント。
    -   ユーザー一覧画面のUIと、バックエンドAPIからのデータ取得ロジックが含まれます。
    -   バックエンドのURL設定 (`baseUrl`) が定義されています。

## 4. 開発のヒント

-   **Spring Bootが初めての方へ**:
    -   `application.properties` でデータベース接続やCORS設定が行われていることを理解しましょう。
    -   `entity` パッケージのクラスはデータベースのテーブル構造に対応し、`repository` パッケージのインターフェースはデータベース操作を抽象化します。
    -   `controller` パッケージのクラスは、APIエンドポイントを定義し、フロントエンドからのリクエストを処理します。
-   **Flutter開発**:
    -   `lib/main.dart` がアプリケーションのメインロジックです。UIの変更やAPI呼び出しの調整はここで行います。
    -   ホットリロードを活用して、素早くUIの変更を確認しましょう。
-   **Docker**:
    -   `docker-compose.yml` を理解することで、サービス間の連携や環境変数の設定方法が分かります。
    -   `Dockerfile` は、各サービスがどのように構築されるかを定義します。

## 5. Docker環境とローカル環境の切り替え

### FlutterをDockerで起動する場合

将来的にFlutterもDockerコンテナで起動したい場合は、以下の手順で設定を変更してください。

1.  `bridge/docker/docker-compose.yml` を開きます。
2.  `frontend:` サービスとその配下のすべての行のコメントアウトを解除します。
3.  `bridge/frontend/lib/main.dart` を開きます。
4.  `_fetchUsers` メソッド内の `baseUrl` の定義を、`http://backend:8080` に変更します。
    ```dart
    final String baseUrl = 'http://backend:8080'; // Docker環境用
    ```
5.  `bridge/docker` ディレクトリで `docker-compose up --build -d` を実行して、すべてのサービスをDockerで起動します。

---

このREADMEファイルは、チームメンバーがプロジェクトを理解し、開発を開始するための包括的なガイドとなるはずです。