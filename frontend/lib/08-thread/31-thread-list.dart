import 'dart:convert';
import 'package:bridge/06-company/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bridge/11-common/58-header.dart';
import '32-thread-official-detail.dart';
import '33-thread-unofficial-detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'thread_api_client.dart';
import 'thread_model.dart';
import 'thread-unofficial-list.dart';
import 'package:bridge/10-payment/55-plan-status.dart';

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
      userType = userData['type'] + 1;
    });
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserData(); //ユーザ取得
    await _checkAndUpdateSubscriptionStatus(); // 無料プランチェック
    await _fetchThreads(); //userType を使う処理
  }

  /// ログイン中のアカウントのサブスク確認・更新
  Future<void> _checkAndUpdateSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('current_user');
    if (jsonString == null) return;

    final userData = jsonDecode(jsonString);
    final userId = userData['id'];
    final accountType =
        userData['accountType'] ?? (userData['type'] == 3 ? '企業' : 'other');

    // 企業アカウントのみチェック
    if (accountType != '企業') {
      return;
    }

    try {
      final response = await http
          .post(
            Uri.parse(
              // "http://localhost:8080/api/users/$userId/check-subscription",
              "${ApiConfig.baseUrl}/api/users/$userId/check-subscription",
            ),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📋 スレッド画面: サブスク確認完了: ${data['message']}');

        // usersテーブルのplanStatusが更新されている場合、セッションも更新
        if (data['planStatus'] != null) {
          print('🔄 セッション更新: planStatus=${data['planStatus']}');
          userData['planStatus'] = data['planStatus'];
          await prefs.setString('current_user', jsonEncode(userData));

          // 無料に変わった場合
          if (data['planStatus'] == '無料') {
            print('⚠️ 無料プランを検出 - アラート表示');
            // ヘッダーのキャッシュとアラート履歴をリセット
            BridgeHeader.clearPlanStatusCache();
            BridgeHeader.resetAlertHistory(userId);

            if (mounted) {
              // アラートを表示してからプラン確認画面に遷移
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (_) => AlertDialog(
                      title: const Text('プランのご案内'),
                      content: const Text(
                        '現在のプランは「無料」です。\n\n'
                        '企業機能をすべて利用するには有料プランへのアップグレードが必要です。',
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        const PlanStatusScreen(userType: '企業'),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text('プランを確認'),
                        ),
                      ],
                    ),
              );
            }
          }
        }
      } else {
        print('❌ サブスク確認エラー: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ サブスク確認通信エラー: $e');
    }
  }

  Future<void> _fetchThreads() async {
    try {
      final threads = await ThreadApiClient.getAllThreads();

      // ---- 公式スレッド ----
      final official = threads.where((t) => t.type == 1).toList();

      // ---- 非公式フィルタ ----
      final filtered =
          threads
              .where(
                (t) =>
                    t.type == 2 &&
                    (t.entryCriteria == userType || t.entryCriteria == 1),
              )
              .toList();

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
