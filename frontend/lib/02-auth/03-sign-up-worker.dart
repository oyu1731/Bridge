import 'package:flutter/material.dart';
import 'package:bridge/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class WorkerInputPage extends StatefulWidget {
  const WorkerInputPage({super.key});
  @override
  State<WorkerInputPage> createState() => _WorkerInputPageState();
}
Future<void> saveSession(dynamic userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(userData));
}

class _WorkerInputPageState extends State<WorkerInputPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _societyHistoryController = TextEditingController();

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
      appBar: AppBar(title: const Text('社会人サインアップ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ニックネーム',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'ニックネームを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

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
                if (value.length < 8) {
                  return 'パスワードは8文字以上で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '電話番号',
                hintText: 'ハイフンまで正しく入力してください',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')), // 数字とハイフンだけOK
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '電話番号を入力してください';
                }
                if (!RegExp(r'^[0-9-]+$').hasMatch(value)) {
                  return '有効な電話番号を入力してください';
                }
                if (value.split('-').length - 1 != 2) {
                  return 'ハイフンを正しく入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            const Text(
              '所属業界:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                  children:
                      _industries.map((industry) {
                        return CheckboxListTile(
                          title: Text(industry["name"]),
                          value: _selectedIndustryIds.contains(industry["id"]),
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedIndustryIds.clear();
                              if (value == true) {
                                _selectedIndustryIds.add(industry["id"]);
                              }
                            });
                          },
                        );
                      }).toList(),
                ),

            const SizedBox(height: 20),
            TextFormField(
              controller: _societyHistoryController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '社会人歴（年数）',
                hintText: '整数で入力してください',
              ),
              keyboardType: TextInputType.number, // 数字入力専用キーボード
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // 数字以外を弾く
                LengthLimitingTextInputFormatter(2), // 最大2文字まで
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '社会人歴を入力してください';
                }
                final numValue = int.tryParse(value);
                if (numValue == null) {
                  return '整数で入力してください';
                }
                if (value.length > 2) {
                  return '2桁以内で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final nickname = _nicknameController.text;
                  final email = _emailController.text;
                  final password = _passwordController.text;
                  final societyHistory = int.parse(_societyHistoryController.text);

                  final phoneNumber = _phoneNumberController.text;

                  // SharedPreferencesインスタンス
                  final prefs = await SharedPreferences.getInstance();

                  // 業界ID（List<int>）を送信
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
                    'societyHistory' : societyHistory,
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
                }
              },
              child: const Text('作成'),
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
      ),
    );
  }
}
