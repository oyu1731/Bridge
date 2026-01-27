import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '37-admin-report-log-list.dart';
import '38-admin-thread-list.dart';
import '42-admin-account-list.dart';
import 'package:bridge/05-notice/44-admin-mail-list.dart';
import '40-admin-company-column-list.dart';

class AdminHome extends StatefulWidget {
  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  @override
  Widget build(BuildContext context) {
    // 画面サイズ取得
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth - 80) / 2; // 2列で左右マージン
    final buttonWidth2 = screenWidth -60;
    final buttonHeight = 100.0;

    return Scaffold(
      appBar: BridgeHeader(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton('スレッド一覧', buttonWidth, buttonHeight, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminThreadList()),
                  );
                }),
                SizedBox(width: 20),
                _buildButton('通報一覧', buttonWidth, buttonHeight, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminReportLogList(),
                    ),
                  );
                }),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildButton('アカウント管理', buttonWidth, buttonHeight, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminAccountList()),
                  );
                }),
                SizedBox(width: 20),
                _buildButton('メール一覧', buttonWidth, buttonHeight, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminMailList()),
                  );
                }),
              ],
            ),
            SizedBox(height: 20),
            _buildButton('企業情報一覧', buttonWidth2, buttonHeight, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminCompanyColumnList()),
              );
            })
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
    String text,
    double width,
    double height,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // 背景白
          foregroundColor: Colors.black, // 文字黒
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // 少し角丸
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
