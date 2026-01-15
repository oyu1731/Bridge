import 'dart:convert';
import 'package:bridge/06-company/api_config.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/60-ScreenWrapper.dart';

class AnswerExplanationScreen extends StatefulWidget {
  final Map<String, dynamic> question;
  final bool userAnswer;
  final int questionNumber;
  final int? totalQuestions;
  final String courseType;
  final VoidCallback onNext;
  final VoidCallback onFinish;

  const AnswerExplanationScreen({
    super.key,
    required this.question,
    required this.userAnswer,
    required this.questionNumber,
    this.totalQuestions,
    required this.courseType,
    required this.onNext,
    required this.onFinish,
  });

  @override
  State<AnswerExplanationScreen> createState() =>
      _AnswerExplanationScreenState();
}

class _AnswerExplanationScreenState extends State<AnswerExplanationScreen> {
  Map<String, dynamic>? session;

  @override
  void initState() {
    super.initState();
    _sendCorrectIfNeeded();
  }

  /// 正解ならバックエンドへPOST
  Future<void> _sendCorrectIfNeeded() async {
    session = await GlobalActions().loadUserSession();
    final bool isCorrect = widget.userAnswer == widget.question['answer'];

    if (!isCorrect) return;

    // final url = Uri.parse("http://localhost:8080/api/quiz/correct");
    final url = Uri.parse("${ApiConfig.baseUrl}/api/quiz/correct");

    final int userId = session?['id'];
    final String nickname = session?['nickname'];

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": userId, "nickname": nickname}),
      );

      print("正解通知送信: ${response.statusCode}");
      print("レスポンス: ${response.body}");
    } catch (e) {
      print("正解通知エラー: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isCorrect = widget.userAnswer == widget.question['answer'];
    final Color primaryColor =
        isCorrect ? Color(0xFF10B981) : Color(0xFFEF4444);
    final Color secondaryColor =
        isCorrect ? Color(0xFFECFDF5) : Color(0xFFFEF2F2);

    return ScreenWrapper(
      appBar: BridgeHeader(),
      backgroundColor: Color(0xFFF8FAFC),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 進捗表示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '問題 ${widget.questionNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (widget.totalQuestions != null)
                    Text(
                      '${widget.questionNumber}/${widget.totalQuestions}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 正解/不正解ヘッダー
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isCorrect
                          ? [Color(0xFF10B981), Color(0xFF059669)]
                          : [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCorrect ? '正解！' : '不正解',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isCorrect ? '素晴らしい回答です！' : 'もう一度復習しましょう',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 問題セクション
            _buildSection(
              title: '問題',
              icon: Icons.help_outline,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Text(
                  widget.question['question'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 解答比較
            Row(
              children: [
                Expanded(
                  child: _buildAnswerCard(
                    title: 'あなたの解答',
                    isCorrect: isCorrect,
                    isUserAnswer: true,
                    answer: widget.userAnswer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnswerCard(
                    title: '正解',
                    isCorrect: isCorrect,
                    isUserAnswer: false,
                    answer: widget.question['answer'],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 解説セクション
            _buildSection(
              title: '解説',
              icon: Icons.lightbulb_outline,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.question['explanation'] ?? '解説がありません',
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF475569),
                      ),
                    ),
                    if (widget.question['tip'] != null &&
                        widget.question['tip'].toString().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.question['tip'].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF92400E),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 次へ/結果を見るボタン
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed:
                    _shouldShowFinishButton() ? widget.onFinish : widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shouldShowFinishButton() ? '結果を見る' : '次へ進む',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _shouldShowFinishButton()
                          ? Icons.arrow_forward
                          : Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.white,
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

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF6366F1), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildAnswerCard({
    required String title,
    required bool isCorrect,
    required bool isUserAnswer,
    required bool answer,
  }) {
    final Color cardColor =
        isUserAnswer
            ? (isCorrect ? Color(0xFFECFDF5) : Color(0xFFFEF2F2))
            : Color(0xFFF0F9FF);
    final Color textColor =
        isUserAnswer
            ? (isCorrect ? Color(0xFF065F46) : Color(0xFF991B1B))
            : Color(0xFF0C4A6E);
    final Color iconColor =
        isUserAnswer
            ? (isCorrect ? Color(0xFF10B981) : Color(0xFFEF4444))
            : Color(0xFF0EA5E9);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              isUserAnswer
                  ? (isCorrect ? Color(0xFFA7F3D0) : Color(0xFFFECACA))
                  : Color(0xFFBAE6FD),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  answer ? Icons.check : Icons.close,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                answer ? 'マル' : 'バツ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _shouldShowFinishButton() {
    if (widget.totalQuestions == null) return false;
    return widget.questionNumber >= widget.totalQuestions!;
  }
}
