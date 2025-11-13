import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminMailSend extends StatefulWidget {
  @override
  _AdminMailSendState createState() => _AdminMailSendState();
}

class _AdminMailSendState extends State<AdminMailSend> {
  // 宛先
  String _selectedRecipient = '学生';
  final List<String> _recipientOptions = ['学生', '社会人', '企業', '個人'];

  // カテゴリ
  String _selectedCategory = '運営情報';
  final List<String> _categoryOptions = ['運営情報', '重要'];

  // 送信時間
  String _selectedTimeOption = '即時';
  DateTime? _selectedDate;
  String? _selectedHour;

  // 件名・内容
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // 時間プルダウン用
  final List<String> _hours = List.generate(24, (index) => index.toString().padLeft(2, '0') + ':00');

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const labelWidth = 90.0;

    return Scaffold(
      appBar: BridgeHeader(),
      body: Container(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, // フォーム全体背景白
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // タイトル部分だけ灰色
                Container(
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'メール送信フォーム',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),

                // 内側のフォーム
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 宛先
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: labelWidth,
                            child: Text('宛先', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: Row(
                              children: _recipientOptions.map((option) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Radio<String>(
                                      value: option,
                                      groupValue: _selectedRecipient,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedRecipient = value!;
                                        });
                                      },
                                    ),
                                    Text(option),
                                    const SizedBox(width: 16),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // カテゴリ
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: labelWidth,
                            child: Text('カテゴリ', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              items: _categoryOptions
                                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value!;
                                });
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 送信時間
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: labelWidth,
                            child: Text('送信時間', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 即時
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: '即時',
                                      groupValue: _selectedTimeOption,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedTimeOption = value!;
                                        });
                                      },
                                    ),
                                    Text('即時'),
                                  ],
                                ),
                                // 予約
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: '予約',
                                      groupValue: _selectedTimeOption,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedTimeOption = value!;
                                        });
                                      },
                                    ),
                                    Text('予約'),
                                    const SizedBox(width: 8),
                                    // 日付選択
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
                                          _selectedDate != null
                                              ? _formatDate(_selectedDate!)
                                              : '日付選択',
                                          style: TextStyle(color: Colors.black),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 時間選択
                                    DropdownButton<String>(
                                      value: _selectedHour,
                                      hint: Text('時間'),
                                      items: _hours
                                          .map((h) => DropdownMenuItem(value: h, child: Text(h)))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedHour = value;
                                        });
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

                      // 件名
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

                      // 内容
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

                      // 送信ボタン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              print('送信押下');
                            },
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
