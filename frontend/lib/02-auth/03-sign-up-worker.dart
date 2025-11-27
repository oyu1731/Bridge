import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:bridge/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfessionalInputPage extends StatefulWidget {
  const ProfessionalInputPage({super.key});

  @override
  State<ProfessionalInputPage> createState() => _ProfessionalInputPageState();
}

class _ProfessionalInputPageState extends State<ProfessionalInputPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  String _errorMessage = '';

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('社会人情報入力')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ニックネーム',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'メールアドレス',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'パスワード',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '電話番号',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '会社名',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _positionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '役職',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final nickname = _nicknameController.text;
                final email = _emailController.text;
                final password = _passwordController.text;
                final phoneNumber = _phoneNumberController.text;
                final companyName = _companyNameController.text;
                final position = _positionController.text;

                final url = Uri.parse('http://localhost:8080/api/users');
                final headers = {
                  'Content-Type': 'application/json; charset=UTF-8',
                };

                final body = jsonEncode({
                  'nickname': nickname,
                  'email': email,
                  'password': password,
                  'phoneNumber': phoneNumber,
                  'companyName': companyName,
                  'position': position,
                  'type': 2, // 社会人
                });

                print("📤 送信JSON: $body");

                try {
                  final response = await http.post(
                    url,
                    headers: headers,
                    body: body,
                  );

                  if (response.statusCode == 200) {
                    print('✅ サインアップ成功: ${response.body}');
                    Navigator.pop(context); // 前の画面に戻る
                  } else {
                    print('❌ サインアップ失敗: ${response.statusCode}');
                    final errorMessage = jsonDecode(response.body);
                    print('❌ エラーメッセージ: ${errorMessage}');
                    setState(() {
                      _errorMessage = errorMessage['message'] ?? 'サインアップに失敗しました';
                    });
                  }
                } catch (e) {
                  print('❌ 通信エラー: $e');
                  setState(() {
                    _errorMessage = '通信エラーが発生しました: $e';
                  });
                }
              },
              child: const Text('登録'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
