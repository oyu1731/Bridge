import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '39-admin-thread-detail.dart';

// Thread モデル
class Thread {
  final String id;
  final String title;
  final String timeAgo;

  Thread({
    required this.id,
    required this.title,
    required this.timeAgo,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    return Thread(
      id: json['id'].toString(),
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
  }

  // 初回に最新更新順で取得（疑似通信）
  Future<void> _loadDummyThreads() async {
    await Future.delayed(Duration(milliseconds: 300)); // 疑似通信待ち

    setState(() {
      unofficialThreads = [
        Thread(id: 't1', title: '業界別の面接対策', timeAgo: '3分前'),
        Thread(id: 't2', title: '社会人一年目の過ごし方', timeAgo: '10分前'),
        Thread(id: 't3', title: 'おすすめの資格', timeAgo: '25分前'),
        Thread(id: 't4', title: '働きながら転職活動するには', timeAgo: '50分前'),
        Thread(id: 't5', title: '就活で意識すべきこと', timeAgo: '1時間前'),
      ];

      filteredThreads = List.from(unofficialThreads);
    });
  }

  // タイトル検索
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

  // 削除申請ダイアログ
  void _showDeleteDialog(Thread thread) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除申請'),
        content: Text('${thread.title} の削除を申請しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                unofficialThreads.remove(thread);
                filteredThreads.remove(thread);
              });
              Navigator.pop(context);
            },
            child: const Text('削除申請'),
          ),
        ],
      ),
    );
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
                const Text(
                  '非公式スレッド一覧',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '検索',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchThreads,
                  child: const Text('検索'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredThreads.length,
                itemBuilder: (context, index) {
                  final thread = filteredThreads[index];
                  return GestureDetector(
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
                    child: Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        title: Text(thread.title),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              thread.timeAgo,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showDeleteDialog(thread),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.black,
                              ),
                            ),
                          ],
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
