import 'package:bridge/02-auth/06-delete-account.dart';
import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class StudentWorkerHome extends StatefulWidget {
  const StudentWorkerHome({Key? key}) : super(key: key);

  @override
  State<StudentWorkerHome> createState() => _StudentWorkerHomeState();
}

class _StudentWorkerHomeState extends State<StudentWorkerHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // タブ5個
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTopPageTab(context),
          Center(child: Text('タブ2の内容')),
          Center(child: Text('タブ3の内容')),
          Center(child: Text('タブ4の内容')),
          Center(child: Text('タブ5の内容')),
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

  // ダミー記事リスト（12件）
  final articles = List.generate(
    12,
    (i) => {
      "title": "株式会社${String.fromCharCode(65 + i)} 説明会",
      "description": "#説明会開催中,#会社紹介\n${i + 1}番目の記事の説明テキストです。",
      "link": "https://example.com/${i + 1}"
    },
  );

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCyanDark),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('>スレッド一覧',
                  style: TextStyle(
                    color: textCyanDark,
                  )
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildThreadCard(
                title: 'これは、学生・社会人トップです。',
                time: '1分前',
              ),
              const SizedBox(height: 12),
              _buildThreadCard(
                title: '株式会社AAAーフリースレッド',
                time: '2分前',
              ),
              const SizedBox(height: 12),
              _buildThreadCard(
                title: '学生×社会人スレッド',
                time: '7分前',
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textCyanDark),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('>記事一覧',
                  style: TextStyle(
                    color: textCyanDark,
                  )
                ),
              ),
            ],
          ),
        ),

        // スマホ: 横スクロール / PC: PageView＋ボタン（3枚ずつ）
        SizedBox(
          height: 260,
          child: isMobile
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final a = articles[i];
                    return _buildArticleCard(
                      title: a["title"]!,
                      description: a["description"]!,
                      link: a["link"]!,
                    );
                  },
                )
              : _ArticlePager(articles: articles),
        ),

        const SizedBox(height: 24),
      ],
    ),
  );
}

// =====================
// スレッドカード
// =====================
Widget _buildThreadCard({
  required String title,
  required String time,
}) {
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

// =====================
// 記事カード
// =====================
Widget _buildArticleCard({
  required String title,
  required String description,
  required String link,
}) {
  return Container(
    width: 280,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.teal[300]!),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Text(description,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 3,
            overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

// =====================
// PC用記事ページャー (3枚ずつ表示)
// =====================
class _ArticlePager extends StatefulWidget {
  final List<Map<String, String>> articles;
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
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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
                children: pageArticles
                    .map((a) => _buildArticleCard(
                          title: a["title"]!,
                          description: a["description"]!,
                          link: a["link"]!,
                        ))
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
