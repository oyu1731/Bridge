import 'dart:convert'; // JSON用
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback用
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/02-auth/02-sign-up-student.dart';
import 'package:bridge/02-auth/03-sign-up-worker.dart';
import 'package:bridge/02-auth/04-sign-up-company.dart';
import 'package:bridge/02-auth/05-sign-in.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/03-home/09-company-home.dart';
import 'package:bridge/09-admin/36-admin-home.dart';
// import 'package:bridge/09-admin/36-admin-home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? jsonString = prefs.getString('current_user');
  print('【Debug】セッション確認: jsonString = $jsonString');

  Widget initialPage;

  if (jsonString != null && jsonString.isNotEmpty) {
    try {
      final Map<String, dynamic> userData = jsonDecode(jsonString);
      final int? type = userData['type'];
      print('ユーザータイプ: $type');
      if (type == 1 || type == 2) {
        print('学生・社会人ホームへ遷移');
        initialPage = const StudentWorkerHome();
      } else if (type == 3) {
        print('企業ホームへ遷移');
        initialPage = const CompanyHome();
      } else if (type == 4) {
        print('管理者ホームへ遷移');
        initialPage = AdminHome();
      } else {
        print('ログイン画面へ遷移（タイプ不正）');
        initialPage = const MyHomePage(title: 'Bridge');
      }
    } catch (e) {
      print('セッション解析エラー: $e');
      initialPage = const MyHomePage(title: 'Bridge');
    }
  } else {
    print('セッションなし - トップ画面へ遷移');
    initialPage = const MyHomePage(title: 'Bridge');
  }

  runApp(MyApp(initialPage: initialPage));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminMailList(), // ← ログインスキップして直接開く
    );
  }
}
