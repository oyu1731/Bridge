import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart'; // ★ 追加
import 'package:share_plus/share_plus.dart' show XFile; // XFileのために追加
import '27-quiz-course-select.dart';
import 'dart:typed_data'; // Uint8Listのために追加

// StatefulWidgetに変更
class ResultScreen extends StatefulWidget {
  final int totalQuestions;
  final int correctAnswers;
  final String courseType;

  const ResultScreen({
    super.key,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.courseType,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  RankInfo _calculateRank(double rate) {
    final double score = rate * 100;
    final List<RankDefinition> ranks = [
      RankDefinition(
        level: 1,
        title: 'ビギナー',
        description: 'これからが楽しみです！基礎を固めましょう',
        minScore: 0,
        maxScore: 20,
        icon: Icons.emoji_people,
        gradientColors: [Color(0xFF6B7280), Color(0xFF4B5563)],
      ),
      RankDefinition(
        level: 2,
        title: 'ブロンズ',
        description: '基礎が身についてきました！継続が力になります',
        minScore: 21,
        maxScore: 40,
        icon: Icons.looks_one,
        gradientColors: [Color(0xFF92400E), Color(0xFF78350F)],
      ),
      RankDefinition(
        level: 3,
        title: 'シルバー',
        description: '確実に成長しています！応用にも挑戦しましょう',
        minScore: 41,
        maxScore: 60,
        icon: Icons.looks_two,
        gradientColors: [Color(0xFF374151), Color(0xFF1F2937)],
      ),
      RankDefinition(
        level: 4,
        title: 'ゴールド',
        description: '優秀な実力です！さらに高みを目指しましょう',
        minScore: 61,
        maxScore: 75,
        icon: Icons.looks_3,
        gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
      RankDefinition(
        level: 5,
        title: 'プラチナ',
        description: '高いスキルを持っています！プロレベルまであと少し',
        minScore: 76,
        maxScore: 90,
        icon: Icons.looks_4,
        gradientColors: [Color(0xFF6EE7B7), Color(0xFF10B981)],
      ),
      RankDefinition(
        level: 6,
        title: 'ダイヤモンド',
        description: '卓越した知識の持ち主です！あなたはエキスパート',
        minScore: 91,
        maxScore: 98,
        icon: Icons.looks_5,
        gradientColors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      ),
      RankDefinition(
        level: 7,
        title: 'マスター',
        description: '完璧な理解力！あなたは真の達人です',
        minScore: 99,
        maxScore: 100,
        icon: Icons.verified_user,
        gradientColors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      ),
    ];

    RankDefinition currentRank = ranks.first;
    for (final rank in ranks) {
      if (score >= rank.minScore && score <= rank.maxScore) {
        currentRank = rank;
        break;
      }
    }

    final int currentIndex = ranks.indexOf(currentRank);
    final RankDefinition? nextRank =
        currentIndex < ranks.length - 1 ? ranks[currentIndex + 1] : null;

    final double progressToNextRank =
        nextRank != null
            ? (score - currentRank.minScore) /
                (nextRank.minScore - currentRank.minScore)
            : 1.0;

    return RankInfo(
      title: currentRank.title,
      description: currentRank.description,
      level: currentRank.level,
      icon: currentRank.icon,
      gradientColors: currentRank.gradientColors,
      nextRankInfo: nextRank,
      progressToNextRank: progressToNextRank.clamp(0.0, 1.0),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double correctRate =
        widget.totalQuestions > 0
            ? widget.correctAnswers / widget.totalQuestions
            : 0;
    final RankInfo rankInfo = _calculateRank(correctRate);

    return Scaffold(
      appBar: BridgeHeader(),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // 完了メッセージ
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '${widget.courseType} コース完了！',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'お疲れ様でした！あなたの結果はこちらです',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // メイン結果カード
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 正解数
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        value: '${widget.correctAnswers}',
                        label: '正解数',
                        icon: Icons.check_circle,
                        color: Colors.white,
                      ),
                      _buildStatCard(
                        value: '${(correctRate * 100).toStringAsFixed(1)}%',
                        label: '正答率',
                        icon: Icons.bar_chart,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 進捗バー
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '進捗',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          Text(
                            '${(correctRate * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 16,
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
                              flex: (correctRate * 100).round(),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF10B981),
                                      Color(0xFF34D399),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 100 - (correctRate * 100).round(),
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

            const SizedBox(height: 32),

            // 称号カード
            Container(
              padding: const EdgeInsets.all(24),
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
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 称号アイコン
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(rankInfo.icon, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // 称号名
                  Text(
                    rankInfo.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 称号説明
                  Text(
                    rankInfo.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // レベル表示
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'レベル ${rankInfo.level}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 次のレベルまでの進捗（次の称号がある場合）
            if (rankInfo.nextRankInfo != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '次の称号まで',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: rankInfo.progressToNextRank,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              rankInfo.gradientColors.first,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(rankInfo.progressToNextRank * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'あと${(rankInfo.nextRankInfo!.minScore - correctRate * 100).abs().toStringAsFixed(1)}%で${rankInfo.nextRankInfo!.title}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // アクションボタン
            Column(
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CourseSelectionScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.home, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'コース選択に戻る',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// RankDefinitionとRankInfoはそのまま使用します

class RankDefinition {
  final int level;
  final String title;
  final String description;
  final double minScore;
  final double maxScore;
  final IconData icon;
  final List<Color> gradientColors;

  RankDefinition({
    required this.level,
    required this.title,
    required this.description,
    required this.minScore,
    required this.maxScore,
    required this.icon,
    required this.gradientColors,
  });
}

class RankInfo {
  final String title;
  final String description;
  final int level;
  final IconData icon;
  final List<Color> gradientColors;
  final RankDefinition? nextRankInfo;
  final double progressToNextRank;

  RankInfo({
    required this.title,
    required this.description,
    required this.level,
    required this.icon,
    required this.gradientColors,
    this.nextRankInfo,
    required this.progressToNextRank,
  });
}
