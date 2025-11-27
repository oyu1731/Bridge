import 'package:flutter/material.dart';
import '../main.dart';

class DeleteCompletePage extends StatelessWidget {
  const DeleteCompletePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeGray = const Color(0xFF616161);
    final borderGray = const Color(0xFFE0E0E0);
    final lightGray = const Color(0xFFF5F5F5);
    final primaryOrange = const Color(0xFFFFA000);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Bridgeロゴ（画像がある場合は Image.asset に変更）
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'lib/01-images/bridge-logo.png',
                        height: 55, // サイズを少し小さく
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
                    ],
                  ),

                  const SizedBox(height: 32),

                  // メッセージカード
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderGray),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ご利用ありがとうございました。',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          '「Bridge」をご利用いただき、心より感謝申し上げます。\nまたいつでも戻ってきてください。\n皆さんの学びとつながりを、これからも応援しています。',
                          style: TextStyle(fontSize: 16, color: Color(0xFF424242)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // トップページへボタン + ステップバッジ
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MyHomePage(title: 'Bridge')),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('トップページへ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
