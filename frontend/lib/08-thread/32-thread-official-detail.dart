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
import 'package:bridge/main.dart';

class ThreadOfficialDetail extends StatefulWidget {
  final Map<String, dynamic> thread;
  const ThreadOfficialDetail({required this.thread, Key? key}) : super(key: key);

  @override
  _ThreadOfficialDetailState createState() => _ThreadOfficialDetailState();
}

class _ThreadOfficialDetailState extends State<ThreadOfficialDetail> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  //サインインしているユーザーのアイコンのURL
  String? _currentUserIconUrl; 
  //initでユーザのIDを入れる
  String currentUserId="";
  //読み込めたかどうかの判定
  bool _isUserLoaded = false;
  //ユーザ情報取得
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('current_user');
    if (jsonString == null) return;
    final userData = jsonDecode(jsonString);
    currentUserId = userData['id'].toString();
    final res = await http.get(
      Uri.parse('$baseUrl/chat/user/$currentUserId'),
    );
    if (res.statusCode == 200) {
      final iconId = json.decode(res.body)['icon'];
      if (iconId != null) {
        final res2 = await http.get(
          Uri.parse('$baseUrl/photos/$iconId'),
        );
        if (res2.statusCode == 200) {
          final path = json.decode(res2.body)['photoPath'];
          _currentUserIconUrl = "http://localhost:8080$path";
        }
      }
    }
    // setState(() {
    //   currentUserId = userData['id'].toString();
    // });
    setState(() {
      currentUserId = userData['id'].toString();
      _isUserLoaded = true;
    });
  }
  Map<String, String> _userNicknames = {};
  List<Map<String, dynamic>> _messages = [];
  String searchText = '';
  bool _isSending = false;

  late final StreamController<List<Map<String, dynamic>>> _messageStreamController;
  late final WebSocketChannel _channel;
  final String baseUrl = 'http://localhost:8080/api';

  File? _selectedImage;
  Uint8List? _webImageBytes;
  String? _webImageName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _messageStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
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
            'userIconUrl': msg['userIconUrl'], 
          });
          _messages.sort((a, b) =>
              DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
          _messageStreamController.add(List.from(_messages));

          //ページを開いたときに下まで移動する（移動しないだめコメントアウト）
          // if (msg['userId'].toString() == currentUserId) {
          //   _scrollToBottom();
          // }
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

  //写真を大きく表示（写真をクリックされた時用）
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,      //これをいれなきゃたまに画像が送れない（0〜100）
      //maxWidth: 1200,        // ← 大きすぎる画像を縮小
    );
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

  //写真の保存
  Future<int?> uploadImage() async {
    if (_selectedImage == null && _webImageBytes == null) return null;
    setState(() => _isUploading = true);
    final uri = Uri.parse('$baseUrl/photos/upload');
    final request = http.MultipartRequest('POST', uri);
    request.fields['userId'] = currentUserId;
    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        _webImageBytes!,
        filename: _webImageName ?? "upload.jpg",
        //contentType: MediaType('image', 'jpeg'),
      ));
    } else {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _selectedImage!.path,
        //contentType: MediaType('image', 'jpeg'),
      ));
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
        print("aaaaaaaaaaaaaaaaa");
        print("=== Upload Response Status === ${response.statusCode}");
        print("=== Upload Response Body === $body");
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

  //写真のパス取得
  Future<String?> fetchPhotoUrl(int photoId) async {
    final response = await http.get(Uri.parse('$baseUrl/photos/$photoId'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return "http://localhost:8080${data['photoPath']}";
    }
    return null;
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/${widget.thread['id']}/active')
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        for (var msg in data) {
          final userId = msg['userId'].toString();
          String? userIconUrl;
          //ユーザーidを指定してアイコンidを取得する
          final response = await http.get(
            Uri.parse('$baseUrl/chat/user/$userId')
          );
          //名前、アイコンidが取得
          print(json.decode(response.body)['icon']);
          final chat_userid=json.decode(response.body)['icon'];
          //アイコンidを指定してアイコンの写真のパスを取得
          final response2 = await http.get(
            Uri.parse('$baseUrl/photos/$chat_userid')
          );
          print(json.decode(response2.body));
          print("これでアイコンの写真のパスが取得できる");
          print(json.decode(response2.body)['photoPath']);
          final iconPath = json.decode(response2.body)['photoPath'];
          userIconUrl = "http://localhost:8080$iconPath";
          // アイコンIDがあればURLを取得
          // if (msg['userIconId'] != null) {
          //   final iconResponse = await http.get(Uri.parse('$baseUrl/photos/${msg['userIconId']}'));
          //   if (iconResponse.statusCode == 200) {
          //     final iconData = json.decode(iconResponse.body);
          //     userIconUrl = "http://localhost:8080/photos/${iconData['photoPath']}";
          //   }
          // }
          // メッセージリストに追加
          if (!_messages.any((m) => m['id'] == msg['id'])) {
            _messages.add({
              'id': msg['id'],
              'user_id': userId,
              'text': msg['content'],
              'created_at': msg['createdAt'],
              'photoId': msg['photoId'],
              'userIconUrl': userIconUrl,
            });
          }
          print("UserId: $userId, IconUrl: $userIconUrl");
        }
        // 投稿時間順にソート
        _messages.sort((a, b) =>
            DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
        _messageStreamController.add(List.from(_messages));
      }
    } catch (e) {
      print("Fetch error: $e");
    }
  }

  //読み込める場所までスクロール
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

  //サインインができていないユーザーをサインインページに
  void _showLoginExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('ログインが必要です'),
          content: const Text(
            'ログイン状態が切れています。\nもう一度サインインしてください。',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // ダイアログを閉じる
                Navigator.of(context).pop();

                // ログイン情報をクリア（安全のため）
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // サインイン画面（MyHomePage）へ戻す
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MyHomePage(title: 'Bridge'),
                  ),
                  (_) => false,
                );
              },
              child: const Text('サインインへ'),
            ),
          ],
        );
      },
    );
  }

  //チャットを送信する
  Future<void> _sendMessage() async {
    //セッションが切れていないか確認する
    if (currentUserId.isEmpty) {
      _showLoginExpiredDialog();
      return;
    }
    // if (currentUserId.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text("ログインが切れています。再ログインしてください")),
    //   );
    //   return;
    // }
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null && _webImageBytes == null) return;
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
          'userIconUrl': _currentUserIconUrl,
        });
        _messages.sort((a, b) =>
            DateTime.parse(a['created_at']).compareTo(DateTime.parse(b['created_at'])));
        _messageStreamController.add(List.from(_messages));

        _messageController.clear();
        setState(() {
          _selectedImage = null;
          _webImageBytes = null;
          _webImageName = null;
        });

        _channel.sink.add(json.encode({
          ...msg,
          'userIconUrl': _currentUserIconUrl,
        }));

        //自動スクロール
        _scrollToBottom(); 
      } else {
        print("Send failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Send error: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  //チャットを通報
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("通報しました")),
        );
      } else if (response.statusCode == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("このチャットはすでに通報済みです")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("通報に失敗しました")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("通信エラーが発生しました")),
      );
    }
  }

  //名前の取得
  Future<String> _getNickname(String userId) async {
    if (_userNicknames.containsKey(userId)) return _userNicknames[userId]!;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/user/$userId'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final nickname = data['nickname'] ?? 'Unknown';
        _userNicknames[userId] = nickname;
        return nickname;
      }
    } catch (e) {
      print("Nickname fetch error: $e");
    }
    return "Unknown";
  }

  //表示部分
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
                  child: Text(widget.thread['title'] ?? 'スレッド',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                final filtered = items
                    .where((m) => searchText.isEmpty || m['text'].contains(searchText))
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
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: _getNickname(msg['user_id']),
                              builder: (context, snapshot) {
                                final nickname = snapshot.data ?? '...';
                                final iconUrl = msg['userIconUrl']; // ここでアイコンURL取得

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 2.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // アイコン表示
                                      ClipOval(
                                        child: iconUrl != null && iconUrl.toString().isNotEmpty
                                            ? Image.network(
                                                iconUrl,
                                                width: 16,
                                                height: 16,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  //画像が無い
                                                  return const Icon(
                                                    Icons.account_circle_outlined,
                                                    color: Color(0xFF616161),
                                                    size: 16,
                                                  );
                                                },
                                              )
                                            : const Icon(
                                                Icons.account_circle_outlined,
                                                color: Color(0xFF616161),
                                                size: 16,
                                              ),
                                      ),
                                      SizedBox(width: 4), // アイコンと名前の間の余白
                                      Text(
                                        isMe ? 'あなた' : nickname,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(vertical: 4),
                              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.green[300] : Colors.grey[200],
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
                                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  if (msg['photoId'] != null) ...[
                                    FutureBuilder(
                                      future: fetchPhotoUrl(msg['photoId']),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return SizedBox(width: 200, height: 200); // プレースホルダー
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (_) => Dialog(
                                                    child: InteractiveViewer(
                                                      child: Image.network(snapshot.data!),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Image.network(
                                                snapshot.data!,
                                                width: 200,
                                                height: 200,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
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
                                            if (value == 'report') _reportMessage(msg);
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'report',
                                              child: Text('通報する'),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    timeStr,
                                    style: TextStyle(fontSize: 10),
                                  ),
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
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.memory(_webImageBytes!, width: 120, height: 120, fit: BoxFit.cover)
                          : Image.file(_selectedImage!, width: 120, height: 120, fit: BoxFit.cover),
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
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    )
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
                  icon: _isSending
                      ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
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
