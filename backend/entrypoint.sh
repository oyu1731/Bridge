#!/bin/bash

# ===== 初期画像をボリュームにコピー（初回起動のみ）=====
INITIAL_IMAGES_DIR="/app/initial-images"
UPLOADS_DIR="/app/uploads/photos"
INIT_MARKER="/app/uploads/photos/.init_complete"

# uploads/photos ディレクトリを作成（まだなければ）
mkdir -p "$UPLOADS_DIR"

# 初回起動かどうかを確認
if [ ! -f "$INIT_MARKER" ]; then
    echo "[INIT] 初期画像をボリュームにコピー中..."
    
    # initial-images ディレクトリが存在すればコピー
    if [ -d "$INITIAL_IMAGES_DIR" ]; then
        cp -v "$INITIAL_IMAGES_DIR"/* "$UPLOADS_DIR/" 2>/dev/null || true
        echo "[INIT] ✅ 初期画像のコピー完了"
    fi
    
    # 初期化完了マーカーを作成
    touch "$INIT_MARKER"
    echo "[INIT] 初期化フラグを設定しました"
else
    echo "[INIT] 既に初期化済みのため、スキップします"
fi

# ===== Java アプリケーションを起動 =====
echo "[START] Spring Boot アプリケーションを起動します..."
exec java -jar target/backend-0.0.1-SNAPSHOT.jar "$@"
