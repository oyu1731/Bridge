import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '43-admin-account-detail.dart';

class AdminAccountList extends StatefulWidget {
  @override
  _AdminAccountListState createState() => _AdminAccountListState();
}

class _AdminAccountListState extends State<AdminAccountList> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;

  // ダミーデータ
  final List<Map<String, dynamic>> _users = [
    {
      'id': '001',
      'name': '山田太郎',
      'type': '学生',
      'reports': 0,
      'icon': 'A',
    },
    {
      'id': '002',
      'name': '佐藤花子',
      'type': '社会人',
      'reports': 2,
      'icon': 'B',
    },
    {
      'id': '003',
      'name': '株式会社テック',
      'type': '企業',
      'reports': 1,
      'icon': 'C',
    },
  ];

  // 削除確認
  void _deleteUser(int index) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このアカウントを削除しますか？'),
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

    if (confirm) {
      setState(() {
        _users.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildSearchCard(),
              const SizedBox(height: 24),
              _buildUserTable(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'アカウント検索',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'アカウント名で検索',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'アカウントタイプ',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('学生')),
                      DropdownMenuItem(value: '2', child: Text('社会人')),
                      DropdownMenuItem(value: '3', child: Text('企業')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    print('検索: ${_searchController.text}, type=$_selectedType');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('検索'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: List.generate(_users.length, (index) {
          final user = _users[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DataTable(
                columns: const [
                  DataColumn(label: SizedBox.shrink()),
                  DataColumn(label: Text('アカウント名')),
                  DataColumn(label: Text('アカウントタイプ')),
                  DataColumn(label: Text('通報回数')),
                ],
                rows: [
                  DataRow(cells: [
                    DataCell(CircleAvatar(child: Text(user['icon']))),
                    DataCell(
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminAccountDetail(
                                userId: user['id'],
                              ),
                            ),
                          );
                        },
                        child: Text(
                          user['name'],
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(user['type'])),
                    DataCell(Text(user['reports'].toString())),
                  ]),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.black),
                onPressed: () => _deleteUser(index),
              ),
            ],
          );
        }),
      ),
    );
  }
}
