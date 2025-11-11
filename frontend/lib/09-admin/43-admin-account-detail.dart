import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminAccountDetail extends StatefulWidget {
  final String userId;

  const AdminAccountDetail({Key? key, required this.userId}) : super(key: key);

  @override
  _AdminAccountDetailState createState() => _AdminAccountDetailState();
}

class _AdminAccountDetailState extends State<AdminAccountDetail> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _commentHistory = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // バック処理を仮定したダミーデータ
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _userData = {
        'icon': 'A', // 本来は写真テーブルから取得
        'name': '山田太郎',
        'type': 1,
        'accountId': '001',
        'phone': '090-1111-2222',
        'email': 'taro@example.com',
        'password': '••••••',
        'registeredAt': '2024-12-01',
        'reports': 2,
        'industry': 'IT業界（希望）',
      };

      _commentHistory = [
        {
          'thread': 'キャリア相談スレッド',
          'comment': 'IT業界に興味があります！',
          'date': '2025-10-20',
        },
        {
          'thread': '自己紹介スレッド',
          'comment': 'よろしくお願いします！',
          'date': '2025-10-01',
        },
      ];
    });
  }

  String _getAccountTypeLabel(int type) {
    switch (type) {
      case 1:
        return '学生アカウント';
      case 2:
        return '社会人アカウント';
      case 3:
        return '企業アカウント';
      default:
        return '不明';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoCard(),
                  const SizedBox(height: 32),
                  _buildCommentHistoryTable(),
                ],
              ),
            ),
    );
  }

  // 上部：ユーザー情報カード（右上に削除ボタン）
  Widget _buildUserInfoCard() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 上段（アイコン＋基本情報）
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左：アイコン
                  CircleAvatar(
                    radius: 40,
                    child: Text(_userData!['icon']), // 実際は画像
                  ),
                  const SizedBox(width: 16),
                  // 右：アカウント名・タイプ・ID
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'admin<${_getAccountTypeLabel(_userData!['type'])}>',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userData!['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('アカウントID: ',
                              style: TextStyle(color: Colors.grey)),
                          Text(_userData!['accountId']),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              // 下段（左右2カラム情報）
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('電話番号', _userData!['phone']),
                        _buildInfoRow('メールアドレス', _userData!['email']),
                        _buildInfoRow('パスワード', _userData!['password']),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow('登録日', _userData!['registeredAt']),
                        _buildInfoRow(
                            '通報回数', _userData!['reports'].toString()),
                        _buildInfoRow('業界', _userData!['industry']),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 右上に削除ボタン
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: Icon(Icons.delete, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text('削除確認'),
                  content: Text('このアカウント情報を削除しますか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, true);
                        // TODO: 削除処理はバック側で実装
                      },
                      child: Text('削除'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'アカウント削除',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // 下部：コメント履歴テーブル
  Widget _buildCommentHistoryTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'コメント履歴',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: 300, // スクロールできる高さ
            child: Scrollbar(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('スレッド名')),
                    DataColumn(label: Text('コメント')),
                    DataColumn(label: Text('日付')),
                  ],
                  rows: _commentHistory
                      .map(
                        (comment) => DataRow(cells: [
                          DataCell(Text(comment['thread'])),
                          DataCell(Text(comment['comment'])),
                          DataCell(Text(comment['date'])),
                        ]),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
