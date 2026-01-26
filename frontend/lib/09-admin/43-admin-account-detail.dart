import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminAccountDetail extends StatefulWidget {
  final int userId;
  const AdminAccountDetail({required this.userId, super.key});

  @override
  _AdminAccountDetailState createState() => _AdminAccountDetailState();
}

class _AdminAccountDetailState extends State<AdminAccountDetail> {
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _commentHistory = [];

  // ダミーデータ（本来はバックエンドから取得）
  final List<Map<String, dynamic>> _dummyUsers = [
    {
      'id': '001',
      'icon': 'A',
      'name': '山田太郎',
      'type': 1,
      'accountId': '001',
      'phone': '090-1111-2222',
      'email': 'taro@example.com',
      'password': '••••••',
      'registeredAt': '2024-12-01',
      'reports': 2,
      'industry': 'IT業界（希望）',
      'comments': [
        {
          'thread': 'キャリア相談スレッド',
          'comment': 'IT業界に興味があります！',
          'date': '2025-10-20',
        },
        {'thread': '自己紹介スレッド', 'comment': 'よろしくお願いします！', 'date': '2025-10-01'},
      ],
    },
    {
      'id': '002',
      'icon': 'B',
      'name': '佐藤花子',
      'type': 2,
      'accountId': '002',
      'phone': '080-2222-3333',
      'email': 'hanako@example.com',
      'password': '••••••',
      'registeredAt': '2025-01-15',
      'reports': 1,
      'industry': '教育業界（希望）',
      'comments': [
        {
          'thread': '勉強スレッド',
          'comment': '最近Pythonを学習しています。',
          'date': '2025-09-10',
        },
      ],
    },
    {
      'id': '003',
      'icon': 'C',
      'name': '株式会社テック',
      'type': 3,
      'accountId': '003',
      'phone': '03-5555-6666',
      'email': 'tech@example.com',
      'password': '••••••',
      'registeredAt': '2023-11-20',
      'reports': 0,
      'industry': 'IT企業',
      'comments': [],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // 疑似通信
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _dummyUsers.firstWhere(
      (u) => u['id'] == widget.userId,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      setState(() {
        _userData = user;
        _commentHistory = List<Map<String, dynamic>>.from(
          user['comments'] ?? [],
        );
      });
    }
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
      body:
          _userData == null
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                  CircleAvatar(radius: 40, child: Text(_userData!['icon'])),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_userData!['name']} <${_getAccountTypeLabel(_userData!['type'])}>',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text(
                            'アカウントID: ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(_userData!['accountId']),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
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
                        _buildInfoRow('通報回数', _userData!['reports'].toString()),
                        _buildInfoRow('業界', _userData!['industry']),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.delete, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('削除確認'),
                      content: const Text('このアカウント情報を削除しますか？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                            // TODO: バック側で削除処理
                          },
                          child: const Text('削除'),
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
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

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
          LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: 300,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: constraints.maxWidth,
                        ),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('スレッド名')),
                            DataColumn(label: Text('コメント')),
                            DataColumn(label: Text('日付')),
                          ],
                          rows:
                              _commentHistory
                                  .map(
                                    (comment) => DataRow(
                                      cells: [
                                        DataCell(Text(comment['thread'])),
                                        DataCell(Text(comment['comment'])),
                                        DataCell(Text(comment['date'])),
                                      ],
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
