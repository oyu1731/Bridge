import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminMailList extends StatefulWidget {
  @override
  _AdminMailListState createState() => _AdminMailListState();
}

class _AdminMailListState extends State<AdminMailList> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedTarget;
  String? _selectedCategory;
  DateTime? _selectedDate;

  final List<Map<String, dynamic>> _notices = [
    {
      'id': '001',
      'title': 'メンテナンスのお知らせ',
      'target': '学生',
      'category': '運営情報',
      'date': '2025-11-12'
    },
    {
      'id': '002',
      'title': '新機能リリース',
      'target': '企業',
      'category': '重要',
      'date': '2025-11-15'
    },
  ];

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _deleteNotice(int index) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このお知らせを削除しますか？'),
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
        _notices.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSearchCard(),
            const SizedBox(height: 24),
            _buildNoticeTable(),
          ],
        ),
      ),
    );
  }

  // 🔍 検索フォーム部分
  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text('お知らせ検索',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),

          // 一段目：タイトル検索
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'タイトルで検索',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
          const SizedBox(height: 16),

          // 二段目：宛先・カテゴリ・送信日＋検索ボタン
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedTarget,
                  decoration: const InputDecoration(
                    labelText: '宛先',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: '学生', child: Text('学生')),
                    DropdownMenuItem(value: '社会人', child: Text('社会人')),
                    DropdownMenuItem(value: '企業', child: Text('企業')),
                    DropdownMenuItem(value: '個人', child: Text('個人')),
                  ],
                  onChanged: (value) => setState(() => _selectedTarget = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'カテゴリ',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: '運営情報', child: Text('運営情報')),
                    DropdownMenuItem(value: '重要', child: Text('重要')),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _pickDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: '送信日',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        suffixIcon: const Icon(Icons.calendar_today),
                        hintText: _selectedDate != null
                            ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
                            : '未選択',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  print('検索: ${_searchController.text}');
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                child: const Text('検索'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 📋 お知らせ一覧テーブル
  Widget _buildNoticeTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
          2: FlexColumnWidth(),
          3: FlexColumnWidth(),
          4: FixedColumnWidth(40), // ゴミ箱を右端に配置
        },
        border: TableBorder.symmetric(
            inside: BorderSide(color: Colors.grey.shade300)),
        children: [
          // ヘッダー行
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('タイトル',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('宛先',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('カテゴリ',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('送信日',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              SizedBox(), // 右端のゴミ箱列（ヘッダー空白）
            ],
          ),

          // データ行
          for (int i = 0; i < _notices.length; i++)
            TableRow(
              decoration: const BoxDecoration(color: Colors.white),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_notices[i]['title']),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_notices[i]['target']),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_notices[i]['category']),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_notices[i]['date']),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black),
                  onPressed: () => _deleteNotice(i),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
