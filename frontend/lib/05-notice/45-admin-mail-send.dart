import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminMailSend extends StatefulWidget {
  @override
  _AdminMailSendState createState() => _AdminMailSendState();
}

class _AdminMailSendState extends State<AdminMailSend> {
  final Map<String, bool> _selectedTypes = {
    '学生': false,
    '社会人': false,
    '企業': false,
    '個人': false,
  };

  final TextEditingController _specificUserIdController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String? _selectedCategory;
  final Map<String, int> _categories = {
    '運営情報': 1,
    '重要': 2,
  };

  String _selectedTimeOption = '即時';
  DateTime? _selectedDate;
  String? _selectedHour;
  final List<String> _hours =
      List.generate(24, (index) => index.toString().padLeft(2, '0') + ':00');

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  int? _determineType() {
    final student = _selectedTypes['学生'] ?? false;
    final worker = _selectedTypes['社会人'] ?? false;
    final company = _selectedTypes['企業'] ?? false;
    final individual = _selectedTypes['個人'] ?? false;

    if (individual && !student && !worker && !company) return 8;
    if (student && worker && !company && !individual) return 4;
    if (student && company && !worker && !individual) return 5;
    if (worker && company && !student && !individual) return 6;
    if (student && worker && company && !individual) return 7;
    if (student && !worker && !company && !individual) return 1;
    if (worker && !student && !company && !individual) return 2;
    if (company && !student && !worker && !individual) return 3;

    return null;
  }

  void _clearForm() {
    setState(() {
      _selectedTypes.updateAll((key, value) => false);
      _specificUserIdController.clear();
      _subjectController.clear();
      _contentController.clear();
      _selectedTimeOption = '即時';
      _selectedDate = null;
      _selectedHour = null;
    });
  }

  Future<void> _sendNotification() async {
    final type = _determineType();
    if (type == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('宛先を正しく選択してください')),
      );
      return;
    }

    final userId = (type == 8) ? int.tryParse(_specificUserIdController.text) : null;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('カテゴリを選択してください')),
      );
      return;
    }


    // 個人宛チェック
    if (type == 8) {
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('個人宛の場合はユーザーIDを入力してください')),
        );
        return;
      }
      if (_selectedTypes['学生']! || _selectedTypes['社会人']! || _selectedTypes['企業']!) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('個人宛の場合は他の宛先を選択できません')),
        );
        return;
      }
    }

    // 送信時間チェック
    if (_selectedTimeOption == '予約') {
      if (_selectedDate == null || _selectedHour == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('予約送信の場合は日付と時間を選択してください')),
        );
        return;
      }
      final hour = int.parse(_selectedHour!.split(":")[0]);
      final dt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, hour);
      if (dt.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('過去の日時は選択できません')),
        );
        return;
      }
    }

    // タイトル・内容チェック
    if (_subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('件名を入力してください')),
      );
      return;
    }
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('内容を入力してください')),
      );
      return;
    }

    // 送信日時を組み立て
    String? reservationTime;
    if (_selectedTimeOption == '予約') {
      final hour = int.parse(_selectedHour!.split(":")[0]);
      final dt = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, hour);
      reservationTime = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}T${dt.hour.toString().padLeft(2,'0')}:00:00';
    }

    final body = jsonEncode({
      'type': type,
      'userId': userId,
      'title': _subjectController.text,
      'content': _contentController.text,
      'category': _categories[_selectedCategory],
      'reservationTime': reservationTime,
    });

    final url = Uri.parse('http://localhost:8080/api/notifications/send');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信が完了しました'),
          ),
        );
        _clearForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('送信失敗: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通信エラー: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const labelWidth = 90.0;

    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              color: Colors.grey.shade300,
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('メール送信フォーム',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: labelWidth,
                    child: Text('宛先', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: _selectedTypes.keys.map((type) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _selectedTypes[type],
                            onChanged: (value) {
                              setState(() {
                                _selectedTypes[type] = value!;
                                if (type == '個人' && !value) _specificUserIdController.clear();
                              });
                            },
                          ),
                          Text(type),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            if (_selectedTypes['個人'] == true)
              Padding(
                padding: const EdgeInsets.only(left: labelWidth),
                child: TextField(
                  controller: _specificUserIdController,
                  decoration: InputDecoration(
                    hintText: 'ユーザーIDを入力',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: labelWidth,
                    child: Text('カテゴリ', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    hint: Text('選択してください'),
                    items: _categories.keys
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _selectedCategory = v);
                    },
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                    width: labelWidth,
                    child: Text('送信時間', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Radio<String>(
                          value: '即時',
                          groupValue: _selectedTimeOption,
                          onChanged: (v) {
                            setState(() {
                              _selectedTimeOption = v!;
                            });
                          },
                        ),
                        Text('即時'),
                      ]),
                      Row(
                        children: [
                          Radio<String>(
                            value: '予約',
                            groupValue: _selectedTimeOption,
                            onChanged: (v) {
                              setState(() {
                                _selectedTimeOption = v!;
                              });
                            },
                          ),
                          Text('予約'),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _selectedTimeOption == '予約' ? _pickDate : null,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(6),
                                color: Colors.white,
                              ),
                              child: Text(
                                  _selectedDate != null ? _formatDate(_selectedDate!) : '日付選択',
                                  style: TextStyle(color: Colors.black)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedHour,
                            hint: Text('時間'),
                            items: _hours
                                .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                                .toList(),
                            onChanged: (v) {
                              setState(() => _selectedHour = v);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: '件名を入力',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 15,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: '内容を入力',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _sendNotification,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('送信'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
