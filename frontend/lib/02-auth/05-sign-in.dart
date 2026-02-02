import 'dart:math';

import 'package:flutter/material.dart';
import 'package:bridge/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '46-forgot-password.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/03-home/09-company-home.dart';
import 'package:bridge/09-admin/36-admin-home.dart';
import 'package:bridge/style.dart';
import 'package:bridge/11-common/url.dart';

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

  bool _obscurePassword = true;
  String _errorMessage = '';

  InputDecoration _inputStyle(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.cyanMedium, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('サインイン'),
          backgroundColor: AppTheme.cyanMedium,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('サインインページです。', style: AppTheme.mainTextStyle),
                    const SizedBox(height: 10),
                    Text(
                      'アカウント未登録の方は、サインアップを行ってください。',
                      style: AppTheme.subTextStyle,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.only(top: 14),
                          child: Icon(
                            Icons.email_outlined,
                            color: AppTheme.cyanDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.only(top: 14),
                          child: Icon(
                            Icons.lock_outlined,
                            color: AppTheme.cyanDark,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: _inputStyle(
                              'パスワード',
                              hint: '英数字8文字以上で入力してください',
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.cyanDark,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: _obscurePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'パスワードを入力してください';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),

                    SizedBox(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          String email = _emailController.text;
                          String password = _passwordController.text;

                          try {
                            var response = await http
                                .post(
                                  // Uri.parse('http://127.0.0.1:8080/api/auth/signin'),
                                  Uri.parse(
                                    '${ApiConfig.baseUrl}/api/auth/signin',
                                  ),
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
                              } else if (type == 4) {
                                homePage = AdminHome();
                              } else {
                                homePage = const MyHomePage(title: 'Bridge');
                              }

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => homePage,
                                ),
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
                            MaterialPageRoute(
                              builder: (context) => ForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text('パスワードを忘れた方'),
                      ),
                    ),

                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: TextStyle(
                          color: AppTheme.errorOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
