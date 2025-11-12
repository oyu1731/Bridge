import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '34-thread-create.dart';
import '33-thread-unofficial-detail.dart';

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
                  'スレッド一覧',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // 内側を白に
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
            // 検索バー
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '検索',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Colors.grey[700]),
                  onPressed: _searchThreads,
                ),
              ),
              onSubmitted: (_) => _searchThreads(),
            ),
            SizedBox(height: 20),
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
                      color: Colors.white, // カードの背景白
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
