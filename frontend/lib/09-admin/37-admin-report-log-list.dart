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

/*
id -id-
通報者 -from_user_id-
非通報者 -to_user_id-
通報タイプ -type-
通報日 -created_at-
*/

// Notification モデル
class NoticeData {
  final int id;
  final int? fromUserId; // nullable
  final int? toUserId; // nullable
  final int? threadId; // nullable
  final int? chatId; // nullable
  final DateTime? createdAt;

  NoticeData({
    required this.id,
    this.fromUserId,
    this.toUserId,
    this.threadId,
    this.chatId,
    this.createdAt,
  });

  factory NoticeData.fromJson(Map<String, dynamic> json) {
    return NoticeData(
      id: json['id'],
      fromUserId: json['fromUserId'] != null ? json['fromUserId'] as int : null,
      toUserId: json['toUserId'] != null ? json['toUserId'] as int : null,
      threadId: json['threadId'] != null ? json['threadId'] as int : null,
      chatId: json['chatId'] != null ? json['chatId'] as int : null,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

class _AdminReportLogListState extends State<AdminReportLogList> {
  List<NoticeData> _notices = [];
  bool _loading = true;

  Future<void> _fetchNotices() async {
    try {
      final response = await http.get(
        // Uri.parse("http://localhost:8080/api/notices"),
        Uri.parse("https://api.bridge-tesg.com/api/notices"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _notices = data.map((e) => NoticeData.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        throw Exception("Fail: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching notices: $e");
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNotices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              '通報ログ',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // テーブルヘッダー
            Container(
              color: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Center(child: Text('通報日'))),
                  Expanded(flex: 2, child: Center(child: Text('通報者'))),
                  Expanded(flex: 2, child: Center(child: Text('非通報者'))),
                  Expanded(flex: 3, child: Center(child: Text('対象スレッド'))),
                  Expanded(flex: 4, child: Center(child: Text('対象レス'))),
                  Expanded(flex: 1, child: Center(child: Text('通報数(合計)'))),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: _notices.length,
                        itemBuilder: (context, index) {
                          final log = _notices[index];

                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: Text(
                                      log.createdAt?.toString().split('.')[0] ??
                                          '',
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => AdminAccountDetail(
                                                  userId: log.fromUserId!,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        log.fromUserId.toString(),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => AdminAccountDetail(
                                                  userId: log.toUserId!,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        log.toUserId.toString(),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => AdminThreadDetail(
                                                  threadId: log.threadId!,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        log.threadId.toString(),
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Center(
                                    child:
                                        log.chatId != 0
                                            ? GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (context) =>
                                                            AdminThreadDetail(
                                                              threadId:
                                                                  log.threadId!,
                                                            ),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                log.chatId.toString(),
                                                style: const TextStyle(
                                                  color: Colors.blue,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            )
                                            : Text('—'),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(child: Text(log.id.toString())),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
