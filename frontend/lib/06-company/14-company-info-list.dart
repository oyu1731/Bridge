import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:html' as html show window;
import '../11-common/58-header.dart';
import '15-company-info-detail.dart';
import '16-article-list.dart';

class CompanySearchPage extends StatefulWidget {
  const CompanySearchPage({Key? key}) : super(key: key);

  @override
  State<CompanySearchPage> createState() => _CompanySearchPageState();
}

class _CompanySearchPageState extends State<CompanySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedIndustry = '業種';
  String _selectedProfession = '職種';
  String _selectedArea = 'エリア';

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

  bool get _isTabletOrDesktop {
    if (kIsWeb) {
      // Web版でのタブレット/デスクトップ判別
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      return !userAgent.contains('mobile') || userAgent.contains('ipad');
    } else {
      return !(Platform.isAndroid || Platform.isIOS);
    }
  }

  // ダミーデータ
  final List<String> _industries = ['業種', 'IT', '製造業', '金融', '医療', '教育'];
  final List<String> _professions = ['職種', 'エンジニア', '営業', 'マーケティング', 'デザイナー'];
  final List<String> _areas = ['エリア', '東京', '大阪', '愛知', '福岡', '北海道'];

  final List<Map<String, String>> _featuredCompanies = [
    {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
    {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
    {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
    {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
    {'name': '企業名（リンク）', 'category': 'IT', 'location': '東京都大学等'},
  ];

  final List<Map<String, String>> _featuredArticles = [
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
                onPressed: () {
                  // 検索結果ページに遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CompanySearchResultPage(
                            searchQuery: _searchController.text,
                            industry: _selectedIndustry,
                            profession: _selectedProfession,
                            area: _selectedArea,
                          ),
                    ),
                  );
                },
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
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown('職種', _professions, _selectedProfession, (
                  value,
                ) {
                  setState(() => _selectedProfession = value!);
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown('エリア', _areas, _selectedArea, (value) {
                  setState(() => _selectedArea = value!);
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
          Text(
            '注目企業',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 16),
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
                    itemCount: _featuredCompanies.length,
                    itemBuilder: (context, index) {
                      return _buildCompanyCard(_featuredCompanies[index], true);
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
              itemCount: _featuredCompanies.length,
              itemBuilder: (context, index) {
                return _buildCompanyCard(_featuredCompanies[index], isSmallScreen);
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

  Widget _buildCompanyCard(Map<String, String> company, [bool isSmallScreen = false]) {
    // スマートフォンサイズに応じてカードサイズを調整
    double cardWidth = isSmallScreen ? 140 : 160;
    double imageHeight = isSmallScreen ? 80 : 100;
    double fontSize = isSmallScreen ? 13 : 14;
    double categoryFontSize = isSmallScreen ? 11 : 12;
    double cardMargin = isSmallScreen ? 8 : 12;
    
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
            child: Center(
              child: Text(
                '画像',
                style: TextStyle(
                  color: Color(0xFF757575), 
                  fontSize: categoryFontSize,
                ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CompanyDetailPage(
                          companyName: company['name']!,
                          companyId: 'company-${company['name']!.hashCode}',
                        ),
                      ),
                    );
                  },
                  child: Text(
                    company['name']!,
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
                  company['category']!,
                  style: TextStyle(
                    color: Color(0xFF757575), 
                    fontSize: categoryFontSize,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  company['location']!,
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
          Column(
            children:
                _featuredArticles
                    .map((article) => _buildArticleCard(article))
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, String> article) {
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
          Text(
            article['title']!,
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontSize: 14,
              fontWeight: FontWeight.w500,
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

// 検索結果ページ
class CompanySearchResultPage extends StatelessWidget {
  final String searchQuery;
  final String industry;
  final String profession;
  final String area;

  const CompanySearchResultPage({
    Key? key,
    required this.searchQuery,
    required this.industry,
    required this.profession,
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
            _buildRelatedArticlesSection(relatedArticles),
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
          if (profession != '職種')
            Text('職種: $profession', style: TextStyle(fontSize: 14)),
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
                            companyId: 'company-${company['name']!.hashCode}',
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

  Widget _buildRelatedArticlesSection(List<Map<String, String>> articles) {
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
                articles.map((article) => _buildArticleCard(article)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Map<String, String> article) {
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
          Text(
            article['title']!,
            style: TextStyle(
              color: Color(0xFF1976D2),
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
