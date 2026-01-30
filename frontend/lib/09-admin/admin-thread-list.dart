import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '39-admin-thread-detail.dart';
import 'package:bridge/08-thread/thread_api_client.dart';
import 'package:bridge/08-thread/thread_model.dart';

class ThreadUnofficialList extends StatefulWidget {
  @override
  _ThreadUnofficialListState createState() => _ThreadUnofficialListState();
}

class _ThreadUnofficialListState extends State<ThreadUnofficialList> {
  List<Thread> unofficialThreads = [];
  List<Thread> filteredThreads = [];
  final TextEditingController _searchController = TextEditingController();

  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _fetchUnofficialThreads();
  }

  Future<void> _fetchUnofficialThreads() async {
    try {
      final allThreads = await ThreadApiClient.getAllThreads();

      setState(() {
        unofficialThreads = allThreads.where((t) => t.type == 2).toList();
        filteredThreads = List.from(unofficialThreads);
      });
    } catch (e) {
      debugPrint('管理者 非公式スレッド取得失敗: $e');
    }
  }

  Future<void> _confirmDeleteThread(Thread thread) async {
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
      await _deleteThread(thread.id);
    }
  }

  Future<void> _deleteThread(String threadId) async {
    try {
      await ThreadApiClient.deleteThread(threadId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('スレッドを削除しました')),
      );

      await _fetchUnofficialThreads();
      _hasChanged = true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除に失敗しました')),
      );
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanged);
        return false;
      },
      child: Scaffold(
        appBar: BridgeHeader(),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル
              const Text(
                '非公式スレッド一覧',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              // 検索バー（タイトルの下）
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '検索',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: _searchThreads,
                  ),
                ),
                onSubmitted: (_) => _searchThreads(),
              ),

              const SizedBox(height: 20),

              // スレッド一覧
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
                          title: Text(thread.title),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                thread.timeAgo,
                                style:
                                    const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () =>
                                    _confirmDeleteThread(thread),
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
      ),
    );
  }
}
