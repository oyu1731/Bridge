import 'package:bridge/06-company/api_config.dart';
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
    _fetchUsers(); // 画面開いた瞬間に初期表示
  }

  // 初期表示: 上位30件
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // final response = await http.get(Uri.parse('http://localhost:8080/api/users?limit=30'));
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/users?limit=30'),
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

  // 検索ボタン押下時
  Future<void> _searchUsers() async {
    final keyword = _searchController.text;
    final type = _selectedType ?? '';
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final url = Uri.parse(
        // 'http://localhost:8080/api/users/search?keyword=$keyword&type=$type');
        '${ApiConfig.baseUrl}/api/users/search?keyword=$keyword&type=$type',
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

    if (confirm) {
      // 削除処理はバックエンド側にAPIを呼び出すこと
      setState(() {
        _users.removeAt(index);
      });
    }
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
        return '不明';
    }
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
                physics: const BouncingScrollPhysics(),
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
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
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
                    _searchUsers();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
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

  Widget _buildUserCards() {
    return Column(
      children:
          _users.map((user) {
            return Container(
              width: double.infinity,
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
                  CircleAvatar(radius: 30, child: Text(user['icon'] ?? '?')),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AdminAccountDetail(userId: user['id']),
                              ),
                            );
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
                        Text(_getTypeLabel(user['type'] ?? 0)),
                        const SizedBox(height: 2),
                        Text('通報回数: ${user['reportCount'] ?? 0}'),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.black),
                    onPressed: () {
                      _deleteUser(_users.indexOf(user));
                    },
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
