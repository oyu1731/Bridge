import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/11-common/58-header.dart';

class Industry {
  final int id;
  final String name;
  bool isSelected;

  Industry({required this.id, required this.name, this.isSelected = false});
}

class StudentProfileEditPage extends StatefulWidget {
  const StudentProfileEditPage({super.key});

  @override
  State<StudentProfileEditPage> createState() => _StudentProfileEditPageState();
}

class _StudentProfileEditPageState extends State<StudentProfileEditPage> {
  Map<String, dynamic> userData = {};
  List<Industry> industries = [];
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isSaving = false; // 保存中フラグ

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchData();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('current_user');

    if (userJson != null) {
      final userData = jsonDecode(userJson);
      final userId = userData['id'];

      final url = 'http://localhost:8080/api/users/$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final userData = jsonDecode(responseBody);

        setState(() {
          this.userData = userData;
          _nicknameController.text = userData['nickname'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneNumberController.text = userData['phoneNumber'] ?? '';
        });
      } else {
        print('Failed to load user data');
      }
    } else {
      print('No user session found');
    }
  }

  Future<void> fetchData() async {
    final industriesResponse = await http.get(Uri.parse('http://localhost:8080/api/industries'));
    if (industriesResponse.statusCode == 200) {
      final List<dynamic> industriesData = jsonDecode(industriesResponse.body);
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('current_user');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        final dynamic idValue = userData['id'];
        final int userId = idValue is int ? idValue : int.parse(idValue.toString());

        setState(() {
          industries = industriesData.map((e) => Industry(id: e['id'], name: e['industry'].toString())).toList();
        });

        await fetchIndustryRelations(userId);
      }
    } else {
      print('Failed to load industries');
    }
  }

  Future<void> fetchIndustryRelations(int userId) async {
    final url = 'http://localhost:8080/api/industries/user/$userId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> selectedIndustriesData = jsonDecode(response.body);

      // 修正ポイント: industry は文字列で返るのでシンプルに取得
      final List<String> selectedIndustryNames = selectedIndustriesData.map((e) {
        return e['industry'].toString();
      }).toList();

      if (!mounted) return;
      setState(() {
        for (var industry in industries) {
          if (selectedIndustryNames.contains(industry.name)) {
            industry.isSelected = true;
          }
        }
      });
    } else {
      print('Failed to load industry relations for user $userId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.person, size: 60, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 10),
                  const Text("プロフィール写真"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildLabel("ニックネーム"),
            _buildTextField(_nicknameController),
            const SizedBox(height: 20),
            _buildLabel("メールアドレス"),
            _buildTextField(_emailController),
            const SizedBox(height: 20),
            _buildLabel("電話番号"),
            _buildTextField(_phoneNumberController),
            const SizedBox(height: 20),
            _buildLabel("業界"),
            Column(
              children: industries.map((industry) {
                return CheckboxListTile(
                  title: Text(industry.name),
                  value: industry.isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      industry.isSelected = value ?? true;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        await _updateUserProfile();
                        setState(() => _isSaving = false);
                      },
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('編集'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField(TextEditingController controller, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _updateUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userJson = prefs.getString('current_user');
    if (userJson == null) {
      print('No user session found for updating profile');
      return;
    }

    final userData = jsonDecode(userJson);
    final dynamic idValue = userData['id'];
    final int userId = idValue is int ? idValue : int.parse(idValue.toString());

    final Map<String, dynamic> updatedData = {
      'nickname': _nicknameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneNumberController.text,
    };

    final userUpdateUrl = 'http://localhost:8080/api/users/$userId/profile';
    final userUpdateResponse = await http.put(
      Uri.parse(userUpdateUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );

    // 修正ポイント: name ではなく id を送信
    final selectedIndustries = industries
        .where((industry) => industry.isSelected)
        .map((industry) => industry.id) // ← id を送る
        .toList();

    final industriesUpdateUrl = 'http://localhost:8080/api/users/$userId/industries';
    final industriesUpdateResponse = await http.put(
      Uri.parse(industriesUpdateUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(selectedIndustries),
    );

    if (userUpdateResponse.statusCode == 200 && industriesUpdateResponse.statusCode == 200) {
      // 現在のセッション情報を取得して、変更点のみ更新する
      final String? currentUserJson = prefs.getString('current_user');
      if (currentUserJson != null) {
        Map<String, dynamic> currentUserData = jsonDecode(currentUserJson);

        // 変更された項目だけを更新
        currentUserData['nickname'] = _nicknameController.text;
        currentUserData['email'] = _emailController.text;
        currentUserData['phoneNumber'] = _phoneNumberController.text;

        // 更新したセッション情報を保存
        await prefs.setString('current_user', jsonEncode(currentUserData));
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('成功'),
            content: const Text('プロフィールを更新しました'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ダイアログを閉じる
                  Navigator.of(context).pop(); // プロフィール編集画面を閉じる
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('エラー'),
            content: const Text('プロフィールの更新に失敗しました'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          );
        },
      );
    }
  }

}
