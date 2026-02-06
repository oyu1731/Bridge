import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bridge/11-common/api_config.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/03-home/08-student-worker-home.dart';
import 'package:bridge/03-home/09-company-home.dart';
import 'package:bridge/09-admin/36-admin-home.dart';
import 'package:bridge/main.dart';
import 'package:bridge/style.dart';

class PasswordUpdatePage extends StatefulWidget {
  const PasswordUpdatePage({Key? key}) : super(key: key);

  @override
  State<PasswordUpdatePage> createState() => _PasswordUpdatePageState();
}

class _PasswordUpdatePageState extends State<PasswordUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'パスワードを入力してください';
    }
    if (value.length < 8) {
      return 'パスワードは8文字以上である必要があります';
    }
    if (value.length > 255) {
      return 'パスワードは255文字以内で入力してください';
    }
    final regex = RegExp(r'^[a-zA-Z0-9._]+$');
    if (!regex.hasMatch(value)) {
      return '使用できるのは英数字・.・_ のみです';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');

      if (userJson == null) {
        throw Exception('ユーザー情報が見つかりません');
      }

      final userData = jsonDecode(userJson);
      final int userId = userData['id'];
      final int userType = userData['type'];

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/users/$userId/password',
      );

      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': _currentController.text,
          'newPassword': _newController.text,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('現在のパスワードが一致しません');
      }

      _showSuccessDialog(userType);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSuccessDialog(int userType) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('パスワード変更', style: TextStyle(color: AppTheme.textCyanDark)),
          content: const Text('パスワードの変更が完了しました', style: TextStyle(color: AppTheme.textCyanDark)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();

                Widget home;
                if (userType == 1 || userType == 2) {
                  home = const StudentWorkerHome();
                } else if (userType == 3) {
                  home = const CompanyHome();
                } else if (userType == 4) {
                  home = AdminHome();
                } else {
                  home = const MyHomePage(title: 'Bridge');
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => home),
                );
              },
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 28),
                    const Text(
                      'パスワード変更',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textCyanDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '現在のパスワードと新しいパスワードを入力してください。',
                      style: TextStyle(color: AppTheme.textCyanDark),
                    ),
                    const SizedBox(height: 28),

                    _buildPasswordField(
                      label: '現在のパスワード',
                      controller: _currentController,
                      obscure: _obscureCurrent,
                      toggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: 16),

                    _buildPasswordField(
                      label: '新しいパスワード',
                      controller: _newController,
                      obscure: _obscureNew,
                      toggle: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 16),

                    _buildPasswordField(
                      label: '新しいパスワード（再入力）',
                      controller: _confirmController,
                      obscure: _obscureConfirm,
                      toggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) =>
                          v != _newController.text ? 'パスワードが一致しません' : null,
                    ),

                    const SizedBox(height: 24),

                    if (_errorMessage != null)
                      Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),

                    const SizedBox(height: 24),

                    Center(
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _onSubmit,
                        child: _isSaving
                            ? const CircularProgressIndicator()
                            : const Text('送信'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
        Text(label, style: const TextStyle(color: AppTheme.textCyanDark)),
        const SizedBox(height: 8),
        SizedBox(
          width: 600,
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            validator: validator ?? _validatePassword,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.textCyanDark,
                ),
                onPressed: toggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
