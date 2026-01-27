import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bridge/11-common/58-header.dart';
import '32-thread-official-detail.dart';
import '33-thread-unofficial-detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'thread_api_client.dart';
import 'thread_model.dart';
import 'thread-unofficial-list.dart';

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
      userType = userData['type'];
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserData(); //ユーザ取得
    await _fetchThreads(); //userType を使う処理
  }

  Future<void> _fetchThreads() async {
    try {
      final threads = await ThreadApiClient.getAllThreads();
      // ★★★★★ ここに入れる ★★★★★
      print('=== THREAD DEBUG START ===');
      print('userType=$userType');
      for (final t in threads) {
        print(
          'threadId=${t.id},threadtitle=${t.title}, type=${t.type}, entry=${t.entryCriteria}, lastComment=${t.lastCommentDate}',
        );
      }
      print('=== THREAD DEBUG END ===');

      // ---- 公式スレッド ----
      final official = threads.where((t) => t.type == 1).toList();

      // ---- 非公式フィルタ ----
      final filtered =
          threads.where((t) {
            if (t.type != 2) return false;
            // 全員OK
            if (t.entryCriteria == 1) return true;
            // 学生
            if (userType == 1 && t.entryCriteria == 2) return true;
            // 社会人
            if (userType == 2 && t.entryCriteria == 3) return true;
            return false;
          }).toList();

      // 並び替え（新しい順）
      filtered.sort((a, b) {
        final aDate = a.lastCommentDate ?? DateTime(2000);
        final bDate = b.lastCommentDate ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      // 上位5件
      final top5 = filtered.take(5).toList();

      setState(() {
        officialThreads = official;
        hotUnofficialThreads = top5;
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
              children:
                  officialThreads.map((thread) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ThreadOfficialDetail(
                                  thread: {
                                    'id': thread.id,
                                    'title': thread.title,
                                  },
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          //スレッドの説明文
                          subtitle: Text(
                            thread.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
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
              children:
                  hotUnofficialThreads.map((thread) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ThreadUnOfficialDetail(
                                  thread: {
                                    'id': thread.id,
                                    'title': thread.title,
                                  },
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
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          //スレッドの説明文
                          subtitle: Text(
                            thread.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
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
