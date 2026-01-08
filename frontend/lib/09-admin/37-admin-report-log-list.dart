import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '43-admin-account-detail.dart';
import '39-admin-thread-detail.dart';

class AdminReportLogList extends StatefulWidget {
  @override
  _AdminReportLogListState createState() => _AdminReportLogListState();
}

/* ===== 通報ログモデル ===== */
class NoticeData {
  final int id;
  final int? fromUserId;
  final int? toUserId;
  final int? type;
  final int? threadId;
  final int? chatId;
  final DateTime? createdAt;
  final String? threadTitle;
  final String? chatContent;
  final bool? threadDeleted;
  final bool? chatDeleted;
  final int? totalCount;

  NoticeData({
    required this.id,
    this.fromUserId,
    this.toUserId,
    this.type,
    this.threadId,
    this.chatId,
    this.createdAt,
    this.threadTitle,
    this.chatContent,
    this.threadDeleted,
    this.chatDeleted,
    this.totalCount,
  });

  factory NoticeData.fromJson(Map<String, dynamic> json) {
    return NoticeData(
      id: json['id'],
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      type: json['type'],
      threadId: json['threadId'],
      chatId: json['chatId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      threadTitle: json['threadTitle'],
      chatContent: json['chatContent'],
      threadDeleted: json['threadDeleted'],
      chatDeleted: json['chatDeleted'],
      totalCount: json['totalCount'],
    );
  }
}

class _AdminReportLogListState extends State<AdminReportLogList> {

  List<NoticeData> _logs = [];
  bool _loading = true;

  Future<void> _fetchLogs() async {
    final res = await http.get(Uri.parse("http://localhost:8080/api/notice/logs"));
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      setState(() {
        _logs = data.map((e) => NoticeData.fromJson(e)).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _confirmDelete(NoticeData n) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この投稿を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );

    if (confirm == true) _delete(n.id);
  }

  Future<void> _delete(int id) async {
    final res = await http.put(Uri.parse("http://localhost:8080/api/notice/admin/delete/$id"));

    if (res.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("削除しました")));
      _fetchLogs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("削除に失敗しました")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('通報ログ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, i) => _buildRow(_logs[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.grey.shade300,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Center(child: Text('通報日'))),
          Expanded(flex: 2, child: Center(child: Text('通報者'))),
          Expanded(flex: 2, child: Center(child: Text('非通報者'))),
          Expanded(flex: 3, child: Center(child: Text('対象スレッド'))),
          Expanded(flex: 4, child: Center(child: Text('対象レス'))),
          Expanded(flex: 1, child: Center(child: Text('通報数'))),
          Expanded(flex: 1, child: Center(child: Text('削除'))),
        ],
      ),
    );
  }

  Widget _buildRow(NoticeData n) {
    String date = n.createdAt != null
        ? "${n.createdAt!.year}/${n.createdAt!.month.toString().padLeft(2, '0')}/${n.createdAt!.day.toString().padLeft(2, '0')} "
          "${n.createdAt!.hour.toString().padLeft(2, '0')}:${n.createdAt!.minute.toString().padLeft(2, '0')}"
        : "";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Center(child: Text(date))),
          Expanded(flex: 2, child: _userLink(n.fromUserId)),
          Expanded(flex: 2, child: _userLink(n.toUserId)),
          Expanded(flex: 3, child: _threadLink(n)),
          Expanded(flex: 4, child: _chatLink(n)),
          Expanded(flex: 1, child: Center(child: Text(n.totalCount?.toString() ?? '0'))),
          Expanded(
            flex: 1,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.black),
                onPressed: () => _confirmDelete(n),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userLink(int? id) => Center(
    child: id == null ? const Text('—') : GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAccountDetail(userId: id))),
      child: Text(id.toString(), style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
    ),
  );

  Widget _threadLink(NoticeData n) => Column(
    children: [
      n.threadId == null ? const Text('—') : GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminThreadDetail(threadId: n.threadId!))),
        child: Text(n.threadTitle ?? '（削除済み）',
            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
      ),
      if (n.threadDeleted == true)
        const Text("削除済み", style: TextStyle(color: Colors.red, fontSize: 12))
    ],
  );

  Widget _chatLink(NoticeData n) => Column(
    children: [
      n.chatId == null ? const Text('—') : GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminThreadDetail(threadId: n.threadId!))),
        child: Text(n.chatContent ?? '（削除済み）',
            style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
      ),
      if (n.chatDeleted == true)
        const Text("削除済み", style: TextStyle(color: Colors.red, fontSize: 12))
    ],
  );
}
