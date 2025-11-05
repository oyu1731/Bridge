import 'package:flutter/material.dart';
import '../header.dart';
import '15-company-info-detail.dart';

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

  // ダミーデータ
  final List<String> _industries = ['業種', 'IT', '製造業', '金融', '医療', '教育'];
  final List<String> _professions = ['職種', 'エンジニア', '営業', 'マーケティング', 'デザイナー'];
  final List<String> _areas = ['エリア', '東京', '大阪', '愛知', '福岡', '北海道'];

  final List<Map<String, String>> _featuredCompanies = [
    {
      'name': '企業名（リンク）',
      'category': 'IT',
      'location': '東京都大学等',
    },
    {
      'name': '企業名（リンク）',
      'category': 'IT', 
      'location': '東京都大学等',
    },
    {
      'name': '企業名（リンク）',
      'category': 'IT',
      'location': '東京都大学等',
    },
    {
      'name': '企業名（リンク）',
      'category': 'IT',
      'location': '東京都大学等',
    },
    {
      'name': '企業名（リンク）',
      'category': 'IT',
      'location': '東京都大学等',
    },
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
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      builder: (context) => CompanySearchResultPage(
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
              Expanded(child: _buildDropdown('業種', _industries, _selectedIndustry, (value) {
                setState(() => _selectedIndustry = value!);
              })),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown('職種', _professions, _selectedProfession, (value) {
                setState(() => _selectedProfession = value!);
              })),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown('エリア', _areas, _selectedArea, (value) {
                setState(() => _selectedArea = value!);
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selectedValue, ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          items: items.map((String value) {
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _featuredCompanies.map((company) => _buildCompanyCard(company)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, String> company) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
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
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  company['category']!,
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  company['location']!,
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 12,
                  ),
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
          Text(
            '注目記事',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: _featuredArticles.map((article) => _buildArticleCard(article)).toList(),
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
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                article['location']!,
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                ),
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
      {
        'name': '企業名（リンク）',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'name': '企業名（リンク）',
        'category': '製造業',
        'location': '愛知県大学等',
      },
      {
        'name': '企業名（リンク）',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'name': '企業名（リンク）',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'name': '企業名（リンク）',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'name': '企業名（リンク）',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'name': '企業名（リンク）',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'name': '企業名（リンク）',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'name': '企業名（リンク）',
        'category': 'IT',
        'location': '東京都大学等',
      },
      {
        'name': '企業名（リンク）',
        'category': 'IT',
        'location': '東京都大学等',
      },
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
          if (area != 'エリア')
            Text('エリア: $area', style: TextStyle(fontSize: 14)),
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
              return _buildCompanyCard(context, results[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(BuildContext context, Map<String, String> company) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(8),
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
                    fontSize: 14,
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
                  ),
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
            children: articles.map((article) => _buildArticleCard(article)).toList(),
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
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                article['location']!,
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}