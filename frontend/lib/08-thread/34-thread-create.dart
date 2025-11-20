import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class ThreadCreate extends StatefulWidget {
  @override
  _ThreadCreateState createState() => _ThreadCreateState();
}

class _ThreadCreateState extends State<ThreadCreate> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCondition = '全員';
  Map<String, bool> _industry = {
    'メーカー': false,
    '商社': false,
    '流通・小売': false,
    '金融': false,
    'サービス・インフラ': false,
    'ソフトウェア・通信': false,
    '広告・出版・マスコミ': false,
    '官公庁・公社・団体': false,
    'その他': false,
  };

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
            Text('スレッド名', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            Text('説明', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            Text('参加条件', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: ['全員', '学生', '社会人'].map((label) {
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
            Text('業界', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 0, // 改行時の縦余白なし
              children: _industry.keys.map((key) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 20 * 2 - 24) / 3,
                  child: CheckboxListTile(
                    title: Text(key, style: TextStyle(fontSize: 14)),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _industry[key],
                    onChanged: (val) {
                      setState(() {
                        _industry[key] = val!;
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
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _handleCreate,
                child: Text('作成', style: TextStyle(fontSize: 20, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCreate() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final condition = _selectedCondition;
    final selectedIndustries =
        _industry.entries.where((e) => e.value).map((e) => e.key).toList();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('スレッド名を記入してください')),
      );
      return;
    }

    final threadData = {
      'title': title,
      'description': description.isNotEmpty ? description : null,
      'condition': condition,
      'industries': selectedIndustries.isNotEmpty ? selectedIndustries : [],
      'type': 'unofficial',
    };

    print(threadData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('スレッドの作成が完了しました\nスレッドへの書き込みが可能になります。')),
    );
  }
}
