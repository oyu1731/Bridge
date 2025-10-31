@echo off
REM 開発環境を起動するためのバッチファイルです。
REM MySQL、Spring Bootバックエンド（Dockerコンテナ）、Flutterフロントエンド（ローカル）を起動します。
REM
REM チームメンバーへ:
REM   - このファイルをダブルクリックすると、開発環境が自動的にセットアップされます。
REM   - Flutterのホットリロードを有効にするため、Flutterのウィンドウは閉じないでください。

echo Dockerコンテナ (MySQLとSpring Bootバックエンド) を起動中...
cd docker
docker-compose up --build -d
echo Dockerコンテナの状態:
docker-compose ps
cd ..

echo バックエンドが起動するまで待機中... (約30秒)
REM この待機時間は、Spring Bootバックエンドが完全に起動するまでの目安です。
REM 環境によっては調整が必要な場合があります。
timeout /t 30 /nobreak > NUL

echo Spring Bootバックエンドの起動状況を確認中...
curl -s http://localhost:8080/actuator/health | findstr /c:"UP" > NUL
if %errorlevel% equ 0 (
    echo Spring Bootバックエンドは正常に起動しました。
) else (
    echo Spring Bootバックエンドの起動に失敗したか、まだ起動していません。
    echo ログを確認してください: docker-compose logs backend
)

echo Flutterアプリケーションをローカルで起動中...
cd frontend
REM 'start cmd /k' は、新しいコマンドプロンプトウィンドウを開き、その中でコマンドを実行します。
REM これにより、Flutterのホットリロードが可能な状態を維持できます。
REM '-d chrome' はChromeブラウザで起動することを指定します。
REM '--web-port 5000' はWebサーバーのポートを指定します。
start cmd /k "flutter run -d chrome --web-port 5000"

@REM Edgeブラウザで起動したい場合は、上記の行をコメントアウトし、以下の行のコメントを解除してください。
@REM start cmd /k "flutter run -d edge --web-port 5000"
cd ..

echo 開発環境の起動が完了しました。
echo Flutterのホットリロードを有効にするため、Flutterのウィンドウは開いたままにしてください。
echo このウィンドウは閉じても問題ありません。
pause
