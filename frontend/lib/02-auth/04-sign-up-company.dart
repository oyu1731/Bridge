import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/03-home/09-company-home.dart';
import 'package:http/http.dart' as http;
import 'package:payjp_flutter/payjp_flutter.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/services.dart' show MissingPluginException;

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
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  List<Map<String, dynamic>> _industries = [];
  List<int> _selectedIndustryIds = [];

  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchIndustries();
    // Payjp はネイティブ (Android/iOS) のみ対応のため、対応プラットフォームでのみ初期化する
    final bool _payjpSupported = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (_payjpSupported) {
      _initPayjp();
    }
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
      appBar: AppBar(title: const Text('企業サインアップ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '企業名',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'メールアドレス',
              ),
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
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: '住所',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '所属業界:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    children: _industries.map((industry) {
                      return CheckboxListTile(
                        title: Text(industry["name"]),
                        value:
                            _selectedIndustryIds.contains(industry["id"]),
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
            /*課金部分*/ 
            // ElevatedButton(
            //   onPressed: () async {
            //     // Payjp plugin supports only Android/iOS. Skip on other platforms.
            //     final bool supportedPlatform = !kIsWeb &&
            //         (defaultTargetPlatform == TargetPlatform.android ||
            //             defaultTargetPlatform == TargetPlatform.iOS);

            //     if (!supportedPlatform) {
            //       setState(() {
            //         _errorMessage = 'このプラグインは現在のプラットフォームでサポートされていません';
            //       });
            //       return;
            //     }

            //     try {
            //       await Payjp.startCardForm(
            //         onCardFormProducedTokenCallback: (token) async {
            //           // TODO: send token to server
            //           print('Got token: $token');
            //           return CallbackResultOk();
            //         },
            //         onCardFormCompletedCallback: () {
            //           print('Card form completed');
            //         },
            //       );
            //     } on MissingPluginException catch (e) {
            //       // More specific message for plugin not found
            //       print('MissingPluginException: $e');
            //       setState(() {
            //         _errorMessage = '決済プラグインがネイティブ側で見つかりません: $e';
            //       });
            //     } catch (e) {
            //       print('Payjp error: $e');
            //       setState(() {
            //         _errorMessage = '決済フォームの起動に失敗しました: $e';
            //       });
            //     }
            //   },
            //   child: const Text('次へ'),
            // ),

            ElevatedButton(
              onPressed: () async {
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
                    print('✅ 保存したセッションデータ: $userData');

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyHome(),
                      ),
                    );
                  } else {
                    print('❌ サインアップ失敗: ${response.statusCode}');
                    final errorMessage = jsonDecode(response.body);
                    print('❌ エラーメッセージ: $errorMessage');
                    setState(() {
                      _errorMessage =
                          errorMessage['message'] ?? 'サインアップに失敗しました';
                    });
                  }
                } catch (e) {
                  print('❌ 通信エラー: $e');
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
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
