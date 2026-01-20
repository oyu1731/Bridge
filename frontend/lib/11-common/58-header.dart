import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:bridge/main.dart';

// AI・クイズ
import 'package:bridge/07-ai-training/21-ai-training-list.dart';
import 'package:bridge/07-ai-training/27-quiz-course-select.dart';

// プラン
import 'package:bridge/10-payment/55-plan-status.dart';

// プロフィール
import '../04-profile/11-student-profile-edit.dart';
import '../04-profile/12-worker-profile-edit.dart';
import '../04-profile/13-company-profile-edit.dart';

// 認証
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

// 管理者
import '../09-admin/37-admin-report-log-list.dart';
import '../09-admin/38-admin-thread-list.dart';
import '../09-admin/40-admin-company-column-list.dart';
import '../09-admin/42-admin-account-list.dart';
import '../05-notice/45-admin-mail-send.dart';

// アイコン取得
import '../06-company/photo_api_client.dart';

class BridgeHeader extends StatelessWidget implements PreferredSizeWidget {
  const BridgeHeader({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(120);

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

        final greetings = ['こんにちは', 'いらっしゃいませ', 'ようこそ', 'お帰りなさい'];
        final greeting =
            greetings[DateTime.now().millisecond % greetings.length];

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
                child: Row(
                  children: [
                    Image.asset(
                      'lib/01-images/bridge-logo.png',
                      height: 55,
                      width: 110,
                    ),

                    const Spacer(),

                    // 👇 テキストだけ Expanded
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final width = MediaQuery.of(context).size.width;

                          String text;
                          if (width < 500) {
                            text = '$nicknameさん';
                          } else {
                            text = '$greeting、$nicknameさん。';
                          }

                          return Text(
                            text,
                            maxLines: 1,
                            overflow: TextOverflow.visible, // ← 重要
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF424242),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    PopupMenuButton<String>(
                      onSelected: (v) => _handleProfileMenuSelection(context, v),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFF5F5F5),
                        backgroundImage:
                            iconPath.isNotEmpty ? NetworkImage(iconPath) : null,
                        child: iconPath.isEmpty
                            ? const Icon(
                                Icons.account_circle_outlined,
                                color: Color(0xFF616161),
                              )
                            : null,
                      ),
                      itemBuilder: (_) => _buildProfileMenu(accountType),
                    ),


                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_outlined),
                    ),
                  ],
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
                        if (isAdmin) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => AdminHome()),
                          );
                        } else if (accountType == '企業') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CompanyHome()),
                          );
                        } else {
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
                      // 管理者用ナビ
                      buttons.add(_nav('スレッド', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdminThreadList()),
                        );
                      }, isSmall));
                      buttons.add(SizedBox(width: space));
                      buttons.add(_nav('企業情報', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdminCompanyColumnList()),
                        );
                      }, isSmall));
                      buttons.add(SizedBox(width: space));
                      buttons.add(_nav('メール送信', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdminMailSend()),
                        );
                      }, isSmall));
                      buttons.add(SizedBox(width: space));
                      buttons.add(_nav('アカウント管理', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdminAccountList()),
                        );
                      }, isSmall));
                      buttons.add(SizedBox(width: space));
                      buttons.add(_nav('通報一覧', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AdminReportLogList()),
                        );
                      }, isSmall));
                    } else {
                      buttons.add(
                        _nav('スレッド', () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ThreadList()),
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
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFF5F5F5),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 18,
          vertical: small ? 6 : 8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: small ? 11 : 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF424242),
        ),
      ),
    );
  }

  // ===== プロフィールメニュー =====
  List<PopupMenuEntry<String>> _buildProfileMenu(String accountType) {
    // 管理者は一部メニュー非表示
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

    try {
      final res = await http.get(
        Uri.parse('http://localhost:8080/api/users/$userId'),
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
          'accountType': typeStr,
          'nickname': nickname,
          'iconPath': iconPath,
          'isAdmin': type == 4,
        };
      }
    } catch (_) {}

    return {'accountType': 'unknown', 'nickname': nickname, 'iconPath': '', 'isAdmin': false};
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => StudentProfileEditPage()),
          );
        } else if (type == '社会人') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkerProfileEditPage()),
          );
        } else if (type == '企業') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CompanyProfileEditPage()),
          );
        }
        break;

      case 'password_change':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PasswordUpdatePage()),
        );
        break;

      case 'post_article':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArticlePostPage()),
        );
        break;

      case 'article_list':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CompanyArticleListPage()),
        );
        break;

      case 'plan_check':
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DeleteAccountPage()),
        );
        break;

      case 'logout':
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MyHomePage(title: 'Bridge')),
          (_) => false,
        );
        break;
    }
  }
}
