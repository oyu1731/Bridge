import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/05-notice/45-admin-mail-send.dart';
import 'admin_mail_api.dart';

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
      category:
          json['category'] != null ? int.parse(json['category'].toString()) : 1,
      sendFlag:
          json['sendFlag'] != null ? DateTime.parse(json['sendFlag']) : null,
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
  bool _isSearched = false; // ★追加

  Future<void> _fetchNotifications() async {
    try {
      final list = await AdminNotificationApi.fetchAll();
      setState(() {
        _notifications = list;
        _loading = false;
        _isSearched = false;
      });
    } catch (e) {
      print('Error fetching notices: $e');
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
    try {
      final results = await AdminNotificationApi.search(
        title: _searchController.text,
        type: _selectedTarget,
        category: _selectedCategory == null
            ? null
            : (_selectedCategory == '運営情報' ? '1' : '2'),
        sendDate: _selectedDate,
      );

      setState(() {
        _notifications = results;
        _isSearched = true;
      });
    } catch (e) {
      print('検索エラー: $e');
    }
  }

  Future<void> _clearSearch() async {
    setState(() {
      _searchController.clear();
      _selectedTarget = null;
      _selectedCategory = null;
      _selectedDate = null;
      _loading = true;
      _isSearched = false;
    });

    await _fetchNotifications();
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
      await AdminNotificationApi.delete(notification.id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールを削除しました')),
      );

      _fetchNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除に失敗しました')),
      );
    }
  }

  void _showNotificationDetail(
    BuildContext context,
    NotificationData notification,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Text(
            notification.content,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
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

  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'タイトルで検索',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTargetDropdown()),
              const SizedBox(width: 8),
              Expanded(child: _buildCategoryDropdown()),
              const SizedBox(width: 8),
              Expanded(child: _buildDateField()),
              const SizedBox(width: 8),
              _buildSearchButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: _searchNotifications,
          child: const Text('検索'),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: _clearSearch,
          child: const Text('クリア'),
        ),
      ],
    );
  }

  Widget _buildSendMailButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          label: const Text('メール送信'),
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminMailSend()),
            );
            if (result == true) {
              _fetchNotifications();
            }
          },
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
                ? "${_selectedDate!.year}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.day.toString().padLeft(2, '0')}"
                : '',
          ),
        ),
      ),
    );
  }

  Widget _buildNoticeTable() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Text(
          _isSearched ? 'お知らせがありません' : 'データがありません',
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          4: FixedColumnWidth(40),
        },
        children: [
          for (final n in _notifications)
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: InkWell(
                    onTap: () => _showNotificationDetail(context, n),
                    child: Text(
                      n.title,
                      style: const TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_convertType(n.type)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_convertCategory(n.category)),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    n.sendFlag != null
                        ? "${n.sendFlag!.year}/${n.sendFlag!.month.toString().padLeft(2, '0')}/${n.sendFlag!.day.toString().padLeft(2, '0')}"
                        : '-',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteNotification(n),
                ),
              ],
            ),
        ],
      ),
    );
  }
}