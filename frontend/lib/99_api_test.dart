// main.dart
// このファイルはFlutterアプリケーションのエントリポイントです。
// ユーザー一覧を表示し、バックエンドAPIからデータを取得します。

import 'dart:convert'; // JSONデータのエンコード/デコードに使用
import 'package:flutter/foundation.dart'; // プラットフォーム判定 (Webかどうか) やビルドモード判定に使用
import 'package:flutter/material.dart'; // FlutterのUIコンポーネント
import 'package:http/http.dart' as http; // HTTPリクエストの実行に使用

// アプリケーションのエントリポイント
void main() {
  runApp(MyApp()); // MyAppウィジェットを起動
}

// アプリケーションのルートウィジェット
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bridge App', // アプリケーションのタイトル
      theme: ThemeData(primarySwatch: Colors.blue), // アプリケーションのテーマカラー
      home: UserListScreen(), // アプリケーションのホーム画面
    );
  }
}

// ユーザー一覧画面のStatefulWidget
class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  List<User> _users = []; // ユーザーデータのリスト
  bool _isLoading = true; // データロード中かどうかを示すフラグ
  String? _error; // エラーメッセージ

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // 画面初期化時にユーザーデータを取得
  }

  // バックエンドからユーザーデータを取得する非同期メソッド
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true; // ロード中フラグをtrueに設定
      _error = null; // エラーメッセージをクリア
    });

    try {
      // ★ URL判定ロジックの修正
      // kReleaseMode は flutter build web をした時だけ true になります。
      final String baseUrl;
      if (kReleaseMode) {
        // Firebaseにデプロイした本番環境（独自ドメイン）
        baseUrl = 'https://api.bridge-tesg.com';
      } else {
        // ローカルPCでの開発環境
        baseUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
      }

      final url = Uri.parse('$baseUrl/api/users'); // APIエンドポイントのURLを構築
      print('[DEBUG] Fetching users from: $url');

      final response = await http.get(url); // HTTP GETリクエストを実行

      if (response.statusCode == 200) {
        // ステータスコードが200 (OK) の場合
        List<dynamic> data = json.decode(response.body); // JSON文字列をデコード
        setState(() {
          _users =
              data.map((json) => User.fromJson(json)).toList(); // ユーザーリストを更新
          _isLoading = false;
        });
      } else {
        // エラーの場合
        setState(() {
          _error = 'Failed to load users: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      // 例外が発生した場合
      print('[ERROR] $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ユーザー一覧')), // アプリケーションバー
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator()) // ロード中
              : _error != null
              ? Center(child: Text('エラー: $_error')) // エラー表示
              : ListView.builder(
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name.isNotEmpty ? user.name[0] : '?'),
                    ),
                    title: Text(user.name),
                    subtitle: Text(user.email),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchUsers,
        child: Icon(Icons.refresh),
      ),
    );
  }
}

// Userモデルクラス
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}
