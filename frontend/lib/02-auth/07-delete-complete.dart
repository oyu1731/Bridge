import 'package:bridge/style.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import 'package:bridge/style.dart';

class DeleteCompletePage extends StatelessWidget {
  const DeleteCompletePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'lib/01-images/bridge-logo.png',
                        height: 70,
                        width: 200,
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
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cyanMedium),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'ご利用ありがとうございました。',
                          style: AppTheme.mainTextStyle
                        ),
                        SizedBox(height: 12),
                        Text(
                          '「Bridge」をご利用いただき、心より感謝申し上げます。\nまたいつでも戻ってきてください。\n皆さんの学びとつながりを、これからも応援しています。',
                          style: AppTheme.subTextStyle
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const MyHomePage(title: 'Bridge'),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('トップページへ'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          textStyle: AppTheme.subTextStyle,
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
