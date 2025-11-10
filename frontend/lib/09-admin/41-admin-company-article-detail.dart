import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminCompanyArticleDetail extends StatefulWidget {
  @override
  _AdminCompanyArticleDetailState createState() => _AdminCompanyArticleDetailState();
}

class _AdminCompanyArticleDetailState extends State<AdminCompanyArticleDetail> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;

  // ダミーデータ
  final List<Map<String, dynamic>> _users = [
    {
      'icon': 'A',
      'name': '山田太郎',
      'type': '学生',
      'reports': 0,
    },
    {
      'icon': 'B',
      'name': '佐藤花子',
      'type': '社会人',
      'reports': 2,
    },
    {
      'icon': 'C',
      'name': '株式会社テック',
      'type': '企業',
      'reports': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildSearchCard(), // 別メソッドに切り出し
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
          // 上段タイトル
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

          // 下段：検索バー＋タイプ＋検索ボタン
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
                    decoration: InputDecoration(
                      hintText: 'アカウント名で検索',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
}
