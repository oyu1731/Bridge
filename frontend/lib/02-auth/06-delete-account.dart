import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../02-auth/07-delete-complete.dart';
import '../11-common/58-header.dart';
import 'package:bridge/style.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({Key? key}) : super(key: key);

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  bool _isProcessing = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson != null) {
      try {
        final userData = jsonDecode(userJson);
        if (mounted) {
          setState(() {
            _userId = userData['id'] as int?;
          });
        }
      } catch (_) {
      }
    }
  }

  Future<void> _showSnack(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentOrange,
      ),
    );
  }

  Future<void> _confirmAndDelete() async {
    if (_userId == null) {
      _showSnack('ユーザー情報が見つかりません。再度ログインしてください。');
      return;
    }

    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退会確認'),
        content: const Text('会員登録を解除します。よろしいですか？この操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent[400],
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('退会する'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    setState(() => _isProcessing = true);

    try {
      final url = Uri.parse('http://localhost:8080/api/users/$_userId');
      final resp = await http.delete(url);

      if (resp.statusCode == 200) {
        // セッション削除（フロント側）
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user');

        if (!mounted) return;

        // ルートスタックをクリアして完了ページへ
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DeleteCompletePage()),
        );
      } else if (resp.statusCode == 404) {
        _showSnack('ユーザーが見つかりません。');
      } else {
        _showSnack('退会に失敗しました（${resp.statusCode}）。時間をおいて再試行してください。');
      }
    } catch (e) {
      _showSnack('通信エラーが発生しました: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Container(height: 1, color: const Color(0xFFF0F0F0)),
                  const SizedBox(height: 16),

                  const Text(
                    '退会手続き',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.cyanDark),
                    ),
                    child: const Text(
                      '会員登録を解除します。\n退会すると、あなたのアカウント情報は削除され元に戻せません。本当に退会しますか？',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // 退会ボタン
                  Row(
                    children: [

                      TextButton(
                        onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textCyanDark,
                          textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        child: const Text('戻る'),
                      ),

                      const SizedBox(width: 30),

                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _confirmAndDelete,
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.exit_to_app),
                        label: Text(_isProcessing ? '処理中...' : '退会する'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
