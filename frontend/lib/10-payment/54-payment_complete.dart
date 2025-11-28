import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('決済完了'),
        automaticallyImplyLeading: false, // 戻るボタンを非表示
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'お支払いが完了しました！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('ご利用ありがとうございました。', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst); // ホーム画面に戻る
              },
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}

// 決済キャンセル画面
class PaymentCancelScreen extends StatelessWidget {
  const PaymentCancelScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('決済キャンセル'),
        automaticallyImplyLeading: false, // 戻るボタンを非表示
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 100),
            const SizedBox(height: 20),
            const Text(
              'お支払いがキャンセルされました。',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              '必要であれば再度お支払い手続きを行ってください。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).popUntil((route) => route.isFirst); // ホーム画面に戻る
              },
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
