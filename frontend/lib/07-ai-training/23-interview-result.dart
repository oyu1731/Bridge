import 'package:bridge/07-ai-training/21-ai-training-list.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:bridge/11-common/58-header.dart';

class InterviewResultPage extends StatelessWidget {
  final String evaluationJson;

  const InterviewResultPage({Key? key, required this.evaluationJson})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final InterviewEvaluation evaluation = InterviewEvaluation.fromJson(
      json.decode(evaluationJson),
    );

    return Scaffold(
      appBar: BridgeHeader(),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallAssessment(evaluation),
            const SizedBox(height: 24),
            ...evaluation.evaluations
                .map((e) => _buildEvaluationItem(e))
                .toList(),
            const SizedBox(height: 24),
            _buildOverallReview(evaluation.overallAssessment),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildOverallAssessment(InterviewEvaluation evaluation) {
    final score = evaluation.totalCalculatedScore;
    final maxScore = evaluation.maxPossibleScore;
    final scaledScore = (maxScore == 0) ? 0 : (score / maxScore * 100).round();
    const displayMaxScore = 100;
    final passRate = (scaledScore / displayMaxScore * 100).toStringAsFixed(0);
    final RankInfo rankInfo = _calculateRank(scaledScore);

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
                  '面接結果',
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
                  value: '$scaledScore',
                  label: '総合スコア',
                  maxValue: '$displayMaxScore',
                  color: Colors.white,
                ),
                _buildScoreCard(
                  value: '$passRate',
                  label: '合格率',
                  maxValue: '%',
                  color: Colors.white,
                ),
                _buildScoreCard(
                  value: evaluation.averageNormalizedScore.toStringAsFixed(1),
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
                      '$scaledScore%',
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
                        flex: scaledScore,
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
                        flex: 100 - scaledScore,
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

  Widget _buildEvaluationItem(Evaluation evaluation) {
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
            // 質問
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.question_answer,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    evaluation.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 回答
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'あなたの回答:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    evaluation.answer,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 評価項目
            const Text(
              '評価項目',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            _buildScoreRow('論理性', evaluation.scores.logicNormalized),
            _buildScoreRow('企業適合性', evaluation.scores.companyFitNormalized),
            _buildScoreRow('表現力', evaluation.scores.expressionNormalized),
            _buildScoreRow(
              '面接応答',
              evaluation.scores.interviewResponseNormalized,
            ),
            const SizedBox(height: 16),

            // フィードバック
            if (evaluation.detailedFeedback.strengths.isNotEmpty)
              _buildFeedbackSection(
                '強み',
                Icons.thumb_up,
                const Color(0xFF10B981),
                evaluation.detailedFeedback.strengths,
              ),
            if (evaluation.detailedFeedback.weaknesses.isNotEmpty)
              _buildFeedbackSection(
                '改善点',
                Icons.thumb_down,
                const Color(0xFFEF4444),
                evaluation.detailedFeedback.weaknesses,
              ),
            _buildFeedbackSection(
              'アドバイス',
              Icons.lightbulb,
              const Color(0xFFF59E0B),
              [evaluation.detailedFeedback.improvementAdvice],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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
                                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
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
    );
  }

  Widget _buildFeedbackSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Color(0xFF64748B))),
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
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildOverallReview(OverallAssessment overallAssessment) {
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
                overallAssessment.summary,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF0C4A6E),
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (overallAssessment.keyStrengths.isNotEmpty)
              _buildReviewSection(
                '主要な強み',
                Icons.verified,
                const Color(0xFF10B981),
                overallAssessment.keyStrengths,
              ),
            if (overallAssessment.developmentAreas.isNotEmpty)
              _buildReviewSection(
                '改善点',
                Icons.trending_up,
                const Color(0xFFF59E0B),
                overallAssessment.developmentAreas,
              ),
            if (overallAssessment.nextInterviewTips.isNotEmpty)
              _buildReviewSection(
                '次回の面接へのヒント',
                Icons.tips_and_updates,
                const Color(0xFF6366F1),
                overallAssessment.nextInterviewTips,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewSection(
    String title,
    IconData icon,
    Color color,
    List<String> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
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
                Icon(Icons.arrow_forward_ios, size: 12, color: color),
                const SizedBox(width: 8),
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
        const SizedBox(height: 16),
      ],
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
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.replay, size: 20),
              label: const Text('もう一度面接'),
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
    print('結果をシェア');
    // Share.share('面接練習の結果をシェアします！');
  }

