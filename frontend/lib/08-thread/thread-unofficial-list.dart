import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bridge/11-common/58-header.dart';
import '34-thread-create.dart';
import '33-thread-unofficial-detail.dart';

// Thread モデル（公式一覧と同じ構造に統一）
class Thread {
  final String id;
  final String title;
  final int type; // 1=公式, 2=非公式
  final String timeAgo;

  Thread({
    required this.id,
    required this.title,
    required this.type,
    required this.timeAgo,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    String timeAgoText = "";
    final lastUpdateStr = json["lastUpdateDate"];

    if (lastUpdateStr != null) {
      DateTime lastUpdate = DateTime.parse(lastUpdateStr);
      timeAgoText = _formatTimeAgo(lastUpdate);
    }

    return Thread(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      type: json['type'] != null ? int.parse(json['type'].toString()) : 2,
      timeAgo: timeAgoText,
    );
  }

  // 「◯分前」「◯時間前」形式へ変換
  static String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inSeconds < 60) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}

// API からスレッド一覧取得
Future<List<Thread>> fetchThreads() async {
  final url = Uri.parse('http://localhost:8080/api/threads');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => Thread.fromJson(json)).toList();
  } else {
    throw Exception('スレッド取得に失敗: ${response.statusCode}');
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
    _fetchUnofficialThreads();
  }

  Future<void> _fetchUnofficialThreads() async {
    try {
      final allThreads = await fetchThreads();

      setState(() {
        unofficialThreads =
            allThreads.where((t) => t.type == 2).toList(); // 非公式だけ取る
        filteredThreads = List.from(unofficialThreads);
      });
    } catch (e) {
      print("非公式スレッドの取得に失敗: $e");
    }
  }

  void _searchThreads() {
    final query = _searchController.text.trim();

    setState(() {
      if (query.isEmpty) {
        filteredThreads = List.from(unofficialThreads);
      } else {
        filteredThreads =
            unofficialThreads.where((t) => t.title.contains(query)).toList();
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
            // タイトル + スレッド作成ボタン
            Row(
              children: [
                Text(
                  '非公式スレッド一覧',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
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

            // 非公式スレッドの一覧
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
                          builder: (context) => ThreadUnOfficialDetail(
                            thread: {'id': thread.id, 'title': thread.title},
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: Colors.white,
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
