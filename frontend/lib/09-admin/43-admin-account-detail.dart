import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminAccountDetail extends StatefulWidget {

  final int userId;
  const AdminAccountDetail({required this.userId, super.key});

  @override
  _AdminAccountDetailState createState() => _AdminAccountDetailState();
}

class _AdminAccountDetailState extends State<AdminAccountDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
      ),
    );
  }
}