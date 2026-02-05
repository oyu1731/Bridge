import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/11-common/58-header.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../03-home/08-student-worker-home.dart';
import '../03-home/09-company-home.dart';
import '../09-admin/36-admin-home.dart';
import '../main.dart';

class CommonErrorPage extends StatelessWidget {
  final int errorCode;
  const CommonErrorPage({Key? key, required this.errorCode}) : super(key: key);

  String get errorMessage {
    switch (errorCode) {
      case 400:
        return 'リクエストが正しくありません（400エラー）';
      case 401:
        return '認証が必要です。再度ログインしてください（401エラー）';
      case 403:
        return 'このリソースにアクセスする権限がありません（403エラー）';
      case 404:
        return 'リクエストされたページが見つかりません（404エラー）';
      case 500:
        return 'サーバーエラーが発生しました。しばらく時間をおいてお試しください（500エラー）';
      default:
        return '予期しないエラーが発生しました';
    }
  }

  String get errorDescription {
    switch (errorCode) {
      case 400:
        return '入力内容に誤りがあります。再度確認してお試しください。';
      case 401:
        return 'セッションの有効期限が切れた可能性があります。';
      case 403:
        return 'このアカウントは当該機能の利用権限がありません。';
      case 404:
        return 'ページが移動または削除された可能性があります。';
      case 500:
        return 'システムに一時的な問題が発生しています。';
      default:
        return 'もう一度お試しいただくか、サポートにお問い合わせください。';
    }
  }

  bool get isAuthError => errorCode == 401;

  Future<Map<String, dynamic>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) {
      return {'isLoggedIn': false, 'type': null};
    }
    final local = jsonDecode(userJson);
    final userId = local['id'];
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
      );
      if (res.statusCode == 200) {
        final api = jsonDecode(res.body);
        // type: 1=学生, 2=社会人, 3=企業, 4=管理者
        return {'isLoggedIn': true, 'type': api['type']};
      }
    } catch (_) {}
    return {'isLoggedIn': true, 'type': null};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      backgroundColor: const Color(0xFFF5FAFC),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getUserInfo(),
          builder: (context, snapshot) {
            final userInfo =
                snapshot.data ?? {'isLoggedIn': false, 'type': null};
            final isLoggedIn = userInfo['isLoggedIn'] ?? false;
            final type = userInfo['type'];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // エラーアイコン
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red.shade600,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // エラーコード
                    Text(
                      'エラー $errorCode',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // エラーメッセージ
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // エラー詳細説明
                    Text(
                      errorDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ボタングループ
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if (isAuthError && !isLoggedIn) {
                              // 401エラーで未ログインの場合、ホーム画面へ
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => MyHomePage(title: 'Bridge'),
                                ),
                                (_) => false,
                              );
                            } else if (isLoggedIn) {
                              // ログイン済みの場合、ホーム画面へ
                              if (type == 4) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => AdminHome(),
                                  ),
                                  (_) => false,
                                );
                              } else if (type == 3) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => CompanyHome(),
                                  ),
                                  (_) => false,
                                );
                              } else {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => StudentWorkerHome(),
                                  ),
                                  (_) => false,
                                );
                              }
                            } else {
                              // 未ログインの場合、ホーム画面へ
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => MyHomePage(title: 'Bridge'),
                                ),
                                (_) => false,
                              );
                            }
                          },
                          icon: const Icon(Icons.home),
                          label: Text(isLoggedIn ? 'TOPページへ戻る' : 'サインインへ戻る'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (isAuthError)
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => MyHomePage(title: 'Bridge'),
                                ),
                                (_) => false,
                              );
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('再度ログインする'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade600,
                              side: BorderSide(color: Colors.blue.shade600),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
