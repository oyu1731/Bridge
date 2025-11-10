import 'package:bridge/09-admin/38-admin-thread-list.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminThreadDetail extends StatefulWidget {
  final Map<String, dynamic> thread;

  const AdminThreadDetail({required this.thread, Key? key})
      : super(key: key);

  @override
  _AdminThreadDetailState createState() => _AdminThreadDetailState();
}

class _AdminThreadDetailState extends State<AdminThreadList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
    );
  }
}