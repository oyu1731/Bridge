import 'package:flutter/material.dart' as material;
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/60-ScreenWrapper.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:bridge/config/stripe_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // Web用のリダイレクトに必要
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferencesを追加
import 'package:bridge/06-company/api_config.dart'; // ApiConfigを追加

class PlanStatusScreen extends material.StatefulWidget {
  final String userType; // 'student', 'worker', 'company'
  // isPremium, premiumExpiry, currentPlan はAPIから取得するため、ここでは不要になる
  // final bool isPremium; // プレミアムユーザーかどうか
  // final DateTime? premiumExpiry; // プレミアム有効期限
  // final String currentPlan; // 現在のプラン

  const PlanStatusScreen({
    material.Key? key,
    required this.userType,
    // this.isPremium = false,
    // this.premiumExpiry,
    // this.currentPlan = '',
  }) : super(key: key);

  @override
  _PlanStatusScreenState createState() => _PlanStatusScreenState();
}

class _PlanStatusScreenState extends material.State<PlanStatusScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _userData; // ユーザーデータを保持
  bool _isPremium = false; // プレミアムユーザーかどうか
  DateTime? _premiumExpiry; // プレミアム有効期限
  String _currentPlan = '無料'; // 現在のプラン

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // ユーザーデータをロード
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('current_user');

      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> localUserData = jsonDecode(jsonString);
        final int userId = localUserData['id']; // セッションからIDを取得
        print('【Debug】PlanStatusScreen: userId = $userId');

        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'), // ユーザーAPIエンドポイント
          headers: {'Content-Type': 'application/json'},
        );
        print(
          '【Debug】PlanStatusScreen: API Response Status = ${response.statusCode}',
        );
        print('【Debug】PlanStatusScreen: API Response Body = ${response.body}');

        if (response.statusCode == 200) {
          final Map<String, dynamic> apiUserData = json.decode(response.body);
          setState(() {
            _userData = apiUserData;
            _isPremium = apiUserData['planStatus'] == 'プレミアム';
            _currentPlan = apiUserData['planStatus'] ?? '無料';
            print(
              '【Debug】PlanStatusScreen: _isPremium = $_isPremium, _currentPlan = $_currentPlan',
            );

            if (apiUserData['premiumExpiry'] != null) {
              _premiumExpiry = DateTime.parse(apiUserData['premiumExpiry']);
              print(
                '【Debug】PlanStatusScreen: _premiumExpiry = $_premiumExpiry',
              );
            } else {
              _premiumExpiry = null;
              print('【Debug】PlanStatusScreen: _premiumExpiry = null');
            }
          });
        } else {
          material.ScaffoldMessenger.of(context).showSnackBar(
            material.SnackBar(
              content: material.Text('ユーザー情報の取得に失敗しました: ${response.body}'),
            ),
          );
        }
      } else {
        material.ScaffoldMessenger.of(context).showSnackBar(
          const material.SnackBar(content: material.Text('ユーザーセッションが見つかりません。')),
        );
      }
    } catch (e) {
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text('エラーが発生しました: $e')),
      );
      print('ユーザーデータ取得エラー: $e'); // デバッグ用
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Web用のCheckout処理（Stripe Checkout Sessionを使用）
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

    setState(() {
      _isLoading = true;
    });

    try {
      // バックエンドからCheckout SessionのURLを取得
      final response = await http.post(
        Uri.parse(
          '${StripeConfig.backendUrl}/api/payments/create-checkout-session',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'amount': amount ~/ 100, // 円単位に変換
          'currency': currency,
          'planType': planType,
          'successUrl':
              '${StripeConfig.successUrl}?session_id={CHECKOUT_SESSION_ID}',
          'cancelUrl': StripeConfig.cancelUrl,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final String checkoutUrl = body['url'];

        // Stripe Checkoutページへリダイレクト
        html.window.open(checkoutUrl, '_self');
      } else {
        material.ScaffoldMessenger.of(context).showSnackBar(
          material.SnackBar(
            content: material.Text('チェックアウトセッションの作成に失敗しました: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      material.ScaffoldMessenger.of(context).showSnackBar(
        material.SnackBar(content: material.Text('エラーが発生しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // プレミアムユーザー向けの表示内容
  material.Widget _buildPremiumUserContent() {
    final daysLeft =
        _premiumExpiry != null
            ? _premiumExpiry!.difference(DateTime.now()).inDays
            : 0;

    return material.Column(
      children: [
        material.Container(
          padding: const material.EdgeInsets.all(16),
          margin: const material.EdgeInsets.only(bottom: 20),
          decoration: material.BoxDecoration(
            color: material.Colors.green[50],
            borderRadius: material.BorderRadius.circular(12),
            border: material.Border.all(color: material.Colors.green),
          ),
          child: material.Row(
            children: [
              material.Icon(
                material.Icons.check_circle,
                color: material.Colors.green,
                size: 40,
              ),
              const material.SizedBox(width: 16),
              material.Expanded(
                child: material.Column(
                  crossAxisAlignment: material.CrossAxisAlignment.start,
                  children: [
                    material.Text(
                      'プレミアムプラン加入中',
                      style: const material.TextStyle(
                        fontSize: 18,
                        fontWeight: material.FontWeight.bold,
                        color: material.Colors.green,
                      ),
                    ),
                    const material.SizedBox(height: 4),
                    material.Text(
                      '現在のプラン: $_currentPlan',
                      style: const material.TextStyle(fontSize: 14),
                    ),
                    if (_premiumExpiry != null) ...[
                      const material.SizedBox(height: 4),
                      material.Text(
                        daysLeft > 0
                            ? '有効期限: ${_premiumExpiry!.toString().split(' ')[0]} (あと${daysLeft}日)'
                            : '有効期限: ${_premiumExpiry!.toString().split(' ')[0]}',
                        style: material.TextStyle(
                          fontSize: 14,
                          color:
                              daysLeft <= 7
                                  ? material.Colors.orange
                                  : material.Colors.black87,
                          fontWeight:
                              daysLeft <= 7
                                  ? material.FontWeight.bold
                                  : material.FontWeight.normal,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // プレミアム特権の表示
        material.Card(
          child: material.Padding(
            padding: const material.EdgeInsets.all(16),
            child: material.Column(
              crossAxisAlignment: material.CrossAxisAlignment.start,
              children: [
                material.Text(
                  '🎉 プレミアム特権',
                  style: const material.TextStyle(
                    fontSize: 18,
                    fontWeight: material.FontWeight.bold,
                  ),
                ),
                const material.SizedBox(height: 12),
                _buildFeatureRow('AIトレーニング機能', true),
                _buildFeatureRow('企業情報閲覧', true),
                if (widget.userType == 'company')
                  _buildFeatureRow('求人掲載（3件まで）', true),
                _buildFeatureRow('優先サポート', true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 無料ユーザー向けの表示内容
  material.Widget _buildFreeUserContent() {
    return material.Column(
      children: [
        material.Container(
          padding: const material.EdgeInsets.all(16),
          margin: const material.EdgeInsets.only(bottom: 20),
          decoration: material.BoxDecoration(
            color: material.Colors.blue[50],
            borderRadius: material.BorderRadius.circular(12),
            border: material.Border.all(color: material.Colors.blue),
          ),
          child: material.Row(
            children: [
              material.Icon(
                material.Icons.info,
                color: material.Colors.blue,
                size: 40,
              ),
              const material.SizedBox(width: 16),
              material.Expanded(
                child: material.Column(
                  crossAxisAlignment: material.CrossAxisAlignment.start,
                  children: [
                    material.Text(
                      '無料プラン利用中',
                      style: const material.TextStyle(
                        fontSize: 18,
                        fontWeight: material.FontWeight.bold,
                        color: material.Colors.blue,
                      ),
                    ),
                    const material.SizedBox(height: 4),
                    material.Text(
                      'プレミアムプランにアップグレードして、すべての機能を利用しましょう！',
                      style: const material.TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // アップグレード案内
        material.Card(
          child: material.Padding(
            padding: const material.EdgeInsets.all(16),
            child: material.Column(
              crossAxisAlignment: material.CrossAxisAlignment.start,
              children: [
                material.Text(
                  '✨ プレミアムプランにアップグレード',
                  style: const material.TextStyle(
                    fontSize: 18,
                    fontWeight: material.FontWeight.bold,
                  ),
                ),
                const material.SizedBox(height: 12),
                _buildFeatureRow('AIトレーニング機能', false),
                _buildFeatureRow('企業情報閲覧', false),
                if (widget.userType == 'company')
                  _buildFeatureRow('求人掲載（3件まで）', false),
                _buildFeatureRow('優先サポート', false),
                const material.SizedBox(height: 16),
                material.Text(
                  '今すぐアップグレードして、すべての機能を利用しましょう！',
                  style: material.TextStyle(
                    color: material.Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  material.Widget _buildFeatureRow(String feature, bool isAvailable) {
    return material.Padding(
      padding: const material.EdgeInsets.symmetric(vertical: 4),
      child: material.Row(
        children: [
          material.Icon(
            isAvailable
                ? material.Icons.check_circle
                : material.Icons.remove_circle,
            color: isAvailable ? material.Colors.green : material.Colors.grey,
            size: 20,
          ),
          const material.SizedBox(width: 8),
          material.Text(
            feature,
            style: material.TextStyle(
              fontSize: 14,
              color:
                  isAvailable ? material.Colors.black87 : material.Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  material.Widget build(material.BuildContext context) {
    // プラン情報の設定
    String planTitle = '';
    String planPrice = '';
    String planDescription = '';
    int planAmount = 0;
    String planType = '';

    if (widget.userType == 'student' ||
        widget.userType == 'worker' ||
        widget.userType == '学生' ||
        widget.userType == '社会人') {
      planTitle = '個人基本プラン';
      planPrice = '月額 500円';
      planDescription = 'AIトレーニング、企業情報閲覧';
      planAmount = 50000; // 500円 * 100
      planType = '個人基本プラン';
    } else if (widget.userType == 'company' || widget.userType == '企業') {
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
      appBar: BridgeHeader(),
      body: ScreenWrapper(
        child: material.Padding(
          padding: const material.EdgeInsets.all(16.0),
          child: material.Column(
            crossAxisAlignment: material.CrossAxisAlignment.start,
            children: [
              material.Text(
                '${_getUserTypeText(widget.userType)}向けプラン',
                style: const material.TextStyle(
                  fontSize: 24,
                  fontWeight: material.FontWeight.bold,
                ),
              ),
              // デバッグ用
              material.Text('Debug: userType = ${widget.userType}'),
              material.Text('Debug: _isPremium = $_isPremium'),
              material.Text('Debug: _currentPlan = $_currentPlan'),
              if (_premiumExpiry != null)
                material.Text(
                  'Debug: _premiumExpiry = ${_premiumExpiry!.toString().split(' ')[0]}',
                ),
              const material.SizedBox(height: 20),

              // ユーザーステータスに応じたコンテンツ表示
              if (_isPremium)
                _buildPremiumUserContent()
              else
                _buildFreeUserContent(),

              const material.SizedBox(height: 30),

              // プランカード（無料ユーザーのみ表示）
              if (!_isPremium)
                _buildPlanCard(
                  context,
                  planTitle,
                  planPrice,
                  planDescription,
                  planAmount,
                  'jpy',
                  planType,
                ),

              const material.Spacer(),

              // 戻るボタン
              material.Center(
                child: material.ElevatedButton(
                  onPressed: () {
                    material.Navigator.of(context).pop();
                  },
                  child: const material.Text('戻る'),
                ),
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
      elevation: 4,
      child: material.Padding(
        padding: const material.EdgeInsets.all(20.0),
        child: material.Column(
          crossAxisAlignment: material.CrossAxisAlignment.start,
          children: [
            material.Row(
              mainAxisAlignment: material.MainAxisAlignment.spaceBetween,
              children: [
                material.Text(
                  title,
                  style: const material.TextStyle(
                    fontSize: 20,
                    fontWeight: material.FontWeight.bold,
                  ),
                ),
                material.Container(
                  padding: const material.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: material.BoxDecoration(
                    color: material.Colors.blue,
                    borderRadius: material.BorderRadius.circular(20),
                  ),
                  child: material.Text(
                    'おすすめ',
                    style: const material.TextStyle(
                      color: material.Colors.white,
                      fontWeight: material.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const material.SizedBox(height: 10),
            material.Text(
              price,
              style: const material.TextStyle(
                fontSize: 18,
                color: material.Colors.blue,
                fontWeight: material.FontWeight.bold,
              ),
            ),
            const material.SizedBox(height: 10),
            material.Text(
              description,
              style: const material.TextStyle(fontSize: 14),
            ),
            const material.SizedBox(height: 20),
            material.Align(
              alignment: material.Alignment.center,
              child: material.ElevatedButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          if (amount > 0) {
                            _startWebCheckout(amount, currency, planType);
                          }
                        },
                style: material.ElevatedButton.styleFrom(
                  backgroundColor: material.Colors.blue,
                  foregroundColor: material.Colors.white,
                  padding: const material.EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child:
                    _isLoading
                        ? material.Row(
                          mainAxisSize: material.MainAxisSize.min,
                          children: [
                            material.SizedBox(
                              width: 16,
                              height: 16,
                              child: material.CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: material.AlwaysStoppedAnimation<
                                  material.Color
                                >(material.Colors.white),
                              ),
                            ),
                            const material.SizedBox(width: 8),
                            const material.Text('処理中...'),
                          ],
                        )
                        : const material.Text('今すぐアップグレード'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getUserTypeText(String userType) {
    // APIから取得したユーザーデータが`int`型で来る可能性を考慮して対応
    // main.dartでsessionから取得した'type'がintなので、それを文字列として渡すことも考慮
    switch (userType) {
      case '1':
      case 'student':
        return '学生';
      case '2':
      case 'worker':
        return '社会人';
      case '3':
      case 'company':
        return '企業';
      default:
        return '不明なユーザー';
    }
  }
}
