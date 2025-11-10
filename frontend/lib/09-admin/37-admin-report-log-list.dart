import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
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
対象スレッド -thread_id-
対象レス -chat_id-
通報日 -created_at-
*/

class _AdminReportLogListState extends State<AdminReportLogList> {
  // ダミーデータ
  final List<Map<String, String>> reportLogs = [
    {
      'date': '2025-11-10',
      'from_user': '001',
      'to_user': '010',
      'thread': '27卒集まれ!',
      'chat': '不適切な投稿',
      'total': '6',
    },
    {
      'date': '2025-11-09',
      'from_user': '005',
      'to_user': '011',
      'thread': '闇バイト募集中',
      'chat': null,
      'total': '13',
    },
    {
      'date': '2025-11-08',
      'from_user': '007',
      'to_user': '015',
      'thread': '入社一年目、転職したい',
      'chat': '誹謗中傷',
      'total': '4',
    },
  ];

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

            // データ部分
            Expanded(
              child: ListView.builder(
                itemCount: reportLogs.length,
                itemBuilder: (context, index) {
                  final log = reportLogs[index];
                  final chatText = log['chat'] ?? '—';

                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Center(child: Text(log['date'] ?? ''))),
                        // 通報者ID（クリック可能）
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminAccountDetail(),
                                  ),
                                );
                              },
                              child: Text(
                                log['from_user'] ?? '',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 非通報者ID（クリック可能）
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminAccountDetail(),
                                  ),
                                );
                              },
                              child: Text(
                                log['to_user'] ?? '',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 対象スレッド（クリック可能）
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminThreadDetail(
                                      thread: {
                                        'id': thread.id,
                                        'title': thread.title,
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                log['thread'] ?? '',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 対象レス（クリック可能 / nullなら無効）
                        Expanded(
                          flex: 4,
                          child: Center(
                            child: log['chat'] != null
                                ? GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AdminThreadDetail(
                                            thread: {
                                              'id': thread.id,
                                              'title': thread.title,
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      chatText,
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  )
                                : Text(chatText),
                          ),
                        ),
                        Expanded(flex: 1, child: Center(child: Text(log['total'] ?? ''))),
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