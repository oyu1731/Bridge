import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

Future<void> startWebCheckout({
  required int amount,
  required String currency,
  required String planType,
  String successUrl = "http://localhost:5000/#/payment-success",
  String cancelUrl = "http://localhost:5000/#/payment-cancel",
}) async {
  try {
    final response = await http.post(
      Uri.parse("http://localhost:8080/api/v1/payment/checkout-session"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "amount": amount,
        "currency": currency,
        "planType": planType,
        "successUrl": successUrl,
        "cancelUrl": cancelUrl,
      }),
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
