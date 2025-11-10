import 'package:flutter/material.dart';
/*
リアルタイムチャットに必要な Firestore パッケージの導入がまだのため、
Firebase 関連の import やリアルタイムチャット用のコードはコメントアウトしています。
*/
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bridge/11-common/58-header.dart';
import '31-thread-list.dart'; // Thread モデルをインポート
import 'dart:async';

class ThreadUnofficialDetail extends StatefulWidget {
  final Map<String, dynamic> thread;

  const ThreadUnofficialDetail({required this.thread, Key? key})
      : super(key: key);

  @override
  _ThreadUnofficialDetailState createState() => _ThreadUnofficialDetailState();
}

class _ThreadUnofficialDetailState extends State<ThreadUnofficialDetail> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = 'user_001'; // 仮ユーザー

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

  // メッセージ送信（擬似ソケットでリアルタイム反映）
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = {
      'id': (_messages.isEmpty ? 0 : _messages.last['id'] as int) + 1,
      'user_id': currentUserId,
      'text': text,
      'created_at': DateTime.now(),
    };

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // ストリームへ追加（他クライアントに届く想定）
    _messageStreamController.add(_messages);

    // 一番下にいるときのみ自動スクロールで最新を表示
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
        // ユーザーが上を見ている場合はバッジ表示
        setState(() {
          _showNewBadge = true;
        });
      }
    });
  }

  // （将来）外部ソケットからの着信を想定した擬似メソッド
  // 実際にバックエンド接続したら socket.on('new_message', ...) 内で呼ぶ
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
                    widget.thread['title'] ?? 'スレッド',
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
                    final isMe = msg['user_id'] == currentUserId;

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
                        Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe)
                                const CircleAvatar(
                                  // assetsパスはプロジェクトに合わせて調整
                                  backgroundImage: AssetImage('assets/user_icon1.png'),
                                  radius: 18,
                                ),
                              if (!isMe) const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                              if (isMe) const SizedBox(width: 8),
                              if (isMe)
                                const CircleAvatar(
                                  backgroundImage: AssetImage('assets/user_icon2.png'),
                                  radius: 18,
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 入力欄
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'メッセージを入力',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
