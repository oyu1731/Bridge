import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import '../11-common/api_config.dart';

/// Web版 Stripe Checkout
Future<void> startWebCheckout({
  required int amount,
  required String currency,
  required String planType,
  required String userType,
  required int userId,
  String? successUrl,
  String? cancelUrl,
}) async {
  // 注: DB更新は Webhook の handleSuccessfulPayment() で処理されるため、ここでは不要

  // Set default URLs if not provided
  final String effectiveSuccessUrlBase =
      successUrl ?? "${ApiConfig.frontendUrl}/#/payment-success";
  final String effectiveCancelUrl =
      cancelUrl ?? "${ApiConfig.frontendUrl}/#/payment-cancel";

  final payload = {
    "amount": amount,
    "currency": currency,
    "userType": userType,
    "userId": userId,
    "successUrl": effectiveSuccessUrlBase,
    "cancelUrl": effectiveCancelUrl,
  };

  // successUrl に userType と session_id プレースホルダを付与しておく
  final String effectiveSuccessUrl =
      effectiveSuccessUrlBase.contains('?')
          ? '$effectiveSuccessUrlBase&userType=${Uri.encodeComponent(userType)}&session_id={CHECKOUT_SESSION_ID}'
          : '$effectiveSuccessUrlBase?userType=${Uri.encodeComponent(userType)}&session_id={CHECKOUT_SESSION_ID}';

  payload['successUrl'] = effectiveSuccessUrl;

  print("===== Stripe Checkout リクエスト開始 =====");
  print("送信先: ${ApiConfig.checkoutSessionUrl}");
  print("送信データ(JSON): ${jsonEncode(payload)}");

  try {
    final response = await http.post(
      Uri.parse(ApiConfig.checkoutSessionUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    print("Stripeレスポンスコード: ${response.statusCode}");
    print("Stripeレスポンスボディ: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final url = data["url"];

      if (url != null && url.isNotEmpty) {
        print("CheckoutURL: $url へリダイレクトします");
        // ブラウザの新しいタブまたは現在のタブでStripe決済ページを開く
        html.window.location.href = url;
      } else {
        print("エラー: チェックアウトURLが空です");
      }
    } else {
      print("エラー: Stripeセッション作成に失敗しました (Status: ${response.statusCode})");
    }
  } catch (e) {
    print("通信エラー: $e");
  }
}
