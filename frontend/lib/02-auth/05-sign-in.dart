import 'package:flutter/material.dart';
import 'package:bridge/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/03-home/09-company-home.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
      appBar: AppBar(
        title: const Text('サインイン'),
        backgroundColor: const Color.fromARGB(255, 24, 147, 178),
        foregroundColor: Colors.white,
      ),
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
                      Uri.parse('http://127.0.0.1:8080/api/auth/signin'),
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
                        final int? type = userData['type'];
                        Widget homePage;
                        if (type == 1 || type == 2) {
                          homePage = const StudentWorkerHome();
                        } else if (type == 3) {
                          homePage = const CompanyHome();
                        } else {
                          // 予期しないタイプの場合は、とりあえずトップページに戻す
                          homePage = const MyHomePage(title: 'Bridge');
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => homePage),
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
                    style: TextStyle(color: Colors.orange[800]),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}