  String _buildStarRating(int score, {int maxStars = 5}) {
    final filledStars = '★' * score;
    final emptyStars = '☆' * (maxStars - score);
    return filledStars + emptyStars;
  }

  RankInfo _calculateRank(int score) {
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

class InterviewEvaluation {
  final List<Evaluation> evaluations;
  final OverallAssessment overallAssessment;

  InterviewEvaluation({
    required this.evaluations,
    required this.overallAssessment,
  });

  factory InterviewEvaluation.fromJson(Map<String, dynamic> json) {
    return InterviewEvaluation(
      evaluations:
          (json['evaluations'] as List?)
              ?.map((e) => Evaluation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      overallAssessment: OverallAssessment.fromJson(
        json['overall_assessment'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  String toJson() => json.encode(toMap());

  Map<String, dynamic> toMap() => {
    "evaluations": evaluations.map((e) => e.toMap()).toList(),
    "overall_assessment": overallAssessment.toMap(),
  };

  /// 総合スコアを計算
  int get totalCalculatedScore {
    return evaluations.fold(0, (sum, evaluation) {
      return sum +
          evaluation.scores.logic +
          evaluation.scores.companyFit +
          evaluation.scores.expression +
          evaluation.scores.interviewResponse;
    });
  }

  /// 最大可能スコア（各項目15点×5項目）
  int get maxPossibleScore {
    if (evaluations.isEmpty) return 0;
    return evaluations.length *
        (30 + 30 + 20 + 20); // 論理性30点、企業適合性30点、表現力20点、面接対応力20点
  }

  /// 5段階評価平均
  double get averageNormalizedScore {
    if (evaluations.isEmpty) return 0.0;
    int total = evaluations.fold(0, (sum, e) {
      return sum +
          e.scores.logicNormalized +
          e.scores.companyFitNormalized +
          e.scores.expressionNormalized +
          e.scores.interviewResponseNormalized;
    });
    return total / (evaluations.length * 4); // 4項目で割る (正規化されたスコアは5段階なので、項目数で割る)
  }
}

class Evaluation {
  final String question;
  final String answer;
  final Scores scores;
  final DetailedFeedback detailedFeedback;

  Evaluation({
    required this.question,
    required this.answer,
    required this.scores,
    required this.detailedFeedback,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    return Evaluation(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      scores: Scores.fromJson(
        json['score_breakdown'] as Map<String, dynamic>? ?? {},
      ),
      detailedFeedback: DetailedFeedback.fromJson(
        json['detailed_feedback'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    "question": question,
    "answer": answer,
    "scores": scores.toMap(),
    "detailed_feedback": detailedFeedback.toMap(),
  };
}

class Scores {
  final int logic;
  final int companyFit;
  final int expression;
  final int interviewResponse;

  Scores({
    required this.logic,
    required this.companyFit,
    required this.expression,
    required this.interviewResponse,
  });

  factory Scores.fromJson(Map<String, dynamic> json) {
    final data = (json['score_breakdown'] as Map<String, dynamic>?) ?? json;

    return Scores(
      logic: (data['logic'] as num?)?.toInt() ?? 0,
      companyFit: (data['company_fit'] as num?)?.toInt() ?? 0,
      expression: (data['expression'] as num?)?.toInt() ?? 0,
      interviewResponse: (data['interview_response'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    "score_breakdown": {
      "logic": logic,
      "company_fit": companyFit,
      "expression": expression,
      "interview_response": interviewResponse,
    },
  };

  // 各項目を5段階評価に正規化
  int get logicNormalized => (logic / 30 * 5).round(); // 30点満点を5段階評価に正規化
  int get companyFitNormalized =>
      (companyFit / 30 * 5).round(); // 30点満点を5段階評価に正規化
  int get expressionNormalized =>
      (expression / 20 * 5).round(); // 20点満点を5段階評価に正規化
  int get interviewResponseNormalized =>
      (interviewResponse / 20 * 5).round(); // 20点満点を5段階評価に正規化
}

class DetailedFeedback {
  final List<String> strengths;
  final List<String> weaknesses;
  final String improvementAdvice;

  DetailedFeedback({
    required this.strengths,
    required this.weaknesses,
    required this.improvementAdvice,
  });

  factory DetailedFeedback.fromJson(Map<String, dynamic> json) {
    return DetailedFeedback(
      strengths:
          (json['good_points'] as List?)?.map((e) => e as String).toList() ??
          [],
      weaknesses:
          (json['bad_points'] as List?)?.map((e) => e as String).toList() ?? [],
      improvementAdvice: json['specific_advice'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    "strengths": strengths,
    "weaknesses": weaknesses,
    "improvement_advice": improvementAdvice,
  };
}

class OverallAssessment {
  final int totalScore;
  final String summary;
  final List<String> keyStrengths;
  final List<String> developmentAreas;
  final List<String> nextInterviewTips;

  OverallAssessment({
    required this.totalScore,
    required this.summary,
    required this.keyStrengths,
    required this.developmentAreas,
    required this.nextInterviewTips,
  });

  factory OverallAssessment.fromJson(Map<String, dynamic> json) {
    return OverallAssessment(
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      summary: json['summary'] as String? ?? '',
      keyStrengths:
          (json['key_strengths'] as List?)?.map((e) => e as String).toList() ??
          [],
      developmentAreas:
          ((json['development_areas'] as List?) ??
                  (json['critical_improvements'] as List?) ??
                  [])
              .map((e) => e as String)
              .toList(),
      nextInterviewTips:
          ((json['next_interview_tips'] as List?) ??
                  (json['next_steps'] as List?) ??
                  [])
              .map((e) => e as String)
              .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    "total_score": totalScore,
    "summary": summary,
    "key_strengths": keyStrengths,
    "development_areas": developmentAreas,
    "next_interview_tips": nextInterviewTips,
  };
}

/// ---------------------------
/// Flutter でスコアを print する例
/// ---------------------------
void printScoresDemo(InterviewEvaluation eval) {
  print('===== 評価結果 =====');
  print('総合スコア: ${eval.totalCalculatedScore} / ${eval.maxPossibleScore}');
  print('5段階平均スコア: ${eval.averageNormalizedScore.toStringAsFixed(2)}');

  for (var e in eval.evaluations) {
    print('質問: ${e.question}');
    print('回答: ${e.answer}');
    print('論理性: ${e.scores.logicNormalized}');
    print('企業適合性: ${e.scores.companyFitNormalized}');
    print('表現力: ${e.scores.expressionNormalized}');
    print('面接対応力: ${e.scores.interviewResponseNormalized}');
    print('強み: ${e.detailedFeedback.strengths.join(', ')}');
    print('弱み: ${e.detailedFeedback.weaknesses.join(', ')}');
    print('改善アドバイス: ${e.detailedFeedback.improvementAdvice}');
    print('-----------------------');
  }

  print('=== 総合評価 ===');
  print('合計スコア: ${eval.overallAssessment.totalScore}');
  print('要約: ${eval.overallAssessment.summary}');
  print('強み: ${eval.overallAssessment.keyStrengths.join(', ')}');
  print('改善点: ${eval.overallAssessment.developmentAreas.join(', ')}');
  print('次回アドバイス: ${eval.overallAssessment.nextInterviewTips.join(', ')}');
}
