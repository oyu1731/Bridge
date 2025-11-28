import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class StudentInputPage extends StatefulWidget {
  const StudentInputPage({super.key});
  @override
  State<StudentInputPage> createState() => _StudentInputPageState();
}

Future<void> saveSession(dynamic userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(userData));
}

class _StudentInputPageState extends State<StudentInputPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  List<Map<String, dynamic>> _industries = [];
  List<int> _selectedIndustryIds = [];

  bool _isLoading = true;
  String _errorMessage = '';

  // 統一カラー
  static const Color cyanDark = Color.fromARGB(255, 0, 100, 120);
  static const Color cyanMedium = Color.fromARGB(255, 24, 147, 178);
  static const Color errorOrange = Color.fromARGB(255, 239, 108, 0);

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
              data.map((item) => {"id": item["id"], "name": item["industry"]}).toList();
          _isLoading = false;
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
    final base = Theme.of(context);
    final pageTheme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(error: errorOrange),
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
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: cyanDark),
    );

    return Theme(
      data: pageTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('学生サインアップ'),
          backgroundColor: cyanMedium,
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
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'ニックネーム',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'ニックネームを入力してください';
                    }
<<<<<<< HEAD
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
=======
                    return null;
                  },
>>>>>>> tentative
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
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
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
                  '希望業界:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 6, 62, 85),
                  ),
                ),

                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: _industries.map((industry) {
                          return CheckboxListTile(
                            title: Text(
                              industry["name"],
                              style: const TextStyle(
                                color: cyanDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: _selectedIndustryIds.contains(industry["id"]),
                            activeColor: cyanDark,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final nickname = _nicknameController.text;
                      final email = _emailController.text;
                      final password = _passwordController.text;
                      final phoneNumber = _phoneNumberController.text;

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
                        'type': 1,
                      });

                      try {
                        final response = await http.post(url, headers: headers, body: body);
                        if (response.statusCode == 200) {
                          final userData = jsonDecode(response.body);
                          await saveSession(userData);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => StudentWorkerHome()),
                          );
                        } else {
                          final errorMessage = jsonDecode(response.body);
                          setState(() {
                            _errorMessage = errorMessage['message'] ?? 'サインアップに失敗しました';
                          });
                        }
                      } catch (e) {
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
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
