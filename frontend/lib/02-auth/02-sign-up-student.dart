import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/style.dart'; 

class StudentInputPage extends StatefulWidget {
  const StudentInputPage({super.key});
  @override
  State<StudentInputPage> createState() => _StudentInputPageState();
}

Future<void> saveSession(dynamic userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(userData));
}

// 電話番号フォーマッター
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) return oldValue;

    String formatted;
    if (digits.length >= 7) {
      formatted =
          '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    } else if (digits.length >= 4) {
      formatted = '${digits.substring(0, 3)}-${digits.substring(3)}';
    } else {
      formatted = digits;
    }

    int selectionIndex = newValue.selection.baseOffset;

    if (digits.length >= 4 && selectionIndex > 3) {
      selectionIndex++;
    }
    if (digits.length >= 7 && selectionIndex > 8) {
      selectionIndex++;
    }

    if (selectionIndex > formatted.length) {
      selectionIndex = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}

class _StudentInputPageState extends State<StudentInputPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  List<Map<String, dynamic>> _industries = [];
  List<int> _selectedIndustryIds = [];
  bool _obscurePassword = true;

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
              data
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('学生サインアップ'),
          backgroundColor: AppTheme.cyanMedium,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600, 
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '学生向けのアカウント作成ページです。',
                      style: AppTheme.mainTextStyle,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '※企業または社会人の方は、このページでは登録できません。',
                      style: AppTheme.subTextStyle,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsetsGeometry.only(top: 14),
                          child: Icon(
                            Icons.person_outline,
                            color: AppTheme.cyanDark,
                          )
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsetsGeometry.only(top: 14),
                          child: Icon(
                            Icons.email_outlined,
                            color: AppTheme.cyanDark,
                          )
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'メールアドレス',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return '入力してください';
                              if (!v.contains('@')) return '形式が不正です';
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
                        Padding(padding: EdgeInsetsGeometry.only(top: 14),
                          child: Icon(
                            Icons.lock_outline,
                            color: AppTheme.cyanDark,
                          )
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              labelText: 'パスワード',
                              hintText: '英数字８文字以上で入力してください',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppTheme.cyanDark,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(padding: EdgeInsetsGeometry.only(top: 14),
                          child: Icon(
                            Icons.phone_outlined,
                            color: AppTheme.cyanDark,
                          )
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneNumberController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '電話番号',
                              hintText: 'ハイフンは自動入力されます',
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              PhoneNumberFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return '電話番号を入力してください';
                              }
                              if (!RegExp(r'^\d{3}-\d{4}-\d{4}$').hasMatch(value)) {
                                return '電話番号の形式が正しくありません';
                              }
                              return null;
                            },

                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Padding(padding:  EdgeInsetsGeometry.only(top: 4),
                          child: Icon(
                            Icons.business_outlined,
                            color: AppTheme.cyanDark,
                          )
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '希望業界',
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                        const Text(
                          '　※複数選択可',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _isLoading
                      ? const CircularProgressIndicator()
                      : Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.cyanDark,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: _industries.map((industry) {
                              return CheckboxListTile(
                                title: Text(
                                  industry["name"],
                                  style: const TextStyle(
                                    color: AppTheme.textCyanDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                        ),
                    const SizedBox(height: 20),

                    ElevatedButton(
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
                                  builder: (context) => StudentWorkerHome(),
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
        ),
      ),
    );
  }
}
