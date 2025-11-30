class StripeConfig {
  static const String publishableKey =
      'pk_test_51SXy5IBqY1IqUPbLRXNQHGz9VM0gbFXz9lAGWj1bUL7UR38tpSeYxCPVSzWhiB7GfVltxfvLWZWHX01au79dUc6W0012Ma5KLH'; // Replace with your actual publishable key
  static const String backendUrl =
      'http://localhost:8080/api/v1/payment'; // Adjust as needed
  static const String successUrl =
      'http://localhost:3000/success'; // サクセスURLを追加
  static const String cancelUrl = 'http://localhost:3000/cancel'; // キャンセルURLを追加
}
