import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/05-notice/45-admin-mail-send.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Notification モデル
class NotificationData {
  final int id;
  final String title;
  final String content;
  final int type;
  final int category;
  final DateTime? sendFlag;

  NotificationData({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.category,
    required this.sendFlag,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      id: json['id'],
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type'] != null ? int.parse(json['type'].toString()) : 7,
      category: json['category'] != null ? int.parse(json['category'].toString()) : 1,
      sendFlag: json['sendFlag'] != null ? DateTime.parse(json['sendFlag']) : null,
    );
  }
}

String _convertType(int value) {
  switch (value) {
    case 1:
      return '学生';
    case 2:
      return '社会人';
    case 3:
      return '企業';
    case 4:
      return '学生×社会人';
    case 5:
      return '学生×企業';
    case 6:
      return '社会人×企業';
    case 7:
      return '全員';
    case 8:
      return '個人';
    default:
      return '-';
  }
}

String _convertCategory(int value) {
  switch (value) {
    case 1:
      return '運営情報';
    case 2:
      return '重要';
    default:
      return '-';
  }
}

class AdminMailList extends StatefulWidget {
  @override
  _AdminMailListState createState() => _AdminMailListState();
}

class _AdminMailListState extends State<AdminMailList> {
  final TextEditingController _searchController = TextEditingController();

  String? _selectedTarget;
  String? _selectedCategory;
  DateTime? _selectedDate;

  List<NotificationData> _notifications = [];
  bool _loading = true;

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(
        Uri.parse("http://localhost:8080/api/notifications"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _notifications = data.map((e) => NotificationData.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        throw Exception("Fail: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching notices: $e");
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

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

  Future<void> _searchNotifications() async {
    // 送信するパラメータをMapにまとめる
    Map<String, String> params = {};

    if (_searchController.text.isNotEmpty) {
      params['title'] = _searchController.text;
    }
    if (_selectedTarget != null) {
      params['type'] = _selectedTarget!;
    }
    if (_selectedCategory != null) {
      params['category'] = _selectedCategory == '運営情報' ? '1' : '2';
    }
    if (_selectedDate != null) {
      params['sendFlag'] =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2,'0')}-${_selectedDate!.day.toString().padLeft(2,'0')}";
    }

    final uri =
        Uri.http('localhost:8080', '/api/notifications/search', params);

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<NotificationData> results =
            data.map((e) => NotificationData.fromJson(e)).toList();

        // 日付指定がある場合は、念のためフロントでも絞り込み
        if (_selectedDate != null) {
          results = results.where((n) =>
              n.sendFlag != null &&
              n.sendFlag!.year == _selectedDate!.year &&
              n.sendFlag!.month == _selectedDate!.month &&
              n.sendFlag!.day == _selectedDate!.day).toList();
        }

        setState(() {
          _notifications = results;
        });
      } else {
        print('検索失敗: ${response.statusCode}');
      }
    } catch (e) {
      print('検索エラー: $e');
    }
  }

  Future<void> _deleteNotification(NotificationData notification) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('このメールを削除しますか？'),
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

    if (confirm != true) return;

    try {
      final response = await http.delete(
        Uri.parse(
          'http://localhost:8080/api/notifications/${notification.id}',
        ),
      );

      if (response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メールを削除しました'),
            duration: Duration(seconds: 2),
          ),
        );
        
        _fetchNotifications(); // 再取得
      } else {
        throw Exception('削除失敗: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました')),
      );
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
            _buildSendMailButton(),
            const SizedBox(height: 12),
            _buildNoticeTable(),
          ],
        ),
      ),
    );
  }

  // 🔍 検索フォーム（レスポンシブ修正版）
  Widget _buildSearchCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

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
                child: Text(
                  'お知らせ検索',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              // タイトル検索（未変更）
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'タイトルで検索',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 16),

              if (!isMobile)
                // ===== 横幅が広いとき：1行 =====
                Row(
                  children: [
                    Expanded(child: _buildTargetDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryDropdown()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDateField()),
                    const SizedBox(width: 12),
                    _buildSearchButton(),
                  ],
                )
              else
                // ===== スマホ：2行 =====
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildTargetDropdown()),
                        const SizedBox(width: 12),
                        Expanded(child: _buildCategoryDropdown()),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildDateField()),
                        const SizedBox(width: 12),
                        _buildSearchButton(),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSendMailButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          label: const Text('メール送信'),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AdminMailSend()));
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTarget,
      decoration: const InputDecoration(
        labelText: '宛先',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: '1', child: Text('学生')),
        DropdownMenuItem(value: '2', child: Text('社会人')),
        DropdownMenuItem(value: '3', child: Text('企業')),
        DropdownMenuItem(value: '4', child: Text('学生×社会人')),
        DropdownMenuItem(value: '5', child: Text('学生×企業')),
        DropdownMenuItem(value: '6', child: Text('社会人×企業')),
        DropdownMenuItem(value: '7', child: Text('全員')),
        DropdownMenuItem(value: '8', child: Text('個人')),
      ],
      onChanged: (value) => setState(() => _selectedTarget = value),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'カテゴリ',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: const [
        DropdownMenuItem(value: '運営情報', child: Text('運営情報')),
        DropdownMenuItem(value: '重要', child: Text('重要')),
      ],
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _pickDate(context),
      child: AbsorbPointer(
        child: TextFormField(
          decoration: const InputDecoration(
            labelText: '送信日',
            border: OutlineInputBorder(),
            isDense: true,
            suffixIcon: Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: _selectedDate != null
                ? "${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2,'0')}/${_selectedDate!.day.toString().padLeft(2,'0')}"
                : '',
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return ElevatedButton(
      onPressed: _searchNotifications,
      child: const Text('検索'),
    );
  }

  // 以下、一覧テーブル部分は
  Widget _buildNoticeTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_notifications.isEmpty) {
      return const Center(child: Text('お知らせはありません'));
    }

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
          4: FixedColumnWidth(40),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.grey.shade300),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.grey.shade200),
            children: const [
              Padding(padding: EdgeInsets.all(8), child: Text('タイトル', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('宛先', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('カテゴリ', style: TextStyle(fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(8), child: Text('送信日', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(),
            ],
          ),
          for (final n in _notifications)
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(n.title,style: const TextStyle(decoration: TextDecoration.underline)),
              ),
              Padding(padding: const EdgeInsets.all(8), child: Text(_convertType(n.type))),
              Padding(padding: const EdgeInsets.all(8), child: Text(_convertCategory(n.category))),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(n.sendFlag != null
                    ? "${n.sendFlag!.year}/${n.sendFlag!.month.toString().padLeft(2,'0')}/${n.sendFlag!.day.toString().padLeft(2,'0')}"
                    : "-"),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteNotification(n),
              ),
            ])
        ],
      ),
    );
  }
}
