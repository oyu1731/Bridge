import 'package:flutter/material.dart';
import 'package:bridge/header.dart';
import '34-thread-create.dart';
import '33-thread-unofficial-detail.dart';

class ThreadUnofficialList extends StatefulWidget {
  @override
  _ThreadUnofficialListState createState() => _ThreadUnofficialListState();
}

class _ThreadUnofficialListState extends State<ThreadUnofficialList> {
  List<Map<String, String>> unofficialThreads = [];
  List<Map<String, String>> filteredThreads = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchThreads();
  }

  @override
  void didUpdateWidget(covariant ThreadUnofficialList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ホットリロードなどで再読み込みされた際にスレッド情報を再取得
    _fetchThreads();
  }

  // 初回に最新更新順で30件ほど取得（バック側で並び替え・絞り込み想定）
  Future<void> _fetchThreads() async {
    await Future.delayed(Duration(milliseconds: 300)); // 通信待ち想定
    setState(() {
      unofficialThreads = [
        {'id': 't1', 'title': 'IT業界の転職事情について', 'timeAgo': '5分前'},
        {'id': 't2', 'title': '学生時代にやっておくべきこと', 'timeAgo': '12分前'},
        {'id': 't3', 'title': '社会人1年目の壁', 'timeAgo': '30分前'},
        {'id': 't4', 'title': '在宅勤務でのモチベ維持', 'timeAgo': '1時間前'},
      ];
      filteredThreads = unofficialThreads;
    });
  }

  // タイトル検索（バック接続時は検索クエリを送信して結果を再描画）
  void _searchThreads() {
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        filteredThreads = unofficialThreads;
      } else {
        filteredThreads = unofficialThreads
            .where((t) => t['title']!.contains(query))
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
                // スレッド作成ボタン（ThreadCreateへ遷移）
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ThreadCreate()),
                    );
                  },
                  child: Text('スレッド作成'),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
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
                              ThreadUnofficialDetail(thread: thread),
                        ),
                      );
                    },
                    child: Card(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        title: Text(thread['title']!),
                        trailing: Text(
                          thread['timeAgo']!,
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
