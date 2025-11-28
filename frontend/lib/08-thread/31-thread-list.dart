import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bridge/11-common/58-header.dart';
import '32-thread-official-detail.dart';
import '33-thread-unofficial-detail.dart';
import 'thread-unofficial-list.dart';

// Thread モデル
class Thread {
  final String id;
  final String title;
  final int type; // 1=公式, 2=非公式
  final String? lastComment; // 公式のみ
  final String timeAgo;

  Thread({
    required this.id,
    required this.title,
    required this.type,
    this.lastComment,
    required this.timeAgo,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    // last_update_date があれば経過時間を計算
    String timeAgoText = "";
    if (json["last_update_date"] != null) {
      DateTime lastUpdate = DateTime.parse(json["last_update_date"]);
      timeAgoText = _formatTimeAgo(lastUpdate);
    }

    return Thread(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      type: json['type'] != null ? int.parse(json['type'].toString()) : 2,
      lastComment: null, // DB仕様上なし
      timeAgo: timeAgoText,
    );
  }

  /// 時間差 → 「〜分前」「〜時間前」「〜日前」
  static String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inSeconds < 60) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}

// API呼び出し関数
Future<List<Thread>> fetchThreads() async {
  final url = Uri.parse('http://localhost:8080/api/threads');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Thread.fromJson(json)).toList();
  } else {
    throw Exception('スレッド取得に失敗しました: ${response.statusCode}');
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
    _fetchThreads(); // DBから取得
  }

  Future<void> _fetchThreads() async {
    try {
      final threads = await fetchThreads();

      setState(() {
        officialThreads = threads.where((t) => t.type == 1).toList();
        hotUnofficialThreads = threads.where((t) => t.type == 2).toList();
      });
    } catch (e) {
      print('スレッド取得に失敗: $e');
    }
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
                          thread: {'id': thread.id, 'title': thread.title},
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white, // 背景を白に設定
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

            SizedBox(height: 30),

            // 非公式スレッド
            Row(
              children: [
                Text(
                  'HOTスレッド',
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
              children: hotUnofficialThreads.map((thread) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ThreadUnofficialDetail(
                          thread: {'id': thread.id, 'title': thread.title},
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white, // 背景を白に設定
                    margin: EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
