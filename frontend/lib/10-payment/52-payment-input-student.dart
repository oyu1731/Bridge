import 'dart:convert';
import 'package:bridge/06-company/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

/// Web版 Stripe Checkout
/// 修正点：Stripeリダイレクト前にバックエンドのサブスクリプション更新APIを実行するようにしました。
Future<void> startWebCheckout({
  required int amount,
  required String currency,
  required String planType,
  required String userType,
  required int userId,
  String successUrl = "http://localhost:5000/#/payment-success",
  String cancelUrl = "http://localhost:5000/#/payment-cancel",
}) async {
  // ---------------------------------------------------------
  // 【追加】決済画面に遷移する前にDBを先行して更新する（学生と同様の挙動）
  // ---------------------------------------------------------
  try {
    print("--- DB先行更新リクエスト開始 ---");
    final dbResponse = await http.post(
      // Uri.parse("http://localhost:8080/api/subscriptions/subscribe"),
      Uri.parse("${ApiConfig.baseUrl}/api/subscriptions/subscribe"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": userId,
        "planName": userType == '社会人' ? "社会人プレミアム" : "プレミアム",
        "durationMonths": 1,
      }),
    );

    if (dbResponse.statusCode == 200) {
      print("✅ DB先行更新成功: ${dbResponse.body}");
    } else {
      print("⚠️ DB更新警告 (Status: ${dbResponse.statusCode}): ${dbResponse.body}");
    }
  } catch (e) {
    print("❌ DB更新エラー (決済処理は続行します): $e");
  }
  // ---------------------------------------------------------

  final payload = {
    "amount": amount,
    "currency": currency,
    "planType": planType,
    "userType": userType,
    "userId": userId,
    "successUrl": successUrl,
    "cancelUrl": cancelUrl,
  };

  // successUrl に userType と session_id プレースホルダを付与しておく
  final String effectiveSuccessUrl =
      successUrl.contains('?')
          ? '$successUrl&userType=${Uri.encodeComponent(userType)}&session_id={CHECKOUT_SESSION_ID}'
          : '$successUrl?userType=${Uri.encodeComponent(userType)}&session_id={CHECKOUT_SESSION_ID}';

  payload['successUrl'] = effectiveSuccessUrl;

  print("===== Stripe Checkout リクエスト開始 =====");
  // print("送信先: http://localhost:8080/api/v1/payment/checkout-session");
  print("送信先: ${ApiConfig.baseUrl}/api/v1/payment/checkout-session");
  print("送信データ(JSON): ${jsonEncode(payload)}");

  try {
    final response = await http.post(
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
