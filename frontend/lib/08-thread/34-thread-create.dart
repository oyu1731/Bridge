import 'package:bridge/06-company/api_config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bridge/11-common/58-header.dart';

class ThreadCreate extends StatefulWidget {
  @override
  _ThreadCreateState createState() => _ThreadCreateState();
}

class _ThreadCreateState extends State<ThreadCreate> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCondition = '全員';

  // APIから取得した業界リスト
  List<Map<String, dynamic>> _industries = [];
  Map<int, bool> _selectedIndustries = {};

  @override
  void initState() {
    super.initState();
    _fetchIndustries();
  }

  // APIから業界データ取得
  Future<void> _fetchIndustries() async {
    try {
      // final response = await http.get(Uri.parse('http://localhost:8080/api/industries'));
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/industries'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          _industries =
              data
                  .map(
                    (e) => {
                      'id': e['id'],
                      'name': e['industry'], // DBカラム名に合わせる
                    },
                  )
                  .toList();

          _selectedIndustries = {
            for (var item in _industries) item['id'] as int: false,
          };
        });
      } else {
        print('Failed to fetch industries: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching industries: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- スレッド名 ---
            Text(
              'スレッド名',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              maxLength: 40,
              decoration: InputDecoration(
                hintText: 'スレッド名を記入してください',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // --- 説明 ---
            Text(
              '説明',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _descriptionController,
              maxLength: 255,
              maxLines: 7,
              decoration: InputDecoration(
                hintText: '説明を記入してください（任意）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // --- 参加条件 ---
            Text(
              '参加条件',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children:
                  ['全員', '学生', '社会人'].map((label) {
                    return Expanded(
                      child: RadioListTile<String>(
                        title: Text(label),
                        value: label,
                        groupValue: _selectedCondition,
                        onChanged: (value) {
                          setState(() {
                            _selectedCondition = value!;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),

            // --- 業界 ---
            Text(
              '業界',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 0,
              children:
                  _industries.map((industry) {
                    final id = industry['id'] as int;
                    return SizedBox(
                      width: (MediaQuery.of(context).size.width - 40 - 24) / 3,
                      child: CheckboxListTile(
                        title: Text(
                          industry['name'],
                          style: TextStyle(fontSize: 14),
                        ),
                        value: _selectedIndustries[id],
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() {
                            _selectedIndustries[id] = val!;
                          });
                        },
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 30),

            // --- 作成ボタン ---
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _handleCreate,
                child: Text(
                  '作成',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCreate() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final condition = _selectedCondition;

    final selectedIndustryIds =
        _selectedIndustries.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toList();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('スレッド名を記入してください')));
      return;
    }

    final threadData = {
      'title': title,
      'description': description.isNotEmpty ? description : null,
      'condition': condition,
      'industryIds': selectedIndustryIds,
      'userId': 1, // ここに作成者IDを入れる
    };

    try {
      final response = await http.post(
        // Uri.parse('http://localhost:8080/api/threads/unofficial'),
        Uri.parse('${ApiConfig.baseUrl}/api/threads/unofficial'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(threadData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('スレッドの作成が完了しました')));
        // 必要なら画面遷移やリスト更新もここで
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('スレッド作成に失敗しました: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エラーが発生しました: $e')));
    }
  }
}
