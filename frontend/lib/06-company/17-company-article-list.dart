import 'package:flutter/material.dart';
import '18-article-detail.dart';
import '20-company-article-edit.dart';
import '../11-common/58-header.dart';

class CompanyArticleListPage extends StatefulWidget {
  @override
  _CompanyArticleListPageState createState() => _CompanyArticleListPageState();
}

class _CompanyArticleListPageState extends State<CompanyArticleListPage> {
  final TextEditingController _searchController = TextEditingController();

  // サンプルの投稿記事データ
  final List<Map<String, dynamic>> _articles = [
    {
      'id': '1',
      'title': '【株式会社AAA】【選考あり】会社説明会のご案内',
      'description': '弊社では、随時オンライン会社説明会を開催中です。定期的にあるマイナビもしくはリクナビのリンクからエントリーください！エントリーお待ちしております！',
      'tag': '#説明会開催中,#会社紹介',
      'isActive': true,
      'hasPreview': true,
      'hasEdit': true,
    },
    {
      'id': '2',
      'title': '【株式会社AAA】スレッドを開設しました。',
      'description': '弊社の交流スレッドを作成いたしました！質問においても気になることや、弊社に対する質問など気軽に投稿してくださいね♪\n\nスレッドタイトルは【株式会社AAA～フリースレッド】です！',
      'tag': '#スレッド開設',
      'isActive': true,
      'hasPreview': true,
      'hasEdit': true,
    },
  ];

  List<Map<String, dynamic>> _filteredArticles = [];

  @override
  void initState() {
    super.initState();
    _filteredArticles = List.from(_articles);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildArticleList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '記事検索',
                  hintStyle: TextStyle(
                    color: Color(0xFF9E9E9E),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: TextStyle(fontSize: 14),
                onChanged: _filterArticles,
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xFF1976D2),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              child: Icon(
                Icons.search,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '投稿記事一覧',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: _filteredArticles.map((article) => _buildArticleCard(article)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              article['title'],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            // タグ
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                article['tag'],
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 16),
            // 説明文
            Text(
              article['description'],
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF616161),
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 20),
            // ボタン行
            Row(
              children: [
                if (article['hasPreview'])
                  _buildActionButton(
                    'プレビュー',
                    Color(0xFFFF9800),
                    () => _navigateToArticleDetail(article),
                  ),
                if (article['hasEdit']) ...[
                  if (article['hasPreview']) SizedBox(width: 12),
                  _buildActionButton(
                    '編集',
                    Color(0xFF1976D2),
                    () => _editArticle(article),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _filterArticles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredArticles = List.from(_articles);
      } else {
        _filteredArticles = _articles
            .where((article) =>
                article['title'].toLowerCase().contains(query.toLowerCase()) ||
                article['description'].toLowerCase().contains(query.toLowerCase()) ||
                article['tag'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _navigateToArticleDetail(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(
          articleTitle: article['title'],
          articleId: article['id'],
        ),
      ),
    );
  }

  void _editArticle(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleEditPage(
          articleId: article['id'],
          initialTitle: article['title'],
          initialTags: article['tag'].split(','),
          initialImages: [], // 既存画像があれば設定
          initialContent: article['description'],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}