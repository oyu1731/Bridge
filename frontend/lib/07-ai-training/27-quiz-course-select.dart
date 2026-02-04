import 'package:bridge/11-common/api_config.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/59-global-method.dart';
import 'package:bridge/11-common/60-ScreenWrapper.dart';
import 'package:http/http.dart' as http; // HTTP リクエストのため追加
import 'dart:convert'; // JSON エンコード/デコードのため追加
import '28-quiz-question.dart';
import 'dart:js' as js; // JavaScript との連携のため追加
import '../06-company/photo_api_client.dart';

class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({super.key});

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  // 状態変数はVoiceSettingDialogに移動するため削除

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

              // --- 各コースカード ---
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

              // --- ランキングボタン（区切り線を入れて強調） ---
              const Divider(thickness: 1, color: Colors.grey),
              const SizedBox(height: 20),
              _buildCourseCard(
                context,
                'ランキング',
                '全国のユーザーと正答数を競いましょう！\n上位入賞を目指して頑張ってください',
                Icons.emoji_events, // トロフィーアイコン
                Colors.amber.shade700, // ゴールドっぽい色
                () => _openRanking(context),
                isRanking: true, // デザインを少し変えるためのフラグ
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
      elevation: isRanking ? 8 : 4, // ランキングは少し影を強くして目立たせる
      shadowColor: isRanking ? color.withOpacity(0.4) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isRanking
                ? BorderSide(color: color.withOpacity(0.5), width: 2)
                : BorderSide.none, // ランキングは枠線をつける
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

  // ランキング画面へ遷移
  void _openRanking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RankingScreen()),
    );
  }
}

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Map<String, dynamic>> _rankingData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRankingData();
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

        final List<Map<String, dynamic>> temp = [];

        for (final item in jsonResponse) {
          String iconPath = '';

          // user_idからユーザー情報を取得
          if (item['userId'] != null) {
            try {
              final userResponse = await http.get(
                Uri.parse('${ApiConfig.baseUrl}/api/users/${item['userId']}'),
                headers: {'Content-Type': 'application/json'},
              );

              if (userResponse.statusCode == 200) {
                final userData = json.decode(
                  utf8.decode(userResponse.bodyBytes),
                );

                // icon_idを取得
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
              // エラーの場合はアイコン取得をスキップ
            }
          }

          temp.add({
            'name': item['nickname'] ?? '名無し',
            'score': item['score'] ?? 0,
            'iconPath': iconPath,
            'avatarColor': GlobalActions.getColorFromName(
              item['nickname'] ?? '名無し',
            ),
          });
        }

        setState(() {
          _rankingData = temp;
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
    return ScreenWrapper(
      appBar: BridgeHeader(),
      backgroundColor: Colors.grey[50],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 40,
                  color: Colors.amber,
                ),
                const SizedBox(height: 8),
                const Text(
                  '正解数ランキング',
                  style: TextStyle(
                    fontSize: 22,
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
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text('エラー: $_errorMessage'))
                    : RefreshIndicator(
                      // 引っ張って更新機能を追加
                      onRefresh: _fetchRankingData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _rankingData.length,
                        itemBuilder: (context, index) {
                          final data = _rankingData[index];
                          final rank = index + 1;
                          return _buildRankingItem(
                            rank: rank,
                            iconPath: data['iconPath'],
                            name: data['name'],
                            score: data['score'],
                            avatarColor: data['avatarColor'],
                          );
                        },
                      ),
                    ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // ランキング画面を閉じて前の画面（コース選択）に戻る
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50), // ボタンの高さを設定
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('コース選択に戻る', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem({
    required int rank,
    required String name,
    required int score,
    required Color avatarColor,
    required String iconPath,
  }) {
    Color? rankColor;
    IconData? rankIcon;
    double elevation = 1;
    double scale = 1.0;

    switch (rank) {
      case 1:
        rankColor = const Color(0xFFFFD700);
        rankIcon = Icons.workspace_premium;
        elevation = 4;
        scale = 1.05;
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0);
        rankIcon = Icons.looks_two;
        elevation = 3;
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32);
        rankIcon = Icons.looks_3;
        elevation = 2;
        break;
      default:
        rankColor = Colors.grey[400];
        elevation = 0.5;
    }

    return Transform.scale(
      scale: scale,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: elevation,
        shadowColor: rank <= 3 ? rankColor!.withOpacity(0.4) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              rank <= 3
                  ? BorderSide(color: rankColor!, width: 1.5)
                  : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child:
                    rank <= 3
                        ? Icon(rankIcon, color: rankColor, size: 32)
                        : Text(
                          '$rank',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
              ),
              const SizedBox(width: 12),

              // ===== アイコン表示（ここが本題）=====
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor.withOpacity(0.2),
                backgroundImage:
                    iconPath.isNotEmpty ? NetworkImage(iconPath) : null,
                child:
                    iconPath.isEmpty
                        ? Text(
                          name.isNotEmpty ? name.substring(0, 1) : '?',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                        : null,
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$score問',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Text(
                    '正解',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
