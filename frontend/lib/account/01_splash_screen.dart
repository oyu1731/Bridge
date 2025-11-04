import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback用
import 'package:bridge/account/02_sign_up_student.dart';
import 'package:bridge/account/03_sign_up_worker.dart';
import 'package:bridge/account/04_sign_up_company.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.title});
  final String title;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void _onCircleTap(String label, BuildContext context) {
    HapticFeedback.selectionClick(); // 軽い振動
    print('$label が押されました'); // デバッグ用

    Widget nextPage;
    if (label == '学生') {
      nextPage = const StudentInputPage();
    } else if (label == '社会人') {
      nextPage = const ProfessionalInputPage();
    } else if (label == '企業') {
      nextPage = const CompanyInputPage();
    } else {
      return; // 不明なラベルの場合は何もしない
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => nextPage));
  }

  Widget _buildCircleButton(String label) {
    return Material(
      color: Colors.transparent, // Materialが必要
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: () => _onCircleTap(label, context),
        borderRadius: BorderRadius.circular(100),
        containedInkWell: true, // 円形リップル
        splashColor: Colors.blueAccent.withOpacity(0.5),
        child: Container(
          height: 200,
          width: 200,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bridge',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontSize: 48),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircleButton('学生'),
                _buildCircleButton('社会人'),
                _buildCircleButton('企業'),
              ],
            ),
            TextButton(
              onPressed: () {
                // サインインページへの遷移ロジックをここに追加
                print("サインインはこちら が押されました");
              },
              child: const Text("サインインはこちら"),
            ),
          ],
        ),
      ),
    );
  }
}
