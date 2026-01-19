import 'package:bridge/02-auth/06-delete-account.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '../06-company/article_api_client.dart';
import '../06-company/16-article-list.dart';
import '../06-company/18-article-detail.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart'; // セッション保存用
import '../08-thread/thread_api_client.dart';
import 'package:bridge/08-thread/33-thread-unofficial-detail.dart';
import 'package:bridge/08-thread/thread_model.dart';

class CompanyHome extends StatefulWidget {
  final String? initialMessage;
  const CompanyHome({Key? key, this.initialMessage}) : super(key: key);

  @override
  State<CompanyHome> createState() => _CompanyHomeState();
}

class _CompanyHomeState extends State<CompanyHome>
  with SingleTickerProviderStateMixin {
    List<Thread> officialThreads = [];
    List<Thread> hotUnofficialThreads = [];
    static const Color textCyanDark = Color.fromARGB(255, 2, 44, 61);
    // API呼び出し　並び替え　上位３件に絞り込み
    Future<List<Thread>> fetchTop3UnofficialThreads() async {
      final threads = await ThreadApiClient.getAllThreads();
      final unofficial = threads.where((t) => t.type == 2 && (t.entryCriteria == userType || t.entryCriteria == 1)).toList();
      unofficial.sort((a, b) {
        final aTime = a.lastCommentDate ?? DateTime(2000);
        final bTime = b.lastCommentDate ?? DateTime(2000);
        return bTime.compareTo(aTime); // 新しい順
      });
      return unofficial.take(3).toList();
    }
     //ユーザ情報取得
    int? userType;
    Future<void> _loadUserData() async {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('current_user');
      if (jsonString == null) return;
      final userData = jsonDecode(jsonString);
      setState(() {
        userType = userData['type']+1;
      });
    }

    Future<void> _init() async {
      await _loadUserData();   //ユーザ取得
      print("iiiiiiiiii");
      print(userType);
    }

  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // タブ5個
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
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
                    FutureBuilder<List<Thread>>(
                      future: fetchTop3UnofficialThreads(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Text('スレッド取得エラー');
                        }
                        final threads = snapshot.data ?? [];
                        if (threads.isEmpty) {
                          return Text('表示できるスレッドがありません');
                        }
                        return Column(
                          children: threads.map((t) {
                            return Column(
                               children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ThreadUnOfficialDetail(
                                        thread: {'id': t.id, 'title': t.title},
                                      ),
                                    ),
                                  );
                                },
                                //説明文の表示
                                child: Card(
                                  child: ListTile(
                                    title: Text(
                                      t.title,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(
                                      t.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey[700]),
                                    ),
                                    trailing: Text(
                                      t.timeAgo,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),

                            ],
                            );
                          }).toList(),
                        );
                      },
                    ),
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
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    companyName,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Row(
            children: [
              const Icon(
                Icons.thumb_up_alt_outlined,
                size: 16,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 2),
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
// PC用記事ページャー (3枚ずつ表示)
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
