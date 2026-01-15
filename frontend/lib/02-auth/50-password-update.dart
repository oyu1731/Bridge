import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/03-home/09-company-home.dart';
import 'package:bridge/main.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bridge/style.dart';

class PasswordUpdatePage extends StatefulWidget {
  const PasswordUpdatePage({Key? key}) : super(key: key);

  @override
  State<PasswordUpdatePage> createState() => _PasswordUpdatePageState();
}

class _PasswordUpdatePageState extends State<PasswordUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController(text: '');
  final _newController = TextEditingController(text: '');
  final _confirmController = TextEditingController(text: '');

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toggleCurrent() => setState(() => _obscureCurrent = !_obscureCurrent);
  void _toggleNew() => setState(() => _obscureNew = !_obscureNew);
  void _toggleConfirm() => setState(() => _obscureConfirm = !_obscureConfirm);

  Future<void> _onSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');

      int? userId;
      int? userType;

      if (userJson != null) {
        final userData = jsonDecode(userJson);
        userId = userData['id'];
        userType = userData['type'];
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ユーザーが見つかりません')));
        return;
      }

      if (userId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ユーザーIDが取得できませんでした')));
        return;
      }

      // final url = Uri.parse('http://localhost:8080/api/users/$userId/password');
      final url = Uri.parse(
        'https://api.bridge-tesg.com/api/users/$userId/password',
      );
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': _currentController.text,
          'newPassword': _newController.text,
        }),
      );

      if (response.statusCode == 200) {
        // 成功時はポップアップ表示
        showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('パスワード変更'),
              content: const Text('パスワードの変更が完了しました'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // トップページへ遷移
                    Widget homePage;
                    if (userType == 1 || userType == 2) {
                      homePage = const StudentWorkerHome();
                    } else if (userType == 3) {
                      homePage = const CompanyHome();
                    } else {
                      homePage = const MyHomePage(title: 'Bridge');
                    }
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => homePage),
                    );
                  },
                  child: const Text('閉じる'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: ${response.body}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // --- タイトル ---
                  Text('パスワード変更', style: AppTheme.mainTextStyle),
                  const SizedBox(height: 12),
                  const Text(
                    '現在のパスワードと、新しいパスワードを入力してください。',
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 28),

                  // --- フォーム ---
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildPasswordField(
                          label: '現在のパスワード',
                          controller: _currentController,
                          obscure: _obscureCurrent,
                          toggle: _toggleCurrent,
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: '新しいパスワード',
                          controller: _newController,
                          obscure: _obscureNew,
                          toggle: _toggleNew,
                          validator: (v) {
                            if (v == null || v.isEmpty) return '入力してください';
                            if (v.length < 8) return 'パスワードは8文字以上である必要があります';
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildPasswordField(
                          label: '新しいパスワード（再入力）',
                          controller: _confirmController,
                          obscure: _obscureConfirm,
                          toggle: _toggleConfirm,
                          validator: (v) {
                            if (v == null || v.isEmpty) return '再入力してください';
                            if (v != _newController.text) return 'パスワードが一致しません';
                            return null;
                          },
                        ),

                        const SizedBox(height: 28),

                        // --- ボタン群 ---
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.of(context).maybePop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('戻る'),
                            ),

                            const Spacer(),

                            ElevatedButton(
                              onPressed: _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orangeAccent[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('送信'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuPill(String text) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: const StadiumBorder(),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.black26),
      ),
      child: Text(text),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator:
              validator ?? (v) => (v == null || v.isEmpty) ? '入力してください' : null,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: toggle,
            ),
          ),
        ),
      ],
    );
  }
}
