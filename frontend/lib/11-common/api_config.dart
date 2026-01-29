import 'package:flutter/foundation.dart';

class ApiConfig {
  // 環境に応じてベースURLを切り替え
  static String get baseUrl {
    // 優先順: 1) ビルド時の --dart-define=API_BASE_URL  2) リリース時は実行中のオリジン 3) 開発時は localhost
    // これにより、本番ビルドで localhost を参照してしまう誤動作を防ぎます。
    const env = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (env.isNotEmpty) return env;

    if (kReleaseMode) {
      // フロントエンドと同一オリジンで API を提供している構成に対応
      final origin = '${Uri.base.scheme}://${Uri.base.authority}';
      return origin;
    } else {
      return 'http://localhost:8080'; // 開発環境向けのデフォルト
    }
  }

  // 各APIのエンドポイント（ここに必要なものを追加していく）
  static String get articlesUrl => '$baseUrl/api/articles';
  static String get companiesUrl => '$baseUrl/api/companies';
  static String get photosUrl => '$baseUrl/api/photos';
  static String get notificationsUrl => '$baseUrl/api/notifications'; // ←追加
  static String get reportUrl => '$baseUrl/api/notice/report'; // ←追加
}
