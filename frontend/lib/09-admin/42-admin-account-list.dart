import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '43-admin-account-detail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAccountList extends StatefulWidget {
  @override
  _AdminAccountListState createState() => _AdminAccountListState();
}

class _AdminAccountListState extends State<AdminAccountList> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedType;

  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users/list'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _users = data.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '取得失敗: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '通信エラー: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers() async {
    final keyword = _searchController.text;
    final type = _selectedType ?? '';
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/users/search?keyword=${Uri.encodeComponent(keyword)}&type=$type',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _users = data.map((e) => e as Map<String, dynamic>).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '検索失敗: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '通信エラー: $e';
        _isLoading = false;
      });
    }
  }

  void _deleteUser(int index) async {
    final userId = _users[index]['id'];

    bool confirm = await showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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

    if (!confirm) return;

    await http.put(Uri.parse('${ApiConfig.baseUrl}/api/users/$userId/delete'));

    _fetchUsers();
  }

  String _getTypeLabel(int type) {
    switch (type) {
      case 1:
        return '学生';
      case 2:
        return '社会人';
      case 3:
        return '企業';
      default:
        return '管理者';
    }
  }

  String _buildIconUrl(String path) {
    if (path.startsWith('http')) return path;
    return 'http://localhost:8080$path';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildSearchCard(),
                    const SizedBox(height: 24),
                    _buildUserCards(),
                  ],
                ),
              ),
    );
  }

  /// 🔽 ここが修正ポイント
  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'アカウント検索',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),

          /// Wrapで自動改行
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width:
                        constraints.maxWidth >= 600
                            ? constraints.maxWidth * 0.45
                            : constraints.maxWidth,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'アカウント名で検索',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width:
                        constraints.maxWidth >= 600
                            ? constraints.maxWidth * 0.3
                            : constraints.maxWidth,
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'アカウントタイプ',
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('学生')),
                        DropdownMenuItem(value: '2', child: Text('社会人')),
                        DropdownMenuItem(value: '3', child: Text('企業')),
                      ],
                      onChanged:
                          (value) => setState(() => _selectedType = value),
                    ),
                  ),
                  SizedBox(
                    width:
                        constraints.maxWidth >= 600
                            ? 120
                            : constraints.maxWidth,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _searchUsers,
                      child: const Text('検索'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserCards() {
    return Column(
      children:
          _users.map((user) {
            final photoPath = user['photoPath'];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage:
                        photoPath != null && photoPath.isNotEmpty
                            ? NetworkImage(_buildIconUrl(photoPath))
                            : null,
                    child:
                        photoPath == null || photoPath.isEmpty
                            ? const Icon(Icons.person, size: 30)
                            : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        AdminAccountDetail(userId: user['id']),
                              ),
                            );
                            if (result == true) {
                              _fetchUsers();
                            }
                          },
                          child: Text(
                            user['nickname'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getTypeLabel(int.tryParse('${user['type']}') ?? 0),
                        ),
                        const SizedBox(height: 2),
                        Text('通報回数: ${user['reportCount'] ?? 0}'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteUser(_users.indexOf(user)),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
