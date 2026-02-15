import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'package:bridge/11-common/60-ScreenWrapper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import '28-quiz-question.dart';
import '../06-company/photo_api_client.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 追加

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      appBar: BridgeHeader(),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'クイズコースを選択',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              _buildCourseCard(
                context,
                'お好みコース',
                '好きな問題数を設定して始められます\n自分のペースで学習したい方におすすめ',
                Icons.favorite,
                Colors.red,
                () => showNumberInputDialog(
                  context: context,
                  title: '問題数を設定',
                  message: '挑戦する問題数を入力してください',
                  initialValue: 10,
                  minValue: 1,
                  maxValue: 100,
                  onConfirm: (questionCount) {
                    _startQuiz(context, questionCount, 'お好みコース');
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildCourseCard(
                context,
                '30問コース',
                '30問連続で挑戦します\n結果は記録され、自分の成長を確認できます',
                Icons.assignment,
                Colors.green,
                () => _startQuiz(context, 30, '30問コース'),
              ),
              const SizedBox(height: 20),
              _buildCourseCard(
                context,
                'エンドレスコース',
                '終わりのないチャレンジ\n満足いくまで続けられます',
                Icons.all_inclusive,
                Colors.orange,
                () => _startEndlessQuiz(context),
              ),

              const SizedBox(height: 40),
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 20),
              _buildCourseCard(
                context,
                'ランキング',
                '全国のユーザーと正答数を競いましょう！\n上位入賞を目指して頑張ってください',
                Icons.emoji_events,
                Colors.amber.shade700,
                () => _openRanking(context),
                isRanking: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isRanking = false,
  }) {
    return Card(
      elevation: isRanking ? 8 : 4,
      shadowColor: isRanking ? color.withOpacity(0.4) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isRanking
                ? BorderSide(color: color.withOpacity(0.5), width: 2)
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isRanking ? color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isRanking ? color : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startQuiz(BuildContext context, int questionCount, String courseType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizScreen(
              questionCount: questionCount,
              courseType: courseType,
            ),
      ),
    );
  }

  void _startEndlessQuiz(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => QuizScreen(questionCount: 0, courseType: 'エンドレスコース'),
      ),
    );
  }

  void _openRanking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RankingScreen()),
    );
  }
}

// ================= 改良版 RankingScreen =================
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _rankingData = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchRankingData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRankingData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/quiz/ranking'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(
          utf8.decode(response.bodyBytes),
        );

        // 各ユーザーのアイコン情報を並列取得
        final futures =
            jsonResponse.map((item) async {
              String iconPath = '';
              if (item['userId'] != null) {
                try {
                  final userResponse = await http.get(
                    Uri.parse(
                      '${ApiConfig.baseUrl}/api/users/${item['userId']}',
                    ),
                    headers: {'Content-Type': 'application/json'},
                  );
                  if (userResponse.statusCode == 200) {
                    final userData = json.decode(
                      utf8.decode(userResponse.bodyBytes),
                    );
                    if (userData['icon'] != null) {
                      final photo = await PhotoApiClient.getPhotoById(
                        userData['icon'],
                      );
                      if (photo?.photoPath?.isNotEmpty == true) {
                        iconPath = photo!.photoPath!;
                      }
                    }
                  }
                } catch (e) {
                  // アイコン取得失敗は無視
                }
              }
              return {
                'name': item['nickname'] ?? '名無し',
                'score': item['score'] ?? 0,
                'iconPath': iconPath,
                'avatarColor': GlobalActions.getColorFromName(
                  item['nickname'] ?? '名無し',
                ),
              };
            }).toList();

        final results = await Future.wait(futures);
        setState(() {
          _rankingData = results;
        });
      } else {
        _errorMessage = 'ランキングデータの取得に失敗しました: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'エラーが発生しました: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return ScreenWrapper(
      appBar: BridgeHeader(),
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            // ヘッダー部分
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 50,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '正解数ランキング',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Top 10 Players',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _isLoading
                      ? _buildLoading()
                      : _errorMessage.isNotEmpty
                      ? _buildError()
                      : _rankingData.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                        onRefresh: _fetchRankingData,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    isSmallScreen ? 16 : screenWidth * 0.2,
                                vertical: 16,
                              ),
                              itemCount: math.min(_rankingData.length, 10),
                              itemBuilder: (context, index) {
                                final data = _rankingData[index];
                                final rank = index + 1;
                                return _buildAnimatedRankingItem(
                                  rank: rank,
                                  iconPath: data['iconPath'],
                                  name: data['name'],
                                  score: data['score'],
                                  avatarColor: data['avatarColor'],
                                  isSmallScreen: isSmallScreen,
                                );
                              },
                            );
                          },
                        ),
                      ),
            ),
            // 戻るボタン
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
                child: const Text('コース選択に戻る', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          Text('ランキングを読み込み中...', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: TextStyle(fontSize: 18, color: Colors.grey[800]),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchRankingData,
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ランキングデータがありません',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedRankingItem({
    required int rank,
    required String name,
    required int score,
    required Color avatarColor,
    required String iconPath,
    required bool isSmallScreen,
  }) {
    // 順位に応じた色とアイコン
    Color rankColor;
    IconData rankIcon;
    double baseElevation;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700);
      rankIcon = Icons.stars;
      baseElevation = 8;
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0);
      rankIcon = Icons.star;
      baseElevation = 6;
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32);
      rankIcon = Icons.star_half;
      baseElevation = 4;
    } else {
      rankColor = Colors.grey.shade400;
      rankIcon = Icons.circle;
      baseElevation = 2;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (rank * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
      child: MouseRegion(
        onEnter: (_) => _animationController.forward(),
        onExit: (_) => _animationController.reverse(),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final elevation = baseElevation + _animationController.value * 4;
            final scale = 1.0 + _animationController.value * 0.02;
            return Transform.scale(
              scale: scale,
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: elevation,
                shadowColor: rank <= 3 ? rankColor.withOpacity(0.3) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side:
                      rank <= 3
                          ? BorderSide(color: rankColor, width: 2)
                          : BorderSide.none,
                ),
                child: Container(
                  decoration:
                      rank <= 3
                          ? BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                rankColor.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          )
                          : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // 順位バッジ
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: rankColor.withOpacity(0.2),
                          ),
                          child: Center(
                            child:
                                rank <= 3
                                    ? Icon(rankIcon, color: rankColor, size: 24)
                                    : Text(
                                      '$rank',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // アバター
                        CircleAvatar(
                          radius: isSmallScreen ? 20 : 24,
                          backgroundColor: avatarColor.withOpacity(0.2),
                          backgroundImage:
                              iconPath.isNotEmpty
                                  ? CachedNetworkImageProvider(iconPath)
                                  : null,
                          child:
                              iconPath.isEmpty
                                  ? Text(
                                    name.isNotEmpty
                                        ? name.substring(0, 1)
                                        : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 16 : 18,
                                    ),
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 16),

                        // 名前
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight:
                                  rank <= 3
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // スコア + プログレスバー
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.green.shade400,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 80,
                              child: LinearProgressIndicator(
                                value: score / 100, // 仮の最大値100として表示
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  rank <= 3 ? rankColor : Colors.blue.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
