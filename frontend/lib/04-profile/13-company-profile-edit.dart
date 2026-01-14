import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/image_crop_dialog.dart';
import '../06-company/photo_api_client.dart';
import 'user_api_client.dart';
import 'company_photo_modal.dart';
import '../../06-company/company_api_client.dart';

class Industry {
  final int id;
  final String name;
  bool isSelected;

  Industry({required this.id, required this.name, this.isSelected = false});
}
  int? _companyPhotoId;
  String? _companyPhotoUrl;

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
  int? _iconPhotoId;
  String? _iconUrl;
  bool _uploadingIcon = false;

  bool _isSaving = false;

  // 統一カラー
  // static const Color cyanDark = Color.fromARGB(255, 0, 100, 120);
  // static const Color cyanMedium = Color.fromARGB(255, 24, 147, 178);
  // static const Color errorOrange = Color.fromARGB(255, 239, 108, 0);
  static const Color textCyanDark = Color.fromARGB(255, 2, 44, 61);

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
          _iconPhotoId = userData['icon'];

          // 企業写真情報をセット
          if (userData['companyPhotoId'] != null) {
            _companyPhotoId = userData['companyPhotoId'];
          }
          if (userData['companyPhotoId'] != null && userData['companyPhotoId'] is int) {
            PhotoApiClient.getPhotoById(userData['companyPhotoId']).then((photo) {
              if (photo?.photoPath != null) {
                setState(() {
                  _companyPhotoUrl = photo!.photoPath;
                });
              }
            });
          }
        });

        // 既存アイコン取得
        if (_iconPhotoId != null) {
          try {
            final photo = await PhotoApiClient.getPhotoById(_iconPhotoId!);
            setState(() {
              _iconUrl = photo?.photoPath;
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
                  Text("プロフィールアイコン",
                    style: TextStyle(
                      fontSize: 16,
                      color: textCyanDark
                    ),
                  ),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey.shade200,
                        child: _iconUrl != null
                            ? CircleAvatar(
                                radius: 52,
                                backgroundImage: NetworkImage(_iconUrl!),
                              )
                            : Icon(Icons.person, size: 60, color: Colors.grey[600]),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _uploadingIcon ? null : _pickAndUploadIcon,
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.blueAccent,
                            child: _uploadingIcon
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt, size: 20, color: Colors.white),
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
            // 企業写真追加ボタン（常に表示、アップロード時にphoto_id/photoUrlを上書き）
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo),
                label: const Text('企業写真追加'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CompanyPhotoModal(
                      onPhotoUploaded: (photoId, photoUrl) {
                        setState(() {
                          _companyPhotoId = photoId;
                          _companyPhotoUrl = photoUrl;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
                        if (_companyPhotoUrl != null)
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              Text('選択中の企業写真', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Image.network(_companyPhotoUrl!, width: 120, height: 120, fit: BoxFit.cover),
                            ],
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
            _buildLabel("所属業界"),
            Column(
              children: industries.map((industry) {
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
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() => _isSaving = true);
                        await _updateUserProfile();
                        setState(() => _isSaving = false);
                      },
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('編集',
                        style: TextStyle(
                          fontSize: 16,
                        ),),
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
        color: textCyanDark,
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
    int? companyId = userData['companyId'];
    print('プロフィール更新: companyId=$companyId, photoId=$_companyPhotoId');

    final Map<String, dynamic> updatedData = {
      'nickname': _nicknameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneNumberController.text,
      'companyAddress': _companyAddressController.text,
      'companyDescription': _companyDescriptionController.text,
      'icon': _iconPhotoId,
    };

    final userUpdateUrl = 'http://localhost:8080/api/users/$userId/profile';
    final userUpdateResponse = await http.put(
      Uri.parse(userUpdateUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );

    // 企業写真のphoto_idを保存
    if (companyId != null && _companyPhotoId != null) {
      final companyPhotoUrl = 'http://localhost:8080/api/companies/$companyId/photo';
      final companyPhotoRes = await http.put(
        Uri.parse(companyPhotoUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'photo_id': _companyPhotoId}),
      );
      print('企業写真APIレスポンス: status=${companyPhotoRes.statusCode}, body=${companyPhotoRes.body}');
      if (companyPhotoRes.statusCode != 200) {
        print('企業写真の保存に失敗: ${companyPhotoRes.statusCode}');
      }
    }

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

    // 企業プロフィール更新（企業アカウントの場合のみ）
    if (companyId != null && userData['type'] == 3) {
      // planStatusを数値型で送信
      int planStatusValue = 1; // デフォルト: 無料
      if (userData['planStatus'] != null) {
        if (userData['planStatus'] is int) {
          planStatusValue = userData['planStatus'];
        } else if (userData['planStatus'] is String) {
          switch (userData['planStatus']) {
            case '無料':
            case 'free':
              planStatusValue = 1;
              break;
            case '有料':
            case 'paid':
              planStatusValue = 2;
              break;
            default:
              planStatusValue = 1;
          }
        }
      }
      final Map<String, dynamic> companyUpdateData = {
        'name': _nicknameController.text,
        'address': _companyAddressController.text,
        'phoneNumber': _phoneNumberController.text,
        'description': _companyDescriptionController.text,
        'planStatus': planStatusValue,
      };
      if (_companyPhotoId != null) {
        companyUpdateData['photoId'] = _companyPhotoId;
      }
      print('企業プロフィール更新: $companyUpdateData');
      final companyUpdateUrl = 'http://localhost:8080/api/companies/$companyId';
      final companyUpdateRes = await http.put(
        Uri.parse(companyUpdateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(companyUpdateData),
      );
      print('企業プロフィールAPIレスポンス: status=${companyUpdateRes.statusCode}, body=${companyUpdateRes.body}');
    }

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

  Future<void> _pickAndUploadIcon() async{
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) return;
    final sessionUser = jsonDecode(userJson);
    final userId = sessionUser['id'];

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;

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
      final pseudoFile = XFile.fromData(croppedBytes, name: tempPath, mimeType: 'image/jpeg');
      final uploaded = await PhotoApiClient.uploadPhoto(pseudoFile, userId: userId);
      final photoId = uploaded.id;
      if (photoId != null) {
        await UserApiClient.updateIcon(userId, photoId);
        setState(() {
          _iconPhotoId = photoId;
          _iconUrl = uploaded.photoPath;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アイコンアップロード失敗: $e')),
      );
    } finally {
      setState(() => _uploadingIcon = false);
    }
  }
}