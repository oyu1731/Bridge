import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: ThreadCreate(), // 起動時に表示する画面
  ));
}

class ThreadCreate extends StatefulWidget {
  @override
  _ThreadCreateState createState() => _ThreadCreateState();
}

class _ThreadCreateState extends State<ThreadCreate> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}