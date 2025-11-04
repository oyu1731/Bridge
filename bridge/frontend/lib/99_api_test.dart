// main.dart
// このファイルはFlutterアプリケーションのエントリポイントです。
// ユーザー一覧を表示し、バックエンドAPIからデータを取得します。

import 'dart:convert'; // JSONデータのエンコード/デコードに使用
import 'package:flutter/foundation.dart'; // プラットフォーム判定 (Webかどうか) に使用
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
// 状態を持つウィジェットで、APIから取得したユーザーデータを表示します。
class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

// UserListScreenの状態を管理するStateクラス
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
      // Web とモバイルで異なるバックエンドURLを使用
      // チームメンバーへ:
      //   - ローカル開発時: Spring Bootバックエンドが `http://localhost:8080` で起動していることを想定しています。
      //   - Docker環境でFlutterも起動する場合: `http://backend:8080` に変更してください。
      final String baseUrl =
          kIsWeb
              ? 'http://localhost:8080' // WebブラウザならPCのlocalhost
              : 'http://10.0.2.2:8080'; // Android Emulatorなら10.0.2.2

      final url = Uri.parse('$baseUrl/api/users'); // APIエンドポイントのURLを構築
      print('[DEBUG] Fetching users from: $url'); // デバッグログ

      final response = await http.get(url); // HTTP GETリクエストを実行

      print('[DEBUG] Response status: ${response.statusCode}'); // デバッグログ
      print('[DEBUG] Response body: ${response.body}'); // デバッグログ

      if (response.statusCode == 200) {
        // ステータスコードが200 (OK) の場合
        List<dynamic> data = json.decode(response.body); // JSON文字列をデコード
        setState(() {
          _users =
              data.map((json) => User.fromJson(json)).toList(); // ユーザーリストを更新
          _isLoading = false; // ロード中フラグをfalseに設定
        });
      } else {
        // エラーの場合
        setState(() {
          _error =
              'Failed to load users: ${response.statusCode}'; // エラーメッセージを設定
          _isLoading = false; // ロード中フラグをfalseに設定
        });
      }
    } catch (e) {
      // 例外が発生した場合
      print('[ERROR] $e'); // エラーログ
      setState(() {
        _error = e.toString(); // エラーメッセージを設定
        _isLoading = false; // ロード中フラグをfalseに設定
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // アプリケーションの基本的な視覚的構造を提供
      appBar: AppBar(title: Text('ユーザー一覧')), // アプリケーションバー
      body:
          _isLoading // ロード中ならインジケーターを表示
              ? Center(child: CircularProgressIndicator())
              : _error !=
                  null // エラーがあればエラーメッセージを表示
              ? Center(child: Text('エラー: $_error'))
              : ListView.builder(
                // ユーザーリストを表示
                itemCount: _users.length, // リストのアイテム数
                itemBuilder: (context, index) {
                  // 各アイテムのビルド
                  final user = _users[index];
                  return ListTile(
                    // リストの各行
                    leading: CircleAvatar(
                      // アイテムの先頭に表示されるアバター
                      child: Text(
                        user.name.isNotEmpty ? user.name[0] : '?',
                      ), // ユーザー名の頭文字
                    ),
                    title: Text(user.name), // ユーザー名
                    subtitle: Text(user.email), // ユーザーメールアドレス
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        // 画面右下のフローティングアクションボタン
        onPressed: _fetchUsers, // ボタンが押されたらユーザーデータを再取得
        child: Icon(Icons.refresh), // 更新アイコン
      ),
    );
  }
}

// Userモデルクラス
// バックエンドから取得するユーザーデータの構造を定義します。
class User {
  final int id; // ユーザーID
  final String name; // ユーザー名
  final String email; // ユーザーメールアドレス

  // コンストラクタ
  User({required this.id, required this.name, required this.email});

  // JSONからUserオブジェクトを生成するファクトリコンストラクタ
  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], name: json['name'], email: json['email']);
  }
}
