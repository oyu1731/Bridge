@echo off
REM 開発環境を起動するためのバッチファイルです。
REM MySQL、Spring Bootバックエンド（Dockerコンテナ）、Flutterフロントエンド（ローカル）を起動します。

REM コマンドプロンプトの文字コードを UTF-8 に変更
chcp 65001 > NUL

echo Dockerコンテナ (MySQLとSpring Bootバックエンド) を起動中...
cd docker
docker-compose build --no-cache
docker-compose up -d
echo Dockerコンテナの状態:
docker-compose ps
cd ..

echo MySQLに初期データを挿入中...
type bridge\docker\init.sql | docker exec -i bridge-mysql mysql -u root -prootpassword bridgedb
if %errorlevel% neq 0 (
    echo 初期データの挿入に失敗しました。
    exit /b %errorlevel%
)
echo 初期データの挿入が完了しました。

echo バックエンドが起動するまで待機中... (約30秒)
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

REM Flutter のポート番号
set PORT=5000

REM 5000ポートを使用しているプロセスがあれば強制終了
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :%PORT% ^| findstr LISTENING') do (
    echo ポート %PORT% を使用しているプロセス %%a を終了します...
    taskkill /PID %%a /F
)

cd frontend
REM Flutter を Chrome で起動
start cmd /k "flutter run -d chrome --web-port %PORT%"

@REM Edgeブラウザで起動したい場合は上記行をコメントアウトし、以下の行を使用
@REM start cmd /k "flutter run -d edge --web-port %PORT%"
cd ..

echo 開発環境の起動が完了しました。
echo Flutterのホットリロードを有効にするため、Flutterのウィンドウは開いたままにしてください。
pause
