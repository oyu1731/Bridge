import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/03-home/09-company-home.dart';
import 'package:bridge/main.dart';
import 'package:bridge/11-common/image_crop_dialog.dart';
import '../06-company/photo_api_client.dart';
import 'user_api_client.dart';
import 'package:bridge/style.dart';

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
  int? _iconPhotoId;
  String? _iconUrl; // 表示用URL
  bool _uploadingIcon = false;

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

      // final url = 'http://localhost:8080/api/users/$userId';
      final url = 'https://api.bridge-tesg.com/api/users/$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final responseBody = response.body;
        final userData = jsonDecode(responseBody);

        setState(() {
          this.userData = userData;
          _nicknameController.text = userData['nickname'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneNumberController.text = userData['phoneNumber'] ?? '';
          _iconPhotoId = userData['icon'];
        });

        // 既存アイコン取得
        if (_iconPhotoId != null) {
          try {
            final photo = await PhotoApiClient.getPhotoById(_iconPhotoId!);
            setState(() {
              _iconUrl = photo?.photoPath; // フルURL
            });
          } catch (_) {}
        }
      } else {
        print('Failed to load user data');
      }
    } else {
      print('No user session found');
    }
  }

  Future<void> fetchData() async {
    final industriesResponse = await http.get(
      // Uri.parse('http://localhost:8080/api/industries'),
      Uri.parse('https://api.bridge-tesg.com/api/industries'),
    );
    if (industriesResponse.statusCode == 200) {
      final List<dynamic> industriesData = jsonDecode(industriesResponse.body);
      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      final String? userJson = prefs.getString('current_user');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        final dynamic idValue = userData['id'];
        final int userId =
            idValue is int ? idValue : int.parse(idValue.toString());

        setState(() {
          industries =
              industriesData
                  .map(
                    (e) =>
                        Industry(id: e['id'], name: e['industry'].toString()),
                  )
                  .toList();
        });

        await fetchIndustryRelations(userId);
      }
    } else {
      print('Failed to load industries');
    }
  }

  Future<void> fetchIndustryRelations(int userId) async {
    // final url = 'http://localhost:8080/api/industries/user/$userId';
    final url = 'https://api.bridge-tesg.com/api/industries/user/$userId';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> selectedIndustriesData = jsonDecode(response.body);

      // 修正ポイント: industry は文字列で返るのでシンプルに取得
      final List<String> selectedIndustryNames =
          selectedIndustriesData.map((e) {
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
            Text(
              "プロフィールアイコン",
              style: TextStyle(fontSize: 16, color: AppTheme.textCyanDark),
            ),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey.shade200,
                        child:
                            _iconUrl != null
                                ? CircleAvatar(
                                  radius: 52,
                                  backgroundImage: NetworkImage(_iconUrl!),
                                )
                                : Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey[600],
                                ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _uploadingIcon ? null : _pickAndUploadIcon,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blueAccent,
                            child:
                                _uploadingIcon
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
            _buildLabel("希望業界"),
            Column(
              children:
                  industries.map((industry) {
                    return CheckboxListTile(
                      title: Text(industry.name),
                      value: industry.isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          industry.isSelected = value ?? false;
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent[400],
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    _isSaving
                        ? null
                        : () async {
                          setState(() => _isSaving = true);
                          await _updateUserProfile();
                          setState(() => _isSaving = false);
                        },
                child:
                    _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('編集', style: TextStyle(fontSize: 16)),
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
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textCyanDark,
      ),
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

    final selectedIndustryIds =
        industries
            .where((industry) => industry.isSelected)
            .map((industry) => industry.id)
            .toList();

    final Map<String, dynamic> updatedData = {
      'nickname': _nicknameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneNumberController.text,
      'desiredIndustries': selectedIndustryIds,
      'icon': _iconPhotoId,
    };

    // final url = 'http://localhost:8080/api/users/$userId/profile';
    final url = 'https://api.bridge-tesg.com/api/users/$userId/profile';
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

  Future<void> _pickAndUploadIcon() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) return;
    final sessionUser = jsonDecode(userJson);
    final userId = sessionUser['id'];

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    // クロップダイアログを表示
    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    final croppedBytes = await showDialog<Uint8List>(
      context: context,
      builder: (context) => ImageCropDialog(imageBytes: bytes),
    );

    if (croppedBytes == null) return;

    setState(() => _uploadingIcon = true);
    try {
      final tempPath = picked.name;
      final pseudoFile = XFile.fromData(
        croppedBytes,
        name: tempPath,
        mimeType: 'image/jpeg',
      );
      final uploaded = await PhotoApiClient.uploadPhoto(
        pseudoFile,
        userId: userId,
      );
      final photoId = uploaded.id;
      if (photoId != null) {
        await UserApiClient.updateIcon(userId, photoId);
        setState(() {
          _iconPhotoId = photoId;
          _iconUrl = uploaded.photoPath;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('アイコンアップロード失敗: $e')));
    } finally {
      setState(() => _uploadingIcon = false);
    }
  }
}
