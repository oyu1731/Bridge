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
import 'package:bridge/03-home/09-company-home.dart';
import 'dart:convert';
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

  // 統一カラー
  static const Color cyanDark = Color.fromARGB(255, 0, 100, 120);
  static const Color cyanMedium = Color.fromARGB(255, 24, 147, 178);
  static const Color errorOrange = Color.fromARGB(255, 239, 108, 0);
  static const Color textCyanDark = Color.fromARGB(255, 2, 44, 61);

  InputDecoration _inputStyle(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cyanMedium, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final pageTheme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        error: Colors.orange[800],
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        errorStyle: const TextStyle(color: errorOrange),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: errorOrange),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: errorOrange, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.all<Color>(cyanDark),
        checkColor: MaterialStateProperty.all<Color>(Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: cyanDark,
      ),
    );
    
    return Theme(
      data: pageTheme,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('サインイン'),
        backgroundColor: cyanMedium,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: _inputStyle('メールアドレス'),
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
                decoration: _inputStyle(
                  'パスワード',
                  hint: '英数字8文字以上で入力してください',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'パスワードを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;

                    String email = _emailController.text;
                    String password = _passwordController.text;

                    try {
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

                      if (response.statusCode == 200) {
                        final userData = jsonDecode(response.body);
                        await saveSession(userData);

                        final int? type = userData['type'];
                        Widget homePage;
                        if (type == 1 || type == 2) {
                          homePage = const StudentWorkerHome();
                        } else if (type == 3) {
                          homePage = const CompanyHome();
                        } else {
                          homePage = const MyHomePage(title: 'Bridge');
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => homePage),
                        );
                      } else {
                        final errorMessage = jsonDecode(response.body);
                        setState(() {
                          _errorMessage =
                              errorMessage['message'] ?? 'サインインに失敗しました';
                        });
                      }
                    } catch (e) {
                      setState(() {
                        _errorMessage = '通信エラーが発生しました: $e';
                      });
                    }
                  },
                  child: const Text('サインイン'),
                ),
              ),

              const SizedBox(height: 10),

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

              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: TextStyle(
                    color: errorOrange,
                    fontWeight: FontWeight.bold,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}