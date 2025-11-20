import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:bridge/11-common/58-header.dart';

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
final String currentUserId = '1';

List<Map<String, dynamic>> _messages = [];
String searchText = '';
bool _isSending = false;

late final StreamController<List<Map<String, dynamic>>> _messageStreamController;
late final WebSocketChannel _channel;

final String baseUrl = 'http://localhost:8080/api';

@override
void initState() {
super.initState();
_messageStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
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
      });  

      _messages.sort((a, b) =>  
          DateTime.parse(a['created_at'])  
              .compareTo(DateTime.parse(b['created_at'])));  

      _messageStreamController.add(List.from(_messages));  
      _scrollToBottom();  
    }  
  } catch (e) {  
    print('WebSocket parse error: $e');  
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
Uri.parse('$baseUrl/chat/${widget.thread['id']}'));


  if (response.statusCode == 200) {  
    final List<dynamic> data = json.decode(response.body);  
    final List<Map<String, dynamic>> fetched = data.map((msg) {  
      return {  
        'id': msg['id'],  
        'user_id': msg['userId'].toString(),  
        'text': msg['content'],  
        'created_at': msg['createdAt'],  
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
      _messages.sort((a, b) =>  
          DateTime.parse(a['created_at'])  
              .compareTo(DateTime.parse(b['created_at'])));  
      _messageStreamController.add(List.from(_messages));  
      _scrollToBottom();  
    }  
  }  
} catch (e) {  
  print('Error fetching messages: $e');  
}  

}

void _scrollToBottom() {
WidgetsBinding.instance.addPostFrameCallback((_) {
if (_scrollController.hasClients) {
_scrollController.animateTo(
_scrollController.position.maxScrollExtent,
duration: const Duration(milliseconds: 300),
curve: Curves.easeOut,
);
}
});
}

Future<void> _sendMessage() async {
if (_isSending) return;
final text = _messageController.text.trim();
if (text.isEmpty) return;


setState(() => _isSending = true);  

final payload = {  
  'userId': int.parse(currentUserId),  
  'content': text,  
  'threadId': widget.thread['id'],  
};  

try {  
  final response = await http.post(  
    Uri.parse('$baseUrl/chat/${widget.thread['id']}'),  
    headers: {'Content-Type': 'application/json'},  
    body: json.encode(payload),  
  );  

  if (response.statusCode == 200 || response.statusCode == 201) {  
    final msg = json.decode(response.body);  

    final newMessage = {  
      'id': msg['id'],  
      'user_id': msg['userId'].toString(),  
      'text': msg['content'],  
      'created_at': msg['createdAt'],  
    };  

    _messages.add(newMessage);  
    _messages.sort((a, b) =>  
        DateTime.parse(a['created_at'])  
            .compareTo(DateTime.parse(b['created_at'])));  
    _messageStreamController.add(List.from(_messages));  
    _scrollToBottom();  

    _channel.sink.add(json.encode(msg));  

    _messageController.clear();  
  } else {  
    print('Failed to send message: ${response.statusCode}');  
  }  
} catch (e) {  
  print('Error sending message: $e');  
} finally {  
  setState(() => _isSending = false);  
}  


}

Future<void> _reportMessage(int chatId, String toUserId) async {
final payload = {
'fromUserId': int.parse(currentUserId),
'toUserId': int.parse(toUserId),
'type': 2, // メッセージ通報
'chatId': chatId,
};

//通報部分
try {  
  final response = await http.post(  
    Uri.parse('$baseUrl/notice/report'),  
    headers: {'Content-Type': 'application/json'},  
    body: json.encode(payload),  
  );  

  if (response.statusCode == 200 || response.statusCode == 201) {  
    ScaffoldMessenger.of(context).showSnackBar(  
      const SnackBar(content: Text('通報しました')),  
    );  
  } else if (response.statusCode == 400) {
    // ★ 重複通報メッセージをそのまま表示
    final msg = response.body; // ← バックエンドからの文字列
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  } else {  
    print('Failed to report: ${response.statusCode}');  
    ScaffoldMessenger.of(context).showSnackBar(  
      const SnackBar(content: Text('通報に失敗しました')),  
    );  
  }  
} catch (e) {  
  print('Error reporting: $e');  
  ScaffoldMessenger.of(context).showSnackBar(  
    const SnackBar(content: Text('通報に失敗しました')),  
  );  
}  


}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: BridgeHeader(),
body: Column(
children: [
// -----------------------
// タイトル + 検索バー
// -----------------------
Padding(
padding: const EdgeInsets.all(12),
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
decoration: const InputDecoration(
hintText: 'コメント検索',
prefixIcon: Icon(Icons.search),
),
onChanged: (value) => setState(() => searchText = value),
),
),
],
),
),
// -----------------------
// メッセージリスト
// -----------------------
Expanded(
child: StreamBuilder<List<Map<String, dynamic>>>(
stream: _messageStreamController.stream,
initialData: _messages,
builder: (context, snapshot) {
final filtered = snapshot.data!
.where((msg) =>
searchText.isEmpty || msg['text'].contains(searchText))
.toList();


            return ListView.builder(  
              controller: _scrollController,  
              itemCount: filtered.length,  
              itemBuilder: (context, index) {  
                final msg = filtered[index];  
                final isMe = msg['user_id'] == currentUserId;  
                final createdAt = DateTime.parse(msg['created_at']);  
                final timeStr =  
                    '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';  

                return Align(  
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,  
                  child: Container(  
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),  
                    padding: const EdgeInsets.all(8),  
                    decoration: BoxDecoration(  
                      color: isMe ? Colors.blue[200] : Colors.grey[300],  
                      borderRadius: BorderRadius.circular(12),  
                    ),  
                    child: Column(  
                      crossAxisAlignment: isMe  
                          ? CrossAxisAlignment.end  
                          : CrossAxisAlignment.start,  
                      children: [  
                        Row(  
                          mainAxisSize: MainAxisSize.min,  
                          children: [  
                            Flexible(child: Text(msg['text'])),  
                            const SizedBox(width: 4),  
                            if (!isMe)  
                              IconButton(  
                                icon: const Icon(Icons.report, size: 18, color: Colors.red),  
                                onPressed: () => _reportMessage(msg['id'], msg['user_id']),  
                                padding: EdgeInsets.zero,  
                                constraints: const BoxConstraints(),  
                                tooltip: 'このメッセージを通報',  
                              ),  
                          ],  
                        ),  
                        Text(timeStr, style: const TextStyle(fontSize: 10)),  
                      ],  
                    ),  
                  ),  
                );  
              },  
            );  
          },  
        ),  
      ),  
      // -----------------------  
      // メッセージ入力  
      // -----------------------  
      SafeArea(  
        child: Row(  
          children: [  
            Expanded(  
              child: TextField(  
                controller: _messageController,  
                decoration: const InputDecoration(  
                  hintText: 'メッセージを入力',  
                ),  
                onSubmitted: (_) => _sendMessage(),  
              ),  
            ),  
            IconButton(  
              icon: _isSending  
                  ? const CircularProgressIndicator()  
                  : const Icon(Icons.send),  
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
