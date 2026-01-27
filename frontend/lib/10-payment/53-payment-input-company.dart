import 'dart:convert';
import 'package:bridge/06-company/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'package:bridge/06-company/api_config.dart';

Future<void> startWebCheckout({
  required int amount,
  required String currency,
  required String companyName,
  required String companyEmail,
  required int? tempId,
  // String successUrl = "http://localhost:5000/#/payment-success",
  String successUrl = "https://bridge-915bd.web.app//#/payment-success",
  // String cancelUrl = "http://localhost:5000/#/payment-cancel",
  String cancelUrl = "https://bridge-915bd.web.app//#/payment-cancel",
}) async {
  final payload = {
    "amount": amount,
    "currency": currency,
    "userType": "company",
    "companyName": companyName,
    "companyEmail": companyEmail,
    "tempId": tempId,
    "successUrl": successUrl,
    "cancelUrl": cancelUrl,
  };

  final String effectiveSuccessUrl =
      successUrl.contains('?')
          ? '$successUrl&session_id={CHECKOUT_SESSION_ID}'
          : '$successUrl?session_id={CHECKOUT_SESSION_ID}';

  payload['successUrl'] = effectiveSuccessUrl;

  print("===== Stripe Checkout リクエスト開始 =====");
  print("送信データ(JSON): ${jsonEncode(payload)}");

  try {
    final response = await http.post(
      // Uri.parse("http://localhost:8080/api/v1/payment/checkout-session"),
      Uri.parse("${ApiConfig.baseUrl}/api/v1/payment/checkout-session"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    print("Stripeレスポンスコード: ${response.statusCode}");
    print("Stripeレスポンスボディ: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final url = data["url"];

      if (url != null && url.isNotEmpty) {
        html.window.location.href = url;
      } else {
        print("❌ エラー: チェックアウトURLが空です");
      }
    } else {
      print("❌ Stripeセッション作成失敗 (Status: ${response.statusCode})");
    }
  } catch (e) {
    print("❌ 通信エラー: $e");
  }
}
