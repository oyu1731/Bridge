import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'package:bridge/main.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/style.dart';

class ProfessionalInputPage extends StatefulWidget {
  const ProfessionalInputPage({super.key});

  @override
  State<ProfessionalInputPage> createState() => _ProfessionalInputPageState();
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

class _ProfessionalInputPageState extends State<ProfessionalInputPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _societyHistoryController =
      TextEditingController();

  List<Map<String, dynamic>> _industries = [];
  List<int> _selectedIndustryIds = [];

  bool _isLoading = true;
  bool _obscurePassword = true;

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
      final response =
      // await http.get(Uri.parse('http://localhost:8080/api/industries'));
      await http.get(Uri.parse('https://api.bridge-tesg.com/api/industries'));
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _industries =
              data
                  .map<Map<String, dynamic>>(
                    (item) => {'id': item['id'], 'name': item['industry']},
                  )
                  .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '業界取得に失敗しました';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '通信エラー: $e';
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
    _societyHistoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('社会人サインアップ'),
          backgroundColor: cyanMedium,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '社会人向けのアカウント作成ページです。',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textCyanDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '企業または学生の方は、このページでは登録できません。',
                      style: TextStyle(fontSize: 15, color: textCyanDark),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.only(top: 14),
                          child: Icon(Icons.person_outline, color: cyanDark),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _nicknameController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'ニックネーム',
                            ),
                            validator:
                                (v) =>
                                    v == null || v.isEmpty ? '入力してください' : null,
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
                          child: Icon(Icons.email_outlined, color: cyanDark),
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
                        Padding(
                          padding: EdgeInsetsGeometry.only(top: 14),
                          child: Icon(Icons.lock_outline, color: cyanDark),
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
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: cyanDark,
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
                        Padding(
                          padding: EdgeInsetsGeometry.only(top: 14),
                          child: Icon(Icons.phone_outlined, color: cyanDark),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneNumberController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '電話番号',
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
                              if (!RegExp(
                                r'^\d{3}-\d{4}-\d{4}$',
                              ).hasMatch(value)) {
                                return '電話番号の形式が正しくありません';
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
                          child: Icon(Icons.work_outline, color: cyanDark),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _societyHistoryController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '社会人歴（年）',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            validator:
                                (v) =>
                                    v == null || v.isEmpty ? '入力してください' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsetsGeometry.only(top: 4),
                          child: Icon(Icons.business_outlined, color: cyanDark),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '現職業界',
                          style: TextStyle(fontSize: 17, color: textCyanDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  _industryError.isNotEmpty
                                      ? errorOrange
                                      : cyanDark,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children:
                                _industries.map((industry) {
                                  return CheckboxListTile(
                                    title: Text(
                                      industry['name'],
                                      style: const TextStyle(
                                        color: textCyanDark,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: _selectedIndustryIds.contains(
                                      industry['id'],
                                    ),
                                    activeColor: cyanDark,
                                    onChanged: (v) {
                                      setState(() {
                                        v == true
                                            ? _selectedIndustryIds.add(
                                              industry['id'],
                                            )
                                            : _selectedIndustryIds.remove(
                                              industry['id'],
                                            );
                                      });
                                    },
                                  );
                                }).toList(),
                          ),
                        ),

                    if (_industryError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _industryError,
                          style: const TextStyle(color: errorOrange),
                        ),
                      ),

                    const SizedBox(height: 20),

                    ElevatedButton(
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
                          'societyHistory': int.parse(
                            _societyHistoryController.text,
                          ),
                          'desiredIndustries': _selectedIndustryIds,
                          'type': 2,
                        });

                        try {
                          final res = await http.post(
                            Uri.parse('http://localhost:8080/api/users'),
                            headers: {
                              'Content-Type': 'application/json; charset=UTF-8',
                            },
                            body: body,
                          );

                          if (res.statusCode == 200) {
                            final userData = jsonDecode(res.body);
                            await saveSession(userData);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentWorkerHome(),
                              ),
                            );
                          } else {
                            setState(() {
                              _errorMessage = 'サインアップに失敗しました';
                            });
                          }
                        } catch (e) {
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
        ),
      ),
    );
  }
}
