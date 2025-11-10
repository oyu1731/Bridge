import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '32-thread-official-detail.dart';
import '33-thread-unofficial-detail.dart';
import 'thread-unofficial-list.dart';

// Thread モデル
class Thread {
  final String id;
  final String title;
  final String? lastComment; // 公式スレッドのみ
  final String timeAgo;

  Thread({
    required this.id,
    required this.title,
    this.lastComment,
    required this.timeAgo,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    return Thread(
      id: json['id'].toString(),
      title: json['title'] as String,
      lastComment: json['lastComment'] as String?,
      timeAgo: json['timeAgo'] as String,
    );
  }
}

class ThreadList extends StatefulWidget {
  @override
  _ThreadListState createState() => _ThreadListState();
}

class _ThreadListState extends State<ThreadList> {
  List<Thread> officialThreads = [];
  List<Thread> hotUnofficialThreads = [];

  @override
  void initState() {
    super.initState();
    _loadDummyThreads();

    // DBからデータを持ってくる際、画面更新時に最新スレッド情報を取得
    // _fetchThreads();
  }

  Future<void> _loadDummyThreads() async {
    await Future.delayed(Duration(milliseconds: 300)); // 疑似通信待ち

    setState(() {
      officialThreads = [
        Thread(
            id: '1',
            title: '学生・社会人',
            lastComment: '最近忙しいけど頑張ってる！',
            timeAgo: '3分前'),
        Thread(
            id: '2',
            title: '学生',
            lastComment: 'テスト期間でやばいです…',
            timeAgo: '15分前'),
        Thread(
            id: '3',
            title: '社会人',
            lastComment: '残業が多くてつらい…',
            timeAgo: '42分前'),
      ];

      hotUnofficialThreads = [
        Thread(id: 't1', title: '業界別の面接対策', timeAgo: '3分前'),
        Thread(id: 't2', title: '社会人一年目の過ごし方', timeAgo: '10分前'),
        Thread(id: 't3', title: 'おすすめの資格', timeAgo: '25分前'),
        Thread(id: 't4', title: '働きながら転職活動するには', timeAgo: '50分前'),
        Thread(id: 't5', title: '就活で意識すべきこと', timeAgo: '1時間前'),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 公式スレッド
            Text(
              '公式スレッド',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Column(
              children: officialThreads.map((thread) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThreadOfficialDetail(
                          thread: {
                            'id': thread.id,
                            'title': thread.title,
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        thread.title,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: thread.lastComment != null
                          ? Text(
                              thread.lastComment!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 14),
                            )
                          : null,
                      trailing: Text(
                        thread.timeAgo,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 30),

            // 非公式スレッド
            Row(
              children: [
                Text(
                  'HOTスレッド（非公式）',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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
                    'もっと見る',
                    style: TextStyle(fontSize: 16, color: Colors.orange),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Column(
              children: hotUnofficialThreads.map((thread) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThreadUnofficialDetail(
                          thread: {
                            'id': thread.id,
                            'title': thread.title,
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        thread.title,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        thread.timeAgo,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
