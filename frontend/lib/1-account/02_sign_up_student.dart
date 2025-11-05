import 'package:flutter/material.dart';
import 'package:bridge/main.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentInputPage extends StatefulWidget {
  const StudentInputPage({super.key});

  @override
  State<StudentInputPage> createState() => _StudentInputPageState();
}

class _StudentInputPageState extends State<StudentInputPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  List<String> _industries = [];
  final Map<String, bool> _selectedIndustries = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchIndustries();
  }

  Future<void> _fetchIndustries() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/industries'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _industries =
              data.map((item) => item['industry'].toString()).toList();
          for (var industry in _industries) {
            _selectedIndustries[industry] = false;
          }
          _isLoading = false;
          print("取得した中身：$_industries");
        });
      } else {
        setState(() {
          _errorMessage = '業界の取得に失敗しました: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        print("エラー内容：$e");
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学生サインアップ')),
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
            const Text(
              '希望業界:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            _isLoading
                ? const CircularProgressIndicator()
                : _errorMessage.isNotEmpty
                ? Text('エラー: $_errorMessage')
                : Column(
                  children:
                      _industries
                          .map(
                            (industry) => CheckboxListTile(
                              title: Text(industry),
                              value: _selectedIndustries[industry],
                              onChanged: (bool? value) {
                                setState(() {
                                  _selectedIndustries[industry] = value!;
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final nickname = _nicknameController.text;
                final email = _emailController.text;
                final password = _passwordController.text;
                final phoneNumber = _phoneNumberController.text;
                final desiredIndustries =
                    _selectedIndustries.entries
                        .where((entry) => entry.value)
                        .map((entry) => entry.key)
                        .toList();

                final url = Uri.parse('http://localhost:8080/api/users');
                final headers = {
                  'Content-Type': 'application/json; charset=UTF-8',
                };
                final body = jsonEncode({
                  'nickname': nickname,
                  'email': email,
                  'password': password,
                  'phoneNumber': phoneNumber,
                  'desiredIndustries': desiredIndustries,
                });

                try {
                  final response = await http.post(
                    url,
                    headers: headers,
                    body: body,
                  );

                  if (response.statusCode == 200) {
                    print('サインアップ成功: ${response.body}');
                    Navigator.pop(context); // 前の画面に戻る
                  } else {
                    print('サインアップ失敗: ${response.statusCode}');
                    print('エラーメッセージ: ${response.body}');
                    // エラーメッセージをユーザーに表示するなどの処理
                  }
                } catch (e) {
                  print('エラーが発生しました: $e');
                  // ネットワークエラーなどをユーザーに表示する処理
                }
              },
              child: const Text('作成'),
            ),
          ],
        ),
      ),
    );
  }
}
