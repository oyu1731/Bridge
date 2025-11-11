import 'package:flutter/material.dart';
import 'package:bridge/main.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class StudentInputPage extends StatefulWidget {
  const StudentInputPage({super.key});

  @override
  State<StudentInputPage> createState() => _StudentInputPageState();
}

Future<void> saveSession(dynamic userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('user_data', jsonEncode(userData));
}

class _StudentInputPageState extends State<StudentInputPage> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  List<Map<String, dynamic>> _industries = [];
  List<int> _selectedIndustryIds = [];

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchIndustries();
  }

  /// ✅ 業界を ID + 名前 で取得する
  Future<void> _fetchIndustries() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/industries'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          _industries =
              data
                  .map((item) => {"id": item["id"], "name": item["industry"]})
                  .toList();

          _isLoading = false;
        });

        print("✅取得した業界一覧: $_industries");
      } else {
        setState(() {
          _errorMessage = '業界の取得に失敗しました: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'エラーが発生しました: $e';
        _isLoading = false;
      });
      print("❌ 業界取得エラー: $e");
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
                      _industries.map((industry) {
                        return CheckboxListTile(
                          title: Text(industry["name"]),
                          value: _selectedIndustryIds.contains(industry["id"]),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedIndustryIds.add(industry["id"]);
                              } else {
                                _selectedIndustryIds.remove(industry["id"]);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                final nickname = _nicknameController.text;
                final email = _emailController.text;
                final password = _passwordController.text;

                // パスワードをハッシュ化
                final hashedPassword = sha256.convert(utf8.encode(password)).toString();

                final phoneNumber = _phoneNumberController.text;

                // SharedPreferencesインスタンス
                final prefs = await SharedPreferences.getInstance();
                

                // ✅ 業界ID（List<int>）を送信
                final desiredIndustries = _selectedIndustryIds;

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
                  'type': 1, // 学生
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
                    final userData = jsonDecode(response.body);
                    await saveSession(userData);
                    print('✅ 保存したセッションデータ: ${userData}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StudentWorkerHome()),
                    );
                  } else {
                    print('❌ サインアップ失敗: ${response.statusCode}');
                    final errorMessage = jsonDecode(response.body);
                    print('❌ エラーメッセージ: ${errorMessage}');
                  }
                } catch (e) {
                  print('❌ 通信エラー: $e');
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
