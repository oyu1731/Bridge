import 'package:bridge/07-ai-training/24-phone-practice.dart';
import 'package:flutter/material.dart';
import '22-interview-practice.dart';
import '26-email-correction.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/59-global-method.dart';
// ↓ ScreenWrapperのインポートを追加 (パスは環境に合わせて調整してください)
import 'package:bridge/11-common/60-ScreenWrapper.dart';
import 'voice_setting_dialog.dart';
import 'dart:js' as js; // ※Web以外でエラーになる場合は削除してください
import 'package:http/http.dart' as http;

// カスタムのScrollBehaviorを定義
class NoThumbScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // オーバーフローインジケータを非表示にする
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // スクロールバーを非表示にする
  }
}

class AiTrainingListPage extends StatefulWidget {
  const AiTrainingListPage({super.key});

  @override
  State<AiTrainingListPage> createState() => _AiTrainingListPageState();
}

class _AiTrainingListPageState extends State<AiTrainingListPage> {
  final GlobalActions _globalActions = GlobalActions();
  String? _selectedVoiceName;
  double _pitch = 1.0;
  double _rate = 0.5;
  Map<String, dynamic>? user;
  int _currentTokens = 0; // 新しいトークン状態変数
  bool _isLoading = false; // ロード状態を示す変数

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserSessionAndTokens();
    _loadCurrentSettings();
  }

  Future<void> _loadUserSessionAndTokens() async {
    setState(() {
      _isLoading = true; // ロード開始
    });
    print('[_loadUserSessionAndTokens] ユーザーセッションをロード中...');
    user = await _globalActions.loadUserSession();
    if (user != null) {
      print('[_loadUserSessionAndTokens] セッションからユーザーをロードしました: $user');
      if (user!['id'] != null) {
        print(
          '[_loadUserSessionAndTokens] ユーザーID: ${user!['id']} でトークンを取得中...',
        );
        final int? fetchedTokens = await _globalActions.fetchUserTokens(
          user!['id'] as int,
        );
        setState(() {
          _currentTokens = fetchedTokens ?? 0;
        });
        print('[_loadUserSessionAndTokens] 取得したトークン: $_currentTokens');
      } else {
        print('[_loadUserSessionAndTokens] ユーザーIDがセッションに見つかりません。');
      }
    } else {
      print('[_loadUserSessionAndTokens] セッションにユーザー情報が見つかりません。');
    }
    setState(() {
      _isLoading = false; // ロード終了
    });
  }

  Future<void> _loadCurrentSettings() async {
    final String? savedVoice = await _globalActions.loadVoiceSetting();
    final double? savedPitch = await _globalActions.loadVoicePitch();
    final double? savedRate = await _globalActions.loadVoiceRate();

    setState(() {
      _selectedVoiceName = savedVoice;
      _pitch = savedPitch ?? 1.0;
      _rate = savedRate ?? 0.5;
    });
  }

  void _openVoiceSettingDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return const VoiceSettingDialog();
      },
    ).then((_) {
      _loadCurrentSettings();
    });
  }

  void _playDummySpeech(String text) {
    if (_selectedVoiceName != null) {
      speakWeb(
        text,
        voiceName: _selectedVoiceName!,
        pitch: _pitch,
        rate: _rate,
      );
    } else {
      print('音声が選択されていません。');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    // ユーザーのトークン数を取得（デフォルトは0）
    final int currentTokens = _currentTokens;

    // 変更点: Scaffold を ScreenWrapper に置き換え
    return ScreenWrapper(
      appBar: BridgeHeader(), // ScreenWrapperのappBar引数へ
      child: Stack(
        // Scaffoldのbodyだった部分をchild引数へ
        // Stackウィジェットを追加
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFF0F7FF),
                  Color(0xFFE8F3FF),
                ],
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Expanded(
                      child: ScrollConfiguration(
                        // ScrollConfigurationでラップ
                        behavior:
                            NoThumbScrollBehavior(), // カスタムのScrollBehaviorを適用
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                            horizontal: isLargeScreen ? 40.0 : 20.0,
                            vertical: 20.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 20),

                              // ヘッダーセクション
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF4F46E5),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      size: isLargeScreen ? 40 : 32,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "AIと一緒にスキルを磨こう",
                                      style: TextStyle(
                                        fontSize: isLargeScreen ? 20 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "～あなたの成長をサポートする学習モード～",
                                      style: TextStyle(
                                        fontSize: isLargeScreen ? 13 : 12,
                                        color: Colors.white70,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // トークン表示カード
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet,
                                          color: Colors.blue.shade600,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "現在のトークン",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade500,
                                            Colors.blue.shade700,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "$currentTokens トークン",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),

                              // トレーニングボタングリッド - 中央揃え
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: isLargeScreen ? 3 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio:
                                    1.0, // 縦横比を調整してトークン表示用のスペースを確保
                                padding: EdgeInsets.zero,
                                children: [
                                  _buildTrainingCard(
                                    icon: Icons.phone_in_talk,
                                    title: "電話練習",
                                    subtitle: "電話対応をAIと練習",
                                    tokenCost: 20,
                                    currentTokens: currentTokens,
                                    isPremium:
                                        (user?['planStatus'] ?? '無料') != '無料',
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PhonePractice(),
                                        ),
                                      ).then(
                                        (_) => _loadUserSessionAndTokens(),
                                      ); // 画面戻り時にトークンを再取得
                                    },
                                  ),
                                  _buildTrainingCard(
                                    icon: Icons.record_voice_over,
                                    title: "面接練習",
                                    subtitle: "模擬面接で実践力を養う",
                                    tokenCost: 20,
                                    currentTokens: currentTokens,
                                    isPremium:
                                        (user?['planStatus'] ?? '無料') != '無料',
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF2563EB),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => InterviewPractice(),
                                        ),
                                      ).then(
                                        (_) => _loadUserSessionAndTokens(),
                                      ); // 画面戻り時にトークンを再取得
                                    },
                                  ),
                                  _buildTrainingCard(
                                    icon: Icons.email_outlined,
                                    title: "メール添削",
                                    subtitle: "ビジネスメールをAIが添削",
                                    tokenCost: 5,
                                    currentTokens: currentTokens,
                                    isPremium:
                                        (user?['planStatus'] ?? '無料') != '無料',
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8B5CF6),
                                        Color(0xFF7C3AED),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  EmailCorrectionScreen(),
                                        ),
                                      ).then(
                                        (_) => _loadUserSessionAndTokens(),
                                      ); // 画面戻り時にトークンを再取得
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              // 特徴説明セクション
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      "AIトレーニングの特徴",
                                      style: TextStyle(
                                        fontSize: isLargeScreen ? 18 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFeatureItem(
                                      Icons.insights,
                                      "詳細なフィードバック",
                                      "回答に対して具体的な改善点を指摘",
                                      isLargeScreen,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildFeatureItem(
                                      Icons.schedule,
                                      "いつでもどこでも",
                                      "24時間いつでも練習可能",
                                      isLargeScreen,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 音声設定ボタン
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Opacity(
                        opacity:
                            (user?['planStatus'] ?? '無料') == '無料' ? 0.6 : 1.0,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if ((user?['planStatus'] ?? '無料') == '無料') {
                              showGenericDialog(
                                context: context,
                                type: DialogType.onlyOk,
                                title: 'プレミアム限定',
                                content: 'AI音声設定はプレミアム会員限定です。',
                              );
                            } else {
                              _openVoiceSettingDialog();
                            }
                          },
                          icon: Icon(
                            Icons.voice_chat,
                            size: isLargeScreen ? 22 : 20,
                          ),
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'AI音声設定',
                                style: TextStyle(
                                  fontSize: isLargeScreen ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFA500),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "PREMIUM",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isLargeScreen ? 10 : 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) // ロード中のオーバーレイ
            const Opacity(
              opacity: 0.5,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildTrainingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int tokenCost,
    required int currentTokens,
    required bool isPremium,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    // プレミアムユーザーの場合はトークンコストを0に設定
    final int effectiveTokenCost = isPremium ? 0 : tokenCost;
    final bool hasEnoughTokens = currentTokens >= effectiveTokenCost;

    return GestureDetector(
      onTap: hasEnoughTokens ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アイコン部分
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),

                // タイトル部分
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // サブタイトル部分
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),

                // トークン消費量表示
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPremium ? "無制限" : "$tokenCost トークン",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 矢印アイコン
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            // トークン不足時のオーバーレイ
            if (!hasEnoughTokens)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 32,
                        color: Colors.orange.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "トークン不足",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "$tokenCost トークン必要",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    bool isLargeScreen,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: isLargeScreen ? 20 : 18,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isLargeScreen ? 14 : 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: isLargeScreen ? 12 : 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
