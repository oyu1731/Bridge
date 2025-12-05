import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

/// Web版 Stripe Checkout
Future<void> startWebCheckout({
  required int amount,
  required String currency,
  required String planType,
  required String userType,
  required int userId,
  String successUrl = "http://localhost:5000/#/payment-success",
  String cancelUrl = "http://localhost:5000/#/payment-cancel",
}) async {
  final payload = {
    "amount": amount,
    "currency": currency,
    "planType": planType,
    "userType": userType,
    "userId": userId,
    "successUrl": successUrl,
    "cancelUrl": cancelUrl,
  };

  print("===== Stripe Checkout リクエスト開始 =====");
  print("送信先: http://localhost:8080/api/v1/payment/checkout-session");
  print("送信データ(JSON): ${jsonEncode(payload)}");

  try {
    final response = await http.post(
      Uri.parse("http://localhost:8080/api/v1/payment/checkout-session"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    print("レスポンスコード: ${response.statusCode}");
    print("レスポンスボディ: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final url = data["url"];

      if (url != null && url.isNotEmpty) {
        print("CheckoutURL: $url へリダイレクトします");
        html.window.open(url, "_self");
      } else {
        print("エラー: Checkout URL が null or 空");
      }
    } else {
      print("サーバーエラー発生: ${response.body}");
    }
  } catch (e) {
    print("通信エラー: $e");
  }

  print("===== Stripe Checkout リクエスト終了 =====");
}
