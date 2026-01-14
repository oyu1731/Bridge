import 'package:bridge/02-auth/06-delete-account.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import 'package:bridge/11-common/59-global-method.dart'; // loadUserSession 等のため
import 'package:shared_preferences/shared_preferences.dart'; // セッション保存用
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../06-company/article_api_client.dart';
import '../06-company/16-article-list.dart';
import '../06-company/18-article-detail.dart';

class StudentWorkerHome extends StatefulWidget {
  final String? initialMessage;
  const StudentWorkerHome({Key? key, this.initialMessage}) : super(key: key);

  @override
  State<StudentWorkerHome> createState() => _StudentWorkerHomeState();
}

class _StudentWorkerHomeState extends State<StudentWorkerHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalActions _globalActions = GlobalActions(); // グローバルアクション利用
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // ホーム表示時にリアルタイムで状態を更新する
    _refreshUserStatus();
  }

  /// サーバーから最新のプラン状態を取得し、セッションを更新する
  Future<void> _refreshUserStatus() async {
    // 1. 現在のローカルセッションを読み込む
    _user = await _globalActions.loadUserSession();

    if (_user != null && _user!['id'] != null) {
      final userId = _user!['id'];

      try {
        // 2. サーバーから最新の planStatus を取得
        final response = await http
            .get(
              Uri.parse(
                "http://localhost:8080/api/subscriptions/status/$userId",
              ),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final String latestStatus = response.body;
          print('ホーム画面：最新ステータスを取得 -> $latestStatus');

          // 3. セッション情報(SharedPreferences)を更新
          final prefs = await SharedPreferences.getInstance();
          _user!['planStatus'] = latestStatus; // メモリ上のデータを更新
          await prefs.setString('current_user', jsonEncode(_user)); // 保存

          if (mounted) {
            setState(() {}); // 画面再描画
          }
        }
      } catch (e) {
        print('ホーム画面：リアルタイム更新に失敗しました: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 統一カラー
  static const Color cyanDark = Color.fromARGB(255, 0, 100, 120);
  static const Color cyanMedium = Color.fromARGB(255, 24, 147, 178);
  static const Color errororange = Color.fromARGB(255, 239, 108, 0);
  static const Color textCyanDark = Color.fromARGB(255, 6, 62, 85);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
        children: [
          if (widget.initialMessage != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.initialMessage ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTopPageTab(context),
                Center(child: Text('タブ2の内容')),
                Center(child: Text('タブ3の内容')),
                Center(child: Text('タブ4の内容')),
                Center(child: Text('タブ5の内容')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================
// トップページタブ
// =====================
Widget _buildTopPageTab(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  return FutureBuilder<List<ArticleDTO>>(
    future: ArticleApiClient.getAllArticles(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('記事の取得に失敗しました'));
      }
      final articles = snapshot.data ?? [];
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 最新スレッド
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '最新スレッド',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textCyanDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      '>スレッド一覧',
                      style: TextStyle(color: textCyanDark),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildThreadCard(title: 'これは、学生・社会人トップです。', time: '1分前'),
                  const SizedBox(height: 12),
                  _buildThreadCard(title: '株式会社AAAーフリースレッド', time: '2分前'),
                  const SizedBox(height: 12),
                  _buildThreadCard(title: '学生×社会人スレッド', time: '7分前'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 注目記事
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '注目記事',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textCyanDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ArticleListPage()),
                      );
                    },
                    child: const Text(
                      '>記事一覧',
                      style: TextStyle(color: textCyanDark),
                    ),
                  ),
                ],
              ),
            ),

            // スマホ: 横スクロール / PC: PageView＋ボタン（3枚ずつ）
            SizedBox(
              height: 260,
              child:
                  isMobile
                      ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: articles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemBuilder: (context, i) {
                          final a = articles[i];
                          return _buildArticleCard(
                            title: a.title,
                            companyName: a.companyName ?? '',
                            totalLikes: a.totalLikes ?? 0,
                            link: '',
                            onTitleTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ArticleDetailPage(
                                        articleTitle: a.title,
                                        articleId: a.id?.toString() ?? '',
                                        companyName: a.companyName,
                                        description: a.description,
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      )
                      : _ArticlePager(
                        articles:
                            articles
                                .map(
                                  (a) => {
                                    "title": a.title,
                                    "companyName": a.companyName ?? '',
                                    "totalLikes": a.totalLikes ?? 0,
                                    "link": '',
                                    "onTitleTap": () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => ArticleDetailPage(
                                                articleTitle: a.title,
                                                articleId:
                                                    a.id?.toString() ?? '',
                                                companyName: a.companyName,
                                                description: a.description,
                                              ),
                                        ),
                                      );
                                    },
                                  },
                                )
                                .toList(),
                      ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}

// =====================
// スレッドカード
// =====================
Widget _buildThreadCard({required String title, required String time}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Text(time, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    ),
  );
}

// =====================
// 記事カード
// =====================
Widget _buildArticleCard({
  required String title,
  required String companyName,
  required int totalLikes,
  required String link,
  VoidCallback? onTitleTap,
}) {
  return Container(
    width: 280,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.teal[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onTitleTap,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              companyName,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Row(
            children: [
              const Icon(Icons.thumb_up, size: 16, color: Colors.redAccent),
              const SizedBox(width: 4),
              Text(
                '$totalLikes',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// =====================
// PC用記事ページアー (3枚ずつ表示)
// =====================
class _ArticlePager extends StatefulWidget {
  final List<Map<String, dynamic>> articles;
  const _ArticlePager({required this.articles});

  @override
  State<_ArticlePager> createState() => _ArticlePagerState();
}

class _ArticlePagerState extends State<_ArticlePager> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < (widget.articles.length / 3).ceil() - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (widget.articles.length / 3).ceil();

    return Row(
      children: [
        IconButton(onPressed: _prevPage, icon: const Icon(Icons.arrow_back)),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: totalPages,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, pageIndex) {
              final start = pageIndex * 3;
              final end = (start + 3).clamp(0, widget.articles.length);
              final pageArticles = widget.articles.sublist(start, end);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    pageArticles
                        .map(
                          (a) => _buildArticleCard(
                            title: a["title"] ?? '',
                            companyName: a["companyName"] ?? '',
                            totalLikes: a["totalLikes"] ?? 0,
                            link: a["link"] ?? '',
                            onTitleTap: a["onTitleTap"],
                          ),
                        )
                        .toList(),
              );
            },
          ),
        ),
        IconButton(onPressed: _nextPage, icon: const Icon(Icons.arrow_forward)),
      ],
    );
  }
}
