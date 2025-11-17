# 画像アップロードAPI実装完了

## 実装内容

### バックエンド (Java Spring Boot)

1. **PhotoDTO** (`backend/src/main/java/com/bridge/backend/dto/PhotoDTO.java`)
   - 写真情報を転送するためのデータ転送オブジェクト
   - フィールド: id, photoPath, userId

2. **PhotoService** (`backend/src/main/java/com/bridge/backend/service/PhotoService.java`)
   - 画像のアップロード、保存、取得、削除を管理
   - ファイルサイズ検証（最大10MB）
   - 画像形式検証（jpg, jpeg, png, gif, webp）
   - UUIDを使用したユニークなファイル名生成

3. **PhotoController** (`backend/src/main/java/com/bridge/backend/controller/PhotoController.java`)
   - APIエンドポイント:
     - `POST /api/photos/upload` - 画像アップロード
     - `GET /api/photos/{id}` - 写真情報取得
     - `DELETE /api/photos/{id}` - 写真削除

4. **WebMvcConfig** (`backend/src/main/java/com/bridge/backend/config/WebMvcConfig.java`)
   - 静的リソース（アップロードされた画像）の提供設定
   - `/uploads/photos/**` で画像にアクセス可能

5. **application.properties**
   - ファイルアップロード設定追加:
     - `file.upload-dir=uploads/photos`
     - `spring.servlet.multipart.max-file-size=10MB`
     - `spring.servlet.multipart.max-request-size=10MB`

### フロントエンド (Flutter/Dart)

1. **photo_api_client.dart** (`frontend/lib/06-company/photo_api_client.dart`)
   - PhotoDTO クラス
   - PhotoApiClient クラス:
     - `uploadPhoto()` - 画像アップロード
     - `getPhotoById()` - 写真情報取得
     - `deletePhoto()` - 写真削除

2. **19-article-post.dart** 更新
   - photo_api_clientをインポート
   - 記事投稿時に画像を自動アップロード
   - 最大3枚まで対応（photo1Id, photo2Id, photo3Id）
   - エラーハンドリング付き

## 使用方法

### 1. バックエンド起動

```bash
cd backend
./mvnw spring-boot:run
```

### 2. フロントエンドから画像アップロード

記事投稿画面で：
1. 「+」ボタンをクリック
2. カメラまたはギャラリーを選択
3. 画像を選択（最大3枚）
4. タイトルと本文を入力
5. 「投稿」ボタンをクリック

→ 自動的に画像がアップロードされ、記事と紐付けられます

## API仕様

### POST /api/photos/upload

**リクエスト:**
- Content-Type: multipart/form-data
- パラメータ:
  - `file` (required): 画像ファイル
  - `userId` (optional): ユーザーID

**レスポンス (201 Created):**
```json
{
  "id": 1,
  "photoPath": "/uploads/photos/550e8400-e29b-41d4-a716-446655440000.jpg",
  "userId": 123
}
```

### GET /api/photos/{id}

**レスポンス (200 OK):**
```json
{
  "id": 1,
  "photoPath": "/uploads/photos/550e8400-e29b-41d4-a716-446655440000.jpg",
  "userId": 123
}
```

### DELETE /api/photos/{id}

**レスポンス (200 OK):**
```json
"写真を削除しました"
```

## セキュリティとバリデーション

- ファイルサイズ制限: 10MB
- 許可される画像形式: jpg, jpeg, png, gif, webp
- ファイル名はUUIDで自動生成（上書き防止）
- アップロードディレクトリは自動作成

## 注意事項

1. バックエンド起動時に `uploads/photos` ディレクトリが自動作成されます
2. 画像は `/uploads/photos/**` のURLでアクセス可能です
3. データベースには画像パスのみが保存されます（ファイル自体はファイルシステムに保存）

## テスト方法

### curlでテスト

```bash
# 画像アップロード
curl -X POST http://localhost:8080/api/photos/upload \
  -F "file=@/path/to/image.jpg" \
  -F "userId=1"

# 写真情報取得
curl http://localhost:8080/api/photos/1

# 写真削除
curl -X DELETE http://localhost:8080/api/photos/1
```
