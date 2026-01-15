import 'package:flutter/material.dart';
import '../11-common/58-header.dart';
import '18-article-detail.dart';
import 'article_api_client.dart';
import 'filter_api_client.dart';

class ArticleListPage extends StatefulWidget {
  final String? companyName;

  const ArticleListPage({Key? key, this.companyName}) : super(key: key);

  @override
  _ArticleListPageState createState() => _ArticleListPageState();
}

class _ArticleListPageState extends State<ArticleListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isFilterExpanded = false;
  List<String> _selectedTags = [];
  String? _selectedIndustry;
  bool _isStrictMode = false; // すべての条件に当てはまるもののみ表示
  String _sortOrder = 'newest'; // newest, oldest, mostLiked, leastLiked

  // 実際の記事データ（APIから取得）
  List<ArticleDTO> _allArticles = [];
  List<ArticleDTO> _filteredArticles = [];
  List<String> _availableTags = []; // 動的タグリスト
  List<String> _availableIndustries = []; // 動的業界リスト
  Map<String, int> _industryIdMap = {}; // 業界名かIDのマッピング
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    // 企業名が渡された場合は検索バーに設定
    if (widget.companyName != null && widget.companyName!.isNotEmpty) {
      _searchController.text = widget.companyName!;
    }

    _loadFilterData();
    _loadArticles();
  }

  Future<void> _loadFilterData() async {
    try {
      // タグデータを取得
      final tags = await FilterApiClient.getAllTags();
      final industries = await FilterApiClient.getAllIndustries();

      setState(() {
        _availableTags = tags.map((tag) => tag.tag).toList();
        _availableIndustries =
            industries.map((industry) => industry.industry).toList();

        // 業界名かIDのマッピングを作成
        _industryIdMap = {};
        for (final industry in industries) {
          _industryIdMap[industry.industry] = industry.id;
        }
      });
    } catch (e) {
      print('フィルタデータの読み込みエラー: $e');
      // エラーが発生した場合はデフォルト値を使用
      setState(() {
        _availableTags = ['説明会開催中', '会社員の日常', 'インターン開催中'];
        _availableIndustries = ['IT', '製造業', 'サービス業'];
        _industryIdMap = {'IT': 1, '製造業': 2, 'サービス業': 3};
      });
    }
  }

  Future<void> _loadArticles() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final articles = await ArticleApiClient.getAllArticles();
      setState(() {
        _allArticles = articles;
        _filteredArticles = articles;
        _isLoading = false;
      });

      // 初期ロード時もソートを適用
      _applySorting();

      // 企業名が指定されている場合は検索を実行
      if (widget.companyName != null && widget.companyName!.isNotEmpty) {
        _searchArticlesFromAPI();
      }
    } catch (e) {
      setState(() {
        _error = '記事の読み込みエラー: $e';
        _isLoading = false;
      });
      print('記事読み込みエラー: $e');
    }
  }

  Future<void> _searchArticlesFromAPI() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      String? keyword =
          _searchController.text.isEmpty ? null : _searchController.text;
      int? industryId =
          _selectedIndustry != null ? _industryIdMap[_selectedIndustry] : null;

      final articles = await ArticleApiClient.searchArticles(
        keyword: keyword,
        industryId: industryId,
      );

      setState(() {
        _allArticles = articles;
        _filteredArticles = articles;
        _isLoading = false;
      });

      // Apply remaining local filters (tags) and sorting after getting API results
      _applyLocalFilters();
    } catch (e) {
      setState(() {
        _error = '検索エラー: $e';
        _isLoading = false;
      });
      print('検索エラー: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterArticles() {
    // If there's a search keyword or industry filter, use API search
    if (_searchController.text.isNotEmpty || _selectedIndustry != null) {
      _searchArticlesFromAPI();
      return;
    }

    // Otherwise, filter locally by tags only
    _applyLocalFilters();
  }

  void _applyLocalFilters() {
    setState(() {
      _filteredArticles =
          _allArticles.where((article) {
            bool matchesTag = true;

            // タグでフィルタ
            if (_selectedTags.isNotEmpty && article.tags != null) {
              if (_isStrictMode) {
                // すべての選択されたタグが記事に含まれているかチェック（AND条件）
                matchesTag = _selectedTags.every(
                  (tag) => article.tags!.contains(tag),
                );
              } else {
                // いずれかのタグが一致すればOK（OR条件）
                matchesTag = _selectedTags.any(
                  (tag) => article.tags!.contains(tag),
                );
              }
            } else if (_selectedTags.isNotEmpty && article.tags == null) {
              matchesTag = false;
            }

            return matchesTag;
          }).toList();

      // ソート適用
      _applySorting();
    });
  }

  void _applySorting() {
    switch (_sortOrder) {
      case 'newest':
        _filteredArticles.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case 'oldest':
        _filteredArticles.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return a.createdAt!.compareTo(b.createdAt!);
        });
        break;
      case 'mostLiked':
        _filteredArticles.sort((a, b) {
          final aLikes = a.totalLikes ?? 0;
          final bLikes = b.totalLikes ?? 0;
          return bLikes.compareTo(aLikes);
        });
        break;
      case 'leastLiked':
        _filteredArticles.sort((a, b) {
          final aLikes = a.totalLikes ?? 0;
          final bLikes = b.totalLikes ?? 0;
          return aLikes.compareTo(bLikes);
        });
        break;
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedTags.clear();
      _selectedIndustry = null;
      _isStrictMode = false;
      _sortOrder = 'newest';
      _filteredArticles = List.from(_allArticles);
      _applySorting();
      // _isFilterExpanded は維持して、メニューを閉じないようにする
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: Column(
        children: [
          // 検索バーとフィルターエリア
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 検索バーとソート
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFFE0E0E0)),
                          borderRadius: BorderRadius.circular(8),
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
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                onChanged: (value) {
                                  // 入力時には検索しない
                                },
                              ),
                            ),
                            // フィルター展開ボタン
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _isFilterExpanded = !_isFilterExpanded;
                                });
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                ),
                                child: Icon(
                                  _isFilterExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                            // 検索ボタン
                            InkWell(
                              onTap: () => _filterArticles(),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                ),
                                child: Icon(
                                  Icons.search,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    // ソートドロップダウン
                    Container(
                      height: 48,
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: DropdownButton<String>(
                        value: _sortOrder,
                        underline: SizedBox(),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF757575),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF424242),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'newest',
                            child: Text('新しい順'),
                          ),
                          DropdownMenuItem(value: 'oldest', child: Text('古い順')),
                          DropdownMenuItem(
                            value: 'mostLiked',
                            child: Text('いいね数が多い順'),
                          ),
                          DropdownMenuItem(
                            value: 'leastLiked',
                            child: Text('いいね数が少ない順'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortOrder = value;
                              _applyLocalFilters();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),

                // フィルタードロップダウン（展開時）
                if (_isFilterExpanded)
                  Container(
                    margin: EdgeInsets.only(top: 16),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      border: Border.all(color: Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '業界で絞り込み',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    height: 200,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        children:
                                            _availableIndustries.map((
                                              industry,
                                            ) {
                                              return RadioListTile<String>(
                                                title: Text(
                                                  industry,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                value: industry,
                                                groupValue: _selectedIndustry,
                                                onChanged: (String? value) {
                                                  setState(() {
                                                    _selectedIndustry = value;
                                                  });
                                                  // 検索ボタンを押すまで検索しない
                                                },
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                activeColor: Color(0xFF1976D2),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'タグで絞り込み',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    height: 200,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Color(0xFFE0E0E0),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: Column(
                                        children:
                                            _availableTags.map((tag) {
                                              return CheckboxListTile(
                                                title: Text(
                                                  tag,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                value: _selectedTags.contains(
                                                  tag,
                                                ),
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    if (value == true) {
                                                      _selectedTags.add(tag);
                                                    } else {
                                                      _selectedTags.remove(tag);
                                                    }
                                                  });
                                                  // 検索ボタンを押すまで検索しない
                                                },
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                dense: true,
                                                contentPadding: EdgeInsets.zero,
                                                activeColor: Color(0xFF1976D2),
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // 選択されたタグの表示
                        if (_selectedTags.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Color(0xFF1976D2).withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '選択中のタグ:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children:
                                      _selectedTags.map((tag) {
                                        return Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF1976D2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                tag,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedTags.remove(tag);
                                                  });
                                                  // 検索ボタンを押すまで検索しない
                                                },
                                                child: Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // すべての条件に当てはまるもののみ表示チェックボックス
                            Row(
                              children: [
                                Checkbox(
                                  value: _isStrictMode,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isStrictMode = value ?? false;
                                    });
                                    // 検索ボタンを押すまで検索しない
                                  },
                                  activeColor: Color(0xFF1976D2),
                                ),
                                Text(
                                  'すべてのタグに当てはまる記事のみを表示',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF424242),
                                  ),
                                ),
                              ],
                            ),
                            // リセットボタン
                            OutlinedButton(
                              onPressed: _resetFilters,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                side: BorderSide(color: Color(0xFF757575)),
                              ),
                              child: Text(
                                'リセット',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 記事一覧タイトル
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              '記事一覧',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424242),
              ),
            ),
          ),
          SizedBox(height: 16),

          // 記事一覧
          Expanded(
            child:
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF757575),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadArticles,
                            child: Text('再試行'),
                          ),
                        ],
                      ),
                    )
                    : _filteredArticles.isEmpty
                    ? Center(
                      child: Text(
                        '該当する記事が見つかりません',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF757575),
                        ),
                      ),
                    )
                    : LayoutBuilder(
                      builder: (context, constraints) {
                        // スマートフォンサイズ（幅600px以下）の場合は1列、タブレット（幅800px以下）は2列、それ以上は3列
                        int crossAxisCount;
                        if (constraints.maxWidth <= 600) {
                          crossAxisCount = 1; // スマートフォン: 1列
                        } else if (constraints.maxWidth <= 800) {
                          crossAxisCount = 2; // タブレット: 2列
                        } else {
                          crossAxisCount = 3; // デスクトップ: 3列
                        }

                        // スマートフォンの場合は横間隔を狭くする
                        double crossAxisSpacing =
                            constraints.maxWidth <= 800 ? 12 : 16;
                        // 記事カードの縦横比を調整（値が大きいほど横長、小さいほど縦長）
                        double childAspectRatio =
                            constraints.maxWidth <= 600
                                ? 2.2
                                : (constraints.maxWidth <= 800 ? 1.4 : 1.6);

                        return GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: crossAxisSpacing,
                                mainAxisSpacing: 16,
                                childAspectRatio: childAspectRatio,
                              ),
                          itemCount: _filteredArticles.length,
                          itemBuilder: (context, index) {
                            final article = _filteredArticles[index];
                            return _buildArticleCard(article);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(ArticleDTO article) {
    // 新着判定（作成日から7日以内）
    bool isNew = false;
    if (article.createdAt != null) {
      try {
        final createdDate = DateTime.parse(article.createdAt!);
        final now = DateTime.now();
        isNew = now.difference(createdDate).inDays <= 7;
      } catch (e) {
        // 日付解析エラーの場合は新着扱いしない
        isNew = false;
      }
    }

    // 最初のタグを取得（表示用）
    String displayTag = '';
    if (article.tags != null && article.tags!.isNotEmpty) {
      displayTag = article.tags!.first;
    }

    return InkWell(
      onTap: () {
        // 記事詳細ページへの遷移
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ArticleDetailPage(
                  articleTitle: article.title,
                  articleId: article.id?.toString() ?? '0',
                  companyName: article.companyName ?? '会社名不明',
                  description: article.description,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12), // タグ上部の余白
            // タグ表示
            if (article.tags != null && article.tags!.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children:
                      article.tags!
                          .map(
                            (tag) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Color(0xFF1976D2),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '# $tag',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            if (article.tags != null && article.tags!.isNotEmpty)
              SizedBox(height: 8),

            // 会社名と業界名
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      article.companyName ?? '会社名不明',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF424242),
                      ),
                    ),
                  ),
                  if (article.industry != null && article.industry!.isNotEmpty)
                    Text(
                      article.industry!,
                      style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                    ),
                ],
              ),
            ),
            SizedBox(height: 8),

            // 記事タイトル
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                article.title,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Spacer(),

            // いいね数表示
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.favorite, color: Colors.red, size: 16),
                  SizedBox(width: 6),
                  Text(
                    '${article.totalLikes ?? 0}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF424242),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
