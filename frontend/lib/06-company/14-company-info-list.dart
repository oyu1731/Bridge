import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:html' as html show window;
import '../11-common/58-header.dart';
import 'company_api_client.dart';
import 'article_api_client.dart';
import '15-company-info-detail.dart';
import '16-article-list.dart';
import '18-article-detail.dart';

class CompanySearchPage extends StatefulWidget {
  const CompanySearchPage({Key? key}) : super(key: key);

  @override
  State<CompanySearchPage> createState() => _CompanySearchPageState();
}

class _CompanySearchPageState extends State<CompanySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedIndustry = '業種';
  String _selectedArea = 'エリア';

  // API連携のための状態管理
  List<CompanyDTO> _filteredCompanies = [];
  List<ArticleDTO> _articles = [];
  bool _isLoading = false;
  bool _isLoadingArticles = false;
  String? _errorMessage;
  bool _hasSearched = false; // 検索が実行されたかどうかを管理

  @override
  void initState() {
    super.initState();
    _loadCompanies();
    _loadArticles();
  }

  // 企業データを読み込む
  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final companies = await CompanyApiClient.getAllCompanies();
      setState(() {
        _filteredCompanies = companies;
        _isLoading = false;
        _hasSearched = false; // 初期データは注目企業として表示
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // 記事データを読み込み
  Future<void> _loadArticles() async {
    setState(() {
      _isLoadingArticles = true;
    });

    try {
      final articles = await ArticleApiClient.getAllArticles();
      setState(() {
        _articles = articles;
        _isLoadingArticles = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingArticles = false;
      });
      print('記事の読み込みエラー: $e');
    }
  }

  // 検索を実行
  Future<void> _performSearch() async {
    final keyword = _searchController.text.trim();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true; // 検索が実行されたことをマーク
    });

    try {
      print('検索開始: キーワード = "$keyword"'); // デバッグログ
      print('選択された業種: $_selectedIndustry'); // デバッグログ
      print('選択されたエリア: $_selectedArea'); // デバッグログ
      
      List<CompanyDTO> results;
      
      // 検索条件チェック
      bool hasKeyword = keyword.isNotEmpty;
      bool hasIndustryFilter = _selectedIndustry != '業種';
      bool hasAreaFilter = _selectedArea != 'エリア';
      
      if (!hasKeyword && !hasIndustryFilter && !hasAreaFilter) {
        // 何も条件が指定されていない場合は注目企業として表示
        print('検索条件なし - 注目企業を表示'); // デバッグログ
        results = await CompanyApiClient.getAllCompanies();
        setState(() {
          _hasSearched = false; // 検索ではなく初期表示として扱う
        });
      } else {
        // 何らかの条件が指定されている場合は検索結果として表示
        if (hasKeyword) {
          print('企業を検索中: $keyword'); // デバッグログ
          results = await CompanyApiClient.searchCompanies(keyword);
        } else {
          print('全企業を取得してフィルタリング'); // デバッグログ
          results = await CompanyApiClient.getAllCompanies();
        }
        
        // フィルタリング（プルダウンの選択値に基づいて）
        results = _applyFilters(results);
      }
      
      print('最終結果: ${results.length}件'); // デバッグログ
      setState(() {
        _filteredCompanies = results;
        _isLoading = false;
      });
    } catch (e) {
      print('検索エラー: $e'); // デバッグログ
      setState(() {
        _errorMessage = '検索エラー: $e';
        _isLoading = false;
      });
    }
  }

  // プルダウンメニューの選択に基づいてフィルタリングを適用
  // 検索条件をクリア
  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _selectedIndustry = '業種';
      _selectedArea = 'エリア';
      _hasSearched = false;
    });
    _loadCompanies(); // 注目企業を再読み込み
  }

  // プルダウンメニューの選択に基づいてフィルタリングを適用
  List<CompanyDTO> _applyFilters(List<CompanyDTO> companies) {
    List<CompanyDTO> filtered = companies;
    
    // 業種でフィルタリング
    if (_selectedIndustry != '業種' && _selectedIndustry.isNotEmpty) {
      filtered = filtered.where((company) {
        // 実際の業界情報を使用してフィルタリング
        if (company.industry != null) {
          return company.industry!.contains(_selectedIndustry);
        }
        // 業界情報がない場合は従来のロジックをフォールバックとして使用
        String industryKeyword = _selectedIndustry;
        if (industryKeyword == 'IT') {
          return company.name.toLowerCase().contains('it') || 
                 company.name.contains('Bridge') || // Bridge はIT企業として扱う
                 (company.description != null && 
                  (company.description!.toLowerCase().contains('it') ||
                   company.description!.contains('システム') ||
                   company.description!.contains('ソフトウェア')));
        }
        return company.name.contains(industryKeyword) || 
               (company.description != null && company.description!.contains(industryKeyword));
      }).toList();
      print('業種フィルタリング後: ${filtered.length}件 (業種: $_selectedIndustry)');
    }

    // エリアでフィルタリング
    if (_selectedArea != 'エリア' && _selectedArea.isNotEmpty) {
      filtered = filtered.where((company) {
        String areaKeyword = _selectedArea;
        // 東京の場合は東京都も含む
        if (areaKeyword == '東京') {
          return company.address.contains('東京') || company.address.contains('渋谷');
        }
        return company.address.contains(areaKeyword);
      }).toList();
      print('エリアフィルタリング後: ${filtered.length}件 (エリア: $_selectedArea)');
    }
    
    return filtered;
  }

  // プラットフォーム判別ヘルパーメソッド
  bool get _isMobileDevice {
    if (kIsWeb) {
      // Webの場合はユーザーエージェントで判別
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return userAgent.contains('mobile') || 
             userAgent.contains('android') || 
             userAgent.contains('iphone') || 
             userAgent.contains('ipad');
    } else {
      // ネイティブアプリの場合はプラットフォームで判別
      return Platform.isAndroid || Platform.isIOS;
    }
  }

  // ダミーデータ
  final List<String> _industries = ['業種', 'IT', '製造業', 'サービス業', '金融'];
  final List<String> _areas = ['エリア', '東京都', '大阪府', '愛知県', '福岡県'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 企業検索セクション
            _buildSearchSection(),

            // 注目企業セクション
            _buildFeaturedCompaniesSection(),

            // 注目記事セクション
            _buildFeaturedArticlesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '企業検索',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 16),
          // 検索バー
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFE0E0E0)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '企業名で検索',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _performSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text('検索'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // フィルター
          Row(
            children: [
              Expanded(
                child: _buildDropdown('業種', _industries, _selectedIndustry, (
                  value,
                ) {
                  setState(() => _selectedIndustry = value!);
                  // 自動検索を削除 - 検索ボタンを押すまで検索しない
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown('エリア', _areas, _selectedArea, (value) {
                  setState(() => _selectedArea = value!);
                  // 自動検索を削除 - 検索ボタンを押すまで検索しない
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          items:
              items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(value),
                  ),
                );
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFeaturedCompaniesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _hasSearched ? '検索結果' : '注目企業',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              Row(
                children: [
                  if (_hasSearched && !_isLoading)
                    Text(
                      '${_filteredCompanies.length}件',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  if (_hasSearched && !_isLoading) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _clearSearch,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF1976D2)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'クリア',
                          style: TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            Container(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            Container(
              height: 180,
              child: Center(
                child: Text(
                  'エラー: $_errorMessage',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (_filteredCompanies.isEmpty)
            Container(
              height: 180,
              child: Center(
                child: Text(
                  '企業が見つかりませんでした',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // プラットフォームと画面幅を組み合わせて表示方法を判定
                double screenWidth = constraints.maxWidth;
                
                // プラットフォームベースの判別を優先
                if (_isMobileDevice) {
                  // モバイルデバイス（Android/iOS）: シンプルな横スクロール
                  return Container(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: _filteredCompanies.length,
                      itemBuilder: (context, index) {
                        return _buildCompanyCard(_filteredCompanies[index], true);
                      },
                    ),
                  );
                } else {
                  // PC・タブレット（Web/Desktop）: 矢印ボタン付きの横スクロール
                  // 画面幅が非常に小さい場合でも矢印ボタンを維持
                  bool isSmallScreen = screenWidth <= 600; // 閾値を下げる
                  return _buildPCHorizontalScroll(isSmallScreen);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPCHorizontalScroll([bool isSmallScreen = false]) {
    final ScrollController _scrollController = ScrollController();
    double containerHeight = isSmallScreen ? 180 : 200;
    double buttonSize = isSmallScreen ? 36 : 40; // 最小サイズを36に
    double iconSize = isSmallScreen ? 18 : 20; // アイコンサイズも調整
    
    return Container(
      height: containerHeight,
      child: Row(
        children: [
          // 左矢印ボタン
          Container(
            width: buttonSize,
            child: Center(
              child: IconButton(
                onPressed: () {
                  _scrollController.animateTo(
                    _scrollController.offset - 200,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Color(0xFF757575),
                  size: iconSize,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Color(0xFFE0E0E0)),
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8), // パディングも調整
                  minimumSize: Size(buttonSize, buttonSize), // 最小サイズを保証
                ),
              ),
            ),
          ),
          
          // スクロール可能なカードリスト
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              itemCount: _filteredCompanies.length,
              itemBuilder: (context, index) {
                return _buildCompanyCard(_filteredCompanies[index], isSmallScreen);
              },
            ),
          ),
          
          // 右矢印ボタン
          Container(
            width: buttonSize,
            child: Center(
              child: IconButton(
                onPressed: () {
                  _scrollController.animateTo(
                    _scrollController.offset + 200,
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xFF757575),
                  size: iconSize,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Color(0xFFE0E0E0)),
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(isSmallScreen ? 6 : 8), // パディングも調整
                  minimumSize: Size(buttonSize, buttonSize), // 最小サイズを保証
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(dynamic company, [bool isSmallScreen = false]) {
    // スマートフォンサイズに応じてカードサイズを調整
    double cardWidth = isSmallScreen ? 140 : 160;
    double imageHeight = isSmallScreen ? 80 : 100;
    double fontSize = isSmallScreen ? 13 : 14;
    double categoryFontSize = isSmallScreen ? 11 : 12;
    double cardMargin = isSmallScreen ? 8 : 12;
    
    // CompanyDTOまたはMap<String, String>から値を取得
    String companyName;
    String companyLocation;
    String companyCategory;
    String? photoPath;
    
    if (company is CompanyDTO) {
      companyName = company.name;
      companyLocation = company.address;
      companyCategory = 'IT'; // デフォルト値、後で業種データがあれば使用
      photoPath = company.photoPath; // 写真パスを取得
    } else if (company is Map<String, String>) {
      companyName = company['name'] ?? '';
      companyLocation = company['location'] ?? '';
      companyCategory = company['category'] ?? 'IT';
      photoPath = null; // Mapの場合は写真パスなし
    } else {
      companyName = '不明';
      companyLocation = '不明';
      companyCategory = '不明';
      photoPath = null;
    }
    
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: cardMargin),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: imageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: photoPath != null && photoPath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      photoPath,
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.business,
                            color: Color(0xFF757575),
                            size: categoryFontSize * 2,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.business,
                      color: Color(0xFF757575),
                      size: categoryFontSize * 2,
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () {
                    // 企業詳細ページへの遷移
                    if (company is CompanyDTO) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyDetailPage(
                            companyName: companyName,
                            companyId: company.id ?? 0,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyDetailPage(
                            companyName: companyName,
                            companyId: 0, // ダミーIDとして0を使用
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    companyName,
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  companyCategory,
                  style: TextStyle(
                    color: Color(0xFF757575), 
                    fontSize: categoryFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  companyLocation,
                  style: TextStyle(
                    color: Color(0xFF757575), 
                    fontSize: categoryFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedArticlesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '注目記事',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              InkWell(
                onTap: () {
                  // 記事一覧ページに遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArticleListPage(),
                    ),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'もっと見る',
                    style: TextStyle(
                      color: Color(0xFF1976D2),
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _isLoadingArticles
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Column(
                  children: _articles
                      .take(3) // 最初の3件のみ表示
                      .map((article) => _buildArticleCard(article))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(ArticleDTO article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              // 記事詳細ページに遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(
                    articleTitle: article.title,
                    articleId: article.id.toString(),
                    companyName: article.companyName ?? '企業名不明',
                    description: article.description,
                  ),
                ),
              );
            },
            child: Text(
              article.title,
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article.description,
            style: TextStyle(
              color: Color(0xFF424242),
              fontSize: 13,
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                article.companyName ?? '企業名不明',
                style: TextStyle(color: Color(0xFF757575), fontSize: 12),
              ),
              const SizedBox(width: 16),
              Text(
                '♡ ${article.totalLikes ?? 0}',
                style: TextStyle(color: Color(0xFF757575), fontSize: 12),
              ),
              const Spacer(),
              Text(
                article.createdAt != null 
                    ? article.createdAt!.substring(0, 10) // 日付部分のみ表示
                    : '日付不明',
                style: TextStyle(color: Color(0xFF757575), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// 検索結果ページ
class CompanySearchResultPage extends StatelessWidget {
  final String searchQuery;
  final String industry;
  final String area;

  const CompanySearchResultPage({
    Key? key,
    required this.searchQuery,
    required this.industry,
    required this.area,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ダミーの検索結果データ
    final List<Map<String, String>> searchResults = [
      {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
      {'name': '企業名（リンク）', 'category': '製造業', 'location': '愛知県大学等'},
      {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
      {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
      {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
      {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
      {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
      {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
      {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
      {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
    ];

    final List<Map<String, String>> relatedArticles = [
      {
        'title': '企業名（リンク）',
        'description': '【営業】ITエンジニアとして、このようなことを、してみたい・やってみたい',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'title': '企業名（リンク）',
        'description': '【営業】ITエンジニアとして、このようなことを、してみたい・やってみたい',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'title': '企業名（リンク）',
        'description': '【営業】ITエンジニアとして、このようなことを、してみたい・やってみたい',
        'category': 'IT',
        'location': '東京都大学等',
      },
    ];

    return Scaffold(
      appBar: BridgeHeader(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 検索条件表示
            _buildSearchInfo(context),

            // 検索結果セクション
            _buildSearchResultsSection(searchResults),

            // 関連記事セクション
            _buildRelatedArticlesSection(context, relatedArticles),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '検索結果',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF424242),
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('検索条件を変更'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (searchQuery.isNotEmpty)
            Text('検索キーワード: "$searchQuery"', style: TextStyle(fontSize: 14)),
          if (industry != '業種')
            Text('業種: $industry', style: TextStyle(fontSize: 14)),
          if (area != 'エリア') Text('エリア: $area', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSearchResultsSection(List<Map<String, String>> results) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '検索結果（${results.length}件）',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              return _buildCompanyCardForResults(context, results[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCardForResults(BuildContext context, Map<String, String> company) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Text(
                  '画像',
                  style: TextStyle(
                    color: Color(0xFF757575), 
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      // 企業詳細ページへの遷移
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompanyDetailPage(
                            companyName: company['name']!,
                            companyId: 0, // ダミーIDとして0を使用
                          ),
                        ),
                      );
                    },
                    child: Text(
                      company['name']!,
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    company['category']!,
                    style: TextStyle(
                      color: Color(0xFF757575), 
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    company['location']!,
                    style: TextStyle(
                      color: Color(0xFF757575), 
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedArticlesSection(BuildContext context, List<Map<String, String>> articles) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '関連記事',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children:
                articles.map((article) => _buildArticleCard(context, article)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, Map<String, String> article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              // 記事詳細ページに遷移
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleDetailPage(
                    articleTitle: article['title']!,
                    articleId: 'article-${article['title']!.hashCode}',
                    companyName: '株式会社AAA',
                    description: article['description'],
                  ),
                ),
              );
            },
            child: Text(
              article['title']!,
              style: TextStyle(
                color: Color(0xFF1976D2),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            article['description']!,
            style: TextStyle(
              color: Color(0xFF424242),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                article['category']!,
                style: TextStyle(color: Color(0xFF757575), fontSize: 12),
              ),
              const SizedBox(width: 16),
              Text(
                article['location']!,
                style: TextStyle(color: Color(0xFF757575), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
