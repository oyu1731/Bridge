import 'package:flutter/material.dart' as material; // materialをエイリアスでインポート
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/60-ScreenWrapper.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:bridge/config/stripe_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class PlanStatusScreen extends material.StatefulWidget {
  final String userType; // 'student', 'worker', 'company'
  const PlanStatusScreen({material.Key? key, required this.userType})
    : super(key: key);

  @override
  _PlanStatusScreenState createState() => _PlanStatusScreenState();
}

class _PlanStatusScreenState extends material.State<PlanStatusScreen> {
  Future<void> _startWebCheckout(
    int amount,
    String currency,
    String planType,
  ) async {
    if (!kIsWeb) {
      material.ScaffoldMessenger.of(context).showSnackBar(
        const material.SnackBar(
          content: material.Text('この機能はWebブラウザでのみ利用可能です。'),
        ),
      );
      return;
    }

    try {
      // バックエンドからPaymentIntentのclient_secretを取得
      final response = await http.post(
        Uri.parse('${StripeConfig.backendUrl}'), // backendUrlはStripeConfigで定義済み
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': amount,
          'currency': currency,
          'planType': planType,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final String clientSecret = body['clientSecret'];
        final String customerId = body['customerId'];
        final String customerEphemeralKeySecret =
            body['customerEphemeralKeySecret'];

        // PaymentSheetを初期化
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Bridge',
            customerId: customerId, // 顧客IDを適切に設定
            customerEphemeralKeySecret:
                customerEphemeralKeySecret, // エフェメラルキーを適切に設定
            // currency: currency, // initPaymentSheetでは通常不要 - currencyCode の代わりに currency をコメントアウト
          ),
        );

        // PaymentSheetを表示
        await Stripe.instance.presentPaymentSheet();
        material.ScaffoldMessenger.of(context).showSnackBar(
          const material.SnackBar(content: material.Text('支払いが完了しました！')),
        );
      } else {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text('チェックアウトセッションの作成に失敗しました: ${response.body}'),
          ),
        );
      }
    } on StripeException catch (e) {
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(
          content: material.Text('Stripeエラー: ${e.error.localizedMessage}'),
        ),
      );
    } catch (e) {
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text('エラーが発生しました: $e')),
      );
    }
  }

  @override
  material.Widget build(material.BuildContext context) {
    String planTitle = '';
    String planPrice = '';
    String planDescription = '';
    int planAmount = 0;
    String planType = '';

    if (widget.userType == 'student' || widget.userType == 'worker') {
      planTitle = '基本プラン';
      planPrice = '月額 500円';
      planDescription = 'AIトレーニング、企業情報閲覧';
      planAmount = 50000; // 500円 * 100
      planType = '個人基本プラン';
    } else if (widget.userType == 'company') {
      planTitle = '企業基本プラン';
      planPrice = '月額 5,000円';
      planDescription = '求人掲載3件まで';
      planAmount = 500000; // 5000円 * 100
      planType = '企業基本プラン';
    } else {
      planTitle = 'プラン情報なし';
      planPrice = 'N/A';
      planDescription = 'ユーザータイプが不明です。';
      planAmount = 0;
      planType = '不明';
    }

    return material.Scaffold(
      appBar: BridgeHeader(
        // title: const material.Text('プラン状態確認'), // BridgeHeaderにはtitle引数がないため削除
        // onBack: () => material.Navigator.of(context).pop(), // BridgeHeaderにはonBack引数がないため削除
      ),
      body: ScreenWrapper(
        child: material.Center(
          child: material.Column(
            mainAxisAlignment: material.MainAxisAlignment.center,
            children: [
              material.Text(
                '${_getUserTypeText(widget.userType)}向けプラン',
                style: const material.TextStyle(
                  fontSize: 24,
                  fontWeight: material.FontWeight.bold,
                ),
              ),
              const material.SizedBox(height: 20),
              _buildPlanCard(
                context,
                planTitle,
                planPrice,
                planDescription,
                planAmount,
                'jpy',
                planType,
              ),
              const material.SizedBox(height: 40),
              material.ElevatedButton(
                onPressed: () {
                  material.Navigator.of(context).pop(); // 前の画面に戻る
                },
                child: const material.Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  material.Widget _buildPlanCard(
    material.BuildContext context,
    String title,
    String price,
    String description,
    int amount,
    String currency,
    String planType,
  ) {
    return material.Card(
      margin: const material.EdgeInsets.symmetric(horizontal: 20),
      child: material.Padding(
        padding: const material.EdgeInsets.all(20.0),
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            material.Text(
              title,
              style: const material.TextStyle(
                fontSize: 20,
                fontWeight: material.FontWeight.bold,
              ),
            ),
            const material.SizedBox(height: 10),
            material.Text(
              price,
              style: const material.TextStyle(
                fontSize: 18,
                color: material.Colors.blue,
              ),
            ),
            const material.SizedBox(height: 10),
            material.Text(description),
            const material.SizedBox(height: 20),
            material.Align(
              alignment: material.Alignment.centerRight,
              child: material.ElevatedButton(
                onPressed: () {
                  if (amount > 0) {
                    _startWebCheckout(amount, currency, planType);
                  } else {
                    material.ScaffoldMessenger.of(context).showSnackBar(
                      const material.SnackBar(
                        content: material.Text('選択可能なプランがありません。'),
                      ),
                    );
                  }
                },
                child: const material.Text('このプランを選択'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserTypeText(String userType) {
    switch (userType) {
      case 'student':
        return '学生';
      case 'worker':
        return '社会人';
      case 'company':
        return '企業';
      default:
        return '不明なユーザー';
    }
  }
}
