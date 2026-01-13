import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bridge/main.dart';
import 'package:bridge/03-home/09-company-home.dart';

class CompanyInputPage extends StatefulWidget {
  const CompanyInputPage({super.key});

  @override
  State<CompanyInputPage> createState() => _CompanyInputPageState();
}

Future<void> saveSession(dynamic userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(userData));
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

  bool _obscurePassword = true;
  bool _isLoading = true;

  String _errorMessage = '';
  String _industryError = '';

  static const Color cyanDark = Color.fromARGB(255, 0, 100, 120);
  static const Color cyanMedium = Color.fromARGB(255, 24, 147, 178);
  static const Color errorOrange = Color.fromARGB(255, 239, 108, 0);
  static const Color textCyanDark = Color.fromARGB(255, 2, 44, 61);

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

      if (!mounted) return;

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
      if (!mounted) return;
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
        fillColor: MaterialStateProperty.all<Color>(cyanMedium),
        checkColor: MaterialStateProperty.all<Color>(Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: cyanDark, width: 2),
        ),
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: cyanDark),
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
          padding: const EdgeInsets.all(16),
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
                  validator: (v) =>
                      v == null || v.isEmpty ? '企業名を入力してください' : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'メールアドレス',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'メールアドレスを入力してください';
                    }
                    if (!v.contains('@')) {
                      return '正しいメールアドレスを入力してください';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'パスワード',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: textCyanDark,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 8 ? '8文字以上で入力してください' : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '電話番号',
                  ),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                  ],
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '住所',
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  '所属業界:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textCyanDark,
                  ),
                ),

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: _industries.map((industry) {
                          return CheckboxListTile(
                            title: Text(
                              industry['name'],
                              style: const TextStyle(
                                color: cyanDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            value: _selectedIndustryIds
                                .contains(industry['id']),
                            onChanged: (v) {
                              setState(() {
                                if (v == true &&
                                    !_selectedIndustryIds
                                        .contains(industry['id'])) {
                                  _selectedIndustryIds.add(industry['id']);
                                } else {
                                  _selectedIndustryIds
                                      .remove(industry['id']);
                                }
                                _industryError = '';
                              });
                            },
                          );
                        }).toList(),
                      ),

                if (_industryError.isNotEmpty)
                  Text(_industryError,
                      style: const TextStyle(color: errorOrange)),

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
                    if (!_formKey.currentState!.validate()) return;

                    if (_selectedIndustryIds.isEmpty) {
                      setState(() {
                        _industryError = '業界を1つ以上選択してください';
                      });
                      return;
                    }

                    final body = jsonEncode({
                      'nickname': _nicknameController.text,
                      'email': _emailController.text,
                      'password': _passwordController.text,
                      'phoneNumber': _phoneNumberController.text,
                      'companyName': _nicknameController.text,
                      'companyAddress': _addressController.text,
                      'companyPhoneNumber': _phoneNumberController.text,
                      'companyDescription': '',
                      'type': 3,
                      'desiredIndustries': _selectedIndustryIds,
                    });

                    try {
                      final res = await http.post(
                        Uri.parse('http://localhost:8080/api/users'),
                        headers: {
                          'Content-Type': 'application/json; charset=UTF-8'
                        },
                        body: body,
                      );

                      if (res.statusCode == 200) {
                        final userData = jsonDecode(res.body);
                        await saveSession(userData);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CompanyHome(),
                          ),
                        );
                      } else {
                        setState(() {
                          _errorMessage = 'サインアップに失敗しました';
                        });
                      }
                    } catch (e) {
                      if (!mounted) return;
                      setState(() {
                        _errorMessage = '通信エラー: $e';
                      });
                    }
                  },
                  child: const Text('作成'),
                ),

                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
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
