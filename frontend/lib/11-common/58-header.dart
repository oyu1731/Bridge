import 'dart:convert';
import 'dart:math';

import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:bridge/main.dart';
import '../style.dart';

// AI・クイズ
import 'package:bridge/07-ai-training/21-ai-training-list.dart';
import 'package:bridge/07-ai-training/27-quiz-course-select.dart';

// プラン
import 'package:bridge/10-payment/55-plan-status.dart';

// プロフィール
import '../04-profile/11-student-profile-edit.dart';
import '../04-profile/12-worker-profile-edit.dart';
import '../04-profile/13-company-profile-edit.dart';
import '../04-profile/14-liked-article-list.dart';

// 認証
import '../02-auth/05-sign-in.dart';
import '../02-auth/50-password-update.dart';
import '../02-auth/06-delete-account.dart';

// 企業
import '../06-company/14-company-info-list.dart';
import '../06-company/17-company-article-list.dart';
import '../06-company/19-article-post.dart';

// スレッド
import '../08-thread/31-thread-list.dart';

// Home
import '../03-home/08-student-worker-home.dart';
import '../03-home/09-company-home.dart';
import '../09-admin/36-admin-home.dart';

//メール
import '../05-notice/44-admin-mail-list.dart';

// 管理者
import '../09-admin/37-admin-report-log-list.dart';
import '../09-admin/38-admin-thread-list.dart';
import '../09-admin/40-admin-company-column-list.dart';
import '../09-admin/42-admin-account-list.dart';

// アイコン取得
import '../06-company/photo_api_client.dart';
import 'bridge_route_observer.dart';

// 隠しページ
import '99-hidden-page.dart';

class SimpleNotification {
  final int id;
  final String title;
  final String content;
  final int type;
  final int category;
  final DateTime? sendFlag;
  final int? userId;
  final int sendFlagInt;

  SimpleNotification({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.category,
    required this.sendFlagInt,
    this.sendFlag,
    this.userId,
  });

  factory SimpleNotification.fromJson(Map<String, dynamic> json) {
    return SimpleNotification(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      category: json['category'],
      userId: json['userId'],
      sendFlagInt: json['sendFlagInt'],
      sendFlag:
          json['sendFlag'] != null ? DateTime.parse(json['sendFlag']) : null,
    );
  }
}

class BridgeHeader extends StatelessWidget implements PreferredSizeWidget {
  const BridgeHeader({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(120);

  static int _logoTapCount = 0;
  static DateTime? _lastTapTime;
  static Set<String> _shownAlertUserIds = {}; // format: "userId_planStatus"
  static Map<int, String> _cachedPlanStatus = {};

  static const String _lastNotificationOpenedKeyPrefix =
      'lastNotificationOpenedAt_';
  static const List<String> _greetings = [
    'こんにちは',
    'いらっしゃいませ',
    'ようこそ',
    'お帰りなさい',
  ];
  static int _greetingIndex = Random().nextInt(_greetings.length);

  // =========================
  // 🔧 プラン状態取得
  // =========================
  static void clearPlanStatusCache() {
    // print('🗑️ プラン状態キャッシュをクリア');
    _cachedPlanStatus.clear();
  }

  static void resetAlertHistory(int userId) {
    // print('🗑️ ユーザー $userId のアラート表示履歴をリセット');
    // このユーザーのすべてのプラン状態に対するアラート履歴をリセット
    _shownAlertUserIds.removeWhere((key) => key.startsWith('${userId}_'));
  }

  Future<String?> _fetchPlanStatus(int userId) async {
    // print('🔍 プラン状態取得開始: userId=$userId');
    try {
      final response = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/api/users/$userId/plan-status"),
      );

      // print('📶 APIレスポンスコード: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        // print("📡 APIレスポンス: $data");
        // print("📡 レスポンス型: ${data.runtimeType}");

        // レスポンスが直接文字列の場合と、オブジェクトの場合の両対応
        if (data is String) {
          // print("✅ 文字列として受け取った: $data");
          return data;
        } else if (data is Map) {
          final planStatus = data['planStatus'] as String?;
          // print("✅ Mapから取得: $planStatus");
          return planStatus;
        }
      } else {
        // print("❌ ステータスコード異常: ${response.statusCode}");
      }
    } catch (e) {
      // print("❌ プラン状態取得エラー: $e");
    }
    // print("🛑 プラン状態取得失敗: nullを返却");
    return null;
  }

