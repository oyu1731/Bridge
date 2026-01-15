import 'package:bridge/06-company/api_config.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThreadUnOfficialDetail extends StatefulWidget {
  final Map<String, dynamic> thread;
  const ThreadUnOfficialDetail({required this.thread, Key? key})
    : super(key: key);

  @override
  _ThreadUnOfficialDetailState createState() => _ThreadUnOfficialDetailState();
}

class _ThreadUnOfficialDetailState extends State<ThreadUnOfficialDetail> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  //ユーザーidを持ってくるが、今は固定値で作っている
  //initでユーザのIDを入れる
  String currentUserId = "";
  //ユーザ情報取得
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('current_user');
    if (jsonString == null) return;
    final userData = jsonDecode(jsonString);
    setState(() {
      currentUserId = userData['id'].toString();
    });
  }

  //useridを指定して情報を取得する箱
  Map<String, String> _userNicknames = {};
  List<Map<String, dynamic>> _messages = [];
  String searchText = '';
  bool _isSending = false;

  late final StreamController<List<Map<String, dynamic>>>
  _messageStreamController;
  late final WebSocketChannel _channel;
  // final String baseUrl = 'http://localhost:8080/api';
  final String baseUrl = ApiConfig.baseUrl;

  File? _selectedImage;
  Uint8List? _webImageBytes;
  String? _webImageName;
  bool _isUploading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _webImageBytes = bytes;
        _webImageName = picked.name;
        _selectedImage = null;
      });
    } else {
      setState(() {
        _selectedImage = File(picked.path);
        _webImageBytes = null;
      });
    }
  }

  Future<int?> uploadImage() async {
    if (_selectedImage == null && _webImageBytes == null) return null;
    setState(() => _isUploading = true);
    final uri = Uri.parse('$baseUrl/photos/upload');
    final request = http.MultipartRequest('POST', uri);
    //ここは絶対にユーザーidを文字列にする
    request.fields['userId'] = currentUserId.toString();
    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _webImageBytes!,
          filename: _webImageName ?? "upload.jpg",
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedImage!.path,
          // contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 201) {
        final jsonBody = jsonDecode(body);
        final photoId = jsonBody['id'];
        // final int? photoId = int.tryParse(
        //   RegExp(r'"id"\s*:\s*(\d+)').firstMatch(body)?.group(1) ?? '',
        // );
        return photoId;
      }
      return null;
    } catch (e) {
      print("Upload error: $e");
      return null;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<String?> fetchPhotoUrl(int photoId) async {
    final response = await http.get(Uri.parse('$baseUrl/photos/$photoId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // return "http://localhost:8080${data['photoPath']}";
      return "${ApiConfig.baseUrl}${data['photoPath']}";
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _messageStreamController =
        StreamController<List<Map<String, dynamic>>>.broadcast();
    _loadCurrentUser();
    _fetchMessages();
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:8080/ws/chat/${widget.thread['id']}'),
    );

    _channel.stream.listen((data) {
      try {
        final msg = Map<String, dynamic>.from(jsonDecode(data));
        if (!_messages.any((m) => m['id'] == msg['id'])) {
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
          // _scrollToBottom();
        }
      } catch (e) {
        print("WebSocket parse error: $e");
      }
    });
  }

  @override
  void dispose() {
    _channel.sink.close();
    _messageStreamController.close();
    _scrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/${widget.thread['id']}'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final fetched =
            data.map((msg) {
              return {
                'id': msg['id'],
                'user_id': msg['userId'].toString(),
                'text': msg['content'],
                'created_at': msg['createdAt'],
                'photoId': msg['photoId'],
              };
            }).toList();
        bool updated = false;
        for (var msg in fetched) {
          if (!_messages.any((m) => m['id'] == msg['id'])) {
            _messages.add(msg);
            updated = true;
          }
        }

        if (updated) {
          _messages.sort(
            (a, b) => DateTime.parse(
              a['created_at'],
            ).compareTo(DateTime.parse(b['created_at'])),
          );
          _messageStreamController.add(List.from(_messages));
          // _scrollToBottom();
        }
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  void _scrollToBottom() {
    // スクロール対象があるか確認
    if (!_scrollController.hasClients) return;

    // 描画後にスクロール
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null && _webImageBytes == null)
      return;
    setState(() => _isSending = true);

    int? photoId;
    if (_selectedImage != null || _webImageBytes != null) {
      photoId = await uploadImage();
    }

    final payload = {
      'userId': int.parse(currentUserId),
      'content': text,
      'threadId': widget.thread['id'],
      'photoId': photoId,
    };

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/${widget.thread['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final msg = json.decode(response.body);
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
        _scrollToBottom();
        _channel.sink.add(json.encode(msg));
        _messageController.clear();
        setState(() {
          _selectedImage = null;
          _webImageBytes = null;
          _webImageName = null;
        });
      } else {
        print("Send failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Send error: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _reportMessage(Map<String, dynamic> msg) async {
    try {
      final payload = {
        'fromUserId': int.parse(currentUserId),
        'toUserId': int.parse(msg['user_id']),
        'type': 2,
        'threadId': widget.thread['id'],
        'chatId': msg['id'],
      };
      final response = await http.post(
        Uri.parse('$baseUrl/notice/report'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("通報しました")));
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("このチャットはすでに通報済みです")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("通報に失敗しました")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("通信エラーが発生しました")));
    }
  }

  //ニックネーム取得
  Future<String> _getNickname(String userId) async {
    // すでに取得済みならそれを返す
    if (_userNicknames.containsKey(userId)) {
      return _userNicknames[userId]!;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/chat/user/$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nickname = data['nickname'] ?? 'Unknown';

        _userNicknames[userId] = nickname; // キャッシュする
        return nickname;
      }
    } catch (e) {
      print("Nickname fetch error: $e");
    }

    return "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.thread['title'] ?? 'スレッド',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_downward),
                  tooltip: '読み込める最新のコメントまでスクロール',
                  onPressed: _scrollToBottom, // ボタン押下時も確実にスクロール
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'コメント検索',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => searchText = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messageStreamController.stream,
              initialData: _messages,
              builder: (context, snapshot) {
                final items = snapshot.data!;
                final filtered =
                    items
                        .where(
                          (m) =>
                              searchText.isEmpty ||
                              m['text'].contains(searchText),
                        )
                        .toList();
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final msg = filtered[i];
                    final isMe = msg['user_id'] == currentUserId;
                    final createdAt = DateTime.parse(msg['created_at']);
                    final timeStr =
                        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: _getNickname(msg['user_id']),
                              builder: (context, snapshot) {
                                final name = snapshot.data ?? '...';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Text(
                                    isMe ? 'あなた' : name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isMe ? Colors.green[300] : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 12),
                                ),
                              ),
                              //コメントのコンテナ
                              child: Column(
                                crossAxisAlignment:
                                    isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                children: [
                                  if (msg['photoId'] != null) ...[
                                    FutureBuilder(
                                      future: fetchPhotoUrl(msg['photoId']),
                                      builder: (context, snapshot) {
                                        Widget imageWidget;

                                        if (snapshot.hasData) {
                                          // 画像が読み込まれたらスクロール
                                          WidgetsBinding.instance
                                              .addPostFrameCallback(
                                                (_) => _scrollToBottom(),
                                              );

                                          imageWidget = Image.network(
                                            snapshot.data!,
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          );
                                        } else {
                                          imageWidget = SizedBox(
                                            width: 200,
                                            height: 200,
                                          ); // プレースホルダー
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: imageWidget,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(child: Text(msg['text'])),
                                      if (!isMe)
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            if (value == 'report')
                                              _reportMessage(msg);
                                          },
                                          itemBuilder:
                                              (context) => [
                                                PopupMenuItem(
                                                  value: 'report',
                                                  child: Text('通報する'),
                                                ),
                                              ],
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(timeStr, style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_selectedImage != null || _webImageBytes != null)
            Align(
              alignment: Alignment.centerLeft, // 左寄せ
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          kIsWeb
                              ? Image.memory(
                                _webImageBytes!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                              : Image.file(
                                _selectedImage!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _webImageBytes = null;
                            _webImageName = null;
                          });
                        },
                        child: CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SafeArea(
            child: Row(
              children: [
                IconButton(icon: Icon(Icons.photo), onPressed: pickImage),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'メッセージを入力',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                IconButton(
                  icon:
                      _isSending
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(Icons.send, color: Colors.blue),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
