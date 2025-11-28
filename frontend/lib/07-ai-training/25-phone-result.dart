import 'package:bridge/07-ai-training/21-ai-training-list.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:bridge/11-common/58-header.dart';
import 'package:http/http.dart' as http;

class PhoneResultScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? evaluationResult;

  const PhoneResultScreen({
    Key? key,
    required this.sessionId,
    this.evaluationResult,
  }) : super(key: key);

  @override
  State<PhoneResultScreen> createState() => _PhoneResultScreenState();
}

class _PhoneResultScreenState extends State<PhoneResultScreen> {
  PhonePracticeEvaluation? _evaluation;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchEvaluationResult();
  }

  Future<void> _fetchEvaluationResult() async {
    if (widget.evaluationResult != null) {
      setState(() {
        _evaluation = PhonePracticeEvaluation.fromJson(
          widget.evaluationResult!,
        );
        _isLoading = false;
      });
      return;
    }

    final encodedSessionId = Uri.encodeComponent(widget.sessionId);
    final url = Uri.parse(
      'http://localhost:8080/api/phone/evaluation/$encodedSessionId',
    );
    print('Sending GET request to URL: $url');
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = jsonDecode(response.body);
        setState(() {
          _evaluation = PhonePracticeEvaluation.fromJson(apiResponse);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '評価結果の取得に失敗しました: ${response.body}';
          print("評価結果の取得に失敗: ${response.body}");
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error内容: $e");
      setState(() {
        _errorMessage = '評価結果の取得中にエラーが発生しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      backgroundColor: const Color(0xFFF8FAFC),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverallAssessment(_evaluation!),
                    const SizedBox(height: 24),
                    _buildScoreBreakdown(_evaluation!),
                    const SizedBox(height: 24),
                    if (_evaluation!.keyStrengths.isNotEmpty)
                      _buildFeedbackSection(
                        '良かった点',
                        Icons.thumb_up,
                        const Color(0xFF10B981),
                        _evaluation!.keyStrengths,
                      ),
                    if (_evaluation!.criticalImprovements.isNotEmpty)
                      _buildFeedbackSection(
                        '改善点',
                        Icons.thumb_down,
                        const Color(0xFFEF4444),
                        _evaluation!.criticalImprovements,
                      ),
                    if (_evaluation!.nextSteps.isNotEmpty)
                      _buildFeedbackSection(
                        '今後のアドバイス',
                        Icons.lightbulb,
                        const Color(0xFFF59E0B),
                        _evaluation!.nextSteps,
                      ),
                    const SizedBox(height: 24),
                    _buildOverallReview(_evaluation!),
                  ],
                ),
              ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildOverallAssessment(PhonePracticeEvaluation evaluation) {
    final int displayMaxScore = evaluation.totalScore;
    final double averageNormalizedScore =
        ((evaluation.comprehensionScore / 20 * 5) +
            (evaluation.businessMannerScore / 20 * 5) +
            (evaluation.politenessScore / 20 * 5) +
            (evaluation.flowOfResponseScore / 20 * 5) +
            (evaluation.scenarioAchievementScore / 20 * 5)) /
        5;

    final RankInfo rankInfo = _calculateRank(averageNormalizedScore * 20);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rankInfo.gradientColors,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: rankInfo.gradientColors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '電話練習結果',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rankInfo.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // スコア表示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreCard(
                  value: '$displayMaxScore',
                  label: '総合スコア',
                  maxValue: '/100',
                  color: Colors.white,
                ),
                _buildScoreCard(
                  value: averageNormalizedScore.toStringAsFixed(1),
                  label: '平均評価',
                  maxValue: '/5',
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // プログレスバー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '総合評価',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      '${displayMaxScore}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: displayMaxScore,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF34D399)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 100 - displayMaxScore,
                        child: const SizedBox(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard({
    required String value,
    required String label,
    required String maxValue,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          maxValue,
          style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildScoreBreakdown(PhonePracticeEvaluation evaluation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assessment, color: Color(0xFF6366F1), size: 20),
                SizedBox(width: 8),
                Text(
                  '項目別評価',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildScoreRow(
              '理解力',
              (evaluation.comprehensionScore / 20 * 5).round(),
              evaluation.comprehensionFeedback,
            ),
            _buildScoreRow(
              'ビジネスマナー',
              (evaluation.businessMannerScore / 20 * 5).round(),
              evaluation.businessMannerFeedback,
            ),
            _buildScoreRow(
              '敬語',
              (evaluation.politenessScore / 20 * 5).round(),
              evaluation.politenessFeedback,
            ),
            _buildScoreRow(
              '対応の流れ',
              (evaluation.flowOfResponseScore / 20 * 5).round(),
              evaluation.flowOfResponseFeedback,
            ),
            _buildScoreRow(
              'シナリオ達成度',
              (evaluation.scenarioAchievementScore / 20 * 5).round(),
              evaluation.scenarioAchievementFeedback,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score, String feedback) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: score,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF4F46E5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            Expanded(flex: 5 - score, child: const SizedBox()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 24,
                      alignment: Alignment.center,
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        _buildStarRating(score),
                        style: const TextStyle(
                          color: Color(0xFFF59E0B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (feedback.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                feedback,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(color: Color(0xFF64748B)),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.5,
                        ),
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

  Widget _buildOverallReview(PhonePracticeEvaluation evaluation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.star_rate_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '総合レビュー',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Text(
                evaluation.summary,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF0C4A6E),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _shareResults();
              },
              icon: const Icon(Icons.share, size: 20),
              label: const Text('結果をシェア'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6366F1),
                side: const BorderSide(color: Color(0xFF6366F1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.replay, size: 20),
              label: const Text('もう一度練習'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const AiTrainingListPage(),
                  ),
                );
              },
              icon: const Icon(Icons.home, size: 20),
              label: const Text('ホーム'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareResults() {
    // シェア機能の実装
    // 実際のアプリでは share_plus パッケージなどを使用
    print('電話練習結果をシェア');
    // Share.share('電話練習の結果をシェアします！');
  }

  String _buildStarRating(int score, {int maxStars = 5}) {
    final filledStars = '★' * score;
    final emptyStars = '☆' * (maxStars - score);
    return filledStars + emptyStars;
  }

  RankInfo _calculateRank(double score) {
    if (score >= 90) {
      return RankInfo(
        title: 'エキスパート',
        gradientColors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      );
    } else if (score >= 80) {
      return RankInfo(
        title: 'アドバンス',
        gradientColors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      );
    } else if (score >= 70) {
      return RankInfo(
        title: 'ミドル',
        gradientColors: [Color(0xFF10B981), Color(0xFF059669)],
      );
    } else if (score >= 60) {
      return RankInfo(
        title: 'ビギナー+',
        gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      );
    } else {
      return RankInfo(
        title: 'ビギナー',
        gradientColors: [Color(0xFF6B7280), Color(0xFF4B5563)],
      );
    }
  }
}

class RankInfo {
  final String title;
  final List<Color> gradientColors;

  RankInfo({required this.title, required this.gradientColors});
}

class PhonePracticeEvaluation {
  final String sessionId;
  final int totalScore;
  final String summary;
  final List<String> keyStrengths;
  final List<String> criticalImprovements;
  final List<String> nextSteps;
  final Map<String, dynamic> detailedEvaluation;
  final int comprehensionScore;
  final String comprehensionFeedback;
  final int businessMannerScore;
  final String businessMannerFeedback;
  final int politenessScore;
  final String politenessFeedback;
  final int flowOfResponseScore;
  final String flowOfResponseFeedback;
  final int scenarioAchievementScore;
  final String scenarioAchievementFeedback;

  PhonePracticeEvaluation({
    required this.sessionId,
    required this.totalScore,
    required this.summary,
    required this.keyStrengths,
    required this.criticalImprovements,
    required this.nextSteps,
    required this.detailedEvaluation,
    required this.comprehensionScore,
    required this.comprehensionFeedback,
    required this.businessMannerScore,
    required this.businessMannerFeedback,
    required this.politenessScore,
    required this.politenessFeedback,
    required this.flowOfResponseScore,
    required this.flowOfResponseFeedback,
    required this.scenarioAchievementScore,
    required this.scenarioAchievementFeedback,
  });

  factory PhonePracticeEvaluation.fromJson(Map<String, dynamic> json) {
    return PhonePracticeEvaluation(
      sessionId: json['sessionId'] as String? ?? '',
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? '',
      keyStrengths:
          (json['keyStrengths'] as List?)?.map((e) => e as String).toList() ??
          [],
      criticalImprovements:
          (json['criticalImprovements'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      nextSteps:
          (json['nextSteps'] as List?)?.map((e) => e as String).toList() ?? [],
      detailedEvaluation:
          json['detailedEvaluation'] as Map<String, dynamic>? ?? {},
      comprehensionScore: (json['comprehensionScore'] as num?)?.toInt() ?? 0,
      comprehensionFeedback: json['comprehensionFeedback'] as String? ?? '',
      businessMannerScore: (json['businessMannerScore'] as num?)?.toInt() ?? 0,
      businessMannerFeedback: json['businessMannerFeedback'] as String? ?? '',
      politenessScore: (json['politenessScore'] as num?)?.toInt() ?? 0,
      politenessFeedback: json['politenessFeedback'] as String? ?? '',
      flowOfResponseScore: (json['flowOfResponseScore'] as num?)?.toInt() ?? 0,
      flowOfResponseFeedback: json['flowOfResponseFeedback'] as String? ?? '',
      scenarioAchievementScore:
          (json['scenarioAchievementScore'] as num?)?.toInt() ?? 0,
      scenarioAchievementFeedback:
          json['scenarioAchievementFeedback'] as String? ?? '',
    );
  }
}
