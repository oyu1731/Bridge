import 'package:flutter/material.dart';
import '../06-company/14-company-info-list.dart';

class BridgeHeader extends StatelessWidget implements PreferredSizeWidget {
  const BridgeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Column(
        children: [
          // 上段: ロゴ、挨拶、プロフィール・お知らせアイコン
          Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // 左側: Bridgeロゴ（大きくして文字を削除）
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'lib/images/bridge-logo.png',
                    height: 44, // サイズを少し小さく
                    width: 110, // 横幅も調整
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Row(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            color: Colors.blue,
                            size: 44,
                          ),
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
                ),

                const Spacer(),

                // 右側: ユーザー情報とアイコン
                Row(
                  children: [
                    Text(
                      'こんにちは、adminさん。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // プロフィールメニュー
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF5F5F5),
                        border: Border.all(color: Color(0xFFE0E0E0)),
                      ),
                      child: PopupMenuButton<String>(
                        onSelected: (String value) {
                          _handleProfileMenuSelection(context, value);
                        },
                        offset: Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 8,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle),
                          child: Icon(
                            Icons.account_circle_outlined,
                            color: Color(0xFF616161),
                            size: 22,
                          ),
                        ),
                        itemBuilder:
                            (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'profile_edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Color(0xFF616161),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('プロフィール編集'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'password_change',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.lock,
                                      size: 18,
                                      color: Color(0xFF616161),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('パスワード変更'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'post_article',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.article,
                                      size: 18,
                                      color: Color(0xFF616161),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('記事投稿'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'plan_check',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      size: 18,
                                      color: Color(0xFF616161),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('プラン確認'),
                                  ],
                                ),
                              ),
                              PopupMenuDivider(),
                              PopupMenuItem<String>(
                                value: 'withdraw',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.exit_to_app,
                                      size: 18,
                                      color: Color(0xFFD32F2F),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '退会手続き',
                                      style: TextStyle(
                                        color: Color(0xFFD32F2F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      size: 18,
                                      color: Color(0xFFD32F2F),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'ログアウト',
                                      style: TextStyle(
                                        color: Color(0xFFD32F2F),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF5F5F5),
                        border: Border.all(color: Color(0xFFE0E0E0)),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // お知らせページへの遷移
                          print('お知らせページへ遷移');
                        },
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: Color(0xFF616161),
                          size: 24,
                        ),
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 中央の区切り線
          Container(height: 1, color: Color(0xFFF0F0F0)),

          // 下段: ナビゲーションボタン
          Container(
            height: 51,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavButton('TOPページ', () {
                  print('TOPページへ遷移');
                }),
                const SizedBox(width: 20),
                _buildNavButton('AI練習', () {
                  print('AI練習ページへ遷移');
                }),
                const SizedBox(width: 20),
                _buildNavButton('1問1答', () {
                  print('1問1答ページへ遷移');
                }),
                const SizedBox(width: 20),
                _buildNavButton('スレッド', () {
                  print('スレッドページへ遷移');
                }),
                const SizedBox(width: 20),
                _buildNavButton('企業情報', () {
                  // 企業情報ページへの遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CompanySearchPage(),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5), // より淡いグレー背景
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Color(0xFFE0E0E0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          minimumSize: const Size(75, 36),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Color(0xFF424242), // ダークグレー
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // プロフィールメニューの選択処理
  void _handleProfileMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'profile_edit':
        // プロフィール編集ページへの遷移（張りぼて）
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プロフィール編集ページに遷移します'),
            backgroundColor: Color(0xFF1976D2),
          ),
        );
        break;
      case 'password_change':
        // パスワード変更ページへの遷移（張りぼて）
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('パスワード変更ページに遷移します'),
            backgroundColor: Color(0xFF1976D2),
          ),
        );
        break;
      case 'post_article':
        // 記事投稿ページへの遷移（張りぼて）
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('記事投稿ページに遷移します'),
            backgroundColor: Color(0xFF1976D2),
          ),
        );
        break;
      case 'plan_check':
        // プラン確認ページへの遷移（張りぼて）
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('プラン確認ページに遷移します'),
            backgroundColor: Color(0xFF1976D2),
          ),
        );
        break;
      case 'withdraw':
        // 退会手続きの確認ダイアログ（張りぼて）
        _showWithdrawDialog(context);
        break;
      case 'logout':
        // ログアウト確認ダイアログ（張りぼて）
        _showLogoutDialog(context);
        break;
    }
  }

  // 退会手続きの確認ダイアログ
  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('退会手続き'),
          content: Text('本当に退会しますか？\nこの操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('退会手続きを開始します'),
                    backgroundColor: Color(0xFFD32F2F),
                  ),
                );
              },
              child: Text('退会する', style: TextStyle(color: Color(0xFFD32F2F))),
            ),
          ],
        );
      },
    );
  }

  // ログアウト確認ダイアログ
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ログアウト'),
          content: Text('ログアウトしますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ログアウトしました'),
                    backgroundColor: Color(0xFFD32F2F),
                  ),
                );
              },
              child: Text('ログアウト', style: TextStyle(color: Color(0xFFD32F2F))),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(120);
}
