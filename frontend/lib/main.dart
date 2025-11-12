import 'package:bridge/09-admin/36-admin-home.dart';
import 'package:flutter/material.dart';
import 'package:bridge/05-notice/44-admin-mail-list.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdminMailList(), // ← ログインスキップして直接開く
    );
  }
}
