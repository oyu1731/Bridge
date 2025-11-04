import 'package:flutter/material.dart';
import '14-company-info-list.dart';

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
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
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
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF5F5F5),
                        border: Border.all(color: Color(0xFFE0E0E0)),
                      ),
                      child: IconButton(
                        onPressed: () {
                          // プロフィールページへの遷移
                          print('プロフィールページへ遷移');
                        },
                        icon: Icon(
                          Icons.account_circle_outlined,
                          color: Color(0xFF616161),
                          size: 22,
                        ),
                        padding: EdgeInsets.all(6),
                        constraints: BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
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
          Container(
            height: 1,
            color: Color(0xFFF0F0F0),
          ),
          
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

  @override
  Size get preferredSize => const Size.fromHeight(120);
}