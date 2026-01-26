import 'package:flutter/foundation.dart';

class StripeConfig {
  static const String publishableKey =
      'pk_test_51SXy5IBqY1IqUPbLRXNQHGz9VM0gbFXz9lAGWj1bUL7UR38tpSeYxCPVSzWhiB7GfVltxfvLWZWHX01au79dUc6W0012Ma5KLH';

  // 環境に応じてベースとなるドメインを判定
  static String get _backendBaseUrl =>
      kReleaseMode ? 'https://api.bridge-tesg.com' : 'http://localhost:8080';

  static String get _frontendBaseUrl =>
      kReleaseMode
          ? 'https://bridge-915bd.web.app' // ★あなたのFirebase HostingのURL
          : 'http://localhost:3000'; // ローカル開発時のポート

  // 各設定値
  static String get backendUrl => '$_backendBaseUrl/api/v1/payment';
  static String get successUrl => '$_frontendBaseUrl/success';
  static String get cancelUrl => '$_frontendBaseUrl/cancel';
}
