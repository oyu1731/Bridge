import 'package:flutter/material.dart';
import 'package:bridge/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'dart:convert';
import 'dart:async';
// 'crypto' を現在は使っていないためコメントアウト（将来ハッシュ等を使うなら戻す）
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '46-forgot-password.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});
  @override
  State<SignInPage> createState() => _SignInPageState();
}
Future<void> saveSession(dynamic userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(userData));
}


class _SignInPageState extends State<SignInPage> {
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  
  String _errorMessage = '';

    @override
  void initState() {
    super.initState();
    // _fetchIndustries();
  }
  //   @override
  // void dispose() {
  //   _emailController.dispose();
  //   _passwordController.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('サインイン')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'メールアドレス',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'メールアドレスを入力してください';
                  }
                  if (!value.contains('@')) {
                    return '有効なメールアドレスを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'パスワード',
                  hintText: '英数字８文字以上で入力してください',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'パスワードを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // フォームが有効な場合の処理
                    String email = _emailController.text;
                    String password = _passwordController.text;

                    // SharedPreferences は saveSession で使うためここでは不要

                    // サインインリクエストの送信
                    // NOTE: ホスト/ポート指定のタイポを修正しました。
                    var response = await http
                        .post(
                      Uri.parse('http://localhost:8080/api/auth/signin'),
                      headers: {'Content-Type': 'application/json'},
                      body: jsonEncode({
                        'email': email,
                        'password': password,
                      }),
                    )
                        .timeout(const Duration(seconds: 10));

                    try {
                      if (response.statusCode == 200) {
                        print('✅ サインイン成功: ${response.body}');
                        final userData = jsonDecode(response.body);
                        await saveSession(userData);
                        print('✅ 保存したセッションデータ: ${userData}');
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => StudentWorkerHome()),
                        );
                      } else {
                        print('❌ サインイン失敗: ${response.statusCode}');
                        final errorMessage = jsonDecode(response.body);
                        print('❌ エラーメッセージ: ${errorMessage}');
                        setState(() {
                          _errorMessage = errorMessage['message'] ?? 'サインインに失敗しました';
                        });
                      }
                    } catch (e) {
                      print('❌ 通信エラー: $e');
                      setState(() {
                        _errorMessage = '通信エラーが発生しました: $e';
                      });
                    }
                  }
                },
                child: const Text('サインイン'),
              ),
                const SizedBox(height: 12),
                if (_errorMessage.isNotEmpty)
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
            // ...existing code...
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                  );
                },
                child: Text('パスワードを忘れた方'),
              ),
            ),
            // ...existing code...
            ],
          ),
        ),
      ),
    );
  }
}