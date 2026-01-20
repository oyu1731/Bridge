import 'package:flutter/material.dart';
import '../11-common/58-header.dart';
import '../06-company/article_api_client.dart';
import '41-admin-company-article-detail.dart';

class AdminCompanyColumnList extends StatefulWidget {
  const AdminCompanyColumnList({Key? key}) : super(key: key);

  @override
  State<AdminCompanyColumnList> createState() => _AdminCompanyColumnListState();
}

class _AdminCompanyColumnListState extends State<AdminCompanyColumnList> {
  final TextEditingController _searchController = TextEditingController();

  List<ArticleDTO> _articles = [];
  List<ArticleDTO> _filteredArticles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    try {
      final articles = await ArticleApiClient.getAllArticles();
      articles.sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));

      setState(() {
        _articles = articles;
        _filteredArticles = articles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(ArticleDTO article) async {
    if (article.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この記事を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ArticleApiClient.deleteArticle(article.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('記事を削除しました'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadArticles(); // 即時反映
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('削除に失敗しました'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      _buildArticleList(),
                    ],
                  ),
                ),
    );
  }

  // ===== 以下 UI は企業側と完全同一 =====

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
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
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _filterArticles(),
              ),
            ),
            InkWell(
              onTap: _filterArticles,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Icon(Icons.search, color: Colors.white, size: 20),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('投稿記事一覧',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF424242))),
        const SizedBox(height: 4),
        Text('${_filteredArticles.length}件の記事',
            style: const TextStyle(fontSize: 14, color: Color(0xFF757575))),
        const SizedBox(height: 16),
        Column(children: _filteredArticles.map(_buildArticleCard).toList())
      ]),
    );
  }

  Widget _buildArticleCard(ArticleDTO article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(article.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
          const SizedBox(height: 12),
          Row(children: [
            if (article.createdAt != null)
              Text(article.createdAt!.substring(0, 10),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
            const Spacer(),
            Row(children: [
              const Icon(Icons.favorite, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text('${article.totalLikes ?? 0}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF757575))),
            ])
          ]),
          const SizedBox(height: 12),
          if (article.tags != null)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: article.tags!
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(6)),
                        child: Text('#$t',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1976D2))),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildPreviewButton(article),
              const SizedBox(width: 12),
              _buildDeleteButton(article),
            ],
          )
        ]),
      ),
    );
  }

  Widget _buildPreviewButton(ArticleDTO article) {
    return ElevatedButton(
      onPressed: () async {
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCompanyArticleDetail(articleId: article.id.toString()),
          ),
        );

        if (deleted == true) {
          await _loadArticles();
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF9800),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        shadowColor: const Color(0xFFFF9800).withOpacity(0.3),
      ),
      child: const Text(
        'プレビュー',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDeleteButton(ArticleDTO article) {
    return ElevatedButton(
      onPressed: () => _confirmDelete(article),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1976D2), // 詳細と同じ
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
        shadowColor: const Color(0xFF1976D2).withOpacity(0.3),
      ),
      child: const Text(
        '削除',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _filterArticles() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredArticles = _articles.where((a) =>
          a.title.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q) ||
          (a.companyName?.toLowerCase().contains(q) ?? false) ||
          (a.tags?.any((t) => t.toLowerCase().contains(q)) ?? false)).toList();
    });
  }
}
