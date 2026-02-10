import 'dart:convert'; // JSON用
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback用
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/11-common/bridge_page_transitions.dart';
import 'package:bridge/11-common/bridge_route_observer.dart';
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
import 'package:flutter/foundation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
// グローバルエラー遷移用のタイマー・フラグ変数
DateTime? _firstGlobalErrorTime;
bool _isGlobalErrorActive = false;
bool _hasNavigatedToErrorPage = false;

void main() async {
  // グローバルエラーハンドリング: UI例外はログ出力のみ
  // HTTP エラー処理は safeGet/safePost などの共通関数で行う
  ErrorWidget.builder =
      (FlutterErrorDetails details) => BridgeErrorWidget(details);
  FlutterError.onError = (FlutterErrorDetails details) {
    // UI例外はログ出力のみ、エラーページへは遷移しない
    debugPrint('【Flutter Error】${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
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
        // Temporarily disabled: logo animation on page transitions.
        // pageTransitionsTheme: const PageTransitionsTheme(
        //   builders: {
        //     TargetPlatform.android: BridgeLogoPageTransitionsBuilder(),
        //     TargetPlatform.iOS: BridgeLogoPageTransitionsBuilder(),
        //     TargetPlatform.linux: BridgeLogoPageTransitionsBuilder(),
        //     TargetPlatform.macOS: BridgeLogoPageTransitionsBuilder(),
        //     TargetPlatform.windows: BridgeLogoPageTransitionsBuilder(),
        //     TargetPlatform.fuchsia: BridgeLogoPageTransitionsBuilder(),
        //   },
        // ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 0, 100, 120),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.3),
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
      navigatorObservers: [BridgeRouteObserver(navigatorKey: navigatorKey)],
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
        splashColor: Colors.cyan[700]!.withOpacity(0.6),
        child: Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, const Color.fromARGB(255, 230, 247, 255)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(2, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 4,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: size * 0.4,
                  height: size * 0.4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromARGB(255, 24, 147, 178),
                        const Color.fromARGB(255, 0, 100, 120),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          0,
                          100,
                          120,
                        ).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, size: size * 0.25, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: size * 0.15,
                    color: const Color.fromARGB(255, 6, 62, 85),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _roleEnglish(label),
                  style: TextStyle(
                    fontSize: size * 0.08,
                    color: const Color.fromARGB(
                      255,
                      6,
                      62,
                      85,
                    ).withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 英語ラベル変換
  String _roleEnglish(String jp) {
    switch (jp) {
      case '学生':
        return 'Student';
      case '社会人':
        return 'Professional';
      case '企業':
        return 'Company';
      default:
        return jp;
    }
  }

  Widget _buildRoleCard(String label, IconData icon) {
    final color = const Color.fromARGB(255, 24, 147, 178);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: () => _onCircleTap(label, context),
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color.fromARGB(255, 24, 147, 178).withOpacity(0.2),
          child: Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withOpacity(0.9),
                  const Color.fromARGB(255, 240, 252, 255),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color.fromARGB(255, 230, 240, 245),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(2, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color.fromARGB(255, 24, 147, 178),
                        const Color.fromARGB(255, 0, 100, 120),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          0,
                          100,
                          120,
                        ).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(2, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _roleEnglish(label),
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color.fromARGB(
                            255,
                            6,
                            62,
                            85,
                          ).withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 6, 62, 85),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      6,
                      62,
                      85,
                    ).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Color.fromARGB(255, 6, 62, 85),
                    size: 22,
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
        'icon': null,
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
        'icon': null,
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
        'icon': null,
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
        title: Image.asset(
          'lib/01-images/bridge-logo.png',
          height: 28,
          fit: BoxFit.contain,
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.2),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 245, 252, 255),
              const Color.fromARGB(255, 230, 247, 255),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 32,
                vertical: 20,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  // ロゴ部分（楕円背景：さらに小さく）
                  Container(
                    width: (isSmallScreen ? 160 : 200) + 20,
                    // さらに縦を短くしてコンパクトに
                    height: (isSmallScreen ? 90 : 110) + 8,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999), // ピル型の楕円にする
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'lib/01-images/bridge-logo.png',
                        height: isSmallScreen ? 70 : 90,
                        width: isSmallScreen ? 160 : 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: isSmallScreen ? 160 : 200,
                            height: isSmallScreen ? 70 : 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color.fromARGB(255, 24, 147, 178),
                                  const Color.fromARGB(255, 0, 100, 120),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.handshake,
                                color: Colors.white,
                                size: 50,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // タイトル
                  Text(
                    'Bridgeへようこそ！',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 6, 62, 85),
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // 説明文 - スマホで改行を適切に
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 80,
                    ),
                    child: Text(
                      '以下の３つのタイプから選択して、\nアカウントを作成してください。',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        color: const Color.fromARGB(
                          255,
                          6,
                          62,
                          85,
                        ).withOpacity(0.8),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // レスポンシブレイアウト
                  if (isSmallScreen)
                    Column(
                      children: [
                        _buildRoleCard('学生', Icons.school),
                        const SizedBox(height: 16),
                        _buildRoleCard('社会人', Icons.work),
                        const SizedBox(height: 16),
                        _buildRoleCard('企業', Icons.business),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildCircleButton('学生', Icons.school, size: 220),
                        _buildCircleButton('社会人', Icons.work, size: 220),
                        _buildCircleButton('企業', Icons.business, size: 220),
                      ],
                    ),

                  const SizedBox(height: 40),

                  // 既存ユーザー向けセクション
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color.fromARGB(255, 230, 240, 245),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '既にアカウントをお持ちの方',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color.fromARGB(255, 6, 62, 85),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: isSmallScreen ? double.infinity : 300,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignInPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: const Color.fromARGB(
                                255,
                                24,
                                147,
                                178,
                              ),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: Colors.black.withOpacity(0.3),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, size: 22),
                                SizedBox(width: 10),
                                Text(
                                  'サインイン',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // デバッグセクション（開発時のみ）
                  if (!kReleaseMode) ...[
                    const Divider(height: 40),
                    const Text(
                      "デバッグ用: ユーザーセッション操作",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: () => saveUserSession('学生'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('学生を保存'),
                        ),
                        ElevatedButton(
                          onPressed: () => saveUserSession('社会人'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('社会人を保存'),
                        ),
                        ElevatedButton(
                          onPressed: () => saveUserSession('企業'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('企業を保存'),
                        ),
                        ElevatedButton(
                          onPressed: () => saveUserSession('管理者'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('管理者を保存'),
                        ),
                        ElevatedButton(
                          onPressed: loadUserSession,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('セッション取得'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