  // =========================
  // ⚠️ 無料プラン警告ダイアログ
  // =========================
  void _showUpgradeAlert(BuildContext context) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('プランのご案内'),
            content: const Text(
              '現在のプランは「無料」です。\n\n'
              '企業機能をすべて利用するには有料プランへのアップグレードが必要です。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('あとで'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _markHeaderNavigation();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PlanStatusScreen(userType: '企業'),
                    ),
                  );
                },
                child: const Text('プランを確認'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserInfo(),
      builder: (context, snapshot) {
        final userInfo = snapshot.data ?? {};
        final accountType = userInfo['accountType'] ?? 'unknown';
        final nickname = userInfo['nickname'] ?? '';
        final iconPath = userInfo['iconPath'] ?? '';
        final isAdmin = userInfo['isAdmin'] == true;
        final userId = userInfo['userId'];

        // 退会済み・削除済みチェック
        final isWithdrawn =
            userInfo['is_withdrawn'] == 1 || userInfo['is_withdrawn'] == true;
        final isDeleted =
            userInfo['is_deleted'] == 1 ||
            userInfo['is_deleted'] == true ||
            userInfo['is_deleted'] == '0x01';
        if (isWithdrawn || isDeleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('アカウントが無効です。トップページに戻ります。')));
          });
        }

        final greeting = _greetings[_greetingIndex];

        // =========================
        // 🏢 企業アカウントならプランチェック
        // =========================
        if (accountType == '企業' &&
            userId != null &&
            !_shownAlertUserIds.contains(userId)) {
          _fetchPlanStatus(userId)
              .then((status) {
                final alertKey = '${userId}_$status';
                if (!_shownAlertUserIds.contains(alertKey)) {
                  if (status == null) {
                    // ❌ DB登録なし → トップに戻す
                    print('❌ プラン状態がnull（DB登録なし） → ホーム画面へ遷移');
                    _shownAlertUserIds.add(alertKey);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => MyHomePage(title: 'Bridge'),
                        ),
                        (route) => false,
                      );
                    });
                  } else if (status == '無料' || status == '無料' || status == '') {
                    // ⚠️ 無料プラン → プラン確認画面へ直接遷移
                    print('⚠️ 無料プラン検出: userId=$userId → プラン確認画面へ遷移');
                    _shownAlertUserIds.add(alertKey);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder:
                              (_) => const PlanStatusScreen(userType: '企業'),
                        ),
                        (route) => false,
                      );
                    });
                  }
                }
              })
              .catchError((error) {
                print('❌ プランステータス取得エラー: $error');
              });
        }

        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
          ),
          child: Column(
            children: [
              // ===== 上段 =====
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;

                    if (isSmallScreen) {
                      // スマホ：1行コンパクトレイアウト（ロゴは左、他は右寄せ）
                      return SizedBox(
                        height: 58,
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final now = DateTime.now();
                                if (_lastTapTime == null ||
                                    now.difference(_lastTapTime!) >
                                        const Duration(seconds: 1)) {
                                  _logoTapCount = 0;
                                }
                                _lastTapTime = now;
                                _logoTapCount++;
                                if (_logoTapCount >= 3) {
                                  _logoTapCount = 0;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HiddenPage(),
                                    ),
                                  );
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.asset(
                                  'lib/01-images/bridge-logo.png',
                                  height: 30,
                                  width: 50,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (_, __, ___) => const Text(
                                        'B',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1976D2),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$greeting、$nicknameさん。',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textCyanDark,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 2),
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: PopupMenuButton<String>(
                                onSelected:
                                    (v) =>
                                        _handleProfileMenuSelection(context, v),
                                offset: const Offset(0, 32),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFFF5F5F5),
                                  backgroundImage:
                                      iconPath.isNotEmpty
                                          ? NetworkImage(iconPath)
                                          : null,
                                  child:
                                      iconPath.isEmpty
                                          ? const Icon(
                                            Icons.account_circle_outlined,
                                            size: 16,
                                            color: Color(0xFF616161),
                                          )
                                          : null,
                                ),
                                itemBuilder:
                                    (_) => _buildProfileMenu(accountType),
                              ),
                            ),
                            if (!isAdmin)
                              _buildNotificationButton(
                                context,
                                icon: Icons.notifications_outlined,
                                iconSize: 16,
                                iconColor: const Color(0xFF616161),
                                size: 28,
                              ),
                          ],
                        ),
                      );
                    } else {
                      // PC
                      return Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final now = DateTime.now();
                              if (_lastTapTime == null ||
                                  now.difference(_lastTapTime!) >
                                      const Duration(seconds: 1)) {
                                _logoTapCount = 0;
                              }
                              _lastTapTime = now;
                              _logoTapCount++;
                              if (_logoTapCount >= 10) {
                                _logoTapCount = 0;
                                _markHeaderNavigation();
                                _markHeaderNavigation();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HiddenPage(),
                                  ),
                                );
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.asset(
                                'lib/01-images/bridge-logo.png',
                                height: 55,
                                width: 110,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (_, __, ___) => const Text(
                                      'Bridge',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1976D2),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                '$greeting、$nicknameさん。',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textCyanDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 16),
                              PopupMenuButton<String>(
                                onSelected:
                                    (v) =>
                                        _handleProfileMenuSelection(context, v),
                                offset: const Offset(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: const Color(0xFFF5F5F5),
                                  backgroundImage:
                                      iconPath.isNotEmpty
                                          ? NetworkImage(iconPath)
                                          : null,
                                  child:
                                      iconPath.isEmpty
                                          ? const Icon(
                                            Icons.account_circle_outlined,
                                            color: Color(0xFF616161),
                                          )
                                          : null,
                                ),
                                itemBuilder:
                                    (_) => _buildProfileMenu(accountType),
                              ),
                              const SizedBox(width: 8),
                              if (!isAdmin)
                                _buildNotificationButton(
                                  context,
                                  icon: Icons.notifications_none_outlined,
                                  iconColor: AppTheme.accentOrange,
                                  size: 36,
                                ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),

              Container(height: 1, color: const Color(0xFFF0F0F0)),

              // ===== 下段ナビ =====
              Container(
                height: 51,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmall = constraints.maxWidth <= 800;
                    final space = isSmall ? 8.0 : 20.0;

                    List<Widget> buttons = [];

                    buttons.add(
                      _nav('TOPページ', () {
                        print(
                          '【TOPページ遷移】isAdmin=$isAdmin, accountType=$accountType',
                        );
                        if (isAdmin) {
                          print('✅ 管理者ページへ遷移');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AdminHome()),
                          );
                        } else if (accountType == '企業') {
                          print('✅ 企業ページへ遷移');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CompanyHome()),
                          );
                        } else {
                          print('✅ 学生/社会人ページへ遷移');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentWorkerHome(),
                            ),
                          );
                        }
                      }, isSmall),
                    );

                    buttons.add(SizedBox(width: space));

                    if (accountType == '学生' || accountType == '社会人') {
                      buttons.add(
                        _nav('AI練習', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AiTrainingListPage(),
                            ),
                          );
                        }, isSmall),
                      );
                      buttons.add(SizedBox(width: space));

                      buttons.add(
                        _nav('1問1答', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CourseSelectionScreen(),
                            ),
                          );
                        }, isSmall),
                      );
                      buttons.add(SizedBox(width: space));
                    }

                    if (isAdmin) {
                      buttons.add(
                        _nav('スレッド', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(
                                name: '/admin/thread-list',
                              ),
                              builder: (_) => AdminThreadList(),
                            ),
                          );
                        }, isSmall),
                      );
                      buttons.add(SizedBox(width: space));
                      buttons.add(
                        _nav('企業情報', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminCompanyColumnList(),
                            ),
                          );
                        }, isSmall),
                      );
                      buttons.add(SizedBox(width: space));
                      buttons.add(
                        _nav('お知らせ一覧', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AdminMailList()),
                          );
                        }, isSmall),
                      );
                      buttons.add(SizedBox(width: space));
                      buttons.add(
                        _nav('アカウント管理', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminAccountList(),
                            ),
                          );
                        }, isSmall),
                      );
                      buttons.add(SizedBox(width: space));
                      buttons.add(
                        _nav('通報一覧', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminReportLogList(),
                            ),
                          );
                        }, isSmall),
                      );
                    } else {
                      buttons.add(
                        _nav('スレッド', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              settings: const RouteSettings(
                                name: '/thread/list',
                              ),
                              builder: (_) => ThreadList(),
                            ),
                          );
                        }, isSmall),
                      );
                      buttons.add(SizedBox(width: space));
                      buttons.add(
                        _nav('企業情報', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompanySearchPage(),
                            ),
                          );
                        }, isSmall),
                      );
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: buttons),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== ナビボタン =====
  Widget _nav(String text, VoidCallback onPressed, bool small) {
    return TextButton(
      onPressed: () {
        if (_shouldRotateGreetingOnHeaderNav(text)) {
          _greetingIndex = (_greetingIndex + 1) % _greetings.length;
        }
        _markHeaderNavigation();
        onPressed();
      },
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textCyanDark,
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 18,
          vertical: small ? 6 : 8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: const BorderSide(color: AppTheme.borderGray, width: 1),
        ),
        textStyle: TextStyle(
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(text),
    );
  }

  bool _shouldRotateGreetingOnHeaderNav(String text) {
    return text == 'TOPページ' ||
        text == 'AI練習' ||
        text == '1問1答' ||
        text == 'スレッド' ||
        text == '企業情報';
  }

  // ===== プロフィールメニュー =====
  List<PopupMenuEntry<String>> _buildProfileMenu(String accountType) {
    if (accountType == '管理者') {
      return <PopupMenuEntry<String>>[
        _menu('password_change', Icons.lock, 'パスワード変更'),
        const PopupMenuDivider(),
        _menu('logout', Icons.logout, 'ログアウト', danger: true),
      ];
    }
    final items = <PopupMenuEntry<String>>[
      _menu('profile_edit', Icons.edit, 'プロフィール編集'),
      _menu('password_change', Icons.lock, 'パスワード変更'),
      _menu('liked_articles', Icons.favorite, 'いいねした記事一覧'),
    ];
    if (accountType == '企業') {
      items.addAll([
        _menu('post_article', Icons.article, '記事投稿'),
        _menu('article_list', Icons.list_alt, '投稿記事一覧'),
      ]);
    }
    items.addAll([
      _menu('plan_check', Icons.credit_card, 'プラン確認'),
      const PopupMenuDivider(),
      _menu('withdraw', Icons.exit_to_app, '退会手続き', danger: true),
      _menu('logout', Icons.logout, 'ログアウト', danger: true),
    ]);
    return items;
  }

  PopupMenuItem<String> _menu(
    String v,
    IconData i,
    String t, {
    bool danger = false,
  }) {
    return PopupMenuItem(
      value: v,
      child: Row(
        children: [
          Icon(i, size: 18, color: danger ? const Color(0xFFD32F2F) : null),
          const SizedBox(width: 12),
          Text(
            t,
            style: TextStyle(color: danger ? const Color(0xFFD32F2F) : null),
          ),
        ],
      ),
    );
  }

  // ===== ユーザー情報 =====
  Future<Map<String, dynamic>> _getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) {
      return {'accountType': 'unknown', 'nickname': '', 'iconPath': ''};
    }

    final local = jsonDecode(userJson);
    final userId = local['id'];
    final nickname = local['nickname'] ?? '';
    final localType = local['type']; // ローカルの type も取得

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/$userId'),
      );
      if (res.statusCode == 200) {
        final api = jsonDecode(res.body);
        final type = api['type'];
        String typeStr =
            type == 1
                ? '学生'
                : type == 2
                ? '社会人'
                : type == 3
                ? '企業'
                : type == 4
                ? '管理者'
                : 'unknown';

        String iconPath = '';
        if (api['icon'] != null) {
          final photo = await PhotoApiClient.getPhotoById(api['icon']);
          if (photo?.photoPath?.isNotEmpty == true) {
            iconPath = photo!.photoPath!;
          }
        }

        return {
          'userId': userId,
          'accountType': typeStr,
          'nickname': nickname,
          'iconPath': iconPath,
          'isAdmin': type == 4,
        };
      }
    } catch (e) {
      // print('⚠️ API呼び出しエラー: $e。ローカル情報を使用します');
    }

    // API呼び出し失敗時、ローカルキャッシュから type を使用
    String fallbackTypeStr =
        localType == 1
            ? '学生'
            : localType == 2
            ? '社会人'
            : localType == 3
            ? '企業'
            : localType == 4
            ? '管理者'
            : 'unknown';

    // print('📌 フォールバック: typeStr=$fallbackTypeStr, isAdmin=${localType == 4}');

    return {
      'userId': userId,
      'accountType': fallbackTypeStr,
      'nickname': nickname,
      'iconPath': '',
      'isAdmin': localType == 4,
    };
  }

  // ===== メニュー処理 =====
  Future<void> _handleProfileMenuSelection(
    BuildContext context,
    String value,
  ) async {
    switch (value) {
      case 'profile_edit':
        final type = (await _getUserInfo())['accountType'];
        if (type == '学生') {
          _markHeaderNavigation();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentProfileEditPage()),
          );
        } else if (type == '社会人') {
          _markHeaderNavigation();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkerProfileEditPage()),
          );
        } else if (type == '企業') {
          _markHeaderNavigation();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CompanyProfileEditPage()),
          );
        }
        break;

      case 'password_change':
        _markHeaderNavigation();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PasswordUpdatePage()),
        );
        break;

      case 'liked_articles':
        _markHeaderNavigation();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LikedArticleListPage()),
        );
        break;

      case 'post_article':
        _markHeaderNavigation();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArticlePostPage()),
        );
        break;

      case 'article_list':
        _markHeaderNavigation();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CompanyArticleListPage()),
        );
        break;

      case 'plan_check':
        _markHeaderNavigation();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => FutureBuilder<String>(
                  future: _getUserInfo().then(
                    (v) => v['accountType'] as String,
                  ),
                  builder: (c, s) {
                    if (!s.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return PlanStatusScreen(userType: s.data!);
                  },
                ),
          ),
        );
        break;

      case 'withdraw':
        _markHeaderNavigation();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeleteAccountPage()),
        );
        break;

      case 'logout':
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        _markHeaderNavigation();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MyHomePage(title: 'Bridge')),
          (_) => false,
        );
        break;
    }
  }

  void _markHeaderNavigation() {
    BridgeRouteObserver.requestLogoForNextNavigation();
  }

  Future<void> _showNotificationDialog(BuildContext context) async {
    final userInfo = await _getUserInfo();
    final accountType = userInfo['accountType'];

    final prefs = await SharedPreferences.getInstance();
    final userJson = jsonDecode(prefs.getString('current_user')!);
    final userId = userJson['id'];

    int? type;
    if (accountType == '学生') type = 1;
    if (accountType == '社会人') type = 2;
    if (accountType == '企業') type = 3;

    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
    );
    if (res.statusCode != 200) return;

    final List list = jsonDecode(res.body);

    final notifications = _filterNotifications(list, userId, type);

    await _saveNotificationOpenedAt(userId);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('お知らせ'),
            content: SizedBox(
              width: 420,
              child:
                  notifications.isEmpty
                      ? const Center(child: Text('お知らせはありません'))
                      : ListView.separated(
                        shrinkWrap: true,
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (_, i) {
                          final n = notifications[i];
                          return ListTile(
                            title: Text(n.title),
                            subtitle: Text(n.category == 1 ? '運営情報' : '重要'),
                            onTap: () {
                              Navigator.pop(context);
                              _showNotificationDetail(context, n);
                            },
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  void _showNotificationDetail(BuildContext context, SimpleNotification n) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(n.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.content),
                const SizedBox(height: 12),
                Text(
                  '送信日：${n.sendFlag != null ? '${n.sendFlag!.year}/${n.sendFlag!.month.toString().padLeft(2, '0')}/${n.sendFlag!.day.toString().padLeft(2, '0')} '
                          '${n.sendFlag!.hour.toString().padLeft(2, '0')}:${n.sendFlag!.minute.toString().padLeft(2, '0')}' : '-'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
    );
  }

  List<SimpleNotification> _filterNotifications(
    List list,
    int userId,
    int? type,
  ) {
    return list.map((e) => SimpleNotification.fromJson(e)).where((n) {
      if (n.sendFlagInt != 2) return false;
      // 全員
      if (n.type == 7) return true;

      // 個人宛
      if (n.type == 8 && n.userId == userId) return true;

      // 学生
      if (type == 1) {
        return n.type == 1 || n.type == 4 || n.type == 5;
      }

      // 社会人
      if (type == 2) {
        return n.type == 2 || n.type == 4 || n.type == 6;
      }

      // 企業
      if (type == 3) {
        return n.type == 3 || n.type == 5 || n.type == 6;
      }

      return false;
    }).toList();
  }

  Future<void> _saveNotificationOpenedAt(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      '$_lastNotificationOpenedKeyPrefix$userId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<bool> _hasNewNotifications() async {
    final userInfo = await _getUserInfo();
    final accountType = userInfo['accountType'];
    if (accountType == null) return false;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) return false;
    final userData = jsonDecode(userJson);
    final userId = userData['id'];
    if (userId == null) return false;

    int? type;
    if (accountType == '学生') type = 1;
    if (accountType == '社会人') type = 2;
    if (accountType == '企業') type = 3;

    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/notifications'),
    );
    if (res.statusCode != 200) return false;

    final List list = jsonDecode(res.body);
    final notifications = _filterNotifications(list, userId, type);
    if (notifications.isEmpty) return false;

    final lastOpenedMillis = prefs.getInt(
      '$_lastNotificationOpenedKeyPrefix$userId',
    );
    if (lastOpenedMillis == null) {
      return true;
    }
    final lastOpened = DateTime.fromMillisecondsSinceEpoch(lastOpenedMillis);
    return notifications.any(
      (n) => n.sendFlag != null && n.sendFlag!.isAfter(lastOpened),
    );
  }

  Widget _buildNotificationButton(
    BuildContext context, {
    required IconData icon,
    double? iconSize,
    Color? iconColor,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<bool>(
        future: _hasNewNotifications(),
        builder: (context, snapshot) {
          final hasNew = snapshot.data == true;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'お知らせ一覧',
                onPressed: () {
                  _showNotificationDialog(context);
                },
                icon: Icon(icon, size: iconSize, color: iconColor),
                padding: EdgeInsets.zero,
              ),
              if (hasNew) Positioned(right: 2, top: 2, child: _BlinkingDot()),
            ],
          );
        },
      ),
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  const _BlinkingDot();

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
