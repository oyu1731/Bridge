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
// import 'package:bridge/09-admin/36-admin-home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final String? jsonString = prefs.getString('current_user');

  Widget initialPage;

  if (jsonString != null) {
    final Map<String, dynamic> user = jsonDecode(jsonString);
    final int type = user['type'];
    if (type == 1 || type == 2) {
      initialPage = StudentWorkerHome();
    } else if (type == 3) {
      initialPage = CompanyHome();
    // } else if (type == 4) {
    //   initialPage = AdminHome();
    } else {
      initialPage = const MyHomePage(title: 'Bridge');
    }
  } else {
    initialPage = const MyHomePage(title: 'Bridge');
  }

  runApp(MyApp(initialPage: initialPage));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({super.key, required this.initialPage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bridge App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: initialPage,
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
  late final Map<String, Map<String, dynamic>> sampleUsers;

  /// 円形ボタンが押されたときの処理
  Future<void> _onCircleTap(String label, BuildContext context) async {
    HapticFeedback.selectionClick();
    print('$label が押されました');

    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('current_user');
    if (jsonString != null) {
      print('セッションが存在するため、ホーム画面に遷移します');
      final Map<String, dynamic> user = jsonDecode(jsonString);
      final int type = user['type'];
      Widget? homePage;
      if (type == 1 || type == 2) {
        homePage = StudentWorkerHome();
      } else if (type == 3) {
        homePage =  CompanyHome();
      // } else if (type == 4) {
      //   homePage = AdminHome();
      } else {
        homePage = const MyHomePage(title: 'Bridge');
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => homePage ?? const MyHomePage(title: 'Bridge')));
      return;
    }

    Widget nextPage;
    if (label == '学生') {
      nextPage = const StudentInputPage();
    } else if (label == '社会人') {
      nextPage = const ProfessionalInputPage();
    } else if (label == '企業') {
      nextPage = const CompanyInputPage();
    } else {
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
  }

  Widget _buildCircleButton(String label, IconData icon) {
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 60,
                  color: Color.fromARGB(255, 93, 87, 87),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 32,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
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
        'nickname': '学生ユーザー',
        'type': 1,
        'password': 'hashed_password_student',
        'phone_number': '090-1111-2222',
        'email': 'student@example.com',
        'company_id': null,
        'report_count': 0,
        'plan_status': '無料',
        'is_withdrawn': false,
        'created_at': '2025-11-10',
        'society_history': null,
        'icon': 1,
        'announcement_deletion': 1,
      },
      '社会人': {
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
      },
      '企業': {
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
                  _buildCircleButton('学生', Icons.school),
                  _buildCircleButton('社会人', Icons.work),
                  _buildCircleButton('企業', Icons.business),
                ],
              ),
              const SizedBox(height: 20),
              const Text("デバッグ用: ユーザーセッション操作"),
              const SizedBox(height: 10),
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
                child: const Text("サインインはこちら"),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SignInPage()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
