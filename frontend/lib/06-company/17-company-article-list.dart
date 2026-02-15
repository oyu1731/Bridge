import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '18-article-detail.dart';
import '20-company-article-edit.dart';
import '../11-common/58-header.dart';
import 'article_api_client.dart';

class CompanyArticleListPage extends StatefulWidget {
  const CompanyArticleListPage({Key? key}) : super(key: key);

  @override
  _CompanyArticleListPageState createState() => _CompanyArticleListPageState();
}

class _CompanyArticleListPageState extends State<CompanyArticleListPage> {
  final TextEditingController _searchController = TextEditingController();

  List<ArticleDTO> _articles = [];
  List<ArticleDTO> _filteredArticles = [];
  bool _isLoading = true;
  String? _error;
  int? _currentCompanyId;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadCompanyId();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_user');
    if (userJson == null) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/signin');
      }
      return;
    }
    final userData = jsonDecode(userJson);

    // 退会済み・削除済みチェック
    final bool isWithdrawn = userData['is_withdrawn'] == true;
    final bool isDeleted = userData['isDeleted'] == true;

    if (isWithdrawn || isDeleted) {
      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
        // 遷移後にSnackBar表示（WidgetsBindingで遅延実行）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('アカウントが無効です。トップページに戻ります。')));
        });
      }
      return;
    }
  }

  Future<void> _loadCompanyId() async {
    try {
      // デモ用: 固定のユーザー情報を使用
      // email: company@example.com, password: hashed_password_company
      // このユーザーのcompanyIdを取得

      final prefs = await SharedPreferences.getInstance();

      // サインイン情報からcompanyIdを取得
      final userDataString = prefs.getString('current_user');
      if (userDataString == null) {
        setState(() {
          _error = 'ログインしていません。サインインしてください。';
          _isLoading = false;
        });
        return;
      }

      final userData = jsonDecode(userDataString);
      final int? companyId = userData['companyId'] ?? userData['company_id'];

      if (companyId == null) {
        setState(() {
          _error = '企業アカウントでログインしてください。';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _currentCompanyId = companyId;
      });

      // companyIdを取得後に記事を読み込む
      _loadArticles();
    } catch (e) {
      setState(() {
        _error = '企業情報の取得に失敗しました: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadArticles() async {
    if (_currentCompanyId == null) {
      setState(() {
        _error = 'ログイン情報が取得できませんでした';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // ログイン中の企業の記事のみ取得
      List<ArticleDTO> articles = await ArticleApiClient.getArticlesByCompanyId(
        _currentCompanyId!,
      );

      // 作成日時順にソート（新しい順）
      articles.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'エラーが発生しました',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(_error!),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadArticles,
                      child: Text('再読み込み'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  children: [_buildSearchBar(), _buildArticleList()],
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
                  hintStyle: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(fontSize: 14),
                onSubmitted: (_) => _filterArticles(),
              ),
            ),
            InkWell(
              onTap: _filterArticles,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(0xFF1976D2),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Icon(Icons.search, color: Colors.white, size: 20),
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
          Column(
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
              SizedBox(height: 4),
              Text(
                '${_filteredArticles.length}件の記事',
                style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _filteredArticles.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    '記事がありません',
                    style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                  ),
                ),
              )
              : Column(
                children:
                    _filteredArticles
                        .map((article) => _buildArticleCard(article))
                        .toList(),
              ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(ArticleDTO article) {
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
              article.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
                height: 1.4,
              ),
            ),
            SizedBox(height: 12),
            // 作成日時といいね数
            Row(
              children: [
                if (article.createdAt != null)
                  Text(
                    article.createdAt!.substring(0, 10),
                    style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                  ),
                Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      '${article.totalLikes ?? 0}',
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 12),
            // タグ
            if (article.tags != null && article.tags!.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children:
                    article.tags!.map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            SizedBox(height: 20),
            // ボタン行
            Row(
              children: [
                _buildActionButton(
                  'プレビュー',
                  Color(0xFFFF9800),
                  () => _navigateToArticleDetail(article),
                ),
                SizedBox(width: 12),
                _buildActionButton(
                  '編集',
                  Color(0xFF1976D2),
                  () => _editArticle(article),
                ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        shadowColor: color.withOpacity(0.3),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _filterArticles() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredArticles = List.from(_articles);
      });
      return;
    }

    if (_currentCompanyId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final searched = await ArticleApiClient.searchArticles(
        companyId: _currentCompanyId,
        keyword: query,
      );

      setState(() {
        _filteredArticles = searched;
        _isLoading = false;
      });
    } catch (e) {
      // API検索失敗時はローカルフィルターにフォールバック
      final lowerQuery = query.toLowerCase();
      setState(() {
        _filteredArticles =
            _articles.where((article) {
              final titleMatch = article.title.toLowerCase().contains(
                lowerQuery,
              );
              final descriptionMatch = article.description
                  .toLowerCase()
                  .contains(lowerQuery);
              final companyMatch =
                  article.companyName?.toLowerCase().contains(lowerQuery) ??
                  false;
              final tagsMatch =
                  article.tags?.any(
                    (tag) => tag.toLowerCase().contains(lowerQuery),
                  ) ??
                  false;
              return titleMatch ||
                  descriptionMatch ||
                  companyMatch ||
                  tagsMatch;
            }).toList();
        _isLoading = false;
      });
    }
  }

  void _navigateToArticleDetail(ArticleDTO article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ArticleDetailPage(
              articleTitle: article.title,
              articleId: article.id.toString(),
              companyName: article.companyName,
              description: article.description,
            ),
      ),
    );
  }

  void _editArticle(ArticleDTO article) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ArticleEditPage(
              articleId: article.id.toString(),
              initialTitle: article.title,
              initialTags: article.tags ?? [],
              initialImages: [], // 既存画像があれば設定
              initialContent: article.description,
            ),
      ),
    );

    // 編集画面から戻ってきたら記事一覧を再読み込み
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
