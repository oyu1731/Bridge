import 'package:flutter/material.dart';
import 'package:bridge/header.dart';
import '32-thread-official-detail.dart';
import '33-thread-unofficial-detail.dart';
import 'thread-unofficial-list.dart';

class ThreadList extends StatefulWidget {
  @override
  _ThreadListState createState() => _ThreadListState();
}

class _ThreadListState extends State<ThreadList> {
  List<Map<String, String>> officialThreads = [];
  List<Map<String, String>> hotUnofficialThreads = [];

  @override
  void initState() {
    super.initState();
    _fetchThreads();
  }

  @override
  void didUpdateWidget(covariant ThreadList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ホットリロードや再読み込み時にスレッド情報を再取得
    _fetchThreads();
  }

  // 初回に公式スレッド（固定3件）＋ 非公式スレッド上位5件を取得
  Future<void> _fetchThreads() async {
    await Future.delayed(Duration(milliseconds: 300)); // 通信待ち想定
    setState(() {
      // 公式スレッド（固定）: ラストコメント＋経過時間を取得
      officialThreads = [
        {
          'id': '1',
          'title': '学生・社会人',
          'lastComment': '最近忙しいけど頑張ってる！',
          'timeAgo': '3分前',
        },
        {
          'id': '2',
          'title': '学生',
          'lastComment': 'テスト期間でやばいです…',
          'timeAgo': '15分前',
        },
        {
          'id': '3',
          'title': '社会人',
          'lastComment': '残業が多くてつらい…',
          'timeAgo': '42分前',
        },
      ];

      // 非公式スレッド（最新コメント送信からの経過時間が短い上位5件）
      hotUnofficialThreads = [
        {'id': 't1', 'title': '業界別の面接対策', 'timeAgo': '3分前'},
        {'id': 't2', 'title': '社会人一年目の過ごし方', 'timeAgo': '10分前'},
        {'id': 't3', 'title': 'おすすめの資格', 'timeAgo': '25分前'},
        {'id': 't4', 'title': '働きながら転職活動するには', 'timeAgo': '50分前'},
        {'id': 't5', 'title': '就活で意識すべきこと', 'timeAgo': '1時間前'},
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 公式スレッド一覧
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
                        builder: (context) =>
                            ThreadOfficialDetail(thread: thread),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        thread['title']!,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        thread['lastComment']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                      trailing: Text(
                        thread['timeAgo']!,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 30),

            // 非公式スレッド（HOTスレッド上位5件）
            Row(
              children: [
                Text(
                  'HOTスレッド（非公式）',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    // 非公式スレッド一覧へ遷移
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ThreadUnofficialList()),
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
                        builder: (context) =>
                            ThreadUnofficialDetail(thread: thread),
                      ),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        thread['title']!,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        thread['timeAgo']!,
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
