import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '39-admin-thread-detail.dart';
import 'admin-thread-list.dart';

// Thread モデル
class Thread {
  final int id;
  final String title;
  final String? lastComment;
  final String timeAgo;

  Thread({
    required this.id,
    required this.title,
    this.lastComment,
    required this.timeAgo,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    return Thread(
      id: json['id'],
      title: json['title'] as String,
      lastComment: json['lastComment'] as String?,
      timeAgo: json['timeAgo'] as String,
    );
  }
}

class AdminThreadList extends StatefulWidget {
  @override
  _AdminThreadListState createState() => _AdminThreadListState();
}

class _AdminThreadListState extends State<AdminThreadList> {
  List<Thread> officialThreads = [];
  List<Thread> unofficialThreads = [];

  @override
  void initState() {
    super.initState();
    _loadDummyThreads();
  }

  Future<void> _loadDummyThreads() async {
    await Future.delayed(Duration(milliseconds: 300));
    setState(() {
      officialThreads = [
        Thread(
          id: 1,
          title: '学生・社会人',
          lastComment: '最近忙しいけど頑張ってる！',
          timeAgo: '3分前',
        ),
        Thread(
          id: 2,
          title: '学生',
          lastComment: 'テスト期間でやばいです…',
          timeAgo: '15分前',
        ),
        Thread(id: 3, title: '社会人', lastComment: '残業が多くてつらい…', timeAgo: '42分前'),
      ];

      unofficialThreads = [
        Thread(id: 4, title: '業界別の面接対策', timeAgo: '3分前'),
        Thread(id: 5, title: '社会人一年目の過ごし方', timeAgo: '10分前'),
        Thread(id: 6, title: 'おすすめの資格', timeAgo: '25分前'),
        Thread(id: 7, title: '働きながら転職活動するには', timeAgo: '50分前'),
        Thread(id: 8, title: '就活で意識すべきこと', timeAgo: '1時間前'),
      ];
    });
  }

  void _deleteThread(List<Thread> threadList, int index) async {
    bool confirm = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('削除確認'),
            content: Text('このスレッドを削除しますか？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('キャンセル'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('削除'),
              ),
            ],
          ),
    );

    if (confirm) {
      setState(() {
        threadList.removeAt(index);
      });
    }
  }

  Widget _buildThreadCard(
    Thread thread,
    List<Thread> threadList,
    int index, {
    bool showLastComment = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminThreadDetail(threadId: thread.id),
          ),
        );
      },
      child: Card(
        color: Colors.white, // 背景を白に
        margin: EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Text(
            thread.title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle:
              showLastComment && thread.lastComment != null
                  ? Text(
                    thread.lastComment!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  )
                  : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(thread.timeAgo, style: TextStyle(color: Colors.grey)),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.black),
                onPressed: () => _deleteThread(threadList, index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
              children:
                  officialThreads.map((thread) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    AdminThreadDetail(threadId: thread.id),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle:
                              thread.lastComment != null
                                  ? Text(
                                    thread.lastComment!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
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
                  '直近に通報のあったスレッド',
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
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Column(
              children:
                  unofficialThreads.map((thread) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    AdminThreadDetail(threadId: thread.id),
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
