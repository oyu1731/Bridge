import 'package:flutter/foundation.dart';

class ApiConfig {
  // 環境に応じてベースURLを切り替え
  static String get baseUrl {
    // kReleaseMode は Flutter がビルド（flutter build web）された時に自動で true になります
    if (kReleaseMode) {
      return 'https://api.bridge-tesg.com'; // ★本番（独自ドメイン）
    } else {
      return 'localhost:8080'; // ★開発（自分のPC）
    }
  }

  // フロントエンド自身のベースURL（リダイレクト用）
  static String get frontendUrl {
    if (kReleaseMode) {
      return 'https://bridge-915bd.web.app';
    } else {
      return 'localhost:5000';
    }
  }

  // 各APIのエンドポイント（ここに必要なものを追加していく）
  static String get articlesUrl => '$baseUrl/api/articles';
  static String get companiesUrl => '$baseUrl/api/companies';
  static String get photosUrl => '$baseUrl/api/photos';
  static String get notificationsUrl => '$baseUrl/api/notifications';
  static String get reportUrl => '$baseUrl/api/notice/report';

  // ユーザー関連
  static String userPlanStatusUrl(int userId) =>
      '$baseUrl/api/users/$userId/plan-status';
  static String userUrl(int userId) => '$baseUrl/api/users/$userId';

  // 認証関連
  static String get signinUrl => '$baseUrl/api/auth/signin';
  static String loginByIdUrl(String userId) =>
      '$baseUrl/api/auth/login-by-id/$userId';

  // 決済関連
  static String get paymentSessionUrl => '$baseUrl/api/v1/payment/session';
  static String paymentSessionDetail(String sessionId) =>
      '$paymentSessionUrl/$sessionId';
  static String get paymentBackendUrl => '$baseUrl/api/v1/payment';
  static String get paymentSuccessUrl => '${frontendUrl}/success';
  static String get paymentCancelUrl => '${frontendUrl}/cancel';

  // 郵便番号API
  static String postcodeUrl(String postcode) =>
      '$baseUrl/api/postcode?postcode=$postcode';

  // 業界API
  static String get industriesUrl => '$baseUrl/api/industries';

  // ユーザー作成
  static String get usersUrl => '$baseUrl/api/users';
  static String userDetailUrl(int userId) =>
      '$baseUrl/api/users/$userId/detail';
  static String userCommentsUrl(int userId) =>
      '$baseUrl/api/users/$userId/comments';
  static String userImageUrl(int userId, String path) => '$baseUrl$path';
  static String userDeleteUrl(int userId) =>
      '$baseUrl/api/users/$userId/delete';
  static String get usersListUrl => '$baseUrl/api/users/list';
  static String usersSearchUrl(String keyword, int type) =>
      '$baseUrl/api/users/search?keyword=${Uri.encodeComponent(keyword)}&type=$type';

  // 決済チェックアウト
  static String get checkoutSessionUrl =>
      '$baseUrl/api/v1/payment/checkout-session';

  // レポート・通知
  static String get reportLogsUrl => '$baseUrl/api/notice/logs';
  static String reportDeleteUrl(int id) =>
      '$baseUrl/api/notice/admin/delete/$id';

  // AI学習・クイズ
  static String get quizCorrectUrl => '$baseUrl/api/quiz/correct';
  static String get quizRankingUrl => '$baseUrl/api/quiz/ranking';

  // WebSocket（チャット）
  static String chatWebSocketUrl(int threadId) {
    String wsBaseUrl;
    if (kReleaseMode) {
      wsBaseUrl = 'wss://api.bridge-tesg.com'; // 本番は wss (SSLあり)
    } else {
      // 開発時はここを api.bridge-tesg.com にするか localhost にするか選べます
      wsBaseUrl = 'wss://api.bridge-tesg.com';
    }
    return '$wsBaseUrl/ws/chat/$threadId';
  }

  // スレッド関連
  static String get threadsUrl => '$baseUrl/api/threads';
  static String get threadsUnofficialUrl => '$baseUrl/api/threads/unofficial';

  // メール修正
  static String get emailCorrectionUrl => '$baseUrl/api/email-correction';

  // サブスクリプション
  static String userCheckSubscriptionUrl(int userId) =>
      '$baseUrl/api/users/$userId/check-subscription';
  static String userSubscriptionsUrl(int userId) =>
      '$baseUrl/api/subscriptions/user/$userId';

  // 通知・メール
  static String get notificationsSendUrl => '$baseUrl/api/notifications/send';

  // 電話練習
  static String get phoneContinueUrl => '$baseUrl/api/phone/continue';
  static String get phoneEndUrl => '$baseUrl/api/phone/end';

  // ユーザー操作
  static String userPasswordUrl(int userId) =>
      '$baseUrl/api/users/$userId/password';

  // 認証
  static String get passwordVerifyOtpUrl => '$baseUrl/api/password/verify-otp';
}
