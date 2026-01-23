import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboardを使用するために追加
import 'package:http/http.dart' as http;
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'package:bridge/11-common/60-ScreenWrapper.dart';

class EmailCorrectionScreen extends StatefulWidget {
  const EmailCorrectionScreen({super.key});

  @override
  State<EmailCorrectionScreen> createState() => _EmailCorrectionScreenState();
}

class _EmailCorrectionScreenState extends State<EmailCorrectionScreen> {
  final TextEditingController _originalEmailController =
      TextEditingController();
  String _correctedEmail = '';
  String _correctionDetails = '';
  bool _isLoading = false;
  bool _showCorrectionCompleteAlert = false; // 添削完了アラート表示フラグ
  final GlobalActions _globalActions = GlobalActions(); // GlobalActionsのインスタンス
  Map<String, dynamic>? _userSession; // ユーザーセッションを保持

  @override
  void initState() {
    super.initState();
    _loadUserSession(); // ユーザーセッションをロード
  }

  void _loadUserSession() async {
    _userSession = await _globalActions.loadUserSession();
    setState(() {}); // UIを更新するためにsetStateを呼び出す
  }

  void _correctEmail() async {
    if (_originalEmailController.text.trim().isEmpty) {
      // エラー時はshowGenericDialogを使用
      showGenericDialog(
        context: context,
        type: DialogType.onlyOk,
        title: '入力エラー',
        content: 'メール本文を入力してください',
        confirmText: 'OK',
        onConfirm: () {},
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _showCorrectionCompleteAlert = false; // リセット
    });

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/api/email-correction'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'originalEmail': _originalEmailController.text}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        setState(() {
          _correctedEmail = responseData['correctedEmail'] ?? '添削結果がありません。';
          _correctionDetails = responseData['correctionDetails'] ?? '詳細がありません。';
          _showCorrectionCompleteAlert = true; // アラート表示フラグを立てる
        });

        // トークンを消費（プレミアムユーザーは除外）
        if (_userSession != null && _userSession!['id'] != null) {
          final isPremium = (_userSession?['planStatus'] ?? '無料') != '無料';
          if (!isPremium) {
            final userId = _userSession!['id'] as int;
            final tokensToDeduct = 5; // メール添削のトークンコスト
            final bool deducted = await _globalActions.deductUserTokens(
              userId,
              tokensToDeduct,
            );
            if (deducted) {
              print('$tokensToDeduct トークンを消費しました。');
              // セッションのトークン数を更新するなどの処理が必要であればここに追加
            } else {
              print('トークン消費に失敗しました。');
            }
          } else {
            print('プレミアムユーザーのためトークン消費をスキップしました。');
          }
        }

        // 添削完了アラートを表示
        if (_showCorrectionCompleteAlert) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 成功ダイアログ
            showGenericDialog(
              context: context,
              type: DialogType.onlyOk,
              title: '添削完了',
              content: 'メールの添削が完了しました',
              confirmText: 'OK',
              onConfirm: () {},
            );
          });
        }
      } else {
        showGenericDialog(
          context: context,
          type: DialogType.onlyOk,
          title: 'APIエラー',
          content: 'ステータスコード: ${response.statusCode}',
          confirmText: 'OK',
          onConfirm: () {},
        );
      }
    } catch (e) {
      showGenericDialog(
        context: context,
        type: DialogType.onlyOk,
        title: '通信エラー',
        content: 'エラー内容: $e',
        confirmText: 'OK',
        onConfirm: () {},
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // コピー機能を実装
  void _copyToClipboard() async {
    if (_correctedEmail.isEmpty) {
      showGenericDialog(
        context: context,
        type: DialogType.onlyOk,
        title: 'コピーできません',
        content: '添削後のメールがありません',
        confirmText: 'OK',
        onConfirm: () {},
      );
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: _correctedEmail));

      // コピー成功アラート
      showGenericDialog(
        context: context,
        type: DialogType.onlyOk,
        title: 'コピー完了',
        content: '添削後のメールをクリップボードにコピーしました',
        confirmText: 'OK',
        onConfirm: () {},
      );
    } catch (e) {
      showGenericDialog(
        context: context,
        type: DialogType.onlyOk,
        title: 'コピー失敗',
        content: 'クリップボードへのコピーに失敗しました: $e',
        confirmText: 'OK',
        onConfirm: () {},
      );
    }
  }

  void _clearAll() {
    setState(() {
      _originalEmailController.clear();
      _correctedEmail = '';
      _correctionDetails = '';
      _showCorrectionCompleteAlert = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return ScreenWrapper(
      appBar: BridgeHeader(),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child:
            isSmallScreen
                ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // スマホ：縦積みレイアウト
                    Flexible(flex: 2, child: _buildInputSection()),
                    const SizedBox(height: 12),
                    _buildCorrectionButtonSmall(),
                    const SizedBox(height: 12),
                    Flexible(flex: 2, child: _buildCorrectedSection()),
                    const SizedBox(height: 12),
                    Flexible(flex: 1, child: _buildCorrectionDetails()),
                  ],
                )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // PC：横並びレイアウト
                    Flexible(
                      flex: 3,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 左側：オリジナルメール入力
                          Expanded(child: _buildInputSection()),

                          // 中央：添削ボタン
                          _buildCorrectionButton(),

                          // 右側：添削後メール表示
                          Expanded(child: _buildCorrectedSection()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 下部：編集内容説明
                    Flexible(flex: 2, child: _buildCorrectionDetails()),
                  ],
                ),
      ),
    );
  }

  Widget _buildInputSection() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '元のメール',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '添削したいメール本文を入力してください',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TextField(
                  controller: _originalEmailController,
                  maxLines: null,
                  expands: true,
                  decoration: InputDecoration(
                    hintText: '例：\nお世話になります。\n先日の件ですが、資料送ってください。\nよろしくお願いします。',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                    hintStyle: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                  ),
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: _isLoading ? null : _correctEmail,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.arrow_forward, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            _isLoading ? '添削中...' : '添削',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionButtonSmall() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _correctEmail,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: _isLoading ? Colors.grey : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isLoading ? '添削中...' : 'メールを添削',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildCorrectedSection() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '添削後のメール',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AIによる添削結果が表示されます',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade50,
                ),
                child:
                    _correctedEmail.isEmpty
                        ? const Center(
                          child: Text(
                            '添削結果がここに表示されます',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                        : Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: SelectableText(
                              _correctedEmail,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorrectionDetails() {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '編集内容の詳細',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '何をどう編集したかが表示されます',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.3,
                ),
                padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade50,
                ),
                child:
                    _correctionDetails.isEmpty
                        ? const Center(
                          child: Text(
                            '編集内容の詳細がここに表示されます',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                        : SingleChildScrollView(
                          child: SelectableText(
                            _correctionDetails,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              height: 1.5,
                            ),
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),
            isSmallScreen
                ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _clearAll,
                        child: const Text('クリア'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _correctedEmail.isEmpty ? null : _copyToClipboard,
                        child: const Text('コピー'),
                      ),
                    ),
                  ],
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: _clearAll,
                      child: const Text('クリア'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          _correctedEmail.isEmpty ? null : _copyToClipboard,
                      child: const Text('コピー'),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _originalEmailController.dispose();
    super.dispose();
  }
}
