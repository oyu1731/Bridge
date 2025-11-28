import 'dart:convert'; // JSON用
import 'package:bridge/07-ai-training/27-quiz-course-select.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback用
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/02-auth/02-sign-up-student.dart';
import 'package:bridge/02-auth/03-sign-up-worker.dart';
import 'package:bridge/02-auth/04-sign-up-company.dart';
import 'package:bridge/07-ai-training/21-ai-training-list.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'package:bridge/10-payment/53-payment-input-company.dart';
import 'package:bridge/10-payment/54-payment_complete.dart';
import 'package:bridge/10-payment/55-plan_status.dart'; // PlanStatusScreenをインポート

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bridge App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      initialRoute: '/', // 初期ルートを設定
      routes: {
        '/': (context) => const MyHomePage(title: 'Bridge'),
        '/payment-success': (context) => const PaymentSuccessScreen(),
        '/payment-cancel': (context) => const PaymentCancelScreen(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // サンプルユーザー情報
  late final Map<String, Map<String, dynamic>> sampleUsers;

  /// 円形ボタンが押されたときの処理
  void _onCircleTap(String label, BuildContext context) {
    HapticFeedback.selectionClick(); // 軽い振動
    print('$label が押されました');

    Widget nextPage;
    if (label == '学生') {
      nextPage = const CourseSelectionScreen();
    } else if (label == '社会人') {
      // 決済フローを開始
      // 仮の金額、通貨、プランタイプを設定
      startWebCheckout(980, "jpy", "社会人プレミアムプラン");
      return; // 決済画面への遷移はhtml.window.openで行われるため、ここではNavigator.pushは不要
    } else if (label == '企業') {
      nextPage = const AiTrainingListPage(); // AiTrainingListPageに遷移
    } else {
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
  }

  /// 円形ボタン作成
  Widget _buildCircleButton(String label) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: () => _onCircleTap(label, context),
        borderRadius: BorderRadius.circular(100),
        containedInkWell: true,
        splashColor: Colors.blueAccent.withOpacity(0.5),
        child: Container(
          height: 200,
          width: 200,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 選択したユーザーをSharedPreferencesに保存
  Future<void> saveUserSession(String role) async {
    final prefs = await SharedPreferences.getInstance();
    if (sampleUsers.keys.contains(role)) {
      await prefs.setString('current_user', jsonEncode(sampleUsers[role]));
      print('$role のユーザー情報をセッションに保存しました');
    } else {
      print('指定されたユーザーは存在しません');
    }
  }

  /// SharedPreferencesからユーザー情報を取得
  Future<void> loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('current_user');
    if (jsonString != null) {
      final Map<String, dynamic> user = jsonDecode(jsonString);
      print('セッションから取得:');
      print(user);
    } else {
      print('セッションにユーザー情報はありません');
    }
  }

  @override
  void initState() {
    super.initState();
    sampleUsers = {
      '学生': {
        'id': 1,
        'nickname': '学生ユーザー',
        'type': 1,
        'password': 'hashed_password_student',
        'phone_number': '090-1111-2222',
        'email': 'student@example.com',
        'company_id': null,
        'report_count': 0,
        'plan_status': '学生プレミアム',
        'is_withdrawn': false,
        'created_at': '2025-11-10',
        'society_history': null,
        'icon': 1,
        'announcement_deletion': 1,
      },
      '社会人': {
        'id': 2,
        'nickname': '社会人ユーザー',
        'type': 2,
        'password': 'hashed_password_worker',
        'phone_number': '080-3333-4444',
        'email': 'worker@example.com',
        'company_id': null,
        'report_count': 0,
        'plan_status': '無料',
        'is_withdrawn': false,
        'created_at': '2025-11-10',
        'society_history': 5,
        'icon': 2,
        'announcement_deletion': 1,
        'token': 100,
      },
      '企業': {
        'id': 3,
        'nickname': '企業ユーザー',
        'type': 3,
        'password': 'hashed_password_company',
        'phone_number': '070-5555-6666',
        'email': 'company@example.com',
        'company_id': 1,
        'report_count': 0,
        'plan_status': '無料',
        'is_withdrawn': false,
        'created_at': '2025-11-10',
        'society_history': null,
        'icon': 3,
        'announcement_deletion': 1,
        'token': 100,
      },
      '管理者': {
        'nickname': '管理者ユーザー',
        'type': 4,
        'password': 'hashed_password_admin',
        'phone_number': '060-7777-8888',
        'email': 'admin@example.com',
        'company_id': null,
        'report_count': 0,
        'plan_status': '無料',
        'is_withdrawn': false,
        'created_at': '2025-11-10',
        'society_history': null,
        'icon': null,
        'announcement_deletion': 1,
        'token': 100,
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleButton('学生'),
                  _buildCircleButton('社会人'),
                  _buildCircleButton('企業'),
                ],
              ),
              const SizedBox(height: 20),
              const Text("デバッグ用: ユーザーセッション操作"),
              const SizedBox(height: 10),
              // セッション保存ボタン
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton(
                    onPressed: () => saveUserSession('学生'),
                    child: const Text('学生を保存'),
                  ),
                  ElevatedButton(
                    onPressed: () => saveUserSession('社会人'),
                    child: const Text('社会人を保存'),
                  ),
                  ElevatedButton(
                    onPressed: () => saveUserSession('企業'),
                    child: const Text('企業を保存'),
                  ),
                  ElevatedButton(
                    onPressed: () => saveUserSession('管理者'),
                    child: const Text('管理者を保存'),
                  ),
                  ElevatedButton(
                    onPressed: loadUserSession,
                    child: const Text('セッション取得'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  print("サインインはこちら が押されました");
                },
                child: const Text("サインインはこちら"),
              ),
              // テスト用
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  speakWeb("こんにちは、これはテストの読み上げです。");
                },
                child: const Text("テキスト読み上げテスト"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
