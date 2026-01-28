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
import 'package:bridge/10-payment/54-payment-complete.dart';

import 'package:flutter/foundation.dart' show kIsWeb; // Web判定
import 'dart:html' as html; // WebのURL取得用
import 'bridge_error_widget.dart';
import '11-common/common_error_page.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// グローバルエラー遷移用のタイマー・フラグ変数
DateTime? _firstGlobalErrorTime;
bool _isGlobalErrorActive = false;
bool _hasNavigatedToErrorPage = false;

void main() async {
    // グローバルエラーハンドリング: 画面ビルドエラー時は共通エラーページ
    ErrorWidget.builder = (FlutterErrorDetails details) => BridgeErrorWidget(details);
    FlutterError.onError = (FlutterErrorDetails details) {
      int errorCode = 500;
      final errorMsg = details.exceptionAsString().toLowerCase();
      if (errorMsg.contains('404')) {
        errorCode = 404;
      } else if (errorMsg.contains('400')) {
        errorCode = 400;
      }
      if (_firstGlobalErrorTime == null) {
        _firstGlobalErrorTime = DateTime.now();
        _isGlobalErrorActive = true;
      }
        if (_isGlobalErrorActive &&
          DateTime.now().difference(_firstGlobalErrorTime!).inMilliseconds >= 10 &&
          !_hasNavigatedToErrorPage) {
        _hasNavigatedToErrorPage = true;
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => CommonErrorPage(errorCode: errorCode)),
          (route) => false,
        );
      }
    };
  WidgetsFlutterBinding.ensureInitialized();

  Widget initialPage;

  // Webの場合、URLをチェックしてリダイレクト先を決定
  if (kIsWeb) {
    final uri = Uri.parse(html.window.location.href);
    final fragment = uri.fragment; // 例: '/payment-success?userType=...'
    print('【Debug】現在のURL: ${html.window.location.href}');
    print('【Debug】URL fragment: $fragment');

    // フラグメントが payment-success / payment-cancel を含む場合は専用ページに遷移
    if (fragment.startsWith('/payment-success') ||
        fragment.startsWith('payment-success')) {
      // フラグメント内のクエリを解析
      String? userType;
      if (fragment.contains('?')) {
        final parts = fragment.split('?');
        if (parts.length > 1) {
          try {
            final qmap = Uri.splitQueryString(parts[1]);
            userType = qmap['userType'];
          } catch (_) {
            userType = null;
          }
        }
      }
      initialPage = PaymentSuccessScreen(userType: userType);
    } else if (fragment.startsWith('/payment-cancel') ||
        fragment.startsWith('payment-cancel')) {
      initialPage = const PaymentCancelScreen();
    } else {
      // 通常のセッションチェック処理
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('current_user');
      if (jsonString != null && jsonString.isNotEmpty) {
        try {
          final Map<String, dynamic> userData = jsonDecode(jsonString);
          final int? type = userData['type'];
          if (type == 1 || type == 2) {
            initialPage = const StudentWorkerHome();
          } else if (type == 3) {
            initialPage = const CompanyHome();
          } else if (type == 4) {
            initialPage = AdminHome();
          } else {
            initialPage = const MyHomePage(title: 'Bridge');
          }
        } catch (e) {
          initialPage = const MyHomePage(title: 'Bridge');
        }
      } else {
        initialPage = const MyHomePage(title: 'Bridge');
      }
    }
  } else {
    // モバイルアプリのセッションチェック処理
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString('current_user');
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> userData = jsonDecode(jsonString);
        final int? type = userData['type'];
        if (type == 1 || type == 2) {
          initialPage = const StudentWorkerHome();
        } else if (type == 3) {
          initialPage = const CompanyHome();
        } else if (type == 4) {
          initialPage = AdminHome();
        } else {
          initialPage = const MyHomePage(title: 'Bridge');
        }
      } catch (e) {
        initialPage = const MyHomePage(title: 'Bridge');
      }
    } else {
      initialPage = const MyHomePage(title: 'Bridge');
    }
  }

  runApp(MyApp(initialPage: initialPage));
}

class MyApp extends StatelessWidget {
  final Widget initialPage;
  const MyApp({super.key, required this.initialPage});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 100, 120),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 100, 120),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          errorStyle: TextStyle(color: Colors.orange[800]),
          errorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orange),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.orange, width: 2),
          ),
        ),
      ),
      title: 'Bridge App',
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => initialPage);
          case '/payment-success':
            return MaterialPageRoute(
              builder: (_) => const PaymentSuccessScreen(),
            );
          case '/payment-cancel':
            return MaterialPageRoute(
              builder: (_) => const PaymentCancelScreen(),
            );
          default:
            return MaterialPageRoute(builder: (_) => initialPage);
        }
      },
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
      final Map<String, dynamic> userData = jsonDecode(jsonString);
      final int type = userData['type'];
      Widget? homePage;
      if (type == 1 || type == 2) {
        homePage = StudentWorkerHome();
      } else if (type == 3) {
        homePage = CompanyHome();
      } else if (type == 4) {
        homePage = AdminHome();
      } else {
        homePage = const MyHomePage(title: 'Bridge');
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => homePage ?? const MyHomePage(title: 'Bridge'),
        ),
      );
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

  Widget _buildCircleButton(String label, IconData icon, {double size = 200}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: () => _onCircleTap(label, context),
        borderRadius: BorderRadius.circular(100),
        containedInkWell: true,
        splashColor: Colors.cyan[700]!,
        child: Container(
          height: size,
          width: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(1, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: size * 0.3,
                  color: const Color.fromARGB(255, 6, 62, 85),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: size * 0.13,
                    color: const Color.fromARGB(255, 6, 62, 85),
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
        'id': 1,
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
        'id': 2,
        'nickname': '社会人ユーザー',
        'type': 2,
        'password': 'hashed_password_worker',
        'phone_number': '080-3333-4444',
        'email': 'worker@example.com',
        'company_id': null,
        'report_count': 0,
        'plan_status': 'プレミアム',
        'is_withdrawn': false,
        'created_at': '2025-11-10',
        'society_history': 5,
        'icon': 2,
        'announcement_deletion': 1,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600; // スマホ判定

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 24, 147, 178),
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'lib/01-images/bridge-logo.png',
                height: 100, // サイズを少し小さく
                width: 220, // 横幅も調整
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Row(
                    children: [
                      Icon(Icons.home_outlined, color: Colors.blue, size: 44),
                      const SizedBox(width: 8),
                      Text(
                        'Bridge',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Text(
                'Bridgeへようこそ！',
                style: TextStyle(
                  fontSize: 23,
                  color: const Color.fromARGB(255, 6, 62, 85),
                ),
              ),
              const Text(
                '以下の３つのタイプから選択して、アカウントを作成してください。',
                style: TextStyle(
                  fontSize: 17,
                  color: const Color.fromARGB(255, 6, 62, 85),
                ),
              ),
              const SizedBox(height: 30),

              // レスポンシブレイアウト
              if (isSmallScreen)
                Column(
                  children: [
                    _buildCircleButton('学生', Icons.school, size: 150),
                    const SizedBox(height: 20),
                    _buildCircleButton('社会人', Icons.work, size: 150),
                    const SizedBox(height: 20),
                    _buildCircleButton('企業', Icons.business, size: 150),
                  ],
                )
              else
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
                child: const Text(
                  "サインインはこちら",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
