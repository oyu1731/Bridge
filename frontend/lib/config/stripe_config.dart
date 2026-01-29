import 'package:bridge/11-common/api_config.dart';

class StripeConfig {
  static const String publishableKey =
      'pk_test_51SXy5IBqY1IqUPbLRXNQHGz9VM0gbFXz9lAGWj1bUL7UR38tpSeYxCPVSzWhiB7GfVltxfvLWZWHX01au79dUc6W0012Ma5KLH'; // Replace with your actual publishable key
  static final String backendUrl =
      '${ApiConfig.baseUrl}/api/v1/payment'; // Adjust as needed
  static final String successUrl = '${ApiConfig.baseUrl}/success'; // サクセスURLを追加
  static final String cancelUrl = '${ApiConfig.baseUrl}/cancel'; // キャンセルURLを追加
}
