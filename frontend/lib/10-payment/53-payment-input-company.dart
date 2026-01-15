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
  String successUrl = "http://localhost:5000/#/payment-success",
  String cancelUrl = "http://localhost:5000/#/payment-cancel",
}) async {
  try {
    final String successUrlWithParam =
        successUrl.contains('?')
            ? '$successUrl&userType=${Uri.encodeComponent(userType)}&session_id={CHECKOUT_SESSION_ID}'
            : '$successUrl?userType=${Uri.encodeComponent(userType)}&session_id={CHECKOUT_SESSION_ID}';

    final Map<String, dynamic> payload = {
      "amount": amount,
      "currency": currency,
      "planType": planType,
      "userType": userType,
      "companyName": companyName,
      "companyEmail": companyEmail,
      "successUrl": successUrlWithParam,
      "cancelUrl": cancelUrl,
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
