import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:bridge/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CompanyInputPage extends StatefulWidget {
  const CompanyInputPage({super.key});

  @override
  State<CompanyInputPage> createState() => _CompanyInputPageState();
}

class _CompanyInputPageState extends State<CompanyInputPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _responsibleNameController =
      TextEditingController();

  String _errorMessage = '';

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
    _responsibleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('企業情報入力')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '企業名',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _responsibleNameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '担当者名',
              ),
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
            ElevatedButton(
              onPressed: () async {
                final companyName = _companyNameController.text;
                final responsibleName = _responsibleNameController.text;
                final phoneNumber = _phoneNumberController.text;
                final email = _emailController.text;
                final password = _passwordController.text;

                final url = Uri.parse('http://localhost:8080/api/users');
                final headers = {
                  'Content-Type': 'application/json; charset=UTF-8',
                };

                final body = jsonEncode({
                  'companyName': companyName,
                  'responsibleName': responsibleName,
                  'phoneNumber': phoneNumber,
                  'email': email,
                  'password': password,
                  'type': 3, // 企業
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
