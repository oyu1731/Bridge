import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/03-home/09-company-home.dart';
import 'package:bridge/main.dart';

class Industry {
  final int id;
  final String name;
  bool isSelected;

  Industry({required this.id, required this.name, this.isSelected = false});
}

class CompanyProfileEditPage extends StatefulWidget {
  const CompanyProfileEditPage({super.key});

  @override
  State<CompanyProfileEditPage> createState() => _CompanyProfileEditPageState();
}

class _CompanyProfileEditPageState extends State<CompanyProfileEditPage> {
  Map<String, dynamic> userData = {};
  List<Industry> industries = [];
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _companyAddressController = TextEditingController();
  final _companyDescriptionController = TextEditingController();

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
    _companyAddressController.dispose();
    _companyDescriptionController.dispose();
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
          _companyAddressController.text = userData['companyAddress'] ?? '';
          _companyDescriptionController.text = userData['companyDescription'] ?? '';
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
            _buildLabel("企業名"),
            _buildTextField(_nicknameController),
            const SizedBox(height: 20),
            _buildLabel("メールアドレス"),
            _buildTextField(_emailController),
            const SizedBox(height: 20),
            _buildLabel("電話番号"),
            _buildTextField(_phoneNumberController),
            const SizedBox(height: 20),
            _buildLabel("住所"),
            _buildTextField(_companyAddressController),
            const SizedBox(height: 20),
            _buildLabel("詳細"),
            _buildTextField(_companyDescriptionController, maxLines: 5),
            const SizedBox(height: 30),
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

  void _navigateToHome(Map<String, dynamic> userData) {
    final int? type = userData['type'];
    Widget homePage;
    if (type == 1 || type == 2) {
      homePage = const StudentWorkerHome();
    } else if (type == 3) {
      homePage = const CompanyHome();
    } else {
      homePage = const MyHomePage(title: 'Bridge');
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => homePage),
      (Route<dynamic> route) => false,
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
    final int userId = userData['id'];

    final selectedIndustryIds = industries
        .where((industry) => industry.isSelected)
        .map((industry) => industry.id)
        .toList();

    final Map<String, dynamic> updatedData = {
      'nickname': _nicknameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneNumberController.text,
      'companyAddress': _companyAddressController.text,
      'companyDescription': _companyDescriptionController.text,
      'desiredIndustries': selectedIndustryIds,
    };

    final url = 'http://localhost:8080/api/users/$userId/profile';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );

    if (response.statusCode == 200) {
      final updatedUserData = jsonDecode(response.body);
      await prefs.setString('current_user', jsonEncode(updatedUserData));

      showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('成功'),
            content: const Text('プロフィールを更新しました'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('OK'),
              ),
            ],
          );
        },
      ).then((result) {
        if (result == true) {
          _navigateToHome(updatedUserData);
        }
      });
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
