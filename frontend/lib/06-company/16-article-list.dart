import 'package:flutter/material.dart';
import '../11-common/58-header.dart';
import '18-article-detail.dart';
import 'article_api_client.dart';

class ArticleListPage extends StatefulWidget {
  final String? companyName;

  const ArticleListPage({
    Key? key,
    this.companyName,
  }) : super(key: key);

  @override
  _ArticleListPageState createState() => _ArticleListPageState();
}

class _ArticleListPageState extends State<ArticleListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isFilterExpanded = false;
  List<String> _selectedTags = [];
  String? _selectedIndustry;
  bool _isStrictMode = false; // すべての条件に当てはまるもののみ表示

  // 実際の記事データ（APIから取得）
  List<ArticleDTO> _allArticles = [];
  List<ArticleDTO> _filteredArticles = [];
  bool _isLoading = true;
  String? _error;

  final List<String> _tags = [
    '説明会開催中',
    '会社員の日常',
    'インターン開催中',
    '就活イベント情報',
    '新卒募集中',
    '全社員のご紹介',
    'エンジニア採用',
    '会社紹介',
    '新卒社員のリアル',
    '先輩インタビュー',
    '新人社員インタビュー',
    '社内イベント',
    '最新ニュース',
    'スレッド開設',
    'キャリアアドバイス',
    '面接のコツ',
    '社員の推しポイント',
  ];

  final List<String> _industries = [
    'メーカー',
    '商社',
    '流通・小売',
    '金融',
    'サービス・インフラ',
    'ソフトウェア・通信',
    '広告・出版・マスコミ',
    '官公庁・公社・団体',
    'IT・ソフトウェア',
    '製造業',
    'サービス業',
    'コンサルティング',
  ];

  @override
  void initState() {
    super.initState();
    _loadArticles();
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
    } catch (e) {
      setState(() {
        _error = '記事の読み込みエラー: $e';
        _isLoading = false;
      });
      print('記事読み込みエラー: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterArticles() {
    setState(() {
      _filteredArticles = _allArticles.where((article) {
        bool matchesSearch = true;
        bool matchesTag = true;
        bool matchesIndustry = true;

        // 検索キーワードでフィルタ
        if (_searchController.text.isNotEmpty) {
          final searchText = _searchController.text.toLowerCase();
          matchesSearch = article.title.toLowerCase().contains(searchText) ||
              (article.companyName?.toLowerCase().contains(searchText) ?? false) ||
              article.description.toLowerCase().contains(searchText);
        }

        // タグでフィルタ
        if (_selectedTags.isNotEmpty && article.tags != null) {
          if (_isStrictMode) {
            // すべての選択されたタグが記事に含まれているかチェック（AND条件）
            matchesTag = _selectedTags.every((tag) => article.tags!.contains(tag));
          } else {
            // いずれかのタグが一致すればOK（OR条件）
            matchesTag = _selectedTags.any((tag) => article.tags!.contains(tag));
          }
        } else if (_selectedTags.isNotEmpty && article.tags == null) {
          matchesTag = false;
        }

        // 業界でフィルタ（現在は実装なし、将来的に追加予定）
        // if (_selectedIndustry != null) {
        //   matchesIndustry = article.industry == _selectedIndustry;
        // }

        return matchesSearch && matchesTag && matchesIndustry;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedTags.clear();
      _selectedIndustry = null;
      _isStrictMode = false;
      _filteredArticles = List.from(_allArticles);
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
                // 検索バー
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
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
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
                                      border: Border.all(color: Color(0xFFE0E0E0)),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: _industries.map((industry) {
                                          return RadioListTile<String>(
                                            title: Text(
                                              industry,
                                              style: TextStyle(fontSize: 13),
                                            ),
                                            value: industry,
                                            groupValue: _selectedIndustry,
                                            onChanged: (String? value) {
                                              setState(() {
                                                _selectedIndustry = value;
                                              });
                                              // 検索ボタンを押すまで検索しない
                                            },
                                            controlAffinity: ListTileControlAffinity.leading,
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
                                      border: Border.all(color: Color(0xFFE0E0E0)),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                    ),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: _tags.map((tag) {
                                          return CheckboxListTile(
                                            title: Text(
                                              tag,
                                              style: TextStyle(fontSize: 13),
                                            ),
                                            value: _selectedTags.contains(tag),
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
                                            controlAffinity: ListTileControlAffinity.leading,
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
                              border: Border.all(color: Color(0xFF1976D2).withOpacity(0.3)),
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
                                  children: _selectedTags.map((tag) {
                                    return Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF1976D2),
                                        borderRadius: BorderRadius.circular(12),
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
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
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
                              // スマートフォンサイズ（幅800px以下）の場合は2列、それ以上は3列
                              int crossAxisCount = constraints.maxWidth <= 800 ? 2 : 3;
                              // スマートフォンの場合は横間隔を狭くする
                              double crossAxisSpacing = constraints.maxWidth <= 800 ? 12 : 16;
                              // 記事カードの縦横比を調整（値が大きいほど横長、小さいほど縦長）
                              double childAspectRatio = constraints.maxWidth <= 800 ? 1.4 : 1.6;
                              
                              return GridView.builder(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
            builder: (context) => ArticleDetailPage(
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
                  children: article.tags!.map((tag) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF1976D2), width: 0.5),
                    ),
                    child: Text(
                      '# $tag',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            if (article.tags != null && article.tags!.isNotEmpty)
              SizedBox(height: 8),

            // 会社名
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                article.companyName ?? '会社名不明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
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
                  Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 16,
                  ),
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