import 'dart:async';
import 'dart:convert';
import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminThreadDetail extends StatefulWidget {
  final String threadId;
  final String title;

  const AdminThreadDetail({
    super.key,
    required this.threadId,
    required this.title,
  });

  @override
  State<AdminThreadDetail> createState() => _AdminThreadDetailState();
}

class _AdminThreadDetailState extends State<AdminThreadDetail> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late final StreamController<List<Map<String, dynamic>>>
  _messageStreamController;
  late final WebSocketChannel _channel;

  final List<Map<String, dynamic>> _messages = [];
  final Map<String, String> _userNicknames = {};

  String _searchText = '';
  bool _showNewBadge = false;

  final String baseUrl = '${ApiConfig.baseUrl}/api';

  @override
  void initState() {
    super.initState();

    _messageStreamController =
        StreamController<List<Map<String, dynamic>>>.broadcast();

    _fetchMessages();
    _connectWebSocket();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _channel.sink.close();
    _messageStreamController.close();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // -------------------------
  // 初期メッセージ取得
  // -------------------------
  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/${widget.threadId}/active'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        for (final msg in data) {
          _messages.add({
            'id': msg['id'],
            'user_id': msg['userId'].toString(),
            'text': msg['content'],
            'created_at': msg['createdAt'],
            'photoId': msg['photoId'],
          });
        }

        _messages.sort(
          (a, b) => DateTime.parse(
            a['created_at'],
          ).compareTo(DateTime.parse(b['created_at'])),
        );

        _messageStreamController.add(List.from(_messages));
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('管理者メッセージ取得失敗: $e');
    }
  }

  // -------------------------
  // WebSocket 接続（受信専用）
  // -------------------------
  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse(ApiConfig.chatWebSocketUrl(widget.threadId)),
    );

    _channel.stream.listen((data) {
      try {
        final msg = Map<String, dynamic>.from(jsonDecode(data));

        if (_messages.any((m) => m['id'] == msg['id'])) return;

        _messages.add({
          'id': msg['id'],
          'user_id': msg['userId'].toString(),
          'text': msg['content'],
          'created_at': msg['createdAt'],
          'photoId': msg['photoId'],
        });

        _messages.sort(
          (a, b) => DateTime.parse(
            a['created_at'],
          ).compareTo(DateTime.parse(b['created_at'])),
        );

        _messageStreamController.add(List.from(_messages));

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;

          if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 50) {
            _scrollToBottom();
          } else {
            setState(() => _showNewBadge = true);
          }
        });
      } catch (e) {
        debugPrint('WebSocket parse error: $e');
      }
    });
  }

  // -------------------------
  // スクロール制御
  // -------------------------
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onScroll() {
    if (_showNewBadge &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50) {
      setState(() => _showNewBadge = false);
    }
  }

  // -------------------------
  // ニックネーム取得
  // -------------------------
  Future<String> _getNickname(String userId) async {
    if (_userNicknames.containsKey(userId)) {
      return _userNicknames[userId]!;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/chat/user/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nickname = data['nickname'] ?? 'Unknown';
        _userNicknames[userId] = nickname;
        return nickname;
      }
    } catch (_) {}

    return 'Unknown';
  }

  // -------------------------
  // 画像データ取得
  // -------------------------
  Future<String?> fetchPhotoUrl(int photoId) async {
    final response = await http.get(Uri.parse('$baseUrl/photos/$photoId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return "http://localhost:8080${data['photoPath']}";
    }
    return null;
  }

  Future<void> _confirmDeleteChat(int chatId) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('コメント削除'),
            content: const Text('このコメントを削除しますか？'),
            actions: [
              TextButton(
                child: const Text('キャンセル'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('削除'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (result == true) {
      await _deleteChat(chatId);
    }
  }

  Future<void> _deleteChat(int chatId) async {
    final response = await http.put(Uri.parse('$baseUrl/chat/$chatId/delete'));

    if (response.statusCode == 200) {
      setState(() {
        _messages.removeWhere((m) => m['id'] == chatId);
      });
      _messageStreamController.add(List.from(_messages));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('コメントの削除に失敗しました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
        children: [
          // ===== ヘッダー =====
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                /// ↓↓↓ 追加：最新コメントへスクロールボタン ↓↓↓
                Tooltip(
                  message: '読み込める最新のコメントまでスクロール',
                  child: IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: _scrollToBottom,
                  ),
                ),

                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'コメント検索',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _searchText = v.trim()),
                  ),
                ),
              ],
            ),
          ),

          if (_showNewBadge)
            GestureDetector(
              onTap: () {
                _scrollToBottom();
                setState(() => _showNewBadge = false);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '新しいメッセージがあります',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

          // ===== メッセージ一覧 =====
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStreamController.stream,
              initialData: _messages,
              builder: (context, snapshot) {
                final messages =
                    snapshot.data!
                        .where(
                          (m) =>
                              _searchText.isEmpty ||
                              m['text'].contains(_searchText),
                        )
                        .toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final createdAt = DateTime.parse(msg['created_at']);
                    final time =
                        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(radius: 18),
                          const SizedBox(width: 8),

                          Stack(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ニックネーム
                                  FutureBuilder<String>(
                                    future: _getNickname(msg['user_id']),
                                    builder:
                                        (_, snap) => Text(
                                          snap.data ?? '...',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  ),

                                  // 吹き出し（横幅制限が超重要）
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.65,
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        top: 4,
                                        right: 28,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey[200],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (msg['photoId'] != null)
                                            FutureBuilder<String?>(
                                              future: fetchPhotoUrl(
                                                msg['photoId'],
                                              ),
                                              builder: (context, snapshot) {
                                                if (!snapshot.hasData) {
                                                  return const SizedBox(
                                                    width: 200,
                                                    height: 200,
                                                  );
                                                }
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    child: Image.network(
                                                      snapshot.data!,
                                                      width: 200,
                                                      height: 200,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          if (msg['text'] != null &&
                                              msg['text'].toString().isNotEmpty)
                                            Text(msg['text']),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // 時刻
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      time,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),

                              // 削除ボタン：吹き出し右下
                              Positioned(
                                right: 0,
                                bottom: 18,
                                child: IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed:
                                      () => _confirmDeleteChat(msg['id']),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
