import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/11-common/58-header.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../03-home/08-student-worker-home.dart';
import '../03-home/09-company-home.dart';
import '../09-admin/36-admin-home.dart';
import '../main.dart';

class CommonErrorPage extends StatelessWidget {
  final int errorCode;
  const CommonErrorPage({Key? key, required this.errorCode}) : super(key: key);

  String get errorMessage {
    switch (errorCode) {
      case 400:
        return '400エラーが発生しました';
      case 404:
        return '404エラーが発生しました';
      case 500:
        return '500エラーが発生しました';
      default:
        return 'エラーが発生しました';
    }
  }

  Future<Map<String, dynamic>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) {
      return {'isLoggedIn': false, 'type': null};
    }
    final local = jsonDecode(userJson);
    final userId = local['id'];
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
      );
      if (res.statusCode == 200) {
        final api = jsonDecode(res.body);
        // type: 1=学生, 2=社会人, 3=企業, 4=管理者
        return {'isLoggedIn': true, 'type': api['type']};
      }
    } catch (_) {}
    return {'isLoggedIn': true, 'type': null};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      backgroundColor: const Color(0xFFF5FAFC),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _getUserInfo(),
          builder: (context, snapshot) {
            final userInfo =
                snapshot.data ?? {'isLoggedIn': false, 'type': null};
            final isLoggedIn = userInfo['isLoggedIn'] ?? false;
            final type = userInfo['type'];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  errorMessage,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF757575),
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (isLoggedIn) {
                      if (type == 4) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => AdminHome()),
                          (_) => false,
                        );
                      } else if (type == 3) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => CompanyHome()),
                          (_) => false,
                        );
                      } else {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => StudentWorkerHome(),
                          ),
                          (_) => false,
                        );
                      }
                    } else {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => MyHomePage(title: 'Bridge'),
                        ),
                        (_) => false,
                      );
                    }
                  },
                  child: Text(isLoggedIn ? 'TOPページへ' : 'サインインへ戻る'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
