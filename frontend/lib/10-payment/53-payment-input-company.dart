import 'dart:convert';
import 'package:bridge/11-common/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import '../11-common/url.dart' as url;

Future<void> startWebCheckout({
  required int amount,
  required String currency,
  required String companyName,
  required String companyEmail,
  required int? tempId,
  String? successUrl,
  String? cancelUrl,
}) async {
  final String baseUrl = ApiConfig.baseUrl;
  final String effectiveSuccessUrlParam =
      successUrl ?? "${url.ApiConfig.frontendUrl}/#/payment-success";
  final String effectiveCancelUrl =
      cancelUrl ?? "${url.ApiConfig.frontendUrl}/#/payment-cancel";

  final payload = {
    "amount": amount,
    "currency": currency,
    "userType": "company",
    "companyName": companyName,
    "companyEmail": companyEmail,
    "tempId": tempId,
    "successUrl": effectiveSuccessUrlParam,
    "cancelUrl": effectiveCancelUrl,
  };

  final String effectiveSuccessUrl =
      effectiveSuccessUrlParam.contains('?')
          ? '$effectiveSuccessUrlParam&session_id={CHECKOUT_SESSION_ID}'
          : '$effectiveSuccessUrlParam?session_id={CHECKOUT_SESSION_ID}';

  payload['successUrl'] = effectiveSuccessUrl;

  print("===== Stripe Checkout リクエスト開始 =====");
  print("送信データ(JSON): ${jsonEncode(payload)}");

  try {
    final response = await http.post(
      Uri.parse("${url.ApiConfig.frontendUrl}/api/v1/payment/checkout-session"),
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
