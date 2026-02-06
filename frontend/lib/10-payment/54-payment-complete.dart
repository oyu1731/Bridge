import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:bridge/03-home/09-company-home.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/02-auth/05-sign-in.dart';
import 'package:bridge/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

// ===============================
// セッション保存関数
// ===============================
Future<void> saveSession(dynamic userData) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('current_user', jsonEncode(userData));
}

// ===============================
// 決済完了画面（軽量版）
// ===============================
class PaymentSuccessScreen extends StatefulWidget {
  final String? userType;
  const PaymentSuccessScreen({Key? key, this.userType}) : super(key: key);

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeInOut,
    );

    _checkController.forward();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _showConfetti = true);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showConfetti = false);
      });
    });

    _handleSessionAndNavigate();
  }

  // ===============================
  // ✅ 決済完了後のユーザー取得 → URLリセットしてトップへ
  // ===============================
  Future<void> _handleSessionAndNavigate() async {
    final sessionId = _extractSessionId();

    if (sessionId == null || sessionId.isEmpty) {
      print('❌ session_id がありません');
      return;
    }

    print('✅ 取得した session_id = $sessionId');

    const int maxAttempts = 6;
    int attempt = 0;
    Map<String, dynamic>? user;

    while (attempt < maxAttempts && mounted) {
      try {
        final res = await http.get(
          Uri.parse(ApiConfig.paymentSessionDetail(sessionId)),
        );
        if (res.statusCode == 200) {
          user = jsonDecode(res.body) as Map<String, dynamic>;
          break;
        }
      } catch (_) {}
      attempt++;
      await Future.delayed(const Duration(seconds: 1));
    }

    if (user == null) {
      print('❌ ユーザー情報取得失敗');
      return;
    }

    print('✅ ユーザーID: ${user['id']}を取得');

    // ✅ バックエンド側でセッション保存
    try {
      final loginRes = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login-by-id/${user['id']}'),
      );
      if (loginRes.statusCode == 200) {
        final sessionUser = jsonDecode(loginRes.body);
        await saveSession(sessionUser);
        print('✅ バックエンドセッション保存完了: userId=${user['id']}');
      } else {
        print('⚠️ バックエンドセッション保存エラー: ${loginRes.statusCode}');
      }
    } catch (e) {
      print('⚠️ バックエンドセッション保存例外: $e');
    }

    final resolvedUserType = _normalizeUserType(
      user['userType'] ?? user['type'] ?? widget.userType,
    );

    print('✅ 解決された userType = $resolvedUserType');

    // 🔥 Flutter Webのルーター干渉を完全に避けるため次フレームでURLリセット
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      _resetUrlAndNavigateHome();
    }
  }

  // ===============================
  // ✅ hashルーティング対応 session_id 抽出
  // ===============================
  String? _extractSessionId() {
    final uri = Uri.base;

    // ① 通常クエリ (?session_id=)
    if (uri.queryParameters['session_id'] != null) {
      return uri.queryParameters['session_id'];
    }

    // ② Flutter Web hash (#/payment-success?session_id=)
    final fragment = uri.fragment;
    if (fragment.contains('?')) {
      final fragmentUri = Uri.parse('https://dummy/$fragment');
      return fragmentUri.queryParameters['session_id'];
    }

    return null;
  }

  // ===============================
  // ✅ 表記ゆれ統一
  // ===============================
  String _normalizeUserType(dynamic raw) {
    final value = raw?.toString().toLowerCase().trim() ?? '';

    if (['student', '学生'].contains(value)) return 'student';
    if (['worker', '社会人'].contains(value)) return 'worker';
    if (['company', '企業'].contains(value)) return 'company';

    print('⚠️ 未知の userType: $raw → company 扱い');
    return 'company';
  }

  // ===============================
  // 🔥 URLを確実に http://localhost:5000/ にしてトップへ
  // （自動遷移・ボタン両対応 / Flutter Web完全対応）
  // ===============================
  void _resetUrlAndNavigateHome() {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() {
          html.window.location.replace('${ApiConfig.frontendUrl}/#/');
        });
      });
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CompanyHome()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Widget _buildConfettiLite() {
    if (!_showConfetti) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.6,
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: List.generate(
              40,
              (i) => Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.primaries[i % Colors.primaries.length],
                  shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final maxWidth = isMobile ? screenWidth : 500.0;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green.shade50, Colors.teal.shade50, Colors.white],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            scale: 1,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            child: Container(
                              width: isMobile ? 140 : 180,
                              height: isMobile ? 140 : 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.teal.shade400,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _checkAnimation,
                                child: const SizedBox(width: 80, height: 80),
                                builder: (_, child) {
                                  return CustomPaint(
                                    painter: CheckmarkPainter(
                                      progress: _checkAnimation.value,
                                      color: Colors.white,
                                      strokeWidth: 7,
                                    ),
                                    child: child,
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: isMobile ? 24 : 40),
                          AnimatedOpacity(
                            opacity: 1,
                            duration: const Duration(milliseconds: 500),
                            child: Column(
                              children: [
                                Text(
                                  '決済が完了しました！',
                                  style: TextStyle(
                                    fontSize: isMobile ? 24 : 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isMobile ? 12 : 16),
                                Text(
                                  'ご登録いただきありがとうございます。\nプレミアムプランのすべての機能がご利用いただけます。',
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.grey.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isMobile ? 24 : 40),
                          ElevatedButton(
                            onPressed: () => _resetUrlAndNavigateHome(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 30 : 40,
                                vertical: isMobile ? 12 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.home),
                                SizedBox(width: 8),
                                Text('ホームに戻る', style: TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildConfettiLite(),
          ],
        ),
      ),
    );
  }
}

// ===============================
// 決済キャンセル画面（軽量版）
// ===============================
class PaymentCancelScreen extends StatelessWidget {
  const PaymentCancelScreen({Key? key}) : super(key: key);

  void _resetUrlAndNavigateHome(BuildContext context) {
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.microtask(() {
          html.window.location.replace('${ApiConfig.frontendUrl}/#/');
        });
      });
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CompanyHome()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.red.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.red.shade400],
                    ),
                  ),
                  child: const Icon(Icons.close, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Text(
                  '決済がキャンセルされました',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'お支払いは完了していません。\n再度お試しください。',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _resetUrlAndNavigateHome(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('ホームに戻る', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================
// チェックマークPainter
// ===============================
class CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CheckmarkPainter({
    required this.progress,
    required this.color,
    this.strokeWidth = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(
      size.width * (0.2 + 0.2 * progress),
      size.height * (0.5 + 0.1 * progress),
    );
    path.lineTo(
      size.width * (0.3 + 0.5 * progress),
      size.height * (0.6 - 0.3 * progress),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
