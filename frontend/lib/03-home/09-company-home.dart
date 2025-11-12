import 'package:flutter/material.dart';

class CompanyHome extends StatelessWidget {
  const CompanyHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('企業ホーム'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '企業ホーム画面',
              style: TextStyle(fontSize: 24),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: 企業向け機能への遷移
              },
              child: const Text('企業向け機能へ'),
            ),
          ],
        ),
      ),
    );
  }
}