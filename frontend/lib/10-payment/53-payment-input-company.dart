import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

Future<void> startWebCheckout(
  int amount,
  String currency,
  String planType,
) async {
  try {
    final response = await http.post(
      Uri.parse("http://localhost:8080/api/payments/create-checkout-session"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "amount": amount,
        "currency": currency,
        "planType": planType,
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
