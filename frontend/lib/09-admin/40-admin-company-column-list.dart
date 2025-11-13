import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';
import '41-admin-company-article-detail.dart';

class AdminCompanyColumnList extends StatefulWidget {
  @override
  _AdminCompanyColumnListState createState() => _AdminCompanyColumnListState();
}

class _AdminCompanyColumnListState extends State<AdminCompanyColumnList> {
  final TextEditingController _searchController = TextEditingController();

  // サンプル記事データ
  final List<Map<String, dynamic>> _articles = [
    {
      'id': '1',
      'title': '【株式会社AAA】【選考あり】会社説明会のご案内',
      'description':
          '弊社では、随時オンライン会社説明会を開催中です。定期的にあるマイナビもしくはリクナビのリンクからエントリーください！エントリーお待ちしております！',
      'tag': '#説明会開催中,#会社紹介',
      'company': '株式会社AAA',
    },
    {
      'id': '2',
      'title': '【株式会社AAA】スレッドを開設しました。',
      'description':
          '弊社の交流スレッドを作成いたしました！質問においても気になることや、弊社に対する質問など気軽に投稿してくださいね♪\n\nスレッドタイトルは【株式会社AAA～フリースレッド】です！',
      'tag': '#スレッド開設',
      'company': '株式会社AAA',
    },
  ];

  List<Map<String, dynamic>> _filteredArticles = [];

  @override
  void initState() {
    super.initState();
    _filteredArticles = List.from(_articles);
  }

  // 検索処理
  void _onSearchPressed() {
    final query = _searchController.text.trim();
    setState(() {
      if (query.isEmpty) {
        _filteredArticles = List.from(_articles);
      } else {
        _filteredArticles = _articles
            .where((article) =>
                article['title'].toLowerCase().contains(query.toLowerCase()) ||
                article['description']
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // 削除処理（ポップアップで確認）
  void _deleteArticle(int index) async {
    bool confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('削除確認'),
        content: Text('この記事を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('削除'),
          ),
        ],
      ),
    );

    if (confirm) {
      setState(() {
        _filteredArticles.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 20),
            Column(
              children: List.generate(_filteredArticles.length, (index) {
                return _buildArticleCard(_filteredArticles[index], index);
              }),
            ),
          ],
        ),
      ),
    );
  }

  // 検索バー
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '記事検索',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          suffixIcon: IconButton(
            icon: Icon(Icons.search, color: Colors.grey[700]),
            onPressed: _onSearchPressed,
          ),
        ),
        onSubmitted: (_) => _onSearchPressed(),
      ),
    );
  }
  
  // 記事カード
  Widget _buildArticleCard(Map<String, dynamic> article, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 左側（タイトル・本文）
            Expanded(
              flex: 7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    article['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    article['description'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF616161),
                      height: 1.6,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            SizedBox(width: 16),

            // 右側（会社名・ボタン2つ）
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    article['company'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // プレビューボタン
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AdminCompanyArticleDetail(
                              articleId: article['id'],
                            )),
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFFFF3E0), // 淡いオレンジ
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: Color(0xFFFFB74D)), // 少し濃い枠線
                          ),
                        ),
                        child: Text('プレビュー'),
                      ),
                      SizedBox(width: 8),
                      // 削除ボタン
                      TextButton(
                        onPressed: () => _deleteArticle(index),
                        style: TextButton.styleFrom(
                          backgroundColor: Color(0xFFE3F2FD), // 淡い水色
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: Color(0xFF64B5F6)), // 少し濃い枠線
                          ),
                        ),
                        child: Text('削除'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
