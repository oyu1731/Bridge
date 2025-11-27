import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Notification モデル
class NotificationData {
  final int id;
  final String title;
  final String content;
  final int type; // 1=学生, 2=社会人, 3=企業, 4=学生×社会人, 5=学生×企業, 6=社会人×企業, 7=全員, 8=特定のユーザー
  final int category; // 1=運営情報, 2=重要
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
        Uri.parse("http://localhost:8080/api/notifications"), // ←SpringのURL
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

  void _showNoticeDetail(NotificationData notice) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            notice.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notice.content,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Text(
                "【宛先】 ${_convertType(notice.type)}",
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                "【カテゴリ】 ${_convertCategory(notice.category)}",
                style: const TextStyle(color: Colors.grey),
              ),
              Text(
                "【送信日】 ${notice.sendFlag != null 
                  ? "${notice.sendFlag!.year}/${notice.sendFlag!.month.toString().padLeft(2,'0')}/${notice.sendFlag!.day.toString().padLeft(2,'0')}" 
                  : "-"}",
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("閉じる"),
            ),
          ],
        );
      },
    );
  }

  void _deleteNotice(int id) async {
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
      final response = await http.delete(Uri.parse("http://localhost:8080/api/notifications/$id"));

      if (response.statusCode == 204) {
        // 削除後に一覧を更新
        _fetchNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('削除が完了しました'),
            duration: Duration(seconds: 2), // 表示時間
          ),
        );
      } else {
        print('削除失敗: ${response.statusCode}');
      }
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

  // 検索フォーム部分
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        controller: TextEditingController(
                          text: _selectedDate != null
                            ? "${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2,'0')}/${_selectedDate!.day.toString().padLeft(2,'0')}"
                            : '',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  // 送信するパラメータをMapにまとめる
                  Map<String, String> params = {};
                  if (_searchController.text.isNotEmpty) params['title'] = _searchController.text;
                  if (_selectedTarget != null) params['type'] = _selectedTarget!;
                  if (_selectedCategory != null) params['category'] = _selectedCategory == '運営情報' ? '1' : '2';
                  if (_selectedDate != null) params['sendFlag'] = "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2,'0')}-${_selectedDate!.day.toString().padLeft(2,'0')}";

                  final uri = Uri.http('localhost:8080', '/api/notifications/search', params);

                  try {
                    final response = await http.get(uri);
                    if (response.statusCode == 200) {
                      final List<dynamic> data = jsonDecode(response.body);
                      List<NotificationData> results = data.map((e) => NotificationData.fromJson(e)).toList();

                      // 日付指定がある場合は sendFlag != null かつ一致するものだけに絞る
                      if (_selectedDate != null) {
                        results = results.where((n) =>
                            n.sendFlag != null &&
                            n.sendFlag!.year == _selectedDate!.year &&
                            n.sendFlag!.month == _selectedDate!.month &&
                            n.sendFlag!.day == _selectedDate!.day
                        ).toList();
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
                },
                child: const Text('検索'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // お知らせ一覧テーブル
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
          for (int i = 0; i < _notifications.length; i++)
            TableRow(
              decoration: const BoxDecoration(color: Colors.white),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      _showNoticeDetail(_notifications[i]);
                    },
                    child: Text(
                      _notifications[i].title,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_convertType(_notifications[i].type)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(_convertCategory(_notifications[i].category)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _notifications[i].sendFlag != null
                      ? "${_notifications[i].sendFlag!.year}/${_notifications[i].sendFlag!.month.toString().padLeft(2,'0')}/${_notifications[i].sendFlag!.day.toString().padLeft(2,'0')}"
                      : "-",
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.black),
                  onPressed: () => _deleteNotice(_notifications[i].id),
                ),
              ],
            ),
        ],
      ),
    );
  }
}