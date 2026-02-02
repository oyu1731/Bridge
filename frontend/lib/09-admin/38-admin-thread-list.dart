import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '39-admin-thread-detail.dart';
import 'package:bridge/08-thread/thread_api_client.dart';
import 'package:bridge/08-thread/thread_model.dart';
import 'admin_reported_thread.dart';
import 'admin-thread-list.dart';

class AdminThreadList extends StatefulWidget {
  @override
  _AdminThreadListState createState() => _AdminThreadListState();
}

class _AdminThreadListState extends State<AdminThreadList> {
  List<Thread> officialThreads = [];
  List<AdminReportedThread> unofficialThreads = [];

  @override
  void initState() {
    super.initState();
    _fetchThreads();
  }

  Future<void> _fetchThreads() async {
    try {

      final allThreads = await ThreadApiClient.getAllThreads();
      final official = allThreads.where((t) => t.type == 1).toList();

      final reportedThreads = await ThreadApiClient.getReportedThreads();
      final unofficial = reportedThreads
          .where((r) => r.thread.type == 2)
          .toList();

      // 通報順
      unofficial.sort((a, b) {
        final aDate = a.thread.lastReportedAt ?? DateTime(2000);
        final bDate = b.thread.lastReportedAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });

      // 上位5件
      final top5 = unofficial.take(5).toList();

      setState(() {
        officialThreads = official;
        unofficialThreads = top5;
      });
    } catch (e) {
      print('管理者スレッド取得失敗: $e');
    }
  }

  Future<void> _confirmDeleteThread(AdminReportedThread reported) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このスレッドを削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteThread(reported.thread.id);
    }
  }

  Future<void> _deleteThread(String threadId) async {
    try {
      await ThreadApiClient.deleteThread(threadId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('スレッドを削除しました')),
      );

      _fetchThreads();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除に失敗しました')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== 公式スレッド =====
            const Text(
              '公式スレッド',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Column(
              children: officialThreads.map((thread) {
                return GestureDetector(
                  onTap: () {
                    print('thread.id=${thread.id}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminThreadDetail(
                          threadId: thread.id,
                          title: thread.title,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        thread.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        thread.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            thread.timeAgo,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),

            // ===== 非公式スレッド =====
            const Text(
              '直近に通報のあったスレッド',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  // ★追加：戻ってきたら再取得
                  final changed = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ThreadUnofficialList(),
                    ),
                  );

                  if (changed == true) {
                    _fetchThreads();
                  }
                },
                child: const Text(
                  'もっと見る',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: unofficialThreads.map((thread) {
                return GestureDetector(
                  onTap: () {
                    print('thread.id=${thread.thread.id}');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminThreadDetail(
                          threadId: thread.thread.id,
                          title: thread.thread.title,
                        ),
                      ),
                    );
                  },
                  child: Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        thread.thread.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        thread.thread.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            thread.thread.adminTimeAgo ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _confirmDeleteThread(thread),
                          ),
                        ],
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
