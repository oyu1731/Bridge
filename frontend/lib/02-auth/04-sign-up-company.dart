import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/03-home/09-company-home.dart';
import 'package:http/http.dart' as http;
import 'package:payjp_flutter/payjp_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class CompanyInputPage extends StatefulWidget {
  const CompanyInputPage({super.key});

  @override
  State<CompanyInputPage> createState() => _CompanyInputPageState();
}

Future<void> saveSession(dynamic userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(userData));
}

Future<void> _initPayjp() async {
  await Payjp.init(publicKey: 'pk_test_fc1c2a514fc1023cd2fffbab');
}

class _CompanyInputPageState extends State<CompanyInputPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<Map<String, dynamic>> _industries = [];
  List<int> _selectedIndustryIds = [];

  bool _isLoading = true;
  String _errorMessage = '';
  String _industryError = '';

  // 統一カラー
  static const Color cyanDark = Color.fromARGB(255, 0, 100, 120);
  static const Color cyanMedium = Color.fromARGB(255, 24, 147, 178);
  static const Color errororange = Color.fromARGB(255, 239, 108, 0);

  @override
  void initState() {
    super.initState();
    _fetchIndustries();

    final bool _payjpSupported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (_payjpSupported) {
      _initPayjp();
    }
  }

  Future<void> _fetchIndustries() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/industries'),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _industries = data
              .map((item) => {"id": item["id"], "name": item["industry"]})
              .toList();
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
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final pageTheme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        error: Colors.orange[800],
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        errorStyle: const TextStyle(color: errororange),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: errororange),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: errororange, width: 2),
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
          title: const Text('企業サインアップ'),
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
                    labelText: '企業名',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '企業名を入力してください';
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!value.contains('@')) {
                      return '正しいメールアドレスを入力してください';
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
                    hintText: '8文字以上で入力してください',
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
                      return '数字とハイフンのみ使用できます';
                    }
                    if (value.split('-').length - 1 != 2) {
                      return 'ハイフンを2つ含めてください（例: 090-1234-5678）';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '住所',
                    hintText: '正しく入力してください（例：東京都千代田区1-1-1）',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '住所を入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                const Text(
                  '所属業界:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 6, 62, 85)),
                ),

                _isLoading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: _industries.map((industry) {
                          return CheckboxListTile(
                            title: const Text(""
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
                            subtitle: Text(
                              industry["name"],
                              style: const TextStyle(
                                color: cyanDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                if (_industryError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _industryError,
                      style: const TextStyle(color: errororange),
                    ),
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
                    if (!_formKey.currentState!.validate()) {
                      return;
                    }

                    if (_selectedIndustryIds.isEmpty) {
                      setState(() {
                        _industryError = '所属業界を1つ以上選択してください';
                      });
                      return;
                    } else {
                      setState(() {
                        _industryError = '';
                      });
                    }

                    final nickName = _nicknameController.text;
                    final email = _emailController.text;
                    final password = _passwordController.text;
                    final phoneNumber = _phoneNumberController.text;
                    final address = _addressController.text;

                    final url = Uri.parse('http://localhost:8080/api/users');
                    final headers = {
                      'Content-Type': 'application/json; charset=UTF-8',
                    };

                    final body = jsonEncode({
                      'nickname': nickName,
                      'email': email,
                      'password': password,
                      'phoneNumber': phoneNumber,
                      'companyName': nickName,
                      'companyAddress': address,
                      'companyPhoneNumber': phoneNumber,
                      'companyDescription': '',
                      'type': 3,
                      'desiredIndustries': _selectedIndustryIds,
                    });

                    try {
                      final response = await http.post(
                        url,
                        headers: headers,
                        body: body,
                      );

                      if (response.statusCode == 200) {
                        final userData = jsonDecode(response.body);
                        await saveSession(userData);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompanyHome(),
                          ),
                        );
                      } else {
                        final errorMessage = jsonDecode(response.body);
                        setState(() {
                          _errorMessage =
                              errorMessage['message'] ?? 'サインアップに失敗しました';
                        });
                      }
                    } catch (e) {
                      setState(() {
                        _errorMessage = '通信エラーが発生しました: $e';
                      });
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
