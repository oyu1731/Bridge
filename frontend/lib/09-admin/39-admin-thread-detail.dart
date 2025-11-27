import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'dart:async';

class AdminThreadDetail extends StatefulWidget {
  final int threadId; // ← String → int に変更

  const AdminThreadDetail({required this.threadId, super.key});

  @override
  _AdminThreadDetailState createState() => _AdminThreadDetailState();
}

class _AdminThreadDetailState extends State<AdminThreadDetail> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String searchText = ''; // 検索文字列

  // ---- 擬似メッセージデータ（サーバー代替） ----
  List<Map<String, dynamic>> _messages = [];
  int _loadedPages = 1;
  final int _pageSize = 20;

  // ソケット風 StreamController（リアルタイム更新用）
  late final StreamController<List<Map<String, dynamic>>> _messageStreamController;

  // 新着バッジ表示フラグ（上を見てるときに新着を示す）
  bool _showNewBadge = false;

  @override
  void initState() {
    super.initState();
    _messageStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
    _loadInitialMessages();

    // 無限スクロール（上方向）監視
    _scrollController.addListener(() {
      // 上端に近づいたら過去ログをロード
      if (_scrollController.position.pixels <=
          _scrollController.position.minScrollExtent + 10) {
        _loadMoreMessages();
      }

      // 新着バッジ自動消去：ユーザーが下に戻ってきたらバッジを消す
      if (_showNewBadge &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 50) {
        setState(() {
          _showNewBadge = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageStreamController.close();
    _scrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // 初期データ読み込み（最新ページを生成）
  void _loadInitialMessages() {
    final now = DateTime.now();
    List<Map<String, dynamic>> initialData = List.generate(_pageSize, (index) {
      return {
        'id': index,
        'user_id': index % 2 == 0 ? 'user_001' : 'user_002',
        'text': 'メッセージ ${index + 1} (最新側)',
        'created_at': now.subtract(Duration(minutes: _pageSize - index))
      };
    });

    _messages = initialData;
    _messageStreamController.add(_messages);
    // 初回は下までスクロール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // 上スクロール（過去ログ）を追加読み込み
  Future<void> _loadMoreMessages() async {
    // ロード中に何度も呼ばれるのを防ぎ、疑似待ち時間
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 400));

    final base = _loadedPages * _pageSize;
    final now = DateTime.now();
    List<Map<String, dynamic>> moreData = List.generate(_pageSize, (index) {
      final id = base + index;
      return {
        'id': id,
        'user_id': id % 2 == 0 ? 'user_001' : 'user_002',
        'text': '過去メッセージ ${id + 1}',
        'created_at': now.subtract(Duration(minutes: id + 1 + _pageSize))
      };
    });

    // preserve scroll offset: record current offset from top, then update list, then restore near same visual spot
    double prevScrollHeight = _scrollController.hasClients ? _scrollController.position.maxScrollExtent : 0;
    setState(() {
      _messages = [...moreData, ..._messages];
      _loadedPages++;
    });
    _messageStreamController.add(_messages);

    // attempt to keep view on the same message after prepending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final newScrollHeight = _scrollController.position.maxScrollExtent;
      final delta = newScrollHeight - prevScrollHeight;
      if (delta > 0) {
        _scrollController.jumpTo(_scrollController.position.pixels + delta);
      }
    });
  }

  // （将来）外部ソケットからの着信を想定した擬似メソッド
  void _onExternalNewMessage(Map<String, dynamic> msg) {
    setState(() {
      _messages.add(msg);
    });
    _messageStreamController.add(_messages);

    // 新着に対するスクロール制御は送信と同様
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        setState(() {
          _showNewBadge = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
        children: [
          // タイトル＋検索バー
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "スレッドID: ${widget.threadId}", // ← 受け取ったIDのみ使用
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'コメント検索',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchText = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 新着バッジ
          if (_showNewBadge)
            GestureDetector(
              onTap: () {
                // タップで最新までスクロールしてバッジを消す
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
                setState(() {
                  _showNewBadge = false;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('新しいメッセージがあります', style: TextStyle(color: Colors.white)),
              ),
            ),

          // コメント一覧（ソケット風リアルタイム表示＋無限スクロール）
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStreamController.stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 検索フィルタ
                final filteredMessages = snapshot.data!.where((msg) {
                  final text = (msg['text'] ?? '').toString();
                  return searchText.isEmpty || text.contains(searchText);
                }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    final msg = filteredMessages[index];

                    final createdAt = msg['created_at'] as DateTime;
                    final timeString =
                        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                    final dateString =
                        '${createdAt.year}年${createdAt.month}月${createdAt.day}日';

                    bool showDateLabel = index == 0 ||
                        dateString !=
                            '${(filteredMessages[index - 1]['created_at'] as DateTime).year}年'
                            '${(filteredMessages[index - 1]['created_at'] as DateTime).month}月'
                            '${(filteredMessages[index - 1]['created_at'] as DateTime).day}日';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateLabel)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(dateString, style: const TextStyle(fontSize: 13)),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const CircleAvatar(
                              backgroundImage: AssetImage('assets/user_icon1.png'),
                              radius: 18,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(msg['user_id'], style: const TextStyle(fontSize: 12)),
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(width: 1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(msg['text'], style: const TextStyle(fontSize: 15)),
                                  ),
                                  Text(timeString, style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
