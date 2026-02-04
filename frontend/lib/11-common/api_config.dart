import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kReleaseMode) {
      return 'https://api.bridge-tesg.com';
    } else {
      return 'http://localhost:8080'; // ← ★必須（http付き）
    }
  }

  static String get articlesUrl => '$baseUrl/api/articles';
  static String get companiesUrl => '$baseUrl/api/companies';
  static String get photosUrl => '$baseUrl/api/photos';
  static String get notificationsUrl => '$baseUrl/api/notifications';
  static String get reportUrl => '$baseUrl/api/notice/report';

  // ユーザー関連
  static String userPlanStatusUrl(int userId) =>
      '$baseUrl/api/users/$userId/plan-status';
  static String userUrl(int userId) => '$baseUrl/api/users/$userId';

  // 認証
  static String get signinUrl => '$baseUrl/api/auth/signin';
  static String loginByIdUrl(String userId) =>
      '$baseUrl/api/auth/login-by-id/$userId';

  // 決済
  static String get paymentSessionUrl => '$baseUrl/api/v1/payment/session';
  static String paymentSessionDetail(String sessionId) =>
      '$paymentSessionUrl/$sessionId';
  static String get paymentBackendUrl => '$baseUrl/api/v1/payment';
  static String get checkoutSessionUrl =>
      '$baseUrl/api/v1/payment/checkout-session';

  // WebSocket
  static String chatWebSocketUrl(int threadId) {
    final wsBase = baseUrl.replaceFirst('http', 'ws');
    return '$wsBase/ws/chat/$threadId';
  }

  // スレッド
  static String get threadsUrl => '$baseUrl/api/threads';
  static String get threadsUnofficialUrl => '$baseUrl/api/threads/unofficial';

  static String get frontendUrl {
    if (kReleaseMode) {
      return 'https://bridge-tesg.com'; // 本番フロント
    } else {
      return 'http://localhost:5000'; // Flutter Web 開発サーバ
    }
  }
}
