import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/11-common/58-header.dart';

class StudentWorkerHome extends StatefulWidget {
  const StudentWorkerHome({Key? key}) : super(key: key);

  @override
  State<StudentWorkerHome> createState() => _StudentWorkerHomeState();
}

class _StudentWorkerHomeState extends State<StudentWorkerHome> {
  String _savedUser = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('学生・社会人ホーム')
      ),
      // body: Center(
      //   child: Column(
      //     mainAxisAlignment: MainAxisAlignment.center,
      //     children: <Widget>[
      //       // =====================
      //       // セッション保存ボタン
      //       // =====================
      //       ElevatedButton(
      //         onPressed: () async {
      //           // SharedPreferencesのインスタンスを取得
      //           // final prefs = await SharedPreferences.getInstance();

      //           // 'user_test' というキーで文字列データを保存
      //           await prefs.setString('user_test', 'テストユーザー情報');

      //           // デバッグ用にコンソール出力
      //           print('セッションに保存しました: user_test');
      //         },
      //         child: const Text('セッション保存'),
      //       ),

      //       const SizedBox(height: 16),

      //       // =====================
      //       // セッション取得ボタン
      //       // =====================
      //       ElevatedButton(
      //         onPressed: () async {
      //           // SharedPreferencesのインスタンスを取得
      //           // final prefs = await SharedPreferences.getInstance();

      //           // 'user_test' キーで保存したデータを取得
      //           // String? savedUser = prefs.getString('user_test');

      //           // デバッグ用にコンソール出力
      //           print('取得したセッションデータ: $savedUser');
      //           setState(() {
      //             _savedUser = savedUser ?? 'データなし';
      //           });
      //         },
      //         child: const Text('セッション取得'),
      //       ),

      //       const SizedBox(height: 16),

      //       // =====================
      //       // セッション削除ボタン（ログアウト想定）
      //       // =====================
      //       ElevatedButton(
      //         onPressed: () async {
      //           // final prefs = await SharedPreferences.getInstance();

      //           // 保存した 'user_test' データを削除
      //           // await prefs.remove('user_test');

      //           print('セッションを削除しました: user_test');
      //         },
      //         child: const Text('セッション削除'),
      //       ),
      //       Text('保存されたデータ: $_savedUser'),
      //     ],
      //   ),
      // ),
    );
  }
}