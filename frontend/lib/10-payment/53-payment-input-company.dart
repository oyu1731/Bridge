import 'dart:convert';
import 'package:bridge/06-company/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

Future<void> startWebCheckout({
  required int amount,
  required String currency,
  required String planType,
  required String companyName,
  required String companyEmail,
  int? tempId,
  String userType = 'company',
  String? successUrl,
  String? cancelUrl,
}) async {
  try {
    // フロントエンドのベースURL（バックエンドではなくフロントエンド）
    final String frontendBaseUrl =
        ApiConfig.baseUrl.contains('localhost')
            ? 'http://localhost:5000' // 開発環境
            : 'https://bridge-915bd.web.app'; // 本番環境（Firebase Hosting）

    final String resolvedSuccessUrl =
        successUrl ?? "$frontendBaseUrl/#/payment-success";
    final String resolvedCancelUrl =
        cancelUrl ?? "$frontendBaseUrl/#/payment-cancel";
    final String successUrlWithParam =
        resolvedSuccessUrl.contains('?')
            ? '$resolvedSuccessUrl&userType=${Uri.encodeComponent(userType)}&session_id={CHECKOUT_SESSION_ID}'
            : '$resolvedSuccessUrl?userType=${Uri.encodeComponent(userType)}&session_id={CHECKOUT_SESSION_ID}';

    final Map<String, dynamic> payload = {
      "amount": amount,
      "currency": currency,
      "planType": planType,
      "userType": userType,
      "companyName": companyName,
      "companyEmail": companyEmail,
      "successUrl": successUrlWithParam,
      "cancelUrl": resolvedCancelUrl,
    };
    if (tempId != null) payload["tempId"] = tempId;

    final response = await http.post(
      // Uri.parse("http://localhost:8080/api/v1/payment/checkout-session"),
      Uri.parse("${ApiConfig.baseUrl}/api/v1/payment/checkout-session"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final url = data["url"];

      // Stripe の Checkout ページへ遷移
      html.window.open(url, "_self");
    } else {
      print("エラー: ${response.body}");
    }
  } catch (e) {
    print("通信エラー: $e");
  }
}
