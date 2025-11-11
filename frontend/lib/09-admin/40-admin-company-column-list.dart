import 'package:flutter/material.dart';
import 'package:bridge/11-common/58-header.dart';

class AdminCompanyColumnList extends StatefulWidget {
  @override
  _AdminCompanyColumnListState createState() => _AdminCompanyColumnListState();
}

class _AdminCompanyColumnListState extends State<AdminCompanyColumnList> {
  final TextEditingController _searchController = TextEditingController();

  // サンプルの投稿記事データ
  final List<Map<String, dynamic>> _articles = [
    {
      'id': '1',
      'title': '【株式会社AAA】【選考あり】会社説明会のご案内',
      'description':
          '弊社では、随時オンライン会社説明会を開催中です。定期的にあるマイナビもしくはリクナビのリンクからエントリーください！エントリーお待ちしております！',
      'tag': '#説明会開催中,#会社紹介',
      'isActive': true,
      'hasPreview': true,
      'hasEdit': true,
      'company': '株式会社AAA',
    },
    {
      'id': '2',
      'title': '【株式会社AAA】スレッドを開設しました。',
      'description':
          '弊社の交流スレッドを作成いたしました！質問においても気になることや、弊社に対する質問など気軽に投稿してくださいね♪\n\nスレッドタイトルは【株式会社AAA～フリースレッド】です！',
      'tag': '#スレッド開設',
      'isActive': true,
      'hasPreview': true,
      'hasEdit': true,
      'company': '株式会社AAA',
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
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            // 記事一覧
            Column(
              children: _filteredArticles
                  .map((article) => _buildColumnList(article))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '記事検索',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
              onSubmitted: (value) {
                _onSearchPressed();
              },
            ),
          ),
          const SizedBox(width: 8),
          // 検索ボタン
          Container(
            height: 48, // TextFieldと高さ揃え
            child: ElevatedButton(
              onPressed: _onSearchPressed,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Icon(Icons.search),
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchPressed() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredArticles = List.from(_articles);
      } else {
        _filteredArticles = _articles
            .where((article) =>
                article['title'].toLowerCase().contains(query) ||
                article['description'].toLowerCase().contains(query) ||
                article['company'].toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Widget _buildColumnList(Map<String, dynamic> article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Text(
              article['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            // タグ
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                article['tag'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 説明文
            Text(
              article['description'],
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF616161),
                height: 1.6,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            // ボタン行（現時点では空）
            Row(),
          ],
        ),
      ),
    );
  }
}
