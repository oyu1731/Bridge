class ApiConfig {
  // 環境に応じてベースURLを切り替え
  static String get baseUrl {
    // 本番環境の判定（例：kReleaseMode、環境変数、ドメインチェックなど）
    if (_isProduction()) {
      return 'https://your-production-domain.com'; // 本番環境のURL
    } else if (_isStaging()) {
      return 'https://your-staging-domain.com'; // ステージング環境のURL
    } else {
      return 'http://localhost:8080'; // 開発環境のURL
    }
  }

  static bool _isProduction() {
    // 本番環境の判定ロジック
    // 例：const bool.fromEnvironment('dart.vm.product')
    // 例：window.location.hostname == 'your-production-domain.com'
    return const bool.fromEnvironment('dart.vm.product');
  }

  static bool _isStaging() {
    // ステージング環境の判定ロジック
    return const bool.fromEnvironment('STAGING', defaultValue: false);
  }

  // 各APIのエンドポイント
  static String get articlesUrl => '$baseUrl/api/articles';
  static String get companiesUrl => '$baseUrl/api/companies';
  static String get photosUrl => '$baseUrl/api/photos';
}