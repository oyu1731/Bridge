import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '32-thread-official-detail.dart';
import '33-thread-unofficial-detail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Thread モデルの定義 (仮)
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
    try {
      // 公式スレッドの取得
      final officialResponse = await http.get(
        Uri.parse('http://localhost:8080/api/official-threads'),
      ); // 仮のAPIエンドポイント
      if (officialResponse.statusCode == 200) {
        List<dynamic> officialJson = json.decode(officialResponse.body);
        officialThreads =
            officialJson.map((json) => Thread.fromJson(json)).toList();
      } else {
        print(
          'Failed to load official threads: ${officialResponse.statusCode}',
        );
      }

      // 非公式スレッドの取得
      final unofficialResponse = await http.get(
        Uri.parse('http://localhost:8080/api/unofficial-threads/hot'),
      ); // 仮のAPIエンドポイント
      if (unofficialResponse.statusCode == 200) {
        List<dynamic> unofficialJson = json.decode(unofficialResponse.body);
        hotUnofficialThreads =
            unofficialJson.map((json) => Thread.fromJson(json)).toList();
      } else {
        print(
          'Failed to load hot unofficial threads: ${unofficialResponse.statusCode}',
        );
      }

      setState(() {});
    } catch (e) {
      print('Error fetching threads: $e');
    }
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
              children:
                  officialThreads.map((thread) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ThreadOfficialDetail(thread: thread),
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
                    // TODO: ThreadUnofficialList ページの実装または適切な遷移先を検討
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => ThreadUnofficialList(),
                    //   ),
                    // );
                    print('非公式スレッド一覧ページへの遷移ボタンが押されました。');
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
              children:
                  hotUnofficialThreads.map((thread) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    ThreadUnofficialDetail(thread: thread),
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
