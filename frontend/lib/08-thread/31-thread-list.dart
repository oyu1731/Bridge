import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '33-thread-unofficial-detail.dart';
import 'dart:math';

void main() {
  runApp(MaterialApp(home: ThreadList()));
}

// スレッドモデル
class Thread {
  final int id;
  final String title;
  final String lastComment; // 最新コメント内容
  final DateTime lastUpdateDate;
  final int type; // 1=公式, 2=非公式

  Thread({
    required this.id,
    required this.title,
    required this.lastComment,
    required this.lastUpdateDate,
    required this.type,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(lastUpdateDate);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}

class ThreadList extends StatefulWidget {
  @override
  _ThreadListState createState() => _ThreadListState();
}

class _ThreadListState extends State<ThreadList> {
  List<Thread> allThreads = [];

  @override
  void initState() {
    super.initState();
    _loadThreads(); // ダミーデータ読み込み
  }

  void _loadThreads() {
    final now = DateTime.now();
    final random = Random();

    // ダミーデータ生成（公式3件、非公式7件）
    allThreads = [
      // 公式スレッド（type=1）
      Thread(
        id: 1,
        title: '公式スレッド①',
        lastComment: '最新アップデートの情報です！',
        lastUpdateDate: now.subtract(Duration(minutes: 10)),
        type: 1,
      ),
      Thread(
        id: 2,
        title: '公式スレッド②',
        lastComment: '運営からのお知らせです。',
        lastUpdateDate: now.subtract(Duration(hours: 1, minutes: 20)),
        type: 1,
      ),
      Thread(
        id: 3,
        title: '公式スレッド③',
        lastComment: 'メンテナンス完了しました。',
        lastUpdateDate: now.subtract(Duration(hours: 5)),
        type: 1,
      ),
      // 非公式スレッド（type=2）
      ...List.generate(7, (index) {
        return Thread(
          id: index + 4,
          title: '非公式スレッド ${index + 1}',
          lastComment: 'コメント${index + 1}：盛り上がってるね！',
          lastUpdateDate: now.subtract(Duration(minutes: random.nextInt(500))),
          type: 2,
        );
      }),
    ];

    // 更新日時の新しい順にソート
    allThreads.sort((a, b) => b.lastUpdateDate.compareTo(a.lastUpdateDate));
  }

  @override
  Widget build(BuildContext context) {
    // 公式スレッド3件
    List<Thread> officialThreads =
        allThreads.where((t) => t.type == 1).take(3).toList();

    // HOTスレッド（非公式のみ上位5件）
    List<Thread> hotThreads =
        allThreads.where((t) => t.type == 2).take(5).toList();

    return Scaffold(
      appBar: BridgeHeader(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 公式スレッドタイトル
            Text(
              '公式スレッド',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            // 公式スレッド一覧（タイトル + コメント + 時間）
            Column(
              children:
                  officialThreads.map((thread) {
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    thread.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    thread.lastComment,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              thread.timeAgo,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),

            SizedBox(height: 20),

            // HOTスレッドタイトル + リンク
            Row(
              children: [
                Text(
                  'HOTスレッド',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThreadUnofficialList(),
                      ),
                    );
                  },
                  child: Text(
                    'スレッド一覧',
                    style: TextStyle(fontSize: 18, color: Colors.blueAccent),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // HOTスレッド（非公式）
            Expanded(
              child: ListView.builder(
                itemCount: hotThreads.length,
                itemBuilder: (context, index) {
                  final thread = hotThreads[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  thread.title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  thread.lastComment,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            thread.timeAgo,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
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
