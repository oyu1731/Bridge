import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminAccountDetail extends StatefulWidget {
  final int userId;
  const AdminAccountDetail({required this.userId, super.key});

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
    _loadCommentHistory();
  }

  Future<void> _loadUserData() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}api/users/${widget.userId}/detail'),
    );
    final data = json.decode(utf8.decode(response.bodyBytes));
    setState(() {
      _userData = {
        'id': data['id'],
        'icon': data['icon'] ?? '',
        'name': data['nickname'] ?? '',
        'type': data['type'] ?? 0,
        'accountId': data['id'].toString(),
        'phone': data['phoneNumber'] ?? '',
        'email': data['email'] ?? '',
        'password': '••••••',
        'registeredAt': data['createdAt'] ?? '',
        'reports': data['reportCount'] ?? 0,
        'industry': data['industry'] ?? '',
      };
    });
  }

  Future<void> _loadCommentHistory() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}api/users/${widget.userId}/comments'),
    );
    final List list = json.decode(utf8.decode(res.bodyBytes));
    setState(() {
      _commentHistory = List<Map<String, dynamic>>.from(list);
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
      case 4:
        return '管理者アカウント';
      default:
        return '不明なアカウント';
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
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildUserInfoInner(),
                        const SizedBox(height: 24),
                        const Divider(thickness: 1),
                        const SizedBox(height: 24),
                        _buildCommentHistoryTable(),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // ====== ユーザー情報(中身は完全そのまま) ======
  Widget _buildUserInfoInner() {
    String industryLabel =
        _userData!['type'] == 1
            ? '希望業界'
            : _userData!['type'] == 2
            ? '所属業界'
            : _userData!['type'] == 3
            ? '企業所属業界'
            : '';

    String _buildIconUrl(String path) {
      if (path.startsWith('http')) return path;
      return '${ApiConfig.baseUrl}$path';
    }

    final icon = _userData!['icon'];

    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage:
                  icon != null && icon.isNotEmpty
                      ? NetworkImage(_buildIconUrl(icon))
                      : null,
              child:
                  icon == null || icon.isEmpty
                      ? const Icon(Icons.person, size: 40)
                      : null,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_userData!['name']} <${_getAccountTypeLabel(_userData!['type'])}>',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'アカウントID: ${_userData!['accountId']}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const Spacer(), // ← 右端へ押し出す
            // ===== 削除ボタン =====
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                bool ok = await showDialog(
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

                if (!ok) return;

                await http.put(
                  Uri.parse(
                    '${ApiConfig.baseUrl}/api/users/${widget.userId}/delete',
                  ),
                );

                Navigator.pop(context, true); // 一覧へ戻す
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  _buildInfoRow('電話番号', _userData!['phone']),
                  _buildInfoRow('メールアドレス', _userData!['email']),
                  _buildInfoRow('パスワード', _userData!['password']),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildInfoRow(
                    '登録日',
                    _userData!['registeredAt'].split('T')[0],
                  ),
                  _buildInfoRow('通報回数', _userData!['reports'].toString()),
                  _buildInfoRow(industryLabel, _userData!['industry']),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(l, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(v)),
      ],
    ),
  );

  // ====== コメント履歴 ======
  Widget _buildCommentHistoryTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('コメント履歴'),
        const SizedBox(height: 12),

        if (_commentHistory.isEmpty)
          const Text('コメント履歴はありません')
        else
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3), // スレッド名 30%
              1: FlexColumnWidth(4.5), // コメント 50%
              2: FlexColumnWidth(2.5), // 日付 20%
            },
            border: TableBorder.all(color: Colors.grey.shade400),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // ===== ヘッダー =====
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade200),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: Text('スレッド名')),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: Text('コメント')),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Center(child: Text('日付')),
                  ),
                ],
              ),

              // ===== データ行 =====
              ..._commentHistory.map(
                (c) => TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(c['threadTitle'] ?? '', softWrap: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child:
                          c['isDeleted'] == true
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c['content'] ?? '', softWrap: true),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '削除済み',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              )
                              : Text(c['content'] ?? '', softWrap: true),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(c['createdAt'].split('T')[0]),
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }
}
