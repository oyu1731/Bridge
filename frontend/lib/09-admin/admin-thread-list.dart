import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '39-admin-thread-detail.dart';

// Thread モデル
class Thread {
  final int id;
  final String title;
  final String timeAgo;

  Thread({
    required this.id,
    required this.title,
    required this.timeAgo,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    return Thread(
      id: json['id'],
      title: json['title'] as String,
      timeAgo: json['timeAgo'] as String,
    );
  }
}

class ThreadUnofficialList extends StatefulWidget {
  @override
  _ThreadUnofficialListState createState() => _ThreadUnofficialListState();
}

class _ThreadUnofficialListState extends State<ThreadUnofficialList> {
  List<Thread> unofficialThreads = [];
  List<Thread> filteredThreads = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDummyThreads();

    // DBからデータを持ってくる際、画面更新時に最新スレッド情報を取得
    // _fetchThreads();
  }

  // 初回に最新更新順で30件ほど取得（バック側で並び替え・絞り込み想定）
  Future<void> _loadDummyThreads() async {
    await Future.delayed(Duration(milliseconds: 300)); // 疑似通信待ち

    setState(() {
      unofficialThreads = [
        Thread(id: 1, title: '業界別の面接対策', timeAgo: '3分前'),
        Thread(id: 2, title: '社会人一年目の過ごし方', timeAgo: '10分前'),
        Thread(id: 3, title: 'おすすめの資格', timeAgo: '25分前'),
        Thread(id: 4, title: '働きながら転職活動するには', timeAgo: '50分前'),
        Thread(id: 5, title: '就活で意識すべきこと', timeAgo: '1時間前'),
      ];

      // 初期状態では全件表示
      filteredThreads = List.from(unofficialThreads);
    });
  }

  // タイトル検索（バック接続時は検索クエリを送信して結果を再描画）
  void _searchThreads() {
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        filteredThreads = List.from(unofficialThreads);
      } else {
        filteredThreads = unofficialThreads
            .where((t) => t.title.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '非公式スレッド一覧',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                // スレッドタイトル検索欄
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '検索',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchThreads,
                  child: Text('検索'),
                ),
              ],
            ),
            SizedBox(height: 20),
            // スレッド一覧表示
            Expanded(
              child: ListView.builder(
                itemCount: filteredThreads.length,
                itemBuilder: (context, index) {
                  final thread = filteredThreads[index];
                  return GestureDetector(
                    onTap: () {
                      // 非公式スレッド詳細へ遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                            AdminThreadDetail(
                                threadId: thread.id,
                            ),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        title: Text(thread.title),
                        trailing: Text(
                          thread.timeAgo,
                          style: TextStyle(color: Colors.grey),
                        ),
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
