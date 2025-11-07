import 'package:flutter/material.dart';
/*
リアルタイムチャットに必要な Firestore パッケージの導入がまだのため、
Firebase 関連の import やリアルタイムチャット用のコードはコメントアウトしています。
*/
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bridge/11-common/58-header.dart';
import '31-thread-list.dart'; // Thread モデルをインポート

class ThreadOfficialDetail extends StatefulWidget {
  final Thread thread;

  const ThreadOfficialDetail({required this.thread});

  @override
  _ThreadOfficialDetailState createState() => _ThreadOfficialDetailState();
}

class _ThreadOfficialDetailState extends State<ThreadOfficialDetail> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String currentUserId = 'user_001'; // 仮ユーザー

  String searchText = ''; // 検索文字列

  // Firestore上でスレッドごとのコメントをリアルタイム取得
  /*
  Stream<QuerySnapshot> _messageStream() {
    return FirebaseFirestore.instance
        .collection('chatCollection')
        .where('thread_id', isEqualTo: widget.thread['id'])
        .orderBy('created_at', descending: false)
        .snapshots();
  }

  // コメント送信（Firestoreに追加）
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance.collection('chatCollection').add({
      'thread_id': widget.thread['id'],
      'user_id': currentUserId,
      'text': text,
      'created_at': Timestamp.now(),
    });

    _messageController.clear();
  }
  */

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
                    widget.thread.title,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'コメント検索',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 0),
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

          Divider(height: 1),

          // コメント一覧（リアルタイム取得＋検索）
          /*
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messageStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                // Firestoreのドキュメントを取得
                final docs = snapshot.data!.docs;

                // 検索文字列で絞り込み
                final filteredDocs = docs.where((doc) {
                  final text = (doc['text'] ?? '').toString();
                  return searchText.isEmpty ||
                      text.contains(searchText); // 部分一致
                }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(12),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final data =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final isMe = data['user_id'] == currentUserId;

                    // Firestoreのtimestampを時刻文字列に変換
                    final createdAt = (data['created_at'] as Timestamp).toDate();
                    final timeString =
                        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
                    final dateString =
                        '${createdAt.year}年${createdAt.month}月${createdAt.day}日';

                    return Column(
                      children: [
                        if (index == 0 ||
                            dateString !=
                                ((filteredDocs[index - 1].data()
                                        as Map<String, dynamic>)['created_at']
                                    as Timestamp)
                                    .toDate()
                                    .toString())
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: Text(dateString,
                                  style: TextStyle(fontSize: 13)),
                            ),
                          ),
                        Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe)
                                CircleAvatar(
                                  backgroundImage:
                                      AssetImage('assets/user_icon1.png'),
                                  radius: 18,
                                ),
                              if (!isMe) SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(data['user_id'],
                                        style: TextStyle(fontSize: 12)),
                                    Container(
                                      margin:
                                          EdgeInsets.symmetric(vertical: 4),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        border: Border.all(width: 1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(data['text'],
                                          style: TextStyle(fontSize: 15)),
                                    ),
                                    Text(timeString,
                                        style: TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (isMe) SizedBox(width: 8),
                              if (isMe)
                                CircleAvatar(
                                  backgroundImage:
                                      AssetImage('assets/user_icon2.png'),
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
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add),
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
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
          */
        ],
      ),
    );
  }
}
