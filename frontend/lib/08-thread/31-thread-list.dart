import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bridge/11-common/58-header.dart';
import '32-thread-official-detail.dart';
import '33-thread-unofficial-detail.dart';
import 'thread-unofficial-list.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Thread モデル
class Thread {
  final String id;
  final String title;
  final int type; // 1=公式, 2=非公式
  final String description;
  final int entryCriteria;//1=全員, 2=学生のみ, 3=社会人のみ
  final DateTime? lastCommentDate;
  final String timeAgo;

  Thread({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.entryCriteria,
    this.lastCommentDate,
    required this.timeAgo,
  });

  factory Thread.fromJson(Map<String, dynamic> json) {
    String timeAgoText = "";
    DateTime? lastUpdateDate;

    // lastUpdateDate → timeAgo に使用 & 並び替えにも使う
    final lastUpdateStr = json["lastUpdateDate"] ?? json["lastUpdateDate"];
    if (lastUpdateStr != null && lastUpdateStr != "") {
      lastUpdateDate = DateTime.parse(lastUpdateStr);
      timeAgoText = _formatTimeAgo(lastUpdateDate);
    }

    return Thread(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      type: json['type'] != null ? int.parse(json['type'].toString()) : 2,
      description: json['description']?.toString() ?? '',
      entryCriteria: json['entryCriteria'],
      lastCommentDate: lastUpdateDate,  // ← ここ重要！
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
  print(response.body); 

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
  //ユーザ情報取得
  int? userType;
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('current_user');
    if (jsonString == null) return;

    final userData = jsonDecode(jsonString);

    setState(() {
      userType = userData['type']+1;
    });
  }
  @override
  void initState() {
    super.initState();
    _fetchThreads(); // DBから取得
  }

  Future<void> _fetchThreads() async {
    try {
      //ちゃんと読み込めるようにawaitを付ける！
      await _loadUserData();
      print("aaaa");
      print(userType);
      print("aaaa");
      final threads = await fetchThreads();
      print(threads.map((t) => t.timeAgo).toList()); 

      setState(() {
        officialThreads = threads.where((t) => t.type == 1).toList();
        print(userType);
        //リスト（ソートされた）を作る
        hotUnofficialThreads = threads.where((t) => t.type == 2 && (t.entryCriteria == userType || t.entryCriteria == 1))
          .toList()
          ..sort((a, b) {
            final aDate = a.lastCommentDate ?? DateTime(2000);
            final bDate = b.lastCommentDate ?? DateTime(2000);
            return bDate.compareTo(aDate); // 新しい順
          });
        //作られたリストに対して上位５件を取得
        hotUnofficialThreads = hotUnofficialThreads.take(5).toList();
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
                      //スレッドの説明文
                      subtitle: Text(
                        thread.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
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
                        builder: (context) => ThreadUnOfficialDetail(
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
                      //スレッドの説明文
                      subtitle: Text(
                        thread.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[700],
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
